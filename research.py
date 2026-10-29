"""Property research database: evidence-backed, null-only remediation demonstration."""
import argparse
import hashlib
import json
import sqlite3
from pathlib import Path
import pandas as pd

ROOT=Path(__file__).resolve().parent
FIELDS=('address','sale_price','gross_square_feet','residential_units')

def connect(path):
    con=sqlite3.connect(path)
    con.row_factory=sqlite3.Row
    con.execute('PRAGMA foreign_keys=ON')
    return con

def value(x):
    return None if pd.isna(x) or str(x).strip()=='' else str(x)

def initialize(con):
    con.executescript((ROOT/'sql/schema.sql').read_text())
    if con.execute('SELECT COUNT(*) FROM records').fetchone()[0]:
        raise ValueError('Refusing to replace an existing populated database')
    path=ROOT/'data/brooklyn_multifamily_sales.csv'
    registry=json.loads((ROOT/'data/sources.json').read_text())
    if hashlib.sha256(path.read_bytes()).hexdigest()!=registry['snapshot_sha256']:
        raise ValueError('Source extract checksum mismatch')
    data=pd.read_csv(path,keep_default_na=False)
    if len(data)!=sum(s['scope_rows'] for s in registry['sources']):
        raise ValueError('Source count mismatch')
    with con:
        for s in registry['sources']:
            con.execute('INSERT INTO sources VALUES(?,?,?,?)',(s['source_id'],s['url'],s['sha256'],json.dumps(s['publisher_notes'])))
        for r in data.to_dict('records'):
            con.execute('INSERT INTO records VALUES(?,?,?,?,?,?,?,?,?,?,?)',
                (r['record_id'],r['source_id'],r['source_row'],r['bbl'],r['neighborhood'],value(r['address']),
                 r['building_class_at_time_of_sale'],r['sale_date'],value(r['sale_price']),value(r['gross_square_feet']),value(r['residential_units'])))
            for f in FIELDS:
                con.execute('INSERT INTO evidence VALUES(?,?,?,?,?)',(r['record_id'],f,value(r[f]),r['source_id'],r['source_row']))
    return registry

def seed_demo(con):
    """Explicit simulation: create recoverable local gaps, never alter source evidence."""
    rows=con.execute('SELECT * FROM records WHERE sale_price>100000 AND gross_square_feet>1000 AND residential_units>=4 ORDER BY record_id LIMIT 80').fetchall()
    with con:
        for i,r in enumerate(rows):
            f=FIELDS[i%4]
            con.execute(f'UPDATE records SET {f}=NULL WHERE record_id=?',(r['record_id'],))
            e=con.execute('SELECT * FROM evidence WHERE record_id=? AND field=?',(r['record_id'],f)).fetchone()
            con.execute('INSERT INTO proposals(proposal_id,record_id,field,proposed_value,evidence_source,evidence_row,created_by) VALUES(?,?,?,?,?,?,?)',
                        (f'DEMO-{i:03}',r['record_id'],f,e['source_value'],e['source_id'],e['source_row'],'DEMO_IMPORT'))
        # Deliberately wrong evidence; this must be rejected, not converted into value.
        r=rows[0]
        con.execute('INSERT INTO proposals(proposal_id,record_id,field,proposed_value,evidence_source,evidence_row,created_by) VALUES(?,?,?,?,?,?,?)',
                    ('INVALID-DEMO',r['record_id'],'sale_price','999999999','unverified',1,'DEMO_IMPORT'))

def apply_proposal(con,proposal_id,reviewer):
    if not reviewer.strip(): raise ValueError('Named reviewer required')
    # Immediate lock prevents concurrent writers from racing the null-only check.
    con.execute('BEGIN IMMEDIATE')
    try:
        p=con.execute('SELECT * FROM proposals WHERE proposal_id=?',(proposal_id,)).fetchone()
        if p is None: raise ValueError('Unknown proposal')
        if p['status']!='PENDING':
            con.rollback();return p['status']
        f=p['field']
        if f not in FIELDS: raise ValueError('Unsupported field')
        e=con.execute('SELECT * FROM evidence WHERE record_id=? AND field=?',(p['record_id'],f)).fetchone()
        current=con.execute(f'SELECT {f} FROM records WHERE record_id=?',(p['record_id'],)).fetchone()[0]
        reason=None
        if e is None or e['source_id']!=p['evidence_source'] or e['source_row']!=p['evidence_row']:
            reason='Source identity/row does not match evidence'
        elif e['source_value'] is None or p['proposed_value']!=e['source_value']:
            reason='Value does not exactly match source evidence'
        elif current is not None:
            reason='Existing value preserved; overwrite requires separate investigation'
        elif f!='address' and (not pd.to_numeric(p['proposed_value'],errors='coerce')>0):
            reason='Nonpositive or invalid numeric value cannot resolve this gap'
        if reason:
            con.execute("UPDATE proposals SET status='REJECTED',reason=? WHERE proposal_id=?",(reason,proposal_id))
            con.commit();return 'REJECTED'
        con.execute(f'UPDATE records SET {f}=? WHERE record_id=? AND {f} IS NULL',(p['proposed_value'],p['record_id']))
        con.execute('INSERT INTO audit_log(proposal_id,record_id,field,old_value,new_value,evidence_source,evidence_row,reviewer) VALUES(?,?,?,?,?,?,?,?)',
                    (proposal_id,p['record_id'],f,None,p['proposed_value'],e['source_id'],e['source_row'],reviewer))
        con.execute("UPDATE proposals SET status='APPLIED',reason='Exact source recovery; no imputation' WHERE proposal_id=?",(proposal_id,))
        con.commit();return 'APPLIED'
    except Exception:
        con.rollback();raise

def quality(con):
    d=pd.read_sql_query('SELECT * FROM records',con)
    d['missing_fields']=d[list(FIELDS)].isna().sum(axis=1)
    d['zero_or_negative_consideration']=d.sale_price.fillna(0).le(0)
    d['invalid_area']=d.gross_square_feet.fillna(0).le(0)
    d['possible_package']=d.groupby(['sale_date','sale_price'],dropna=False).bbl.transform('nunique').gt(1)&d.sale_price.gt(0)
    d['requires_review']=d.missing_fields.gt(0)|d.zero_or_negative_consideration|d.invalid_area|d.possible_package
    return d

def export(con,out,before):
    out=Path(out);out.mkdir(parents=True,exist_ok=True)
    d=quality(con)
    coverage=pd.read_sql_query((ROOT/'sql/coverage.sql').read_text(),con)
    coverage.to_csv(out/'coverage_by_neighborhood.csv',index=False)
    d.to_csv(out/'record_quality.csv',index=False)
    for table in ('proposals','audit_log','sources'):
        pd.read_sql_query(f'SELECT * FROM {table}',con).to_csv(out/f'{table}.csv',index=False)
    after=int(d.missing_fields.sum());total=len(d)*len(FIELDS)
    m=dict(mode='CONTROLLED GAP-RECOVERY DEMONSTRATION ON OFFICIAL DATA',records=len(d),audited_fields=total,
        missing_before=before,missing_after=after,completeness_before_pct=round(100*(total-before)/total,2),
        completeness_after_pct=round(100*(total-after)/total,2),
        source_backed_updates=con.execute('SELECT COUNT(*) FROM audit_log').fetchone()[0],
        rejected_proposals=con.execute("SELECT COUNT(*) FROM proposals WHERE status='REJECTED'").fetchone()[0],
        records_requiring_review=int(d.requires_review.sum()))
    (out/'summary.json').write_text(json.dumps(m,indent=2))
    report=f'''# Property Research Database — Reviewer Brief

**Purpose:** demonstrate reliable market-data collection, database maintenance and exception reporting for supervised appraisal research.

**Data:** {len(d):,} official Brooklyn C1/C2/C3 sale records from NYC DOF annual 2024/2025 workbooks. Source workbook hashes and row references are retained. These are recorded transactions, not verified appraisals.

## Findings
- Controlled simulation removed 80 otherwise available field values from a local working copy. This is a demonstration of import gaps, not a claim that the provider lost data.
- {m['source_backed_updates']} missing values were restored by exact source record/field matches, with reviewer label, evidence row and audit timestamp. No estimated valuation was inserted.
- Field completeness changed from {m['completeness_before_pct']}% to {m['completeness_after_pct']}% across {total:,} audited cells. This is a simulation result, not a measured workplace improvement.
- {m['rejected_proposals']} unsupported proposals were rejected. {m['records_requiring_review']} records still trigger review rules; complete fields do not establish valid market evidence.

## Recommended actions
1. Investigate zero/nonpositive consideration, missing area and possible package-sale records before using them in price comparisons.
2. Verify ambiguous records against deeds and authorized independent sources; repeated price/date across parcels is a signal, not proof of a package transaction.
3. Retain unresolved gaps and existing-value conflicts in the exception queue. Do not replace missing prices with averages or carry-forward estimates.
4. Have a supervising appraiser review transaction terms and property evidence before making any valuation conclusion.

## Limits
The workflow uses one external provider, no internal Newmark database or proprietary feed. DEMO_REVIEWER is a software test identity, not professional approval. Annual sources were published after their sale periods; no contemporaneous valuation claim is made. Missingness checks and selected business flags are not comprehensive appraisal due diligence. The SQLite implementation is locally executable; the original MySQL fund example is historical material in legacy/.
'''
    (out/'reviewer_report.md').write_text(report)
    return m

def run(out):
    out=Path(out);out.mkdir(parents=True,exist_ok=True)
    db=out/'research.sqlite'
    if db.exists(): raise FileExistsError('Output database exists; choose a new --output directory to preserve its audit history')
    con=connect(db)
    try:
        initialize(con);seed_demo(con)
        before=int(quality(con).missing_fields.sum())
        for p in con.execute('SELECT proposal_id FROM proposals ORDER BY proposal_id').fetchall():
            apply_proposal(con,p[0],'DEMO_REVIEWER')
        return export(con,out,before)
    finally: con.close()

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--output',default='outputs/demo');args=p.parse_args()
    print(json.dumps(run(args.output),indent=2))

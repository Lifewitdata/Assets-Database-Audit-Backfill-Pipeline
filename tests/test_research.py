import sqlite3
import pandas as pd
import pytest
from research import connect,initialize,seed_demo,apply_proposal,quality,run,ROOT

@pytest.fixture
def db(tmp_path):
    c=connect(tmp_path/'test.sqlite');initialize(c);seed_demo(c)
    yield c
    c.close()

def test_source_row_counts_and_foreign_keys(db):
    assert db.execute('SELECT COUNT(*) FROM records').fetchone()[0]==2373
    assert db.execute('PRAGMA foreign_key_check').fetchall()==[]
    assert db.execute('SELECT COUNT(*) FROM evidence').fetchone()[0]==9492

def test_source_backed_restore_and_idempotence(db):
    assert apply_proposal(db,'DEMO-000','test reviewer')=='APPLIED'
    assert apply_proposal(db,'DEMO-000','test reviewer')=='APPLIED'
    assert db.execute('SELECT COUNT(*) FROM audit_log').fetchone()[0]==1
    assert quality(db).missing_fields.sum()==79

def test_unsupported_source_rejected(db):
    assert apply_proposal(db,'INVALID-DEMO','test reviewer')=='REJECTED'
    assert db.execute('SELECT COUNT(*) FROM audit_log').fetchone()[0]==0

@pytest.mark.parametrize('column,new_value', [('proposed_value','99999999'),('evidence_row',1),('evidence_source','WRONG')])
def test_mismatched_evidence_rejected(db,column,new_value):
    db.execute(f'UPDATE proposals SET {column}=? WHERE proposal_id=?',(new_value,'DEMO-001'));db.commit()
    assert apply_proposal(db,'DEMO-001','tester')=='REJECTED'
    assert quality(db).missing_fields.sum()==80

def test_existing_value_never_overwritten(db):
    p=db.execute("SELECT * FROM proposals WHERE proposal_id='DEMO-001'").fetchone()
    db.execute('UPDATE records SET sale_price=123 WHERE record_id=?',(p['record_id'],));db.commit()
    assert apply_proposal(db,'DEMO-001','tester')=='REJECTED'
    assert db.execute('SELECT sale_price FROM records WHERE record_id=?',(p['record_id'],)).fetchone()[0]==123

def test_failed_audit_rolls_back_data_update(db):
    db.execute("CREATE TRIGGER audit_failure BEFORE INSERT ON audit_log BEGIN SELECT RAISE(ABORT,'test failure'); END;");db.commit()
    with pytest.raises(sqlite3.IntegrityError):apply_proposal(db,'DEMO-001','tester')
    assert quality(db).missing_fields.sum()==80
    assert db.execute("SELECT status FROM proposals WHERE proposal_id='DEMO-001'").fetchone()[0]=='PENDING'

def test_reviewer_required(db):
    with pytest.raises(ValueError):apply_proposal(db,'DEMO-000','')

def test_unknown_proposal_does_not_lock_database(db):
    with pytest.raises(ValueError):apply_proposal(db,'UNKNOWN','tester')
    assert apply_proposal(db,'DEMO-000','tester')=='APPLIED'

def test_rebuild_refuses_existing_database(tmp_path):
    run(tmp_path)
    with pytest.raises(FileExistsError):run(tmp_path)

def test_complete_demo_reconciles(tmp_path):
    m=run(tmp_path)
    assert m['missing_before']==80 and m['missing_after']==0
    assert m['source_backed_updates']==80 and m['rejected_proposals']==1
    assert m['records_requiring_review']>0  # completeness != market suitability
    c=pd.read_csv(tmp_path/'coverage_by_neighborhood.csv')
    assert c.records.sum()==m['records']
    assert 'simulation' in (tmp_path/'reviewer_report.md').read_text()

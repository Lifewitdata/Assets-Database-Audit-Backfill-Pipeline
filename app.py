"""Read-only review interface; no user input is executed as SQL."""
import os
from pathlib import Path
import pandas as pd
import json
import streamlit as st

st.set_page_config(page_title='Property Research Coverage',layout='wide')
st.title('Property Research Database Coverage')
st.caption('Official Brooklyn sales • controlled gap-recovery demonstration • research support only')
out=Path(os.environ.get('PROPERTY_AUDIT_OUTPUT','outputs/demo'))
if not (out/'summary.json').exists():
    st.info('Run python research.py first.');st.stop()
m=json.loads((out/'summary.json').read_text())
st.warning('80 local gaps were deliberately introduced for testing. Recovery metrics are simulated, not workplace results or appraisal approval.')
a,b,c=st.columns(3)
a.metric('Official source records',f"{m['records']:,}")
b.metric('Source-backed recoveries',m['source_backed_updates'])
c.metric('Records needing review',m['records_requiring_review'])
t1,t2,t3,t4=st.tabs(['Coverage','Exceptions','Audit trail','Reviewer report'])
with t1:
    coverage=pd.read_csv(out/'coverage_by_neighborhood.csv')
    st.write('Completeness measures populated fields, not transaction validity.')
    st.bar_chart(coverage.groupby('neighborhood')[['records']].sum())
    st.dataframe(coverage,hide_index=True)
with t2:
    d=pd.read_csv(out/'record_quality.csv')
    area=st.selectbox('Neighborhood',['All']+sorted(d.neighborhood.unique().tolist()))
    d=d[d.requires_review]
    if area!='All':d=d[d.neighborhood.eq(area)]
    st.dataframe(d,hide_index=True)
    st.download_button('Download selected exceptions',d.to_csv(index=False),'exceptions.csv','text/csv')
with t3:
    st.subheader('Applied updates — demonstration reviewer identity')
    st.dataframe(pd.read_csv(out/'audit_log.csv'),hide_index=True)
    st.subheader('Proposal outcomes')
    st.dataframe(pd.read_csv(out/'proposals.csv'),hide_index=True)
with t4:
    report=(out/'reviewer_report.md').read_text();st.markdown(report)
    st.download_button('Download reviewer brief',report,'reviewer_report.md')

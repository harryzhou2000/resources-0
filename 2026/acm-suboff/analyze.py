"""Post-process archived VTKHDF and history files; run with DNDSR root as cwd."""
from pathlib import Path
import csv, json, shutil, gzip
import numpy as np, h5py, pandas as pd
root=Path(__file__).resolve().parent
runs=Path('data/outUnsteady/Cauchy')
cases={'P1':next(runs.glob('SUBOFF_P1_AMGX/20261120T104036*')),'P2':next(runs.glob('20261120T164500*'))}
cases['P1 flux']=runs/'SUBOFF_P1_AMGX/p1-wall-fields-6000/solver-center'
results=[]
for typ in ['Cp','Cf']:
 ref=pd.read_csv(next((root/'reference').glob(typ.lower()+'_*')),comment='#')
 for name,run in cases.items():
    filename='run-D0-S1_0_4000_bnd.vtkhdf'
    if name=='P1 flux': filename='p1-D0-final_bnd.vtkhdf'
    if (name=='P1 flux' and typ=='Cp'): continue
    with h5py.File(run/filename) as f:
     g=f['VTKHDF'];a=g['CellData']; coords=g['Points'][:];off=g['Offsets'][:];con=g['Connectivity'][:]
     xyz=np.add.reduceat(coords[con],off[:-1],axis=0)/np.diff(off)[:,None]
     zone=a['bnd_zone_id'][:];sel=(zone==3)&(xyz[:,2]>0)&(abs(np.arctan2(xyz[:,1],xyz[:,2]))<np.deg2rad(5))
     v=np.column_stack([a[k][:] for k in 'uvw']);normal=a['norm'][:];normal/=np.linalg.norm(normal,axis=1)[:,None]
     ut=v-(v*normal).sum(1)[:,None]*normal
     val=2*a['p'][:] if typ=='Cp' else np.divide(2*np.linalg.norm(ut,axis=1)/12e6,a['wall_distance_cell_center'][:],out=np.zeros(len(v)),where=a['wall_distance_cell_center'][:]>0)
     if name=='P1 flux': val=2*np.linalg.norm(a['force_tangential'][:],axis=1)
     for x,y in ref.values:
      if .212 <= x <= .297 or .874 <= x <= .921: continue
      idx=sel & (abs(xyz[:,0]-x)<=.005)
      if idx.sum()==0: continue
      z=np.median(val[idx]);results.append((name,typ,x,y,z,idx.sum()))
df=pd.DataFrame(results,columns=['case','quantity','x_L','experiment','cauchy','faces']);df.to_csv(root/'evidence/meridian.csv',index=False)
print(df.assign(err=df.cauchy-df.experiment).groupby(['case','quantity']).err.agg(['mean',lambda v:np.mean(abs(v))]))
print(df[df.case=='P2'].to_string(index=False))

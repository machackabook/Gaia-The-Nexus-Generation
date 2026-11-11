#!/usr/bin/env python3
"""Read-only recovered artifact inventory. Does not copy or upload contents."""
import argparse, hashlib, json, pathlib, sys
EXT={'.py','.js','.ts','.tsx','.html','.css','.json','.md','.txt','.sh','.ps1','.yml','.yaml','.zip','.pdf','.mhtml'}
MAX=1024*1024*1024
def sha256(path):
    h=hashlib.sha256()
    with path.open('rb') as f:
        for block in iter(lambda:f.read(1024*1024),b''): h.update(block)
    return h.hexdigest()
def main():
    p=argparse.ArgumentParser()
    p.add_argument('root',type=pathlib.Path)
    p.add_argument('--output',type=pathlib.Path)
    args=p.parse_args()
    root=args.root.resolve(strict=True)
    if not root.is_dir(): p.error('root must be a directory')
    rows=[]
    for file in sorted(root.rglob('*')):
        if file.is_symlink() or not file.is_file() or file.suffix.lower() not in EXT: continue
        rel=file.relative_to(root)
        if any(x in {'.git','node_modules','.venv','venv','.ssh','.aws','.config'} for x in rel.parts):continue
        stat=file.stat()
        if stat.st_size>MAX: rows.append({'path':str(rel),'status':'SKIPPED_TOO_LARGE'});continue
        rows.append({'path':str(rel),'size':stat.st_size,'sha256':sha256(file),'status':'UNREVIEWED'})
    report={'schema':1,'root_redacted':True,'count':len(rows),'artifacts':rows}
    content=json.dumps(report,indent=2)+'\n'
    if args.output:
        args.output.parent.mkdir(parents=True,exist_ok=True)
        args.output.write_text(content)
        try: args.output.chmod(0o600)
        except OSError: pass
        print('Inventory saved locally:',args.output)
    else: print(content)
if __name__=='__main__':main()

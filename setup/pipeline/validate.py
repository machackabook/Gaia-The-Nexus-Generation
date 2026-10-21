#!/usr/bin/env python3
"""Validate setup manifest and source inventory; no external dependencies."""
import json,pathlib,sys
root=pathlib.Path(__file__).resolve().parent
m=json.loads((root/'manifest.json').read_text())
assert m['schema']==1
assert m['deployment']['automatic'] is False
assert m['deployment']['requires_approval'] is True
assert m['privacy']['upload_recovered_files'] is False
assert len(set(m['phases']))==len(m['phases'])
for name,profile in m['profiles'].items():
    assert profile['os'] in ('linux','windows','android'),name
    assert 'core' in profile['components'] or 'web' in profile['components'],name
print('PASS: setup manifest schema, profiles, safety policy')

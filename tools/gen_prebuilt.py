#!/usr/bin/env python3
"""Regenerate tools/prebuilt/*.json from src/ (needs devkitPPC and the retail DOLs).

    PO_DOLS=/path/with/R7PE01.dol,R7PP01.dol,R7PJ01.dol  python3 tools/gen_prebuilt.py [gc|cc ...]

Each retail DOL can instead be given as PO_DOL_<ID>.  The JSON is what the
patcher ships and reads; end users do not need devkitPPC or any game files here.
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, '..', 'src'))
from dol import Dol
from features import PREBUILT, dump
from regions import REGIONS


def dol_for(region):
    env = os.environ.get('PO_DOL_' + region)
    if env:
        return Dol(env)
    base = os.environ.get('PO_DOLS')
    if base:
        p = os.path.join(base, region + '.dol')
        if os.path.exists(p):
            return Dol(p)
    sys.exit('set PO_DOLS=<dir with %s.dol> or PO_DOL_%s=<path>' % (region, region))


def main(argv):
    which = argv or ['gc', 'cc']
    os.makedirs(PREBUILT, exist_ok=True)
    for name in which:
        mod = __import__('gen_po')
        mod.USA_DOL = dol_for('R7PE01')
        for region in REGIONS:
            f = getattr(mod, 'build_' + name)(region, dol_for(region))
            path = os.path.join(PREBUILT, '%s_%s.json' % (name, region))
            with open(path, 'w') as fh:
                json.dump(dump(f), fh, indent=1)
                fh.write('\n')
            print('%-3s %s  %d ops -> %s' % (name, region, len(f.ops), os.path.relpath(path)))


if __name__ == '__main__':
    main(sys.argv[1:])

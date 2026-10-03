"""The retail releases of Punch-Out!! (Wii) and which discs share a main.dol.

Each region has one main.dol; the revision-1 discs (USA, Europe/Australia) carry the
same executable as revision 0, so a disc is accepted for any of its listed versions.
"""
REGIONS = {
    'R7PE01': dict(label='Punch-Out!! (USA)', short='USA', versions=(0, 1)),
    'R7PP01': dict(label='Punch-Out!! (Europe/Australia)', short='Europe', versions=(0, 1)),
    'R7PJ01': dict(label='Punch-Out!! (Japan)', short='Japan', versions=(1,)),
}

# retail DOL sizes, to give a clear error on someone else's modified dump
DOL_SIZES = {'R7PE01': 3599168, 'R7PP01': 3605792, 'R7PJ01': 3603072}

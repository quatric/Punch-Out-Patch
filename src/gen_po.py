"""Build the Classic Controller (cc) and GameCube controller (gc) features for one region."""
import os, struct, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', 'tools'))
import asm
from layout import GC_BASE, GC_END, CC_BASE, CC_END
from ops import Feature, Hook, Patch
from sig import find_unique

# USA (R7PE01) sites; the other regions are found by signature search
READ_AFTER = (0x801B06B4, 6, 6)      # lbz r0,233(r1) after the core-format WPADRead
READ_BTN = (0x801B06C4, 6, 6)        # lhz r0,192(r1): the remote's button word
TYPE_FLAG = (0x801B0554, 6, 6)       # lbz r0,957(r24): "treat a Classic as a plain remote"
KPAD_CC = (0x801B0794, 6, 6)         # lwz r3,240(r1) after the core-path KPADRead
KPAD_GC = (0x801B0798, 6, 6)         # add r7,r24,r27 (the next instruction)
SETFMT = (0x802187C8, 0, 8)          # WPADSetDataFormat
USA_DOL = None


def _read(name):
    return open(os.path.join(HERE, name)).read()


def _bl_target(dol, at):
    w = struct.unpack('>I', dol.read(at, 4))[0]
    li = w & 0x03FFFFFC
    if li & 0x02000000:
        li -= 0x04000000
    return (at + li) & 0xFFFFFFFF


def _sites(region, dol):
    usa = USA_DOL
    f = (lambda s: s[0]) if region == 'R7PE01' else (lambda s: find_unique(usa, dol, *s))
    return f(READ_AFTER), f(READ_BTN), f(TYPE_FLAG), f(SETFMT), f(KPAD_CC), f(KPAD_GC)


def build_cc(region, dol):
    after, _btn, flag, setfmt, kcc, _kgc = _sites(region, dol)
    orig = struct.unpack('>I', dol.read(after, 4))[0]
    assert orig == 0x880100E9, hex(orig)
    body = asm.words(asm.assemble(_read('cc_read.s'), CC_BASE, {'SETFMT': setfmt})) + [0]
    ptr = asm.words(asm.assemble(_read('cc_ptr.s'), CC_BASE + ((len(body) * 4 + 15) & ~15))) + [0]
    porig = struct.unpack('>I', dol.read(kcc, 4))[0]
    assert porig == 0x806100F0, hex(porig)
    ops = [Patch(flag, struct.pack('>I', 0x38000001), dol.read(flag, 4),
                 note='extension check: let a Classic Controller take the Wii Remote path'),
           Hook(after, orig, body, CC_BASE, note='pad update: Classic Controller buttons -> Wii Remote bits'),
           Hook(kcc, porig, ptr, CC_BASE + ((len(body) * 4 + 15) & ~15),
                note='pad update: right stick steers the pointer')]
    if CC_BASE + ((len(body) * 4 + 15) & ~15) + len(ptr) * 4 > CC_END:
        raise SystemExit('cc code overflows its window')
    return Feature('cc', 'Classic Controller', region, ops)


def build_gc(region, dol):
    _after, btn, _flag, _s, _kcc, kgc = _sites(region, dol)
    orig = struct.unpack('>I', dol.read(btn, 4))[0]
    assert orig == 0xA00100C0, hex(orig)
    body = asm.words(asm.assemble(_read('gc_buttons.s'), GC_BASE)) + [0]
    if GC_BASE + len(body) * 4 > GC_END:
        raise SystemExit('gc code overflows its window')
    ptr = asm.words(asm.assemble(_read('gc_ptr.s'), GC_BASE + ((len(body) * 4 + 15) & ~15))) + [0]
    porig = struct.unpack('>I', dol.read(kgc, 4))[0]
    assert porig == 0x7CF8DA14, hex(porig)
    ptr_at = GC_BASE + ((len(body) * 4 + 15) & ~15)
    if ptr_at + len(ptr) * 4 > GC_END:
        raise SystemExit('gc code overflows its window')
    return Feature('gc', 'GameCube controller', region,
                   [Hook(btn, orig, body, GC_BASE, note='pad update: GameCube buttons -> Wii Remote bits'),
                    Hook(kgc, porig, ptr, ptr_at, note='pad update: C-stick steers the pointer')])

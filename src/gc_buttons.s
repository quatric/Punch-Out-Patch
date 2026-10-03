# hook: `lhz r0,0xC0(r1)` in the core path of the pad update -- loads the remote's
# button word (r25 = channel).  OR in the GameCube pad on the same channel.
#
# The SI hardware polls the pads and mirrors the answer into SICnINBUFH
# (0xCD006404 + 12*chan): [31] error, [23] always 1 on a real pad response,
# [29:16] the PAD button word (A 0x100 B 0x200 X 0x400 Y 0x800 Start 0x1000
# L 0x40 R 0x20 Z 0x10 Up 8 Down 4 Right 2 Left 1).  The remote is treated as held
# sideways, so the d-pad is rotated: pad left = remote UP, right = DOWN, up = RIGHT,
# down = LEFT.  The control stick acts as the d-pad too.
    lhz     0, 192(1)                   # displaced instruction
    cmplwi  25, 3
    bgt     9f
    mulli   5, 25, 12
    lis     6, 0xCD00
    add     6, 6, 5
    lwz     8, 0x6404(6)
    cmpwi   8, 0
    blt     9f                          # error / no pad
    andis.  9, 8, 0x0080
    beq     9f                          # not a pad response
    srwi    9, 8, 16                    # PAD buttons
    li      10, 0
    andi.   11, 9, 0x0200               # B -> 1
    beq     2f
    ori     10, 10, 0x0200
2:  andi.   11, 9, 0x0100               # A -> 2
    beq     2f
    ori     10, 10, 0x0100
2:  andi.   11, 9, 0x0800               # Y -> B
    beq     2f
    ori     10, 10, 0x0400
2:  andi.   11, 9, 0x0400               # X -> A
    beq     2f
    ori     10, 10, 0x0800
2:  andi.   11, 9, 0x1000               # Start -> +
    beq     2f
    ori     10, 10, 0x0010
2:  andi.   11, 9, 0x0010               # Z -> HOME
    beq     2f
    ori     10, 10, 0x8000
2:  andi.   11, 9, 0x0001               # d-pad left  -> remote UP
    beq     2f
    ori     10, 10, 0x0008
2:  andi.   11, 9, 0x0002               # d-pad right -> remote DOWN
    beq     2f
    ori     10, 10, 0x0004
2:  andi.   11, 9, 0x0004               # d-pad down  -> remote LEFT
    beq     2f
    ori     10, 10, 0x0001
2:  andi.   11, 9, 0x0008               # d-pad up    -> remote RIGHT
    beq     2f
    ori     10, 10, 0x0002
2:  rlwinm  11, 8, 24, 24, 31           # control stick X (u8, 128 = centre)
    cmplwi  11, 128+40
    ble     2f
    ori     10, 10, 0x0004              # right -> remote DOWN
2:  cmplwi  11, 128-40
    bge     2f
    ori     10, 10, 0x0008              # left  -> remote UP
2:  rlwinm  11, 8, 0, 24, 31            # control stick Y
    cmplwi  11, 128+40
    ble     2f
    ori     10, 10, 0x0002              # up    -> remote RIGHT
2:  cmplwi  11, 128-40
    bge     2f
    ori     10, 10, 0x0001              # down  -> remote LEFT
2:  or      0, 0, 10
9:

# hook: right after the core-format WPADRead in the game's pad update (the path a
# plain Wii Remote takes).  r25 = channel, the read buffer is at 0xC0(r1), the raw
# extension type the game probed is at 8(r1).
#
# A Classic Controller is made to take this same path (see the retail patch at the
# type check), so the game treats it exactly like a Wii Remote held sideways.  To get
# the Classic's own buttons the remote is switched to the Classic data format (8) while
# one is attached, and back to the core format (2) otherwise; WPADSetDataFormat does
# nothing when the format already matches, so asking every frame is cheap.  The
# Classic's buttons (buffer+0x2A) are then mapped onto the remote bits.
    stwu    1, -32(1)
    mflr    0
    stw     0, 36(1)
    lwz     5, 40(1)                    # raw extension type
    li      4, 2
    cmpwi   5, 2
    bne     1f
    li      4, 8
1:  mr      3, 25
    lis     12, SETFMT@ha
    addi    12, 12, SETFMT@l
    mtctr   12
    bctrl
    lwz     5, 40(1)
    cmpwi   5, 2
    bne     9f
    lhz     6, 234+32(1)                # classic buttons
    lhz     7, 192+32(1)                # remote buttons
    # --- face / shoulder buttons -------------------------------------------
    li      8, 0
    andi.   9, 6, 0x0040                # B
    beq     2f
    ori     8, 8, 0x0200                # -> 1
2:  andi.   9, 6, 0x0010                # A
    beq     2f
    ori     8, 8, 0x0100                # -> 2
2:  andi.   9, 6, 0x0020                # Y
    beq     2f
    ori     8, 8, 0x0400                # -> B
2:  andi.   9, 6, 0x0008                # X
    beq     2f
    ori     8, 8, 0x0800                # -> A
2:  andi.   9, 6, 0x0400                # +
    beq     2f
    ori     8, 8, 0x0010                # -> +
2:  andi.   9, 6, 0x1000                # -
    beq     2f
    ori     8, 8, 0x1000                # -> -
2:  andi.   9, 6, 0x0800                # HOME
    beq     2f
    ori     8, 8, 0x8000                # -> HOME
    # --- d-pad ---------------------------------------------------------------
2:  andi.   9, 6, 0x0002                # d-pad left  -> remote UP    (sideways: left)
    beq     2f
    ori     8, 8, 0x0008
2:  andi.   9, 6, 0x8000                # d-pad right -> remote DOWN  (sideways: right)
    beq     2f
    ori     8, 8, 0x0004
2:  andi.   9, 6, 0x4000                # d-pad down  -> remote LEFT  (sideways: down)
    beq     2f
    ori     8, 8, 0x0001
2:  andi.   9, 6, 0x0001                # d-pad up    -> remote RIGHT (sideways: up)
    beq     2f
    ori     8, 8, 0x0002
2:  or      7, 7, 8
    sth     7, 192+32(1)
9:  lwz     0, 36(1)
    mtlr    0
    addi    1, 1, 32
    lbz     0, 233(1)                   # displaced instruction

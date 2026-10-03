# f1 = stick X (+ right), f2 = stick Y (+ up), already read by the caller.  The KPAD
# status the game just read is at 0xF0(r1): pos at +0x20/+0x24, dpd_valid_fg at +0x5E.
# r7 = the game's per-channel copy of the previous frame (pos at +0x58/+0x5C).
#
# While the stick is held it steers the pointer (from where it was); with the stick
# at rest a real IR pointer is left alone, and when there is none (the remote is in
# the controller, not aimed at the screen) the last pointer stays on screen.
    stwu    1, -32(1)
    lis     5, 0x3e4c                   # dead zone 0.2
    ori     5, 5, 0xcccd
    stw     5, 8(1)
    lfs     3, 8(1)
    lis     5, 0x3d23                   # speed 0.04 per frame at full tilt
    ori     5, 5, 0xd70a
    stw     5, 8(1)
    lfs     4, 8(1)
    lis     5, 0x3f80                   # 1.0
    stw     5, 8(1)
    lfs     5, 8(1)
    fsubs   10, 5, 5                    # 0.0
    fneg    6, 5                        # -1.0
    fabs    7, 1
    fabs    8, 2
    fsubs   7, 7, 3
    fsubs   8, 8, 3
    fsel    1, 7, 1, 10                 # |x| > dead zone ? x : 0
    fsel    2, 8, 2, 10
    lfs     11, 0x58(7)                 # previous pointer
    lfs     12, 0x5c(7)
    fcmpu   0, 1, 10
    bne     3f
    fcmpu   0, 2, 10
    bne     3f
    lbz     0, 0x5e+0xf0+32(1)          # dpd_valid_fg
    cmpwi   0, 0
    bne     9f                          # a real pointer is there: leave it
    stfs    11, 0x20+0xf0+32(1)
    stfs    12, 0x24+0xf0+32(1)
    b       4f
3:  fmadds  11, 1, 4, 11                # x += stickX * speed
    fnmsubs 12, 2, 4, 12                # y -= stickY * speed  (pointer y grows downward)
    fsubs   13, 5, 11                   # clamp to [-1, 1]
    fsel    11, 13, 11, 5
    fsubs   13, 11, 6
    fsel    11, 13, 11, 6
    fsubs   13, 5, 12
    fsel    12, 13, 12, 5
    fsubs   13, 12, 6
    fsel    12, 13, 12, 6
    stfs    11, 0x20+0xf0+32(1)
    stfs    12, 0x24+0xf0+32(1)
4:  li      0, 1
    stb     0, 0x5e+0xf0+32(1)
9:  addi    1, 1, 32

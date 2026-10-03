# How the patches work

Everything here was found by reading the retail `main.dol` files in Ghidra and
checked by running them in Dolphin with scripted input (a named pipe as the
controller, memory reads over Dolphin's GDB stub, screenshots).

## The game's pad code

Punch-Out!! (Wii) does not use the KPAD button word the way most games do. It has
its own pad manager (one object, one 0xE8-byte record per channel) that is updated
once per frame by a function of about 3 KB (USA `0x801B04A4`, called per channel):

1. `WPADProbe` tells it what is plugged into the remote: none, Nunchuk, Classic
   Controller, Balance Board.
2. It asks for the data format that matches (`WPADSetDataFormat`: 2 for a bare
   remote, 5 Nunchuk, 8 Classic, 12 Balance Board), reads it with `WPADRead`, then
   reads the pointer/accelerometer state with `KPADRead`, and copies both into the
   channel's record. The record's *kind* (1 remote, 2 Nunchuk, 3 Classic, 4 Balance
   Board) picks the controller class that turns it into fight input.
3. The Classic Controller class exists but is switched off by two flags the manager
   clears at start-up, so a Classic Controller is treated as unusable and the game
   asks for another controller.

A bare Wii Remote therefore takes the *kind 1* path, and that path is what the game
plays with the remote held sideways (D-pad, 1, 2, A, B, +).

## Classic Controller (`cc`)

Three changes, all in that update function:

| Where | What |
| --- | --- |
| `lbz r0,957(r24)` (the "ignore a Classic Controller" flag) | `li r0,1`, so a Classic Controller is reported as a plain remote and takes the kind 1 path |
| `lbz r0,233(r1)` right after the kind 1 `WPADRead` | calls `WPADSetDataFormat` with 8 while a Classic Controller is attached (2 otherwise; the call does nothing when the format already matches), then ORs the Classic's buttons, mapped to remote bits, into the button word of the buffer it just read |
| `lwz r3,240(r1)` right after the `KPADRead` | the left stick sets the D-pad bits in the channel's record, and the right stick steers the pointer |

The pointer is the part the game needs for menus: with the remote in the controller
no IR pointer exists. While the right stick is held, the pointer starts from where
it was and moves at 0.04 of the screen per frame; with the stick at rest a real IR
pointer is left alone, and if there is none the last pointer stays on screen.

## GameCube controller (`gc`)

The Wii's SI hardware polls the pads by itself and mirrors the answer into
`0xCD006400 + 12*channel` (`SICnINBUFH`, `SICnINBUFL`). The hooks read that directly,
so no game or SDK code is involved:

| Where | What |
| --- | --- |
| `lhz r0,192(r1)` (the remote's button word in the kind 1 path) | ORs the pad's buttons, mapped to remote bits, into it; the control stick acts as the D-pad |
| `add r7,r24,r27` after the `KPADRead` | the C-stick steers the pointer (same routine as the Classic) |

Channel *n* of the pad drives player *n*; a Wii Remote must still be connected for
the game to run its pad update for that channel.

## Layout

Hooks replace one instruction with a branch to a trampoline that runs the displaced
instruction and branches back. The trampolines live in a text section added at
`0x80001820` (the Wii's low-memory scratch area, which the game never touches);
`tools/layout.py` gives each feature a window. The same operations are emitted three
ways so they cannot drift apart: a patched `main.dol`, Gecko codes (`C2`/`04`/`06`)
and a Riivolution patch.

The USA addresses above are the reference; the other regions' sites are found by a
masked instruction-signature search at build time (`tools/sig.py`), and
`tools/verify.py` re-checks every site against the real DOLs.

## Revisions

Each region has one `main.dol`: the revision 1 discs of the USA and Europe/Australia
releases carry the same executable as revision 0, so the patcher accepts any of them.

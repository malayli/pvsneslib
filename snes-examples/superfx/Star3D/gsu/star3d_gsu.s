;---------------------------------------------------------------------------------
; Star3D GSU program.
;
; Projects a static wireframe cube (rotated 35 degrees around Y) and plots its
; 12 edges into the Super FX plot buffer. Runs once (launched by src/star3d.c,
; PBR=1/R15=0) then STOPs; the 65816 side DMAs the resulting buffer to VRAM.
;
; Placed at ROM bank 1 (see hdr.asm) to match the PBR value the CPU side
; writes before launching the GSU.
;
; All projection math (rotation, screen-space vertex coordinates, and the
; classification of each edge as horizontal/vertical/diagonal) is baked in at
; assembly time for this one fixed 35 degree rotation - there is no runtime
; trigonometry beyond the two FMULTs per vertex.
;---------------------------------------------------------------------------------

; must match hdr.asm exactly - wlalink requires every linked object to declare
; the same memory architecture.
.MEMORYMAP
  SLOTSIZE $8000
  DEFAULTSLOT 0
  SLOT 0 $8000
  SLOT 1 $0 $2000
  SLOT 2 $2000 $E000
  SLOT 3 $0 $10000
.ENDME

.ROMBANKSIZE $8000
.ROMBANKS 8

; scratch tables in GSU RAM, right above the 16KB ($0000-$3FFF) plot buffer
.DEFINE X_TABLE_BASE $4000
.DEFINE Y_TABLE_BASE $4008

.DEFINE CENTER_X 128
.DEFINE CENTER_Y 64

; cos(35deg)*32768, sin(35deg)*32768, Q15 fixed point
.DEFINE COS_Q15 $68DA
.DEFINE SIN_Q15 $496B

.BANK 1 SLOT 0
.ORG $0000
.SECTION "GSUCODE" FORCE

gsu_program:
    cache

    ; color = 1 (white index), set once
    iwt r0,#1
    color

    ; hoist constants: R3=128 (center X), R7=64 (center Y)
    iwt r3,#CENTER_X
    iwt r7,#CENTER_Y

    ; table address pointers
    iwt r9,#X_TABLE_BASE
    iwt r10,#Y_TABLE_BASE

    ; the code cache only covers 512 bytes from the last CACHE call - this
    ; program is much longer than that, so re-issue CACHE at the start of
    ; every vertex/edge block (each block is well under 512 bytes on its own).
    ; --- vertex 0: vx=-32 vy=-32 vz=-32 -> screenX=82 screenY=77 ---
    cache
    iwt r0,#$FFC0
    iwt r1,#$FFC0
    iwt r6,#COS_Q15
    with r0
    fmult
    iwt r6,#SIN_Q15
    with r1
    fmult
    add r1
    add r3
    move r5,r0
    move r0,r7
    iwt r4,#$FFE0
    sub r4
    add r1
    with r5
    stb (r9)
    inc r9
    with r0
    stb (r10)
    inc r10

    ; --- vertex 1: vx=32 vy=-32 vz=-32 -> screenX=135 screenY=77 ---
    cache
    iwt r0,#$0040
    iwt r1,#$FFC0
    iwt r6,#COS_Q15
    with r0
    fmult
    iwt r6,#SIN_Q15
    with r1
    fmult
    add r1
    add r3
    move r5,r0
    move r0,r7
    iwt r4,#$FFE0
    sub r4
    add r1
    with r5
    stb (r9)
    inc r9
    with r0
    stb (r10)
    inc r10

    ; --- vertex 2: vx=32 vy=32 vz=-32 -> screenX=135 screenY=13 ---
    cache
    iwt r0,#$0040
    iwt r1,#$FFC0
    iwt r6,#COS_Q15
    with r0
    fmult
    iwt r6,#SIN_Q15
    with r1
    fmult
    add r1
    add r3
    move r5,r0
    move r0,r7
    iwt r4,#$0020
    sub r4
    add r1
    with r5
    stb (r9)
    inc r9
    with r0
    stb (r10)
    inc r10

    ; --- vertex 3: vx=-32 vy=32 vz=-32 -> screenX=82 screenY=13 ---
    cache
    iwt r0,#$FFC0
    iwt r1,#$FFC0
    iwt r6,#COS_Q15
    with r0
    fmult
    iwt r6,#SIN_Q15
    with r1
    fmult
    add r1
    add r3
    move r5,r0
    move r0,r7
    iwt r4,#$0020
    sub r4
    add r1
    with r5
    stb (r9)
    inc r9
    with r0
    stb (r10)
    inc r10

    ; --- vertex 4: vx=-32 vy=-32 vz=32 -> screenX=119 screenY=114 ---
    cache
    iwt r0,#$FFC0
    iwt r1,#$0040
    iwt r6,#COS_Q15
    with r0
    fmult
    iwt r6,#SIN_Q15
    with r1
    fmult
    add r1
    add r3
    move r5,r0
    move r0,r7
    iwt r4,#$FFE0
    sub r4
    add r1
    with r5
    stb (r9)
    inc r9
    with r0
    stb (r10)
    inc r10

    ; --- vertex 5: vx=32 vy=-32 vz=32 -> screenX=172 screenY=114 ---
    cache
    iwt r0,#$0040
    iwt r1,#$0040
    iwt r6,#COS_Q15
    with r0
    fmult
    iwt r6,#SIN_Q15
    with r1
    fmult
    add r1
    add r3
    move r5,r0
    move r0,r7
    iwt r4,#$FFE0
    sub r4
    add r1
    with r5
    stb (r9)
    inc r9
    with r0
    stb (r10)
    inc r10

    ; --- vertex 6: vx=32 vy=32 vz=32 -> screenX=172 screenY=50 ---
    cache
    iwt r0,#$0040
    iwt r1,#$0040
    iwt r6,#COS_Q15
    with r0
    fmult
    iwt r6,#SIN_Q15
    with r1
    fmult
    add r1
    add r3
    move r5,r0
    move r0,r7
    iwt r4,#$0020
    sub r4
    add r1
    with r5
    stb (r9)
    inc r9
    with r0
    stb (r10)
    inc r10

    ; --- vertex 7: vx=-32 vy=32 vz=32 -> screenX=119 screenY=50 ---
    cache
    iwt r0,#$FFC0
    iwt r1,#$0040
    iwt r6,#COS_Q15
    with r0
    fmult
    iwt r6,#SIN_Q15
    with r1
    fmult
    add r1
    add r3
    move r5,r0
    move r0,r7
    iwt r4,#$0020
    sub r4
    add r1
    with r5
    stb (r9)
    inc r9
    with r0
    stb (r10)
    inc r10

    ;-----------------------------------------------------------------
    ; edges - screenX/screenY table indices: 0..7 match the vertices above
    ;-----------------------------------------------------------------

    ; H edge 0->1 (y=77 fixed, x 82..135, 54 pixels)
    cache
    iwt r8,#Y_TABLE_BASE+0
    with r2
    ldb (r8)
    iwt r8,#X_TABLE_BASE+0
    with r1
    ldb (r8)
    .REPT 54
    plot
    .ENDR

    ; V edge 2->1 (x=135 fixed, y 13..77, 65 pixels)
    cache
    iwt r8,#X_TABLE_BASE+2
    with r1
    ldb (r8)
    iwt r8,#Y_TABLE_BASE+2
    with r2
    ldb (r8)
    .REPT 65
    plot
    dec r1
    inc r2
    .ENDR

    ; H edge 3->2 (y=13 fixed, x 82..135, 54 pixels)
    cache
    iwt r8,#Y_TABLE_BASE+3
    with r2
    ldb (r8)
    iwt r8,#X_TABLE_BASE+3
    with r1
    ldb (r8)
    .REPT 54
    plot
    .ENDR

    ; V edge 3->0 (x=82 fixed, y 13..77, 65 pixels)
    cache
    iwt r8,#X_TABLE_BASE+3
    with r1
    ldb (r8)
    iwt r8,#Y_TABLE_BASE+3
    with r2
    ldb (r8)
    .REPT 65
    plot
    dec r1
    inc r2
    .ENDR

    ; H edge 4->5 (y=114 fixed, x 119..172, 54 pixels)
    cache
    iwt r8,#Y_TABLE_BASE+4
    with r2
    ldb (r8)
    iwt r8,#X_TABLE_BASE+4
    with r1
    ldb (r8)
    .REPT 54
    plot
    .ENDR

    ; V edge 6->5 (x=172 fixed, y 50..114, 65 pixels)
    cache
    iwt r8,#X_TABLE_BASE+6
    with r1
    ldb (r8)
    iwt r8,#Y_TABLE_BASE+6
    with r2
    ldb (r8)
    .REPT 65
    plot
    dec r1
    inc r2
    .ENDR

    ; H edge 7->6 (y=50 fixed, x 119..172, 54 pixels)
    cache
    iwt r8,#Y_TABLE_BASE+7
    with r2
    ldb (r8)
    iwt r8,#X_TABLE_BASE+7
    with r1
    ldb (r8)
    .REPT 54
    plot
    .ENDR

    ; V edge 7->4 (x=119 fixed, y 50..114, 65 pixels)
    cache
    iwt r8,#X_TABLE_BASE+7
    with r1
    ldb (r8)
    iwt r8,#Y_TABLE_BASE+7
    with r2
    ldb (r8)
    .REPT 65
    plot
    dec r1
    inc r2
    .ENDR

    ; D45 edge 0->4 (x 82..119, y 77..114, 38 pixels)
    cache
    iwt r8,#X_TABLE_BASE+0
    with r1
    ldb (r8)
    iwt r8,#Y_TABLE_BASE+0
    with r2
    ldb (r8)
    .REPT 38
    plot
    inc r2
    .ENDR

    ; D45 edge 1->5 (x 135..172, y 77..114, 38 pixels)
    cache
    iwt r8,#X_TABLE_BASE+1
    with r1
    ldb (r8)
    iwt r8,#Y_TABLE_BASE+1
    with r2
    ldb (r8)
    .REPT 38
    plot
    inc r2
    .ENDR

    ; D45 edge 2->6 (x 135..172, y 13..50, 38 pixels)
    cache
    iwt r8,#X_TABLE_BASE+2
    with r1
    ldb (r8)
    iwt r8,#Y_TABLE_BASE+2
    with r2
    ldb (r8)
    .REPT 38
    plot
    inc r2
    .ENDR

    ; D45 edge 3->7 (x 82..119, y 13..50, 38 pixels)
    cache
    iwt r8,#X_TABLE_BASE+3
    with r1
    ldb (r8)
    iwt r8,#Y_TABLE_BASE+3
    with r2
    ldb (r8)
    .REPT 38
    plot
    inc r2
    .ENDR

    stop

.ENDS

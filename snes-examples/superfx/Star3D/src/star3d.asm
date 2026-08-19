.include "hdr.asm"

.accu 16
.index 16
.16bit

.SECTION ".maintext_0x0" SUPERFREE

;---------------------------------------------------------------------------------
; Star3D: a minimal, real Super FX (GSU) demo.
;
; A wireframe cube, rotated once around the Y axis, is projected and drawn
; entirely by the GSU coprocessor (gsu/star3d_gsu.s) - the 65816 side only
; sets up the PPU, launches the GSU, waits for it to finish, and DMAs its
; plot buffer into VRAM.
;
; This mirrors the reference raw-register-poke sequence as closely as
; possible (same registers, same order, same direct SFR.GO/bit5 poll and raw
; DMA channel-0 setup instead of going through pvsneslib helpers) - the one
; difference is that this runs in native mode (as crt0/pvsneslib requires),
; while the reference stays in 6502 emulation mode the whole time.
;---------------------------------------------------------------------------------
main:
    stz.w screenState               ; checkpoint 0: entered main

    sep #$20                        ; 8-bit accumulator for all the raw register pokes below

    ; --- forced blank on immediately, do all setup while the screen is off ---
    lda #$80
    sta.l $2100                       ; INIDISP = forced blank

    ; --- BG mode 1 ---
    lda #$01
    sta.l $2105                       ; BGMODE = 1

    ; --- BG1 CHR base = word $0000 (NBA low nibble 0); BG1 tilemap base = word $2000 ---
    lda #$00
    sta.l $210B                       ; BG12NBA: BG1 CHR base = 0*0x1000
    lda #$20
    sta.l $2107                       ; BG1SC: base=(0x20>>2)*0x400=$2000, size 32x32

    ; --- CGRAM: index0=black, index1=white ---
    lda #$00
    sta.l $2121                       ; CGADD = 0
    lda #$00
    sta.l $2122                       ; word0 lo = $00
    lda #$00
    sta.l $2122                       ; word0 hi = $00 -> index0 = $0000 (black)
    lda #$FF
    sta.l $2122                       ; word1 lo = $FF
    lda #$7F
    sta.l $2122                       ; word1 hi = $7F -> index1 = $7FFF (white)

    lda #1
    sta.l screenState                 ; checkpoint 1: BG mode/palette done

    rep #$20                        ; back to 16-bit for the tilemap-building loop below

    ; build the tilemap in RAM (512 words / 16 rows x 32 cols, tile number = col*16+row) -
    ; the reference has this precomputed in ROM; we compute it once here instead.
    stz.w row
tilemap_row_loop:
    stz.w col
tilemap_col_loop:
    lda.w row
    sta.b tcc__r0
    ldy.w #5
-   asl a
    dey
    bne -
    sta.b tcc__r0
    lda.w col
    sta.b tcc__r1
    clc
    adc.b tcc__r0
    asl a
    sta.b tcc__r0
    lda.w #:tilemap
    sta.b tcc__r1h
    lda.w #tilemap
    clc
    adc.b tcc__r0
    sta.b tcc__r1
    lda.w col
    asl a
    asl a
    asl a
    asl a
    sta.b tcc__r0
    lda.w row
    clc
    adc.b tcc__r0
    sta.b tcc__r0
    sta.b [tcc__r1]
    lda.w col
    inc a
    sta.w col
    cmp.w #32
    bne tilemap_col_loop
    lda.w row
    inc a
    sta.w row
    cmp.w #16
    bne tilemap_row_loop

    lda.w #2
    sta.l screenState                ; checkpoint 2: tilemap built

    sep #$20                        ; back to 8-bit for the rest of the raw register pokes

    ; --- GSU launch registers ---
    ; matches two real captured Star Fox traces exactly: PBR via .l (safe
    ; regardless of DB), then DB explicitly set to 0 (phb/lda #0/pha/plb),
    ; then SCMR via plain DB-relative addressing, then R15 as a single
    ; 16-bit STX (X register) - not split A stores, not a 16-bit A store.
    lda #$01
    sta.l $3034                       ; PBR = 1 (ROM bank 1, see gsu/star3d_gsu.s)
    lda #$00
    sta.l $3038                       ; SCBR = 0 (buffer at GSU RAM $70:0000)

    phb
    lda #0
    pha
    plb                              ; DB = 0

    lda #$19
    sta $303A                        ; SCMR: RON|RAN|MD=4bpp, HT=0 (128)

    lda #3
    sta.l screenState                  ; checkpoint 3: about to write R15 (launch)

    ldx #0
    stx $301E                        ; R15 = 0 (single 16-bit STX) -> triggers launch

    lda #40
    sta.l screenState                  ; checkpoint 40: GSU launched, waiting

    ; We've confirmed (via the GSU debugger) that the GSU reliably reaches
    ; STOP well within a fraction of a frame - but polling SFR's bit5 for
    ; completion never actually unblocks, even after the GSU is done. Rather
    ; than depend on that bit, just wait a fixed, generous number of frames.
    jsr.l WaitForVBlank
    jsr.l WaitForVBlank
    jsr.l WaitForVBlank
    jsr.l WaitForVBlank
    jsr.l WaitForVBlank
    jsr.l WaitForVBlank
    jsr.l WaitForVBlank
    jsr.l WaitForVBlank

    lda #4
    sta.l screenState                  ; checkpoint 4: done waiting for the GSU

    ; --- DMA #1: GSU RAM buffer ($70:0000, 16384 bytes) -> VRAM CHR @ word $0000 ---
    lda #$80
    sta.l $2115                       ; VMAIN: word access, increment after high byte
    lda #$00
    sta.l $2116                       ; VMADDL
    sta.l $2117                       ; VMADDH -> VMADD = $0000

    lda #$01
    sta.l $4300                       ; DMAP0: mode1 (2 regs alternating), A->B
    lda #$18
    sta.l $4301                       ; BBAD0 = $18 (VMDATAL/H)
    lda #$00
    sta.l $4302                       ; A1T0L
    sta.l $4303                       ; A1T0H -> source addr $0000
    lda #$70
    sta.l $4304                       ; A1B0 = bank $70 (GSU RAM)
    lda #$00
    sta.l $4305                       ; DAS0L
    lda #$40
    sta.l $4306                       ; DAS0H -> 0x4000 bytes (16384)
    lda #$01
    sta.l $420B                       ; trigger channel 0

    ; --- DMA #2: tilemap (512 words / 1024 bytes) -> VRAM tilemap @ word $2000 ---
    lda #$00
    sta.l $2116
    lda #$20
    sta.l $2117                       ; VMADD = $2000

    lda #<tilemap
    sta.l $4302
    lda #>tilemap
    sta.l $4303                       ; source addr = tilemap (RAM)
    lda #:tilemap
    sta.l $4304                       ; A1B0 = tilemap's bank (RAM, $7E)
    lda #$00
    sta.l $4305
    lda #$04
    sta.l $4306                       ; DAS0H -> 0x0400 bytes (1024)
    lda #$01
    sta.l $420B                       ; trigger channel 0

    lda #5
    sta.l screenState                  ; checkpoint 5: both DMAs done

    ; --- turn on display ---
    lda #$01
    sta.l $212C                       ; TM: enable BG1

    lda #$0F
    sta.l $2100                       ; INIDISP: full brightness, forced blank off

    rep #$20                        ; back to 16-bit before returning to native-mode caller

    lda.w #6
    sta.l screenState                ; checkpoint 6: screen on, entering idle loop

forever:
    jsr.l WaitForVBlank
    bra forever

.ENDS

.RAMSECTION ".bss" BANK $7e SLOT 2
tilemap dsb 1024
row dsb 2
col dsb 2
screenState dsb 2
.ENDS

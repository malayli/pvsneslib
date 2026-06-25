.include "hdr.asm"

.accu 16
.index 16
.16bit

.EQU REG_VMAIN $2115
.EQU REG_VMADDLH $2116
.EQU REG_VMDATAH $2119
.EQU REG_VMDATAHREAD $213A

; Read (*LzssDecodeVram7Ex_src)[src_idx++] into \1.
; Must use [tcc__r0],y: LzssDecodeVram7Ex_src is a pointer in WRAM, not the .pc7 buffer.
; LzssDecodeVram7Ex_src,y would index the 4-byte pointer itself (offset, bank, pad…).
.MACRO read_src_postinc
	lda.w LzssDecodeVram7Ex_src
	sta.b tcc__r0
	lda.w LzssDecodeVram7Ex_src + 2
	sta.b tcc__r0h

	ldy.w src_idx

	sep #$20
	lda.b [tcc__r0], y
	rep #$20

	sta.w \1

	iny
	sty.w src_idx
.ENDM

.SECTION ".LzssDecodeVram7Extext_0x0" SUPERFREE

/*
#define REG_VMDATAHREAD (*(vuint8 *)0x213A)

void LzssDecodeVram7Ex()
{
    if ((LzssDecodeVram7Ex_src[0] & 0xF0) != 0x10)
        return;

    decomp_size = LzssDecodeVram7Ex_src[1] | ((u16)LzssDecodeVram7Ex_src[2] << 8);
    REG_VMAIN = VRAM_INCHIGH | VRAM_ADRTR_0B | VRAM_ADRSTINC_1;

    src_idx = 4;
    dst_idx = 0;
    ctrl_byte = 0;
    ctrl_bits = 0;
    run_remain = 0;
    run_src = 0;

    while (dst_idx < decomp_size)
    {
        if (run_remain > 0)
        {
            REG_VMADDLH = (u16)(LzssDecodeVram7Ex_address + run_src);
            vram_byte = REG_VMDATAHREAD;
            REG_VMADDLH = (u16)(LzssDecodeVram7Ex_address + dst_idx);
            REG_VMDATAH = vram_byte;
            run_src++;
            dst_idx++;
            run_remain--;
            continue;
        }

        if (ctrl_bits == 0)
        {
            ctrl_byte = LzssDecodeVram7Ex_src[src_idx++];
            ctrl_bits = 8;
        }

        if (ctrl_byte & 0x80)
        {
            match_hdr = LzssDecodeVram7Ex_src[src_idx++];
            match_dist_lo = LzssDecodeVram7Ex_src[src_idx++];
            match_len = (match_hdr >> 4) + 3;
            match_dist = ((match_hdr & 0x0F) << 8) | match_dist_lo;

            if (match_len > decomp_size - dst_idx)
                match_len = decomp_size - dst_idx;
            run_src = dst_idx - match_dist - 1;
            run_remain = match_len;
        }
        else
        {
            REG_VMADDLH = (u16)(LzssDecodeVram7Ex_address + dst_idx);
            REG_VMDATAH = LzssDecodeVram7Ex_src[src_idx++];
            dst_idx++;
        }

        ctrl_byte <<= 1;
        ctrl_bits--;
    }
}
*/
LzssDecodeVram7Ex:

// if ((LzssDecodeVram7Ex_src[0] & 0xF0) != 0x10)
lda.w LzssDecodeVram7Ex_src
sta.b tcc__r0
lda.w LzssDecodeVram7Ex_src + 2
sta.b tcc__r0h
sep #$20
lda.b [tcc__r0]
rep #$20
and.w #$00f0
cmp.w #$10

beq LzssDecodeVram7Ex_Init_Ok

rtl

LzssDecodeVram7Ex_Init_Ok:

// decomp_size = LzssDecodeVram7Ex_src[1] | (LzssDecodeVram7Ex_src[2] << 8)
ldy #1
sep #$20
lda.b [tcc__r0], y
rep #$20
sta.w decomp_size
iny
sep #$20
lda.b [tcc__r0], y
rep #$20
and.w #$00ff
xba
ora.w decomp_size
sta.w decomp_size

// REG_VMAIN = VRAM_INCHIGH | VRAM_ADRTR_0B | VRAM_ADRSTINC_1;
lda.w #128
sep #$20
sta.l REG_VMAIN
rep #$20

// src_idx = 4;
lda.w #4
sta.l src_idx

// dst_idx = 0;
// ctrl_byte = 0;
// ctrl_bits = 0;
// run_remain = 0;
// run_src = 0;
lda.w #0
sta.w dst_idx
sta.w ctrl_byte
sta.w ctrl_bits
sta.w run_remain
sta.w run_src

LzssDecodeVram7Ex_MainLoop:

// while (dst_idx < decomp_size)
lda.l dst_idx
sec
sbc.l decomp_size

bmi +
rtl
+

// if (run_remain != 0)
lda.w run_remain
bne +
brl __local_3
+

// REG_VMADDLH = (u16)(LzssDecodeVram7Ex_address + run_src);
lda.w run_src
clc
adc.l LzssDecodeVram7Ex_address
sta.l REG_VMADDLH

// vram_byte = REG_VMDATAHREAD;
sep #$20
lda.l REG_VMDATAHREAD
sta.l vram_byte
rep #$20

// REG_VMADDLH = (u16)(LzssDecodeVram7Ex_address + dst_idx);
lda.l dst_idx
clc
adc.l LzssDecodeVram7Ex_address
sta.l REG_VMADDLH

// REG_VMDATAH = vram_byte;
sep #$20
lda.l vram_byte
sta.l REG_VMDATAH
rep #$20

// run_src++;
lda.w run_src
inc a
sta.w run_src

// dst_idx++;
lda.w dst_idx
inc a
sta.w dst_idx

// run_remain--;
lda.l run_remain
dec a
sta.l run_remain

brl LzssDecodeVram7Ex_MainLoop

__local_3:

// if (ctrl_bits == 0)
lda.l ctrl_bits
cmp.w #0
beq +
brl __local_5
+

// ctrl_byte = LzssDecodeVram7Ex_src[src_idx++];
read_src_postinc ctrl_byte

// ctrl_bits = 8;
lda.w #8
sta.l ctrl_bits

__local_5:

// if (ctrl_byte & 0x80)
lda.w ctrl_byte
and.w #128
bne +
brl __local_6
+

// match_hdr = LzssDecodeVram7Ex_src[src_idx++];
read_src_postinc match_hdr

// match_dist_lo = LzssDecodeVram7Ex_src[src_idx++];
read_src_postinc match_dist_lo

// match_len = (match_hdr >> 4) + 3;
lda.w match_hdr
lsr a
lsr a
lsr a
lsr a
clc
adc.w #3
sta.w match_len

// match_dist = ((match_hdr & 0x0F) << 8) | match_dist_lo;
lda.w match_hdr
and.w #15
xba
and #$ff00
sta.b tcc__r0
//
lda.w match_dist_lo
ora.b tcc__r0
sta.w match_dist

// if (match_len > decomp_size - dst_idx)
lda.l match_len
sec
sbc.l decomp_size
clc
adc.l dst_idx
//
bpl +
brl __local_7
+

// match_len = decomp_size - dst_idx;
lda.l decomp_size
sec
sbc.l dst_idx
sta.l match_len

__local_7:

// run_src = dst_idx - match_dist - 1;
lda.l dst_idx
sec
sbc.l match_dist
dec a
sta.l run_src

// run_remain = match_len;
lda.l match_len
sta.l run_remain

brl LzssDecodeVram7Ex_MainLoop_Next

__local_6:

// REG_VMADDLH = (u16)(LzssDecodeVram7Ex_address + dst_idx);
lda.l LzssDecodeVram7Ex_address
clc
adc.l dst_idx
sta.l REG_VMADDLH

// REG_VMDATAH = LzssDecodeVram7Ex_src[src_idx++];
lda.w LzssDecodeVram7Ex_src
sta.b tcc__r0
lda.w LzssDecodeVram7Ex_src + 2
sta.b tcc__r0h
//
ldy.w src_idx
//
sep #$20
lda.b [tcc__r0], y
rep #$20
//
sta.l REG_VMDATAH
//
iny
sty.w src_idx

// dst_idx++;
lda.l dst_idx
inc a
sta.l dst_idx

LzssDecodeVram7Ex_MainLoop_Next:

// ctrl_byte <<= 1;
lda.w ctrl_byte
asl a
sta.w ctrl_byte

// ctrl_bits--;
lda.l ctrl_bits
dec a
sta.l ctrl_bits

brl LzssDecodeVram7Ex_MainLoop

rtl

.ENDS

.RAMSECTION ".bss" BANK $7e SLOT 2

/*
u16 match_hdr;
u16 match_dist_lo;
u16 match_len;
u16 match_dist;
u16 run_remain;
u16 run_src;
u16 ctrl_byte;
u16 ctrl_bits;
u16 src_idx;
u16 dst_idx;
u16 decomp_size;
u8 vram_byte;
u8 *LzssDecodeVram7Ex_src;
u16 LzssDecodeVram7Ex_address;
*/

match_hdr dsb 2
match_dist_lo dsb 2
match_len dsb 2
match_dist dsb 2
run_remain dsb 2
run_src dsb 2
ctrl_byte dsb 2
ctrl_bits dsb 2
src_idx dsb 2
dst_idx dsb 2
decomp_size dsb 2
vram_byte dsb 1
LzssDecodeVram7Ex_src dsb 4
LzssDecodeVram7Ex_address dsb 2

.ENDS

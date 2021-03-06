; Hitbox Display Patch by Yoshifanatic
; When applied, sprite collision hitboxes will display.
; This patch requires the "Extended No Sprite Tile Limits" patch to work correctly!
; Also, I just threw this patch together. Expect there to be bugs.

if read1($00FFD5) == $23
	sa1rom
	!SA1 = 1
	!Addr1 = $6000
	!14C8 = $3242
	!15EA = $33A2

!maxtile_pointer_max        = $6180       ; 16 bytes

else
	!SA1 = 0
	!Addr1 = $0000
	!14C8 = $14C8
	!15EA = $15EA

if read1($02B625) != $22
	error "This patch requires the 'Extended No Sprite Tile Limits' patch to use!"
else
	!ENSTLPatchLoc = read3($02B626)
endif

endif


org $00C569
	JSR.w $C593

org $00C56C
autoclean JSL.l Mario

if !SA1 == 0
org $0180E2
	JSL.l NormalSprite
	NOP #2
else
org $0180E1
	assert read1($0180E1) == $22,"Expecting this address to be patched"
	JSL.l NormalSprite
endif

org $01F562
	JSL.l YoshiTongue

org $02968F
	JSL.l BounceSprite
	NOP

org $0296B3
	JSL.l NetPunchOrCapeSwing

org $02A0B4
	JSL.l PlayerFireball

org $02A3FE
	JSR.w $02A519				;\ Swap this hitbox routine so it executes first before the player clipping values are gotten.
	JSL.l ExtendedSprites			;/

org $02A569
	LDA.b #$13
	STA.b $03

org $039DE9
	JSL.l DinoTorch
	NOP

freecode
Mario:
	REP.b #$20
	LDA.b $94
	PHA
	LDA.b $96
	PHA
	LDA.b $D1
	STA.b $94
	LDA.b $D3
	STA.b $96
	SEP.b #$20
	JSL.l $03B664			; Get Mario Clipping
	REP.b #$20
	PLA
	STA.b $96
	PLA
	STA.b $94
	SEP.b #$20
	JSR.w Hitbox
	LDA.b $16
	AND.b #$20
	RTL

NormalSprite:
if !SA1 == 0
	STA.w !15EA,x
else
	; inserted by SA-1's NoMoreSpriteTileLimits.asm org $0180D2
	db $22 ; JSL
	dl read3($0180E2)
	PHA
endif
	LDA.w !14C8,x
	BEQ.b +
	JSL.l $03B6E5			; Get Sprite Clipping B
	JSR.w Hitbox
if !SA1 == 0
	LDA.w !14C8,x
endif
+:
if !SA1
	PLA
endif
	RTL

YoshiTongue:
	LDA.b #$04
	STA.b $03
	JSR.w Hitbox
	RTL

BounceSprite:
	LDA.w $02968F,x
	STA.b $03
	JSR.w Hitbox
	RTL

NetPunchOrCapeSwing:
	LDA.b #$10
	STA.b $03
	JSR.w Hitbox
	RTL

ExtendedSprites:
	JSR.w SwapHitboxParameters
	JSR.w Hitbox
	JSL.l $03B664
	RTL

PlayerFireball:
	TXY
	STY.w $185E|!Addr1
	PHK
	PEA.w .Return-1
	PEA.w $0294F3
	JML.l $02A547
.Return:
	JSR.w Hitbox
	RTL

DinoTorch:
	LDA.w $039DB2,y
	STA.b $07
	JSR.w SwapHitboxParameters
	JSR.w Hitbox
	RTL

SwapHitboxParameters:
	LDA.b $04
	STA.b $00
	LDA.b $0A
	STA.b $08
	LDA.b $06
	STA.b $02
	LDA.b $05
	STA.b $01
	LDA.b $0B
	STA.b $09
	LDA.b $07
	STA.b $03
	RTS

Hitbox:
	LDA.b $04
	PHA
	LDA.b $05
	PHA
	PHX
	PHY
if !SA1 == 0
	JSL.l !ENSTLPatchLoc
	TAY
else
	LDA.W $0200|!Addr1
	PHA
	LDA.W $0201|!Addr1
	PHA
	LDA.W $0202|!Addr1
	PHA
	LDA.W $0203|!Addr1
	PHA
	LDA.w $0420|!Addr1
	PHA

	LDA #0
	TAY
endif
	LDX.b #$01
	BRA.b +

-:
if !SA1 == 0
	INY #4
endif

	PHX
	LDX #$01

.loop_offset
	LDA.b $00,x ; add hitbox width/height
	CLC
	ADC.b $02,x
	STA.b $00,x
	LDA.b $08,x
	ADC.b #$00
	STA.b $08,x

	LDA.b $00,x
	SEC				;\ Account for the fact that these tiles are drawn from the top left corner
	SBC.b #$08			;/
	STA.b $00,x
	LDA.b $08,x
	SBC.b #$00
	STA.b $08,x
	DEX
	BPL .loop_offset

	PLX

+:
	PHX
	LDX.b #$00
	LDA.b $00
	SEC
	SBC.b $1A
	STA.b $04
	STA.w $0200|!Addr1,y
	LDA.b $08
	SBC.b $1B
	STA.b $05
	BPL.b +
	DEX
+:
	XBA
	TXA
	XBA
	REP.b #$21
	ADC.b $04
	CMP.w #$0100
	SEP.b #$20
	LDA.b #$00
	ADC.b #$00
	PHA
	TYA
	LSR
	LSR
	TAX
	PLA
	STA.w $0420|!Addr1,x

	LDX.b #$00
	LDA.b $01
	SEC
	SBC.b $1C
	STA.b $04
	STA.w $0201|!Addr1,y
	LDA.b $09
	SBC.b $1D
	STA.b $05
	BPL.b +
	DEX
+:
	XBA
	TXA
	XBA
	REP.b #$21
	ADC.b $04
	CLC
	ADC.w #$0010
	CMP.w #$0100
	SEP.b #$20
	BCC.b +
	LDA.b #$F0
	STA.w $0201|!Addr1,y
+:
	LDA.b #$38				; Unused 5-up tile
	STA.w $0202|!Addr1,y

	LDA.b $01,S
	TAX
	LDA.l Flip,x
	STA.w $0203|!Addr1,y
	PLX
+:

if !SA1
; ----	print "inserted at: $",hex(----)," (pc: $",hex(snestopc(----)),")"
	LDA.w $0201|!Addr1,y
	CMP #$F0
	BCS +++

	PHX

	REP #$10
	LDX !maxtile_pointer_max+0
	CPX !maxtile_pointer_max+8
	BEQ .no_slot
	LDA $0200|!Addr1
	STA $400000,x
	LDA $0201|!Addr1
	STA $400001,x
	LDA $0202|!Addr1
	STA $400002,x
	LDA $0203|!Addr1
	STA $400003,x

	; Decrement slot and store back to pointer
	DEX #4
	STX !maxtile_pointer_max+0

	LDX !maxtile_pointer_max+2

	LDA $0420|!Addr1
	STA $400000,x

	; Decrement and store back to pointer
	DEX
	STX !maxtile_pointer_max+2

.no_slot
	SEP #$30
	PLX
+++:
endif

	DEX
	BMI.b +
	JMP.w -

+:
if !SA1
	PLA
	STA.w $0420|!Addr1
	PLA
	STA.W $0203|!Addr1
	PLA
	STA.W $0202|!Addr1
	PLA
	STA.W $0201|!Addr1
	PLA
	STA.W $0200|!Addr1

endif
	PLY
	PLX
	PLA
	STA.b $05
	PLA
	STA.b $04
	RTS

Flip:
	db $F0,$30

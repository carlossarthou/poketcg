_DuelCheckInterface: ; 8000 (2:4000)
	call ResetCursorPosAndBlink
	xor a
	ld [wce5e], a
	call DrawWideTextBox
	xor a
	ld [wDuelCursorBlinkCounter], a
	ld hl, CheckMenuData
	call PlaceTextItems
.loop
	call DoFrame
	call HandleDuelMenuInput2
	jr nc, .loop
	cp $ff
	ret z ; B was pressed
	ld a, [wCursorDuelYPosition] ; A was pressed
	sla a
	ld b, a
	ld a, [wCursorDuelXPosition]
	add b
	ld hl, DuelCheckMenuFunctionTable
	call JumpToFunctionInTable
	jr _DuelCheckInterface

DuelCheckMenuFunctionTable: ; 8031 (2:4031)
	dw DuelCheckMenu_InPlayArea
	dw DuelCheckMenu_Glossary
	dw DuelCheckMenu_YourPlayArea
	dw DuelCheckMenu_OppPlayArea

DuelCheckMenu_InPlayArea: ; 8039 (2:4039)
	xor a
	ld [wce60], a
	farcall Func_180d5
	ret

DuelCheckMenu_Glossary: ; 8042 (2:4042)
	farcall Func_006_44c8
	ret

DuelCheckMenu_YourPlayArea: ; 8047 (2:4047)
	call ResetCursorPosAndBlink
	xor a
	ld [wce5e], a
	ldh a, [hWhoseTurn]
.asm_8050
	ld h, a
	ld l, a
	call LoadTurnHolders

	ld a, [wCursorDuelYPosition]
	sla a
	ld b, a
	ld a, [wCursorDuelXPosition]
	add b
	ld [wLastCursorPosition_YourPlayArea], a
	ld b, $f8 ; black arrow tile
	call DrawByteToTabulatedPositions

	call DrawWideTextBox
	xor a
	ld [wDuelCursorBlinkCounter], a
	ld hl, YourPlayAreaMenuData
	call PlaceTextItems

.asm_8074
	call DoFrame
	xor a
	call DrawArrowsToTabulatedPositions
	call Func_86ac
	jr nc, .asm_8074
	call EraseByteFromTabulatedPositions
	cp $ff
	ret z
	ld a, [wCursorDuelYPosition]
	sla a
	ld b, a
	ld a, [wCursorDuelXPosition]
	add b
	lb hl, $40, $98
	call JumpToFunctionInTable
	jr .asm_8050

	INCROM $8098, $80da

DuelCheckMenu_OppPlayArea: ; 80da (2:40da)
	INCROM $80da, $8158

CheckMenuData: ; (2:4158)
	textitem  2, 14, InPlayAreaText
	textitem  2, 16, YourPlayAreaText
	textitem 12, 14, GlossaryText
	textitem 12, 16, OppPlayAreaText
	db $ff

YourPlayAreaMenuData: ; (2:4169)
	textitem  2, 14, YourPokemonText
	textitem 12, 14, YourHandText
	textitem  2, 16, YourDiscardPileText2
	db $ff

	INCROM $8176, $818c

; checks if arrows need to be erased in Play Area
; and draws new arrows upon cursor position change
DrawArrowsToTabulatedPositions: ; 818c (2:418c)
	push af
	ld b, a
	add b
	add b
	ld c, a
	ld a, [wCursorDuelYPosition]
	sla a
	ld b, a
	ld a, [wCursorDuelXPosition]
	add b
	add c
	; a = 2 * cursor ycoord + cursor xcoord + 3*a

	ld hl, wLastCursorPosition_YourPlayArea
	cp [hl]
	jr z, .unchanged
	call EraseByteFromTabulatedPositions

	ld [wLastCursorPosition_YourPlayArea], a
	ld b, $f8 ; black arrow tile byte
	call DrawByteToTabulatedPositions
.unchanged
	pop af
	ret

; load white tile in b to erase
; the bytes drawn previously
EraseByteFromTabulatedPositions: ; 81af (2:41af)
	push af
	ld a, [wLastCursorPosition_YourPlayArea]
	ld b, $00 ; white tile
	call DrawByteToTabulatedPositions
	pop af
	ret

; writes tile in b to positions tabulated in
; PlayAreaDrawPositionsPointerTable, with offset calculated from the
; cursor x and y positions in a
DrawByteToTabulatedPositions: ; 81ba (2:41ba)
	push bc
	ld hl, PlayAreaDrawPositionsPointerTable
	sla a
	ld c, a
	ld b, $00
	add hl, bc
	; hl points to PlayAreaDrawPositionsPointerTable 
	; plus offset corresponding to a

	ld a, [hli]
	ld h, [hl]
	ld l, a
	pop de

.loop
	ld a, [hli]
	cp $ff
	jr z, .done
	ld b, a
	ld a, [hli]
	ld c, a
	ld a, d
	call WriteByteToBGMap0
	jr .loop
.done
	ret

PlayAreaDrawPositionsPointerTable: ; 81d7 (2:41d7)
	dw PlayAreaDrawPositions.data_81e3
	dw PlayAreaDrawPositions.data_81f0
	dw PlayAreaDrawPositions.data_81f3
	dw PlayAreaDrawPositions.data_81f6
	dw PlayAreaDrawPositions.data_8203
	dw PlayAreaDrawPositions.data_8206

PlayAreaDrawPositions: ; 81e3 (2:41e3)
; x and y coordinates to draw byte
.data_81e3:
	db  5,  5
	db  0, 10
	db  4, 10
	db  8, 10
	db 12, 10
	db 16, 10
	db $ff

.data_81f0:
	db 14, 7
	db $ff

.data_81f3:
	db 14, 5
	db $ff

.data_81f6:
	db  5, 7
	db  0, 3
	db  4, 3
	db  8, 3
	db 12, 3
	db 16, 3
	db $ff

.data_8203:
	db 0, 5
	db $ff

.data_8206:
	db 0, 8
	db $ff

; loads the turn holders
; with the turn that a holds
LoadTurnHolders: ; 8209 (2:4209)
	ld a, h
	ld [wTurnHolder1], a
	ld a, l
	ld [wTurnHolder2], a
; fallthrough

; loads tiles and icons to display play area
; and draws the screen according to the turn player
_DrawPlayArea: ; 8211 (2:4211)
	xor a
	ld [wTileMapFill], a
	call ZeroObjectPositions

	ld a, $01
	ld [wVBlankOAMCopyToggle], a

	call DoFrame
	call EmptyScreen
	call Set_OBJ_8x8
	call LoadCursorTile
	call LoadSymbolsFont
	call LoadDeckAndDiscardPileIcons

	ld a, [wTurnHolder1]
	cp PLAYER_TURN
	jr nz, .opp_turn1
	ld de, wDefaultText
	call CopyPlayerName
	jr .get_text_length
.opp_turn1
	ld de, wDefaultText
	call CopyOpponentName
.get_text_length
	ld hl, wDefaultText

	call GetTextLengthInTiles
	ld a, 6 ; max name size in tiles
	sub b
	srl a
	add 4
	; a = (6 - name text in tiles) / 2 + 4
	ld d, a ; text horizontal alignment

	ld e, $00
	call InitTextPrinting
	lb hl, $02, $47
	ldh a, [hWhoseTurn]
	cp PLAYER_TURN
	jr nz, .opp_turn2
	ld a, [wTurnHolder1]
	cp PLAYER_TURN
	jr nz, .swap
.opp_turn2
	call PrintTextNoDelay
	jr .draw
.swap
	call SwapTurn
	call PrintTextNoDelay
	call SwapTurn

.draw
	ld a, [wTurnHolder1]
	ld b, a
	ld a, [wTurnHolder2]
	cp b
	jr nz, .not_equal

	ld hl, PrizeCardsCoordinateData.player
	call DrawPrizeCards
	lb de, 6, 2 ; coordinates to draw player's active card
	call DrawActiveCardGfx
	lb de, 1, 9
	ld c, $04
	call DrawPlayAreaBenchCards
	xor a
	call Func_85aa
	jr .lcd
.not_equal
	ld hl, PrizeCardsCoordinateData.opponent
	call DrawPrizeCards
	lb de, 6, 5 ; coordinates to draw opponent's active card
	call DrawActiveCardGfx
	lb de, $01, $02
	ld c, $04
	call DrawPlayAreaBenchCards
	ld a, $01
	call Func_85aa

.lcd
	call EnableLCD
	ret

Func_82b6: ; 82b6 (2:42b6)
	INCROM $82b6, $833c

Func_833c: ; 833c (2:433c)
	INCROM $833c, $837e

; draws the active card gfx at coordinates de
; of the player (or opponent) depending on wTurnHolder1
DrawActiveCardGfx: ; 837e (2:437e)
	push de
	ld a, DUELVARS_ARENA_CARD
	ld l, a
	ld a, [wTurnHolder1]
	ld h, a
	ld a, [hl]
	cp $ff
	jr z, .no_pokemon

	ld d, a
	ld a, [wTurnHolder1]
	ld b, a
	ldh a, [hWhoseTurn]
	cp b
	jr nz, .swap
	ld a, d
	call LoadCardDataToBuffer1_FromDeckIndex
	jr .draw
.swap
	call SwapTurn
	ld a, d
	call LoadCardDataToBuffer1_FromDeckIndex
	call SwapTurn

.draw
	lb de, $8a, $00 ; destination offset of loaded gfx
	ld hl, wLoadedCard1Gfx
	ld a, [hli]
	ld h, [hl]
	ld l, a
	lb bc, $30, TILE_SIZE
	call LoadCardGfx
	bank1call SetBGP6OrSGB3ToCardPalette
	bank1call FlushAllPalettesOrSendPal23Packet
	pop de

	; draw card gfx
	ld a, $a0
	lb hl, $06, $01
	lb bc, 8, 6
	call FillRectangle
	bank1call ApplyBGP6OrSGB3ToCardImage
	ret

.no_pokemon
	pop de
	ret

	INCROM $83cc, $8464

DrawPrizeCards: ; 8464 (2:4464)
	push hl
	call GetDuelInitialPrizesUpperBitsSet
	ld a, [wTurnHolder1]
	ld h, a
	ld l, DUELVARS_PRIZES
	ld a, [hl]

	pop hl
	ld b, 0
	push af
; loop each prize card
.loop
	inc b
	ld a, [wDuelInitialPrizes]
	inc a
	cp b
	jr z, .done

	pop af
	srl a ; right shift prize cards left
	push af
	jr c, .not_taken
	ld a, $e0 ; tile byte for empty slot
	jr .draw
.not_taken
	ld a, $dc ; tile byte for card
.draw
	ld e, [hl]
	inc hl
	ld d, [hl]
	inc hl
	
	push hl
	push bc
	lb hl, $01, $02 ; card tile gfx
	lb bc, 2, 2 ; rectangle size
	call FillRectangle

	ld a, [wConsole]
	cp CONSOLE_CGB
	jr nz, .not_cgb
	ld a, $02 ; blue colour
	lb bc, 2, 2
	lb hl, $00, $00
	call BankswitchVRAM1
	call FillRectangle
	call BankswitchVRAM0
.not_cgb
	pop bc
	pop hl
	jr .loop
.done
	pop af
	ret

PrizeCardsCoordinateData: ; 0x84b4 (2:44b4)
; x and y coordinates for player prize cards
.player
	db 2, 1
	db 2, 3
	db 4, 1
	db 4, 3
	db 6, 1
	db 6, 3
; x and y coordinates for opponent prize cards
.opponent
	db 9, 17
	db 9, 15
	db 7, 17
	db 7, 15
	db 5, 17
	db 5, 15

	INCROM $84cc, $84fc

; calculates bits set up to the number of
; initial prizes, with upper 2 bits set, i.e:
; 6 prizes: a = %11111111
; 4 prizes: a = %11001111
; 3 prizes: a = %11000111
; 2 prizes: a = %11000011
GetDuelInitialPrizesUpperBitsSet: ; 84fc (2:44fc)
	ld a, [wDuelInitialPrizes]
	ld b, $01
.loop
	or a
	jr z, .done
	sla b
	dec a
	jr .loop
.done
	dec b
	ld a, b
	or %11000000
	ld [wDuelInitialPrizesUpperBitsSet], a
	ret

; draws filled and empty bench slots depending
; on the turn loaded in wTurnHolder1
; at coordinates loaded in de
; if wTurnHolder1 is different from wTurnHolder2
; adjusts coordinates of the bench slots
DrawPlayAreaBenchCards: ; 8511 (2:4511)
	ld a, [wTurnHolder2]
	ld b, a
	ld a, [wTurnHolder1]
	cp b
	jr z, .skip

	ld a, d
	add c
	add c
	add c
	add c
	ld d, a
	; d = d + 4 * c

	xor a
	sub c
	ld c, a
	; c = $ff - c + 1

	ld a, [wTurnHolder1]
.skip
	ld h, a
	ld l, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	ld b, [hl]
	ld l, DUELVARS_BENCH1_CARD_STAGE
.loop1
	dec b ; num of Bench Pokemon left
	jr z, .done

	ld a, [hli]
	push hl
	push bc
	sla a
	sla a
	add $e4 
	; a holds the correct stage gfx tile
	ld b, a
	push bc

	lb hl, $01, $02
	lb bc, $02, $02
	call FillRectangle

	ld a, [wConsole]
	cp CONSOLE_CGB
	pop bc
	jr nz, .next

	ld a, b
	cp $ec ; tile offset of 2 stage
	jr z, .two_stage
	cp $f0 ; tile offset of 2 stage with no 1 stage
	jr z, .two_stage

	ld a, $02 ; blue colour
	jr .palette
.two_stage
	ld a, $01 ; red colour
.palette
	lb bc, $02, $02
	lb hl, $00, $00
	call BankswitchVRAM1
	call FillRectangle
	call BankswitchVRAM0

.next ; adjust coordinates for next card
	pop bc
	pop hl
	ld a, d
	add c
	ld d, a
	; d = d + c
	jr .loop1

.done
	ld a, [wTurnHolder1]
	ld h, a
	ld l, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	ld b, [hl]
	ld a, MAX_PLAY_AREA_POKEMON
	sub b
	ret z ; return if already full

	ld b, a
	inc b
.loop2
	dec b
	ret z 

	push bc
	ld a, $f4 ; empty bench slot tile
	lb hl, $01, $02
	lb bc, $02, $02
	call FillRectangle

	ld a, [wConsole]
	cp CONSOLE_CGB
	jr nz, .not_cgb

	ld a, $02 ; colour
	lb bc, $02, $02
	lb hl, $00, $00
	call BankswitchVRAM1
	call FillRectangle
	call BankswitchVRAM0

.not_cgb
	pop bc
	ld a, d
	add c
	ld d, a
	jr .loop2

Func_85aa: ; 85aa (2:45aa)
	or a
	jr nz, .asm_85b2
	lb hl, $46, $35
	jr .asm_85b5
.asm_85b2
	lb hl, $46, $3b
.asm_85b5
	ld a, [wTurnHolder1]
	ld d, a
	ld e, DUELVARS_NUMBER_OF_CARDS_IN_HAND
	ld a, [de]
	ld b, a
	ld a, $d0
	call Func_8676

	ld a, [wTurnHolder1]
	ld d, a
	ld e, DUELVARS_NUMBER_OF_CARDS_NOT_IN_DECK
	ld a, [de]
	ld b, a
	ld a, DECK_SIZE
	sub b
	ld b, a
	ld a, $d4
	call Func_85e1

	ld a, [wTurnHolder1]
	ld d, a
	ld e, DUELVARS_NUMBER_OF_CARDS_IN_DISCARD_PILE
	ld a, [de]
	ld b, a
	ld a, $d8
	call Func_85e1
	ret

Func_85e1: ; 85e1 (2:45e1)
	ld d, [hl]
	inc hl
	ld e, [hl]
	inc hl
	push hl
	push bc
	lb hl, $01, $02
	lb bc, $02, $02
	call FillRectangle

	ld a, [wConsole]
	cp CONSOLE_CGB
	jr nz, .asm_8608

	ld a, $02
	lb bc, $02, $02
	lb hl, $00, $00
	call BankswitchVRAM1
	call FillRectangle
	call BankswitchVRAM0

.asm_8608
	inc d
	inc d
	inc e
	call InitTextPrinting
	pop bc
	ld a, b
	call Func_98a6

	ld hl, $ceb6
	ld a, [hli]
	ld b, a
	ld a, [hl]

	ld hl, wDefaultText
	ld [hl], $05
	inc hl
	ld [hl], SYM_CROSS
	inc hl
	ld [hl], $05
	inc hl
	ld [hli], a
	ld [hl], $05
	inc hl
	ld a, b
	ld [hli], a
	ld [hl], $00
	ld hl, wDefaultText
	call ProcessText
	pop hl
	ret

	INCROM $8635, $8676

Func_8676: ; 8676 (2:4676)
	ld d, [hl]
	inc hl
	ld e, [hl]
	inc hl
	push hl
	push bc
	call InitTextPrinting
	ld hl, $24e
	call ProcessTextFromID
	pop bc
	ld a, b
	call Func_98a6
	ld hl, $ceb6
	ld a, [hli]
	ld b, a
	ld a, [hl]
	ld hl, wDefaultText
	ld [hl], $05
	inc hl
	ld [hl], $2d
	inc hl
	ld [hl], $05
	inc hl
	ld [hli], a
	ld [hl], $05
	inc hl
	ld a, b
	ld [hli], a
	ld [hl], $00
	ld hl, wDefaultText
	call ProcessText
	pop hl
	ret
; 0x86ac

Func_86ac: ; 86ac (2:46ac)
	INCROM $86ac, $8764

Func_8764: ; 8764 (2:4764)
	INCROM $8764, $8932

Func_8932: ; 8932 (2:4932)
	INCROM $8932, $8992

LoadCursorTile: ; 8992 (2:4992)
	ld de, v0Tiles0
	ld hl, .tile_data
	ld b, 16
	call SafeCopyDataHLtoDE
	ret

.tile_data: ; 899e (2:499e)
	db $e0, $c0, $98, $b0, $84, $8c, $83, $82
	db $86, $8f, $9d, $be, $f4, $f8, $50, $60

	INCROM $89ae, $8aaa

Func_8aaa: ; 8aaa (2:4aaa)
	INCROM $8aaa, $8b85

Func_8b85: ; 8b85 (2:4b85)
	INCROM $8b85, $8cd4

Func_8cd4: ; 8cd4 (2:4cd4)
	push bc
	call EnableSRAM
	ld b, $3c
.asm_8cda
	ld a, [de]
	inc de
	ld [hli], a
	dec b
	jr nz, .asm_8cda
	xor a
	ld [hl], a
	call DisableSRAM
	pop bc
	ret
; 0x8ce7

	INCROM $8ce7, $8cf9

Func_8cf9: ; 8cf9 (2:4cf9)
	call EnableSRAM
	xor a
	ld hl, $b703
	ld [hli], a
	inc a
	ld [hli], a
	ld [hli], a
	ld [hl], a
	ld [$b701], a
	call DisableSRAM
Func_8d0b: ; 8d0b (2:4d0b)
	ld hl, Unknown_8d15
	ld de, $9380
	call Func_92ad
	ret

Unknown_8d15: ; 8d15 (2:4d15)
	INCROM $8d15, $8d56

Func_8d56: ; 8d56 (2:4d56)
	xor a
	ld [wTileMapFill], a
	call EmptyScreen
	call ZeroObjectPositions
	ld a, $1
	ld [wVBlankOAMCopyToggle], a
	call LoadSymbolsFont
	call LoadDuelCardSymbolTiles
	call Func_8d0b
	bank1call SetDefaultPalettes
	lb de, $3c, $bf
	call SetupText
	ret
; 0x8d78

	INCROM $8d78, $8d9d

Func_8d9d: ; 8d9d (2:4d9d)
	ld de, wcfd1
	ld b, $7
.asm_8da2
	ld a, [hli]
	ld [de], a
	inc de
	dec b
	jr nz, .asm_8da2
	ret

Unknown_8da9: ; 8da9 (2:4da9)
	INCROM $8da9, $8db0

Func_8db0: ; 8db0 (2:4db0)
	ld hl, Unknown_8da9
	call Func_8d9d
	ld a, $ff
	call Func_9168
	xor a

Func_8dbc: ; 8dbc (2:4dbc)
	ld hl, Unknown_8de2
	call InitializeMenuParameters
	ldtx hl, PleaseSelectDeckText
	call DrawWideTextBox_PrintText
.asm_8dc8
	call DoFrame
	jr c, Func_8dbc
	call Func_8dea
	jr c, Func_8dbc
	call HandleMenuInput
	jr nc, .asm_8dc8
	ldh a, [hCurMenuItem]
	cp $ff
	ret z
	ld [wceb1], a
	jp Func_8e42

Unknown_8de2: ; 8de2 (2:4de2)
	INCROM $8de2, $8dea

Func_8dea: ; 8dea (2:4dea)
	ldh a, [hDPadHeld]
	and START
	ret z
	ld a, [wCurMenuItem]
	ld [wceb1], a
	call Func_8ff2
	jp nc, Func_8e05
	ld a, $ff
	call Func_90fb
	call Func_8fe8
	scf
	ret

Func_8e05: ; 8e05 (2:4e05)
	ld a, $1
	call Func_90fb
	call GetPointerToDeckCards
	push hl
	call GetPointerToDeckName
	pop de
	call Func_8e1f
	ld a, $ff
	call Func_9168
	ld a, [wceb1]
	scf
	ret

Func_8e1f: ; 8e1f (2:4e1f)
	push de
	ld de, wcfb9
	call Func_92b4
	pop de
	ld hl, wcf17
	call Func_8cd4
	ld a, $9
	ld hl, wcebb
	call Func_9843
	ld a, $3c
	ld [wcecc], a
	ld hl, wcebb
	ld [hl], a
	call Func_9e41
	ret

Func_8e42: ; 8e42 (2:4e42)
	call DrawWideTextBox
	ld hl, Unknown_9027
	call PlaceTextItems
	call ResetCursorPosAndBlink
.asm_8e4e
	call DoFrame
	call HandleDuelMenuInput2
	jp nc, .asm_8e4e
	cp $ff
	jr nz, .asm_8e64
	call DrawCursorEmpty
	ld a, [wceb1]
	jp Func_8dbc
.asm_8e64
	ld a, [wCursorDuelXPosition]
	or a
	jp nz, Func_8f8a
	ld a, [wCursorDuelYPosition]
	or a
	jp nz, .asm_8ecf
	call GetPointerToDeckCards
	ld e, l
	ld d, h
	ld hl, wcf17
	call Func_8cd4
	ld a, $14
	ld hl, wcfb9
	call Func_9843
	ld de, wcfb9
	call GetPointerToDeckName
	call Func_92b4
	call Func_9345
	jr nc, .asm_8ec4
	call EnableSRAM
	ld hl, wcf17
	call Func_910a
	call GetPointerToDeckCards
	call Func_9152
	ld e, l
	ld d, h
	ld hl, wcf17
	ld b, $3c
.asm_8ea9
	ld a, [hli]
	ld [de], a
	inc de
	dec b
	jr nz, .asm_8ea9
	call GetPointerToDeckName
	ld d, h
	ld e, l
	ld hl, wcfb9
	call Func_92ad
	call GetPointerToDeckName
	ld a, [hl]
	call DisableSRAM
	or a
	jr z, .asm_8edb
.asm_8ec4
	ld a, $ff
	call Func_9168
	ld a, [wceb1]
	jp Func_8dbc
.asm_8ecf
	call Func_8ff2
	jp nc, .asm_8edb
	call Func_8fe8
	jp Func_8dbc
.asm_8edb
	ld a, $14
	ld hl, wcfb9
	call Func_9843
	ld de, wcfb9
	call GetPointerToDeckName
	call Func_92b4
	call Func_8f05
	call GetPointerToDeckName
	ld d, h
	ld e, l
	ld hl, wcfb9
	call Func_92b4
	ld a, $ff
	call Func_9168
	ld a, [wceb1]
	jp Func_8dbc

Func_8f05: ; 8f05 (2:4f05)
	ld a, [wceb1]
	or a
	jr nz, .asm_8f10
	; it refers to a data in the other bank without any bank desc.
	ld hl, Deck1Data
	jr .asm_8f23
.asm_8f10
	dec a
	jr nz, .asm_8f18
	ld hl, Deck2Data
	jr .asm_8f23
.asm_8f18
	dec a
	jr nz, .asm_8f20
	ld hl, Deck3Data
	jr .asm_8f23
.asm_8f20
	ld hl, Deck4Data
.asm_8f23
	ld a, MAX_DECK_NAME_LENGTH
	lb bc, 4, 1
	ld de, wcfb9
	farcall InputDeckName
	ld a, [wcfb9]
	or a
	ret nz
	call Func_8f38
	ret

Func_8f38: ; 8f38 (2:4f38)
	ld hl, $b701
	call EnableSRAM
	ld a, [hli]
	ld h, [hl]
	call DisableSRAM
	ld l, a
	ld de, wDefaultText
	call TwoByteNumberToText
	ld hl, wcfb9
	ld [hl], $6
	inc hl
	ld [hl], $44
	inc hl
	ld [hl], $65
	inc hl
	ld [hl], $63
	inc hl
	ld [hl], $6b
	inc hl
	ld [hl], $20
	inc hl
	ld de, $c592
	ld a, [de]
	inc de
	ld [hli], a
	ld a, [de]
	inc de
	ld [hli], a
	ld a, [de]
	ld [hli], a
	xor a
	ld [hl], a
	ld hl, $b701
	call EnableSRAM
	ld e, [hl]
	inc hl
	ld d, [hl]
	ld a, $3
	cp d
	jr nz, .asm_8f82
	ld a, $e7
	cp e
	jr nz, .asm_8f82
	ld de, $0000
.asm_8f82
	inc de
	ld [hl], d
	dec hl
	ld [hl], e
	call DisableSRAM
	ret

Func_8f8a: ; 8f8a (2:4f8a)
	ld a, [wCursorDuelYPosition]
	or a
	jp nz, Func_9026
	call Func_8ff2
	jp nc, Func_8f9d
	call Func_8fe8
	jp Func_8dbc

Func_8f9d: ; 8f9d (2:4f9d)
	call EnableSRAM
	ld a, [s0b700]
	call DisableSRAM
	ld h, $3
	ld l, a
	call HtimesL
	ld e, l
	inc e
	ld d, 2
	xor a
	lb hl, 0, 0
	lb bc, 2, 2
	call FillRectangle
	ld a, [wceb1]
	call EnableSRAM
	ld [s0b700], a
	call DisableSRAM
	call Func_9326
	call GetPointerToDeckName
	call EnableSRAM
	call Func_9253
	call DisableSRAM
	xor a
	ld [wTxRam2], a
	ld [wTxRam2 + 1], a
	ldtx hl, ChosenAsDuelingDeckText
	call DrawWideTextBox_WaitForInput
	ld a, [wceb1]
	jp Func_8dbc

Func_8fe8: ; 8fe8 (2:4fe8)
	ldtx hl, ThereIsNoDeckHereText
	call DrawWideTextBox_WaitForInput
	ld a, [wceb1]
	ret

Func_8ff2: ; 8ff2 (2:4ff2)
	ld a, [wceb1]
	ld hl, wceb2
	ld b, $0
	ld c, a
	add hl, bc
	ld a, [hl]
	or a
	ret nz
	scf
	ret
; 0x9001

	INCROM $9001, $9026

Func_9026: ; 9026 (2:5026)
	ret

Unknown_9027: ; 9027 (2:5027)
	INCROM $9027, $9038

; return, in hl, the pointer to sDeckXName where X is [wceb1] + 1
GetPointerToDeckName: ; 9038 (2:5038)
	ld a, [wceb1]
	ld h, a
	ld l, sDeck2Name - sDeck1Name
	call HtimesL
	push de
	ld de, sDeck1Name
	add hl, de
	pop de
	ret

; return, in hl, the pointer to sDeckXCards where X is [wceb1] + 1
GetPointerToDeckCards: ; 9048 (2:5048)
	push af
	ld a, [wceb1]
	ld h, a
	ld l, sDeck2Cards - sDeck1Cards
	call HtimesL
	push de
	ld de, sDeck1Cards
	add hl, de
	pop de
	pop af
	ret

ResetCursorPosAndBlink: ; 905a (2:505a)
	xor a
	ld [wCursorDuelXPosition], a
	ld [wCursorDuelYPosition], a
	ld [wDuelCursorBlinkCounter], a
	ret

; handle player input in menu
; works out which cursor coordinate to go to
; and sets carry flag if A or B are pressed
; returns a =  $1 if A pressed
; returns a = $ff if B pressed
HandleDuelMenuInput2: ; 9065 (2:5065)
	xor a
	ld [wcfe3], a
	ld a, [wCursorDuelXPosition]
	ld d, a
	ld a, [wCursorDuelYPosition]
	ld e, a
	ldh a, [hDPadHeld]
	or a
	jr z, .no_pad
	bit D_LEFT_F, a
	jr nz, .horizontal
	bit D_RIGHT_F, a
	jr z, .check_vertical
.horizontal
	ld a, d
	xor $1 ; flips x coordinate
	ld d, a
	jr .okay
.check_vertical
	bit D_UP_F, a
	jr nz, .vertical
	bit D_DOWN_F, a
	jr z, .no_pad
.vertical
	ld a, e
	xor $1 ; flips y coordinate
	ld e, a
.okay
	ld a, $1
	ld [wcfe3], a
	push de
	call DrawCursorEmpty
	pop de
	ld a, d
	ld [wCursorDuelXPosition], a
	ld a, e
	ld [wCursorDuelYPosition], a
	xor a
	ld [wDuelCursorBlinkCounter], a
.no_pad
	ldh a, [hKeysPressed]
	and A_BUTTON | B_BUTTON
	jr z, .no_input
	and A_BUTTON
	jr nz, .a_press
	ld a, $ff
	call Func_90fb
	scf
	ret
.a_press
	call Func_90f7
	ld a, $1
	call Func_90fb
	scf
	ret
.no_input
	ld a, [wcfe3]
	or a
	jr z, .check_blink
	call PlaySFX
.check_blink
	ld hl, wDuelCursorBlinkCounter
	ld a, [hl]
	inc [hl]
	and $f
	ret nz ; don't update cursor
	ld a, $f
	bit 4, [hl]
	jr z, DrawByteInCursor

; draws in the cursor position
DrawCursorEmpty: ; 90d8 (2:50d8)
	ld a, $0 ; empty cursor
; fallthrough

; draws in the cursor position
; with byte in a
DrawByteInCursor:
	ld e, a
	ld a, $a
	ld l, a
	ld a, [wCursorDuelXPosition]
	ld h, a
	call HtimesL
	ld a, l
	add $1
	ld b, a
	ld a, [wCursorDuelYPosition]
	sla a
	add $e
	ld c, a
	ld a, e
	call WriteByteToBGMap0
	or a
	ret

Func_90f7: ; 90f7 (2:50f7)
	ld a, $f
	jr DrawByteInCursor

Func_90fb: ; 90fb (2:50fb)
	push af
	inc a
	jr z, .asm_9103
	ld a, $2
	jr .asm_9105
.asm_9103
	ld a, $3
.asm_9105
	call PlaySFX
	pop af
	ret

Func_910a: ; 910a (2:510a)
	push hl
	ld b, $0
	ld d, $3c
.asm_910f
	ld a, [hli]
	or a
	jr z, .asm_911e
	ld c, a
	push hl
	ld hl, sCardCollection
	add hl, bc
	dec [hl]
	pop hl
	dec d
	jr nz, .asm_910f
.asm_911e
	pop hl
	ret
; 0x9120

	INCROM $9120, $9152

Func_9152: ; 9152 (2:5152)
	push hl
	ld b, $0
	ld d, $3c
.asm_9157
	ld a, [hli]
	or a
	jr z, .asm_9166
	ld c, a
	push hl
	ld hl, sCardCollection
	add hl, bc
	inc [hl]
	pop hl
	dec d
	jr nz, .asm_9157
.asm_9166
	pop hl
	ret

Func_9168: ; 9168 (2:5168)
	ld [hffb5], a
	call Func_8d56
	ld de, $0000
	ld bc, $1404
	call DrawRegularTextBox
	ld de, $0003
	ld bc, $1404
	call DrawRegularTextBox
	ld de, $0006
	ld bc, $1404
	call DrawRegularTextBox
	ld de, $0009
	ld bc, $1404
	call DrawRegularTextBox
	ld hl, Unknown_9242
	call PlaceTextItems
	ld a, $4
	ld hl, wceb2
	call Func_9843
	ld a, [hffb5]
	bit 0, a
	jr z, .asm_91b0
	ld hl, sDeck1Name
	ld de, $0602
	call Func_926e
.asm_91b0
	ld hl, sDeck1Cards
	call Func_9314
	jr c, .asm_91bd
	ld a, $1
	ld [wceb2], a
.asm_91bd
	ld a, [hffb5]
	bit 1, a
	jr z, .asm_91cd
	ld hl, sDeck2Name
	ld de, $0605
	call Func_926e
.asm_91cd
	ld hl, sDeck2Cards
	call Func_9314
	jr c, .asm_91da
	ld a, $1
	ld [wceb3], a
.asm_91da
	ld a, [hffb5]
	bit 2, a
	jr z, .asm_91ea
	ld hl, sDeck3Name
	ld de, $0608
	call Func_926e
.asm_91ea
	ld hl, sDeck3Cards
	call Func_9314
	jr c, .asm_91f7
	ld a, $1
	ld [wceb4], a
.asm_91f7
	ld a, [hffb5]
	bit 3, a
	jr z, .asm_9207
	ld hl, sDeck4Name
	ld de, $060b
	call Func_926e
.asm_9207
	ld hl, sDeck4Cards
	call Func_9314
	jr c, .asm_9214
	ld a, $1
	ld [wceb5], a
.asm_9214
	call EnableSRAM
	ld a, [s0b700]
	ld c, a
	ld b, $0
	ld d, $2
.asm_921f
	ld hl, wceb2
	add hl, bc
	ld a, [hl]
	or a
	jr nz, .asm_9234
	inc c
	ld a, $4
	cp c
	jr nz, .asm_921f
	ld c, $0
	dec d
	jr z, .asm_9234
	jr .asm_921f
.asm_9234
	ld a, c
	ld [s0b700], a
	call DisableSRAM
	call Func_9326
	call EnableLCD
	ret

Unknown_9242: ; 9242 (2:5242)
	INCROM $9242, $9253

Func_9253: ; 9253 (2:5253)
	ld de, wDefaultText
	call Func_92ad
	ld hl, wDefaultText
	call GetTextLengthInTiles
	ld b, $0
	ld hl, wDefaultText
	add hl, bc
	ld d, h
	ld e, l
	ld hl, Unknown_92a7
	call Func_92ad
	ret

Func_926e: ; 926e (2:526e)
	push hl
	call Func_9314
	pop hl
	jr c, .asm_929c
	push de
	ld de, wDefaultText
	call Func_92b4
	ld hl, wDefaultText
	call GetTextLengthInTiles
	ld b, $0
	ld hl, wDefaultText
	add hl, bc
	ld d, h
	ld e, l
	ld hl, Unknown_92a7
	call Func_92ad
	pop de
	ld hl, wDefaultText
	call InitTextPrinting
	call ProcessText
	or a
	ret
.asm_929c
	call InitTextPrinting
	ldtx hl, NewDeckText
	call ProcessTextFromID
	scf
	ret

Unknown_92a7: ; 92a7 (2:52a7)
	INCROM $92a7, $92ad

Func_92ad: ; 92ad (2:52ad)
	ld a, [hli]
	ld [de], a
	or a
	ret z
	inc de
	jr Func_92ad

Func_92b4: ; 92b4 (2:52b4)
	call EnableSRAM
	call Func_92ad
	call DisableSRAM
	ret
; 0x92be

	INCROM $92be, $9314

Func_9314: ; 9314 (2:5314)
	ld bc, $0018
	add hl, bc
	call EnableSRAM
	ld a, [hl]
	call DisableSRAM
	or a
	jr nz, .asm_9324
	scf
	ret
.asm_9324
	or a
	ret

Func_9326: ; 9326 (2:5326)
	call EnableSRAM
	ld a, [s0b700]
	call DisableSRAM
	ld h, 3
	ld l, a
	call HtimesL
	ld e, l
	inc e
	ld d, 2
	ld a, $38
	lb hl, 1, 2
	lb bc, 2, 2
	call FillRectangle
	ret

Func_9345: ; 9345 (2:5345)
	INCROM $9345, $9843

Func_9843: ; 9843 (2:5843)
	INCROM $9843, $98a6

Func_98a6: ; 98a6 (2:58a6)
	push af
	push bc
	push de
	push hl
	ld c, $ff
.asm_98ac
	inc c
	sub $0a
	jr nc, .asm_98ac
	jr z, .asm_98b5
	add $0a
.asm_98b5
	add $20
	ld hl, $ceb6
	ld [hli], a
	ld a, c
	or a
	jr z, .asm_98c1
	add $20
.asm_98c1
	ld [hl], a
	pop hl
	pop de
	pop bc
	pop af
	ret

	INCROM $98c7, $9e41

Func_9e41: ; 9e41 (2:5e41)
	INCROM $9e41, $a288

Func_a288: ; a288 (2:6288)
	INCROM $a288, $b177

Func_b177: ; b177 (2:7177)
	INCROM $b177, $b19d

Func_b19d: ; b19d (2:719d)
	xor a
	ld [wcea1], a
	ld de, CheckForCGB
	ld hl, wd0a2
	ld [hl], e
	inc hl
	ld [hl], d
	call $7379
	ld a, $3c
	ld [wd0a5], a
	xor a
.asm_b1b3
	ld hl, $76fb
	call $5a6d
	call $7704
	call $7545
	ldtx hl, PleaseSelectDeckText
	call DrawWideTextBox_PrintText
	ld de, $0224 ; PleaseSelectDeckText?
	call $7285
	call $729f
	jr c, .asm_b1b3
	cp $ff
	ret z
	ld b, a
	ld a, [wcea1]
	add b
	ld [wd088], a
	call ResetCursorPosAndBlink
	call DrawWideTextBox
	ld hl, $7274
	call PlaceTextItems
	call DoFrame
	call HandleDuelMenuInput2
	jp nc, $71e7
	cp $ff
	jr nz, .asm_b1fa
	ld a, [wd086]
	jp $71b3

.asm_b1fa
	ld a, [wCursorDuelYPosition]
	sla a
	ld hl, wCursorDuelXPosition
	add [hl]
	or a
	jr nz, .asm_b22c
	call $735b
	jr nc, .asm_b216
	call $7592
	ld a, [wd086]
	jp c, $71b3
	jr .asm_b25e

.asm_b216
	ld hl, $0272
	call YesOrNoMenuWithText
	ld a, [wd086]
	jr c, .asm_b1b3
	call $7592
	ld a, [wd086]
	jp c, $71b3
	jr .asm_b25e

.asm_b22c
	cp $1
	jr nz, .asm_b24c
	call $735b
	jr c, .asm_b240
	call $76ca
	ld a, [wd086]
	jp c, $71b3
	jr .asm_b25e

.asm_b240
	ld hl, WaitForVBlank
	call DrawWideTextBox_WaitForInput
	ld a, [wd086]
	jp $71b3

.asm_b24c
	cp $2
	jr nz, .asm_b273
	call $735b
	jr c, .asm_b240
	call $77c6
	ld a, [wd086]
	jp nc, $71b3

.asm_b25e
	ld a, [wd087]
	ld [wcea1], a
	call $7379
	call $7704
	call $7545
	ld a, [wd086]
	jp $71b3

.asm_b273
	ret
; 0xb274

	INCROM $b274, $ba04

Func_ba04: ; ba04 (2:7a04)
	ld a, [wd0a9]
	ld hl, $7b83
	sla a
	ld c, a
	ld b, $0
	add hl, bc
	ld de, wd0a2
	ld a, [hli]
	ld [de], a
	inc de
	ld a, [hl]
	ld [de], a
	xor a
	ld [wcea1], a
	call $7b97
	ld a, $5
	ld [wd0a5], a
	xor a
	ld hl, $7b6e
	call InitializeMenuParameters
	ldtx hl, PleaseSelectDeckText
	call DrawWideTextBox_PrintText
	ld a, $5
	ld [wNamingScreenKeyboardHeight], a
	ld hl, $73fe
	ld d, h
	ld a, l
	ld hl, wcece
	ld [hli], a
	ld [hl], d
.asm_ba40
	call DoFrame
	call HandleMenuInput
	jr c, .asm_baa3
	ldh a, [hDPadHeld]
	and D_UP | D_DOWN
	jr z, .asm_ba4e

.asm_ba4e
	ldh a, [hDPadHeld]
	and START
	jr z, .asm_ba40
	ld a, [wcea1]
	ld [wd087], a
	ld b, a
	ld a, [wCurMenuItem]
	ld [wd086], a
	add b
	ld c, a
	inc a
	or $80
	ld [wceb1], a
	sla c
	ld b, $0
	ld hl, wd00d
	add hl, bc
	call $7653
	ld a, [hli]
	ld h, [hl]
	ld l, a
	push hl
	ld bc, $0018
	add hl, bc
	ld d, h
	ld e, l
	ld a, [hl]
	pop hl
	call $7644
	or a
	jr z, .asm_ba40
	ld a, $1
	call Func_90fb
	call $7653
	call Func_8e1f
	call $7644
	ld a, [wd087]
	ld [wcea1], a
	call $7b97
	ld a, [wd086]
	jp $7a25

.asm_baa3
	call DrawCursor2
	ld a, [wcea1]
	ld [wd087], a
	ld a, [wCurMenuItem]
	ld [wd086], a
	ldh a, [hCurMenuItem]
	cp $ff
	jp z, $7b0d
	ld [wd088], a
	call ResetCursorPosAndBlink
	xor a
	ld [wce5e], a
	call DrawWideTextBox
	ld hl, $7b76
	call PlaceTextItems
	call DoFrame
	call $46ac
	jp nc, $7acc
	cp $ff
	jr nz, .asm_badf
	ld a, [wd086]
	jp $7a25

.asm_badf
	ld a, [wCursorDuelYPosition]
	sla a
	ld hl, wCursorDuelXPosition
	add [hl]
	or a
	jr nz, .asm_bb09
	call $7653
	call $77c6
	call $7644
	ld a, [wd086]
	jp nc, $7a25
	ld a, [wd087]
	ld [wcea1], a
	call $7b97
	ld a, [wd086]
	jp $7a25

.asm_bb09
	cp $1
	jr nz, .asm_bb12
	xor a
	ld [wd0a4], a
	ret

.asm_bb12
	ld a, [wcea1]
	ld [wd087], a
	ld b, a
	ld a, [wCurMenuItem]
	ld [wd086], a
	add b
	ld c, a
	ld [wceb1], a
	sla c
	ld b, $0
	ld hl, wd00d
	add hl, bc
	push hl
	ld hl, wd0aa
	add hl, bc
	ld bc, wcfda
	ld a, [hli]
	ld [bc], a
	inc bc
	ld a, [hl]
	ld [bc], a
	pop hl
	call $7653
	ld a, [hli]
	ld h, [hl]
	ld l, a
	push hl
	ld bc, $0018
	add hl, bc
	ld d, h
	ld e, l
	ld a, [hl]
	pop hl
	call $7644
	or a
	jp z, $7a40
	ld a, $1
	call Func_90fb
	call $7653
	xor a
	call $6dfe
	call $7644
	ld a, [wd087]
	ld [wcea1], a
	call $7b97
	ld a, [wd086]
	jp $7a25
; 0xbb6e

	INCROM $bb6e, $c000

.include "global.inc"
.include "hardware.inc"

.segment "ZEROPAGE"
framecount: .res 1
seed: .res 4



Pointer: .res 2     ; Temporary variable for pointers
DrawX: .res 1       ; X pixel coordinate
DrawY: .res 1       ; Y poxel coordinate

TextIdx: .res 1     ; Index used when filling TextBuf
CursorX: .res 1     ; Which digit is selected

; Port monitor stuff
ViewAddress: .res 2 ; 32-byte preview pointer

Address: .res 2     ; Address entered by the user, in big endian
WriteValue: .res 1  ; Value to write when pressing action
ReadValue:  .res 1  ; Value read by pressing menu

.segment "BSS"
keydown: .res 2     ; Keys pressed
keylast: .res 2     ; Keys pressed last frame
keynew:  .res 2     ; Keys pressed that weren't pressed last frame
AutoRepeatTimer: .res 1

TextBuf: .res 24    ; Buffer for the current line of text that will go out

.code
.export Main
Main:
  jsr UpdateKeys

; Make the screen all green
  lda #HEIGHT
  sta DrawY
@RowLoop:
  lda #WIDTH
  sta DrawX
: lda #$00
  sta LCD_DATA
  lda #$f0
  sta LCD_DATA
  dec DrawX
  bne :-
  dec DrawY
  bne @RowLoop

.if 0
DrawImage:
  lda #<Picture     ; Init pointer to the picture
  sta Pointer+0
  lda #>Picture
  sta Pointer+1

DrawImageLoop:      ; Output byte by byte to send the entire picture
  lda (Pointer)
  sta $8001

  inc Pointer+0     ; Increment pointer
  bne :+
    inc Pointer+1
  :

  lda Pointer+0     ; Stop if the end of the picture is reached
  cmp #<PictureEnd
  bne DrawImageLoop
  lda Pointer+1
  cmp #>PictureEnd
  bne DrawImageLoop
.endif

  

WaitLoop:           ; Wait for Menu to be pressed
  jsr UpdateKeys

  lda keynew
  and #KEY_MENU
  beq :+
    jmp MoveTest
  :
  jmp WaitLoop

; ----------------------------------------

MoveTest:           ; Memory explorer
  lda #0            ; Init variables
  sta CursorX
  sta ViewAddress+0
  sta ViewAddress+1

  lda #$80
  sta Address

Forever:
  jsr StartScreen

  ; Display 32 bytes starting at the view address
  ldy #0
ViewLoop:
  lda (ViewAddress),y
  jsr PutHex
  iny
  tya
  and #7
  bne :+
    phy
    jsr PutNewline   ; New line every 8 bytes
    ply
  :
  cpy #$20           ; Stop at 32 bytes
  bne ViewLoop



  ; Write actual menu
  jsr PutNewline

  ; Display the current values for address and write/read bytes
  lda Address+0
  jsr PutHex
  lda Address+1
  jsr PutHex
  lda #16
  jsr PutChar
  lda WriteValue
  jsr PutHex
  lda #16
  jsr PutChar
  lda ReadValue
  jsr PutHex

  jsr PutNewline

  ; ---
  ; Select different digits
  lda keynew
  and #KEY_LEFT
  beq :+
    dec CursorX
  :
  lda keynew
  and #KEY_RIGHT
  beq :+
    inc CursorX
  :

  ; Modify current digit
  lda keynew
  and #KEY_DOWN
  beq NotDown
    lda CursorX
    lsr
    bcs DownOnes
  DownTens:
    tax
    lda Address,x
    sub #$10
    sta Address,x
    bra NotDown
  DownOnes:
    tax
    dec Address,x
  NotDown:

  lda keynew
  and #KEY_UP
  beq NotUp
    lda CursorX
    lsr
    bcs UpOnes
  UpTens:
    tax
    lda Address,x
    add #$10
    sta Address,x
    bra NotUp
  UpOnes:
    tax
    inc Address,x
    bra NotUp
  NotUp:

  ; Menu = read a byte
  lda keynew
  and #KEY_MENU
  beq :+
    lda Address+0
    sta Pointer+1
    lda Address+1
    sta Pointer+0
    ; Read value
    lda (Pointer)
    sta ReadValue
  :

  ; Action = write a byte
  lda keynew+1
  and #KEY_ACTION
  beq :+
    lda Address+0
    sta Pointer+1
    lda Address+1
    sta Pointer+0
    ; Write value
    lda WriteValue
    sta (Pointer)
  :

  ; Mute = switch the bank in Address into BRR
  lda keynew+1
  and #KEY_MUTE
  beq :+
    lda Address+1
    sta BRRL
    lda Address+0
    sta BRRH
  :

  ; Power = move the 32 byte preview to a new spot
  lda keynew
  and #KEY_POWER
  beq :+
    lda Address+1
    sta ViewAddress+0
    lda Address+0
    sta ViewAddress+1
  :


  ; Stay within the 8 selectable columns
  lda CursorX
  and #7
  sta CursorX
  ; ---

  ; Draw cursor
  ldx CursorX
  ldy CursorXOffsets,x
  lda #17
  sta TextBuf,y
  jsr PutNewline

  jsr FinishScreen
  jsr UpdateKeys
  jmp Forever


; --------------------------------------

CursorXOffsets:
  .byt 0, 1, 2, 3, 5, 6, 8, 9

; Start the text screen and init stuff
StartScreen:
  lda #0
  sta DrawX
  sta DrawY
  jmp ClearTextBuf

; Finish the text screen and send out any remaining pixels
FinishScreen:
  ; Draw screen row 
  lda TextIdx
  beq :+
    jsr DrawTextRow
  :

  ; Send green for as many pixels are left
: lda #$00
  sta $8001
  lda #$f0
  sta $8001

  inc DrawX
  lda DrawX
  cmp #WIDTH
  bne :-
  lda #0
  sta DrawX

  inc DrawY
  lda DrawY
  cmp #HEIGHT
  bne :-
  rts

; --------------------------------------

; Send current row, move onto the next row
PutNewline:
  jsr DrawTextRow
  jmp ClearTextBuf

; Print the byte in A in hexadecimal
PutHex:
  pha
  lsr
  lsr
  lsr
  lsr
  jsr PutChar
  pla
  and #15
; Print one character
PutChar:
  phx
  ldx TextIdx
  sta TextBuf,x
  inc TextIdx
  plx
  rts

; Clear the text buffer
ClearTextBuf:
  ldx #23
  lda #0
  sta TextIdx
  lda #16
: sta TextBuf,x
  dex
  bpl :-
  rts

; Draw a row of text
DrawTextRow:
  jsr DrawTextRow1
  jsr DrawTextRow2
  jsr DrawTextRow2
  jsr DrawTextRow3
  jsr DrawTextRow4
  jsr DrawTextRow4
  jsr DrawTextRow5

  ; Add a row of white as a spacer
  ldx #WIDTH
: jsr WhitePixel
  dex
  bne :-
  inc DrawY
  rts


DrawTextRow1:
  ldx #0
: ldy TextBuf,x
  lda Font1,y
  jsr DrawCharRow
  inx
  cpx #24
  bne :-
  bra DrawTextRowCommon

DrawTextRow2:
  ldx #0
: ldy TextBuf,x
  lda Font2,y
  jsr DrawCharRow
  inx
  cpx #24
  bne :-
  bra DrawTextRowCommon

DrawTextRow3:
  ldx #0
: ldy TextBuf,x
  lda Font3,y
  jsr DrawCharRow
  inx
  cpx #24
  bne :-
  bra DrawTextRowCommon

DrawTextRow4:
  ldx #0
: ldy TextBuf,x
  lda Font4,y
  jsr DrawCharRow
  inx
  cpx #24
  bne :-
  bra DrawTextRowCommon

DrawTextRow5:
  ldx #0
: ldy TextBuf,x
  lda Font5,y
  jsr DrawCharRow
  inx
  cpx #24
  bne :-
  bra DrawTextRowCommon

DrawTextRowCommon:
  ; Round out the 96 pixels of text with 2 more
  jsr WhitePixel
  jsr WhitePixel

  inc DrawY
  rts


DrawCharRow:         ; Draw a whole character row
  jsr DrawCharRowOne
  jsr DrawCharRowOne
  jsr DrawCharRowOne
DrawCharRowOne:      ; Draw one pixel from the row
  and #%1111
  asl
  cmp #%10000
  bcs BlackPixel

WhitePixel:
  pha
  lda #$0f
  sta $8001
  lda #$ff
  sta $8001
  pla
  rts
BlackPixel:
  pha
  lda #$00
  sta $8001
  sta $8001
  pla
  rts

; --------------------------------------

UpdateKeys:
; Set 1
  lda keydown+0
  sta keylast+0
  lda PA
  eor #255 ; Make 1=pressed, 0=unpressed
  sta keydown+0

  lda keylast+0
  eor #255
  and keydown+0
  sta keynew+0
; Set 2
  lda keydown+1
  sta keylast+1
  lda PB
  eor #255 ; Make 1=pressed, 0=unpressed
  sta keydown+1

  lda keylast+1
  eor #255
  and keydown+1
  sta keynew+1
  rts

;Picture:
;  .incbin "picture.bin"
;PictureEnd:

Font1:
  .byt %111 ;0
  .byt %010 ;1
  .byt %010 ;2
  .byt %110 ;3
  .byt %101 ;4
  .byt %111 ;5
  .byt %011 ;6
  .byt %111 ;7
  .byt %010 ;8
  .byt %111 ;9
  .byt %010 ;A
  .byt %110 ;B
  .byt %011 ;C
  .byt %110 ;D
  .byt %111 ;E
  .byt %111 ;F
  .byt %000 ; 
  .byt %111 ; 
Font2:
  .byt %101 ;0
  .byt %110 ;1
  .byt %101 ;2
  .byt %001 ;3
  .byt %101 ;4
  .byt %100 ;5
  .byt %100 ;6
  .byt %001 ;7
  .byt %101 ;8
  .byt %101 ;9
  .byt %101 ;A
  .byt %101 ;B
  .byt %100 ;C
  .byt %101 ;D
  .byt %100 ;E
  .byt %100 ;F
  .byt %000 ; 
  .byt %111 ; 
Font3:
  .byt %101 ;0
  .byt %010 ;1
  .byt %001 ;2
  .byt %110 ;3
  .byt %111 ;4
  .byt %111 ;5
  .byt %111 ;6
  .byt %010 ;7
  .byt %010 ;8
  .byt %111 ;9
  .byt %111 ;A
  .byt %110 ;B
  .byt %100 ;C
  .byt %101 ;D
  .byt %111 ;E
  .byt %111 ;F
  .byt %000 ; 
  .byt %111 ; 
Font4:
  .byt %101 ;0
  .byt %010 ;1
  .byt %010 ;2
  .byt %001 ;3
  .byt %001 ;4
  .byt %001 ;5
  .byt %101 ;6
  .byt %010 ;7
  .byt %101 ;8
  .byt %001 ;9
  .byt %101 ;A
  .byt %101 ;B
  .byt %100 ;C
  .byt %101 ;D
  .byt %100 ;E
  .byt %100 ;F
  .byt %000 ; 
  .byt %111 ; 
Font5:
  .byt %111 ;0
  .byt %111 ;1
  .byt %111 ;2
  .byt %110 ;3
  .byt %001 ;4
  .byt %110 ;5
  .byt %111 ;6
  .byt %100 ;7
  .byt %010 ;8
  .byt %110 ;9
  .byt %101 ;A
  .byt %110 ;B
  .byt %011 ;C
  .byt %110 ;D
  .byt %111 ;E
  .byt %100 ;F
  .byt %000 ; 
  .byt %111 ; 

.proc KeyRepeat
  lda keydown
  beq NoAutorepeat
  cmp keylast
  bne NoAutorepeat
  inc AutoRepeatTimer
  lda AutoRepeatTimer
  cmp #12
  bcc SkipNoAutorepeat

  lda framecount
  and #3
  bne :+
  lda keydown
  and #KEY_LEFT|KEY_RIGHT|KEY_UP|KEY_DOWN
  ora keynew
  sta keynew
:

  ; Keep it from going up to 255 and resetting
  dec AutoRepeatTimer
  bne SkipNoAutorepeat
NoAutorepeat:
  stz PlaceBlockAutorepeat
SkipNoAutorepeat:
  rts
.endproc

.proc BCD99
  .byt $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19
  .byt $20, $21, $22, $23, $24, $25, $26, $27, $28, $29, $30, $31, $32, $33, $34, $35, $36, $37, $38, $39
  .byt $40, $41, $42, $43, $44, $45, $46, $47, $48, $49, $50, $51, $52, $53, $54, $55, $56, $57, $58, $59
  .byt $60, $61, $62, $63, $64, $65, $66, $67, $68, $69, $70, $71, $72, $73, $74, $75, $76, $77, $78, $79
  .byt $80, $81, $82, $83, $84, $85, $86, $87, $88, $89, $90, $91, $92, $93, $94, $95, $96, $97, $98, $99
.endproc

.proc RandomByte
  phy
  ; rotate the middle bytes left
  ldy seed+2 ; will move to seed+3 at the end
  lda seed+1
  sta seed+2
  ; compute seed+1 ($C5>>1 = %1100010)
  lda seed+3 ; original high byte
  lsr
  sta seed+1 ; reverse: 100011
  lsr
  lsr
  lsr
  lsr
  eor seed+1
  lsr
  eor seed+1
  eor seed+0 ; combine with original low byte
  sta seed+1
  ; compute seed+0 ($C5 = %11000101)
  lda seed+3 ; original high byte
  asl
  eor seed+3
  asl
  asl
  asl
  asl
  eor seed+3
  asl
  asl
  eor seed+3
  sty seed+3 ; finish rotating byte 2 into 3
  ply
  sta seed+0
  rts
.endproc

.segment "ZEROPAGE"
  MaxNumTileUpdates  = 4
  TileUpdateA1:    .res MaxNumTileUpdates ; \ address
  TileUpdateA2:    .res MaxNumTileUpdates ; /
  TileUpdateT:     .res MaxNumTileUpdates ; new byte
  PlaceBlockAutorepeat: .res 1 ; Autorepeat timer
  TempVal:     .res 4
  TempX:       .res 1 ; for saving the X register
  TempY:       .res 1 ; for saving the Y register
  OamPtr:      .res 1
  PlayerDir:   .res 1
  TouchTemp:   .res 10

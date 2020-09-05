.include "global.inc"
.include "hardware.inc"

.import Main
.segment "INIT"
  lda #$a7 ;colors
  sta LCD_CTRL

  lda #$5c ;start entering colors
  sta LCD_CTRL
  jmp Main

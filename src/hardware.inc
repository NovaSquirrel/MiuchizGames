; based on http://meuk.spritesserver.nl/st2205um.pdf
.PC02 ; enable 65c02

;------------------------------
; Datasheet register names:
;------------------------------
; I/O ports A-F and L
PA      = $00 ; Keys set 1
              ; TtMP RLDU
              ; |||| |||+- d-pad up
              ; |||| ||+-- d-pad down
              ; |||| |+--- d-pad left
              ; |||| +---- d-pad right
              ; |||+------ power
              ; ||+------- menu
              ; |+-------- upside up
              ; +--------- upside down

PB      = $01 ; Keys set 2
              ; ??MA rlRL
              ; |||| |||+- screen top left
              ; |||| ||+-- screen top right
              ; |||| |+--- screen bottom left
              ; |||| +---- screen bottom right
              ; |||+------ action
              ; ||+------- mute
              ; ++-------- unknown outputs
; Note: Keys read 0 for pressed, 1 for unpressed

PC      = $02 ; Unknown input
PD      = $03 ; Unknown output
PE      = $04
PF      = $05 ; Unknown Output. Toggles 8 every second or so? 
PL      = $4e ; Unknown

; Port type select?
PSC     = $06
PSE     = $07

; Data direction for I/O ports A-F and L (1 is output, 0 is input)
PCA     = $08
PCB     = $09
PCC     = $0a
PCD     = $0b
PCE     = $0c
PCF     = $0d
PCL     = $4f

; Port function control registers
PFC     = $0e
PFD     = $0f

; Port miscellaneous control register
PMCR    = $3a

; ----------------------------

PSG0A   = $10
PSG0B   = $11
PSG1A   = $12
PSG1B   = $13
PSG2A   = $14
PSG2B   = $15
PSG3A   = $16
PSG3B   = $17
VOL0    = $18
VOL1    = $19
VOL2    = $1a
VOL3    = $1b
VOLM0   = $1c
VOLM1   = $1d
PSGC    = $1e
PSGM    = $1f
T0CL    = $20
T0CH    = $21
T1CL    = $22
T1CH    = $23
T2CL    = $24
T2CH    = $25
T3CL    = $26
T3CH    = $27
TIEN    = $28
PRS     = $29
BTEN    = $2a
BTREQ   = $2b
BTC     = $2c
T4C     = $2d
RCTR    = $2e
RCT     = $2f

; Interrupt bank register
IRRL    = $30
IRRH    = $31
; Overrides PRR when an interrupt happens
; until an RTI instruction is executed.

; Bank switching registers
PRRL    = $32 ; \ $4000-$7fff (16KB)
PRRH    = $33 ; /
DRRL    = $34 ; \ $8000-$ffff (32KB)
DRRH    = $35 ; /
BRRL    = $36 ; \ $2000-$3fff (8KB)
BRRH    = $37 ; /
; Each register can only select multiples of its size and there
; are not unused bits on the bottom like MMC3.
; Setting the most significant bit selects the 32KB internal RAM.

; Internal RAM is NOT bankable, and instead the address falls through.
; $2000-$3fff, when set to RAM, accesses $2000-$3fff in RAM.
; $4000-$7fff, when set to RAM, accesses $4000-$7fff in RAM.
; $8000-$ffff, however, provides access to the entire 32KB range.

MISC    = $38
SYS     = $39

XREG    = $3b

; Interrupt request register
IREQL   = $3c
IREQH   = $3d

; Interrupt enable register
IENAL   = $3e
IENAH   = $3f

LSSAL   = $40
LSSAH   = $41
LVPW    = $42
LXMAX   = $43
LYMAX   = $44
LPAN    = $45
LBUF    = $46
LCTR    = $47
LCKR    = $48
LFRA    = $49
LAC     = $4a
LPWM    = $4b
LPAL    = $4c
SDATAL  = $50
SDATAH  = $51
SCTR    = $52
SCKR    = $53
SSR     = $54
SMOD    = $55
LVCTR   = $57
DPTRL   = $58
DPTRH   = $59
DBKRL   = $5a
DBKRH   = $5b
DCNTL   = $5c
DCNTH   = $5d
DCTR    = $5e
DMOD    = $5f
UCTR    = $60
USR     = $61
IRCTR   = $62
BCTR    = $63
UDATA   = $64
BRIS    = $66
BDIV    = $67
FCTR    = $68
ECCL    = $69
ECCM    = $6a
ECCH    = $6b
PCML    = $6c
PCMH    = $6d
MULL    = $6e
MULH    = $6f
USBCON  = $70
USBIEN  = $71
USBIRQ  = $72
USBBFS  = $73
EXP0CON = $74
EXP0LEN = $75
BKCON   = $76
BKOLEN  = $77







;------------------------------
; Constants:
;------------------------------
KEY_UP        = 1
KEY_DOWN      = 2
KEY_LEFT      = 4
KEY_RIGHT     = 8
KEY_POWER     = 16
KEY_MENU      = 32
KEY_UPSIDE_UP = 64
KEY_UPSIDE_DN = 128

; Second byte
KEY_SCREEN_TL = 1
KEY_SCREEN_TR = 2
KEY_SCREEN_BL = 4
KEY_SCREEN_BR = 8
KEY_ACTION    = 16
KEY_MUTE      = 32

WIDTH = 98
HEIGHT = 67

KEYS = $0000

;------------------------------
; Friendlier names:
;------------------------------
Timer0Low  = T0CL
Timer0High = T0CH
Timer1Low  = T1CL
Timer1High = T1CH
Timer2Low  = T2CL
Timer2High = T2CH
Timer3Low  = T3CL
Timer3High = T3CH

MULTIPLY_LOW  = MULL ; write once
MULTIPLY_HIGH = MULH ; write twice

DMASELECT = DCTR
DMA_CHANNEL_0   = %00
DMA_CHANNEL_1   = %10
DMA_SOURCE      = %00
DMA_DESTINATION = %01

DMAADDRLO   = DPTRL
DMAADDRHI   = DPTRH

DMABANKLO   = DBKRL
DMABANKHI   = DBKRH

DMALEN   = DCNTL
DMALENHI = DCNTH ; Initiates the transfer

DMAMODE = DMOD
DMA_SOURCE_CONTINUE       = %00
DMA_SOURCE_RELOAD         = %01
DMA_SOURCE_FIXED          = %10
DMA_DESTINATION_CONTINUE  = %00 << 2
DMA_DESTINATION_RELOAD    = %01 << 2
DMA_DESTINATION_FIXED     = %10 << 2
DMA_XOR = %01 << 4 
DMA_OR  = %10 << 4
DMA_AND = %11 << 4


;------------------------------
; LCD information
;------------------------------
LCD_CTRL = $8000
LCD_DATA = $8001



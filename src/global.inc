.macpack generic
.macpack longbranch
.pc02

; Temporary variables
v0  = $80
v1  = $81
v2  = $82
v3  = $83
v4  = $84
v5  = $85
v6  = $86
v7  = $87
v8  = $88
v9  = $89
v10 = $8a
v11 = $8b
v12 = $8c
v13 = $8d
v14 = $8e
v15 = $8f

; Global variables
.globalzp framecount, seed
.global keydown, keynew, keylast

; Global routines
.global RandomByte, UpdateKeys

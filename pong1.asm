  .inesprg 1   ; 1x 16KB PRG code
  .ineschr 1   ; 1x  8KB CHR data
  .inesmap 0   ; mapper 0 = NROM, no bank swapping
  .inesmir 1   ; background mirroring
  

;;;;;;;;;;;;;;;

;; DECLARE SOME VARIABLES HERE
  .rsset $0000  ;;start variables at ram location 0
  
gamestate  .rs 1  ; .rs 1 means reserve one byte of space
ballx      .rs 1  ; ball horizontal position
bally      .rs 1  ; ball vertical position
ballup     .rs 1  ; 1 = ball moving up
balldown   .rs 1  ; 1 = ball moving down
ballleft   .rs 1  ; 1 = ball moving left
ballright  .rs 1  ; 1 = ball moving right
ballspeedx .rs 1  ; ball horizontal speed per frame
ballspeedy .rs 1  ; ball vertical speed per frame
paddle1ytop   .rs 1  ; player 1 paddle top vertical position
paddle2ytop   .rs 1  ; player 2 paddle bottom vertical position
buttons1   .rs 1  ; player 1 gamepad buttons, one bit per button
buttons2   .rs 1  ; player 2 gamepad buttons, one bit per button
score1     .rs 1  ; player 1 score, 0-15
score2     .rs 1  ; player 2 score, 0-15


;; DECLARE SOME CONSTANTS HERE
STATETITLE     = $00  ; displaying title screen
STATEPLAYING   = $01  ; move paddles/ball, check for collisions
STATEGAMEOVER  = $02  ; displaying game over screen
  
RIGHTWALL      = $F4  ; when ball reaches one of these, do something
RIGHTWALLOFFS  = $EA

TOPWALL        = $20
BOTTOMWALL     = $E0
BOTTOMWALLOFFS = $D0
LEFTWALL       = $04
LEFTWALLOFFS   = $10
  
PADDLE1X       = $08  ; horizontal position for paddles, doesnt move
PADDLE2X       = $F0

PADDLE_LEN_SPR = $04
PADDLE_LEN_PIXELS = $20

BALL_Y_START_POS = $50
BALL_X_START_POS = $80

;;;;;;;;;;;;;;;;;;

  .bank 0
  .org $C000 
RESET:
  SEI          ; disable IRQs
  CLD          ; disable decimal mode
  LDX #$40
  STX $4017    ; disable APU frame IRQ
  LDX #$FF
  TXS          ; Set up stack
  INX          ; now X = 0
  STX $2000    ; disable NMI
  STX $2001    ; disable rendering
  STX $4010    ; disable DMC IRQs

vblankwait1:       ; First wait for vblank to make sure PPU is ready
  BIT $2002
  BPL vblankwait1

clrmem:
  LDA #$00
  STA $0000, x
  STA $0100, x
  STA $0300, x
  STA $0400, x
  STA $0500, x
  STA $0600, x
  STA $0700, x
  LDA #$FE
  STA $0200, x
  INX
  BNE clrmem
   
vblankwait2:      ; Second wait for vblank, PPU is ready after this
  BIT $2002
  BPL vblankwait2

LoadPalettes:
  LDA $2002             ; read PPU status to reset the high/low latch
  LDA #$3F
  STA $2006             ; write the high byte of $3F00 address
  LDA #$00
  STA $2006             ; write the low byte of $3F00 address
  LDX #$00              ; start out at 0
LoadPalettesLoop:
  LDA palette, x        ; load data from address (palette + the value in x)
                          ; 1st time through loop it will load palette+0
                          ; 2nd time through loop it will load palette+1
                          ; 3rd time through loop it will load palette+2
                          ; etc
  STA $2007             ; write to PPU
  INX                   ; X = X + 1
  CPX #$20              ; Compare X to hex $10, decimal 16 - copying 16 bytes = 4 sprites
  BNE LoadPalettesLoop  ; Branch to LoadPalettesLoop if compare was Not Equal to zero
                        ; if compare was equal to 32, keep going down

LoadBackground:
  LDA $2002             ; read PPU status to reset the high/low latch
  LDA #$20
  STA $2006             ; write the high byte of $2000 address
  LDA #$00
  STA $2006             ; write the low byte of $2000 address
	
  LDX #$00              ; start out at 0
  LDY #$00
LoadScoreBackgroundLoop:
  LDA scoreBackground        ; load data from address (background)
  STA $2007             ; write to PPU
  INX                   ; X = X + 1
  CPX #$20              ; Compare X to hex $80, decimal 128 - copying 128 bytes
  BNE LoadScoreBackgroundLoop  ; Branch to LoadBackgroundLoop if compare was Not Equal to zero
                        ; if compare was equal to 128, keep going down
	
  LDX #$00
  INY
  CPY #$03
  BNE LoadScoreBackgroundLoop

  LDX #$00              ; start out at 0
LoadWallBackgroundLoop:
  LDA wallBackground        ; load data from address (background)
  STA $2007             ; write to PPU
  INX                   ; X = X + 1
  CPX #$20              ; Compare X to hex $80, decimal 128 - copying 128 bytes
  BNE LoadWallBackgroundLoop  ; Branch to LoadBackgroundLoop if compare was Not Equal to zero
                        ; if compare was equal to 128, keep going down
  
	
  LDY #$00
  LDX #$00
LoadBackgroundLoop:
  LDA mainBackground        ; load data from address (background)
  STA $2007             ; write to PPU
  INX                   ; X = X + 1
  CPX #$20              ; Compare X to hex $80, decimal 128 - copying 128 bytes
  BNE LoadBackgroundLoop  ; Branch to LoadBackgroundLoop if compare was Not Equal to zero
                        ; if compare was equal to 128, keep going down

  LDX #$00
  INY
  CPY #$1A
  BNE LoadBackgroundLoop  ; Branch to LoadBackgroundLoop if compare was Not Equal to zero
                        ; if compare was equal to 128, keep going down
	

	

;;;Set some initial ball stats
  LDA #$00
  STA balldown
  STA ballright
  LDA #$01
  STA ballup
  STA ballleft
  
  LDA #BALL_Y_START_POS
  STA bally
  
  LDA #BALL_X_START_POS
  STA ballx
  
  LDA #$01
  STA ballspeedx
  STA ballspeedy

;;; Set initial paddle state
  LDA #$80
  STA paddle1ytop
  STA paddle2ytop
  	
;;:Set starting game state
  LDA #STATEPLAYING
  STA gamestate
              
  LDA #%10010000   ; enable NMI, sprites from Pattern Table 0, background from Pattern Table 1
  STA $2000

  LDA #%00011110   ; enable sprites, disable background, no clipping on left side
  STA $2001

Forever:
  JMP Forever     ;jump back to Forever, infinite loop, waiting for NMI
  
NMI:
  LDA #$00
  STA $2003       ; set the low byte (00) of the RAM address
  LDA #$02
  STA $4014       ; set the high byte (02) of the RAM address, start the transfer

  JSR DrawScore

  ;;This is the PPU clean up section, so rendering the next frame starts properly.
  LDA #%10010000   ; enable NMI, sprites from Pattern Table 0, background from Pattern Table 1
  STA $2000
  LDA #%00011110   ; enable sprites, disable background, no clipping on left side
  STA $2001
  LDA #$00        ;;tell the ppu there is no background scrolling
  STA $2005
  STA $2005
    
  ;;;all graphics updates done by here, run game engine
  JSR ReadController1  ;;get the current button data for player 1
  JSR ReadController2  ;;get the current button data for player 2
  
GameEngine:  
  LDA gamestate
  CMP #STATETITLE
  BEQ EngineTitle    ;;game is displaying title screen
    
  LDA gamestate
  CMP #STATEGAMEOVER
  BEQ EngineGameOver  ;;game is displaying ending screen
  
  LDA gamestate
  CMP #STATEPLAYING
  BEQ EnginePlaying   ;;game is playing
GameEngineDone:  
  
  JSR UpdateSprites  ;;set ball/paddle sprites from positions

  RTI             ; return from interrupt
 
;;;;;;;;
 
EngineTitle:
  ;;if start button pressed
  ;;  turn screen off
  ;;  load game screen
  ;;  set starting paddle/ball position
  ;;  go to Playing State
  ;;  turn screen on
  JMP GameEngineDone

;;;;;;;;; 
 
EngineGameOver:
  ;;if start button pressed
  ;;  turn screen off
  ;;  load title screen
  ;;  go to Title State
  ;;  turn screen on 
  JMP GameEngineDone
 
;;;;;;;;;;;
 
EnginePlaying:

MoveBallRight:
  LDA ballright
  BEQ MoveBallRightDone   ;;if ballright=0, skip this section

  LDA ballx
  CLC
  ADC ballspeedx        ;;ballx position = ballx + ballspeedx
  STA ballx

  CMP #RIGHTWALL
  BCC MoveBallRightDone      ;;if ball x < right wall, still on screen, skip next section

  INC score1 ;; Inc score
  
  ;; Reset ball state
  LDA #BALL_Y_START_POS
  STA bally
  
  LDA #BALL_X_START_POS
  STA ballx

  LDA #$00
  STA ballright
  LDA #$01
  STA ballleft         ;; ball now moving left
MoveBallRightDone:

MoveBallLeft:
  LDA ballleft
  BEQ MoveBallLeftDone   ;;if ballleft=0, skip this section

  LDA ballx
  SEC
  SBC ballspeedx        ;;ballx position = ballx - ballspeedx
  STA ballx

  ;; Give point to player 2, reset ball
  CMP #LEFTWALL
  BCS MoveBallLeftDone      

  INC score2 ;; Inc player 2 score
  
  ;; Reset ball state
  LDA #BALL_Y_START_POS
  STA bally
  
  LDA #BALL_X_START_POS
  STA ballx

  LDA #$01
  STA ballright
  LDA #$00
  STA ballleft         ;; ball now moving left
MoveBallLeftDone:

MoveBallUp:
  LDA ballup
  BEQ MoveBallUpDone   ;;if ballup=0, skip this section

  LDA bally
  SEC
  SBC ballspeedy        ;;bally position = bally - ballspeedy
  STA bally

  LDA bally
  CMP #TOPWALL
  BCS MoveBallUpDone      ;;if ball y > top wall, still on screen, skip next section
  LDA #$01
  STA balldown
  LDA #$00
  STA ballup         ;;bounce, ball now moving down
MoveBallUpDone:

MoveBallDown:
  LDA balldown
  BEQ MoveBallDownDone   ;;if ballup=0, skip this section

  LDA bally
  CLC
  ADC ballspeedy        ;;bally position = bally + ballspeedy
  STA bally

  LDA bally
  CMP #BOTTOMWALL
  BCC MoveBallDownDone      ;;if ball y < bottom wall, still on screen, skip next section
  LDA #$00
  STA balldown
  LDA #$01
  STA ballup         ;;bounce, ball now moving down
MoveBallDownDone:

MovePaddle1Up:
  ;;if up button pressed
  LDA buttons1
  AND #%00001000
  BEQ MovePaddle1UpDone ;; not pressed, skip

  LDA paddle1ytop 
  CMP #TOPWALL ;; Check if we have hit top wall

  BCC MovePaddle1UpDone ;; If so, skip

  DEC paddle1ytop ;; Decrement position	
MovePaddle1UpDone:

MovePaddle1Down:
  ;;if down button pressed
  ;;  if paddle bottom < bottom wall
  ;;    move paddle top and bottom down
  LDA buttons1
  AND #%00000100
  BEQ MovePaddle1DownDone ;; not pressed, skip

  LDA paddle1ytop 
  CMP #BOTTOMWALLOFFS ;; Check if we have hit top wall

  BCS MovePaddle1DownDone ;; If so, skip

  INC paddle1ytop ;; Decrement position
MovePaddle1DownDone:

MovePaddle2Up:
  ;;if up button pressed
  LDA buttons2
  AND #%00001000
  BEQ MovePaddle2UpDone ;; not pressed, skip

  LDA paddle2ytop 
  CMP #TOPWALL ;; Check if we have hit top wall

  BCC MovePaddle2UpDone ;; If so, skip

  DEC paddle2ytop ;; Decrement position	
MovePaddle2UpDone:

MovePaddle2Down:
  ;;if down button pressed
  ;;  if paddle bottom < bottom wall
  ;;    move paddle top and bottom down
  LDA buttons2
  AND #%00000100
  BEQ MovePaddle2DownDone ;; not pressed, skip

  LDA paddle2ytop 
  CMP #BOTTOMWALLOFFS ;; Check if we have hit top wall

  BCS MovePaddle2DownDone ;; If so, skip

  INC paddle2ytop ;; Decrement position
MovePaddle2DownDone:
	
CheckPaddle1Collision:
  ;;if ball x < paddle1x
  ;;  if ball y > paddle y top
  ;;    if ball y < paddle y bottom
  ;;      bounce, ball now moving left
  ;; Check if on paddle x position
  LDA ballx
  CMP #LEFTWALLOFFS
  BCS CheckPaddle1CollisionDone

  ;; Check if ball is above paddle
  LDA bally
  CMP paddle1ytop
  BCC CheckPaddle1CollisionDone

  ;; Check if ball is below paddle
  LDA paddle1ytop
  CLC
  ADC #PADDLE_LEN_PIXELS
  CMP bally
  BCC CheckPaddle1CollisionDone

  ;; Bounce, ball now moving right
  LDA #$01
  STA ballright
  LDA #$00
  STA ballleft         
CheckPaddle1CollisionDone:

CheckPaddle2Collision:
  ;;if ball x < paddle1x
  ;;  if ball y > paddle y top
  ;;    if ball y < paddle y bottom
  ;;      bounce, ball now moving left
  ;; Check if on paddle x position
  LDA ballx
  CMP #RIGHTWALLOFFS
  BCC CheckPaddle2CollisionDone

  ;; Check if ball is above paddle
  LDA bally
  CMP paddle2ytop
  BCC CheckPaddle2CollisionDone

  ;; Check if ball is below paddle
  LDA paddle2ytop
  CLC
  ADC #PADDLE_LEN_PIXELS
  CMP bally
  BCC CheckPaddle2CollisionDone

  ;; Bounce, ball now moving left
  LDA #$01
  STA ballleft
  LDA #$00
  STA ballright         
CheckPaddle2CollisionDone:
	
  JMP GameEngineDone

UpdateSprites:
  LDA bally  ;; update all ball sprite info
  STA $0200
  
  LDA #$75
  STA $0201
  
  LDA #$03
  STA $0202
   
  LDA ballx
  STA $0203
  
  ;;update paddle 1 sprites
  LDY paddle1ytop ;; load ball position and add paddle offset
  LDX #$00
  
.DrawPaddle1Part
  TXA
  CLC
  ;; Shift X two bits to the left
  ASL A
  ASL A
  TAX
  TYA
     
  STA $0204, x ;; store position in sprite offset
  
  LDA #$86
  STA $0205, x
  
  LDA #$02
  STA $0206, x
   
  LDA #PADDLE1X
  STA $0207, x

  TXA
  CLC
  ROR A
  ROR A
  TAX
  INX

  TYA
  CLC
  ADC #$08
  TAY

  CPX #PADDLE_LEN_SPR
  BNE .DrawPaddle1Part

  ;;update paddle 2 sprites
  LDY paddle2ytop ;; load ball position and add paddle offset
  LDX #$00
  
.DrawPaddle2Part
  TXA
  CLC
  ;; Shift X two bits to the left
  ASL A
  ASL A
  TAX
  TYA

  STA $0214, x ;; store position in sprite offset

  LDA #$86
  STA $0215, x

  LDA #$02
  STA $0216, x

  LDA #PADDLE2X
  STA $0217, x

  TXA
  CLC
  ROR A
  ROR A
  TAX
  INX

  TYA
  CLC
  ADC #$08
  TAY

  CPX #PADDLE_LEN_SPR
  BNE .DrawPaddle2Part

  RTS
  
DrawScore:
  ;;draw score on screen using background tiles
  

  RTS
 
ReadController1:
  LDA #$01
  STA $4016
  LDA #$00
  STA $4016
  LDX #$08
ReadController1Loop:
  LDA $4016
  LSR A            ; bit0 -> Carry
  ROL buttons1     ; bit0 <- Carry
  DEX
  BNE ReadController1Loop
  RTS
  
ReadController2:
  LDA #$01
  STA $4016
  LDA #$00
  STA $4016
  LDX #$08
ReadController2Loop:
  LDA $4017
  LSR A            ; bit0 -> Carry
  ROL buttons2     ; bit0 <- Carry
  DEX
  BNE ReadController2Loop
  RTS  
          
;;;;;;;;;;;;;;  
  
  .bank 1
  .org $E000
palette:
  .db $22,$29,$1A,$0F,  $22,$36,$17,$0F,  $22,$30,$21,$0F,  $22,$27,$17,$0F   ;;background palette
  .db $22,$1C,$15,$14,  $22,$02,$38,$3C,  $22,$10,$15,$07,  $37,$36,$38,$2D   ;;sprite palette

sprites:
     ;vert tile attr horiz
  .db $80, $32, $00, $80   ;sprite 0
  .db $80, $33, $00, $88   ;sprite 1
  .db $88, $34, $00, $80   ;sprite 2
  .db $88, $35, $00, $88   ;sprite 3

scoreBackground:
  .db $24

mainBackground:
  .db $25

wallBackground:
  .db $47
	
background:
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  ;;row 1
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  ;;all sky

  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  ;;row 2
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  ;;all sky

  .db $24,$24,$24,$24,$45,$45,$24,$24,$45,$45,$45,$45,$45,$45,$24,$24  ;;row 3
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$53,$54,$24,$24  ;;some brick tops

  .db $24,$24,$24,$24,$47,$47,$24,$24,$47,$47,$47,$47,$47,$47,$24,$24  ;;row 4
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$55,$56,$24,$24  ;;brick bottoms

  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  ;;row 5
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  ;;all sky

  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  ;;row 6
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  ;;all sky

  .db $24,$24,$24,$24,$45,$45,$24,$24,$45,$45,$45,$45,$45,$45,$24,$24  ;;row 7
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$53,$54,$24,$24  ;;some brick tops

  .db $24,$24,$24,$24,$47,$47,$24,$24,$47,$47,$47,$47,$47,$47,$24,$24  ;;row 8
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$55,$56,$24,$24  ;;brick bottoms

	
attribute:
  .db %00000000, %00010000, %01010000, %00010000, %00000000, %00000000, %00000000, %00110000

  .db $24,$24,$24,$24, $47,$47,$24,$24 ,$47,$47,$47,$47, $47,$47,$24,$24 ,$24,$24,$24,$24 ,$24,$24,$24,$24, $24,$24,$24,$24, $55,$56,$24,$24  ;;brick bottoms


  .org $FFFA     ;first of the three vectors starts here
  .dw NMI        ;when an NMI happens (once per frame if enabled) the 
                   ;processor will jump to the label NMI:
  .dw RESET      ;when the processor first turns on or is reset, it will jump
                   ;to the label RESET:
  .dw 0          ;external interrupt IRQ is not used in this tutorial
  
  
;;;;;;;;;;;;;;  
  
  
  .bank 2
  .org $0000
  .incbin "mario.chr"   ;includes 8KB graphics file from SMB1

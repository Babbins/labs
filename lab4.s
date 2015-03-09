	AREA	GPIO, CODE, READWRITE	
	EXPORT  lab4   
	EXPORT  gpio_setup
	EXTERN  read_character
	EXTERN	output_character
	EXTERN	read_string
	EXTERN	output_string
	EXTERN	newline
	EXTERN  newpage
	EXTERN	pin_block
	EXTERN	uart_init
	EXTERN string_to_int
	extern read_char
	extern reverse_nibble

;Zachary Esmaelzada, zbesmael
;Ali Mahmoud, alimahmo

stringaddress DCD 0x00000000
	ALIGN
PINSEL0 equ 0xe002c000			
IO0DIR  equ 0xE0028008
IO1DIR  equ 0xE0028018
IO0SET	EQU 0xE0028004 
IO1SET	EQU 0xE0028014
IO0CLR	EQU 0xE002800C
IO1CLR	EQU 0xE002801C
IO1PIN  equ 0xE0028010
IO0PIN  equ 0xE0028000
	ALIGN


prompt	= "Choose from:  [s]-Seven Segment Display, [p]-Pushbuttons, [r]-RGB LED, or [l]-LEDs: ",0   ; Text to be sent to PuTTy
	ALIGN
prompt1  = "(Seven Segment Display) Enter a number [0-15] to be displayed. ",0
	ALIGN
prompt2 = "(Read Push Buttons) Hold down the desired buttons and hit 'Enter'",0
	ALIGN
result2 = "Pushbuttons pressed denote this number in binary: ",0
	ALIGN
zprompt1 = "(LEDs) Enter a number [0-15] to be displayed in binary with leds",0
	ALIGN
zprompt2 = "Check out those LEDs!",0
	ALIGN
zprompt3 = "(RGB LED) [r] - red | [g] - green | [b] - blue | [p] - purple | [y] - yellow | [w] - white |",0
	ALIGN
		
digits_SET	;table that corresponds integers 1-15 to LEDs on seven segment display
		DCD 0x00001F80  ; 0
 		DCD 0x00001800  ; 1
		DCD 0x00002D80	; 2
		DCD 0x00002780	; 3
		DCD 0x00003300	; 4
		DCD 0x00003680	; 5
		DCD 0x00003E80	; 6
		DCD 0x00000380	; 7
		DCD 0x00003F80	; 8
		DCD 0x00003380  ; 9
		DCD 0x00003B80 	; A
		DCD 0x00003E00  ; b
		DCD 0x00001C80  ; C
		DCD 0x00002F00  ; d
		DCD 0x00003C80  ; E
		DCD 0x00003880  ; F
	ALIGN
ascii_SET	;table that corresponds integers 10-15 to their ascii codes
		DCW 0x3031	;10
		DCW	0x3131	;11
		DCW 0x3231	;12
		DCW 0x3331	;13
		DCW 0x3431	;14
		DCW 0x3531	;15
	ALIGN

lab4
	STMFD SP!,{r0-r5,lr}	  ;Store register lr on stack
	LDR r0, =prompt	  ;Load prompt address into r0
	BL output_string  ;output the main menu to user
	BL read_character ;read user selection
	CMP r1, #0x73		  ;Did they chose "Seven Segment Display"?
	BLEQ display_digit ;If so, branch and link to display_digit
	CMP r1, #0x70		  ;Did they chose "Pushbuttons"?
	BLEQ read_push_btns ;If so, branch and link to read_push_btns
	CMP r1, #0x72		  ;Did they "RGB LED"?
	BLEQ rgb ;If so, branch and link to RGB_LED
	CMP r1, #0x6C		  ;Did they chose "LEDs"?
	BLEQ led

	b lab4
donzo
	
	LDMFD SP!, {r0-r5,lr}	; Restore register lr from stack	
	BX lr

display_digit	;parameters: r0-value between 0-15 returns: none
	STMFD SP!,{r0-r3,lr}    ; Store registers on stack
	BL newpage				; print a new page
	BL CLR_7seg				; Clear the display
	LDR r0, =prompt1		; Load prompt for Seven Segment Display
	BL output_string		; Output prompt
	BL newline				; print a new line
	LDR r0, =stringaddress	; Load address of string holder into r0
	BL read_string			; read the number string the user entered
	BL newline				; print a new line
	BL string_to_int		; Convert string to int
	LDR r0, =IO0SET  		; Load memory address of IO0SET
	LDR r3, =digits_SET		; Load address of lookup table into r3
	MOV r1, r1, LSL #2	    ; Multiply value by 4 to get offset (each value stored in a word)
	LDR r2, [r3, r1]   	    ; Load pattern from table with r1 offset into r2
	LDR r3, [r0]			; Load value of IO0SET into r3
	ORR r3, r3, r2			; OR IO0SET with r2 to set pattern bits
	STR r3, [r0]			; Store the edited IO0SET in memory
	B lab4					; return to lab4
	LDMFD SP!, {r0-r3,lr}	; Restore registers from stack	
	BX LR

CLR_7seg	;parameters-none returns- none
	STMFD SP!,{r0,r1,lr}    ; Store registers on stack
	LDR r0, =IO0CLR			;Load IO1CLR into r0
	LDR r1, [r0]			;Load value of IO1CLR into r0
	ORR r1, r1, #0x3F80		; Set bits 7-13
	STR r1, [r0]			; Store r1 in IO1CLR address to turn off Seven Segment Display LEDs
	LDMFD SP!,{r0,r1,lr}
	BX LR

read_push_btns ;paramters: none. returns: r0- integer value of button presses
	STMFD sp!, {r1-r3,lr}
	BL newpage			; new page
	BL set_btns_low		;set button inputs low
	LDR r0, =prompt2    ;Loads prompt into r0 for output_string
	BL output_string    ;outputs prompt for read_push_btns to user
	BL newline
here	
	BL read_character 
    CMP r1, #0xD
	BNE here		 		; Check if user pressed enter
	LDR r0, =IO1PIN   		; Load IO1PIN to check button presses
	LDR r1, [r0]	  		; Load value of IO1PIN 
	AND r1, r1, #0xf00000	; Isolate bits 20-23 
	MOV r1, r1, LSR #20		; Shift bits to LSB of register (to get in number form)
	EOR r1, r1, #0xf		; Negate the nibble
	BL reverse_nibble	 	; Call reverse_nibbole
	MOV r3, r1				;Hold value of r1 in r3
	CMP r1, #10
	BLT single_digit
	SUB r1, r1, #10			; Subtract 10 from value to get offset address
	LSL r1, r1, #1			; r1:= r1*2 since the strings (two chars) are two bytes
	LDR r2, =ascii_SET		; Load ascii string table into r2
	LDRH r1, [r2, r1]		; Load ascii value from r2 with offset r1 into r1
	LDR r0, =result2		; Load address of result2 into r0
	BL output_string		; outputs result2
	LDR  r0, =stringaddress ; Load address of string holder
	STR  r1, [r0]			; Store string into string holder
	BL output_string		; output the string in stringaddress
	BL newline
	B dun
single_digit
	ADD r1, r1, #0x30		; If number is less than 10 add 30 (to get ascii value of number)
	LDR r0, =result2		; Load address of result2 into r0
	BL output_string		; outputs result2
	CMP r1, #0x40
	BLLT output_character   ; "						   " output that character single ascii character
	BL newline
dun	
	MOV r0, r3				;return with button value in r0
	LDMFD sp!, {r1-r3,lr}
	BX LR					; "						   " go back to main menu

set_btns_low ;parameters: none. returns: none.
	STMFD sp!, {r0-r1,lr}
	LDR r0, =IO1CLR		;Load IO1CLR into r0
	LDR r1, [r0]		;Load value of IO1CLR into r0
	ORR r1, r1, #0xf00000
	STR r1, [r0]		;set buttons to low (pin20-23)
	LDMFD sp!, {r0-r1,lr}
	BX LR

led
leds_off
	stmfd sp!, {r0-r2, r5, lr}
	BL newpage
	;r2 = address
	ldr r2, =IO1SET		  ;write to turn IO1SET
	ldr r1, [r2]
	orr r1, r1, #0xf0000 ; turn off leds pin 16-19
	str r1, [r2]
start	
	ldr r0, =zprompt1	;"enter a number"
	bl output_string
	bl newline
	ldr r0, =stringaddress
	bl read_string	   ;read in int (0-15)
	bl newline
	bl LEDs			   ; branch to main LED routine; r0 is pattern to turn on

led_end
	ldr r0, =zprompt2	;"look at the leds"
	bl output_string
	bl newline
	
	;b led
	
	ldmfd sp!, {r0-r2, r5, lr}
	
	bx lr

rgb
	stmfd sp!, {r0-r2, lr}
	BL newpage	
	ldr r2, =IO0SET		;write to IO0SET to turn off
	ldr r1, [r2]
	orr r1, r1, #0x260000 ; turns off all lights (pin 17, 18, and 21)
	str r1, [r2]
start1	;take in a char of what color they want
	ldr r0, =zprompt3	; "pick a color"
	bl output_string
	bl newline
	ldr r0, =stringaddress
	bl read_char	   ;reads char to see what color to turn on
	bl RGB_LED
	
	ldr r0, =zprompt2 ;"look at the leds"
	bl output_string
	bl newline
	
	ldmfd sp!, {r0-r2, lr}
	
	bx lr		
	
gpio_setup
	STMFD sp!, {r0-r1, lr}
	;setup for seven segment display
	LDR   r0, =IO0DIR	   ; Loads address of IO0DIR into r0
	LDR   r1, [r0]		   ; Loads value of IO0DIR into r1
	ORR   r1, r1, #0x3F80  ; Sets P0.pin7-P0.pin13 to output (bits 7-13 of IO0DIR to 1) 	     
	ORR   r1, r1, #0x260000
	STR   r1, [r0]		   ; Stores the edited IO0DIR back in memory
	;setup for LEDs and push buttons
	LDR r0, =IO1DIR	   	   ; Loads address of IO1DIR into r0
    LDR r1, [r0]  		   ; Loads value of IO1DIR into r1
    ORR r1, r1, #0xf0000   ; Sets P1.pin16-P1.pin19 to output (bits 16-19 of IO1DIR to 1)
    BIC r1, r1, #0xf00000  ; Sets P1.pin20-P1.pin23 to input (bits 20-23 of IO1DIR to 0)
    STR r1, [r0]  		   ; Stores the edited IO1DIR back in memory
	
	LDMFD sp!, {r0-r1, lr}
	BX lr

LEDs
	stmfd sp!, {r0-r2, lr}

	bl string_to_int
	;mov r0, r1			;r0 is now the number we need to convert to binary
	;lsl r0, #16
	bl reverse_nibble	;reverses bits in r1
	mov r0, r1
leds_on						 ;turns off with IO1CLR
	ldr r2, =IO1CLR
	ldr r1, [r2]
	orr r1, r1, r0, lsl #16		;turns on leds according to what r0 is
	;mov r5, r1	;check pins		;r0 need to shift 16 left so it is at pin 16
	str r1, [r2]

	ldmfd sp!, {r0-r2, lr}
	bx lr

RGB_LED
	stmfd sp!, {r0-r2, lr}

	bl newline
	mov r0, r1		;red72, gree67n, blue70, purple70, yellow79, white77
	cmp r0, #0x72 	;branches to proper color
	beq red
	cmp r0, #0x67
	beq green
	cmp r0, #0x62
	beq blue
	cmp r0, #0x70
	beq purple
	cmp r0, #0x79
	beq yellow
	cmp r0, #0x77
	beq white
	
	
red						 ;loads r0 with proper color
	mov r0, #0x20000
	b rgb_on	
green
	mov r0, #0x200000
	b rgb_on
blue
	mov r0, #0x40000
	b rgb_on
purple
	mov r0, #0x60000
	b rgb_on
yellow
	mov r0, #0x220000
	b rgb_on
white
	mov r0, #0x260000
	b rgb_on
	
rgb_on					;turns on with IO0CLR
	ldr r2, =IO0CLR
	ldr r1, [r2]
	orr r1, r1, r0  ;all on =0x260000, RED = 0x2000, BLUE = 0x40000, GREEN = 0x200000
	str r1, [r2]

	ldmfd sp!, {r0-r2, lr}
	bx lr

	END
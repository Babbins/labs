	AREA	GPIO, CODE, READWRITE	
	
	EXPORT read_character
	EXPORT output_character
	EXPORT read_string
	EXPORT output_string
	EXPORT newline
	EXPORT newpage
	EXPORT string_to_int 
	EXPORT pin_block
	EXPORT uart_init
	export read_char
	export reverse_nibble

;Zachary Esmaelzada, zbesmael
;Ali Mahmoud, alimahmo
		
U0LSR EQU 0xE000C014			; UART0 Line Status Register
U0THR EQU 0xE000C000			; UART0 Transmit Hold Register	
		ALIGN
read_string						   ; r0-String Destination 	
	STMFD SP!,{r0-r2,lr}
	MOV r2, #0					   ; Initialize offset
loop
	BL read_character		       ; Read the next char
	CMP r1, #0xD			       ; Check if the char is Carriage Return (Enter)	
	MOVEQ r1, #0				   ; set r1 to 0
	STRBEQ r1, [r0, r2]			   ; store null byte (null terminating)
	STRBNE r1, [r0, r2]            ; If not CR, store the char that r1 holds into the string address by offset r2
	ADD r2, r2, #1			       ; Increment offset
	BNE loop				 	   ; If not CR, Branch back to read the next char
	LDMFD sp!, {r0-r2,lr}
	BX lr

output_string					   ; r0-String Address
	STMFD SP!,{r0-r2,lr}		
	MOV r2, #0					   ; Initialize offset
loop2	 
	LDRB r1, [r0, r2]			   ; Load string address (r0) with offset r2 into r1
	ADD r2, r2, #1				   ; Increment Offset
	CMP r1, #0					   ; Is the char NULL?
	;MOVEQ r1, #0xA				   ; store new line ascii in r1
	BLNE output_character		   ; output the char in r1
	;CMP r1, #0
	BNE loop2					   ; If not NULL, move on to the next char
	LDMFD sp!, {r0-r2,lr}
	BX lr

read_character ;reads a char from THR and returns it in r1				
	STMFD SP!,{r0,lr}		
	LDR r0, =U0LSR
start
	LDRB r1, [r0]
	AND r1, r1, #1	    ; Check the RDR bit of U0LSR
	CMP r1, #0 			
	BEQ start
	LDR r0, =U0THR   	;Puts address of U0THR in r
	LDRB r1, [r0]		;Loads value of U0THR to r1
	BL output_character
	LDMFD sp!, {r0,lr}
	BX lr

read_char ;reads a char from THR and returns it in r1				
	STMFD SP!,{r0,lr}		
	LDR r0, =U0LSR
start2
	LDRB r1, [r0]
	AND r1, r1, #1	    ; Check the RDR bit of U0LSR
	CMP r1, #0 			
	BEQ start2
	LDR r0, =U0THR   	;Puts address of U0THR in r
	LDRB r1, [r0]		;Loads value of U0THR to r1
	LDMFD sp!, {r0,lr}
	BX lr			

output_character		 		;arguments: r1-holds character
	STMFD SP!,{r0-r2,lr}
	LDR  r0, =U0LSR		 		;set r0 to U0LSR
begin		
	LDRB r2, [r0]
	AND r2, r2, #32 	 		; Check the fifth bit of LSR (THRE)		
	CMP r2, #0
	BEQ begin			 		; If THRE = 0 , loop back
	LDR r0, =U0THR		 		;Set r0 to U0THR
	STRB r1, [r0]				 ;Write value in r1 to U0THR
	LDMFD sp!, {r0-r2,lr}
	BX lr

string_to_int 					;arguments: r0-String address returns: r1-integer value
	STMFD sp!, {r0,r2-r4,lr}
	MOV r3, #0					;r3 = offset
	MOV r4, #10					;r4 = 10 to multiply by
	MOV r1, #0					;r1 = running sum
	
start1
	LDRB r2, [r0, r3]			;loads r2 with the number
	CMP r2, #45			
	BEQ skip					;if char is '-', skip
	CMP r2, #0
	BEQ done1					;NULL terminate found
	SUB r2, r2, #48
	MUL r1, r4, r1				;multiplies number by 10
	ADD r1, r1, r2				;adds sum and number
skip
	ADD r3, r3, #1				;shifts offset
	B start1
		
done1
	LDMFD sp!, {r0,r2-r4,lr}
	BX lr 

newpage
	STMFD sp!, {r1,lr}
	MOV r1, #0xC
	BL output_character
	LDMFD sp!, {r1,lr}

newline
	STMFD sp!, {r1,lr}
	MOV r1, #0xA		
	BL output_character	; output new line
	MOV r1, #0xD
	BL output_character	; output carriage return
	LDMFD sp!, {r1,lr}
	BX lr

reverse_nibble 			;parameters: r1-holds nibble to be reversed returns: r1- reversed nibble
	STMFD SP!, {r0,r2,r3,lr}
	mov r0, #0			;initialize r0 to 0
	mov r2, #0
	mov r3, #0
	AND r0, r1, #0x8	;Isolate bit 3
	LSR r0, r0, #3		;Put it in bit 0s place	
	AND r2, r1, #0x4	;Isolate bit 2
	LSR r2, r2, #1		;Put it in bit 1s place
	AND r3, r1, #0x2	;Isolate bit 1
	LSL r3, r3, #1		;Put it in bit 2s place
	AND r1, r1, #1		;Isolate bit 0
	LSL r1, r1, #3		;Put it in bit 3s place
	ADD r1, r1, r0		;Add em up
	ADD r1, r1, r2
	ADD r1, r1, r3
	LDMFD SP!, {r0,r2,r3,lr}
	BX LR

uart_init
	STMFD SP!,{r0,r1,lr}	
	LDR r0, =0xe000c00c
	MOV r1, #131
	STR r1, [r0]
	LDR r0, =0xe000c000
	MOV r1, #120
	STR r1, [r0]
	LDR r0, =0xe000c004
	MOV r1, #0
	STR r1, [r0]
	LDR r0, =0xe000c00c
	MOV r1, #3
	STR r1, [r0]
	LDMFD sp!, {r0,r1,lr}
	BX lr 

pin_block
	STMFD sp!, {r0-r1, lr}
	LDR r0, =0xE002C000  ; PINSEL0
	LDR r1, [r0]
	MOV r1, #5
	STR r1, [r0]
	LDMFD sp!, {r0-r1, lr}
	BX lr
	
	END
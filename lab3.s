;Primality Test by Ali Mahmoud and Zachary Esmaelzada for CSE-380


	AREA	lib, CODE, READWRITE	
	EXPORT lab3
	EXPORT pin_connect_block_setup_for_uart0
	
U0LSR EQU 0xE000C014			; UART0 Line Status Register
U0THR EQU 0xE000C000			; UART0 Transmit Hold Register

stringaddress DCD 0x00000000
			  DCD 0x00000000

prompt = "Enter a number between -9999 and 9999: ",0;  
	ALIGN
result0 = "The number entered is prime",0;
	ALIGN
result1 = "The number entered is composite",0;
	ALIGN


	

lab3
	STMFD SP!,{lr}			; Store register lr on stack
	LDR r0, =prompt			; Load prompt address in r0
	BL output_string		; Output prompt
	LDR r0, =stringaddress	; Load stringaddress in r0
	BL read_string			; read_string into stringaddress
	BL newline				; output new line
	BL string_to_int		; convert ascii value in string address to a number (returned in r5)
	MOV r0, r5				; put result of string_to_int (r5) into (r0) to test primality
	BL prime_test			
	CMP r7, #1				; check if r7 is prime
	BEQ prime				; if prime, branch to prime				
	LDR r0, =result1		; if composite, load composite result to r0
	BL output_string		; output composite result
	BL newline				; output new line
	B lab3					; restart program				
prime
	LDR r0, =result0		; ;oad prime result in r0
	BL output_string		; output prime result
	BLE newline				; output new line
	B lab3					; restart program

 
	
read_string						   ; r0-String Destination 	
	STMFD SP!,{r0-r2,lr}
	MOV r2, #0					   ; Initialize offset
loop
	BL read_character		       ; Read the next char
	CMP r1, #0xD			       ; Check if the char is Carriage Return (Enter)						
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

output_character		 ;arguments: r1-holds character
	STMFD SP!,{r0-r2,lr}
	LDR  r0, =U0LSR		 ;set r0 to U0LSR
begin		
	LDRB r2, [r0]
	AND r2, r2, #32 	 ; Check the fifth bit of LSR (THRE)		
	CMP r2, #0
	BEQ begin			 ; If THRE = 0 , loop back
	LDR r0, =U0THR		 ;Set r0 to U0THR
	STRB r1, [r0]		 ;Write value in r1 to U0THR
	LDMFD sp!, {r0-r2,lr}
	BX lr

prime_test
	;r0 is number to check if prime
	;ORIGINAL NUMBER KEPT IN r5
	STMFD sp!, {r0,r1,r5,lr}
	;mov r0, #13		;TESTING
	mov r5, r0		;keep original dividend
	
	;cmp r0, #1			;1, 3, 5, and 7 are all prime.
	;beq stop_not_prime
	cmp r0, #2
	beq number_is_prime
	cmp r0, #3
	beq number_is_prime
	cmp r0, #5
	beq number_is_prime
	cmp r0, #7
	beq number_is_prime
	
	mov r1, #2
	bl div_and_mod	;check remainder when divided by 2
	cmp r1, #0
	beq stop_not_prime	;number not prime
	
	mov r0, r5	;reloads the dividend into r0 for div_and_mod
	mov r1, #3
	bl div_and_mod	;check remainder when divided by 3
	cmp r1, #0
	beq stop_not_prime	;number not prime
	
	mov r0, r5	;reloads r0
	mov r1, #5
	bl div_and_mod
	cmp r1, #0
	beq stop_not_prime
	
	mov r0, r5	;reloads r0
	mov r1, #7
	bl div_and_mod
	cmp r1, #0
	beq stop_not_prime

number_is_prime
	mov r7, #1
	b done
	;output string "Number r0 is prime!"
	
stop_not_prime
	mov r7, #2
	;output string "Number r0 is not prime!"
done 	
	LDMFD sp!, {r0,r1,r5,lr}
	BX LR

div_and_mod
	STMFD sp!, {r2-r12, lr}

	
	MOV r7, r0 ;makes copy of r0 to check later.
	CMP r0, #0
	BGT checkr1
	RSB r0, r0, #0 ;negates r0 if negative to do divison.
	B begin
	
checkr1
	CMP r1, #0
	BGT begin1
	RSB r1, r1, #0

begin1
	MOV r2, #15	;r2 = counter
	MOV r3, #0	;r3 = quotient
	MOV r5, r1  ;copies divisor into r5 to check later
	LSL r1, #15	;logical left shift divisor 15 places
	MOV r4, r0	;r4 = remainder ;remainder initialized to dividend
	ADD r2, r2, #1	; adjust counter so loop doesn't ruin
	
loop1
	SUB r2, r2, #1	;decrement counter
	SUB r4, r4, r1	;remainder = remainder - divisor
	CMP r4, #0
	BGE no			;if remainder (r4) > 0 goto no
	ADD r4, r4, r1	;remainder = remainder + divisor
	LSL r3, #1		;LSB = 0 for quotient (r3)
	B j1
	
no
	LSL r3, #1
	ADD r3, r3, #1	;LSB = 1 for quotient (r3)
	
j1
	LSR r1, #1		;MSB = 0 for divisor (r1)
	CMP r2, #0
	BGT loop1		;loop if counter (r2) > 0

	;now check for positive/negative
	EOR r6, r7, r5 ;Eors to check either number to see the sign of quotient.
	CMP r6, #0
	BLT change_sign ;if negative, change sign of quotient to negative.
	B stop

change_sign
	RSB r3, r3, #0 ;negates the quotient (r3)	
	
stop
	MOV r0, r3		;copy into proper registers.
	MOV r1, r4

	LDMFD r13!, {r2-r12, lr}
	BX lr	;return to c program

string_to_int ;arguments: r0-address of string
	STMFD sp!, {r0,r2-r4,lr}
	;r3 = offset for stringaddress
	mov r3, #0
	mov r4, #10
	mov r5, #0
	
	;r2 = number
	;r5 = sum
	
start1
	ldrb r2, [r0, r3]	;loads r2 with the number
	cmp r2, #45
	beq skip
	cmp r2, #0
	beq done1					;NULL terminate found
	sub r2, r2, #48
	mul r5, r4, r5				;multiplies number by 10
	add r5, r5, r2				;adds sum and number
skip
	add r3, r3, #1				;shifts offset
	b start1
		
done1
	LDMFD sp!, {r0,r2-r4,lr}
	BX lr 
	;r5 is the final number

newline
	STMFD sp!, {r1,lr}
	MOV r1, #0xA		
	BL output_character	; output new line
	MOV r1, #0xD
	BL output_character	; output carriage return
	LDMFD sp!, {r1,lr}
	BX lr
uart_init
	STMFD SP!,{lr}		


	LDMFD sp!, {lr}
	BX lr 
 
pin_connect_block_setup_for_uart0
	STMFD sp!, {r0, r1, lr}
	LDR r0, =0xE002C000  ; PINSEL0
	LDR r1, [r0]
	ORR r1, r1, #5
	BIC r1, r1, #0xA
	STR r1, [r0]
	LDMFD sp!, {r0, r1, lr}
	BX lr

	END

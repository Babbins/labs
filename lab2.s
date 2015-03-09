;div_and_mod: Division and Modulus subroutine by Ali Mahmoud for CSE380
;r0-dividend, r1-divisor, r2-quotient, r3-remainder, r4-sign helper, r5-counter.   	
;Inputs: r0-Dividend r1-Divisor
;Outputs: r0-Quotient r1-Remainder

	AREA	LAB2, CODE, READWRITE	
	EXPORT	div_and_mod


div_and_mod		
			STMFD r13!, {r2-r12, r14}
main
			MOV   r4, #1	  	  ;Sign helper will be manipulated and checked to output a correctly signed quotient
			
			CMP   r0, #0		
			RSBLT r0, r0, #0  ;If dividend is negative, make it positive for calculation 
			RSBLT r4, r4, #0  ;If dividend is negative, negate the sign helper	
			
			CMP   r1, #0		  
			RSBLT r1, r1, #0  ;If divisor is negative, make it positive for calculation
			MVNLT r4, r4	  ;If dividend is negative, negate the sign helper
			
			MOV r5, #15	  	  ;Initialize counter to 15
			MOV r2, #0 	  	  ;Initialize quotieint to 0
			LSL r1, #15	  	  ;Logical Shift Left divisor 15 places
			MOV r3, r0	  	  ;Initialize remainder to dividend

Loop		        
			SUB r3, r3, r1    ;remainder := remainder - divisor
			CMP r3, #0 		  
			LSLGE r2, #1	  ;If remainder > = 0, Logical Shift Left quotient 1 place
			ORRGE r2, #1  	  ;If remainder > = 0, Makes LSB of quotient be 1 if it is not already
			ADDLT r3, r3, r1  ;If remainder < 0, remainder = remainder + divisor
			LSLLT r2, #1	  ;If remainder < 0, Logical Shift Left quotient 1 place
			LSR r1, #1	  	  ;Logical Shift Right divisor 1 place
			CMP r5, #0		  
			SUBGT r5, r5, #1  ;If counter > 0, counter := counter - 1
			BGT Loop 	  	  ;If counter > 0, branch back to loop
			
			CMP r4, #0		  
			RSBLT r2, r2, #0  ;If sign helper < 0, negate the quotient
			MOV r0, r2	  	  ;Put quotient in r0 
			MOV r1, r3	  	  ;Put remainder in r1
				

			LDMFD r13!, {r2-r12, r14}
			BX lr             ;Return to the C program	


			END
	

			
			

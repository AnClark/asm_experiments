; Task 3: Write a simple scholar grade querier.
; TODO: THIS PROGRAM MAY BEHAVIOR UNEXPECTEDLY ON OTHER MACHINES DUE TO UNSUITABLE ENDING FLAG JUDGMENT OF BUF!

STACK SEGMENT USE16 STACK
	DB 512 DUP(0)
STACK ENDS


DATA SEGMENT USE16
	; ======== Student Data ========
	N EQU 30
	BUF DB 'Satoshi',0,0,0		
		DB 100, 85, 80, ?
		DB 'Kasumi',0,0,0,0
		DB 80, 100, 70, ?
		
		DB N-3 DUP('TEMP_VALUE', 60, 60, 60, ?)
		
		DB 'AkuraRyuu',0
		DB 95, 95, 100, ?

	
	; ======== Screen Info ========
	STR_TITLE DB '-------- GRADE QUERIER --------', 0DH, 0AH, '$'
	STR_INPUT_NAME DB 'Please input student name: $'
	STR_NOT_FOUND DB 0DH, 0AH, 'Student not found! $'
	STR_FOUND DB 0DH, 0AH, 'Student FOUND! $'
	STR_QUIT DB 0DH, 0AH, 0DH, 0AH, 'Quitting program... $'
	STR_GRADES DB 'A$','B$','C$','D$','E$','F$'
	CRLF DB 0DH, 0AH, '$'
	
	; ======== Vars for query ========
	IN_NAME	DB 11
			DB ?
			DB 11 DUP(0)
	STUDENT_FOUND DB 0		; Mark if we found the student we want. Value: Found=1, Not found=0
	POIN DW ?
	BUF_END DW ?				; Ending address of BUF
	
DATA ENDS


CODE SEGMENT USE16
	ASSUME CS:CODE, DS:DATA, SS:STACK
START:
	; INITIALIZE
	MOV AX, DATA
	MOV DS, AX
	
	LEA DX, STR_TITLE
	MOV AH, 9
	INT 21H

PROMPT:
	CALL PRINT_CRLF

	; Prompt for user input
	LEA DX, STR_INPUT_NAME
	MOV AH, 9
	INT 21H
	
	; Receive user input
	LEA DX, IN_NAME
	MOV AH, 10
	INT 21H
	
	; Append dollar mark to the end of string
	; NOTICE: If you input nothing, the string will only contain '$'.
	MOV BL, IN_NAME+1					; Get actual length of input
	MOV BH, 0							; Clear BH
	MOV BYTE PTR IN_NAME+2[BX], '$'		; Locate to the end of string, then append
	
	
	; ============================== FUNCTION 1: Check user input ==============================
	
	; First, get value of your input
	LEA SI, IN_NAME+2
	MOV BL, [SI]
	
	; SITUATION 1: Just input an CRLF, aka. input nothing
	; At this time, the buffer only contains a '$'.
	CMP BL, '$'
	JE PROMPT
	
	; SITUATION 2: Just input 'q' for quit.
	; TODO: In future, using 'JE' may raise an exception!
	CMP BL, 'q'
	JE QUIT

	
	; ==================== FUNCTION 3: Calculate all students' average ====================
	; --- DEBUG: This is a mark for locating code in TD.
	XOR DX, DX
	XOR DX, DX
	XOR DX, DX	
	
	CALL CALCULATE_AVERAGE
	
	
	; ============================== FUNCTION 2: Find student ==============================
	; METHOD: Check character one by one, and analyze how many chars are same.
	
	; Get ready
	MOV BUF_END, OFFSET BUF
	ADD BUF_END, 14*30
	
	MOV POIN, OFFSET BUF

; --------------------------------------------------------------------------	
LOOP_FIND_STUDENT:

	MOV SI, POIN
	LEA DI, IN_NAME+2
	
	; Use DL to store the number of same chars, DH stores the length of STR1.
	XOR DX, DX		; Clear DX first
	
	XOR BX, BX		; BX plays role of buffer

LOOP_CHECK_SAME_STUDENT_NAME:	
	; Count how many characters are same.
	MOV BL, [SI]
	MOV BH, [DI]
	INC DH			; Calculate length of STR1
	
	CMP BH, BL
	JE SAME_CHAR
	JMP NOT_SAME_CHAR
	
SAME_CHAR:
	INC DL
	
NOT_SAME_CHAR:
	; Point to the next char
	INC SI
	INC DI
	
	; LOOPBACK JUDGEMENT
	CMP BYTE PTR [SI], 0		; Check if we arrived the end flag
	JNE LOOP_CHECK_SAME_STUDENT_NAME
	
	; Check if found by checking if DH=DL.
	; If found: Give a tip, then TODO: continue.
	CMP DH, DL
	JE FOUND
	JMP TRY_NEXT_STUDENT
	
TRY_NEXT_STUDENT:
	; If not found this time: Try next student
	ADD POIN, 14				; Cursor to the next student
	
	; LOOPBACK JUDGEMENT
	CMP POIN, 14*30				; Check if we arrived the end of BUF
	;LEA DI, BUF_END
	;CMP BYTE PTR POIN, BYTE PTR [DI]
	
	JL LOOP_FIND_STUDENT
; --------------------------------------------------------------------------	
	
	; FINAL CHECK: The worth situation is that we traversed all those students, but still not found.
	CMP POIN, 14*30
	;LEA DI, BUF_END
	;CMP BYTE PTR POIN, BYTE PTR [DI]
	
	JGE NOT_FOUND
	JMP FOUND

NOT_FOUND:
	LEA DX, STR_NOT_FOUND
	MOV AH, 9
	INT 21H
	JMP PROMPT			; Return to prompt
	
FOUND:
	LEA DX, STR_FOUND
	MOV AH, 9
	INT 21H
	JMP PROMPT			; Return to prompt
	

	
	
QUIT:	
	; Print quit tip
	LEA DX, STR_QUIT
	MOV AH, 9
	INT 21H
	
	; Exit program
	MOV AH, 4CH
	INT 21H
	
	
CALCULATE_AVERAGE PROC NEAR
	; Calculate all students' average
	; FORMULA:
	;		- Source: (A*2+B+C/2)/3.5
	;		- Exported: (4*A + 2*B + C) / 7
	; REGISTERS:
	; 		- AX: Occupied by MUL & IMUL
	;		- BX: Contains number to multiply/divide with
	;		- CX: Current result of calculation of current student
	;		
	; STORAGE:
	;		- POIN
	
	; Get ready
	; Get the heading address FOR MARKS of BUF
	LEA SI, BUF
	ADD SI, 10
	
LOOP_FIND_STUDENT_MARKS:
	; Clear registers
	XOR AX, AX
	XOR BX, BX
	XOR CX, CX
	XOR DX, DX
	
	; NOTICE!
	; How much indirect addr picker picks are depended on the first argument!
	; 	Here, each mark takes only 1 Byte. If we use AX instead of AL when getting values of A, B, C,
	; 		2 Bytes of data will be read. The only consequence is that we get a totally wrong result.
	
	; Read, calculate mark A, then accumulate
	MOV AL, [SI]	; Get A
	MOV BX, 4		; Set multiplyer 4
	MUL BX			; 4*A
	ADD CX, AX		; Accumulate
	
	; Read and calculate mark B, then accumulate
	XOR AH, AH		; Clear AH to prevent pollution
	MOV AL, [SI]+1	; Get B
	MOV BX, 2		; Set multiplyer 2
	MUL BX			; 2*B
	ADD CX, AX		; Accumulate
	
	; Read and calculate mark C, then accumulate
	XOR AH, AH		; Clear AH to prevent pollution
	MOV AL, [SI]+2	; Get C
	ADD CX, AX		; Accumulate
	
	; Now let's give it a final division!
	MOV AX, CX		; AX stores the number for divide
	MOV BX, 7		; Set divider 7
	DIV BX			; Divide 7
	MOV CX, AX		; Get result back
	
	; Everything is done. Put result to where it should be.
	MOV [SI]+3, CL
	
	; Cursor to the next student
	ADD SI, 14
	
	; LOOPBACK JUDGEMENT
	CMP SI, 14*30
	JL LOOP_FIND_STUDENT_MARKS

	RET
CALCULATE_AVERAGE ENDP
	
	
PRINT_CRLF PROC NEAR
	; Screen output: Go to a new line
	LEA DX, CRLF
	MOV AH, 9
	INT 21H
	RET
PRINT_CRLF ENDP
	
DEBUG PROC NEAR
	LEA DX, STR_TITLE
	MOV AH, 9
	INT 21H
	RET
DEBUG ENDP
	
CODE ENDS
	END START
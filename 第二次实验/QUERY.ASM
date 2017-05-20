; Task 3: Write a simple scholar grade querier.

; --------------- MACRO DEFINITIONS ---------------
; Screen output: print screen info
PRINT MACRO A
	LEA DX, A
	MOV AH, 9
	INT 21H
ENDM

; Screen output: Go to a new line
PRINT_CRLF MACRO
	LEA DX, CRLF
	MOV AH, 9
	INT 21H
ENDM



STACK SEGMENT USE16 STACK
	DB 512 DUP(0)
STACK ENDS


DATA SEGMENT USE16
	; ================ Student Data ================
	N EQU 30
	BUF DB 'Satoshi',0,0,0		
		DB 100, 85, 80, ?			; AVE = 92 (A)
		DB 'Kasumi',0,0,0,0
		DB 80, 100, 70, ?			; AVE = 84 (B)
		DB 'AsukaRyo',0,0
		DB 77, 83, 60, ?			; AVE = 76 (C)
		DB 'Kagome',0,0,0,0
		DB 62, 87, 70, ?			; AVE = 70 (C)
		DB 'EdSheeran',0
		DB 60, 80, 70, ?			; AVE = 67 (D)
		DB 'NoisyGuy',0,0
		DB 55, 62, 33, ?			; AVE = 53 (F)
		
		DB N-7 DUP('TEMP_VALUE', 60, 60, 60, ?)		; AVE = 60 (D)
		
		DB 'AkuraRyuu',0
		DB 95, 95, 100, ?			; AVE = 95 (A)
	
	; BUF's ending flag, defined in order to mark the end of BUF CORRECTLY. 
	; NOTICE: This is essential for compatibility among different machines!
	BUF_END DB 0			
	
	; ================ Screen Info ================
	STR_TITLE DB '---------------- GRADE QUERY ---------------- $'
	STR_INPUT_NAME DB 'Please input student name: $'
	STR_NOT_FOUND DB 0DH, 0AH, 'Student not found! $'
	STR_FOUND DB 0DH, 0AH, 'Student FOUND! $'
	STR_QUIT DB 0DH, 0AH, 0DH, 0AH, 'Quitting program...', 0DH, 0AH, '$'
	STR_PRINT_GRADE DB 0DH, 0AH, 'Grade is:   $'
	CRLF DB 0DH, 0AH, '$'
	
	; ================ Vars for query ================
	IN_NAME	DB 11
			DB ?
			DB 11 DUP(0)
	STUDENT_FOUND DB 0		; Mark if we found the student we want. Value: Found=1, Not found=0
	POIN DW ?
	
DATA ENDS

CODE SEGMENT USE16
	ASSUME CS:CODE, DS:DATA, SS:STACK
START:
	; ================ INITIALIZE ================
	; Initialize data segment
	MOV AX, DATA
	MOV DS, AX
	;=============================================
	
	; Show program title
	PRINT STR_TITLE

PROMPT:
	PRINT_CRLF
	PRINT_CRLF

	; Prompt for user input
	PRINT STR_INPUT_NAME
	
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
	
	; First: get value of your input
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

	; SITUATION 3: Default --- input a valid student name
	; Just continue!
	
	; ==================== FUNCTION 3: Calculate all students' average ====================	
	CALL CALCULATE_AVERAGE
	
	
	; ============================== FUNCTION 2: Find student ==============================
	; METHOD: Check character one by one, and analyze how many chars are same.
	
	; Get heading addr of BUF.
	; In this segment, POIN points to current position. It will stop on target (if found) or ending (if not found).
	MOV POIN, OFFSET BUF

; --------------------------------------------------------------------------	
LOOP_FIND_STUDENT:
	; Set cursor to strings we compare
	MOV SI, POIN			; Student name in BUF
	LEA DI, IN_NAME+2		; Our input
	
	; Use DL to store the number of same chars, DH stores the length of STR1.
	XOR DX, DX		; Clear DX first
	XOR BX, BX		; BX plays role of buffer

LOOP_CHECK_SAME_STUDENT_NAME:	; Count how many characters are same.
	; Get current characters
	MOV BL, [SI]	; Char in student name in BUF
	MOV BH, [DI]	; Char in our input
	INC DH			; Calculate length of STR1
	
	; Compare if same
	CMP BH, BL		
	JE SAME_CHAR
	JMP NOT_SAME_CHAR
	
SAME_CHAR:
	INC DL
	
NOT_SAME_CHAR:
	; Point to the next char
	INC SI
	INC DI
	
	; --- LOOPBACK JUDGEMENT
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
	
	; --- LOOPBACK JUDGEMENT
	LEA DI, BUF_END
	CMP POIN, DI				; Check if we arrived the end of BUF
	
	JL LOOP_FIND_STUDENT
; --------------------------------------------------------------------------	
	
	; FINAL CHECK: The worth situation is that we traversed all those students, but still not found.
	LEA DI, BUF_END
	CMP POIN, DI
	
	JGE NOT_FOUND
	JMP FOUND

NOT_FOUND:
	PRINT STR_NOT_FOUND
	JMP PROMPT			; Return to prompt
	
FOUND:
	PRINT STR_FOUND
	
	; When found, go to the next stage - getting grade!
	JMP GET_GRADE
	

	; ============================== FUNCTION 4: Get grade ==============================
GET_GRADE:
		; --- DEBUG: This is a mark for locating code in TD.
	XOR DX, DX
	XOR DX, DX
	XOR DX, DX	
	
	; Locate to the chosen student's average
	LEA SI, BUF			; Get BUF's base address
	ADD SI, POIN		; Forward to the target student
	ADD SI, 13			; Forward to the student's average
	
	; Print screen tip
	PRINT STR_PRINT_GRADE
	
	; Now analyse and give a result
	CMP BYTE PTR [SI], 90
	JGE LE_90
	
	CMP BYTE PTR [SI], 80
	JGE LE_80
	
	CMP BYTE PTR [SI], 70
	JGE LE_70
	
	CMP BYTE PTR [SI], 60
	JGE LE_60
	JNGE NLE_60
	
LE_90:
	MOV DX, 'A'
	MOV AH, 2
	INT 21H
	JMP END_GET_GRADE
LE_80:
	MOV DX, 'B'
	MOV AH, 2
	INT 21H
	JMP END_GET_GRADE
LE_70:
	MOV DX, 'C'
	MOV AH, 2
	INT 21H
	JMP END_GET_GRADE
LE_60:
	MOV DX, 'D'
	MOV AH, 2
	INT 21H
	JMP END_GET_GRADE
NLE_60:
	MOV DX, 'F'
	MOV AH, 2
	INT 21H
	JMP END_GET_GRADE
	
END_GET_GRADE:
	JMP PROMPT
	
QUIT:	
	; Print quit tip
	PRINT STR_QUIT
	
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
	
	; NOTICE: I don't keep registers here, or my program will behave unexpectedly.
	
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
	
	; --- LOOPBACK JUDGEMENT
	LEA DI, BUF_END
	CMP SI, DI
	JL LOOP_FIND_STUDENT_MARKS

	RET
CALCULATE_AVERAGE ENDP
	
	
CODE ENDS
	END START

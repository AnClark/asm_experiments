.386
STACK SEGMENT STACK USE16
	DB 200 DUP(0)
STACK ENDS

DATA SEGMENT USE16
	BUF1	DB	0,1,2,3,4,5,6,7,8,9
	BUF2	DB	10	DUP(0)
	BUF3	DB	10	DUP(0)
	BUF4	DB	10	DUP(0)	
	INFO1	DB	'Press any key to begin!', 0DH, 0AH, '$'
	INFO2	DB 	'Finished!', 0DH, 0AH, '$'
DATA ENDS


CODE SEGMENT USE16
	ASSUME	CS:CODE, DS: DATA, SS: STACK
START:
	MOV AX, DATA
	MOV DS, AX
	MOV SI, OFFSET BUF1
	MOV DI, OFFSET BUF2
	MOV BX, OFFSET BUF3
	MOV BP, OFFSET BUF4
	MOV CX, 10
	
	;Show info message
	LEA DX, INFO1
	MOV AH, 9
	INT 21H
	
	; Wait for key input
	MOV AH, 1
	INT 21H
	
LOPA:
	MOV AL, [SI]
	MOV [DI], AL
	INC AL
	MOV [BX], AL
	ADD AL, 3
	MOV DS:[BP], AL
	INC SI
	INC DI
	INC BP
	INC BX
	DEC CX
	JNZ LOPA
	
	; Show a finish informer
	LEA DX, INFO2
	MOV AH, 9
	INT 21H
	
	MOV AH, 4CH
	INT 21H
	
CODE ENDS
	END START
	
.global _start // Entry point

// Initialize memory
array: .word -4, -3, -1, 0, 2, 3, 4, 6
x: .word -3
size: .word 8
idx: .space 4

binarySearch_init:
	PUSH {R4-R5, LR} // STACK: {null, null, LR binarySearch, null, null, LR _start}
binarySearch:
	// If lowIdx >= highIdx, then loop is finished
	CMP R2, R3
	BGE binarySearch_end
	
	// Else
	// Calculate mid
	ADD R4, R2, R3
	LSR R4, R4, #1
	
	// If x == array[mid], then loop is finished
	LDR R5, [R0, R4, LSL#2]
	CMP R1, R5
	BEQ binarySearch_early_end
	
	// Else
	ADDGT R2, R4, #1 // new low: lowIdx = mid + 1
	SUBLT R3, R4, #1 // new high: highIdx = mid - 1
	
	B binarySearch
binarySearch_end:
	// If x == array[lowIdx] result is found
	LDR R4, [R0, R2, LSL#2]
	CMP R1, R4
	MOVEQ R0, R2
	MOVNE R0, #-1
	POP {R4-R5, LR} // STACK: {null, null, LR _start}
	BX LR
binarySearch_early_end:
	MOV R0, R4
	POP {R4-R5, LR} // STACK: {null, null, LR _start}
	BX LR

_start:
	// Load arguments into registers
	LDR R0, =array // Array
	LDR R1, x // Value we are looking for
	MOV R2, #0 // lowIdx
	LDR R3, size
	SUB R3, R3, #1 // highIdx
	
	BL binarySearch_init
	
	STR R0, idx // Id of value we are looking for (-1 if not found)

infinite_end:
	B infinite_end

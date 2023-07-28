.global _start // Entry point

// Initialize memory
matrixA: .short -1, 2, 3, -4
matrixB: .short 6, -3, 2, 4
matrixC: .short 0, 0, 0, 0
size: .word 2

loop_row_init:
	PUSH {R4-R10, LR} // STACK: {row index, null, null, null, null, null, null, LR mm, null, null, null, null, null, null, null, LR _start}
	LDR R5, [SP] // Load row index
	PUSH {R5}
loop_row:
	MOV R4, #0 // Index column and reset
	
	BL loop_col_init
	
	// Augment row index
	POP {R5} // Load row index
	ADD R5, R5, #1
	PUSH {R5}
	
	// If row index >= size, then loop is finished
	CMP R5, R3
	BLT loop_row
	POP {R5}
	POP {R4-R10, LR} // STACK: {null, null, null, null, null, null, null, LR _start}
	BX LR

loop_col_init:
	PUSH {R4-R10, LR} // STACK: {column index, null, null, null, null, null, null, LR loop_row, row index, null, null, null, null, null, null, LR mm, null, null, null, null, null, null, null, LR _start}
	LDR R5, [SP] // Column index
	PUSH {R5}
loop_col:
	// Load variables
	POP {R5} // Column index
	LDR R4, [SP, #32] // Row index
	
	MLA R6, R4, R3, R5 // row * size + col
	LSL R6, R6, #1 // C offset
	MOV R7, #0 // C element
	
	MOV R8, #0 // Index element and reset
	
	BL loop_ele_init
	
	// Augment column index
	ADD R5, R5, #1
	PUSH {R5}
	
	// If column index >= size, then loop is finished
	CMP R5, R3
	BLT loop_col
	POP {R5}
	POP {R4-R10, LR} // STACK: {row index, null, null, null, null, null, null, LR mm, null, null, null, null, null, null, null, LR _start}
	BX LR

loop_ele_init:
	PUSH {R4-R10, LR} // STACK: {row index, column index, C offset, C element, element index, null, null, LR loop_col, column index, null, null, null, null, null, null, LR loop_row, row index, null, null, null, null, null, null, LR mm, null, null, null, null, null, null, null, LR _start}
	LDR R6, [SP, #16] // Element index
	LDR R8, [SP, #12] // C element
	PUSH {R6, R8}
loop_ele:
	// Load variables
	POP {R6, R8} // Element index, C element
	LDR R4, [SP] // Row index
	LDR R5, [SP, #4] // Column index
	LDR R7, [SP, #8] // C offset
	
	// Load elements from matrices
	MLA R9, R4, R3, R6 // row * size + iter
	LSL R9, R9, #1 // A offset
	LDRSH R9, [R0, R9] // Element from A
	MLA R10, R6, R3, R5 // iter * size + col
	LSL R10, R10, #1 // B	 offset
	LDRSH R10, [R1, R10] // Element from B
	
	// Compute C element
	MLA R8, R9, R10, R8 // matrixA[i] * matrixB[j] + matrixC[k]
	
	// Augment element index
	ADD R6, R6, #1
	
	PUSH {R6, R8}
	
	// If element index >= size, then loop is finished
	CMP R6, R3
	BLT loop_ele
	STRH R8, [R2, R7] // Store C element
	POP {R6, R8}
	POP {R4-R10, LR} // STACK: {column index, null, null, null, null, null, null, LR loop_row, row index, null, null, null, null, null, null, LR mm, null, null, null, null, null, null, null, LR _start}
	BX LR

mm:
	PUSH {R4-R10, LR} // STACK: {null, null, null, null, null, null, null, LR _start}
	
	MOV R4, #0 // Index row and reset
	
	BL loop_row_init
	
	POP {R4-R10, LR} // STACK: {}
	BX LR

_start:
	// Move matrices into registers
	LDRSH R0, =matrixA
	LDRSH R1, =matrixB
	LDRSH R2, =matrixC
	LDR R3, size
	
	BL mm

infinite_end:
	B infinite_end

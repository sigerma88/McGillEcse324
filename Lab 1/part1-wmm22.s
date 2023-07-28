.global _start // Entry point

// Initialize memory
matrixA: .short -1, 2, 3, -4
matrixB: .short 6, -3, 2, 4
matrixC: .short 0, 0, 0, 0

wmm22:
	PUSH {R4-R11, LR} // STACK: {null, null, null, null, null, null, null, LR _start}
	
	// Load variables necessary for u, v, w
	LDRSH R4, [R0] // A[0] = aa
	LDRSH R5, [R0, #4] // A[2] = cc
	LDRSH R6, [R0, #6] // A[3] = dd
	LDRSH R7, [R1] // B[0] = AA
	LDRSH R8, [R1, #2] // B[1] = CC
	LDRSH R9, [R1, #6] // B[3] = DD
	
	// Calculate w
	// R4=aa, R5=cc, R6=dd, R7=AA, R8=CC, R9=DD
	// aa*AA + (cc + dd - aa)*(AA + DD - CC) into R11
	ADD R10, R5, R6
	SUB R10, R10, R4
	ADD R11, R7, R9
	SUB R11, R11, R8
	MUL R10, R10, R11
	MLA R11, R4, R7, R10
	
	// Calculate u
	// R4=aa, R5=cc, R6=dd, R7=AA, R8=CC, R9=DD, R11=w
	// (cc - aa)*(CC - DD) into R9
	SUB R4, R5, R4
	SUB R9, R8, R9
	MUL R9, R4, R9
	
	// Calculate v
	// R5=cc, R6=dd, R7=AA, R8=CC, R9=u, R11=w
	// (cc + dd)*(CC - AA) into R10
	ADD R4, R5, R6
	SUB R10, R8, R7
	MUL R10, R4, R10
	
	// Calculate C[3]
	// R5=cc, R6=dd, R7=AA, R8=CC, R9=u, R10=v, R11=w
	// w + u + v
	ADD R4, R9, R10
	ADD R4, R4, R11 // w + u + v
	STRH R4, [R2, #6]
	
	// Calculate C[2]
	// R5=cc, R6=dd, R7=AA, R8=CC, R9=u, R10=v, R11=w
	// w + u + dd*(BB + CC - AA - DD)
	LDRSH R4, [R1, #4] // B[2] = BB
	ADD R4, R4, R8
	SUB R4, R4, R7
	LDRSH R8, [R1, #6] // B[3] = DD
	SUB R4, R4, R8
	MLA R4, R4, R6, R9
	ADD R4, R4, R11
	STRH R4, [R2, #4]
	
	// Calculate C[1]
	// R5=cc, R6=dd, R7=AA, R8=DD, R9=u, R10=v, R11=w
	// w + v + (aa + bb - cc - dd)*DD
	LDRSH R4, [R0] // A[0] = aa
	LDRSH R9, [R0, #2] // A[1] = bb
	SUB R5, R9, R5
	SUB R5, R5, R6
	ADD R5, R4, R5
	MLA R5, R5, R8, R10
	ADD R5, R11, R5
	STRH R5, [R2, #2]
	
	// Calculate C[0]
	// R4=aa, R6=dd, R7=AA, R8=DD, R9=bb, R10=v, R11=w
	// aa*AA + bb*BB
	LDRSH R5, [R1, #4] // B[2] = BB
	MUL R4, R4, R7
	MLA R4, R9, R5, R4
	STRH R4, [R2]
	
	POP {R4-R11, LR} // STACK: {}
	BX LR

_start:
	// Move matrices into registers
	LDRSH R0, =matrixA
	LDRSH R1, =matrixB
	LDRSH R2, =matrixC
	
	BL wmm22

infinite_end:
	B infinite_end

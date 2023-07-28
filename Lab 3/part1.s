.global _start
.equ PIXEL_BUFFER, 0xc8000000
.equ CHAR_BUFFER, 0xc9000000
.equ MAX_PIXEL_X, 319
.equ MAX_PIXEL_Y, 239
.equ MAX_CHAR_X, 79
.equ MAX_CHAR_Y, 59

_start:
	bl draw_test_screen
end:
	b end

// Draws a point on the screen at the specified (x, y) coordinates
// in the indicated color c. The subroutine should check that the
// coordinates supplied are valid, i.e., x in [0, 319] and y in [0, 239].
// Input: R0 (x coordinate), R1 (y coordinate), R2 (c color)
VGA_draw_point_ASM:
	PUSH {R4-R6, LR}
	
	// Verify coordinate inputs within range
	LDR R4, =MAX_PIXEL_X
	LDR R5, =MAX_PIXEL_Y
	CMP R0, R4
	POPGT {R4-R6, LR}
	BXGT LR
	CMP R1, R5
	POPGT {R4-R6, LR}
	BXGT LR
	
	// Shift the coordinates and get memory location
	LSL R4, R0, #1
	LSL R5, R1, #10
	LDR R6, =PIXEL_BUFFER
	ADD R6, R6, R4
	ADD R6, R6, R5
	
	// Store the color pixel
	STRH R2, [R6]
	
	POP {R4-R6, LR}
	BX LR

// Clears all the valid memory locations in the pixel buffer.
// Calls VGA_draw_point_ASM with a color value for every valid
// location on the screen.
VGA_clear_pixelbuff_ASM:
	PUSH {R4-R5, LR}
	
	// Initialize coordinates and color
	MOV R0, #0
	MOV R1, #0
	MOV R2, #0
	
	// Load MAX_PIXEL_X and MAX_PIXEL_Y into R4 and R5 respectively
	LDR R4, =MAX_PIXEL_X
	LDR R5, =MAX_PIXEL_Y
	
	BL loop_VGA_clear_pixelbuff_ASM_init
	POP {R4-R5, LR}
	BX LR
loop_VGA_clear_pixelbuff_ASM_init:
	PUSH {R6, LR}
	MOV R6, R0
loop_VGA_clear_pixelbuff_ASM:
	// Call VGA_draw_point_ASM with the color value
	BL VGA_draw_point_ASM
	
	// Increment X and check if it's greater than MAX_PIXEL_X
	ADD R0, R0, #1
	CMP R0, R4
	BLE loop_VGA_clear_pixelbuff_ASM
	MOVGT R0, R6 // Reset X coordinate
	
	// Increment Y and check if it's greater than MAX_PIXEL_Y
	ADD R1, R1, #1
	CMP R1, R5
	BLE loop_VGA_clear_pixelbuff_ASM
	
	POP {R6, LR}
	BX LR

// Writes the ASCII code c to the screen at (x, y). The subroutine should
// check that the coordinates supplied are valid, i.e., x in [0, 79] and
// y in [0, 59].
// Input: R0 (x coordinate), R1 (y coordinate), R2 (c character)
VGA_write_char_ASM:
	PUSH {R4-R5, LR}
	
	// Verify coordinate inputs within range
	LDR R4, =MAX_CHAR_X
	LDR R5, =MAX_CHAR_Y
	CMP R0, R4
	POPGT {R4-R5, LR}
	BXGT LR
	CMP R1, R5
	POPGT {R4-R5, LR}
	BXGT LR
	
	// Shift the coordinates and get memory location
	LSL R4, R1, #7
	LDR R5, =CHAR_BUFFER
	ADD R5, R5, R0
	ADD R5, R5, R4
	
	// Store the character
	STRB R2, [R5]
	
	POP {R4-R5, LR}
	BX LR

// Clears (sets to 0) all the valid memory locations in the character buffer.
// It takes no arguments and returns nothing.
// Calls VGA_write_char_ASM with a character value of zero for every valid
// location on the screen.
VGA_clear_charbuff_ASM:
	PUSH {R4-R5, LR}
	
	// Initialize R0, R1, R2 to 0
	MOV R0, #0
	MOV R1, #0
	MOV R2, #0
	
	// Load MAX_CHAR_X and MAX_CHAR_Y into R4 and R5 respectively
	LDR R4, =MAX_CHAR_X
	LDR R5, =MAX_CHAR_Y
loop_VGA_clear_charbuff_ASM:
	// Call VGA_write_char_ASM with a character value of 0
	BL VGA_write_char_ASM
	
	// Increment X and check if it's greater than MAX_CHAR_X
	ADD R0, R0, #1
	CMP R0, R4
	BLE loop_VGA_clear_charbuff_ASM
	MOVGT R0, #0 // Reset X coordinate
	
	// Increment Y and check if it's greater than MAX_CHAR_Y
	ADD R1, R1, #1
	CMP R1, R5
	BLE loop_VGA_clear_charbuff_ASM
	
	POP {R4-R5, LR}
	BX LR

draw_test_screen:
	push {r4, r5, r6, r7, r8, r9, r10, lr}
	bl VGA_clear_pixelbuff_ASM
	bl VGA_clear_charbuff_ASM
	mov r6, #0
	ldr r10, .draw_test_screen_L8
	ldr r9, .draw_test_screen_L8+4
	ldr r8, .draw_test_screen_L8+8
	b .draw_test_screen_L2
.draw_test_screen_L7:
	add r6, r6, #1
	cmp r6, #320
	beq .draw_test_screen_L4
.draw_test_screen_L2:
	smull r3, r7, r10, r6
	asr r3, r6, #31
	rsb r7, r3, r7, asr #2
	lsl r7, r7, #5
	lsl r5, r6, #5
	mov r4, #0
.draw_test_screen_L3:
	smull r3, r2, r9, r5
	add r3, r2, r5
	asr r2, r5, #31
	rsb r2, r2, r3, asr #9
	orr r2, r7, r2, lsl #11
	lsl r3, r4, #5
	smull r0, r1, r8, r3
	add r1, r1, r3
	asr r3, r3, #31
	rsb r3, r3, r1, asr #7
	orr r2, r2, r3
	mov r1, r4
	mov r0, r6
	bl VGA_draw_point_ASM
	add r4, r4, #1
	add r5, r5, #32
	cmp r4, #240
	bne .draw_test_screen_L3
	b .draw_test_screen_L7
.draw_test_screen_L4:
	mov r2, #72
	mov r1, #5
	mov r0, #20
	bl VGA_write_char_ASM
	mov r2, #101
	mov r1, #5
	mov r0, #21
	bl VGA_write_char_ASM
	mov r2, #108
	mov r1, #5
	mov r0, #22
	bl VGA_write_char_ASM
	mov r2, #108
	mov r1, #5
	mov r0, #23
	bl VGA_write_char_ASM
	mov r2, #111
	mov r1, #5
	mov r0, #24
	bl VGA_write_char_ASM
	mov r2, #32
	mov r1, #5
	mov r0, #25
	bl VGA_write_char_ASM
	mov r2, #87
	mov r1, #5
	mov r0, #26
	bl VGA_write_char_ASM
	mov r2, #111
	mov r1, #5
	mov r0, #27
	bl VGA_write_char_ASM
	mov r2, #114
	mov r1, #5
	mov r0, #28
	bl VGA_write_char_ASM
	mov r2, #108
	mov r1, #5
	mov r0, #29
	bl VGA_write_char_ASM
	mov r2, #100
	mov r1, #5
	mov r0, #30
	bl VGA_write_char_ASM
	mov r2, #33
	mov r1, #5
	mov r0, #31
	bl VGA_write_char_ASM
	pop {r4, r5, r6, r7, r8, r9, r10, pc}
.draw_test_screen_L8:
	.word 1717986919
	.word -368140053
	.word -2004318071

.global _start
_start:
	bl input_loop
end:
	b end

/* VGA Drivers */

.equ PIXEL_BUFFER, 0xc8000000
.equ CHAR_BUFFER, 0xc9000000
.equ MAX_PIXEL_X, 319
.equ MAX_PIXEL_Y, 239
.equ MAX_CHAR_X, 79
.equ MAX_CHAR_Y, 59

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

/* PS/2 Driver */

.equ PS2_REGISTER, 0xff200100

// Checks the RVALID bit in the PS/2 Data register. If it is valid,
// then the data should be read, stored at the address data, and
// the subroutine should return 1. If the RVALID bit is not set, then
// the subroutine should return 0.
// Input: In R0 the address of the register to store the read data
// Output: In R0 if the RVALID bit is set
read_PS2_data_ASM:
	PUSH {R4-R5, LR}
	MOV R4, R0
	
	// Load data from PS/2 data register
	LDR R5, =PS2_REGISTER
	LDR R5, [R5]
	
	// Check RVALID bit
	UBFX R0, R5, #15, #1
	CMP R0, #0
	BEQ finish_read_PS2_data_ASM
	
	// Store value
	STRB R5, [R4]
finish_read_PS2_data_ASM:
	POP {R4-R5, LR}
	BX LR

write_hex_digit:
        push    {r4, lr}
        cmp     r2, #9
        addhi   r2, r2, #55
        addls   r2, r2, #48
        and     r2, r2, #255
        bl      VGA_write_char_ASM
        pop     {r4, pc}
write_byte:
        push    {r4, r5, r6, lr}
        mov     r5, r0
        mov     r6, r1
        mov     r4, r2
        lsr     r2, r2, #4
        bl      write_hex_digit
        and     r2, r4, #15
        mov     r1, r6
        add     r0, r5, #1
        bl      write_hex_digit
        pop     {r4, r5, r6, pc}
input_loop:
        push    {r4, r5, lr}
        sub     sp, sp, #12
        bl      VGA_clear_pixelbuff_ASM
        bl      VGA_clear_charbuff_ASM
        mov     r4, #0
        mov     r5, r4
        b       .input_loop_L9
.input_loop_L13:
        ldrb    r2, [sp, #7]
        mov     r1, r4
        mov     r0, r5
        bl      write_byte
        add     r5, r5, #3
        cmp     r5, #79
        addgt   r4, r4, #1
        movgt   r5, #0
.input_loop_L8:
        cmp     r4, #59
        bgt     .input_loop_L12
.input_loop_L9:
        add     r0, sp, #7
        bl      read_PS2_data_ASM
        cmp     r0, #0
        beq     .input_loop_L8
        b       .input_loop_L13
.input_loop_L12:
        add     sp, sp, #12
        pop     {r4, r5, pc}

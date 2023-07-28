.global _start

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
// Input: R0 color value
VGA_clear_pixelbuff_ASM:
	PUSH {R4-R5, LR}
	
	// Initialize coordinates and color
	MOV R2, R0
	MOV R0, #0
	MOV R1, #0
	
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
	PUSH {LR}
	BL VGA_write_char_ASM
	POP {LR}
	
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

/* Main program */

.equ BOARD_BG_COLOR, 0b1100011000011000
.equ BLOCK_COLOR, 0b0000000000000000
.equ CURSOR_COLOR, 0b0111111111111111
.equ LINE_Y_FLAG, 0b1000000000

GoLBoard:
	//  x 0 1 2 3 4 5 6 7 8 9 a b c d e f    y
	.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 // 0
	.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 // 1
	.word 0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0 // 2
	.word 0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0 // 3
	.word 0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0 // 4
	.word 0,0,0,0,0,0,0,1,1,1,1,1,0,0,0,0 // 5
	.word 0,0,0,0,1,1,1,1,1,0,0,0,0,0,0,0 // 6
	.word 0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0 // 7
	.word 0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0 // 8
	.word 0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0 // 9
	.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 // a
	.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 // b

GoLBoardNeighbors:
	//  x 0 1 2 3 4 5 6 7 8 9 a b c d e f    y
	.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 // 0
	.word 0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,0 // 1
	.word 0,0,0,0,0,0,2,1,2,0,0,0,0,0,0,0 // 2
	.word 0,0,0,0,0,0,3,2,3,0,0,0,0,0,0,0 // 3
	.word 0,0,0,0,0,0,3,3,5,3,3,2,1,0,0,0 // 4
	.word 0,0,0,1,2,3,5,5,5,3,2,1,1,0,0,0 // 5
	.word 0,0,0,1,1,2,3,5,5,5,3,2,1,0,0,0 // 6
	.word 0,0,0,1,2,3,3,5,3,3,0,0,0,0,0,0 // 7
	.word 0,0,0,0,0,0,0,3,2,3,0,0,0,0,0,0 // 8
	.word 0,0,0,0,0,0,0,2,1,2,0,0,0,0,0,0 // 9
	.word 0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0 // a
	.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 // b

Cursor:
	//    x y
	.word 0,0

KeyboardState:
	.byte 0,0,0,0

// Fill pixels in a line from (x1, y1) to (x2, y2) in color c, where
// either x1 = x2 (a vertical line) or y1 = y2 (a horizontal line)
// Input: R0 x1, R1 y1, R2 c, R3 x2 or y2
// R2's 10th bit used to differentiate between x(0) or y(1)
// R2's coordinate needs to be greater than the corresponding one in coordinate 1
VGA_draw_line_ASM:
	PUSH {R4, LR}
	
	// Determine x line or y line
	UBFX R4, R3, #9, #1 // Get 10th bit
	UBFX R3, R3, #0, #9 // Isolate the coordinate
	CMP R4, #0
	BEQ VGA_draw_x_line_ASM
	B VGA_draw_y_line_ASM
VGA_draw_x_line_ASM:
	// Call VGA_draw_point_ASM with the color value
	BL VGA_draw_point_ASM
	
	// Increment x and check if it's greater than x2
	ADD R0, R0, #1
	CMP R0, R3
	BLE VGA_draw_x_line_ASM
	B finish_VGA_draw_line_ASM
VGA_draw_y_line_ASM:
	// Call VGA_draw_point_ASM with the color value
	BL VGA_draw_point_ASM
	
	// Increment y and check if it's greater than y2
	ADD R1, R1, #1
	CMP R1, R3
	BLE VGA_draw_y_line_ASM
	B finish_VGA_draw_line_ASM
finish_VGA_draw_line_ASM:
	POP {R4, LR}
	BX LR

// Draws a 16x12 grid in color c
// Input: R0 c
GoL_draw_grid_ASM:
	PUSH {R4-R5, LR}
	MOV R2, R0
	MOV R4, #0
	MOV R5, #0
	BL GoL_draw_x_grid_ASM_init
	BL GoL_draw_y_grid_ASM_init
	POP {R4-R5, LR}
	BX LR
GoL_draw_x_grid_ASM_init:
	PUSH {R4-R6, LR}
GoL_draw_x_grid_ASM:
	MOV R0, R4
	MOV R1, R5
	LDR R3, =MAX_PIXEL_X
	BL VGA_draw_line_ASM
	
	// Increment y and check if it's greater than MAX_PIXEL_Y
	LDR R6, =MAX_PIXEL_Y
	ADD R5, R5, #20
	CMP R5, R6
	BLE GoL_draw_x_grid_ASM
	SUB R1, R5, #1
	MOV R0, R4
	LDR R3, =MAX_PIXEL_X
	BL VGA_draw_line_ASM
	POP {R4-R6, LR}
	BX LR
GoL_draw_y_grid_ASM_init:
	PUSH {R4-R6, LR}
GoL_draw_y_grid_ASM:
	MOV R0, R4
	MOV R1, R5
	LDR R3, =LINE_Y_FLAG
	LDR R6, =MAX_PIXEL_Y
	ADD R3, R3, R6
	BL VGA_draw_line_ASM
	
	// Increment x and check if it's greater than MAX_PIXEL_X
	LDR R6, =MAX_PIXEL_X
	ADD R4, R4, #20
	CMP R4, R6
	BLE GoL_draw_y_grid_ASM
	SUB R0, R4, #1
	MOV R1, R5
	LDR R3, =LINE_Y_FLAG
	LDR R6, =MAX_PIXEL_Y
	ADD R3, R3, R6
	BL VGA_draw_line_ASM
	POP {R4-R6, LR}
	BX LR

// Draws a rectangle from pixel (x1, y1) to (x2, y2) in color c
// Input: R0 x1, R1 y1, R2 c, R4 x2, R5 y2
VGA_draw_rect_ASM:
	PUSH {LR}
	BL loop_VGA_clear_pixelbuff_ASM_init
	POP {LR}
	BX LR

// Fills the area of grid location (x, y) with color c
// Specified grid location (x, y), 0 ≤ x < 16, 0 ≤ y < 12
// Input: R0 x, R1 y, R2 c
GoL_fill_gridxy_ASM:
	PUSH {R4-R6, LR}
	
	// Compute coordinates
	MOV R6, #20
	MUL R0, R0, R6
	MUL R1, R1, R6
	ADD R4, R0, R6
	ADD R5, R1, R6
	
	// Fill
	BL VGA_draw_rect_ASM
	
	POP {R4-R6, LR}
	BX LR

// Fills grid locations (x, y), 0 ≤ x < 16, 0 ≤ y < 12 with color c 
// if GoLBoard[y][x] == 1
GoL_draw_board_ASM:
	PUSH {R4, LR}
	LDR R4, =GoLBoard
	MOV R1, #0 // Initialize row counter
GoL_draw_board_ASM_loop_row:
	// Detect end
	CMP R1, #12
	BGE GoL_draw_board_ASM_end
	
	// Loop col
	MOV R0, #0 // Initialize col counter
	BL GoL_draw_board_ASM_loop_col_init
	
	// Increment row counter
	ADD R1, R1, #1
	B GoL_draw_board_ASM_loop_row
GoL_draw_board_ASM_loop_col_init:
	PUSH {R5-R6, LR}
GoL_draw_board_ASM_loop_col:
	// Detect end
	CMP R0, #16
	POPGE {R5-R6, LR}
	BXGE LR
	
	// Extract value
	LSL R5, R0, #2
	ADD R6, R4, R5
	LSL R5, R1, #6
	ADD R6, R6, R5
	LDR R5, [R6]
	
	// Draw
	CMP R5, #1
	BNE GoL_draw_board_ASM_dead
GoL_draw_board_ASM_alive:
	MOV R5, R0
	MOV R6, R1
	LDR R2, =BLOCK_COLOR
	BL GoL_fill_gridxy_ASM
	ADD R0, R5, #1 // Increment col counter
	MOV R1, R6
	B GoL_draw_board_ASM_loop_col
GoL_draw_board_ASM_dead:
	MOV R5, R0
	MOV R6, R1
	LDR R2, =BOARD_BG_COLOR
	BL GoL_fill_gridxy_ASM
	ADD R0, R5, #1 // Increment col counter
	MOV R1, R6
	B GoL_draw_board_ASM_loop_col
GoL_draw_board_ASM_end:
	// Redraw grid
	MOV r0, #0
	BL GoL_draw_grid_ASM
	
	POP {R4, LR}
	BX LR

// Draw cursor with color c
// Input: R2 c
GoL_draw_cursor_ASM:
	PUSH {R4-R8, LR}
	
	// Load cursor coordinates
	LDR R4, =Cursor
	ADD R5, R4, #4
	LDR R4, [R4]
	LDR R5, [R5]
	// Compute pixel coordinates
	MOV R6, #20
	MUL R4, R4, R6
	MUL R5, R5, R6
	
	LDR R6, =LINE_Y_FLAG
	LDR R7, =MAX_PIXEL_X
	LDR R8, =MAX_PIXEL_Y
	
	// Draw top line
	MOV R0, R4
	MOV R1, R5
	ADD R3, R0, #20
	BL VGA_draw_line_ASM
	// Draw left line
	MOV R0, R4
	MOV R1, R5
	ADD R3, R5, #20
	ADD R3, R3, R6
	BL VGA_draw_line_ASM
	// Draw right line
	ADD R0, R4, #20
	CMP R0, R7
	MOVGT R0, R7
	MOV R1, R5
	ADD R3, R5, #20
	ADD R3, R3, R6
	BL VGA_draw_line_ASM
	// Draw bottom line
	MOV R0, R4
	ADD R1, R5, #20
	ADD R3, R4, #20
	CMP R1, R8
	MOVGT R1, R8
	BL VGA_draw_line_ASM
	
	POP {R4-R8, LR}
	BX LR

// Iterate through the board and count the number of active
// neighbors of a coordinate
count_active_neighbors:
	PUSH {R4-R9, LR}
	MOV R0, #0 // Initialize x coordinate
	MOV R1, #0 // Initialize y coordinate
	MOV R4, #0 // Initialize counter for active neighbors
	LDR R7, =GoLBoard
	LDR R8, =GoLBoardNeighbors
count_active_neighbors_NW:
	// Get coordinates of neighbor and check if they are valid
	SUB R5, R0, #1 // Neighbor x coordinate
	CMP R5, #0
	BLT count_active_neighbors_N
	CMP R5, #15
	BGT count_active_neighbors_N
	SUB R6, R1, #1 // Neighbor y coordinate
	CMP R6, #0
	BLT count_active_neighbors_N
	CMP R6, #11
	BGT count_active_neighbors_N
	
	// Load value and check if active
	LSL R5, R5, #2
	ADD R9, R7, R5
	LSL R6, R6, #6
	ADD R9, R9, R6
	LDR R5, [R9]
	ADD R4, R4, R5
count_active_neighbors_N:
	// Get coordinates of neighbor and check if they are valid
	MOV R5, R0 // Neighbor x coordinate
	SUB R6, R1, #1 // Neighbor y coordinate
	CMP R6, #0
	BLT count_active_neighbors_NE
	CMP R6, #11
	BGT count_active_neighbors_NE
	
	// Load value and check if active
	LSL R5, R5, #2
	ADD R9, R7, R5
	LSL R6, R6, #6
	ADD R9, R9, R6
	LDR R5, [R9]
	ADD R4, R4, R5
count_active_neighbors_NE:
	// Get coordinates of neighbor and check if they are valid
	ADD R5, R0, #1 // Neighbor x coordinate
	CMP R5, #0
	BLT count_active_neighbors_E
	CMP R5, #15
	BGT count_active_neighbors_E
	SUB R6, R1, #1 // Neighbor y coordinate
	CMP R6, #0
	BLT count_active_neighbors_E
	CMP R6, #11
	BGT count_active_neighbors_E
	
	// Load value and check if active
	LSL R5, R5, #2
	ADD R9, R7, R5
	LSL R6, R6, #6
	ADD R9, R9, R6
	LDR R5, [R9]
	ADD R4, R4, R5
count_active_neighbors_E:
	// Get coordinates of neighbor and check if they are valid
	ADD R5, R0, #1 // Neighbor x coordinate
	CMP R5, #0
	BLT count_active_neighbors_W
	CMP R5, #15
	BGT count_active_neighbors_W
	MOV R6, R1 // Neighbor y coordinate
	
	// Load value and check if active
	LSL R5, R5, #2
	ADD R9, R7, R5
	LSL R6, R6, #6
	ADD R9, R9, R6
	LDR R5, [R9]
	ADD R4, R4, R5
count_active_neighbors_W:
	// Get coordinates of neighbor and check if they are valid
	SUB R5, R0, #1 // Neighbor x coordinate
	CMP R5, #0
	BLT count_active_neighbors_SW
	CMP R5, #15
	BGT count_active_neighbors_SW
	MOV R6, R1 // Neighbor y coordinate
	
	// Load value and check if active
	LSL R5, R5, #2
	ADD R9, R7, R5
	LSL R6, R6, #6
	ADD R9, R9, R6
	LDR R5, [R9]
	ADD R4, R4, R5
count_active_neighbors_SW:
	// Get coordinates of neighbor and check if they are valid
	SUB R5, R0, #1 // Neighbor x coordinate
	CMP R5, #0
	BLT count_active_neighbors_S
	CMP R5, #15
	BGT count_active_neighbors_S
	ADD R6, R1, #1 // Neighbor y coordinate
	CMP R6, #0
	BLT count_active_neighbors_S
	CMP R6, #11
	BGT count_active_neighbors_S
	
	// Load value and check if active
	LSL R5, R5, #2
	ADD R9, R7, R5
	LSL R6, R6, #6
	ADD R9, R9, R6
	LDR R5, [R9]
	ADD R4, R4, R5
count_active_neighbors_S:
	// Get coordinates of neighbor and check if they are valid
	MOV R5, R0 // Neighbor x coordinate
	ADD R6, R1, #1 // Neighbor y coordinate
	CMP R6, #0
	BLT count_active_neighbors_SE
	CMP R6, #11
	BGT count_active_neighbors_SE
	
	// Load value and check if active
	LSL R5, R5, #2
	ADD R9, R7, R5
	LSL R6, R6, #6
	ADD R9, R9, R6
	LDR R5, [R9]
	ADD R4, R4, R5
count_active_neighbors_SE:
	// Get coordinates of neighbor and check if they are valid
	ADD R5, R0, #1 // Neighbor x coordinate
	CMP R5, #0
	BLT count_active_neighbors_next
	CMP R5, #15
	BGT count_active_neighbors_next
	ADD R6, R1, #1 // Neighbor y coordinate
	CMP R6, #0
	BLT count_active_neighbors_next
	CMP R6, #11
	BGT count_active_neighbors_next
	
	// Load value and check if active
	LSL R5, R5, #2
	ADD R9, R7, R5
	LSL R6, R6, #6
	ADD R9, R9, R6
	LDR R5, [R9]
	ADD R4, R4, R5
count_active_neighbors_next:
	// Store the count
	LSL R5, R0, #2
	ADD R9, R8, R5
	LSL R6, R1, #6
	ADD R9, R9, R6
	STR R4, [R9]
	
	MOV R4, #0 // Reset counter for active neighbors
	
	// Increment x and check if it's greater than 15
	ADD R0, R0, #1
	CMP R0, #15
	BLE count_active_neighbors_NW
	MOVGT R0, #0 // Reset x coordinate
	
	// Increment y and check if it's greater than 11
	ADD R1, R1, #1
	CMP R1, #11
	BLE count_active_neighbors_NW
	
	POP {R4-R9, LR}
	BX LR

// Update the playing field according to the logic of
// the game of life when N is pressed
field_state_update:
	// Count active neighbors for all coordinates
	BL count_active_neighbors
	
	MOV R0, #0 // Initialize x coordinate
	MOV R1, #0 // Initialize y coordinate
	LDR R4, =GoLBoard
	LDR R5, =GoLBoardNeighbors
field_state_update_loop:
	// Load number of neighbors
	LSL R6, R0, #2
	LSL R7, R1, #6
	ADD R6, R6, R7
	ADD R7, R5, R6
	LDR R7, [R7]
	
	// Load active or not
	ADD R6, R4, R6
	LDR R8, [R6]
	CMP R8, #1
	BEQ field_state_update_alive
field_state_update_dead:
	// No changes if not active neighbors not equal 3
	CMP R7, #3
	BNE field_state_update_next
	
	// Store new value
	MOV R7, #1
	STR R7, [R6]
	// Update field
	MOV R6, R0
	MOV R7, R1
	LDR R2, =BLOCK_COLOR
	BL GoL_fill_gridxy_ASM
	MOV R0, R6
	MOV R1, R7
field_state_update_alive:
	// No changes if not active neighbors equal 2 or 3
	CMP R7, #2
	MOVEQ R8, #0
	CMP R7, #3
	MOVEQ R8, #0
	CMP R8, #0
	BEQ field_state_update_next
	
	// Store new value
	MOV R7, #0
	STR R7, [R6]
	// Update field
	MOV R6, R0
	MOV R7, R1
	LDR R2, =BOARD_BG_COLOR
	BL GoL_fill_gridxy_ASM
	MOV R0, R6
	MOV R1, R7
field_state_update_next:
	// Increment x and check if it's greater than 15
	ADD R0, R0, #1
	CMP R0, #15
	BLE field_state_update_loop
	MOVGT R0, #0 // Reset x coordinate
	
	// Increment y and check if it's greater than 11
	ADD R1, R1, #1
	CMP R1, #11
	BLE field_state_update_loop
	
	// Redraw grid
	MOV r0, #0
	BL GoL_draw_grid_ASM
	
	// Redraw cursor
	LDR R2, =CURSOR_COLOR
	BL GoL_draw_cursor_ASM
	
	POP {R4-R8, LR}
	BX LR

// Move the cursor up when W is pressed
move_cursor_up:
	// Load current cursor position
	LDR R4, =Cursor
	ADD R4, R4, #4
	LDR R5, [R4]
	
	// Detect if upper limit reached
	CMP R5, #0
	POPEQ {R4-R8, LR}
	BXEQ LR
	
	// Erase old cursor
	MOV R2, #0
	BL GoL_draw_cursor_ASM
	
	// Move cursor coordinates
	SUB R5, R5, #1
	STR R5, [R4]
	
	// Draw new cursor
	LDR R2, =CURSOR_COLOR
	BL GoL_draw_cursor_ASM
	
	POP {R4-R8, LR}
	BX LR

// Move the cursor left when A is pressed
move_cursor_left:
	// Load current cursor position
	LDR R4, =Cursor
	LDR R5, [R4]
	
	// Detect if left limit reached
	CMP R5, #0
	POPEQ {R4-R8, LR}
	BXEQ LR
	
	// Erase old cursor
	MOV R2, #0
	BL GoL_draw_cursor_ASM
	
	// Move cursor coordinates
	SUB R5, R5, #1
	STR R5, [R4]
	
	// Redraw cursor
	LDR R2, =CURSOR_COLOR
	BL GoL_draw_cursor_ASM
	
	POP {R4-R8, LR}
	BX LR

// Move the cursor down when S is pressed
move_cursor_down:
	// Load current cursor position
	LDR R4, =Cursor
	ADD R4, R4, #4
	LDR R5, [R4]
	
	// Detect if lower limit reached
	CMP R5, #11
	POPEQ {R4-R8, LR}
	BXEQ LR
	
	// Erase old cursor
	MOV R2, #0
	BL GoL_draw_cursor_ASM
	
	// Move cursor coordinates
	ADD R5, R5, #1
	STR R5, [R4]
	
	// Redraw cursor
	LDR R2, =CURSOR_COLOR
	BL GoL_draw_cursor_ASM
	
	POP {R4-R8, LR}
	BX LR

// Move the cursor right when D is pressed
move_cursor_right:
	// Load current cursor position
	LDR R4, =Cursor
	LDR R5, [R4]
	
	// Detect if left limit reached
	CMP R5, #15
	POPEQ {R4-R8, LR}
	BXEQ LR
	
	// Erase old cursor
	MOV R2, #0
	BL GoL_draw_cursor_ASM
	
	// Move cursor coordinates
	ADD R5, R5, #1
	STR R5, [R4]
	
	// Redraw cursor
	LDR R2, =CURSOR_COLOR
	BL GoL_draw_cursor_ASM
	
	POP {R4-R8, LR}
	BX LR

// Toggle the selected block on the grid when spacebar is pressed
toggle_selected_block:
	// Load current cursor position
	LDR R4, =Cursor
	ADD R5, R4, #4
	LDR R4, [R4]
	LDR R5, [R5]
	
	LDR R6, =GoLBoard
	
	// Extract value
	LSL R4, R4, #2
	ADD R6, R4, R6
	LSL R5, R5, #6
	ADD R6, R6, R5
	LDR R5, [R6]
	
	// Switch bit
	CMP R5, #0
	MOVEQ R5, #1
	LDREQ R2, =BLOCK_COLOR
	MOVNE R5, #0
	LDRNE R2, =BOARD_BG_COLOR
	
	// Store new value
	STR R5, [R6]
	
	// Redraw board
	LDR R4, =Cursor
	ADD R5, R4, #4
	LDR R0, [R4]
	LDR R1, [R5]
	BL GoL_fill_gridxy_ASM
	
	// Redraw cursor
	LDR R2, =CURSOR_COLOR
	BL GoL_draw_cursor_ASM
	
	POP {R4-R8, LR}
	BX LR

// Clear keyboard buffer when wrong inputs registered
clear_keyboard_buffer:
	PUSH {LR}
clear_keyboard_buffer_loop:
	LDR R0, =KeyboardState
	BL read_PS2_data_ASM
	CMP R0, #1
	BEQ clear_keyboard_buffer_loop
	POP {LR}
	BX LR

// State when polling the keyboard indicates a
// new make character is registered
keyboard_make_detected:
	PUSH {R4-R8, LR}
	
	// Load value
	LDR R4, =KeyboardState
	LDRB R4, [R4]
	
	// Detect if pressed key is valid
	MOV R5, #0
	CMP R4, #0x1D // Detect W
	MOVEQ R5, #1
	CMP R4, #0x1C // Detect A
	MOVEQ R5, #1
	CMP R4, #0x1B // Detect S
	MOVEQ R5, #1
	CMP R4, #0x23 // Detect D
	MOVEQ R5, #1
	CMP R4, #0x29 // Detect spacebar
	MOVEQ R5, #1
	CMP R4, #0x31 // Detect N
	MOVEQ R5, #1
	
	// If pressed is valid, next state
	CMP R5, #1
	BEQ keyboard_break_detected
	
	// Else clear buffer and return
	BL clear_keyboard_buffer
	POP {R4-R8, LR}
	BX LR

keyboard_break_detected:
	// Detect next keyboard input
	LDR R0, =KeyboardState
	BL read_PS2_data_ASM
	CMP R0, #0
	BEQ keyboard_break_detected
	
	// Load value
	LDR R4, =KeyboardState
	LDRB R4, [R4]
	
	// Detect if break is registered
	CMP R4, #0xF0
	BEQ keyboard_break_action_detected
	
	// Else clear buffer and return
	BL clear_keyboard_buffer
	POP {R4-R8, LR}
	BX LR
keyboard_break_action_detected:
	// Detect next keyboard input
	LDR R0, =KeyboardState
	BL read_PS2_data_ASM
	CMP R0, #0
	BEQ keyboard_break_action_detected
	
	// Load value
	LDR R4, =KeyboardState
	LDRB R4, [R4]
	
	// Detect action taken
	LDR R0, =KeyboardState
	BL read_PS2_data_ASM
	LDR R4, =KeyboardState
	LDRB R4, [R4]
	CMP R4, #0x1D // Detect W
	BEQ move_cursor_up
	CMP R4, #0x1C // Detect A
	BEQ move_cursor_left
	CMP R4, #0x1B // Detect S
	BEQ move_cursor_down
	CMP R4, #0x23 // Detect D
	BEQ move_cursor_right
	CMP R4, #0x29 // Detect spacebar
	BEQ toggle_selected_block
	CMP R4, #0x31 // Detect N
	BEQ field_state_update
	
	// Else clear buffer and return
	BL clear_keyboard_buffer
	POP {R4-R8, LR}
	BX LR

// Main program entry point
_start:
	// Clear board
	BL VGA_clear_charbuff_ASM
	
	// Draw board content
	BL GoL_draw_board_ASM
	
	// Draw cursor
	LDR R2, =CURSOR_COLOR
	BL GoL_draw_cursor_ASM

// Main program
main:
	// Poll for keyboard inputs
	LDR R0, =KeyboardState
	BL read_PS2_data_ASM
	CMP R0, #1
	BLEQ keyboard_make_detected
	
	B main

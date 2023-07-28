.global _start

/* Slider Switches Driver */
// returns the state of slider switches in R0
.equ SW_ADDR, 0xFF200040
read_slider_switches_ASM:
    LDR R1, =SW_ADDR     // load the address of slider switch state
    LDR R0, [R1]         // read slider switch state 
    BX  LR

/* LED Driver */
// writes the state of LEDs (On/Off) in R0 to the LEDs' control register
// pre-- R0: data to write to LED state
.equ LED_ADDR, 0xFF200000
write_LEDs_ASM:
    LDR R1, =LED_ADDR    // load the address of the LEDs' state
    STR R0, [R1]         // update LED state with the contents of R0
    BX  LR

/* HEX Display Drivers */
// 0xFF200020 drives digits HEX3 to HEX0
.equ HEX0_3, 0xFF200020
// 0xFF200030 drives digits HEX5 and HEX4
.equ HEX4_5, 0xFF200030
// HEX display indices can be encoded based on a one-hot encoding scheme
.equ zero, 0x3F
.equ one, 0x6
.equ two, 0x5B
.equ three, 0x4F
.equ four, 0x66
.equ five, 0x6D
.equ six, 0x7D
.equ seven, 0x7
.equ eight, 0x7F
.equ nine, 0x6F
.equ ten, 0x77
.equ eleven, 0x7C
.equ twelve, 0x39
.equ thirteen, 0x5E
.equ fourteen, 0x79
.equ fifteen, 0x71
.equ negative, 0x40
.equ clear, 0x0

// Receives the number in R1 (0-15) and returns the numbers one-hot
// encoded for the HEX display in R1
seven_segment_decoder:
	CMP R1, #0
	MOVEQ R1, #zero
	BXEQ LR
	CMP R1, #1
	MOVEQ R1, #one
	BXEQ LR
	CMP R1, #2
	MOVEQ R1, #two
	BXEQ LR
	CMP R1, #3
	MOVEQ R1, #three
	BXEQ LR
	CMP R1, #4
	MOVEQ R1, #four
	BXEQ LR
	CMP R1, #5
	MOVEQ R1, #five
	BXEQ LR
	CMP R1, #6
	MOVEQ R1, #six
	BXEQ LR
	CMP R1, #7
	MOVEQ R1, #seven
	BXEQ LR
	CMP R1, #8
	MOVEQ R1, #eight
	BXEQ LR
	CMP R1, #9
	MOVEQ R1, #nine
	BXEQ LR
	CMP R1, #10
	MOVEQ R1, #ten
	BXEQ LR
	CMP R1, #11
	MOVEQ R1, #eleven
	BXEQ LR
	CMP R1, #12
	MOVEQ R1, #twelve
	BXEQ LR
	CMP R1, #13
	MOVEQ R1, #thirteen
	BXEQ LR
	CMP R1, #14
	MOVEQ R1, #fourteen
	BXEQ LR
	CMP R1, #15
	MOVEQ R1, #fifteen
	BXEQ LR
	CMP R1, #-1
	MOVEQ R1, #negative
	BXEQ LR

// This subroutine turns off all the segments of the selected HEX displays.
// It receives the selected HEX display indices through register R0 as an 
// argument.
HEX_clear_ASM:
	PUSH {R0, R1, R2, LR}
	CMP R0, #4
	LDRGE R1, =HEX4_5 // If index >= 4, load address of HEX4_5
	LDRLT R1, =HEX0_3 // If index < 4, load address of HEX0_3
	SUBGE R0, R0, #4
	MOV R2, #clear
	STRB R2, [R1, R0]
	POP {R0, R1, R2, LR}
	BX LR

// This subroutine turns on all the segments of the selected HEX displays.
// It receives the selected HEX display indices through register R0 as an
// argument.
HEX_flood_ASM:
	PUSH {R0, R1, R2, LR}
	CMP R0, #4
	LDRGE R1, =HEX4_5 // If index >= 4, load address of HEX4_5
	LDRLT R1, =HEX0_3 // If index < 4, load address of HEX0_3
	SUBGE R0, R0, #4
	MOV R2, #eight
	STRB R2, [R1, R0]
	POP {R0, R1, R2, LR}
	BX LR

// This subroutine receives HEX display indices and an integer value, 0-15,
// to display. These are passed in registers R0 and R1, respectively. Based
// on the second argument (R1), the subroutine will display the corresponding 
// hexadecimal digit (0, 1, 2, 3, 4, 5, 6, 7, 8, 9, A, B, C, D, E, F) on 
// the display(s).
HEX_write_ASM:
	PUSH {R0, R1, R2, LR}
	BL seven_segment_decoder
	CMP R0, #4
	LDRGE R2, =HEX4_5 // If index >= 4, load address of HEX4_5
	LDRLT R2, =HEX0_3 // If index < 4, load address of HEX0_3
	SUBGE R0, R0, #4
	STRB R1, [R2, R0] // Write number
	POP {R0, R1, R2, LR}
	BX LR

// This subroutine changes all the HEX displays starting at HEX of R0
// by changing them to the value of R1
HEX_write_all_ASM_init:
	PUSH {R0, LR}
HEX_write_all_ASM:
	BL HEX_write_ASM
	ADD R0, #1
	CMP R0, #5
	BLE HEX_write_all_ASM
	POP {R0, LR}
	BX LR

// This subroutine turns off all the segments of all the HEX displays.
// Starts at HEX of R0
HEX_clear_all_ASM_init:
	PUSH {R0, LR}
HEX_clear_all_ASM:
	BL HEX_clear_ASM
	ADD R0, #1
	CMP R0, #5
	BLE HEX_clear_all_ASM
	POP {R0, LR}
	BX LR

// This subroutine turns on all the segments of all the HEX displays.
// Starts at HEX of R0
HEX_flow_all_ASM_init:
	PUSH {R0, LR}
HEX_flow_all_ASM:
	BL HEX_flood_ASM
	ADD R0, #1
	CMP R0, #5
	BLE HEX_flow_all_ASM
	POP {R0, LR}
	BX LR

/* Pushbuttons Drivers */
.equ pushbutton_data, 0xFF200050
.equ pushbutton_interruptmask, 0xFF200058
.equ pushbutton_edgecapture, 0xFF20005C

// This subroutine returns the indices of the pressed pushbuttons (the 
// keys from the pushbuttons Data register).
read_PB_data_ASM:
	LDR R1, =pushbutton_data // Load the address
	LDRB R0, [R1] // Load the data register
	BX LR

// This subroutine receives a pushbutton index as an argument in R0. 
// Then, it returns 0x00000001 if the corresponding pushbutton is pressed.
PB_data_is_pressed_ASM:
	MOV R1, #0x1
	LSL R1, R1, R0
	PUSH {R1, LR}
	BL read_PB_data_ASM // Read data registers
	POP {R1, LR}
	AND R0, R1, R0 // Determine if pushbutton index is pressed
	CMP R1, R0
	MOVEQ R0, #0x1
	MOVNE R0, #0x0
	BX LR

// This subroutine returns the indices of the pushbuttons that have been
// pressed and then released (the edge bits from the pushbuttons’ 
// Edgecapture register).
read_PB_edgecp_ASM:
	LDR R1, =pushbutton_edgecapture // Load the address
	LDRB R0, [R1] // Load the edgecapture register
	BX LR

// This subroutine receives a pushbutton index as an argument in R0.
// Then, it returns 0x00000001 if the corresponding pushbutton has been
// pressed and released.
PB_edgecp_is_pressed_ASM:
	MOV R1, #0x1
	LSL R1, R1, R0
	PUSH {R1, LR}
	BL read_PB_edgecp_ASM // Read data registers
	POP {R1, LR}
	AND R0, R1, R0 // Determine if pushbutton index is pressed
	CMP R1, R0
	MOVEQ R0, #0x1
	MOVNE R0, #0x0
	BX LR

// This subroutine clears the pushbutton Edgecapture register. You can
// read the edgecapture register and write what you just read back to
// the edgecapture register to clear it.
PB_clear_edgecp_ASM:
	PUSH {LR}
	BL read_PB_edgecp_ASM
	STR R0, [R1]
	POP {LR}
	BX LR

// This subroutine receives pushbutton indices as an argument in R0. 
// Then, it enables the interrupt function for the corresponding 
// pushbuttons by setting the interrupt mask bits to '1'.
enable_PB_INT_ASM:
	LDR R1, =pushbutton_interruptmask
	LDR R2, [R1] // Load the interrupt mask register
	ROR R2, R2, R0
	ORR R2, R2, #0x00000001
	MOV R3, #32
	SUB R0, R3, R0
	ROR R0, R2, R0
	STR R0, [R1]
	BX LR

// This subroutine receives pushbutton indices as an argument in R0. 
// Then, it disables the interrupt function for the corresponding 
// pushbuttons by setting the interrupt mask bits to '0'.
disable_PB_INT_ASM:
	LDR R1, =pushbutton_interruptmask
	LDR R2, [R1] // Load the interrupt mask register
	ROR R2, R2, R0
	AND R2, R2, #0xFFFFFFFE
	MOV R3, #32
	SUB R0, R3, R0
	ROR R0, R2, R0
	STR R0, [R1]
	BX LR

// This subroutine enables the interrupt function for all the 
// pushbuttons by setting the interrupt mask bits to '1'.
enable_PB_INT_all_ASM:
	LDR R1, =pushbutton_interruptmask
	MOV R0, #0xF
	STR R0, [R1]
	BX LR

// This subroutine disables the interrupt function for all the 
// pushbuttons by setting the interrupt mask bits to '0'.
disable_PB_INT_all_ASM:
	LDR R1, =pushbutton_interruptmask
	MOV R0, #0x0
	STR R0, [R1]
	BX LR

/* Main program */
.equ max_value, 0x000FFFFF
.equ min_value, 0xFFF00001

_start:

// Clear HEX displays to " 00000"
clear_display:
	MOV R0, #0
	MOV R1, #0
	BL HEX_write_all_ASM_init
	MOV R0, #5
	BL HEX_clear_ASM

// Read inputs and wait for instruction to calculate
read_wait:
	BL read_slider_switches_ASM // Numbers in register R0
	// Decode the two numbers
	UBFX R4, R0, #0, #4 // set R4 to the first 4 bits of R0
	UBFX R5, R0, #4, #4 // set R5 to the second 4 bits of R0
	
	BL PB_clear_edgecp_ASM // Operation in register R0
	CMP R0, #0x1 // If clear, branch to clear_display
	BEQ clear_display
	CMP R0, #0x0 // If not 0 (no operation), branch to calculate
	BEQ read_wait
	
	MOV R2, R0 // Prepare inputs for calculate
	MOV R0, R4
	MOV R1, R5
	B calculate

// Read inputs and wait for instruction to calculate
// while result is not cleared and is used to calculate
read_wait_uncleared:
	MOV R4, R0 // Result is the first number of the operation
	BL read_slider_switches_ASM // Numbers in register R0
	// Decode the first number
	UBFX R5, R0, #0, #4 // set R5 to the first 4 bits of R0
	
	BL PB_clear_edgecp_ASM // Operation in register R0
	MOV R2, R0 // Prepare inputs for calculate
	MOV R0, R4
	CMP R2, #0x1 // If clear, branch to clear_display
	BEQ clear_display
	CMP R2, #0x0 // If not 0 (no operation), branch to calculate
	BEQ read_wait_uncleared
	
	MOV R1, R5 // Prepare inputs for calculate

// Subroutine to calculate and write result to HEX displays
// R0 contains first number (n), R1 contains second number (m),
// R2 contains operation (op). Result (r) returned in R0
calculate:
	PUSH {R4-R5, LR}
	MOV R5, #0 // Status of valid operation done
	// Computation
	CMP R2, #0x2 // Multiplication
	MOVEQ R5, #1
	MULEQ R4, R0, R1
	CMP R2, #0x4 // Subtraction
	MOVEQ R5, #1
	SUBEQ R4, R0, R1
	CMP R2, #0x8 // Addition
	MOVEQ R5, #1
	ADDEQ R4, R0, R1
	CMP R5, #0
	BEQ clear_display
	
	// Catch overflow
	// If r > 0x000FFFFF or r < 0xFFF00001, the HEX displays should output OVRFLO
	LDR R5, =max_value
	CMP R4, R5
	BGT write_overflow
	LDR R5, =min_value
	CMP R4, R5
	BLT write_overflow
	
	// Reset display
	MOV R0, #0
	MOV R1, #0
	BL HEX_write_all_ASM_init
	
	// Decode sign and write it
	TST R4, #0x80000000
	MOV R0, R4
	BLEQ write_positive_number
	BLNE write_negative_number
	
	// Return to read_wait_uncleared
	MOV R0, R4
	POP {R4-R5, LR}
	B read_wait_uncleared

// Subroutine to write the number (input in R0) if it is positive
write_positive_number:
	PUSH {R4, LR}
	MOV R4, R0
	
	// Write the sign
	MOV R0, #5
	BL HEX_clear_ASM
	
	// Write the magnitude
	MOV R0, #0 // Write first digit
	UBFX R1, R4, #0, #4
	BL HEX_write_ASM
	MOV R0, #1 // Write second digit
	UBFX R1, R4, #4, #4
	BL HEX_write_ASM
	MOV R0, #2 // Write third digit
	UBFX R1, R4, #8, #4
	BL HEX_write_ASM
	MOV R0, #3 // Write fourth digit
	UBFX R1, R4, #12, #4
	BL HEX_write_ASM
	MOV R0, #4 // Write fifth digit
	UBFX R1, R4, #16, #4
	BL HEX_write_ASM
	
	POP {R4, LR}
	BX LR

// Subroutine to write the number (input in R0) if it is negative
write_negative_number:
	PUSH {R4, LR}
	MOV R4, R0
	
	// Write the sign
	MOV R0, #5
	MOV R1, #-1
	BL HEX_write_ASM
	
	// Conversion
	MVN R4, R4
	ADD R4, #1
	
	// Write the magnitude
	MOV R0, #0 // Write first digit
	UBFX R1, R4, #0, #4
	BL HEX_write_ASM
	MOV R0, #1 // Write second digit
	UBFX R1, R4, #4, #4
	BL HEX_write_ASM
	MOV R0, #2 // Write third digit
	UBFX R1, R4, #8, #4
	BL HEX_write_ASM
	MOV R0, #3 // Write fourth digit
	UBFX R1, R4, #12, #4
	BL HEX_write_ASM
	MOV R0, #4 // Write fifth digit
	UBFX R1, R4, #16, #4
	BL HEX_write_ASM
	
	POP {R4, LR}
	BX LR

// Subroutine to write overflow to the HEX displays
write_overflow:
	PUSH {R4-R6, LR}
	MOV R4, #1
	LDR R5, =HEX4_5
	MOV R6, #zero
	STRB R6, [R5, R4] // O
	MOV R6, #0x3E
	STRB R6, [R5] // OV
	MOV R4, #3
	LDR R5, =HEX0_3
	MOV R6, #0x50
	STRB R6, [R5, R4] // OVr
	MOV R4, #2
	MOV R6, #fifteen
	STRB R6, [R5, R4] // OVrF
	MOV R4, #1
	MOV R6, #0x38
	STRB R6, [R5, R4] // OVrFL
	MOV R6, #zero
	STRB R6, [R5] // OVrFLO

// Overflow is detected and waiting for a clear
wait_overflow:
	BL PB_clear_edgecp_ASM // Instruction in register R0
	CMP R0, #0x1 // If instruction is clear, return to read_wait
	BNE wait_overflow
	POP {R4-R6, LR}
	B clear_display

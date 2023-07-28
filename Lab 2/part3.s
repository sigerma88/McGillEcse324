.section .vectors, "ax"
B _start            // reset vector
B SERVICE_UND       // undefined instruction vector
B SERVICE_SVC       // software interrupt vector
B SERVICE_ABT_INST  // aborted prefetch vector
B SERVICE_ABT_DATA  // aborted data vector
.word 0             // unused vector
B SERVICE_IRQ       // IRQ interrupt vector
B SERVICE_FIQ       // FIQ interrupt vector

.text
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
.equ small_o, 0x5C
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

/* Timer Drivers */
.equ timer_load, 0xFFFEC600
.equ timer_counter, 0xFFFEC604
.equ timer_control, 0xFFFEC608
.equ timer_interrupt_status, 0xFFFEC60C

// This subroutine is used to configure the timer.
// Arguments: load value in R0, configuration bits
// in R1
ARM_TIM_config_ASM:
	LDR R2, =timer_load
	STR R0, [R2]
	LDR R2, =timer_control
	STR R1, [R2]
	BX LR

// This subroutine returns in R0 the “F” value
// (0x00000000 or 0x00000001) from the ARM A9
// private timer interrupt status register.
ARM_TIM_read_INT_ASM:
	LDR R1, =timer_interrupt_status
	LDR R0, [R1]
	BX LR

// This subroutine clears the “F” value in the ARM A9
// private timer Interrupt status register. The F bit
// can be cleared to 0 by writing a 0x00000001 to the
// interrupt status register.
ARM_TIM_clear_INT_ASM:
	MOV R0, #0x00000001
	LDR R1, =timer_interrupt_status
	STR R0, [R1]
	BX LR

// This subroutine is used to pause the timer.
ARM_TIM_pause_ASM:
	MOV R0, #0x6
	LDR R1, =timer_control
	STR R0, [R1]
	BX LR

// This subroutine is used to unpause the timer.
ARM_TIM_unpause_ASM:
	MOV R0, #0x7
	LDR R1, =timer_control
	STR R0, [R1]
	BX LR

/* Main program */
.equ timer_duration_start, 0xBEBC200
.equ timer_duration_end, 0x01312D00
.equ max_score, 0x00FFFFFF
PB_int_flag: .word 0x0
tim_int_flag: .word 0x0

_start:
	// Set up stack pointers for IRQ and SVC processor modes
	MOV R1, #0b11010010      // interrupts masked, MODE = IRQ
	MSR CPSR_c, R1           // change to IRQ mode
	LDR SP, =0xFFFFFFFF - 3  // set IRQ stack to A9 on-chip memory
	
	// Change to SVC (supervisor) mode with interrupts disabled
	MOV R1, #0b11010011      // interrupts masked, MODE = SVC
	MSR CPSR, R1             // change to supervisor mode
	LDR SP, =0x3FFFFFFF - 3  // set SVC stack to top of DDR3 memory
	BL  CONFIG_GIC           // configure the ARM GIC
	
	// enable IRQ interrupts in the processor
	MOV R0, #0b01010011      // IRQ unmasked, MODE = SVC
	MSR CPSR_c, R0
	
	// Enable pushbutton KEY interrupt mask register
	BL enable_PB_INT_all_ASM
	
	// Reset timer
	LDR R0, =timer_duration_start // Load number of cycles for 1 second for a 200MHz clock
	MOV R1, #0x6 // prescaler = 0, I = 1, A = 1, E = 0
	BL ARM_TIM_config_ASM
	
	// Reset HEX display
	MOV R0, #0
	BL HEX_clear_all_ASM_init

// Menu for the game at the beginning and when it is stopped
// (start PB0, stop PB1, reset PB2)
// Actions are edge triggered on the push buttons
// start -> Started game state, stop -> nothing, reset -> nothing
IDLE:
	LDR R1, =PB_int_flag
	LDR R0, [R1] // Get flag
	MOV R2, #0x0
	CMP R0, #0x1 // start
	STREQ R2, [R1] // Clear flag
	BEQ main_game_init
	B IDLE

// Menu for the game when it is paused
// (start PB0, stop PB1, reset PB2)
// Actions are edge triggered on the push buttons
// start -> resume game, stop -> nothing, reset -> Initial game state
menu_game_paused_init:
	PUSH {LR}
	BL ARM_TIM_pause_ASM
menu_game_paused:
	LDR R1, =PB_int_flag
	LDR R0, [R1] // Get flag
	MOV R2, #0x0
	CMP R0, #0x4 // reset
	STREQ R2, [R1] // Clear flag
	POPEQ {LR}
	BEQ _start
	CMP R0, #0x1 // start
	BNE menu_game_paused
	STR R2, [R1] // Clear flag
	BL ARM_TIM_unpause_ASM
	POP {LR}
	BX LR

// Menu for the game at the end of it
// (start PB0, stop PB1, reset PB2)
// Actions are edge triggered on the push buttons
// start -> nothing, stop -> nothing, reset -> Initial game state
menu_game_finish:
	LDR R1, =PB_int_flag
	LDR R0, [R1] // Get flag
	MOV R2, #0x0
	CMP R0, #0x4 // reset
	STREQ R2, [R1] // Clear flag
	BEQ _start
	B menu_game_finish

// Configure the Generic Interrupt Controller (GIC)
CONFIG_GIC:
	PUSH {LR}
	// Configure the FPGA KEYS interrupt (ID 73)
	// Configure the A9 Private Timer interrupt (ID 29)
	// 1. set the target to cpu0 in the ICDIPTRn register
	// 2. enable the interrupt in the ICDISERn register
	// CONFIG_INTERRUPT (int_ID (R0), CPU_target (R1));
	MOV R0, #73            // KEY port (Interrupt ID = 73)
	MOV R1, #1             // this field is a bit-mask; bit 0 targets cpu0
	BL CONFIG_INTERRUPT
	MOV R0, #29            // Timer port (Interrupt ID = 29)
	BL CONFIG_INTERRUPT
	
	// configure the GIC CPU Interface
	LDR R0, =0xFFFEC100    // base address of CPU Interface
	// Set Interrupt Priority Mask Register (ICCPMR)
	LDR R1, =0xFFFF        // enable interrupts of all priorities levels
	STR R1, [R0, #0x04]
	// Set the enable bit in the CPU Interface Control Register (ICCICR).
	// This allows interrupts to be forwarded to the CPU(s)
	MOV R1, #1
	STR R1, [R0]
	// Set the enable bit in the Distributor Control Register (ICDDCR).
	// This enables forwarding of interrupts to the CPU Interface(s)
	LDR R0, =0xFFFED000
	STR R1, [R0]
	POP {PC}

// Configure registers in the GIC for an individual Interrupt ID
// We configure only the Interrupt Set Enable Registers (ICDISERn) and
// Interrupt Processor Target Registers (ICDIPTRn). The default (reset)
// values are used for other registers in the GIC
// Arguments: R0 = Interrupt ID, N
// R1 = CPU target
CONFIG_INTERRUPT:
	PUSH {R4-R5, LR}
	// Configure Interrupt Set-Enable Registers (ICDISERn).
	// reg_offset = (integer_div(N / 32) * 4
	// value = 1 << (N mod 32)
	LSR R4, R0, #3    // calculate reg_offset
	BIC R4, R4, #3    // R4 = reg_offset
	LDR R2, =0xFFFED100
	ADD R4, R2, R4    // R4 = address of ICDISER
	AND R2, R0, #0x1F // N mod 32
	MOV R5, #1        // enable
	LSL R2, R5, R2    // R2 = value
	// Using the register address in R4 and the value in R2 set the
	// correct bit in the GIC register
	LDR R3, [R4]      // read current register value
	ORR R3, R3, R2    // set the enable bit
	STR R3, [R4]      // store the new register value
	// Configure Interrupt Processor Targets Register (ICDIPTRn)
	// reg_offset = integer_div(N / 4) * 4
	// index = N mod 4
	BIC R4, R0, #3    // R4 = reg_offset
	LDR R2, =0xFFFED800
	ADD R4, R2, R4    // R4 = word address of ICDIPTR
	AND R2, R0, #0x3  // N mod 4
	ADD R4, R2, R4    // R4 = byte address in ICDIPTR
	// Using register address in R4 and the value in R2 write to
	// (only) the appropriate byte
	STRB R1, [R4]
	POP {R4-R5, PC}

// Undefined instructions
SERVICE_UND:
	B SERVICE_UND
// Software interrupts
SERVICE_SVC:
	B SERVICE_SVC
// Aborted data reads
SERVICE_ABT_DATA:
	B SERVICE_ABT_DATA
// Aborted instruction fetch
SERVICE_ABT_INST:
	B SERVICE_ABT_INST
// IRQ
SERVICE_IRQ:
	PUSH {R0-R7, LR}
	// Read the ICCIAR from the CPU Interface
	LDR R4, =0xFFFEC100
	LDR R5, [R4, #0x0C] // read from ICCIAR
	// NOTE: Check which interrupt has occurred (check interrupt IDs)
	// Then call the corresponding ISR
	// If the ID is not recognized, branch to UNEXPECTED
	// See the assembly example provided in the DE1-SoC Computer Manual
	// on page 46
Pushbutton_check:
	CMP R5, #73
	BLEQ KEY_ISR
	BEQ EXIT_IRQ
Timer_check:
	CMP R5, #29
UNEXPECTED:
	BNE UNEXPECTED      // if not recognized, stop here
	BL ARM_TIM_ISR
EXIT_IRQ:
	// Write to the End of Interrupt Register (ICCEOIR)
	STR R5, [R4, #0x10] // write to ICCEOIR
	POP {R0-R7, LR}
	SUBS PC, LR, #4
// FIQ
SERVICE_FIQ:
	B SERVICE_FIQ

// Pushbutton interrupt service routine
KEY_ISR:
	PUSH {LR}
	// Read pushbutton edgecapture register and clear
	BL PB_clear_edgecp_ASM
	// Store edgecapture status in flag
	LDR R1, =PB_int_flag
	STR R0, [R1]
	POP {LR}
	BX LR

// Timer interrupt service routine
ARM_TIM_ISR:
	PUSH {LR}
	// Read interrupt status
	BL ARM_TIM_read_INT_ASM
	// Store interrupt status in flag
	LDR R1, =tim_int_flag
	STR R0, [R1]
	// Clear interrupt
	BL ARM_TIM_clear_INT_ASM
	POP {LR}
	BX LR

// Subroutine to divide by 10 and return the the quotient in R0 and the rest in R1
// Input: R0 = dividend
// Output: R0 = quotient, R1 = remainder
divide_by_10:
    PUSH {R4-R6, LR}
	MOV R4, R0 // dividend
    MOV R5, #10 // divisor
    MOV R6, #0 // quotient
divide_by_10_loop:
    CMP R4, R5
    BLT divide_by_10_done
    ADD R6, R6, #1
    SUB R4, R4, R5
    B divide_by_10_loop
divide_by_10_done:
	MUL R4, R6, R5
	SUB R1, R0, R4 // Compute remainder
	MOV R0, R6
    POP {R4-R6, LR}
	BX LR

// Subroutine to write to the display the timer
timer_write:
	PUSH {R4-R5, LR}
	
	// Read counter and display it on the HEX display
	BL divide_by_10
	MOV R4, R0 // Get the quotient of counter divided by 10 (second digit)
	MOV R5, R1 // Get the remainder of counter divided by 10 (first digit)
	MOV R0, #5 // Write second digit
	MOV R1, R4
	BL HEX_write_ASM
	MOV R0, #4 // Write first digit
	MOV R1, R5
	BL HEX_write_ASM
	
	POP {R4-R5, LR}
	BX LR

// Countdown for the initial part of the game 30>=t>=10 seconds
// Counter in R0, returns in R0 the updated counter and in R1 
// the game phase
initial_countdown:
	PUSH {R4, LR}
	MOV R4, R0
	
	// Check the interrupt status, reset if necessary
	LDR R1, =tim_int_flag
	LDR R0, [R1] // Get flag
	MOV R2, #0x0
	CMP R0, #0x00000001
	STREQ R2, [R1] // Clear flag
	SUBEQ R4, #1
	MOV R0, R4
	BLEQ timer_write
	
	// Assert in initial phase or final phase and set the flag
	MOV R0, R4
	MOV R1, #0x0
	CMP R0, #0xa
	BEQ final_countdown_init
	
	POP {R4, LR}
	BX LR

// Initialize the clock for the final countdown
// Returns in R0 the updated counter and in R1 the game phase
final_countdown_init:
	// Configure timer
	LDR R0, =timer_duration_end // Load number of cycles for 0.1 second for a 200MHz clock
	MOV R1, #0x7 // prescaler = 0, I = 1, A = 1, E = 1
	BL ARM_TIM_config_ASM
	
	// Initialize counter
	MOV R0, #100
	MOV R1, #0x1
	
	POP {R4, LR}
	BX LR

// Final countdown fot the last 10 seconds of the game
// Counter in R0, returns in R0 the updated counter and in R1 
// the game phase
final_countdown:
	PUSH {R4, LR}
	MOV R4, R0
	
	// Check the interrupt status, reset if necessary
	LDR R1, =tim_int_flag
	LDR R0, [R1] // Get flag
	MOV R2, #0x0
	CMP R0, #0x1
	STREQ R2, [R1] // Clear flag
	SUBEQ R4, #1
	MOV R0, R4
	BLEQ timer_write
	
	// Check if game has ended
	MOV R0, R4
	MOV R1, #0x1
	CMP R0, #0x0
	MOVEQ R1, #0x2
	
	POP {R4, LR}
	BX LR

// Subroutine to write overflow to the HEX displays
write_overflow:
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
	B menu_game_finish

// Write the mole to the display
// Receives in R0 the position of the mole (0-3)
write_mole:
	PUSH {R4-R6, LR}
	MOV R4, R0
	
	// Check for switches
	BL read_slider_switches_ASM
	LDR R5, =0x1
	LSL R5, R4
	AND R6, R0, R5 // AND to get slider switch value at that bit position
	CMP R5, R6
	BEQ switch_block
	
	LSL R4, R4, #3 // Multiply by 8 to get tge shift for the mole
	LDR R5, =small_o
	LSL R5, R5, R4
	LDR R6, =HEX0_3 // Load address of HEX0_3
	STR R5, [R6] // Write mole
	
	POP {R4-R6, LR}
	BX LR
switch_block:
	POP {R4-R6, LR}
	BX LR

// Generate the random mole
generate_mole_init:
	PUSH {R4, LR}
generate_mole:
	// Load the timer counter
	LDR R4, =timer_counter
	LDR R4, [R4]
	// Manipulate time counter for randomization
	UBFX R0, R4, #0, #2 // set R0 to the first 2 bits of R4
	
	// Random write mole to display
	CMP R0, #0
	BLEQ write_mole
	CMP R0, #1
	BLEQ write_mole
	CMP R0, #2
	BLEQ write_mole
	CMP R0, #3
	BLEQ write_mole
	
	// Check if it is written
	LDR R4, =HEX0_3
	LDR R4, [R4] // Value displayed in HEX0_3
	CMP R4, #0
	BEQ generate_mole
	
	POP {R4, LR}
	BX LR

// Whacking a mole
// Receives in R0 the whacked display by one-hot encoding
whack:
	PUSH {R4, LR}
	MOV R4, R0
	
	// Convert one-hot encoding to display number
	CMP R4, #1
	MOVEQ R0, #0
	CMP R4, #2
	MOVEQ R0, #1
	CMP R4, #4
	MOVEQ R0, #2
	CMP R4, #8
	MOVEQ R0, #3
	
	// Clear display
	BL HEX_clear_ASM
	
	// Generate mole
	BL generate_mole_init
	
	POP {R4, LR}
	BX LR

// Generate the random mole and check for its whacking
// Receives in R0 the current score and returns in R0 the
// updated score
whack_a_mole:
	PUSH {R4-R7, LR}
	MOV R4, R0 // Score
	MOV R5, #-1 // Position of the mole on the displays one-hot encoded
	
	// Assert if mole whacked
	LDR R6, =HEX0_3
	LDR R6, [R6] // Value displayed in HEX0_3
	// Check HEX0
	UBFX R7, R6, #0, #8
	CMP R7, #small_o
	MOVEQ R5, #1
	// Check HEX1
	UBFX R7, R6, #8, #8
	CMP R7, #small_o
	MOVEQ R5, #2
	// Check HEX2
	UBFX R7, R6, #16, #8
	CMP R7, #small_o
	MOVEQ R5, #4
	// Check HEX3
	UBFX R7, R6, #24, #8
	CMP R7, #small_o
	MOVEQ R5, #8
	// Compare with switches
	BL read_slider_switches_ASM
	CMP R0, R5
	ADDEQ R4, R4, #1
	BLEQ whack
	
	MOV R0, R4
	POP {R4-R7, LR}
	BX LR

// Initialize the game
main_game_init:
	// Start the timer
	LDR R0, =timer_duration_start // Load number of cycles for 1 second for a 200MHz clock
	MOV R1, #0x7 // prescaler = 0, I = 1, A = 1, E = 1
	BL ARM_TIM_config_ASM
	
	// Initialize time counter
	MOV R0, #30
	BL timer_write
	
	// Generate mole
	BL generate_mole_init
	
	// Initialize counter, game phase and score
	MOV R4, #30
	MOV R5, #0x0
	MOV R6, #0

// Main routine where the game happens and where the subroutines are called
main_game:
	// Timer countdown
	MOV R0, R4
	MOV R1, R5
	CMP R1, #0x0
	BLEQ initial_countdown
	CMP R1, #0x1
	BLEQ final_countdown
	CMP R1, #0x2
	BEQ game_end
	MOV R4, R0 // Timer counter
	MOV R5, R1 // Game phase
	
	// Gameplay and score keeping
	MOV R0, R6
	BL whack_a_mole
	MOV R6, R0
	
	// Menu actions
	LDR R1, =PB_int_flag
	LDR R0, [R1] // Get flag
	MOV R2, #0x0
	CMP R0, #0x2 // stop
	STREQ R2, [R1] // Clear flag
	BLEQ menu_game_paused_init
	CMP R0, #0x4 // reset
	STREQ R2, [R1] // Clear flag
	BEQ _start
	
	B main_game

// When the game ends, display the score and go back to the menu
game_end:
	// End the timer and disable it
	LDR R0, =timer_duration_start // Load number of cycles for 1 second for a 200MHz clock
	MOV R1, #0x6 // prescaler = 0, I = 1, A = 1, E = 0
	BL ARM_TIM_config_ASM
	
	// Catch score overflow
	// If r > 0x00FFFFFF, the HEX displays should output OVRFLO
	LDR R5, =max_score
	CMP R6, R5
	BGT write_overflow
	
	// Write the score
	MOV R0, #0 // Write first digit
	UBFX R1, R6, #0, #4
	BL HEX_write_ASM
	MOV R0, #1 // Write second digit
	UBFX R1, R6, #4, #4
	BL HEX_write_ASM
	MOV R0, #2 // Write third digit
	UBFX R1, R6, #8, #4
	BL HEX_write_ASM
	MOV R0, #3 // Write fourth digit
	UBFX R1, R6, #12, #4
	BL HEX_write_ASM
	MOV R0, #4 // Write fifth digit
	UBFX R1, R6, #16, #4
	BL HEX_write_ASM
	MOV R0, #5 // Write sixth digit
	UBFX R1, R6, #20, #4
	BL HEX_write_ASM
	
	// Go back to menu
	B menu_game_finish

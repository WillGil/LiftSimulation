; ----------------------- CONTROLLING THE LIFT -------------------------------------
; ----------------------------------------------------------------------------------
; This program is a lift simulation.
; It workds the same as actual lift, if the up button is pressed and then the down button, it will go up then down 

; This program works on speeds 3 and 4. As the code has been made efficent to allow this.

; The lift will display the Current status of where it is/what is is doing:
; This could be: "TOP", "BOTTOM", "DOWN" , "UP"

; The lift will also go straight back down to the bottom from any position when the "Enter" button 
; is clicked on the virtual numeric keypad. It will then return to normal functionality. 

;============================= SETTING BITS ==========================================
	JMP Start 		; Skip past data table 

	DB 	9E		; Hardware Timer Interrupt Vector
	DB 	00		; Unused
	DB 	9F		; Numeric Keypad Interrupt Vector 
		
	DB 	"BOTTOM"	; Word Bottom for display 
	
	DB 	"TOP   " 	; Word TOP with spaces to clear other characters

	DB 	"UP    " 	; Word UP with spaces to clear other charcaters 

	DB 	"DOWN  " 	; Word DOWN with spaces to clear other characters 

;=====================================================================================
;----------------------------- SETTING UP THE PROGRAM --------------------------------
Start:
	CLO			; Close all external windows 
	STI			; Set the interrupt flag
	OUT 	08		; Displays the virtual numeric keypad (Task 5}
	OUT	06		; Display lift window	
	IN 	06		; Read lift status 
	CMP 	AL, 08		; Check if down sensor is on 
	JZ 	Stop_down	; If the down sensor is on jump to stop_up to print status
	CMP 	AL, 04		; Check if up sensor is on 
	JZ 	Stop_up 	; If the up sensor is on jump to stop_up to print status

;--------------------------- RUN WHEN THE PROGRAM IS IDLE ----------------------------
Inactive:
	IN	06		; Read lift status
	AND	AL, 30		; Isolate UP or DOWN button bit
	JZ 	Inactive	; If none of the buttons are pressed Jump back to inactive

;---------------------------- CHECKING FOR UP BUTTON -------------------------------

	AND 	AL, 20 		; Check if UP button is pressed
	JNZ 	UP_INTRO	; If Up button is pushed go UP_INTRO else drop down to DOWN_INTRO

;----------------------------- MAKING LIFT GO DOWN ---------------------------------
DOWN_INTRO:
	IN 	06		; Read lift status 	
	OR 	AL, 12		; Set Down motor bit and button 
	CMP 	AL, 1A 		; Compare AL with the bottom sensor being on to avoid crashing	
	JZ 	Stop_down	; Stop the lift if the sensor is on
	OUT 	06		; Reset the DOWN button and turn on DOWN motor	
	MOV 	BL, 17		; 17 hex RAM location stores the first letter of "DOWN  "
	CALL 	8B		; Calls print function

;------------------------------ CHECKING FOR DOWN SENSOR -----------------------------
DOWN:
	IN 	06 		; Read lift status 
	AND 	AL, 08		; Check if bottom sensor is activated 
	JZ 	DOWN 		; If it is not activated jump up to DOWN and recheck 

;------------------------------ STOPPING LIFT GOING DOWN -----------------------------
Stop_down:
	IN	06		; Read lift status 
	AND 	AL, ED		; Clear DOWN button bit and DOWN motor 
	OUT	06		; Stop Motor and clear button
	MOV 	BL ,05		; 05 hex RAM location stores the first letter of "BOTTOM"
	CALL 	8B		; Calls print function
	JMP 	Inactive	; After prodecure is called return to inactive state

;----------------------------- MAKING LIFT GO UP -----------------------------------
UP_INTRO:
	IN	06		; Read lift status
	INC	AL		; Set UP motor bit, since it is only adding one the instruction can be simplified 
	CMP 	AL, 25 		; Compare AL with the top sensor being on to avoid crashing
	JZ 	Stop_up		; Stop the lift if the sensor is on 
	OUT	06		; Reset UP button and turn on UP motor	
	MOV 	BL, 11		; 11 hex RAM location stores the first letter of "UP    "
	CALL 	8B		; Calls print function

;------------------------------ CHECKING FOR UP SENSOR -----------------------------
UP:	
	IN 	06		; Read lift status 
	AND 	AL,06		; Check if top sensor is activated AND check if down motor is on
	JZ 	UP		; If it is not activated jump to up

;------------------------------ STOPPING LIFT GOING UP -----------------------------
Stop_up:
	IN 	06		; Read lift status 
	AND	AL, DE		; Clear UP button bit and UP motor 
	OUT	06		; Stop Motor and clear button
	CMP 	AL, 12		; Compare AL With the bits for the lift to be going down
	JZ 	DOWN		; If the lift is going down jump to DOWN to make sure it stops 
	MOV 	BL, 0B		; OB hex RAM location stores the first letter of "TOP"	
	CALL 	8B		; Calls print function
	JMP 	Inactive	; After prodecure is called return to inactive state

;------------------------------ PRINT PROCEDURE ------------------------------------
Print:
	ORG 	8B		; Code is generated after RAM location 8B
	MOV	DL, C0 		; Set DL to contain the first display bit each time print is jumped to 

print_loop:
	MOV 	CL,[BL]		; Move the contents of BL RAM location into register CL 
	MOV	[DL],CL		; Move the contens of the CL register into the ram location of CL 
	INC 	BL		; Increment BL to point to the next RAM location
	INC 	DL		; Increment DL to point to the next display location 
	CMP 	DL,C6		; has the lift finished "BOTTOM" OR "TOP   " 
	JNZ 	print_loop	; If yes then jump back to inactive 
	RET			; Return to where the procedure was called from 

;---------------------------------- Hardware Timer --------------------------------------------

	ORG	9E        	; Code is generated after Ram location 9E 
	IRET			; Restore IP from the stack and jump to it 

;---------------------------------- Keyboard Handler ------------------------------------------ 
	ORG 	9F		; Code is generated after Ram location 9F 
	CLI			; Prevent re-entrant use
	PUSH	AL		; PUSH AL on to the stack so it can be restored later  
	PUSHF			; SR flags are saved onto the stack
	IN 	06		; Read lift status 
	AND 	AL,08		; Isolate down sensor and check if it's on 
	JNZ 	Not_enter	; if it is on then jmp to not_enter where the lift is not moved 
	IN	08		; Read in numeric keypad key 
	CMP	AL, 0D		; check to see if it is the enter key 
	JNZ	Not_enter	; if it is not the enter key jump to not_enter
	XOR 	AL, 13		; Use xor to isolate the buttons to go down in the lift 
	OUT 	06		; Reset the down button and motor 
Not_enter:	
	POPF			; Restore flags 
	POP	AL		; Restore the value of AL back 
	STI			; Set the interrupt flag 
	IRET			; Restore IP from the stack and jump to it 
;--------------------------------------------------------------------------------------------
END
;--------------------------------------------------------------------------------------------
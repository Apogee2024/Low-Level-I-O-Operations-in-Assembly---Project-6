TITLE Project_6 (Proj6_bradsean.asm)

; Author:		 Sean Brady
; Last Modified: 6/9/2024
; OSU email address: bradsean@oregonstate.edu
; Course number/section:   CS271 Section 1
; Project Number: 6        Due Date: 6/9/2024
; Description: This program takes 10 numbers as input from the user and takes the string and converts it to it's numeric equivalent.  
; It checks that the input fits within an SDWORD and that the input it valid.
; It then stores that number in the correct positiion in the array. It then displays the array.
; It displays a running total of the numbered entered. Finally, it shows the average of the numbers entered and says bye

INCLUDE Irvine32.inc

; ---------------------------------------------------------------------------------
; Name: mGetString
; Gets a string from a the user and stores it.
;
; Preconditions: do not use EDX, ECX, EDI, ESI as arguments
; Returns:  the mInput buffer contains the string that was entered, 
; mCharsRead contains the number of characters read.
;
; Receives:
; mPromptOffset = prompt address offset
; mMaxChar =  number of the maximum number of character it can receive
; mInputBuffer = offset for the buffer of the characters to be stored
; mCharsRead = offset for the number of characters read
; ---------------------------------------------------------------------------------
mGetString	MACRO    mPromptOffset:REQ ,mMaxChar:REQ ,mInputBuffer:REQ ,mCharsRead:REQ 

; iokn bpreserve registers
	push  EDX						; offset for the prompt
	push  ECX						; maximum numbers of characteres that can be read
    mov   EDX, mPromptOffset		; prompt offset was pushed before calling proc

; write the prompt for the string to the screen
	call  WriteString
	push  ESI						; used for string primitives
	
	push  EDI						; used as destination address for input buffer
	mov   ECX, mMaxChar 
	push  EAX
	

	mov   ESI, mCharsRead			; setup address to  store number of bytes read
	mov   EAX, 0					; sto takes value of AL, so mov 0 into it
; clear the buffer before copying more data into it!
	mov   EDI, mInputBuffer
	rep   stosb						
	mov   EDX, mInputBuffer			; move offset of inputBuffer into EDX
	mov   ECX, mMaxChar				; set max # of characters
	call  ReadString
; store the number of bytes read
	mov   [ESI],EAX					
; cleanup	
	pop   EAX
	pop	  EDI
	pop   ESI
	pop   ECX
	pop   EDX				
ENDM

; ---------------------------------------------------------------------------------
; Name: mDispString
;
; displays the string at the given offset
;
; Preconditions: do not use EDX as an argument
; Postconditions: the string has been written to the screen
;
; Receives: mStringOffset = string's address for the string to be displayed
; 
; ---------------------------------------------------------------------------------
mDispString  MACRO	mStringOffset:REQ 

;preserve registers
	push  EDX		
	mov   EDX, mStringOffset 
	call  WriteString

;restore registers
	pop   EDX		
ENDM

.data
numArray    SDWORD	10 DUP(0)
numStrArray BYTE    200 DUP(0)
charsInANum DWORD   10 DUP(0)
maxChar		DWORD   20
valNumCount	DWORD	0			     ; the number of valid numbers entered
progTitle	BYTE    "Project 6: Designing low-level I/O procedures",13,10, 
					"Written by:  Sean Brady  ~(\^_^)~",13,10,13,10,0 
promptOne	BYTE    "Please provide 10 signed decimal integers.",13,10,  
					"Each number needs to be small enough to fit inside a 32 bit register.",13,10,
					"After you have finished inputting the raw numbers I will display a",13,10,
					"list of the integers, their sum, and their average value.",13,10,13,10,0 
numPrompt	BYTE    "Please enter a signed number: ",0
numError    BYTE	"ERROR: You did not enter a signed number or your number was too big.",13,10,0
tryAgain	BYTE    "Please try again:             ",0
extraC1		BYTE    "**EC: Number each line of user input and display a running subtotal of the user's valid numbers.",13,10,
					"These displays must use WriteVal. (1 pt)",13,10,13,10,0
numArrDisp	BYTE    "You entered the following numbers: ",13,10,0
sumDisp		BYTE    "The sum of these numbers is:    ",0
averageDisp BYTE    "The truncated average is:     ",0
lineNum     SDWORD  1
finalBye	BYTE    "Thank you! It was a super fun class and a great quarter. I hope our paths cross again someday",13,10,
					"until then, have a great day!",0

.code
main PROC

; display the program title
	mDispString offset progTitle     

; display instructions for the user
	mDispString offset promptOne	 

; display extraCredit Attempt Description
	mDispString offset extraC1		 
	
	push  ECX
	mov   ECX, 10					 ; initialize to get 10 numbers

_getNumbersLoop:

; get numbers from the user
	push  offset tryAgain
	push  offset lineNum
	push  offset numError
	push  maxChar
	push  offset numPrompt			
	push  offset numArray
	push  valNumCount
	call  ReadVal					
	inc   valNumCount

; display the running sum
	call  CrLf
	push  offset sumDisp			
	push  offset numArray
	push  valNumCount
	call  CalculateSumAndDisplay
	call  CrLf
	loop  _getNumbersLoop

; display the number array
	call  CrLf
	push  offset numArrDisp
	push  offset numArray			
	push  valNumCount
	call  NumArrayDisplay

; display the sum
	call  CrLf
	push  offset sumDisp			
	push  offset numArray
	push  valNumCount
	call  CalculateSumAndDisplay

; display the average
	call  CrLf
	push  offset averageDisp		
	push  offset numArray
	push  valNumCount
	call  CalcAverageAndDisplay

; say goodbye
	call  CrLf
	mDispString offset finalBye		

	call  CrLf
	invoke ExitProcess,0

main ENDP

; ---------------------------------------------------------------------------------
; Name: WriteVal
;
; Receives an SDWORD and by value, and converts it to a string of ASCII digits, reverses the items to display
; in the correct order and then writes the digits.
;
; Preconditions: an number has been pushed to the stack
;
; Postconditions: the number pushed has been written to the screen.
;
; Receives:
; [EBP+8] = A number as a value, SDWORD
;
; returns: none
; ---------------------------------------------------------------------------------

WriteVal PROC

;declare local variables
	LOCAL pInputBuffer[20]:BYTE		; used to store the reversed number string
	LOCAL pOutputBuffer[21]:BYTE	; used to display the number

;preserve registers
	push  EDI						 ; destination address to store character used in string primitive
	push  ECX						 ; used a counter when reversing the string
	push  EAX						 ; holds the value of the number
	push  EBX						 ; used as a dividend
	push  ESI						 ; will be used as a sign check / multiplier
	mov   ESI, 1

; fill the buffer with 0's to prevent an error
_zeroFillTheBuffers:
	mov   EAX, 0
	lea   EDI, pInputBuffer
	mov   ECX, 20                    ; fill the buffer with 0s for the next iteration!
	rep   stosb
	lea   EDI, pOutputBuffer
	mov   ECX,21
	rep   stosb

; convert integer to ascii text
_setupConvertIntToAscii:
	mov   EAX, [EBP +8]				 ; EAX now holds value of sdword
	cmp   EAX, 0
	jns   _divSetupCont				 ; check if the number is negative
	mov   ESI, -1
	imul  EAX, ESI

;continue setting up for division
_divSetupCont:
	mov   EBX, 10
	lea   EDI, pInputBuffer			 ; where the output will be stored in reverse
	push  ESI			             ; store value of ESI for later!
	mov   ESI, 0					 ; number of numbers for reversal loop later

; convert number from decimal to into string
_convertLoop:
	cdq		   					     ; sign extend eax into edx
	idiv  EBX						 ; divide by 10
	push  EAX						 ; we need to use AL for stoSB so preserve
	mov   EAX, EDX					 ; move remainder into EAX for storage
	add   AL, 48					 ; convert digit to ascii code
	stosb							 ; store the contents of AL into the buffer, increment EDI
	pop   EAX						 ; restore EAX
	inc   ESI
	cmp   EAX, 0					 ; if quotient is 0 no need to keep going
	jne   _convertLoop
	mov   ECX,  ESI
	pop   ESI						 ; ESI now holds if original number was positive or negative

; check if the number if negative
	cmp   ESI,0		
	jns   _reverseOutput
	mov   AL, 45					 ; 45 is dec code for ascii character 
	stosb				  			 ; adding the negative sign
	inc   ECX						 ; increment ecx cause theres another character 

; reverse the output since the number is current string for number is stored in reverse
_reverseOutput:
	std								 ; set std to go backward through the string
	lea   ESI, pInputBuffer
	add   ESI, ECX					 ; the length of the string
	sub   ESI, 1					 ; point at the last byte
	lea	  EDI, pOutputBuffer

; reverse the string loop
_revLoop:
	std								 ; moving backwards for the input string
	lodsb
	cld								 ; moving forwards for the output string
	stosb
	loop  _revLoop

; display the number
_displayNumber:
	lea   EDX, pOutputBuffer
	mDispString EDX

; cleanup the stack
_cleanUp:
	pop   ESI
	pop   EBX
	pop   EAX
	pop   ECX
	pop   EDI
	ret   4

WriteVal ENDP

; ---------------------------------------------------------------------------------
; Name: ReadVal
;
; Uses the mGetString macro to get user input, checks that the user has only
; entered digits and checks the the number fits within an SDWORD, converts the string to an sdword
;and then it stores in the correct position of the array.
;
; Preconditions: ValidNumerCount offset has been pushed, numArray offset has been pushed, numPrompt offset has been pushed, 
; maximum # of characters user can enter has been pushed, errormessage offset for an invalid number entry has been pushed,
; the offset for the line number has been puhshed
;
; Postconditions: Array now contains the valid input
;
; Receives:
; [EBP +8]   = ValidNumberCount as an offset
; [EBP + 12] = numArray as an offset
; [EBP + 16] = numPrompt as an offset
; [EBP + 20] = maximum number of characters that a user can enter as a value
; [EBP + 24] = the offset for the invalid number error message
; [EBP + 28] = the offset for the line number
; [EBP + 32] = the offset for the tryAgain message
;
; returns: none
; ---------------------------------------------------------------------------------

ReadVal PROC	
; valnumCount offset(8 last pushed);numArray(12),numPromptOffset(16),MaxChar by value)(20),mInputBufferOffset(24), LineNumOffset(28), tryAgain(32 first pushed)

; declare local variablees
	LOCAL pSign:SDWORD 
	LOCAL pCharsRead:SDWORD 
	LOCAL pInputBuffer[20]:BYTE
	LOCAL pInputOffset:DWORD
	LOCAL pLineNumOffset:DWORD		; used for line counter
	LOCAL pLineDisp[2]:BYTE			; used to display the text ")"

;preserve registers	
	push  ECX						; will be used for string primitives later
	push  EDI						; the destination address for string primitives
	push  ESI						; the source address for string primitives
	push  EAX						; used in imul and mul
	push  EDX						; used to write the strings
	push  EBX						; operand for multiplication

; setup pLineDisp
	lea   EDI, pLineDisp
	mov   AL, 41					; 41 is ascii code for )
	stosb
	mov   AL, 0						; null terminator
	stosb
	
	mov   EBX,1
	mov   EDX, [EBP + 28]			; memory that that holds the current number of lines
	mov   pLineNumOffset, EDX
	
; move offset for pInputBuffer into pInputOffset
	lea   EDI, pInputBuffer
	mov   pInputOffset,EDI			

; 0 out the output buffer for the next number
_zeroFillTheBuffer:					; I could have used dup 0 and a data declaration oops
	mov   EAX, 0                    
	lea   EDI, pInputBuffer
	mov   ECX, 20                   
	rep   stosb
	lea   EDI, pInputBuffer

; get a number from the user
_getNum:
	mov   ESI, pLineNumOffset		; load line number offset
	mov   EBX, [ESI]
	push  EBX
	call  WriteVal
	lea   EBX, pLineDisp
	mDispString EBX
	lea	  EBX, pCharsRead			;cannot load into macro registers already used in macro
	mGetString [EBP +16], [EBP +20],pInputOffset,EBX 
	jmp   _getNumContinue

; Get another nunmber from the user if numbered entered is invalid
_getRetryNum:
	mov   ESI, pLineNumOffset
	mov   EBX, [ESI]
	push  EBX
	call  WriteVal
	lea   EBX, pLineDisp
	mDispString EBX
	lea	  EBX, pCharsRead
	mGetString [EBP +32], [EBP +20],pInputOffset,EBX ; we want a different error message after the first time! For bling


_getNumContinue:
	inc   DWORD PTR [ESI]			; increment the number in memory at ESI that is  DWORD
	lea   ESI, pInputBuffer
	lodsb							; load byte 

; check if the user entered a + or - sign
	cmp   AL, 43					; check that user entered positive sign
	je    _plusSign
	cmp   AL, 45					; check that user entered negative sign
	je    _negSign
	mov   ECX, pCharsRead
	mov   EBX, 1				     ; if no sign is entered then the number is positive
	mov   pSign, EBX
	lea   ESI, pInputBuffer
	jmp   _validationSetup

; what to do if there's a plus sign
_plusSign:
	mov   ECX, pCharsRead
	sub   ECX, 1					 ; 1 less time to do the loop since we already took off the sign, avoid removing the null terminating 0
	mov   EBX, 1
	  ; setup for integer storage operation
	mov   pSign, EBX
	jmp   _validationSetup

; what to do if there's a negative sign
_negSign:
	mov   ECX, pCharsRead
	sub   ECX,  1					 ; 1 less time to do the loop since we already took off the sign, avoid removing the null terminating 0
	mov   EBX, -1
	mov   pSign, EBX
	jmp   _validationSetup

_validationSetup:
	mov   EDX, 0					
	mov   EBX, 0					 ; holds value of numInt
	mov   EDI, 10

; check that the input was valid and fits with a 32 bit SDWORD
_validationLoop:
	lodsb							 ; load single byte from address pointed to by ESI and increment ESI
	cmp   AL,  48					 ; 48 is the decimal value for 0
	jb    _invalidNum
	cmp   AL,  57				   	 ; 57 is the ascii decimal value for 9
	ja    _invalidNum
	sub   AL,  48					 ; the lower level programming conversion, sub 48 aka 0
	movzx EDX, AL					 ; 0 extend AL and mov into EDX
	imul  EBX, 10
	jo    _invalidNum				 ; if an overflow occursion dring the number conversion the number is too big or too small!
	add   EBX, EDX
	loop  _validationLoop

; add the sign back onto the number
	mov   EDX,  EBX
	mov   EBX,  pSign				 ; multiplying by 1(positive) or -1(negative)
	imul  EDX, EBX					 
	mov   EBX, EDX
	jmp   _validNum

; if invalid number get another number!
_invalidNum:
	mDispString [EBP + 24]
	call  CrLf
	jmp   _getRetryNum				 

; the number entered was valid so store it
_validNum:
	mov   ESI,   [EBP + 8]			 ; num count by value
	mov   EBX,   TYPE SDWORD
	imul  EBX,   ESI				 ; generating the offset
	mov   EDI,   [EBP + 12]			 ; now holds the memory address of the array, the base
	add   EDI,   EBX				 ; adding offset to the base
	mov   [EDI], EDX				 ; edx holds the result num

; cleanup and fix stack pointer
	pop   EBX
	pop   EDX
	pop   EAX
	pop   ESI	
	pop   EDI
	pop   ECX
	ret   28

ReadVal ENDP

; ---------------------------------------------------------------------------------
; Name: NumArrayDisplay
;
; Uses the mDispString macro to display the title for the array.
; It then uses WriteVal to Write each number as a string to the display.
;
; Preconditions: ValidNumberCount offset has been pushed, numArray offset has been pushed, numArrayDisp offset has been pushed
;
; Postconditions: The number array has been written to the screen
;
; Receives:
; [EBP +8] = ValidNumberCount as an offset
; [EBP + 12] = numArray as an offset
; [EBP + 16] = numArrayDisp (the title) as an offset
;
; returns: none
; ---------------------------------------------------------------------------------
NumArrayDisplay Proc

; declare local variables 			; valnumCount offset(8 last pushed);numArray(12),numArrayDispOffset(16, first pushed)
	LOCAL pItemDisp[3]:BYTE			; used to display the text ", "
	LOCAL pCurrentNum:SDWORD		; the current number to be written, passed to WriteVal

;preserve registers
	push  EDI						; used to store address that sotres the text ", "
	push  ESI						; used as the source address to display the arrax
	push  EAX						; used to initialize pItemDisp
	push  ECX						; used as the counter for how many times to display a number
	push  EBX						; used to store offset that is past to mDispString

; setup pItemDisp
	lea   EDI, pItemDisp
	mov   AL, 44					; comma
	stosb
	mov   AL, 32					; space
	stosb
	mov   AL, 0						; null terminator
	stosb
	mDispString [EBP + 16]

; display array Setup
_dispArraySetup:
	mov   ECX, [EBP +8]				; initialize the counter
	mov   ESI, [EBP +12]			; the address of the array

; display the array
_dispArrayLoop:
	mov   EBX, [ESI]
	mov   pCurrentNum, EBX
	push  pCurrentNum
	call  WriteVal					; write the next 
	cmp   ECX, 1
	jz    _end						; we don't want a comma written after the last number!
	add   ESI, 4					; point to the next value
	lea   EBX, pItemDisp
	mDispString EBX
	loop  _dispArrayLoop

; line return
_end:
	call  CrLf
	call  CrLf

; clean up and restore registers
	pop   ECX
	pop   EAX
	pop   ESI
	pop   EDI
	ret   12

numArrayDisplay ENDP

; ---------------------------------------------------------------------------------
; Name: CalculateSumAndDisplay
;
; calculates the Sum of the numbers in the array, displays the title for the sum and 
; then writes the sum as a value using WriteVal
;
; Preconditions: ValidNumberCount offset has been pushed, numArray offset has been pushed, sumDisp offset has been pushed 
;
; Postconditions: The sum string and number have been written to the screen.
;
; Receives:
; [EBP +8] = ValidNumberCount as an offset ( the number of items in the array)
; [EBP + 12] = numArray as an offset
; [EBP + 16] = sumDisp (the title or string to be written) as an offset
;
; returns: none
; ---------------------------------------------------------------------------------

CalculateSumAndDisplay Proc

;declare local variables									; valnumCount offset(8);numArray(12),sumDispOffset(16)
	LOCAL pRunningSum:SDWORD		; used to store the sum of the numbers.

;preserve registers
	push  EDI						; used to initialize pRunningSum
	push  ESI						; used as the offset for the array
	push  EAX						; used to move 0  into pRunningSum
	push  ECX						; used as the counter for how many times to loop(based on the number of items in the array)

; initialize pRunningSum to 0
	lea   EDI, pRunningSum
	mov   EAX, 0
	mov   [EDI],EAX					

; write the result string text to the screen
_dispResultText:
	mDispString [EBP + 16]
	mov   ECX, [EBP +8]
	mov   ESI, [EBP +12] 
	mov   EAX, pRunningSum

; calculate the sum
_calcTotal:
	add   EAX, [ESI]
	add   ESI, 4
	loop _calcTotal

;display the total
_displayTotal:
	mov   pRunningSum, EAX
	push  pRunningSum
	call  WriteVal
	call  CrLf

; restore registers and cleanup
	pop   ECX
	pop   EAX
	pop   ESI
	pop   EDI
	ret   12
CalculateSumAndDisplay ENDP

; ---------------------------------------------------------------------------------
; Name: CalculateAverageAndDisplay
;
; calculates the Sum of the numbers in the array,divides by the number of items in the array to get the average
; displays the title for the truncated  average and then writes the average as a value using WriteVal
;
; Preconditions: ValidNumberCount offset has been pushed, numArray offset has been pushed, sumDisp offset has been pushed 
;
; Postconditions: the average string and the average have been written to the screen
;
; Receives:
; [EBP +8] = ValidNumberCount as an offset ( the number of items in the array)
; [EBP + 12] = numArray as an offset
; [EBP + 16] = averageDisp (the title or string to be written) as an offset
;
; returns: none
; ---------------------------------------------------------------------------------

CalcAverageAndDisplay  Proc

;declare local variables
	LOCAL pSum:SDWORD				; stores the sum of all the numbers in the array
	LOCAL pAverage:SDWORD			; stores the average of the all the numbers in the array

;preserve registers
	push  EDI						; the memory offset for the destination address
	push  ESI						; holds the address for the current item in the array
	push  EAX						; used to store the sum and for the quotient in division
	push  ECX						; the number of times to sum the valid based on the number of items in the array

; initialize pSum to 0
	lea   EDI, pSum			
	mov   EAX, 0
	mov   [EDI],EAX					\

; display the title for the average
_dispAverageText:
	mDispString [EBP + 16]			
	mov   ECX, [EBP +8]
	mov   ESI, [EBP +12] 
	mov   EAX, pSum
	
; get the total for the items in the array
_calcTotal:
	add   EAX, [ESI]
	add   ESI, 4
	loop  _calcTotal
	mov   pSum, EAX

;calculate the average
_calcAverage:
	mov   EBX, [EBP + 8]			; get the number of items in the array
	mov   EAX, pSum			
	cdq
	idiv  EBX					    ; divide sum of the numbers in the array by the number of items
	mov   pAverage, EAX				; store result
	
; write the average
	push  pAverage
	call  WriteVal					
	call  CrLf

; cleanup an restore registers
	pop   ECX
	pop   EAX
	pop   ESI
	pop   EDI
	ret   12
CalcAverageAndDisplay  ENDP

END main
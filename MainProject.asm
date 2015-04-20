#Special thanks to Jared for the awesome graphics wrapper.

#Screen size: 96 x 26

.data
	failureCount:		.byte 10
	matchCount:		.byte 0
	letterState:		.word 0x03FFFFFF #bits 25-0 where 1 is visible
	wordAddress:		.word word_0		#memory location of the correct word
	keyboardBuffer:		.asciiz " "
	wordBuffer:		.asciiz "\0\0\0\0\0\0\0\0\0\0\0"
	debug_win:		.asciiz "win-press enter to play again"
	debug_lose:		.asciiz "lose-press enter to play again"
	txt_bound:		.asciiz	"                                                                                                " #PLEASE update these spaces to reflect the screen width!!
	
	word_0:			.asciiz	"COMPUTER"
	word_1:			.asciiz	"SCIENCE"
	word_2:			.asciiz	"PROCESSOR"
	word_3:			.asciiz	"INSTRUCTION"
	word_4:			.asciiz	"DATAPATH"
	word_5:			.asciiz	"BUFFER"
	word_6:			.asciiz	"BYTE"
	word_7:			.asciiz	"COFFEE"
	word_8:			.asciiz	"PIZZA"
	word_9:			.asciiz	"SUSHI"
	word_10:		.asciiz	"TRANCE"
	word_11:		.asciiz	"FORTYTWO"
	word_12:		.asciiz	"APPLE"
	word_13:		.asciiz	"MICROSOFT"
	word_14:		.asciiz	"BIRD"
	wordList:		.word	word_0,word_1,word_2,word_3,word_4,word_5,word_6,word_7,word_8,word_9,word_10,word_11,word_12,word_13,word_14
	wordListLength:		.word	15 #number of words + 1
	
	msg_title_welcome:	.asciiz	"Welcome to HangMIPS!"
	msg_title_project:	.asciiz	"UTD 2015 Computer Architecture Project"
	msg_title_credit1:	.asciiz	"Luke Escude"
	msg_title_credit2:	.asciiz	"Jared Hull"
	msg_title_credit3:	.asciiz	"Jeff Imam"
	msg_title_credit4:	.asciiz	"Chase Vriezema"
	msg_game_title:		.asciiz	"HangMIPS"
	msg_title_line1:	.asciiz	"                  _    _                       __  __  _____  _____    _____ "
	msg_title_line2:	.asciiz	"                 | |  | |                     |  \\/  ||_   _||  __ \\  / ____|" #62
	msg_title_line3:	.asciiz	"                 | |__| |  __ _  _ __    __ _ | \\  / |  | |  | |__) || (___  "
	msg_title_line4:	.asciiz	"                 |  __  | / _` || '_ \\  / _` || |\\/| |  | |  |  ___/  \\___ \\ "
	msg_title_line5:	.asciiz	"                 | |  | || (_| || | | || (_| || |  | | _| |_ | |      ____) |"
	msg_title_line6:	.asciiz	"                 |_|  |_| \\__,_||_| |_| \\__, ||_|  |_||_____||_|     |_____/ "
	msg_title_line7:	.asciiz	"                                         __/ |                              "
	msg_title_line8:	.asciiz	"                                        |___/                                "
	
#keyboard trap
.ktext 0x80000180
	#clear the interrupt bit
	lw $t0 , 0xFFFF0000
	andi $t0, 0xFFFFFFFD
	sw $t0, 0xFFFF0000
   
	# Coprocessor 0 register $14 has address of trapping instruction
	mfc0 $k0,$14
	# Add 8 to skip return to the next 2 functions
	addi $k0,$k0,4
	# Store new address back into $14
	mtc0 $k0,$14
	# Error return; set PC to value in $14
	eret
		
.text
MainLoop:
	jal DrawMainMenu
	
	#Main menu is drawn, wait for input:
	menuLoop:
		#set interrupt flag to wait for input
		lw $t0 , 0xFFFF0000
		ori $t0, 2
		sw $t0, 0xFFFF0000
		#infinite loop
		ml_WaitLoop:
		b ml_WaitLoop
		
		#if enter is pressed, start the game
		lb $t0, 0xffff0004
		bne $t0, 10, dontStart
		j startGame
		dontStart:
		j menuLoop
	startGame:
	jal gfx_clearScreen
	jal engine_initializeBank
	
	#Game play: get our word:
	jal getRandWord
	
	#display the word (for debugging)
	lw $a0, wordAddress
	li $a1, 0
	li $a2, 1
	li $a3, 0x20
	jal gfx_drawString
	
	gameLoop:
		#set interrupt flag to wait for input
		lw $t0 , 0xFFFF0000
		ori $t0, 2
		sw $t0, 0xFFFF0000
		#infinite loop
		gl_WaitLoop:
		b gl_WaitLoop
		
		#get input	
		lb $t0, 0xffff0004
		#if enter pressed
		bne $t0, 10, notEnter
		
		#check the letter that was input previously
		lb $a0, keyboardBuffer
		jal engine_checkLetter
		j gameLoop
		notEnter:
		
		#convert to uppercase
		bgt $t0, 0x7A, notLower
		blt $t0, 0x61, notLower
		sub $t0, $t0, 0x20
		notLower:
		
		#save to our buffer
		sb $t0, keyboardBuffer	
	j gameLoop
	
	j ExitProgram
DrawMainMenu:
	#This is our main menu. Display: HangMIPS in ASCII art, then by: our names, and menu: 1) Play 2) Quit
	# $a0 =string,  $a1=x $a2=y $a3=color
	subi $sp, $sp, 4
	move $sp, $ra
	
	#li $t0, 0x0002601A #Set screen size to 96x26
	#sw $t0, 0xFFFF000C
	li $a0,96
	li $a1,27
	jal gfx_resizeScreen
	#Load title message
		la $a0, msg_title_line1
		li $a1, 1
		li $a2, 1
		li $a3, 0x60
		jal gfx_drawString
		la $a0, msg_title_line2
		li $a1, 1
		li $a2, 2
		li $a3, 0x60
		jal gfx_drawString
		la $a0, msg_title_line3
		li $a1, 1
		li $a2, 3
		li $a3, 0x50
		jal gfx_drawString
		la $a0, msg_title_line4
		li $a1, 1
		li $a2, 4
		li $a3, 0x50
		jal gfx_drawString
		la $a0, msg_title_line5
		li $a1, 1
		li $a2, 5
		li $a3, 0x40
		jal gfx_drawString
		la $a0, msg_title_line6
		li $a1, 1
		li $a2, 6
		li $a3, 0x40
		jal gfx_drawString
		la $a0, msg_title_line7
		li $a1, 1
		li $a2, 7
		li $a3, 0x40
		jal gfx_drawString
		la $a0, msg_title_line8
		li $a1, 1
		li $a2, 8
		li $a3, 0x40
		jal gfx_drawString
	#project string
	la $a0, msg_title_project
	li $a1, 28
	li $a2, 25
	li $a3, 0x20
	jal gfx_drawString
	#Creditstring
	la $a0, msg_title_credit1
	li $a1, 42
	li $a2, 10
	li $a3, 0xA0
	jal gfx_drawString
	#Creditstring
	la $a0, msg_title_credit2
	li $a1, 42
	li $a2, 11
	li $a3, 0xA0
	jal gfx_drawString
	#Creditstring
	la $a0, msg_title_credit3
	li $a1, 43
	li $a2, 12
	li $a3, 0xA0
	jal gfx_drawString
	#Creditstring
	la $a0, msg_title_credit4
	li $a1, 41
	li $a2, 13
	li $a3, 0xA0
	jal gfx_drawString
	#BORDER !!!
		li $a0, 0xC9	#Up Left corner
		li $a1, 0
		li $a2, 0
		li $a3, 0xB0
		jal gfx_drawChar
		li $a0, 0xBB	#Up Right corner
		li $a1, 95	#Compensate for cut-off
		li $a2, 0
		li $a3, 0xB0
		jal gfx_drawChar
		li $a0, 0xC8	#Low Left corner
		li $a1, 0
		li $a2, 26
		li $a3, 0xB0
		jal gfx_drawChar
		li $a0, 0xBC	#Low Right corner
		li $a1, 95
		li $a2, 26
		li $a3, 0xB0
		jal gfx_drawChar
			#Draw Upper/Lower borders:
			li $s0,95	#Stop at character 95
			li $s1,1	#Start at character 1
			brd_upperLoop:
				beq $s1, $s0, brd_end
				li $t0, 0xCD	#Pipe character (UPPER BORDER)
				li $t2, 0
				li $t3, 0xB0
				sb $t3, 0xffff000c #Col
				sb $t2, 0xffff000d #Y
				sb $s1, 0xffff000e #X
				sb $t0, 0xffff000f #Char
				li $t0, 0xCD	#Pipe character (LOWER BORDER)
				li $t2, 26
				li $t3, 0xB0
				sb $t3, 0xffff000c #Col
				sb $t2, 0xffff000d #Y
				sb $s1, 0xffff000e #X
				sb $t0, 0xffff000f #Char
				addi $s1, $s1, 1
				j brd_upperLoop
			brd_end:
			#Draw left/right borders:
			li $s0,26	#Stop at character 25
			li $s1,1	#Start at character 1
			brd_leftLoop:
				beq $s1, $s0, brd_end2
				li $t0, 0xBA	#Pipe character (LEFT BORDER)
				li $t2, 0
				li $t3, 0xB0 #B0
				sb $t3, 0xffff000c #Col
				sb $s1, 0xffff000d #Y
				sb $t2, 0xffff000e #X
				sb $t0, 0xffff000f #Char
				li $t0, 0xBA	#Pipe character (RIGHT BORDER)
				li $t1, 95
				li $t3, 0xB0
				sb $t3, 0xffff000c #Col
				sb $s1, 0xffff000d #Y
				sb $t1, 0xffff000e #X
				sb $t0, 0xffff000f #Char
				addi $s1, $s1, 1
				j brd_leftLoop
			brd_end2:
			#CONTINUE menu stuff...
			
	
	move $ra, $sp
	addi $sp, $sp, 4
	jr $ra #return to main loop
getRandWord:
	move $t0, $zero #index is 0 for now
	la $t1, wordList # load array
	
	#generate random
	li $a0, 2
	li $a1, 15
	li $v0, 42
	syscall
	move $t0, $a0 #new random index
	sll $t0, $t0, 2 #index=index*4
	addu $t0, $t1, $t0
	
	#store the address of our random word in wordAddress
	lw $t0, ($t0)
	sw $t0, wordAddress
	
	#initialise the wordBuffer
	move $s0, $zero	#offset counter
	lw $s1, wordAddress
	la $s2, wordBuffer
	loopBuffer:
		add $t0, $s0, $s1
		lb $t0, ($t0)
		
		#check for null terminator
		beqz $t0, endBuffer
		
		#set the blank_ in the wordBuffer
		add $t1, $s2, $s0
		li $t2, 0x5F
		sb $t2, ($t1)
		
		#increment the word offset
		addi $s0, $s0, 1
	j loopBuffer
	endBuffer:
	
	subi $sp, $sp, 4
	move $sp, $ra
	
	#draw the wordBuffer to screen
	la $a0, wordBuffer
	li $a1, 0
	li $a2, 2
	li $a3, 0x20
	jal gfx_drawString
	
	move $ra, $sp
	addi $sp, $sp, 4
	jr $ra
	
gfx_drawString:	# $a0 contains the starting address of string $a1x $a2=y $a3=color
	#set color 0xFB foreground/background
	sb $a3, 0xffff000c
	#set Y
	sb $a2, 0xffff000d
	
	stringLoop:
	#set X
	sb $a1, 0xffff000e
	#set character
	lb $t0, 0($a0)
	sb $t0, 0xffff000f
	
	#increment x
	addi $a1, $a1, 1
	#increment the string offset
	addi $a0, $a0, 1
	
	lb $t0, ($a0)
	bnez $t0 stringLoop
	jr $ra
	
gfx_drawChar:	# $a0 = character WORD value $a1x $a2=y $a3=color
	#set color 0xFB foreground/background
	sb $a3, 0xffff000c
	#set Y
	sb $a2, 0xffff000d
	#set X
	sb $a1, 0xffff000e
	#set character
	#lb $t0, 0($a0)
	sb $a0, 0xffff000f
	jr $ra
	
gfx_resizeScreen:
	lui $t0 , 0x0002
	andi $a0 , 0x0FF
	sll $a0, $a0, 8
	andi $a1 , 0x0FF
	addu $t0, $t0, $a0
	addu $t0, $t0, $a1
	sw $t0 , 0xFFFF000C
	rs_WaitLoop:
		lw $t0 , 0xFFFF0008
		bnez $t0 , rs_WaitLoopDone
		b rs_WaitLoop
		rs_WaitLoopDone:
	jr $ra
	
gfx_clearScreen:
	li $t0, 0x00010000
	sw $t0, 0xFFFF000C
	cs_WaitLoop:
		lw $t0 , 0xFFFF0008
		bnez $t0 , cs_WaitLoopDone
		b rs_WaitLoop
		cs_WaitLoopDone:
	jr $ra
	
engine_initializeBank:
	subi $sp, $sp, 4
	move $sp, $ra
	
	#reset letterState
	li $t0, 0x03FFFFFF
	sw $t0, letterState
	
	#start with A and update each letter in the bank
	li $s0, 0x41
	loop_iB:
	move $a0, $s0
	li $a1, 0xF0
	jal engine_updateBank
	addi $s0, $s0, 1
	blt $s0, 0x5B, loop_iB
	
	move $ra, $sp
	addi $sp, $sp, 4
	jr $ra
	
engine_updateBank:	# $a0=ascii letter $a1=color(0-F)
	#set color 0xFB foreground/background
	sb $a1, 0xffff000c
	#set Y to 0
	move $t0, $zero
	sb $t0, 0xffff000d
	#set X
	move $t0, $zero
	subi $t0, $a0, 0x41
	sb $t0, 0xffff000e
	#set character
	sb $a0, 0xffff000f
	jr $ra
engine_checkLetter:	#$a0=letter
	subi $sp, $sp, 4
	move $sp, $ra
	sub $a0, $a0, 0x41
	#check the status of the letter
	lw $t0, letterState
	li $t1, 31
	sub $t1, $t1, $a0
	sllv $t0, $t0, $t1
	srl $t0, $t0, 31
	#if letter already checked
	bnez $t0, notChecked
	jr $ra
	
	notChecked:
	#set the bit in usedLetters to 0
	lw $t0, letterState
	li $t1, 1
	sllv $t1, $t1, $a0
	not $t1, $t1
	and $t0, $t0, $t1
	sw $t0, letterState
	
	#remove the letter from the bank
	add $a0, $a0, 0x41
	#set the color to match the background
	li $a1, 0x00
	jal engine_updateBank
	
	#search the word for any matching letters
	move $s0, $zero	#offset counter
	lw $s1, wordAddress
	la $s2, wordBuffer
	move $s3, $zero #match counter
	loopWord:
		add $t0, $s0, $s1
		lb $t0, ($t0)
		
		#check for null terminator
		beqz $t0, endWord
		
		#check current character for a match
		bne $a0, $t0, notMatch
		
		#set the letter in the wordBuffer
		add $t1, $s2, $s0
		sb $a0, ($t1)
		
		#increment the match counter
		addi $s3, $s3, 1
		
		notMatch:
		#increment the word offset
		addi $s0, $s0, 1
	j loopWord
	endWord:
	
	#check for win
	lb $t0, matchCount
	add $t0, $t0, $s3
	bne $t0, $s0, notWin
	move $ra, $sp
	addi $sp, $sp, 4
	j win
	notWin:
	#update matchCount
	sb $t0, matchCount
	
	#check if no matches were made
	bnez $s3, skipPunishment
	move $ra, $sp
	addi $sp, $sp, 4
	
	#check for complete failure
	lb $t0, failureCount
	bne $t0, 1, notLose
	j lose
	notLose:
	
	#decrement failures
	subi $t0, $t0, 1
	sb $t0, failureCount
	jr $ra
	skipPunishment:
	
	#redraw the wordBuffer on the screen
	la $a0, wordBuffer
	li $a1, 0
	li $a2, 2
	li $a3, 0x20
	jal gfx_drawString
	
	move $ra, $sp
	addi $sp, $sp, 4
	jr $ra
lose:
	jal gfx_clearScreen
	la $a0, debug_lose
	li $a1, 0
	li $a2, 0
	li $a3, 0xF0
	jal gfx_drawString
	
	#set interrupt flag to wait for input
	lw $t0 , 0xFFFF0000
	ori $t0, 2
	sw $t0, 0xFFFF0000
	#infinite loop
	lose_WaitLoop:
	b lose_WaitLoop
	
	j resetGame
	
win:
	jal gfx_clearScreen
	la $a0, debug_win
	li $a1, 0
	li $a2, 0
	li $a3, 0xF0
	jal gfx_drawString
	
	#set interrupt flag to wait for input
	lw $t0 , 0xFFFF0000
	ori $t0, 2
	sw $t0, 0xFFFF0000
	#infinite loop
	win_WaitLoop:
	b win_WaitLoop
	
	j resetGame
	
resetGame:
	li $t0, 10
	sb $t0, failureCount
	sb $zero, matchCount
	
	li $t0, 0x03FFFFFF
	sw $t0, letterState
	
	move $t0, $zero	#offset counter
	la $t1, wordBuffer
	clearBufferLoop:
		beq $t0, 10, endBL
		
		#null the wordBuffer
		add $t2, $t1, $t0
		sb $zero, ($t2)
		
		#increment the word offset
		addi $t0, $t0, 1
	j clearBufferLoop
	endBL:
	
	j startGame
ExitProgram:

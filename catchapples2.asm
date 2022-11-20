.eqv WIDTH 32
.eqv HEIGHT 32

#hex codes for all colors
.eqv RED 0x00FF0000
.eqv BROWN 0xA1785C00
.eqv BLUE  0x00089CFF
.eqv WHITE 0xFFFFFFFF
.eqv SKY 0x00D8F2FF
.eqv TREE 0x79564400
.eqv GREEN 0x00358856

#---------# MACRO DEFINITIONS #---------#

.macro check_key_press
	lw $t9, 0xffff0000
	bne $t9, $0, process_input
.end_macro

#--------------------------------------#
.text

main:
	#counts number of apples drawn
	li $t2, 0	
	
	#tracks score of apples caught
	li $t3, 0	
	
	#tracks number of apples that hit the floor
	li $t5, 0	
	
	j draw_background

	#draw basket in brown
	addi $a2, $0, BROWN
	j draw_basket

exit:
	li $v0, 10
	syscall
	
#---------------- BASKET MOVEMENT ---------------#

process_input:

	#branch to correct movement depending on key pressed
	lw $t8, 0xffff0004	
	beq $t8, 100, move_right
	beq $t8, 97, move_left
	#beq $t8, 115, move_down
	#beq $t8, 119, move_up

move_up:
	li $s2, 0
	jal draw_pixel
	addi $s1, $s1, -1
	addi $s2, $s2, BROWN
	jal draw_pixel
	j return

move_down:
	li $s2, 0
	jal draw_pixel
	addi $s1, $s1, 1
	addi $s2, $s2, BROWN
	jal draw_pixel
	j return

#move basket to the right
move_right:
	#erase current pixel
        addi $s0, $s3, 0
	addi $s1, $s4, 0
	addi $s2, $0, SKY
	jal draw_pixel
	
	#draw new basket
	addi $s0, $s0, 1
	addi $s2, $s2, BROWN
	jal draw_pixel
	
	addi $s3, $s0, 0
	addi $s4, $s1, 0
	j return
	
#move basket to left
move_left:
        addi $s0, $s3, 0
	addi $s1, $s4, 0
	addi $s2, $0, SKY
	jal draw_pixel
	
	addi $s0, $s0, -1
	addi $s2, $s2, BROWN
	jal draw_pixel
	
	addi $s3, $s0, 0
	addi $s4, $s1, 0
	j return
	
############## FALLING APPLES FUNCTIONS ############
	
draw_apples:
	#generate a random number for x value of apple
	li $a1, 29	
	li $v0, 42	#random number stored in $a0
	syscall
	
	#store generated x val in $t7
	addi $t7, $a0, 0
	
	#draw apple
	addi $s0, $a0, 0 
	addi $s2, $0, RED
	li $s1, 6	
	jal draw_pixel
	
	#animating apple falling	
	jal fall_apple	
	
#animation for apple falling
fall_apple:
	
	# t6 = initial height, t4 = ground
	li $t6, 6
	li $t4, 30
	
	fall_loop:
		#delay each movement by 110 ms
		li $a0, 110 
		li $v0, 32
		syscall
		
		#black out current pixel
		addi $s2, $0, SKY	
		jal draw_pixel
		
		#check if next pixel is the basket
		beq $s1, 29, detect_basket
		return_detection:
		
		#check if apple has hit the floor
		beq $s1, 30, lost_apple
		return_detect_apple: 
		
		#move pixel down by 1
		addi $s1, $s1, 1	
		addi $s2, $0, RED
		jal draw_pixel
		addi $t6, $t6, 1	#track y value
		
		#check for user input 
		lw $t9, 0xffff0000
		beq $t9, $0, fall_loop
		j process_input
		
		#come back to this point after processing input
		return: 
		addi $s0, $t7, 0
		addi $s1, $t6, 0
		
		#if apple has not reached ground, loop animation again
		blt $t6, $t4, fall_loop
		j draw_apples
		
#detect whether the apple has hit the basket
detect_basket: 

	#taking current value of basket, and current x value of apple, see if they are equal
	beq $s3, $s0, add_score
	j return_detection
	
#triggered if apple has hit the floor
lost_apple:

	#t5 tracks how many apples have hit floor
	addi $t5, $t5, 1
	
	#black out pixel
	addi $s2, $0, SKY
	addi $s0, $s0, 0
	addi $s1, $s1, 0
	jal draw_pixel
	
	#if 5 apples have hit floor, game over
	beq $t5, 5, game_lost
	j draw_apples
	
#if apple hits basket, increments running score total
add_score:

	#black out pixel
	addi $s2, $0, SKY
	addi $s0, $s0, 0
	addi $s1, $s1, 0
	jal draw_pixel
	
	#track how many apples have been caught, and check if 3 have been caught
	li $t7, 3
	addi $t3, $t3, 1
	beq $t3, 1, first_score
	beq $t3, 2, second_score
	beq $t3, 3, third_score
	return_score:
	beq $t3, $t7, game_won
	j draw_apples
	
#display apple on tree to keep score
first_score:
	li $s0, 28
	li $s1, 3
	addi $s2, $0, RED
	jal draw_pixel
	j return_score
	
#display another apple on tree
second_score:
	li $s0, 26
	li $s1, 2
	addi $s2, $0, RED
	jal draw_pixel
	j return_score
	
#display third apple
third_score:
	li $s0, 23
	li $s1, 1
	addi $s2, $0, RED
	jal draw_pixel
	j return_score

#------# Drawing Functions #-------#
	
draw_basket:
	
	li $s0, 2
	li $s1, 30
	#stores the x-val of basket at current time in s3
	addi $s3, $s0, 0 
	#stores the y-val of basket in s4
	addi $s4, $s1, 0
	addi $s2, $0, BROWN
	jal draw_pixel
	j draw_apples

draw_pixel:
	mul $t9, $s1, WIDTH
	add $t9, $t9, $s0
	mul $t9, $t9, 4
	add $t9, $t9, $gp
	sw $s2, ($t9)
	jr $ra
	
#make background color light blue / sky
draw_background:
	addi $s2, $0, SKY
	li $s0, 0
	li $s1, 0
	
	bg_loop:
		beq $s0, 32, next_bg
		jal draw_pixel
		addi $s0, $s0, 1
		j bg_loop
	
	#move to next row 
	next_bg:
		addi $s1, $s1, 1
		bgt $s1, 31, draw_tree
		li $s0, 0
		j bg_loop
	
	#draw trunk of tree in brown
	draw_tree:
		li $t1, 0
		addi $s2, $0, TREE
		li $s0, 31
		li $s1, 0
		tree_loop:
			beq $s1, 31, second_col
			jal draw_pixel
			addi $s1, $s1, 1
			j tree_loop
			
		#draw second column of tree trunk
		second_col:
			beq $t1, 1, draw_leaves
			addi $t1, $t1, 1
			li $s0, 30
			li $s1, 0
			j tree_loop
	
	#draw leaves on tree
	draw_leaves:
		li $s0, 30
		li $s1, 0
		addi $s2, $0, GREEN
		jal draw_pixel
		
		li $s0, 31
		jal draw_pixel
		
		addi $s1, $s1, 1
		jal draw_pixel
		
		addi $s1, $s1, 1
		jal draw_pixel
		
		addi $s0, $s0, -1
		jal draw_pixel
		
		li $s0, 30
		li $s1, 1
		jal draw_pixel
		
		li $s0, 22
		li $s1, 0
		jal draw_pixel
		
		addi $s0, $s0, 1
		jal draw_pixel
		
		addi $s0, $s0, 1
		jal draw_pixel
		
		addi $s0, $s0, 1
		jal draw_pixel
		
		addi $s0, $s0, 1
		jal draw_pixel
		
		addi $s0, $s0, 1
		jal draw_pixel
		
		addi $s0, $s0, 1
		jal draw_pixel
		
		addi $s0, $s0, 1
		jal draw_pixel
		
		li $s0, 22
		li $s1, 1
		jal draw_pixel
		
		addi $s0, $s0, 1
		jal draw_pixel
		
		addi $s0, $s0, 1
		jal draw_pixel
		
		addi $s0, $s0, 1
		jal draw_pixel
		
		addi $s0, $s0, 1
		jal draw_pixel
		
		addi $s0, $s0, 1
		jal draw_pixel
		
		addi $s0, $s0, 1
		jal draw_pixel
		
		addi $s0, $s0, 1
		jal draw_pixel
		
		li $s0, 22
		li $s1, 2
		jal draw_pixel
		
		addi $s0, $s0, 1
		jal draw_pixel
		
		addi $s0, $s0, 1
		jal draw_pixel
		
		addi $s0, $s0, 1
		jal draw_pixel
		
		addi $s0, $s0, 1
		jal draw_pixel
		
		addi $s0, $s0, 1
		jal draw_pixel
		
		addi $s0, $s0, 1
		jal draw_pixel
		
		addi $s0, $s0, 1
		jal draw_pixel
		
		li $s0, 25
		li $s1, 3
		jal draw_pixel
		
		addi $s0, $s0, 1
		jal draw_pixel
		
		addi $s0, $s0, 1
		jal draw_pixel
		
		addi $s0, $s0, 1
		jal draw_pixel
		
		addi $s0, $s0, 1
		jal draw_pixel
		
		addi $s0, $s0, 1
		jal draw_pixel
		
		addi $s0, $s0, 1
		jal draw_pixel
		
		li $s0, 27
		li $s1, 4
		jal draw_pixel
		
		addi $s0, $s0, 1
		jal draw_pixel
		
		addi $s0, $s0, 1
		jal draw_pixel
		
		addi $s0, $s0 ,1
		jal draw_pixel
		
		addi $s0, $s0, 1
		jal draw_pixel
		j draw_grass
	
	#grass
	draw_grass:
		#set coordinates to bottom left
		li $s0, 0
		li $s1, 31
		addi $s2, $0, GREEN
		jal draw_pixel
		
		grass_loop:
			#if row is finished, start drawing cloud
			beq $s0, 32, draw_cloud
			addi $s0, $s0, 1
			jal draw_pixel
			j grass_loop
		
	
	#draw a cloud!
	draw_cloud:
		addi $s2, $0, WHITE
		li $s0, 6
		li $s1, 3
		jal draw_pixel
		
		addi $s0, $s0, 1
		jal draw_pixel
		
		addi $s0, $s0, 1
		jal draw_pixel
		
		addi $s0, $s0, 1
		jal draw_pixel
		
		addi $s0, $s0, 1
		jal draw_pixel
		
		addi $s0, $s0, 1
		jal draw_pixel
		
		addi $s0, $s0, 1
		jal draw_pixel
		
		li $s0, 7
		li $s1, 2
		jal draw_pixel
		
		addi $s0, $s0, 1
		jal draw_pixel
		
		addi $s0, $s0, 1
		jal draw_pixel
		
		addi $s0, $s0, 1
		jal draw_pixel
		
		addi $s0, $s0, 1
		jal draw_pixel
		
		li $s0, 8
		li $s1, 1
		jal draw_pixel
		
		addi $s0, $s0, 1
		jal draw_pixel
		
		addi $s0, $s0, 1
		jal draw_pixel
		
		#now can start game
		j draw_basket
		
#display 'you won' message
game_won:
	
	#pause game to see third apple!
	li $a0, 110
	li $v0, 32
	syscall
	
	li $t1, 0
	addi $s2, $s2, WHITE
	li $s0, 0
	li $s1, 0
	jal draw_pixel
	
	#start wiping out the board in white
	clear_board_loop:
		beq $s0, 32, next_row
		jal draw_pixel
		addi $t1, $t1, 1 
		addi $s0, $s0, 1
		j clear_board_loop
	
	#move on to next row
	next_row:
		addi $s1, $s1, 1
		bgt $s1, 31, draw_y
		li $s0, 0
		j clear_board_loop
	
	# 'you won' msg display
	draw_y:
		addi $s2, $0, BLUE
		li $s0, 4
		li $s1, 5
		jal draw_pixel
		addi $s0, $s0, 1
		addi $s1, $s1, 1
		jal draw_pixel
		addi $s0, $s0, 1
		addi $s1, $s1, 1
		jal draw_pixel
		addi $s1, $s1, 1
		jal draw_pixel
		addi $s1, $s1, 1
		jal draw_pixel
		addi $s1, $s1, 1
		jal draw_pixel
		addi $s0, $s0, 1
		addi $s1, $s1, -4
		jal draw_pixel
		addi $s0, $s0, 1
		addi $s1, $s1, -1
		jal draw_pixel
		li $t1, 10
		li $t2, 5
		j draw_o
	
	#draw o
	draw_o:
		move $s0, $t1
		move $s1, $t2
		jal draw_pixel
		addi $s0, $s0, 1
		jal draw_pixel
		addi $s0, $s0, 1
		jal draw_pixel
		addi $s0, $s0, 1
		jal draw_pixel
		move $s0, $t1
		addi $s1, $s1, 1
		jal draw_pixel
		addi $s1, $s1, 1
		jal draw_pixel
		addi $s1, $s1, 1
		jal draw_pixel
		addi $s1, $s1, 1
		jal draw_pixel
		addi $s1, $s1, 1
		jal draw_pixel
		addi $s0, $s0, 1
		jal draw_pixel
		addi $s0, $s0, 1
		jal draw_pixel
		addi $s0, $s0, 1
		jal draw_pixel
		addi $s1, $s1, -1
		jal draw_pixel
		addi $s1, $s1, -1
		jal draw_pixel
		addi $s1, $s1, -1
		jal draw_pixel
		addi $s1, $s1, -1
		jal draw_pixel
		j draw_u
	
	draw_u:
		li $s0, 15
		li $s1, 5
		jal draw_pixel
		addi $s1, $s1, 1
		jal draw_pixel
		addi $s1, $s1, 1
		jal draw_pixel
		addi $s1, $s1, 1
		jal draw_pixel
		addi $s1, $s1, 1
		jal draw_pixel
		addi $s1, $s1, 1
		jal draw_pixel
		addi $s0, $s0, 1
		jal draw_pixel
		addi $s0, $s0, 1
		jal draw_pixel
		addi $s0, $s0, 1
		jal draw_pixel
		addi $s1, $s1, -1
		jal draw_pixel
		addi $s1, $s1, -1
		jal draw_pixel
		addi $s1, $s1, -1
		jal draw_pixel
		addi $s1, $s1, -1
		jal draw_pixel
		addi $s1, $s1, -1
		jal draw_pixel
		j draw_w
		
	draw_w:
		li $s1, 15
		li $s0, 4
		jal draw_pixel
		addi $s1, $s1, 1
		jal draw_pixel
		addi $s1, $s1, 1
		jal draw_pixel
		addi $s1, $s1, 1
		jal draw_pixel
		addi $s1, $s1, 1
		jal draw_pixel
		addi $s1, $s1, 1
		addi $s0, $s0, 1
		jal draw_pixel
		addi $s1, $s1, -1
		addi $s0, $s0, 1
		jal draw_pixel
		addi $s1, $s1, -1
		jal draw_pixel
		addi $s1, $s1,-1
		jal draw_pixel
		addi $s1, $s1, -1
		jal draw_pixel
		addi $s1, $s1, -1
		jal draw_pixel
		li $s1, 20
		addi $s0, $s0, 1
		jal draw_pixel
		addi $s0, $s0, 1
		addi $s1, $s1, -1
		jal draw_pixel
		addi $s1, $s1, -1
		jal draw_pixel
		addi $s1, $s1, -1
		jal draw_pixel
		addi $s1, $s1, -1
		jal draw_pixel
		addi $s1, $s1, -1
		jal draw_pixel
		li $t1, 10
		li $t2, 15
		j draw_o_2
	
	draw_o_2:
		move $s0, $t1
		move $s1, $t2
		jal draw_pixel
		addi $s0, $s0, 1
		jal draw_pixel
		addi $s0, $s0, 1
		jal draw_pixel
		addi $s0, $s0, 1
		jal draw_pixel
		move $s0, $t1
		addi $s1, $s1, 1
		jal draw_pixel
		addi $s1, $s1, 1
		jal draw_pixel
		addi $s1, $s1, 1
		jal draw_pixel
		addi $s1, $s1, 1
		jal draw_pixel
		addi $s1, $s1, 1
		jal draw_pixel
		addi $s0, $s0, 1
		jal draw_pixel
		addi $s0, $s0, 1
		jal draw_pixel
		addi $s0, $s0, 1
		jal draw_pixel
		addi $s1, $s1, -1
		jal draw_pixel
		addi $s1, $s1, -1
		jal draw_pixel
		addi $s1, $s1, -1
		jal draw_pixel
		addi $s1, $s1, -1
		jal draw_pixel
		j draw_n
	
	draw_n:
		li $s0, 15
		li $s1, 15
		jal draw_pixel
		addi $s1, $s1, 1
		jal draw_pixel
		addi $s1, $s1, 1
		jal draw_pixel
		addi $s1, $s1, 1
		jal draw_pixel
		addi $s1, $s1, 1
		jal draw_pixel
		addi $s1, $s1, 1
		jal draw_pixel
		li $s0, 16
		li $s1, 16
		jal draw_pixel
		addi $s0, $s0, 1
		addi $s1, $s1, 1
		jal draw_pixel
		addi $s0, $s0, 1
		addi $s1, $s1, 1
		jal draw_pixel
		addi $s1, $s1, 1
		jal draw_pixel
		addi $s1, $s1, 1
		jal draw_pixel
		addi $s1, $s1, -3
		jal draw_pixel
		addi $s1, $s1, -1
		jal draw_pixel
		addi $s1, $s1, -1
		jal draw_pixel
		
		li $s0, 20
		li $s1, 15
		jal draw_pixel
		
		addi $s1, $s1, 1
		jal draw_pixel
		
		addi $s1, $s1, 1
		jal draw_pixel
		
		addi $s1, $s1, 1
		jal draw_pixel
		
		addi $s1, $s1, 2
		jal draw_pixel
		j exit
	
		
#display you lost msg
game_lost:
	li $t1, 0
	addi $s2, $s2, WHITE
	li $s0, 0
	li $s1, 0
	jal draw_pixel
	
	#start wiping out the board in white
	clear_board:
		beq $s0, 32, next
		jal draw_pixel
		addi $t1, $t1, 1 
		addi $s0, $s0, 1
		j clear_board
	
	#move on to next row
	next:
		addi $s1, $s1, 1
		bgt $s1, 31, lost_msg
		li $s0, 0
		j clear_board
		
lost_msg:
		#draw Y
		addi $s2, $0, RED
		li $s0, 4
		li $s1, 5
		jal draw_pixel
		
		addi $s0, $s0, 1
		addi $s1, $s1, 1
		jal draw_pixel
		
		addi $s0, $s0, 1
		addi $s1, $s1, 1
		jal draw_pixel
		
		addi $s1, $s1, 1
		jal draw_pixel
		
		addi $s1, $s1, 1
		jal draw_pixel
		
		addi $s1, $s1, 1
		jal draw_pixel
		
		addi $s0, $s0, 1
		addi $s1, $s1, -4
		jal draw_pixel
		
		addi $s0, $s0, 1
		addi $s1, $s1, -1
		jal draw_pixel
		
		#draw O
		li $s0, 10
		li $s1, 5
		addi $s1, $s1, 1
		jal draw_pixel
		
		addi $s1, $s1, 1
		jal draw_pixel
		
		addi $s1, $s1, 1
		jal draw_pixel
		
		addi $s1, $s1,1
		jal draw_pixel
		
		addi $s1, $s1, 1
		addi $s0, $s0, 1
		jal draw_pixel
		
		addi $s0, $s0, 1
		jal draw_pixel
		
		addi $s0, $s0, 1
		jal draw_pixel
		
		li $s0, 11
		li $s1, 5
		jal draw_pixel
		
		addi $s0, $s0, 1
		jal draw_pixel
		
		addi $s0, $s0, 1
		jal draw_pixel
		
		addi $s0, $s0, 1
		addi $s1, $s1, 1
		jal draw_pixel
		
		addi $s1, $s1, 1
		jal draw_pixel
		
		addi $s1, $s1, 1
		jal draw_pixel
		
		addi $s1, $s1, 1
		jal draw_pixel
		
		#draw u
		li $s0, 16
		li $s1, 5
		jal draw_pixel
		
		addi $s1, $s1, 1
		jal draw_pixel
		
		addi $s1, $s1, 1
		jal draw_pixel
		
		addi $s1, $s1, 1
		jal draw_pixel
		
		addi $s1, $s1, 1
		jal draw_pixel
		
		addi $s1, $s1, 1
		addi $s0, $s0, 1
		jal draw_pixel
		
		addi $s0, $s0, 1
		jal draw_pixel
		
		addi $s0, $s0, 1
		addi $s1, $s1, -1
		jal draw_pixel
		
		addi $s1, $s1, -1
		jal draw_pixel
		
		addi $s1, $s1, -1
		jal draw_pixel
		
		addi $s1, $s1, -1
		jal draw_pixel
		
		addi $s1, $s1, -1
		jal draw_pixel
	
		#draw 'l'
		li $s0, 4
		li $s1, 20
		jal draw_pixel
		
		addi $s1, $s1, 1
		jal draw_pixel
		
		addi $s1, $s1, 1
		jal draw_pixel
		
		addi $s1, $s1, 1
		jal draw_pixel
		
		addi $s1, $s1, 1
		jal draw_pixel
		
		addi $s1, $s1, 1
		jal draw_pixel
		
		addi $s0, $s0, 1
		jal draw_pixel
		
		addi $s0, $s0, 1
		jal draw_pixel
		
		#draw 'o'
		li $s0, 8
		li $s1, 20
		addi $s1, $s1, 1
		jal draw_pixel
		
		addi $s1, $s1, 1
		jal draw_pixel
		
		addi $s1, $s1, 1
		jal draw_pixel
		
		addi $s1, $s1,1
		jal draw_pixel
		
		addi $s1, $s1, 1
		addi $s0, $s0, 1
		jal draw_pixel
		
		addi $s0, $s0, 1
		jal draw_pixel
		
		addi $s0, $s0, 1
		jal draw_pixel
		
		li $s0, 9
		li $s1, 20
		jal draw_pixel
		
		addi $s0, $s0, 1
		jal draw_pixel
		
		addi $s0, $s0, 1
		jal draw_pixel
		
		addi $s0, $s0, 1
		addi $s1, $s1, 1
		jal draw_pixel
		
		addi $s1, $s1, 1
		jal draw_pixel
		
		addi $s1, $s1, 1
		jal draw_pixel
		
		addi $s1, $s1, 1
		jal draw_pixel
		
		# draw 's'
		li $s1, 20
		li $s0, 14
		addi $s0, $s0, 1
		jal draw_pixel
		
		addi $s0, $s0, 1
		jal draw_pixel
		
		li $s0, 14
		li $s1, 21
		jal draw_pixel
		
		addi $s1, $s1, 1
		jal draw_pixel
		
		addi $s1, $s1, 1
		addi $s0, $s0, 1
		jal draw_pixel
		
		addi $s0, $s0, 1
		jal draw_pixel
		
		addi $s0, $s0, 1
		addi $s1, $s1, 1
		jal draw_pixel
		
		addi $s0, $s0, -1
		addi $s1, $s1, 1
		jal draw_pixel
		
		addi $s0, $s0, -1
		jal draw_pixel
		
		#draw 't'
		li $s1, 20
		li $s0, 18
		jal draw_pixel
		
		addi $s0, $s0, 1
		jal draw_pixel
		
		addi $s0, $s0, 1
		jal draw_pixel
		
		addi $s0, $s0, 1
		jal draw_pixel
		
		addi $s0, $s0, 1
		jal draw_pixel
		
		li $s0, 20
		addi $s1, $s1, 1
		jal draw_pixel
		
		addi $s1, $s1, 1
		jal draw_pixel
		
		addi $s1, $s1, 1
		jal draw_pixel
		
		addi $s1, $s1, 1
		jal draw_pixel
		
		addi $s1, $s1, 1
		jal draw_pixel
		j exit
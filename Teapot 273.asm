##
##  Daphne Hegedus 260762425
##

.data  # start data segment with bitmapDisplay so that it is at 0x10010000
.globl bitmapDisplay # force it to show at the top of the symbol table
bitmapDisplay:    .space 0x80000  # Reserve space for memory mapped bitmap display
bitmapBuffer:     .space 0x80000  # Reserve space for an "offscreen" buffer
width:            .word 512       # Screen Width in Pixels, 512 = 0x200
height:           .word 256       # Screen Height in Pixels, 256 = 0x100

lineCount   :     .space 4        # int containing number of lines
lineData:         .space 0x4800   # space for teapot line data
lineDataFileName: .asciiz "teapotLineData.bin"
errorMessage:     .asciiz "Error: File must be in directory where MARS is started."

# TODO: declare other data you need or want here!
.data

M: 		.float
331.3682, 156.83034, -163.18181, 1700.7253
-39.86386, -48.649902, -328.51334, 1119.5535
0.13962941, 1.028447, -0.64546686, 0.48553467
0.11424224, 0.84145665, -0.52810925, 6.3950152

R: .float
0.9994 0.0349 0 0
-0.0349 0.9994 0 0
0 0 1 0
0 0 0 1


.data
vector: 	.space 16
mult1Result:	.space 16
mult2Result:	.space 16

.text
##################################################################
# main entry point
# We will use save registers here without saving and restoring to
# the stack only because this is the main function!  All other 
# functions MUST RESPECT REGISTER CONVENTIONS
main:
	la $a0 lineDataFileName
	la $a1 lineData
	la $a2 lineCount
	jal loadLineData
	la $s0 lineData 	# keep buffer pointer handy for later
	la $s1 lineCount
	lw $s1 0($s1)	   	# keep line count handy for later

	# TODO: write your test code here, as well as your final 
	# animation loop.  We will likewise test individually 
	# the functions that you implement below.
	
	
MainLoop:	
	li $s2 0x00000000
	add $a0 $0 $s2
	jal clearBuffer
	
	move $a0 $s0
	add $a1 $0 $s1
	jal draw3DLines
	jal copyBuffer
	move $a0 $s0
	add $a1 $0 $s1
	jal rotate3DLines
	j MainLoop
	
	
	
	li $v0, 10      # load exit call code 10 into $v0
	syscall         # call operating system to exit
        
        

###############################################################
# void clearBuffer( int colour )
clearBuffer:
	la $t0 bitmapBuffer		#dimensions of Buffer in $t0 and $t1 (+4 for last comparison)
	la $t1 bitmapBuffer
	addi $t1 $t1 0x80004
	
Loop:	
	sw $a0 0($t0)
	addi $t0 $t0 4
	bne $t0 $t1 Loop
	
	jr $ra				

###############################################################
# copyBuffer()
copyBuffer:
	la $t0 bitmapDisplay		#$t0 = beginning of display
	la $t1 bitmapDisplay		#$t1 = beginning of buffer
	addi $t1 $t1 0x80004
	la $t2 0($t1)			#$t2 stays at end of display for bound checking later

		
Loop2:		
	lw $t3 0($t1)			#load whatever is at point in buffer to $t3
	sw $t3 0($t0)			#pass $t3 to point in display
	addi $t0 $t0 4			#move up in display
	addi $t1 $t1 4			#move up in buffer
	bne $t0 $t2 Loop2		#if not at end of display loop again
	jr $ra

###############################################################
# drawPoint( int x, int y ) 
drawPoint: 
	li $t0 512			#store dimensions in registers for comparison
	li $t1 256
	sltu $t0 $a0 $t0		#check inputs for validity
	sltu $t1 $a1 $t1
	beq $t0 $0 Fin			#if either is invalid then jump to end of method
	beq $t1 $0 Fin
		
	li $t0 512		
	mult $t0 $a1			#reach offsetted point with equation b + 4(x + wy)
	mflo $t0
	add $t0 $t0 $a0
	li $t2 4
	mult $t0 $t2
	mflo $t0
	la $t3 bitmapBuffer
	add $t0 $t0 $t3 		#b = bitmapBuffer
	
	li $t1 0x0000ff00		#both are valid so set to green
	sw $t1 0($t0)			#store green into final location
	
Fin:	jr $ra
		

###############################################################   HAVE TO USE STACK SPACE TO STORE t's
# void drawline( int x0, int y0, int x1, int y1 )
drawLine:						# a0 = x0, a1 = y0, a2 = x1, a3 = y1

		addi $sp $sp -20			#store space on stack
		sw $ra 0($sp)
		sw $s0 4($sp)
		sw $s1 8($sp)
		sw $s2 12($sp)
		sw $s3 16($sp)
		
		li $s0 1				# s0 = offset x = 1 
		li $s1 1				# s1 = offset y = 1
		sub $s2 $a2 $a0				# s2 = dx = x1 - x0
		sub $s3 $a3 $a1				# s3 = dy = y1 - y0
		slt $t4 $s2 $0				# dx < 0 test into $t4
		beq $t4 $0 dxPositive			# skip if if dx >= 0
							# t4 used for comparisons here on out
		sub $s2 $0 $s2				# dx = -dx
		li $s0 -1				# x offset = -1
dxPositive:
		slt $t4 $s3 $0				# dy < 0 test into $t4
		beq $t4 $0 dyPositive			# skip if if dy >= 0

		sub $s3 $0 $s3				# dy = -dy
		li $s1 -1				# y offset = -1
dyPositive:	
		jal drawPoint				#both pos so draw
		slt $t4 $s3 $s2				# dy < dx
		beq $t4 $0 Else				# branch to else if doesn't pass
		
		add $t5 $s2 $0				# t5 = error = dx
		beq $a0 $a2 End				# x0 = x1 -> end
		
While1:		
		sub $t5 $t5 $s3				# error = error - 2dy
		sub $t5 $t5 $s3
		slt $t4 $t5 $0				# error < 0
		beq $t4 $0 errorPositive1		# skip if if error is positive
		
		add $a1 $a1 $s1				# y = y + y offset
		add $t5 $t5 $s2				# error = error + 2dx
		add $t5 $t5 $s2
errorPositive1:
		add $a0 $a0 $s0				# x = x + x offset
		jal drawPoint				
		bne $a0 $a2 While1			# if x0 != x1 do loop again
		j End					# done -> end
		
Else:
		add $t5 $s3 $0				# t5 = error = dy
		beq $a1 $a3 End				# if y0 = y1 -> end
While2:
		sub $t5 $t5 $s2				# error = error - 2dx
		sub $t5 $t5 $s2
		slt $t4 $t5 $0 				# error < 0
		beq $t4 $0 errorPositive2		# skip if if error is positive
		
		add $a0 $a0 $s0				# x = x + x pffset
		add $t5 $t5 $s3				# error = error + 2dy
		add $t5 $t5 $s3			
errorPositive2:
		add $a1 $a1 $s1				# y = y + y offset
		jal drawPoint
		bne $a1 $a3 While2			# if y0 != y1 do loop again
		
End:		
		lw $s3 16($sp)				# restore s registers and stack pointer
		lw $s2 12($sp)
		lw $s1 8($sp)
		lw $s0 4($sp)
		lw $ra 0($sp)
		addi $sp $sp 20
		jr $ra

###############################################################
# void mulMatrixVec( float* M, float* vec, float* result )
mulMatrixVec:
		# -------------------------
		move $t0 $a0			# save address of first element in M
		move $t1 $a1			# save the address of the first element of the vector 
		move $t2 $a2			# save address of first element in result vector
		
		# ------------------------- ROW 1
		
		l.s $f4 0($a0) 			# load val at beginning of M into temp float reg
		l.s $f6 0($a1) 			# load val at beginning of vec into temp float reg
		mtc1 $zero $f10
		
		mul.s $f8 $f4 $f6  		# multiply r1c1 of M x r1c1 of vec (will use for emultiplications)
		add.s $f10 $f10 $f8 		# add result into temp f10 (will store cummulative additions)
		
		addi $a0 $a0 4 			# move to r1c2
		addi $a1 $a1 4 			# move to c2
		
		l.s $f4 0($a0)			# load that into temps again
		l.s $f6 0($a1)
		
		mul.s $f8 $f4 $f6 		# mult
		add.s $f10 $f10 $f8		# cummulative addition
		
						# REPEAT FOR FULL ROW 1 of M
		addi $a0 $a0 4 
		addi $a1 $a1 4 
		
		l.s $f4 0($a0)
		l.s $f6 0($a1)
		
		mul.s $f8 $f4 $f6 
		add.s $f10 $f10 $f8
		
		
		addi $a0 $a0 4 
		addi $a1 $a1 4 
		
		l.s $f4 0($a0)
		l.s $f6 0($a1)
		
		mul.s $f8 $f4 $f6 
		add.s $f10 $f10 $f8
		
		

		s.s $f10 0($a2) 		# store cummulative value into the 1st val of result
		addi $a2 $a2 4 			# move result
		
		#----------------------ROW 2
		
		mtc1 $zero $f10			# set register used for addition back to 0
		
		addi $a0 $a0 4 			# move to r2c1 in M
		move $a1 $t1 			# move back to r1c1 in vec
				
		l.s $f4 0($a0) 			# REPEAT r1 PROCESS for r2
		l.s $f6 0($a1) 
		
		
		mul.s $f8 $f4 $f6  
		add.s $f10 $f10 $f8 
		
		addi $a0 $a0 4 
		addi $a1 $a1 4 
		
		l.s $f4 0($a0)
		l.s $f6 0($a1)
		
		mul.s $f8 $f4 $f6 
		add.s $f10 $f10 $f8
		
		
		addi $a0 $a0 4 
		addi $a1 $a1 4 
		
		l.s $f4 0($a0)
		l.s $f6 0($a1)
		
		mul.s $f8 $f4 $f6 
		add.s $f10 $f10 $f8
		
		
		addi $a0 $a0 4 
		addi $a1 $a1 4 
		
		l.s $f4 0($a0)
		l.s $f6 0($a1)
		
		mul.s $f8 $f4 $f6 
		add.s $f10 $f10 $f8
		
		
		s.s $f10 0($a2) 		# store cummulative value into the 2nd val of result
		addi $a2 $a2 4 			# move result to next space
		
		#----------------------ROW 3
		
		mtc1 $zero, $f10		# set register used for addition back to 0
		
		addi $a0 $a0 4 			# move to r3c1 in M
		move $a1 $t1 			# move back to r1c1 in vec
						# REPEAT PROCESS FOR r3
		l.s $f4 0($a0) 
		l.s $f6 0($a1) 
		
		
		mul.s $f8 $f4 $f6  
		add.s $f10 $f10 $f8 
		
		addi $a0 $a0 4 
		addi $a1 $a1 4 
		
		l.s $f4 0($a0)
		l.s $f6 0($a1)
		
		mul.s $f8 $f4 $f6 
		add.s $f10 $f10 $f8
		
		
		addi $a0 $a0 4 
		addi $a1 $a1 4 
		
		l.s $f4 0($a0)
		l.s $f6 0($a1)
		
		mul.s $f8 $f4 $f6 
		add.s $f10 $f10 $f8
		
		
		addi $a0 $a0 4 
		addi $a1 $a1 4 
		
		l.s $f4 0($a0)
		l.s $f6 0($a1)
		
		mul.s $f8 $f4 $f6 
		add.s $f10 $f10 $f8
		
		
		s.s $f10 0($a2) 		# store cummulative value into the 3rd val of result
		addi $a2 $a2 4 			# move result to next space
		
		
		#----------------------ROW 4
		
		mtc1 $zero, $f10		# set register used for addition back to 0
		
		addi $a0 $a0 4 			# move to r4c1 in M
		move $a1 $t1 			# move back to r1c1 in vec
						# REPEAT PROCESS FOR r4
		l.s $f4 0($a0) 
		l.s $f6 0($a1) 
		
		
		mul.s $f8 $f4 $f6  
		add.s $f10 $f10 $f8 
		
		addi $a0 $a0 4
		addi $a1 $a1 4 
		
		l.s $f4 0($a0)
		l.s $f6 0($a1)
		
		mul.s $f8 $f4 $f6 
		add.s $f10 $f10 $f8
		
		
		addi $a0 $a0 4 
		addi $a1 $a1 4 
		
		l.s $f4 0($a0)
		l.s $f6 0($a1)
		
		mul.s $f8 $f4 $f6 
		add.s $f10 $f10 $f8
		
		
		addi $a0 $a0 4 
		addi $a1 $a1 4 
		
		l.s $f4 0($a0)
		l.s $f6 0($a1)
		
		mul.s $f8 $f4 $f6 
		add.s $f10 $f10 $f8
		
		
		s.s $f10 0($a2) 		# store cummulative value into the 4th val of result
		
		#----------------------
		
		move $a0 $t0			# restore a registers (not necessary)
		move $a1 $t1
		move $a2 $t2
		jr $ra
        
        
###############################################################
# (int x,int y) = point2Display( float* vec )
point2Display:      
	       	l.s $f4 0($a0)		# f4 is 'x' in assignment sheet
		l.s $f6 4($a0)		# f6 is 'y' in assignment sheet
		l.s $f8 12($a0)		# f8 is 'w' in assignment sheet
		
		div.s $f10 $f4 $f8	# do the division specified
		div.s $f16 $f6 $f8
		
		cvt.w.s $f0 $f10	# convert f10 float to word / int -> f0
		mfc1 $t0 $f0		# place word in t regs.
		cvt.w.s $f1 $f16	# convert f16 to word / int -> f1
		mfc1 $t1 $f1		# place word in t regs.
		
		add $v0 $0 $t0		# store results in v regs.
		add $v1 $0 $t1
	   	   
	        jr $ra
        
###############################################################
# draw3DLines( float* lineData, int lineCount )
draw3DLines:
		addi $sp $sp -24
		sw $ra 0($sp)
		sw $s0 4($sp)
		sw $s1 8($sp)		
		sw $s2 12($sp)		#  will have address to space for vector
		sw $s3 16($sp)		# will have lines read so far
		sw $s4 20($sp)		# will be used for each nibble
		
		la $s0 0($a0)		# s0 = address to line data
		la $s1 0($a1)		# s1 = lineCount
		li $s4 0		# s4 will store the amount of lines read so far for comparison to s1
		
DataLoop:	
		#---------------------- STARTPOINT CALLS

		la $s3 vector		# point register to where vector will go
	
		lw $s2 0($s0)		# get first nibble of data at that line
		sw $s2 0($s3)		# store nibble in the vector (where s3 points)
		addi $s0 $s0 4		# move the data pointer up one nibble
		addi $s3 $s3 4		# move the vector address up one nibble
					
		lw $s2 0($s0)		# REPEAT 4 TIMES FOR STARTING POINT VEC
		sw $s2 0($s3)
		addi $s0 $s0 4
		addi $s3 $s3 4
		
		lw $s2 0($s0)
		sw $s2 0($s3)
		addi $s0 $s0 4
		addi $s3 $s3 4
		
		lw $s2 0($s0)
		sw $s2 0($s3)
		addi $s0 $s0 4
		
		la $a0 M		# set up args for multiplication of starting point
		la $a1 vector
		la $a2 mult1Result
		jal mulMatrixVec	# store multiplication in mult1Result
		
		#---------------------- ENDPOINT CALLS
		
		
		la $s3 vector		# REPEAT FOR ENDPOINT
		lw $s2 0($s0)
		sw $s2 0($s3)
		addi $s0 $s0 4
		addi $s3 $s3 4
		
		lw $s2 0($s0)
		sw $s2 0($s3)
		addi $s0 $s0 4
		addi $s3 $s3 4
		
		lw $s2 0($s0)
		sw $s2 0($s3)
		addi $s0 $s0 4
		addi $s3 $s3 4
		
		lw $s2 0($s0)
		sw $s2 0($s3)
		addi $s0 $s0 4
		
		la $a0 M		# set up args to do multiplication of end point
		la $a1 vector
		la $a2 mult2Result
		jal mulMatrixVec	# store in mult2Result
		
		la $a0 mult1Result		
		jal point2Display	# ENDPOINT CALL
		add $t5 $0 $v0		# store ENDPOINT results to t2 and t3
		add $t6 $0 $v1
	
		add $v0 $0 $0		# restore v regs so another point2Display can be done
		add $v1 $0 $0
		
		la $a0 mult2Result		
		jal point2Display	# ENDPOINT CALL
		
		
		add $a0 $t5 $0		# set up args for drawLine
		add $a1 $t6 $0
		add $a2 $v0 $0
		add $a3 $v1 $0
		
		jal drawLine		# draw line
		
		addi $s4 $s4 1		# read one more line = add 1
		bne $s4 $s1 DataLoop	# if have read all lines = done
		
		
	#---------------------LOOP DONE	
		
		
		lw $s4 20($sp)		# restore save regs
		lw $s3 16($sp)
		lw $s2 12($sp)
		lw $s1 8($sp)
		lw $s0 4($sp)
		lw $ra 0($sp)
		addi $sp $sp 24
                jr $ra

###############################################################
# rotate3DLines( float* lineData, int lineCount )
rotate3DLines:
		addi $sp $sp -16
		sw $ra 0($sp)
		sw $s0 4($sp)
		sw $s1 8($sp)		
		sw $s2 12($sp)	
		
		la $s0 0($a0)		# s0 = address to end point of first line of line data
		add $s1 $0 $a1		# s1 = lineCount
		li $s2 0		# s4 will store the amount of lines read so far for comparison to s1
				
LineLoop:	
		
		la $a0 R		# set up args to do transformation of end point
		la $a1 0($s0)
		la $a2 0($s0)
		jal mulMatrixVec	
		
		addi $s0 $s0 16
		
		la $a0 R		# set up args to do transformation of end point
		la $a1 0($s0)
		la $a2 0($s0)
		jal mulMatrixVec
		
		addi $s0 $s0 16	
		
		addi $s2 $s2 1
		bne $s2 $s1 LineLoop
		
		#--------------------- LOOP DONE
		
		lw $s2 12($sp)		# restore s regs
		lw $s1 8($sp)
		lw $s0 4($sp)
		lw $ra 0($sp)
		addi $sp $sp 16
		jr $ra        
        
        
        
        
        
###############################################################
# void loadLineData( char* filename, float* data, int* count )
#
# Loads the line data from the specified filename into the 
# provided data buffer, and stores the count of the number 
# of lines into the provided int pointer.  The data buffer 
# must be big enough to hold the data in the file being loaded!
#
# Each line comes as 8 floats, x y z w start point and end point.
# This function does some error checking.  If the file can't be opened, it 
# forces the program to exit and prints an error message.  While other
# errors may happen on reading, note that no other errors are checked!!  
#
# Temporary registers are used to preserve passed argumnets across
# syscalls because argument registers are needed for passing information
# to different syscalls.  Temporary usage:
#
# $t0 int pointer for line count,  passed as argument
# $t1 temporary working variable
# $t2 filedescriptor
# $t3 number of bytes to read
# $t4 pointer to float data,  passed as an argument
#
loadLineData:	move $t4 $a1 		# save pointer to line count integer for later		
		move $t0 $a2 		# save pointer to line count integer for later
			     		# $a0 is already the filename
		li $a1 0     		# flags (0: read, 1: write)
		li $a2 0     		# mode (unused)
		li $v0 13    		# open file, $a0 is null-terminated string of file name
		syscall			# $v0 will contain the file descriptor
		slt $t1 $v0 $0   	# check for error, if ( v0 < 0 ) error! 
		beq $t1 $0 skipError
		la $a0 errorMessage 
		li $v0 4    		# system call for print string
		syscall
		li $v0 10    		# system call for exit
		syscall
skipError:	move $t2 $v0		# save the file descriptor for later
		move $a0 $v0         	# file descriptor (negative if error) as argument for write
  		move $a1 $t0       	# address of buffer to which to write
		li  $a2 4	    	# number of bytes to read
		li  $v0 14          	# system call for read from file
		syscall		     	# v0 will contain number of bytes read
		
		lw $t3 0($t0)	     	# read line count from memory (was read from file)
		sll $t3 $t3 5  	     	# number of bytes to allocate (2^5 = 32 times the number of lines)			  		
		
		move $a0 $t2		# file descriptor
		move $a1 $t4		# address of buffer 
		move $a2 $t3    	# number of bytes 
		li  $v0 14           	# system call for read from file
		syscall               	# v0 will contain number of bytes read

		move $a0 $t2		# file descriptor
		li  $v0 16           	# system call for close file
		syscall		     	
		
		jr $ra        

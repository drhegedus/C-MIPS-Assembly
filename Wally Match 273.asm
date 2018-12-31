# HEGEDUS
# Daphne
# 260762425
.data
displayBuffer:  .space 0x40000 # space for 512x256 bitmap display 
errorBuffer:    .space 0x40000 # space to store match function
templateBuffer: .space 0x100   # space for 8x8 template
imageFileName:    .asciiz "pxlcon512x256cropgs.raw" 
templateFileName: .asciiz "template8x8gs.raw"
# struct bufferInfo { int *buffer, int width, int height, char* filename }
imageBufferInfo:    .word displayBuffer  512 128  imageFileName
errorBufferInfo:    .word errorBuffer    512 128  0
#imageBufferInfo: .word displayBuffer 512 16 imageFileName
#errorBufferInfo: .word errorBuffer 512 16 0
templateBufferInfo: .word templateBuffer 8   8    templateFileName

.text
main:	la $a0, imageBufferInfo
	jal loadImage
	la $a0, templateBufferInfo
	jal loadImage
	la $a0, imageBufferInfo
	la $a1, templateBufferInfo
	la $a2, errorBufferInfo
	jal matchTemplateFast        # MATCHING DONE HERE
	la $a0, errorBufferInfo
	jal findBest
	la $a0, imageBufferInfo
	move $a1, $v0
	jal highlight
	la $a0, errorBufferInfo	
	jal processError
	li $v0, 10		# exit
	syscall
	

##########################################################
# matchTemplate( bufferInfo imageBufferInfo, bufferInfo templateBufferInfo, bufferInfo errorBufferInfo )
# NOTE: struct bufferInfo { int *buffer, int width, int height, char* filename }
matchTemplate:	
	
		lw $a1 8($a0) 			# width of I
		lw $a2 4($a0) 			# height of I
		la $t5 templateBuffer		# pointer to templateBuffer = $t5
		la $t6 errorBuffer		# pointer to errorBuffer = $t6
		la $a3 displayBuffer		# pointer to displayBuffer = $a3
		addi $a1 $a1 -7			# width - 7 for comparison of y
		addi $a2 $a2 -7			# height - 7 for comparison of x
		li $t1 0			# y = $t1
	
heightLoop:  	slt $t0 $t1 $a1			# y <= height - 8
		beq $t0 $0 Fin
 		li $t2 0  			# x = $t2
widthLoop:  	slt $t0 $t2 $a2			# x <= width - 8
		beq $t0 $0 endWidthLoop 
		li $t3 0  			# j = $t3
		li $v0 0
	
jLoop:  	slti $t0 $t3 8			# j < 8
		beq $t0 $0 endJLoop          
		li $t4 0			# i = $t4
	
iLoop:  	slti $t0 $t4 8 			# i < 8
		beq $t0 $0 endiLoop
		addi $t0 $a2 7 			# move up 7 in height
	
		mult $t1 $t0  			# y * (height+7)
		mflo $t7 			
		add $t7 $t7 $t2 		# (y * (height + 7)) + x = t8
	
		mult $t3 $t0 			# j * (height + 7)
		mflo $t8 			
		add $t8 $t8 $t4 		# (j * (height + 7)) + i = t7
	
		add $t7 $t7 $t8			# t7 + t8
		li $a0 4 	
		mult $a0 $t7			# 4(t7 + t8)
		mflo $t7 
	
	
		add $t7 $t7 $a3			# 4(t7 + t8) + displayBuffer*  -> I[x+i][y+j]
	
	
		li $a0 8		
		mult $t3 $a0 			# j * 8
		mflo $t8 
		add $t8 $t8 $t4			# (j * 8) + i
		li $a0 4
		mult $t8 $a0			# 4(8j + i)
		mflo $t8
	

		add $t9 $t8 $t5			# t9 = 4(8j + i) + templateBuffer*  -> T[i][j]
	
		lbu $t7 1($t7)			# pixel by pixel for I and T
		lbu $t9 1($t9)
		subu $t7 $t7 $t9		# I[i+x][y+j] - T[i][j])
		abs $t7 $t7			# abs(I[i+x][y+j] - T[i][j]))
		addu $v0 $t7 $v0		# in SAD[x,y]
	
		addi $t4 $t4 1 			# i ++
		j iLoop
	
	
endiLoop: 	addi $t3 $t3 1			# j ++
	 	j jLoop	

endJLoop:  	
		# PUT IN ERROR BUFFER
		addi $t0 $a2 7 			# t0 now holds height of Image
		mult $t1 $t0			# height * y
		mflo $t7 
		add $t7 $t2 $t7			# (height * y) + x
		li $t0 4 
		mult $t0 $t7 			# 4((height*y) + x)
		mflo $t7 
		add $t7 $t6 $t7 		# t7 + errorBuffer*
		sw $v0 0($t7) 			# store result in v0
		addi $t2 $t2 1 			# x ++
		j widthLoop 	
	   
endWidthLoop:   addi $t1 $t1 1			# y ++
		j heightLoop
		
Fin: 		jr $ra
	
##########################################################
# matchTemplateFast( bufferInfo imageBufferInfo, bufferInfo templateBufferInfo, bufferInfo errorBufferInfo )
# NOTE: struct bufferInfo { int *buffer, int width, int height, char* filename }
matchTemplateFast:	
	
	
		addi $sp $sp -8 	# stack space
		sw $s0 0($sp) 
		sw $s1 4($sp) 
		
		li $a3 0 		# j counter
templateH:	slti $t0 $a3 8 		# j < 8
		beq $t0 $0 End 		# end of outer most loop
		li $t9 32 		# need 4*8
		mult $t9 $a3 		# current number of rows * height offset.
		mflo $t9 	
		lw $t0 0($a1) 		# templateBuffer*
		add $t9 $t0 $t9 	# add the height offset to get the address of the leftmost pixel of the current row (0)
		
		#UNROLLING
		lbu $t0 1($t9) 		# load byte of intensity of leftmost pixel in current row
		lbu $t1 5($t9) 		# next pixel (1)
		lbu $t2 9($t9) 		# next pixel (2)
		lbu $t3 13($t9) 	# next pixel (3)
		lbu $t4, 17($t9) 	# etc		
		lbu $t5, 21($t9) 	
		lbu $t6, 25($t9) 	
		lbu $t7, 29($t9) 	# last pixel (7)
		
		# looping image
		li $v0 0 		# y = 0
imageH:		lw $t9 8($a0)  		# height of image
		addi $t9 $t9 -7 	# y <= height - 7
		slt $t9 $v0 $t9 	# done looping over y?
		beq $t9 $0 imgHeightDone
		
		li $v1 0 		# x = 0
imageW:		lw $t9 4($a0) 		# image width
		addi $t9 $t9 -7 	# x <= width - 7
		slt $t9 $v1 $t9 	# done looping over x?
		beq $t9 $0 imgWidthDone 
	
	
		# t0 - t7 = byte intensities of the current row of the template pixels
		
		# v0 = height (curr image)
		# v1 = width (curr image)
		# at (height, width) -> store SAD[x,y] of row of pixels - row of template pixels
		
		lw $t9 4($a0) 		# image width
		add $t8 $v0 $a3 	# + current template height
		mult $t9 $t8 		# (width * current image height) + template height
		mflo $t8 		
		mult $t9 $v0 		# (width * current image height) (this is for errorBuffer address)
		mflo $t9 		
		add $t8 $t8 $v1 	# offset/4 (this is for imagebuffer address)
		add $t9 $t9 $v1 	# offset/4 (this is for errorBuffer address)
		
		li $s1 4 	
		mult $t8 $s1 		# get word offset
		mflo $t8 		
		mult $t9 $s1 		# original offset * 4
		mflo $t9 	
		lw $s0 0($a2) 		# errorBuffer*
		add $s0 $s0 $t9 	# add total offset to address of errorBuffer (to save SAD)
		lw $s1 0($s0) 		# SAD[x,y]
		lw $t9 0($a0) 		# imageBuffer*
		add $t8 $t8 $t9 	# total offset + address of imagebuffer
		
		#UNROLLNG
		lbu $t9 1($t8) 		# byte of intensity from image (0)
		sub $t9 $t9 $t0 	# difference from template row[0]
		abs $t9 $t9 		# abs(value)
		add $s1 $s1 $t9 	# += abs(SAD)
		
		lbu $t9 5($t8) 		# repeat for all 7 (1)
		sub $t9 $t9 $t1
		abs $t9 $t9 
		add $s1 $s1 $t9 
		
		lbu $t9 9($t8) 		# (2)
		sub $t9 $t9 $t2 
		abs $t9 $t9 
		add $s1 $s1 $t9 
		
		lbu $t9 13($t8) 	# (3)
		sub $t9 $t9 $t3 
		abs $t9 $t9 
		add $s1 $s1 $t9 
		
		lbu $t9 17($t8) 	# (4)
		sub $t9 $t9 $t4 
		abs $t9 $t9 
		add $s1 $s1 $t9 
		
		lbu $t9 21($t8) 	# (5)
		sub $t9 $t9 $t5 
		abs $t9 $t9 
		add $s1 $s1 $t9 
		
		lbu $t9 25($t8) 	# (6)
		sub $t9 $t9 $t6 
		abs $t9 $t9 		
		add $s1 $s1, $t9 
		
		lbu $t9 29($t8) 	# (7)
		sub $t9 $t9 $t7 
		abs $t9 $t9 
		add $s1 $s1 $t9 
		
		
		sw $s1 0($s0) 		# s1 = new SAD -> put in s0
		addi $v1 $v1 1 		# x ++
		j imageW
		
imgWidthDone: 	addi $v0 $v0 1 		# y ++
		j imageH 
		
imgHeightDone:	addi $a3 $a3 1 		# j ++
		j templateH 
		
		# RESTORE REGS
End:		lw $s0 0($sp) 
		lw $s1 4($sp) 
		addi $sp $sp 8 
		jr $ra	
	
	
	
###############################################################
# loadImage( bufferInfo* imageBufferInfo )
# NOTE: struct bufferInfo { int *buffer, int width, int height, char* filename }
loadImage:	lw $a3, 0($a0)  # int* buffer
		lw $a1, 4($a0)  # int width
		lw $a2, 8($a0)  # int height
		lw $a0, 12($a0) # char* filename
		mul $t0, $a1, $a2 # words to read (width x height) in a2
		sll $t0, $t0, 2	  # multiply by 4 to get bytes to read
		li $a1, 0     # flags (0: read, 1: write)
		li $a2, 0     # mode (unused)
		li $v0, 13    # open file, $a0 is null-terminated string of file name
		syscall
		move $a0, $v0     # file descriptor (negative if error) as argument for read
  		move $a1, $a3     # address of buffer to which to write
		move $a2, $t0	  # number of bytes to read
		li  $v0, 14       # system call for read from file
		syscall           # read from file
        		# $v0 contains number of characters read (0 if end-of-file, negative if error).
        		# We'll assume that we do not need to be checking for errors!
		# Note, the bitmap display doesn't update properly on load, 
		# so let's go touch each memory address to refresh it!
		move $t0, $a3	   # start address
		add $t1, $a3, $a2  # end address
loadloop:	lw $t2, ($t0)
		sw $t2, ($t0)
		addi $t0, $t0, 4
		bne $t0, $t1, loadloop
		jr $ra
		
		
#####################################################
# (offset, score) = findBest( bufferInfo errorBuffer )
# Returns the address offset and score of the best match in the error Buffer
findBest:	lw $t0, 0($a0)     # load error buffer start address	
		lw $t2, 4($a0)	   # load width
		lw $t3, 8($a0)	   # load height
		addi $t3, $t3, -7  # height less 8 template lines minus one
		mul $t1, $t2, $t3
		sll $t1, $t1, 2    # error buffer size in bytes	
		add $t1, $t0, $t1  # error buffer end address
		li $v0, 0		# address of best match	
		li $v1, 0xffffffff 	# score of best match	
		lw $a1, 4($a0)    # load width
        		addi $a1, $a1, -7 # initialize column count to 7 less than width to account for template
fbLoop:		lw $t9, 0($t0)        # score
		sltu $t8, $t9, $v1    # better than best so far?
		beq $t8, $zero, notBest
		move $v0, $t0
		move $v1, $t9
notBest:		addi $a1, $a1, -1
		bne $a1, $0, fbNotEOL # Need to skip 8 pixels at the end of each line
		lw $a1, 4($a0)        # load width
        		addi $a1, $a1, -7     # column count for next line is 7 less than width
        		addi $t0, $t0, 28     # skip pointer to end of line (7 pixels x 4 bytes)
fbNotEOL:	add $t0, $t0, 4
		bne $t0, $t1, fbLoop
		lw $t0, 0($a0)     # load error buffer start address	
		sub $v0, $v0, $t0  # return the offset rather than the address
		jr $ra
		

#####################################################
# highlight( bufferInfo imageBuffer, int offset )
# Applies green mask on all pixels in an 8x8 region
# starting at the provided addr.
highlight:	lw $t0, 0($a0)     # load image buffer start address
		add $a1, $a1, $t0  # add start address to offset
		lw $t0, 4($a0) 	# width
		sll $t0, $t0, 2	
		li $a2, 0xff00 	# highlight green
		li $t9, 8	# loop over rows
highlightLoop:	lw $t3, 0($a1)		# inner loop completely unrolled	
		and $t3, $t3, $a2
		sw $t3, 0($a1)
		lw $t3, 4($a1)
		and $t3, $t3, $a2
		sw $t3, 4($a1)
		lw $t3, 8($a1)
		and $t3, $t3, $a2
		sw $t3, 8($a1)
		lw $t3, 12($a1)
		and $t3, $t3, $a2
		sw $t3, 12($a1)
		lw $t3, 16($a1)
		and $t3, $t3, $a2
		sw $t3, 16($a1)
		lw $t3, 20($a1)
		and $t3, $t3, $a2
		sw $t3, 20($a1)
		lw $t3, 24($a1)
		and $t3, $t3, $a2
		sw $t3, 24($a1)
		lw $t3, 28($a1)
		and $t3, $t3, $a2
		sw $t3, 28($a1)
		add $a1, $a1, $t0	# increment address to next row	
		add $t9, $t9, -1		# decrement row count
		bne $t9, $zero, highlightLoop
		jr $ra

######################################################
# processError( bufferInfo error )
# Remaps scores in the entire error buffer. The best score, zero, 
# will be bright green (0xff), and errors bigger than 0x4000 will
# be black.  This is done by shifting the error by 5 bits, clamping
# anything bigger than 0xff and then subtracting this from 0xff.
processError:	lw $t0, 0($a0)     # load error buffer start address
		lw $t2, 4($a0)	   # load width
		lw $t3, 8($a0)	   # load height
		addi $t3, $t3, -7  # height less 8 template lines minus one
		mul $t1, $t2, $t3
		sll $t1, $t1, 2    # error buffer size in bytes	
		add $t1, $t0, $t1  # error buffer end address
		lw $a1, 4($a0)     # load width as column counter
        		addi $a1, $a1, -7  # initialize column count to 7 less than width to account for template
pebLoop:		lw $v0, 0($t0)        # score
		srl $v0, $v0, 5       # reduce magnitude 
		slti $t2, $v0, 0x100  # clamp?
		bne  $t2, $zero, skipClamp
		li $v0, 0xff          # clamp!
skipClamp:	li $t2, 0xff	      # invert to make a score
		sub $v0, $t2, $v0
		sll $v0, $v0, 8       # shift it up into the green
		sw $v0, 0($t0)
		addi $a1, $a1, -1        # decrement column counter	
		bne $a1, $0, pebNotEOL   # Need to skip 8 pixels at the end of each line
		lw $a1, 4($a0)        # load width to reset column counter
        		addi $a1, $a1, -7     # column count for next line is 7 less than width
        		addi $t0, $t0, 28     # skip pointer to end of line (7 pixels x 4 bytes)
pebNotEOL:	add $t0, $t0, 4
		bne $t0, $t1, pebLoop
		jr $ra

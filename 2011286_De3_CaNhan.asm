#Chuong trinh: Chuyen so thanh chuoi luu vao CHUOISO.TXT
#-----------------------------------
#Data segment
	.data
#Cac dinh nghia bien:
int_n: 	.word 0
filename:   .asciiz "CHUOISO.TXT" # filename for output
buffer: .asciiz "0000000000000000" 
buffer1:.asciiz "00000"
buffer2:.asciiz "0000"
He2: 	.asciiz "Ket qua he 2: "
He10: 	.asciiz "Ket qua he 10: "
He16: 	.asciiz "Ket qua he 16: "
newline:.asciiz "\n"
#Cac cau nhac nhap du lieu
#-----------------------------------
Xuat:	.asciiz "So nguyen n: "
#Code segment
	.text
	.globl	main
#-----------------------------------
#Chuong trinh chinh
#-----------------------------------
main:	
#Nhap (syscall)
#Xu ly
	# Thiet lap ban dau cho random
	addi 	$v0, $zero, 30	 # system call for time (system time)	
	syscall                  # $a0 = low order 32 bits of system time
	add 	$t0, $zero, $a0  # Save $a0 value in $t0 
	
	addi	$a0, $zero, 0	# Load RNG ID (0 in this case) into $a0
	add 	$a1, $zero, $t0	# Load RNG seed 
	addi	$v0, $zero, 40	# system call for set seed
	syscall	
	
	# Tao 1 so ngau nhien n nguyen
	li 	$a0, 0		# Load RNG ID (0 in this case) into $a0
	li 	$v0, 42 
	li 	$a1, 65536	# $a1 = upper bound of range of returned values.
	syscall			# $a0 gets the random number
	sw 	$a0, int_n	# Save $a0 value in int_n
	
	# Goi ham chuyen doi so n thanh chuoi he 2 
	lw 	$a0, int_n 	# a0 = int_n
	la 	$a1, buffer 	# a1 = addr(buffer[])
	jal binary
	# Goi ham chuyen doi so n thanh chuoi he 10 
	lw 	$a0, int_n 	# a0 = int_n
	la 	$a1, buffer1 	# a1 = addr(buffer1[])
	jal decimal
	# Goi ham chuyen doi so n thanh chuoi he 16
	lw 	$a0, int_n 	# a0 = int_n
	la 	$a2, buffer2 	# a2 = addr(buffer2[])
	jal hexadecimal
	
#Xuat ket qua (syscall) 
	# Xuat ra tap tin CHUOISO.TXT
	# Open (for writing) a file that does not exist
  	li   	$v0, 13       # system call for open file
  	la   	$a0, filename # output file name
  	li   	$a1, 1        # Open for writing (flags are 0: read, 1: write)
  	li   	$a2, 0        # mode is ignored
  	syscall               # open a file (file descriptor returned in $v0)
 	move 	$s6, $v0      # save the file descriptor 
	# Write to file just opened
  	# output He2
    	la      $a1, He2
   	jal     fputs
   	# output buffer
   	la      $a1, buffer
    	jal     fputs
    	# output newline
   	la      $a1, newline
    	jal     fputs
    	# output He10
    	la      $a1, He10
   	jal     fputs
   	# output buffer1
   	la      $a1, buffer1
    	jal     fputs
    	# output newline
   	la      $a1, newline
    	jal     fputs  
    	# output He16
    	la      $a1, He16
   	jal     fputs
   	# output buffer2
   	la      $a1, buffer2
    	jal     fputs          
  	# Close the file 
  	li   	$v0, 16       # system call for close file
  	move 	$a0, $s6      # file descriptor to close
  	syscall               # close file
  	
  	# Xuat ra man hinh
 	addi 	$v0, $zero, 4
	la 	$a0, Xuat
	syscall
	addi 	$v0, $zero, 1
	lw	$a0, int_n
	syscall
	addi 	$v0, $zero, 4
	la 	$a0, newline
	syscall
	addi 	$v0, $zero, 4
	la 	$a0, He2
	syscall
	addi 	$v0, $zero, 4
	la 	$a0, buffer
	syscall
	addi 	$v0, $zero, 4
	la 	$a0, newline
	syscall
	addi 	$v0, $zero, 4
	la 	$a0, He10
	syscall
	addi 	$v0, $zero, 4
	la 	$a0, buffer1
	syscall
	addi 	$v0, $zero, 4
	la 	$a0, newline
	syscall
	addi 	$v0, $zero, 4
	la 	$a0, He16
	syscall
	addi 	$v0, $zero, 4
	la 	$a0, buffer2
	syscall	
#ket thuc chuong trinh (syscall)
Kthuc:	addiu	$v0, $zero, 10
	syscall
#-----------------------------------
# Chuong trinh con binary: chuyen chuoi he 2
# Input: a0 = int_n, a1 = addr(buffer[]) 
# Output: buffer la chuoi he 2 16 ky tu
binary: 
	addi 	$s1, $zero, 0 	# s1 = i = 0
	addi 	$s2, $zero, 1
	sll 	$s2, $s2, 15 	# s2 = 2^15
	while:
		beq 	$s1, 16, end_wh 	# if (i = 16) thoat khoi vong lap
		slt 	$t1, $a0, $s2
		beq 	$t1, $zero, else 	# if (a0 < s2) 
			addi 	$s0, $zero, '0'
			sb 	$s0, 0($a1) 	# buffer[i] = 0
			addi 	$a1, $a1, 1
			addi 	$s1, $s1, 1 	# i = i + 1
 			srl 	$s2, $s2, 1 	# s2 = s2/2
 			j while
		else: 	# a0 >= s2
			addi 	$s0, $zero, '1'
			sb 	$s0, 0($a1) 	# buffer[i] = 1
			addi 	$a1, $a1, 1
			addi 	$s1, $s1, 1 	# i = i + 1
			sub 	$a0, $a0, $s2 	# a0 = a0 - s2
			srl 	$s2, $s2, 1 	# s2 = s2/2
 			j while
	end_wh:
		jr $ra
# Chuong trinh con decimal: chuyen chuoi he 10
# Input: a0 = int_n, a1 = addr(buffer1[])
# Output: buffer1 la chuoi he 10 5 ky tu
decimal:
	addi 	$s1, $zero, 0 		# s1 = i = 0
	addi 	$s2, $zero, 10000  	# s2 = 10000
	addi 	$s3, $zero, 10		# s3 = 10
	while1:
		beq 	$s1, 5, end_wh1 # if (i = 5) thoat khoi vong lap
		div 	$a0, $s2 	# a0/s2
		mflo 	$t0 		# Ket qua phep chia a0/s2
		mfhi 	$a0 		# a0 cap nhat lai bang so du phep chia
		addi 	$s0, $t0, '0' 
		sb 	$s0, 0($a1) 	# buffer1[i] = t0
		addi 	$a1, $a1, 1
		addi 	$s1, $s1, 1 	# i = i + 1
		div 	$s2, $s3
		mflo 	$s2 		# s2 cap nhat lai s2 = s2/10
 		j while1
	end_wh1:
		jr $ra
# Chuong trinh con hexadecimal: chuyen chuoi he 16
# Input: a0=int_n, a2=addr(buffer2[]), 
# Output: chuoi he 16 4 ky tu
hexadecimal:
	addi 	$a1, $a2, 3 	# a1 = a2 + 3 (a1 là dia chi cuoi)
	addi 	$s1, $zero, 0 	# s1 = i = 0
	while2:
		beq 	$s1, 4, end_wh1 # if (i = 4) thoat khoi vong lap
		andi 	$s2, $a0, 15 	# 4 bit cuoi cua so
		srl 	$a0, $a0, 4 	# a0 cap nhat lai bang a0 dich phai 4 bit
		addi 	$s3, $zero, 10
		slt 	$t0, $s2, $s3
		beq 	$t0, $zero, else2	# if (s2 < 10) 
			addi 	$s0, $s2, '0'
			sb 	$s0, 0($a1) 	# buffer2[i] = s0
			subi 	$a1, $a1, 1
			addi 	$s1, $s1, 1 	# i = i + 1
			j while2
		else2:	# (s2 >= 10)
		addi 	$s0, $s2, '7'	# Luu vao s0 1 trong cac ky tu A, B, C, D, E, F	
		sb 	$s0, 0($a1) 	# buffer2[i] = s0
		subi 	$a1, $a1, 1
		addi 	$s1, $s1, 1 	# i = i + 1
 		j while2
	end_wh2:
		jr $ra
# Chuong trinh con fputs: Luu ket qua len tap tin
fputs:
   	move    $a2, $a1                 # get buffer address
	fputs_loop:
    		lb      $t0, 0($a2)      # get next character -- is it EOS?
    		addiu   $a2, $a2, 1      # pre-increment pointer
    		bnez    $t0, fputs_loop  # no, loop
    	subu    $a2, $a2, $a1            # get strlen + 1
    	subiu   $a2, $a2, 1              # compensate for pre-increment
   	move    $a0, $s6                 # get file descriptor
    	li      $v0, 15                  # syscall for write to file
    	syscall
    	jr      $ra                      # return
#----------

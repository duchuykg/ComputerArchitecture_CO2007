     #Chuong trinh: chia 2 so thuc chinh xac don
#-----------------------------------
#Data segment
	.data
#Cac dinh nghia bien
buffer:	.space 	8       #Noi luu tru 2 so thuc
res:	.space 	4       #Noi chua so thuc ket qua
exp: 	.word	1      	#Bien chua so exp 
fraction:.word	2       #Bien chua fraction ket qua
pos_inf: .space 4  	#Bien vo cung +
neg_inf: .space 4	#Bien vo cung -
zero: 	.float 	0.0	#Bien 0.0
nan: 	.space 	4	#Bien NaN
num1: 	.word 	3
num2: 	.word 	4
filename: 	.asciiz "FLOAT2.BIN"     # filename
#Cac cau nhac nhap du lieu
Xuat_kq:	.asciiz "Ket qua can tinh: "
#-----------------------------------
#Code segment
	.text
	.globl	main
#-----------------------------------
#Chuong trinh chinh
#-----------------------------------
main:	
#Nhap (syscall)
#Xu ly
# Mo file de doc
	addi	$v0, $zero,13  	# system call for open file
	la   	$a0, filename     
  	addi   	$a1, $zero, 0  	# Mo de doc (flags are 0: read, 1: write)
  	addi   	$a2, $zero, 0        
  	syscall            	# Mo file (file descriptor returned in $v0)
  	move 	$s0, $v0      	# save the file descriptor in s0
#doc file
	addi 	$v0, $zero, 14
	move 	$a0, $s0
	la 	$a1, buffer
	addi 	$a2, $zero, 8 	#number of charater
	syscall
#Chuyen 2 so thuc vao thanh ghi: a3=addr(buffer) 
	la 	$a3, buffer 
	lw 	$t1, 0($a3)   	#t1 = float 1
	lw 	$t2, 4($a3)	#t2 = float 2
	sw 	$t1, num1
	sw 	$t2, num2
	#Check valid
	jal valid
	jal new_exp
	sw 	$v0, exp
	#Chia 2 mantissa
	jal divide
 	sw 	$v0, fraction
		jal normalize
		sw 	$v0, fraction
		sw 	$v1, exp
		jal rounding
		sw 	$v0,fraction
		 	  lw	$t3, exp
		 	  lw 	$s2, fraction
		 	  lui 	$t5, 32767
		 	  ori 	$t5, $t5, 65280	#t5 chua 23 bit 1 trung voi vi tri 23 bit cua fration s2
		 	  and 	$s2, $t5, $s2		
			  srl 	$s2, $s2, 8	#s2 chua 23 bit fraction o dung vi tri 23 bit cuoi
			  sll 	$t3, $t3, 23    #exp ve dung vi tri trong cau truc thanh ghi
			  #t5 = -t5
			  mul 	$t5, $t5, -1
			  subi 	$t5, $t5, 256	#t5 chua 1 bit 1 o vi tri dau tien
			  lw 	$t1, num1
			  lw 	$t2, num2
			  and 	$t1, $t1, $t5  	#t1 chi con lai bit dau
			  and 	$t2, $t2, $t5	#t2 chi con lai bit dau
			  xor 	$t1, $t1, $t2	# bit dau tien cua t1 dang chua bit dau cua bai toan
			  or	$s2, $s2, $t3
			  or 	$s2, $s2, $t1	#or 3 thanh ghi lai voi nhau ta duoc thanh ghi chua ket qua
			  #ket qua:
			  sw 	$s2, res
			  lwc1 	$f12, res
#Xuat ket qua
Xuat_ket_qua:
	addi $v0, $zero, 4
	la $a0, Xuat_kq
	syscall
	addi $v0, $zero, 2
	syscall
#close file
	addi $v0, $zero, 16
	move $a0, $s0
	syscall
	
#ket thuc chuong trinh (syscall)
Kthuc:	addiu	$v0,$zero,10
	syscall
#-----------------------------------
#Cac chuong trinh con khac
#----------
new_exp:	#Thuc hien tinh exp moi
	lw 	$a1,num1
	lw 	$a2,num2
	lui 	$t3,32640	#t3 chua 8 bit 1 trung voi vi tri cua 8 bit exp
	and 	$t3,$t3,$a1                 
	srl 	$t3,$t3,23	#t3 chua 8 bit exp cua t1
	lui 	$t4,32640	#t4 chua 8 bit 1 trung voi vi tri cua 8 bit exp
	and 	$t4,$t4,$a2 
	srl 	$t4,$t4,23      #t4 chua 8 bit exp cua t2               
    #Tru 2 exp: t3 = t3 - t4 
	sub 	$t3,$t3,$t4
	addi 	$v0,$t3,127     #cong lai 127 va chua vao v0(new exp)
	jr $ra
normalize:	#Dua fraction ve dang chuan va chinh sua lai exp 
	lw 	$a3,exp
	lw 	$a2,fraction
	for2: 	srl $t9,$a2,31	       	#t9 chua bit dung truoc dau . thap phan
	bne 	$t9,$zero, endfor2	#Neu t9 = 1: ra khoi vong lap
	sll 	$a2,$a2,1		#Neu t9 = 0: shift left 1 lan
	subi 	$a3,$a3,1		#Moi lan dich t3 = t3 -1
	j for2			       	#Lap cho den khi t9 = 1
	endfor2: add $v0,$zero,$a2
		 add $v1,$zero,$a3
		 jr $ra
		 
rounding:	#Lam tron: round to nearest ties to even
	lw 	$a2,fraction
	addi 	$a1,$zero,255	#a1 chua 8 bit 1 trung vi tri voi 8 bit sau cua 23 bit fration a2
	and 	$a1,$a1,$a2	#a1 chua 8 bit phia sau 23 bit fration a2
	srl 	$a0,$a1,7	#a0 chua 1 bit phia sau cua a1
	#if(a0 != 0) do3
	beq 	$a0,$zero,endround	#Neu a0 ==0 thi lay 23 bit phia sau bit dau tien
	#do3 		
	andi 	$a1,$a1,127		#a1 chua 7 bit sau cung cua a2 
	#if(a1 != 0) do4
	beq 	$a1,$zero,doit
	#do4
	addi 	$a2,$a2,256             #Neu a1!=0: Cong them 1 bit vao bit cuoi cua fraction
	j endround
	doit: 	andi $a0,$a2,256        #a0 chua bit cuoi cua fraction a2
		#if(a0 !=0) do5		
		beq $a0,$zero,endround
		#do5
		addi $a2,$a2,256	#Neu a0!=0: Cong bit cuoi cung cua fraction s2 cho 1
		endround:	add	$v0,$zero,$a2
				jr $ra 	#Ket thuc lam tron

divide:	#Chia 2 mantissa
	lw 	$a1,num1
	lw 	$a2,num2
     #t5 = 8388607    t5 chua 23 bit 1 trung voi vi tri cua 23 bit fraction
	lui 	$t5,127
	ori 	$t5,$t5,65535
	and 	$t4,$t5,$a1 	# t4 chua fraction t1
	and 	$t6,$t5,$a2     # t6 chua fraction t2
     #Them bit 1 vao  truoc moi fraction(or voi 8388608)
     	addi 	$t5,$t5,1	#t5 = 8388608 chua 1 bit trung voi vi tri truoc 1 bit so voi fraction
	or 	$t4,$t4,$t5     #t4 chua bit 1 theo sau boi 23 bit fraction t1
	or 	$t6,$t6,$t5	#t6 chua bit 1 theo sau boi 23 bit fraction t2
     #s2 = mantissa ket qua     so bi chia = t4       so chia = t6
     	addi 	$s2,$zero,0
	#if1 (t6 > t4)
	slt 	$s1,$t4,$t6     #co van de
	beq 	$s1,$zero,else  #Neu t6 khong be hon t4 thi den else
	#do
	sll 	$t4,$t4,1	#Neu t6 > t4 them 1 bit 0 vao cuoi s2
	j befor1
	else: 	addi 	$s2,$zero,1	#Them 1 bit 1 vao cuoi cua ket qua s2	
		#Them vao day
		sub 	$t4,$t4,$t6	# t4 = t4 -t6 
		#Them vao day 
	befor1:      #Set gia tri 
	addi 	$t8,$zero,0	#t8 chua bien chay i=(0)
	addi 	$t9,$zero,31	#t9 chua dieu kien so 31
	for1:	beq 	$t8,$t9,endfor1    	#for(int t8=0;t8<31(t9);t8++) moi vong lap them 1 bit vao cuoi ket qua s2
	#if(t4<t6) do1
	slt 	$s1,$t4,$t6				
	beq 	$s1,$zero,else1
	#do1 
	sll 	$t4,$t4,1	#Neu t4 < t6: shift left t4 (tuong duong viec ha so 0 xuong khi chia bang tay)
	#if (t4<t6) do2     
 	slt 	$s1,$t4,$t6				
	beq 	$s1,$zero,else2
	#do2
	sll 	$s2,$s2,1	#Neu t4 van con be hon t6: ghi bit 0 vao cuoi s2 
	j loop
	else2: sll 	$s2,$s2,1	#Neu t4 sau khi shift left ma lon hon t6 thi ghi bit 1 vao cuoi s2 va t4 = t4-t6
	       addi 	$s2,$s2,1
	       sub 	$t4,$t4,$t6
	       j loop
	else1: sub 	$t4,$t4,$t6	#Neu t4 > t6: ghi 1 bit vao cuoi s2 va t4 = t4 - t6
	       sll 	$s2,$s2,1       #moi them 2 dong nay
	       addi 	$s2,$s2,1
	loop: #cap nhat lai gia tri bien chay
	addi 	$t8,$t8,1
	j for1
	endfor1: 	add 	$v0,$zero,$s2
			jr 	$ra
			
valid:		#kiem tra chia cho so 0 hoac chia cho vo cung hoac ket qua la NaN
	lw 	$a1,num1	#a1=num1
	lw 	$a2,num2	#a2=num2
	#store nan
	addi 	$t1, $zero,0
	lui 	$t1,32704	#load nan vao t1
	sw 	$t1,nan		#store nan vao nan
	#store neg_infinity
	addi 	$t1, $zero,0
	lui 	$t1,65408	#load 0xff800000 vao t1
	sw 	$t1,neg_inf	#store 0xff800000 vao neg_inf
	#store pos_inf
	addi 	$t1, $zero,0
	lui 	$t1,32640	#load 0x7f800000 vao t1
	sw 	$t1,pos_inf	#store 0x7f800000 vao pos_inf
	#end store
	bne 	$a2,$zero,continue	#if(a2!=0) continue
	bne 	$a1,$zero,continue2	#if(a1 !=0 && a2==0) continue2
	#else
	Xuat_nan:
	lwc1 	$f12,nan	#load nan vao f12
	j Xuat_ket_qua
	continue2:
		srl 	$t7,$a1,31
		beq 	$t7,$zero,continue3	#if(a1>0) continue3
		#else
		Xuat_neg_inf:
		lwc1 	$f12,neg_inf	#load neg_infinity vao f12
		j Xuat_ket_qua
	continue3:	#Neu a1>0
		Xuat_pos_inf:
		lwc1 	$f12,pos_inf	#load pos_infinity vao f12
		j Xuat_ket_qua
	continue: 	#if(a1==0) thi ket qua = 0
	bne 	$a1,$zero,vo_cung
	Xuat_zero:
	lwc1 	$f12,zero
	j Xuat_ket_qua
	vo_cung: 	#Xet truong hop chia cho vo cung
	lw 	$t2,pos_inf	
	lw 	$t3,neg_inf
	bne 	$a2,$t2,continue4	#if(a2!=+vocung) continue4
	bne 	$a1,$t2,continue5	#if(a1!=+vocung && a2 == +vocung) continue5
	#else
	j Xuat_nan
	continue5:
		beq 	$a1,$t3,continue6	#if(a1==-vocung) continue6
		lwc1 	$f12,zero		#else ket qua = 0
		j Xuat_ket_qua
		continue6:	j Xuat_nan	#+Vocung / -vocung =NaN
	continue4:	#Tiep tuc xet truong hop -vocung
	bne 	$a2,$t3,continue7	#if(a2!=-vocung) continue7
	bne 	$a1,$t3,continue8	#if(a1!=-vocung && a2 == -vocung) continue8
	j Xuat_nan
	continue8:
		beq 	$a1,$t2,continue9	#if(a1==+vocung) continue9
		lwc1 	$f12,zero		#else ket qua = 0
		j Xuat_ket_qua
		continue9: j Xuat_nan		#-Vocung / +vocung =NaN
	continue7:	
		srl 	$t7,$a2,31	#t7 chua bit dau a2
		bne 	$a1,$t2,tt	#if(a1 != +vocung) tt
		bne 	$t7,$zero,soam	#if(a2 < 0 && a1==+vocung) soam
		j Xuat_pos_inf		#if(a1 == +vocung && a2 >0) xuat +vocung
		soam:	j Xuat_neg_inf		#Xuat -vocung
		tt:
			bne 	$a1,$t3,tt2	#tuong tu khi a1 != -vocung thi ket thuc ham
			bne 	$t7,$zero,soduong
			j Xuat_neg_inf
			soduong: j Xuat_pos_inf
	tt2:
	jr $ra

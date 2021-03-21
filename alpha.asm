.data
	array: .space 24
	x1: .float 0.0
	x2: .float 0.0
	xacc: .float 0.0
	# parameteres ^
	MAXIT: .word 30 # CONST ~ iteratii maxime
	nrCoef: .word 0
	zeroFloat: .float 0.0
	j: .word 1
	fl: .float 0.0
	fh: .float 0.0
	xl: .float 0.0
	xh: .float 0.0
	swap: .float 0.0
	dx: .float 0.0
	del: .float 0.0
	f: .float 0.0
	rtf: .float 0.0
	msgEnc: .asciiz "Enter number of coefficients: "
	msgCoef: .asciiz "Coef "
	msgDp: .asciiz " :"
	msgStep: .asciiz "Step "
	msgRoot: .asciiz "Root -> "
	msgX1: .asciiz "x1 = "
	msgX2: .asciiz "x2 = "
	msgXacc: .asciiz "xacc = "
	newLine: .asciiz "\n"
	space: .asciiz " "
	err1: .asciiz "Root must be bracketed in rtflsp"
	err2: .asciiz "Maximum number of iterations exceeded in rtflsp"
.text
	# Enter number of coefficients
	li $v0, 4
	la $a0, msgEnc
	syscall
	li $v0, 5
	syscall
	
	# Store number of coefficients in nrCoef
	sw $v0, nrCoef
	
	# Read coefficients
	lw $t0, nrCoef 
	sll $t0, $t0, 2
	addi $t1, $zero, 0
	whileRead: 
		bge $t1, $t0, exit1
		li $v0, 4
		la $a0, msgCoef
		syscall
		divu $t2, $t1, 4
		addi $t2, $t2, 1
		li $v0, 1
		addi $a0, $t2, 0
		syscall
		li $v0, 4
		la $a0, msgDp
		syscall
		li $v0, 6   # citire coeficient
		syscall
		swc1 $f0, array($t1)
		addi $t1, $t1, 4
		j whileRead
		
	exit1:
	
	# Read other parameters
	li $v0, 4
	la $a0, msgX1
	syscall
	li $v0, 6
	syscall
	swc1 $f0, x1
	li $v0, 4
	la $a0, msgX2
	syscall
	li $v0, 6
	syscall
	swc1 $f0, x2
	li $v0, 4
	la $a0, msgXacc
	syscall
	li $v0, 6
	syscall
	swc1 $f0, xacc
	
	lwc1 $f1, x1 # f1 ~ parametru
	jal getFunctionValue
	swc1 $f0, fl # f0 ~ pun return value in fl, $f0 reprezinta valoarea functiei
	
	lwc1 $f1, x2 # f1 ~ parametru
	jal getFunctionValue
	swc1 $f0, fh # f0 ~ pun return value in fh, $f0 reprezinta valoarea functiei
	
	# verific ca radacina se afla intre intervalele respective
	lwc1 $f0, fl  
	lwc1 $f1, fh
	mul.s $f2, $f0, $f1
	lwc1 $f3, zeroFloat
	c.le.s $f2, $f3
	bc1t continue2
	li $v0, 4
	la $a0, err1
	syscall
	j theEnd
	
	continue2:
	
	c.le.s $f0, $f3 # if (fl < 0.0)
	bc1f flBigger
	lwc1 $f0, x1
	swc1 $f0, xl
	lwc1 $f0, x2
	swc1 $f0, xh
	j continue3
	
	flBigger:
	lwc1 $f0, x2
	swc1 $f0, xl
	lwc1 $f0, x1
	swc1 $f0, xh
	lwc1 $f0, fl
	swc1 $f0, swap
	lwc1 $f0, fh
	swc1 $f0, fl
	lwc1 $f0, swap
	swc1 $f0, fh
		
	continue3:
	
	# dx = xh - xl
	lwc1 $f0, xh
	lwc1 $f1, xl
	sub.s $f2, $f0, $f1
	swc1 $f2, dx
	
	# FOR (j=1; j<=MAXIT; j++)
	forMAXIT:
		lw $t0, j
		lw $t1, MAXIT 
		sle $t2, $t0, $t1
		beq $t2, $zero, errorMaxit
	
		lwc1 $f0, fl
		lwc1 $f1, fh
		sub.s $f0, $f0, $f1
		lwc1 $f1, dx
		lwc1 $f2, fl
		mul.s $f1, $f1, $f2
		div.s $f0, $f1, $f0
		lwc1 $f1, xl
		add.s $f0, $f0, $f1 # $f0 = rtf
		swc1 $f0, rtf
		
		# print current root with step
		li $v0, 4
		la $a0, msgStep
		syscall
		li $v0, 1
		addi $a0, $t0, 0
		syscall
		li $v0, 4
		la $a0, msgDp
		syscall
		li $v0, 2
		mov.s $f12, $f0
		syscall
		li $v0, 4
		la $a0, newLine
		syscall
		
		# iau val functiei unde x = rtf
		lwc1 $f1, rtf # f1 ~ parametru
		jal getFunctionValue
		swc1 $f0, f # f0 ~ pun return value in f, $f0 reprezinta valoarea functiei
		
		lwc1 $f1, zeroFloat
		c.le.s $f0, $f1 # if (f < 0.0)
		bc1f fBigger
		lwc1 $f1, xl
		lwc1 $f2, rtf
		sub.s $f1, $f1, $f2
		swc1 $f1, del
		swc1 $f2, xl
		swc1 $f0, fl
		j continue4
		
		fBigger:
		lwc1 $f1, xh
		lwc1 $f2, rtf
		sub.s $f1, $f1, $f2
		swc1 $f1, del
		swc1 $f2, xh
		swc1 $f0, fh
		
		continue4:
		# dx= xh - xl
		lwc1 $f0, xh
		lwc1 $f1, xl
		sub.s $f0, $f0, $f1
		swc1 $f0, dx 
		
		# if (fabs(del) < xacc || f == 0.0 ) return rtf	;
		lwc1 $f0, del
		jal fabs # modulul se aplica in registrul $f0	
		lwc1 $f1, xacc
		
		c.lt.s $f0, $f1 # |del| - xacc
		bc1t foundRoot # true
		lwc1 $f0, f
		lwc1 $f1, zeroFloat
		c.eq.s $f0, $f1
		bc1t foundRoot
		
		lw $t0, j
		addi $t0, $t0, 1
		sw $t0, j
		
		j forMAXIT
	
		foundRoot:
		li $v0, 4
		la $a0, msgRoot
		syscall
		lwc1 $f0, rtf
		li $v0, 2
		mov.s $f12, $f0
		syscall
		j theEnd
		
	# END FOR, eroare ramasa
	errorMaxit:
	li $v0, 4
	la $a0, err2
	syscall
	
	
	# End program
	theEnd:
	li $v0, 10
	syscall
	
	
	getFunctionValue: # $f0 = valFunctie, $f1 = valX
		lw $t0, nrCoef
		lwc1 $f0, zeroFloat
		addi $t2, $zero, 0
		whileCoefLeft:
			subi $t0, $t0, 1
			bnez $t0, continue1 # aici verific daca coeficientul este 1 (adica ultimul termen ~ c, din ax^2 + bx + c) sa nu se mai inm
			sll $t2, $t2, 2
			lwc1 $f2, array($t2)  
			add.s $f0, $f0, $f2
			j exit2
			continue1:
			addi $t0, $t0, 1
			blez $t0, exit2

			# inmultesc x cu x de nrCoef ori
			addi $t1, $t0, 0 # pastrez nrCoef in $t1
			mov.s $f2, $f1
			subi $t1, $t1, 1
			whilePowLeft:
				subi $t1, $t1, 1
				beqz $t1, exit3
				addi $t1, $t1, 1
				mul.s $f2, $f2, $f1
				subi $t1, $t1, 1
				j whilePowLeft	
			
			# inmultesc rezultatul de mai sus ($f2) cu Coef curent (a | b | c ...), salvat in $f3
			exit3:		
				addi $t1, $t2, 0 # gasesc adresa coef fct
				sll $t1, $t1, 2 # inm cu 4
				lwc1 $f3, array($t1) # in $f3 voi avea coef corespunzator
				mul.s $f3, $f3, $f2
			
			# adun ($f3) rezultatul operatiilor (a * x^y) la suma
			add.s $f0, $f0, $f3
				
			# decrementez nrCoef si continui
			subi $t0, $t0, 1
			addi $t2, $t2, 1
			j whileCoefLeft
			
		exit2:
		jr $ra
		
	fabs:
		lwc1 $f1, zeroFloat
		c.lt.s $f0, $f1
		bc1t nrNegative
		jr $ra	
		nrNegative:
		sub.s $f0, $f1, $f0 	
		jr $ra
		
		
		
		
		
		
		
		
	

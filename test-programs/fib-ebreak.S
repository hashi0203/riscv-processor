	.file	"fib.c"
	.option nopic
	.text
	.align	2
	.globl	fib
	.type	fib, @function
fib:
	addi	sp,sp,-32
	sw	ra,28(sp)
	sw	s0,24(sp)
	ebreak
	sw	s1,20(sp)
	addi	s0,sp,32
	sw	a0,-20(s0)
	ebreak
	lw	a4,-20(s0)
	li	a5,1
	bgt	a4,a5,.L2
	li	a5,1
	j	.L3
.L2:
	lw	a5,-20(s0)
	addi	a5,a5,-1
	mv	a0,a5
	ebreak
	call	fib
	mv	s1,a0
	lw	a5,-20(s0)
	addi	a5,a5,-2
	mv	a0,a5
	ebreak
	call	fib
	mv	a5,a0
	add	a5,s1,a5
.L3:
	mv	a0,a5
	lw	ra,28(sp)
	ebreak
	lw	s0,24(sp)
	lw	s1,20(sp)
	addi	sp,sp,32
	jr	ra
	.size	fib, .-fib
	ebreak
	.align	2
	.globl	main
	.type	main, @function
main:
	addi	sp,sp,-16
	ebreak
	sw	ra,12(sp)
	sw	s0,8(sp)
	ebreak
	addi	s0,sp,16
	li	a0,10
	call	fib
.L5:
	j	.L5
	.size	main, .-main
	.ident	"GCC: (GNU) 10.2.0"
	.section	.note.GNU-stack,"",@progbits

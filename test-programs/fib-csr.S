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
	ebreak                // insert ebreak
	sw	s1,20(sp)
	addi	s0,sp,32
	sw	a0,-20(s0)
	ecall                 // insert ecall
	lw	a4,-20(s0)
	li	a5,1
	bgt	a4,a5,.L2
	li	a5,1
	j	.L3
.L2:
	lw	a5,-20(s0)
	addi	a5,a5,-1
	mv	a0,a5
	ebreak                // change to 32'b0 after compile
	call	fib
	mv	s1,a0
	lw	a5,-20(s0)
	addi	a5,a5,-2
	mv	a0,a5
	mret                  // insert mret in User mode
	call	fib
	mv	a5,a0
	add	a5,s1,a5
.L3:
	mv	a0,a5
	lw	ra,28(sp)
	ebreak                // change to 32'b0 after compile
	lw	s0,24(sp)
	lw	s1,20(sp)
	addi	sp,sp,32
	jr	ra
	.size	fib, .-fib
	mret                  // insert mret in User mode
	.align	2
	.globl	main
	.type	main, @function
main:
	addi	sp,sp,-16
	ebreak                // insert ebreak
	sw	ra,12(sp)
	sw	s0,8(sp)
	ecall                 // insert ecall
	addi	s0,sp,16
	li	a0,10
	call	fib
.L5:
	j	.L5
.L6:
	addi	sp,sp,-32
	sw	a4,28(sp)
	sw	a5,24(sp)
	csrr a4,834
	li a5,31
	srl a4,a4,a5
	bne a4,zero,.L7
	csrr a4,833
	addi a4,a4,1
	csrw 833,a4
.L7:
	lw	a4,28(sp)
	lw	a5,24(sp)
	addi	sp,sp,32
	mret
	.size	main, .-main
	.ident	"GCC: (GNU) 10.2.0"
	.section	.note.GNU-stack,"",@progbits
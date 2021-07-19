
fib.elf:     file format elf32-littleriscv


Disassembly of section .text.init:

00000000 <_start>:
   0:	074000ef          	jal	ra,74 <main>

Disassembly of section .text:

00000004 <fib>:
   4:	fe010113          	addi	sp,sp,-32
   8:	00112e23          	sw	ra,28(sp)
   c:	00812c23          	sw	s0,24(sp)
  10:	00912a23          	sw	s1,20(sp)
  14:	02010413          	addi	s0,sp,32
  18:	fea42623          	sw	a0,-20(s0)
  1c:	fec42703          	lw	a4,-20(s0)
  20:	00100793          	li	a5,1
  24:	00e7c663          	blt	a5,a4,30 <fib+0x2c>
  28:	00100793          	li	a5,1
  2c:	0300006f          	j	5c <fib+0x58>
  30:	fec42783          	lw	a5,-20(s0)
  34:	fff78793          	addi	a5,a5,-1
  38:	00078513          	mv	a0,a5
  3c:	fc9ff0ef          	jal	ra,4 <fib>
  40:	00050493          	mv	s1,a0
  44:	fec42783          	lw	a5,-20(s0)
  48:	ffe78793          	addi	a5,a5,-2
  4c:	00078513          	mv	a0,a5
  50:	fb5ff0ef          	jal	ra,4 <fib>
  54:	00050793          	mv	a5,a0
  58:	00f487b3          	add	a5,s1,a5
  5c:	00078513          	mv	a0,a5
  60:	01c12083          	lw	ra,28(sp)
  64:	01812403          	lw	s0,24(sp)
  68:	01412483          	lw	s1,20(sp)
  6c:	02010113          	addi	sp,sp,32
  70:	00008067          	ret

00000074 <main>:
  74:	ff010113          	addi	sp,sp,-16
  78:	00112623          	sw	ra,12(sp)
  7c:	00812423          	sw	s0,8(sp)
  80:	01010413          	addi	s0,sp,16
  84:	00a00513          	li	a0,10
  88:	f7dff0ef          	jal	ra,4 <fib>
  8c:	0000006f          	j	8c <main+0x18>

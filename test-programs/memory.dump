
memory.elf:     file format elf32-littleriscv


Disassembly of section .text.init:

00000000 <_start>:
   0:	004000ef          	jal	ra,4 <main>

Disassembly of section .text:

00000004 <main>:
   4:	fe010113          	addi	sp,sp,-32
   8:	00812e23          	sw	s0,28(sp)
   c:	02010413          	addi	s0,sp,32
  10:	00100793          	li	a5,1
  14:	fef42223          	sw	a5,-28(s0)
  18:	00200793          	li	a5,2
  1c:	fef42423          	sw	a5,-24(s0)
  20:	fe442703          	lw	a4,-28(s0)
  24:	fe842783          	lw	a5,-24(s0)
  28:	00f707b3          	add	a5,a4,a5
  2c:	fef42623          	sw	a5,-20(s0)
  30:	00000793          	li	a5,0
  34:	00078513          	mv	a0,a5
  38:	01c12403          	lw	s0,28(sp)
  3c:	02010113          	addi	sp,sp,32
  40:	00008067          	ret

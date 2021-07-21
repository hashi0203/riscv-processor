# RISC-V Processor

Implementation of RISC-V Processor in `System Verilog`.


## ISA
- Unprivileged
	- RV32I (jump, branch, load/store, arithmetic/logical operations, ecall, ebreak)
	- RV32 Zicsr (CSR operations)
	- RV32M (mul, div, rem)
- Privileged
	- Trap-Return Instructions (mret)

ISA is published in [RISC-V official page](https://riscv.org/technical/specifications/).<br>
Unprivileged Instructions are based on "[Volume 1, Unprivileged Spec v. 20191213](https://github.com/riscv/riscv-isa-manual/releases/download/Ratified-IMAFDQC/riscv-spec-20191213.pdf)."<br>
Privileged Instructions are based on "[Volume 2, Privileged Spec v. 20190608](https://github.com/riscv/riscv-isa-manual/releases/download/Ratified-IMFDQC-and-Priv-v1.11/riscv-privileged-20190608.pdf)."


## Structure

- 4-stage pipeline (`Fetch`, `Decode`, `Execute`, `Write)`
- Forwarding (`E &rarr; D`, `W &rarr; D`)
- Branch prediction (`Two-level adaptive predictor`)
- Register (32 entries, 32 bit)
- Memory (1024 entries, 32 bit)
	- Use just registers for ease of implementation
- CSR (Control and Status Register)
- Exception/Interrupt handling (only `User` and `Machine` mode without `Supervisor` mode)
	- Exception
		- 2: Illegal instruction exception
		- 3: Breakpoint exception
		- 8: System call exception (from User mode)
		- 11: System call exception (from Machine mode)
	- Interrupt
		- 7: Machine timer interrupt
		- 11: Machine external interrupt

## Registers

| Register | ABI Name | Description                        |
| -------- | -------- | ---------------------------------- |
| r0       | zero     | hardwired zero                     |
| r1       | ra       | return address                     |
| r2       | sp       | stack pointer                      |
| r8       | s0 / fp  | saved register / frame pointer     |
| r9       | s1       | saved register                     |
| r10-11   | a0-1     | function arguments / return values |
| r12-17   | a2-7     | function arguments                 |


## Demo

1. `fib-csr`

	- fib function with exceptions, interrupts, and CSR operations
	- `r15 = fib(10)`

	```
	clocks       : 18613
	pc           :    43
	instructions : total 14587, normal   3809, exception   709, others 10069
	prediction   : total  1344, succeed  1130, fail        214
	register     :
			r00:    0,    r01:   43,    r02: 2032,    r03:    0,
			r04:    0,    r05:    0,    r06:    0,    r07:    0,
			r08: 2048,    r09:    0,    r10:   89,    r11:    0,
			r12:    0,    r13:    0,    r14:    0,    r15:   89
	```

2. `fib-ebreak`

	- fib function with exceptions and interrupts
	- `r15 = fib(10)`

	```
	clocks       :  9385
	pc           :    43
	instructions : total  5267, normal   3809, exception   709, others   749
	prediction   : total   622, succeed   416, fail        206
	register     :
			r00:    0,    r01:   43,    r02: 2032,    r03:    0,
			r04:    0,    r05:    0,    r06:    0,    r07:    0,
			r08: 2048,    r09:    0,    r10:   89,    r11:    0,
			r12:    0,    r13:    0,    r14:    0,    r15:   89
	```

3. `fib`

	- fib function
	- `r15 = fib(10)`
	- 4222 [clocks] = 3809 [instructions] + (206-1) * 2 [stalls] + (4-1) [stages]
		- `206-1` is performed to ignore the prediction miss of the final instruction.

	```
	clocks       :  4222
	pc           :    35
	instructions : total  3809, normal   3809, exception     0, others     0
	prediction   : total   622, succeed   416, fail        206
	register     :
			r00:    0,    r01:   35,    r02: 2032,    r03:    0,
			r04:    0,    r05:    0,    r06:    0,    r07:    0,
			r08: 2048,    r09:    0,    r10:   89,    r11:    0,
			r12:    0,    r13:    0,    r14:    0,    r15:   89
	```

4. `memory`

	- memory operations
	- `r15 = a[0](=1) + a[1](=2)`

	```
	clocks       :    16
	pc           :    12
	instructions : total    13, normal     13, exception     0, others     0
	prediction   : total     2, succeed     1, fail          1
	register     :
			r00:    0,    r01:    1,    r02: 2016,    r03:    0,
			r04:    0,    r05:    0,    r06:    0,    r07:    0,
			r08: 2048,    r09:    0,    r10:    0,    r11:    0,
			r12:    0,    r13:    0,    r14:    1,    r15:    3
	```


## Installation

1. This repository

	```bash
	$ git clone https://github.com/hashi0203/riscv-processor.git
	```

2. RISC-V Cross Compiler

	If you just want to run the processor, you can skip this process.<br>
	If you want to run your `original test program`, you should follow this process.

	We use [riscv-gnu-toolchain](https://github.com/riscv/riscv-gnu-toolchain) as a cross compiler.<br>
	Basically, you can follow the instructions in the GitHub.

	```bash
	$ git clone https://github.com/riscv/riscv-gnu-toolchain
	$ ./configure --prefix=/opt/riscv32 --with-arch=rv32ima --with-abi=ilp32d
	$ make linux
	```

	You can change `--prefix=/opt/riscv32` to the path you want to install this compiler.

	You also have to update `PATH`.

	```
	export PATH=/opt/riscv32/bin:$PATH
	```


## Usage

If you just want to run the processor, you can skip 1 and 2.<br>
If you want to run your `original test program`, you should follow 1 to 3.

1. Make a test program for processor in [test-programs](./test-programs).
	- Make a test program in C (e.g., [fib.c](./test-programs/fib.c), [memory.c](./test-programs/memory.c)).
	- Compile the program by the following command (change "fib" to the file name (without extension) you have made).

	```bash
	$ cd /path/to/test-programs
	$ make ARG=fib
	```

	- Output files are explained later in [Files in test-programs](#files-in-test-programs) chapter.

2. Change the test program for processor.
	- Update instruction memory (`instr_mem`) in [fetch.sv](./src/fetch.sv).
		- Make sure to change `63` in line 14 to `the number of lines - 1`.
	- Update `final_pc`, `privilege_jump_addr`, `exception_enabled`, and `interrupt_enabled` in [core.sv](./src/core.sv).
		- If you don't expect exception or interruption, you don't have to set `privilege_jump_addr`, and you have to set `exception_enabled`, and `interrupt_enabled` to zero.
	- Set `max_clocks`, `max_reg_show`, `ext_intr` and `timer_intr` in [test_core.sv](./src/test_core.sv).
		- If `max_clocks` is small, the program may not finish.
		- If you don't expect external or timer interruption, you don't have to set `ext_intr` and `timer_intr`.

3. Run the processor.
	- We use Vivado simulator commands (`xvlog`, `xelab`, and `xsim`).
	- You just have to run the following command.
		- All the `.sv` files in [src](./src) will be compiled.

	```bash
	$ cd /path/to/src
	$ make
	```


## Advanced Usage

1. Compile from Assembly

	When you make test programs, you can also write or edit RISC-V assembly code.<br>
	For example, [fib-ebreak.S](./test-programs/fib-ebreak.S) and [fib-csr.S](./test-programs/fib-csr.S) are obtained by editing [fib.S](./test-programs/fib.S).<br>
	When editing assemblies, you have to make sure that edited part should be `above` the following three lines.

	```
		.size	main, .-main
		.ident	"GCC: (GNU) 10.2.0"
		.section	.note.GNU-stack,"",@progbits
	```

	After creating test programs in assembly, edit the [Makefile](./test-programs/Makefile) by commenting out line 28 and 29.

	```
	# $(ARG).S: $(ARG).c
	# 	$(CC) $(CFLAGS) -S -o $(ARG).S $(ARG).c
	```

	Then, compile it by using `make` command.

	```bash
	$ cd /path/to/test-programs
	$ make ARG=fib-ebreak
	```


	## Files in [test-programs](./test-programs)

	- [start.S](./test-programs/start.S)
		- disable default initial routine
		- no need to edit
	- [link.ld](./test-programs/link.ld)
		- set start pc (program counter) to 0
		- no need to edit


	### Explanation when using [fib.c](./test-programs/fib.c)
	- [fib.c](./test-programs/fib.c)
		- test program in C
	- [fib.S](./test-programs/fib.S)
		- test program in assembly
		- automatically generated by `make` command
	- [fib.hex](./test-programs/fib.hex)
		- test program in hexadecimal
		- automatically generated by `make` command
	- [fib.b](./test-programs/fib.b)
		- test program in binary
		- used to test processor by editing [fetch.sv](./src/fetch.sv)
		- automatically generated by `make` command
	- [fib.dump](./test-programs/fib.dump)
		- disassembled test program (almost same as [fib.S](./test-programs/fib.S))
		- automatically generated by `make` command

	`.hex` and `.dump` are used for debugging.

2. Simulation in Vivado
	- Start Vivado
	- Create Project
		- `Create a New Vivado Project` &rarr; `Next >`
		- `Project Name` &rarr; Set any `Project Name` and `Project location` &rarr; `Next >`
		- `Project Type` &rarr; `RTL Project` (Default) &rarr; `Next >`
		- `Add Sources` &rarr; Add all `.sv` files in [src](./src) (including [test_core.sv](./src/test_core.sv)) &rarr; `Next >`
		- `Add Constraints (optional)` &rarr; `Next >`
		- `Default Part` &rarr; `Next >`
		- `New Project Summary` &rarr; `Finish`
	- Run Simulation
		- `Flow Navigator` > `PROJECT MANAGER` > `SIMULATION` > `Run Simulation` > `Run Behavioral Simulation`
		- Click `Yes` or `Save`, if there are any pop-ups
		- Add `wire` or `reg` you want to check
			- Choose modules (e.g., `_core`) in `Scope` tab
			- `wire` and `reg` in the module appear in `Objects` tab
			- Choose `wire` or `reg` in `Objects` tab
			- Drag and drop it on `Name` in the wave form area
		- `Run All` &#9654; in the top bar
		- Check the wave form

	After updating source codes, you have to follow `Run Simulation` again.

## Reference
- [riscv-gnu-toolchain](https://github.com/riscv/riscv-gnu-toolchain) (Cross Compiler)
	- to cross-compile the C programs to binary.
- [RISC-Vを使用したアセンブリ言語入門 〜2. アセンブリ言語を見てみよう〜](https://qiita.com/widedream/items/15dbe3a2203811fa7297)
	- to see how to compile programs by using `riscv-gnu-toolchain`.
- [RISC-Vクロスコンパイラで生成したバイナリを自作RISC-V上で実行する](https://kivantium.hateblo.jp/entry/2020/07/24/225016)
	- to see how to compile C programs to binary.
	- to validate the compile result.
- [RV32I, RV64I Instructions](https://msyksphinz-self.github.io/riscv-isadoc/html/rvi.html)
	- to see the detailed explanation of RISC-V ISA.
- [RISC-Vについて(CPU実験その2)](https://progrunner.hatenablog.jp/entry/2017/12/03/221829)
	- to see the detailed explanation of RISC-V ISA.
- [RV32I インストラクション・セット](https://qiita.com/zacky1972/items/48bf61bfe3ef2b8ce557)
	- to see the detailed explanation of RISC-V ISA.
- [分岐先アドレスを予測する](https://news.mynavi.jp/article/architecture-174/)
	- to see how to implement branch prediction.
- [cpuex2019-7th/core](https://github.com/cpuex2019-7th/core)
	- to see how to implement processor.
- [RISC-Vの特権命令まとめ](https://msyksphinz.hatenablog.com/entry/advent20161205)
	- to see how the CSR instructions work.
- [RISC-VでLinuxを動かすためのレジスタ制御](https://www.aps-web.jp/academy/risc-v/584/)
	- to see how the CSR instructions work.
- [RISC-Vにおけるprivilege modeの遷移(xv6-riscvを例にして)](https://cstmize.hatenablog.jp/entry/2019/09/26/RISC-V%E3%81%AB%E3%81%8A%E3%81%91%E3%82%8Bprivilege_mode%E3%81%AE%E9%81%B7%E7%A7%BB%28xv6-riscv%E3%82%92%E4%BE%8B%E3%81%AB%E3%81%97%E3%81%A6%29#fn:21)
	- to see how to handle exception and interrupt.
- [RISC-Vとx86のsystem callの内部実装の違い(xv6を例に)](https://cstmize.hatenablog.jp/entry/2019/10/01/RISC-V%E3%81%A8x86%E3%81%AEsystem_call%E3%81%AE%E5%86%85%E9%83%A8%E5%AE%9F%E8%A3%85%E3%81%AE%E9%81%95%E3%81%84%28xv6%E3%82%92%E4%BE%8B%E3%81%AB%29)
	-	to see the behavior of system call instructions.
- [xv6-riscv](https://github.com/mit-pdos/xv6-riscv) (simple OS)
	- to check exception/interrupt behavior.
- [cpuex2019-yokyo/core](https://github.com/cpuex2019-yokyo/core/)
	- to see how to implement privileged instructions.
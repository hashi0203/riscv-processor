# https://kivantium.hateblo.jp/entry/2020/07/24/225016

CC := riscv32-unknown-linux-gnu-gcc
LD := riscv32-unknown-linux-gnu-ld
OBJCOPY := riscv32-unknown-linux-gnu-objcopy
OBJDUMP := riscv32-unknown-linux-gnu-objdump
CFLAGS := -march=rv32ima -c
LINK := -L/home/nhsmt1123/opt/riscv32/riscv32-unknown-gnu/lib

main: fib.bin
	hexdump -v -e '1/4 "%08x" "\n"' fib.bin > fib.hex

fib.bin: fib.elf
	$(OBJCOPY) -O binary fib.elf fib.bin

fib.elf: fib.o start.o
	$(LD) fib.o start.o $(LINK) -Tlink.ld -nostartfiles -static -o fib.elf

start.o: start.S
	$(CC) $(CFLAGS) -o start.o start.S

fib.o: fib.c
	$(CC) $(CFLAGS) -o fib.o fib.c

disassem: fib.elf
	$(OBJDUMP) -d fib.elf > fib.S

clean:
	$(RM) *.o *.out *.hex *.bin *.elf fib.S

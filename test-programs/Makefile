# https://kivantium.hateblo.jp/entry/2020/07/24/225016

CC := riscv32-unknown-linux-gnu-gcc
LD := riscv32-unknown-linux-gnu-ld
OBJCOPY := riscv32-unknown-linux-gnu-objcopy
OBJDUMP := riscv32-unknown-linux-gnu-objdump
CFLAGS := -march=rv32ima -c

main: $(ARG).hex $(ARG).dump
	./hex2bin.sh $(ARG).hex > $(ARG).b

$(ARG).hex: $(ARG).bin
	hexdump -v -e '/4 "%08X" "\n"' $(ARG).bin > $(ARG).hex

$(ARG).bin: $(ARG).elf
	$(OBJCOPY) -O binary $(ARG).elf $(ARG).bin

$(ARG).elf: $(ARG).o start.o
	$(LD) $(ARG).o start.o -Tlink.ld -nostartfiles -static -o $(ARG).elf

start.o: start.S
	$(CC) $(CFLAGS) -o start.o start.S

$(ARG).o: $(ARG).S
	$(CC) $(CFLAGS) -o $(ARG).o $(ARG).S

$(ARG).S: $(ARG).c
	$(CC) $(CFLAGS) -S -o $(ARG).S $(ARG).c

$(ARG).dump: $(ARG).elf
	$(OBJDUMP) -d $(ARG).elf > $(ARG).dump

clean:
	$(RM) *.o *.out *.bin *.elf

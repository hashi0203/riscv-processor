# https://kivantium.hateblo.jp/entry/2020/07/24/225016

CC := riscv32-unknown-linux-gnu-gcc
LD := riscv32-unknown-linux-gnu-ld
OBJCOPY := riscv32-unknown-linux-gnu-objcopy
OBJDUMP := riscv32-unknown-linux-gnu-objdump
CFLAGS := -march=rv32ima -c
LINK := -L/home/nhsmt1123/opt/riscv32/riscv32-unknown-gnu/lib

main: $(ARG).hex $(ARG).S
	./hex2bin.sh $(ARG).hex > $(ARG).b

$(ARG).hex: $(ARG).bin
	hexdump -v -e '1/4 "%08X" "\n"' $(ARG).bin > $(ARG).hex

$(ARG).bin: $(ARG).elf
	$(OBJCOPY) -O binary $(ARG).elf $(ARG).bin

$(ARG).elf: $(ARG).o start.o
	$(LD) $(ARG).o start.o $(LINK) -Tlink.ld -nostartfiles -static -o $(ARG).elf

start.o: start.S
	$(CC) $(CFLAGS) -o start.o start.S

$(ARG).o: $(ARG).c
	$(CC) $(CFLAGS) -o $(ARG).o $(ARG).c

$(ARG).S: $(ARG).elf
	$(OBJDUMP) -d $(ARG).elf > $(ARG).S

clean:
	$(RM) *.o *.out *.bin *.elf $(ARG).S

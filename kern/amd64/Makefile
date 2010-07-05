.PHONY: all
all: kernel.elf

kernel.elf: kernel.o kernel.ld
	ld -Tkernel.ld -z max-page-size=0x1000 -o $@ kernel.o

kernel.o: kernel.asm
	nasm -felf64 -o $@ $^

.PHONY: clean
clean:
	rm -f *.o *~ kernel.elf

FILES=./build/kernel.asm.o
CC=i686-elf-gcc
CFLAGS=-ffreestanding -O0 -nostdlib
LD=i686-elf-ld

ARCHDIR?=./kernel/arch

#todo: move this into a config script
ARCH?=i686

.PHONY: build clean run
.SUFFIXES: .c .o .asm .h

build: clean ./bin/boot.bin ./bin/kernel.bin
	rm -rf ./bin/simplix.bin
	dd if=./bin/boot.bin >> ./bin/simplix.bin
	dd if=./bin/kernel.bin >> ./bin/simplix.bin
	dd if=/dev/zero bs=512 count=100 >> ./bin/simplix.bin

# This creates the main elf file with debug information.
# It then invokes gcc to turn this into a linked file.
./bin/kernel.bin: $(FILES)
	$(LD) -g -relocatable $(FILES) -o ./build/kernel.o
	$(CC) -T $(ARCHDIR)/$(ARCH)/linker.ld -o ./bin/kernel.bin $(CFLAGS) ./build/kernel.o

./bin/boot.bin: $(ARCHDIR)/$(ARCH)/boot/boot.asm
	nasm -f bin $(ARCHDIR)/$(ARCH)/boot/boot.asm -o ./bin/boot.bin

# -g option enables debug information, remove when building release
./build/kernel.asm.o: $(ARCHDIR)/$(ARCH)/kernel.asm
	nasm -f elf -g $(ARCHDIR)/$(ARCH)/kernel.asm -o ./build/kernel.asm.o

run: build
	qemu-system-x86_64 -hda ./bin/boot.bin

clean:
	rm -rf ./bin/*
	rm -rf ./build/*
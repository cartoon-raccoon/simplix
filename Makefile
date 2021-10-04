#todo: move these two into a config script
ARCH?=i686
TARGET = i686-elf

CC = $(TARGET)-gcc
LD = $(TARGET)-ld

INCLUDES = -I./kernel/arch -I./kernel/include

OBJFILES = ./build/kernel.asm.o ./build/kernel.o

LFLAGS = -ffreestanding -O0 -nostdlib
CFLAGS = -g -ffreestanding \
			-falign-jumps \
			-falign-functions \
			-falign-labels \
			-falign-loops \
			-fstrength-reduce \
			-fomit-frame-pointer \
			-finline-functions \
			-fno-builtin \
			-Wno-unused-function \
			-Werror \
			-Wno-unused-label \
			-Wno-cpp \
			-Wno-unused-parameter \
			-nostdlib \
			-nostartfiles \
			-nodefaultlibs \
			-Wall \
			-O0 \
			-Iinc

ARCHDIR?=./kernel/arch


.PHONY: build clean run
.SUFFIXES: .c .o .asm

build: ./bin/boot.bin ./bin/kernel.bin
#	mkdir ./sysroot
	rm -rf ./bin/simplix.bin
	dd if=./bin/boot.bin >> ./bin/simplix.bin
	dd if=./bin/kernel.bin >> ./bin/simplix.bin
	dd if=/dev/zero bs=512 count=100 >> ./bin/simplix.bin

# This creates the main elf file with debug information.
# It then invokes gcc to turn this into a linked file.
./bin/kernel.bin: $(OBJFILES)
	$(LD) -g -relocatable $(OBJFILES) -o ./build/kernelfull.o
	$(CC) -T $(ARCHDIR)/$(ARCH)/linker.ld -o ./bin/kernel.bin $(LFLAGS) ./build/kernelfull.o

# Boot Sector
./bin/boot.bin: $(ARCHDIR)/$(ARCH)/boot/boot.asm
	nasm -f bin $(ARCHDIR)/$(ARCH)/boot/boot.asm -o ./bin/boot.bin

# Kernel Assembly Code
./build/kernel.asm.o: $(ARCHDIR)/$(ARCH)/kernel.asm
	nasm -f elf -g $(ARCHDIR)/$(ARCH)/kernel.asm -o ./build/kernel.asm.o

# Kernel C Code
./build/kernel.o: ./kernel/kernel.c
	$(CC) $(INCLUDES) $(CFLAGS) -std=gnu99 -c ./kernel/kernel.c -o ./build/kernel.o

run: build
	qemu-system-x86_64 -hda ./bin/simplix.bin

clean:
	rm -rf ./bin/*
	rm -rf ./build/*
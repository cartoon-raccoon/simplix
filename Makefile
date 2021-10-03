FILES=./build/kernel.asm.o
CC=i686-elf-gcc
CFLAGS=-ffreestanding -O0 -nostdlib
LD=i686-elf-ld

build: ./bin/boot.bin ./bin/kernel.bin
	rm -rf ./bin/simplix.bin
	dd if=./bin/boot.bin >> ./bin/simplix.bin
	dd if=./bin/kernel.bin >> ./bin/simplix.bin
	dd if=/dev/zero bs=512 count=100 >> ./bin/simplix.bin

./bin/kernel.bin: $(FILES)
	$(LD) -g -relocatable $(FILES) -o ./build/kernel.o
	$(CC) -T ./src/linker.ld -o ./bin/kernel.bin $(CFLAGS) ./build/kernel.o

./bin/boot.bin: ./src/boot/boot.asm
	nasm -f bin ./src/boot/boot.asm -o ./bin/boot.bin

# -g option enables debug information, remove when building release
./build/kernel.asm.o: ./src/kernel.asm
	nasm -f elf -g ./src/kernel.asm -o ./build/kernel.asm.o

run: build
	qemu-system-x86_64 -hda ./bin/boot.bin

clean:
	rm -rf ./bin/*
	rm -rf ./build/*
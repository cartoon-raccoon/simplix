FILES=./build/kernel.asm.o
build: ./bin/boot.bin $(FILES)
	dd if=./bin/boot.bin >> ./bin/os.bin

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
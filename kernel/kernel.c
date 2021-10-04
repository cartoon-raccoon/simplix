#include <stdint.h>

#include <kernel.h>

void kmain()
{
    uint8_t *video_mem = (uint8_t *)(0xb8000);

    video_mem[0] = 'A';
    video_mem[1] = 1;

    for (;;);
}
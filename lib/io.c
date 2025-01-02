#ifndef __IO_C__
#define __IO_C__

// int putchar(int c) {
//     extern int putchar_stdout;
//     *(int*)(&putchar_stdout) = c;
//     return c;
// }

volatile int putchar_ready = 1;

int putchar(int c) {
    extern int putchar_stdout;
    while (!putchar_ready); // Wait until the previous character is processed
    putchar_ready = 0; // Mark as not ready
    *(int*)(&putchar_stdout) = c;
    putchar_ready = 1; // Mark as ready
    return c;
}

int puts(const char *str) {
    // while (*str) {
    //     putchar(*str++);
    // }
    for (; *str != '\0'; str = str + 1) {
        putchar(*str);
    }
    putchar('\n');
    return 0;
}

#endif

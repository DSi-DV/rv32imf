#ifndef __IO_C__
#define __IO_C__

int putchar(int c) {
    extern int putchar_stdout;
    *(int*)(&putchar_stdout) = c;
    return c;
}

int puts(const char * str) {
    while (*str) {
        putchar(*str++);
    }
    putchar('\n');
    return 0;
}

#endif

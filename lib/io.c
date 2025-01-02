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

// volatile int putchar2_ready = 1;

// int putchar2(int c) {
//     extern int putchar2_stdout;
//     while (!putchar2_ready); // Wait until the previous character is processed
//     putchar2_ready = 0; // Mark as not ready
//     *(int*)(&putchar2_stdout) = c;
//     putchar2_ready = 1; // Mark as ready
//     return c;
// }

int puts(const char *str) {
    // while (*str) {
    //     putchar(*str++);
    // }
    
    // for (; *str != '\0'; str = str + 1) {
    //     putchar(*str);
    // }

    // char c;

    // for(c = *str; c; c = *(++str)) {
    //     putchar(c);
    //     // putchar2(c);
    // }

    putchar(*(str + 0));
    putchar(*(str + 1));
    putchar(*(str + 2));
    putchar(*(str + 3));
    putchar(*(str + 4));
    putchar(*(str + 5));
    putchar(*(str + 6));
    putchar(*(str + 7));
    putchar(*(str + 8));
    putchar(*(str + 9));
    putchar(*(str + 10));

    putchar('\n');
    return 0;
}

#endif

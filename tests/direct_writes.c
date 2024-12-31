#include "io.c"

int main () {
  extern int putchar_stdout;
  *(int*)(&putchar_stdout) = 'H';
  *(int*)(&putchar_stdout) = 'e';
  *(int*)(&putchar_stdout) = 'l';
  *(int*)(&putchar_stdout) = 'l';
  *(int*)(&putchar_stdout) = 'o';
  *(int*)(&putchar_stdout) = ' ';
  *(int*)(&putchar_stdout) = 'W';
  *(int*)(&putchar_stdout) = 'o';
  *(int*)(&putchar_stdout) = 'r';
  *(int*)(&putchar_stdout) = 'l';
  *(int*)(&putchar_stdout) = 'd';
  *(int*)(&putchar_stdout) = '!';
  *(int*)(&putchar_stdout) = '\n';
  return 0;
}

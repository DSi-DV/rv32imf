.section .data

.align 2
.globl tohost
tohost: .dword 0

.align 2
.globl putchar_stdout
putchar_stdout: .dword 0

.section .text
.globl _start
_start:
    call main
    la t0, tohost
    sw a0, 0(t0)

_forever_loop:
    j _forever_loop

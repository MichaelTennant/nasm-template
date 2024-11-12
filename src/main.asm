; An educational template to follow when programming in nasm 
; ... assembly lanuage for x86_64 GNU/Linux.

; Assemble: `nasm -f elf64 <input.asm> -o <object_file.o>`
; Append the `-g -Fdwarf` flags to the command to allow using 
; ... the GDB debugger.

; Link: `gcc <output.o> -o <executable>`
; Append the `-L<library dir> -l<library name>` flags to link 
; ... with a compiled library.
; `gcc` links with glibc automatically so it does not need to 
; ... be linked.

; This template can also be linked with ld, but it requires 
; ... linking with the nessessary glibc libraries manually.
; - Link /usr/lib/crt1.o. This contains _start, the entry 
;   ... point of ELF binaries.
; - Link /usr/lib/crti.o (before libc/m) for initialization. 
; - Link /usr/lib/crtn.o (after libc/m) for finalisation.
; - Use the `-dynamic-linker /lib/ld-linux-x86-64.so.2` flags 
;   ... to set the linking to dynamic instead of static.

; Object files can be linked by appending their path to the ld 
; ... command. And shared object libraries can be linked by 
; ... appending `-l<library>` to the command. 
; For instance: /usr/lib/libc.so.2, which stores some 
; ... syscall based functions, is linked with `-lc`. And 
; ... /usr/lib/libm.so.2, which stores maths based functions, 
; ... is linked with `-lm`.

; Link using ld instead of gcc:
;   `ld <output.o> /usr/lib/crt1.o /usr/libcrti.o -lc 
;   ... /usr/libcrtn.o -o <executable>`

; This program supports PIC (Position Independant Code) and 
; ... PIE (Position Independant Executable), which can be used 
; ... by adding the `-fPIC` or `-fPIE` flags respectivley.
; See https://youtu.be/B1cXyRPu5p4 for a lecture on PIC's.

; TODO - figure out the kinks enabling PIC/PIE with ld.

default rel
global  main:   function

; From lib c (-lc)
extern __stack_chk_fail
extern puts

; Code to include function from precompiled library:
;   `extern <external function>`

; Code to include unassembled nasm file:
;   `%include <nasm file>`
; Or append `-i <nasm file>` flags to nasm command.


; EXECUTABLE CODE
section .text   align=1 exec

; Entry point
; main() -> eax: int status_code (0 = success, no errors)
main:
    ; Create the stack frame
    ; The stack frame size should always be a multiple of 16 
    ; ... to preserve stack alignment.
    push    rbp
    mov     rbp, rsp
    sub     rsp, 16     ; <stack frame size> = 16

    ; Stack frame should be created such that all values are 
    ; ... stored between rbp-8h and rbp-<stack frame size> 
    ; ... inclusive. 
    ; All fixed width values should be stored before varaible 
    ; ... width buffers on the stack frame so they arn't 
    ; ... susceptible to stack smashing. 
    ; The Stack Cookie stored at (fs+28h) should be stored 
    ; ... after all the buffers. This stored value should be 
    ; ... compared with the original Stack Cookie at the end 
    ; ... of the function to verify the return pointer hasn't 
    ; ... been stack smashed.
    ; The Stack Cookie can be omitted if stack smashing is 
    ; ... considered impossible.
    ; 
    ;           ↑
    ;         stack
    ; +---------+-------------------+ 
    ; | rbp-30h | Fixed Width Value |
    ; +---------+-------------------+
    ; | rbp-28h | Fixed Width Value |
    ; +---------+-------------------+   A diagram of a "valid"
    ; | rbp-20h |                   |   ... stack frame.
    ; | rbp-18h | Buffer            |
    ; | rbp-10h |                   |
    ; +---------+-------------------+
    ; | rbp-8h  | Stack Cookie      |
    ; +---------+-------------------+
    ;         stack
    ;           |

    ; Store Stack Cookie to check for stack smashing on the 
    ; ... return pointer at the end of the function.
    ; Stack Cookies stored at absolute address. AKA use `mov` 
    ; ... instead of `lea` when dereferencing.
    mov     rax, qword[fs:abs 0x28]
    mov     qword[rbp-0x08], rax


    ; Print "Hello, World!" using puts
    lea     rdi, qword[hello_world]
    call    puts wrt ..plt

    ; Check the return pointer hasn't been stack smashed.
    ; Can be ommited if you can garentee no stack overflows. 
    ; Stack Cookies stored at absolute address. AKA use `mov` 
    ; ... instead of `lea` when dereferencing.
    mov     rax, qword[rbp-0x08]
    sub     rax, qword[fs:abs 0x28]

    ; If the Stack Cookie hasn't been modified, assume safe 
    ; ... to return and jump to private .return block in main.
    jz      .return

    ; Do not return, stack pointer may be comprimised. 
    ; Return address may now point to malicious code, so
    ; ... returning could result in abitrary code exection. 
    call    __stack_chk_fail wrt ..plt
    
.return:
    ; Destroy the stack frame
    mov     rsp, rbp
    pop     rbp

    ; Return 0 (success, no errors)
    xor     eax, eax
    ret
; End of main function

; CONSTANTS
section .rodata noexec
hello_world:    db  "Hello, World!", 0x00

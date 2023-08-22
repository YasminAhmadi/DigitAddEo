%ifndef SYS_EQUAL
%define SYS_EQUAL
    sys_read     equ     0
    sys_write    equ     1
    sys_open     equ     2
    sys_close    equ     3
   
    sys_lseek    equ     8
    sys_create   equ     85
    sys_unlink   equ     87
     

    sys_mmap     equ     9
    sys_mumap    equ     11
    sys_brk      equ     12
   
     
    sys_exit     equ     60
   
    stdin        equ     0
    stdout       equ     1
    stderr       equ     3

 
 
    PROT_READ     equ   0x1
    PROT_WRITE    equ   0x2
    MAP_PRIVATE   equ   0x2
    MAP_ANONYMOUS equ   0x20
   
    ;access mode
    O_RDONLY    equ     0q000000
    O_WRONLY    equ     0q000001
    O_RDWR      equ     0q000002
    O_CREAT     equ     0q000100
    O_APPEND    equ     0q002000

   
; create permission mode
    sys_IRUSR     equ     0q400      ; user read permission
    sys_IWUSR     equ     0q200      ; user write permission

    NL            equ   0xA
    Space         equ   0x20

%endif
;----------------------------------------------------
newLine:
   push   rax
   mov    rax, NL
   call   putc
   pop    rax
   ret
;---------------------------------------------------------
putc:

   push   rcx
   push   rdx
   push   rsi
   push   rdi
   push   r11

   push   ax
   mov    rsi, rsp    ; points to our char
   mov    rdx, 1      ; how many characters to print
   mov    rax, sys_write
   mov    rdi, stdout
   syscall
   pop    ax

   pop    r11
   pop    rdi
   pop    rsi
   pop    rdx
   pop    rcx
   ret
;---------------------------------------------------------
writeNum:
   push   rax
   push   rbx
   push   rcx
   push   rdx

   sub    rdx, rdx
   mov    rbx, 10
   sub    rcx, rcx
   cmp    rax, 0
   jge    wAgain
   push   rax
   mov    al, '-'
   call   putc
   pop    rax
   neg    rax  

wAgain:
   cmp    rax, 9
   jle    cEnd
   div    rbx
   push   rdx
   inc    rcx
   sub    rdx, rdx
   jmp    wAgain

cEnd:
   add    al, 0x30
   call   putc
   dec    rcx
   jl     wEnd
   pop    rax
   jmp    cEnd
wEnd:
   pop    rdx
   pop    rcx
   pop    rbx
   pop    rax
   ret

;---------------------------------------------------------
getc:
   push   rcx
   push   rdx
   push   rsi
   push   rdi
   push   r11

 
   sub    rsp, 1
   mov    rsi, rsp
   mov    rdx, 1
   mov    rax, sys_read
   mov    rdi, stdin
   syscall
   mov    al, [rsi]
   add    rsp, 1

   pop    r11
   pop    rdi
   pop    rsi
   pop    rdx
   pop    rcx

   ret
;---------------------------------------------------------

readNum:
   push   rcx
   push   rbx
   push   rdx

   mov    bl,0
   mov    rdx, 0
rAgain:
   xor    rax, rax
   call   getc
   cmp    al, '-'
   jne    sAgain
   mov    bl,1  
   jmp    rAgain
sAgain:
   cmp    al, NL
   je     rEnd
   cmp    al, ' ' ;Space
   je     rEnd
   sub    rax, 0x30
   imul   rdx, 10
   add    rdx,  rax
   xor    rax, rax
   call   getc
   jmp    sAgain
rEnd:
   mov    rax, rdx
   cmp    bl, 0
   je     sEnd
   neg    rax
sEnd:  
   pop    rdx
   pop    rbx
   pop    rcx
   ret

;-------------------------------------------
printString:
    push    rax
    push    rcx
    push    rsi
    push    rdx
    push    rdi

    mov     rdi, rsi
    call    GetStrlen
    mov     rax, sys_write  
    mov     rdi, stdout
    syscall
   
    pop     rdi
    pop     rdx
    pop     rsi
    pop     rcx
    pop     rax
    ret
;-------------------------------------------
; rsi : zero terminated string start
GetStrlen:
    push    rbx
    push    rcx
    push    rax  

    xor     rcx, rcx
    not     rcx
    xor     rax, rax
    cld
    repne   scasb
    not     rcx
    lea     rdx, [rcx -1]  ; length in rdx

    pop     rax
    pop     rcx
    pop     rbx
    ret
;-------------------------------------------

section .data
        s db ' ',0
section .bss
        num: resb 4
section .text
        global _start

_start:

        call readNum
        mov [num], rax
        mov r9,[num]
        ;the number is already stored in rax
        mov rax, r9
        ;call writeNum
        ;r10 --> at each iteration we divide the number by r10 which is equal to 10
        mov r10, 10
        ;r8 --> at each iteration we check using r8 whether the digit we got is even or odd
        mov r8, 2
        ;call writeNum
        ;cmp rax,rbx
        ;r13 --> sum of odd digits at each iteration is stored at r13
        xor r13, r13
        ;r14 --> sum of even digits at each iteration is stored at r14
        xor r14, r14
        jmp loop

loop:
        mov rax,r9
        xor rdx, rdx
        div r10
        xor r11, r11
        cmp rax, r11
        ;we dividend is zero we are done but we still need to add the last remainder
        je printsol
        mov r15, rdx
        mov r9, rax
        mov rax, rdx
        xor rdx, rdx
        ;checking if it is odd or even
        div r8
        xor r11,r11
        cmp rdx, r11
        ;if the remainder is 0 then it is even ==> stored in r14
        je add14
        ;if not it is odd ==> stored in r13
        jmp add13
       
add14:
        add r14, r15
        jmp loop
add13:
        add r13, r15
        jmp loop
       
printsol:
        ;addung the last remainder in the respective sum holder
        ;if odd add r13, rdx if even add r14,rdx
        mov r15,rdx
        mov rax,rdx
        xor rdx, rdx
        div r8
        xor r11, r11
        cmp rdx, r11
        je final14
        jmp final13
final14:
        ;if we end up here, the last digit added is even but we still need to
        ;print the odd sum first
        mov rbx, r13
        mov rax, rbx
        call writeNum
        ;printing a space
        mov rsi, s
        call printString
        mov rdx, r14
        add rdx, r15
        mov rax, rdx
        call writeNum
        jmp Exit
final13:
        mov rbx, r13
        add rbx, r15
        mov rax, rbx
        call writeNum
        ;printing a space
        mov rsi, s
        call printString
        mov rdx, r14
        mov rax, rdx
        ;printing the even sum
        call writeNum
        jmp Exit
Exit:
        call newLine
        mov rax, 1
        mov rbx, 0
        int 0x80
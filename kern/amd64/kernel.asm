bits 64
default rel

;; DATA STRUCTURES
section .data
mboot_info: dq 0

; GDT
align 16
GDT:
  dw 0, 0, 0, 0        ; null desciptor
  dw 0xFFFF, 0, 0x9A00, 0xAF    ; kernel code
  dw 0xFFFF, 0, 0x9200, 0x8F    ; kernel data
  dw 0xFFFF, 0, 0xFA00, 0xAF    ; user code
  dw 0xFFFF, 0, 0xF200, 0x8F    ; user data

GDTR:
  dw (GDTR-GDT) - 1
  dq GDT

; IDT
IDTR: dw 4095
dq IDT

IDT_errcode_mask equ (1 << 8) | (1 << 10) | (1 << 11) | (1 << 12) | (1 << 13) | (1 << 14) | (1 << 17)
IDT_pushq equ 0x68
IDT_jmprel equ 0xe9

section .bss
IDT: resb 4096
IDT_stubs: resb 4096 ; dynamically-generated stubs

;; 64-BIT ENTRY POINT
section .text
bits 64

extern VMA

global _start64
_start64:
  cli

  ; load our GDT (become independent of bootstrap)
  lgdt [GDTR]

  ; set up 64-bit IRET frame to switch segments and jump to upper half
  push 0x10 ; SS = 0x10
  mov rbx, 0xffffffffc0900000 ; ESP = phys_to_virt(0x900000)
  push rbx
  push 2 ; EFLAGS = 2
  push 0x8 ; CS = 0x8
  mov rbx, qword .upperhalf ; RIP = .upperhalf
  push rbx 
  iretq

.upperhalf:

  ; save kernel arg: multiboot info
  mov rbx, qword VMA
  add rax, rbx
  mov [mboot_info], rax

  ; zero the bss
extern _sbss, _ebss
  mov rcx, qword _ebss 
  mov rdi, qword _sbss ; rdi = dest
  sub rcx, rdi         ; rcx = size
  xor eax, eax
  rep stosb

  ; init the IDT
  call init_idt
  lidt [IDTR]

  ; enable interrupts
  sti

  ; call kmain
  call kmain

;; Initialization Routines

init_idt:
  mov r9, IDT_errcode_mask
  mov ecx, 0
  lea r10, [IDT_stubs]
  lea r11, [IDT]
.l:
  ; fill IDT entry
  cmp ecx, 31
  jg .intvec
  mov al, 0x8e
  jmp .intvec2
.intvec:
  mov al, 0x8f
.intvec2:
  mov byte [r11+5], al ; type/DLP/present
  mov byte [r11+4], 0  ; rsvd, IST
  mov word [r11+2], 8 ; CS
  ;mov rbx, r10
  mov rbx, qword vec_common
  mov word [r11], bx ; offset 0-15
  shr rbx, 16
  mov word [r11+6], bx ; offset 16-31
  shr rbx, 16
  mov dword [r11+8], ebx ; offset 32-63
  mov dword [r11+12], 0 ; rsvd
  add r11, 16

   ; generate stub: push qword 0 if no errcode, push qword vector, jmprel to vec_common
  cmp ecx, 31
  jg .noerrcode
  bt r9, rcx
  jc .errcode
.noerrcode:
  mov byte [r10], IDT_pushq
  mov dword [r10+1], 0
  add r10, 5
.errcode:
  mov byte [r10], IDT_pushq
  mov dword [r10+1], ecx
  add r10, 5
  mov byte [r10], IDT_jmprel
  add r10, 5
  mov rbx, r10
  mov rdx, qword vec_common
  sub rdx, rbx
  mov [r10-4], edx

  inc ecx
  cmp ecx, 255
  jle .l

  ret

init_syscall:
  ; set LSTAR to syscall entry point
  mov ecx, 0xc0000082
  mov edx, 0xffffffff
  mov rax, qword _syscall
  wrmsr

  ; enable syscall
  mov ecx, 0xc0000080
  rdmsr
  or eax, 1
  wrmsr

  ret

_syscall:
  sysret

;; Vectors

; expects on stack (all qwords): ss rsp eflags cs rip errcode vecnum
vec_common:
  push r15
  push r14
  push r13
  push r12
  push r11
  push r10
  push r9
  push r8
  push rbp
  push rdi
  push rsi
  push rdx
  push rcx
  push rbx
  push rax

  mov rdi, rsp
  mov rax, 15
  not rax
  and rsp, rax
  call vec
  mov rsp, rax

  pop rax
  pop rbx
  pop rcx
  pop rdx
  pop rsi
  pop rdi
  pop rbp
  pop r8
  pop r9
  pop r10
  pop r11
  pop r12
  pop r13
  pop r14
  pop r15
  iret

vec:
  cli
  jmp $
  ret

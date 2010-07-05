bits 32

section .bootstrap

;; Multiboot header
align 4
dd 0x1badb002
dd 2
dd 0 - (0x1badb002 + 2)

mboot_info: dd 0
mboot_valid: dd 0

;; ENTRY POINT
global _start
_start:
  cli

  ; save multiboot parameters
  mov [mboot_info], ebx
  cmp eax, 0x2badb002
  sete [mboot_valid]

  ; load the GDT
  lgdt [GDTR]
  jmp 0x10:.new_cs
.new_cs:

 ; set up new regs
  mov eax, 0x08
  mov ds, ax
  mov es, ax
  mov fs, ax
  mov gs, ax
  mov ss, ax

  ; init stack
  mov esp, 0x90000
  mov ebp, esp

  ; zero the bss
extern _sbss_phys, _ebss_phys
  mov ecx, _ebss_phys
  mov edi, _sbss_phys
  sub ecx, edi
  shr ecx, 2
  xor eax, eax
  rep stosd

  ; turn on PAE
  mov eax, cr4
  or eax, 0x20 ; PAE
  mov cr4, eax

  ; set up page tables for one large 1GB page at end of address space (0xffffffff_c0000000)
  mov edi, pagetab1
  mov ecx, 1024
  xor eax, eax
  rep stosd
  mov edi, pagetab2
  mov ecx, 1024
  xor eax, eax
  rep stosd

  mov eax, pagetab2
  or eax, 3 ; writable, present
  mov dword [pagetab1 + 4088], eax
  mov dword [pagetab1 + 0], eax
  mov dword [pagetab2 + 4088], 0 | 3 | 0x80 ; 1GB page at phys addr 0: PS, WR, P bits
  mov dword [pagetab2 + 0], 0 | 3 | 0x80

  mov eax, pagetab1
  mov cr3, eax

  mov ecx, 0xc0000080 ; EFER
  rdmsr
  or eax, 0x100 ; long mode
  wrmsr

  mov eax, cr0
  or eax, 0x80000000 ; paging enable
  mov cr0, eax

  mov byte [0xb8000], '!'
  hlt

  jmp 0x18:.trampoline

bits 64
.trampoline:
;  jmp _start64
jmp $

bits 32
;; GDT
align 16
GDT:
  dw 0, 0, 0, 0        ; null desciptor
  dw 0xFFFF, 0, 0x9200, 0x8F    ; flat data desciptor
  dw 0xFFFF, 0, 0x9A00, 0xCF    ; 32-bit code desciptor
  dw 0xFFFF, 0, 0x9A00, 0xAF    ; 64-bit code desciptor

GDTR:
  dw 31
  dq GDT

;; page tables
align 4096
pagetab1: times 4096 db 0
pagetab2: times 4096 db 0

%if 0

;; 64-BIT ENTRY POINT
section .text
bits 64

extern VMA

_start64:

  mov rax, 'L O N G '
  mov rbx, VMA
  add rbx, 0xb8000
  mov qword [rbx], rax
  cli
  hlt


;; Utility Functions

global bzero
bzero: ; rdi = dest, rsi = size (bytes)

  ; unrolled main loop: 64 bytes per loop
  
.preloop: ; pre-loop: align dest to 64-byte boundary
  mov rax, rdi
  and rax, 63
  jz .preloop_exit ; if (dest & 0x3f == 0) break
  or rsi, rsi
  jz .preloop_exit ; if (count == 0) break
  mov byte [rdi], 0
  inc rdi
  dec rsi
  jmp .preloop
.preloop_exit:

.loop:
  cmp rsi, 64
  jl .loop_exit
  mov qword [rdi], 0
  mov qword [rdi+8], 0
  mov qword [rdi+16], 0
  mov qword [rdi+24], 0
  mov qword [rdi+32], 0
  mov qword [rdi+40], 0
  mov qword [rdi+48], 0
  mov qword [rdi+56], 0
  add rdi, 64
  sub rsi, 64
  jmp .loop
.loop_exit:
  
.postloop: ; post-loop: remaining count
  or rsi, rsi
  jz .postloop_exit
  mov byte [rdi], 0
  inc rdi
  dec rsi
  jmp .postloop
.postloop_exit:

  xor eax, eax
  ret

%endif

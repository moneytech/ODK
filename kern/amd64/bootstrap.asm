bits 32

section .text

;; Multiboot header
align 4
dd 0x1badb002
dd 2
dd 0 - (0x1badb002 + 2)

mboot_info: dd 0
mboot_valid: dd 0
kern_image: dd 0
kern_entry: dq 0

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

  ; load the kernel: first, find the mboot module

  cmp dword [mboot_valid], 1
  jne load_error
  mov edx, [mboot_info]
  mov eax, [edx+20] ; module count
  cmp eax, 1
  jl load_error
  mov eax, [edx+24] ; module info array
  mov edx, [eax+0] ; mod_start for module 0
  mov [kern_image], edx

  ; now, load the elf image at edx
  cmp dword [edx], `\x7FELF` ; verify magic
  jne load_error
  cmp byte [edx+4], 2 ; verify class (ELF64)
  jne load_error
  cmp word [edx+16], 2 ; verify type (executable)
  mov esi, [edx+32] ; get program header offset
  add esi, edx ; get program header addr
  xor ecx, ecx
  mov cx, word [edx+56] ; get number of program header entries
.phloop: ; for each program header entry...
  cmp word [esi], 1 ; type 1 is loadable segment
  jne .phloop_skip
  push esi
  push ecx
  mov ecx, [esi+32] ; size in file
  mov edi, [esi+24] ; physical (load) address
  mov esi, [esi+8]  ; file offset
  add esi, edx      ; get address in image
  rep movsb         ; copy to load address
  pop ecx
  pop esi
.phloop_skip:
  xor eax, eax
  mov ax, word [edx+54]
  add esi, eax ; add size of PH entry
  loop .phloop

  ; find the entry point
  mov eax, [edx+24]
  sub eax, 0xc0000000
  mov [kern_entry], eax

  ; zero the page tables
  mov edi, pagetab1
  mov ecx, 1024
  xor eax, eax
  rep stosd
  mov edi, pagetab2
  mov ecx, 1024
  xor eax, eax
  rep stosd
  mov edi, pagetab3
  mov ecx, 1024
  xor eax, eax
  rep stosd

  ; set up the PML4: one PDP, shared by upper and lower half
  mov eax, pagetab2
  or eax, 3 ; writable, present
  mov dword [pagetab1 + 4088], eax
  mov dword [pagetab1 + 0], eax
  ; set up the PDP: one pagedir, shared by upper and lower half
  mov eax, pagetab3
  or eax, 3 ; writable, present
  mov dword [pagetab2 + 4088], eax
  mov dword [pagetab2 + 0], eax
  ; set up 2M pages in the page dir
  mov edi, pagetab3
  mov eax, 0x83 ; writable, present, page size bit
  mov ecx, 512
.pagetab3_loop:
  mov [edi], eax
  mov dword [edi+4], 0
  add edi, 8
  add eax, 0x200000
  loop .pagetab3_loop

  mov eax, pagetab1
  mov cr3, eax

  ; turn on the three mode bits for long mode (64-bit mode):
  ; page address extensions, long mode, and paging (in that order)
  ; (see IA-32e manual Vol 3b)

  ; turn on PAE
  mov eax, cr4
  or eax, 0x20 ; PAE
  mov cr4, eax

  ; turn on long mode bit
  mov ecx, 0xc0000080 ; EFER
  rdmsr
  or eax, 0x100
  wrmsr

  ; turn on paging bit
  mov eax, cr0
  or eax, 0x80000000 ; paging enable
  mov cr0, eax

  ; jump into kernel
  push dword 2
  push dword 0x18
  push dword [kern_entry]
  iretd

load_error:
  mov al, '!'
  mov edi, 0xb8000
  mov ecx, 80*25
.l:
  stosb
  inc edi
  loop .l
.done:
  jmp .done

;; GDT
align 16
GDT:
  dw 0, 0, 0, 0        ; null desciptor
  dw 0xFFFF, 0, 0x9200, 0x8F    ; flat data desciptor
  dw 0xFFFF, 0, 0x9A00, 0xCF    ; 32-bit code desciptor
  dw 0xFFFF, 0, 0x9A00, 0xAF    ; 64-bit code desciptor

GDTR:
  dw 31
  dd GDT
  dd 0

;; page tables
align 4096
pagetab1: times 4096 db 0
pagetab2: times 4096 db 0
pagetab3: times 4096 db 0

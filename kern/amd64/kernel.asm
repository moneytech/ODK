;; 64-BIT ENTRY POINT
section .text
bits 64

extern VMA

global _start64
_start64:

  mov rbx, .upperhalf
  push rbx
  ret

.upperhalf:
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



#ifndef _KERNEL_H_
#define _KERNEL_H_

extern void set_cr3(addr_t cr3);
extern void bzero(void *p, u64 size);
extern void new_ctx(void *kstack, void *ustack, void *uip, void *param);

extern 

#endif

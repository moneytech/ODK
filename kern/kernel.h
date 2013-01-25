#ifndef _KERNEL_H_
#define _KERNEL_H_

/**************** kernel low-level routines: arch-dependent *****************/

/** create a new thread context with the given kernel stack pointer,
 *  user stack pointer, user instruction pointer. keep state in the
 *  given context block. */
void arch_new_ctx(void *kstack, void *ustack, void *uip);

typedef int intflags_t;

/** disable interrupts, returning the interrupt flag status prior to this call. */
intflags_t kern_disable_ints();
/** restore interrupt flag. */
void       kern_restore_ints(intflags_t flags);

/************ arch-independent kernel: entry points ***********/

/** kernel main entry point. */
void kmain();

/** kernel interrupt/syscall/trap entry point. Takes kernel stack pointer
 * for the current thread (as we would save it to restore later); returns
 * a stack pointer to return to. */
void *vec(void *sp);

#endif

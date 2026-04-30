  .section .init
  .globl _start
  .extern main
  .extern __bss_start
  .extern __bss_end
  .extern __stack_top

_start:
  la sp, __stack_top
  la t0, __bss_start
  la t1, __bss_end

clear_bss:
  bgeu t0, t1, call_main
  sd zero, 0(t0)
  addi t0, t0, 8
  j clear_bss

call_main:
  call main

hang:
  wfi
  j hang

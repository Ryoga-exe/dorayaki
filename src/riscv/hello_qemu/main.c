#include <stdint.h>

#define UART0_BASE 0x10000000UL
#define UART_THR 0x00UL
#define UART_LSR 0x05UL
#define UART_LSR_THRE 0x20U

#define SIFIVE_TEST_BASE 0x00100000UL
#define SIFIVE_TEST_PASS 0x5555U

static inline void mmio_write8(uintptr_t address, uint8_t value) {
  *(volatile uint8_t *)address = value;
}

static inline uint8_t mmio_read8(uintptr_t address) {
  return *(volatile uint8_t *)address;
}

static inline void mmio_write32(uintptr_t address, uint32_t value) {
  *(volatile uint32_t *)address = value;
}

static void uart_putc(char ch) {
  while ((mmio_read8(UART0_BASE + UART_LSR) & UART_LSR_THRE) == 0U) {
  }

  mmio_write8(UART0_BASE + UART_THR, (uint8_t)ch);
}

static void uart_puts(const char *message) {
  while (*message != '\0') {
    if (*message == '\n') {
      uart_putc('\r');
    }

    uart_putc(*message);
    ++message;
  }
}

static void qemu_exit_success(void) {
  mmio_write32(SIFIVE_TEST_BASE, SIFIVE_TEST_PASS);

  for (;;) {
    __asm__ volatile("wfi");
  }
}

int main(void) {
  uart_puts("Hello, world from dorayaki on QEMU!\n");
  qemu_exit_success();
  return 0;
}

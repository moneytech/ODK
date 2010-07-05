OUTPUT_FORMAT(elf64-x86-64)
ENTRY(_start)

SECTIONS
{
  VMA = 0xffffffffc0000000;

  . = 0x100000;
  .bootstrap :
  {
    *(.bootstrap)
  }

	.text : AT(ADDR(.text) - VMA)
	{
		_stext = .;
		*(.text)
		_etext = .;
	}
	.rodata : AT(ADDR(.rodata) - VMA)
	{
		_srodata = .;
		*(.rodata)
		_erodata = .;
	}
	.data : AT(ADDR(.data) - VMA)
	{
		_sdata = .;
		*(.data)
		_edata = .;
	}
	.bss : AT(ADDR(.bss) - VMA)
	{
		_sbss = .;
    _sbss_phys = _sbss - VMA;
		*(.bss)
		*(COMMON)
		_ebss = .;
    _ebss_phys = _ebss - VMA;
	}
}

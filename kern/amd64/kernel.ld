OUTPUT_FORMAT(elf64-x86-64)
ENTRY(_start64)

SECTIONS
{
  VMA = 0xffffffffc0000000;

  . = VMA + 0x200000;

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
		*(.bss)
		*(COMMON)
		_ebss = .;
	}
}

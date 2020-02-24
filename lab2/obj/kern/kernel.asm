
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4                   	.byte 0xe4

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 40 11 00       	mov    $0x114000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 40 11 f0       	mov    $0xf0114000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/kclock.h>


void
i386_init(void)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	83 ec 0c             	sub    $0xc,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100046:	b8 60 69 11 f0       	mov    $0xf0116960,%eax
f010004b:	2d 00 63 11 f0       	sub    $0xf0116300,%eax
f0100050:	50                   	push   %eax
f0100051:	6a 00                	push   $0x0
f0100053:	68 00 63 11 f0       	push   $0xf0116300
f0100058:	e8 c1 31 00 00       	call   f010321e <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 96 04 00 00       	call   f01004f8 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 c0 36 10 f0       	push   $0xf01036c0
f010006f:	e8 f1 26 00 00       	call   f0102765 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 43 10 00 00       	call   f01010bc <mem_init>
f0100079:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f010007c:	83 ec 0c             	sub    $0xc,%esp
f010007f:	6a 00                	push   $0x0
f0100081:	e8 0e 07 00 00       	call   f0100794 <monitor>
f0100086:	83 c4 10             	add    $0x10,%esp
f0100089:	eb f1                	jmp    f010007c <i386_init+0x3c>

f010008b <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f010008b:	55                   	push   %ebp
f010008c:	89 e5                	mov    %esp,%ebp
f010008e:	56                   	push   %esi
f010008f:	53                   	push   %ebx
f0100090:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100093:	83 3d 64 69 11 f0 00 	cmpl   $0x0,0xf0116964
f010009a:	75 37                	jne    f01000d3 <_panic+0x48>
		goto dead;
	panicstr = fmt;
f010009c:	89 35 64 69 11 f0    	mov    %esi,0xf0116964

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f01000a2:	fa                   	cli    
f01000a3:	fc                   	cld    

	va_start(ap, fmt);
f01000a4:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000a7:	83 ec 04             	sub    $0x4,%esp
f01000aa:	ff 75 0c             	pushl  0xc(%ebp)
f01000ad:	ff 75 08             	pushl  0x8(%ebp)
f01000b0:	68 db 36 10 f0       	push   $0xf01036db
f01000b5:	e8 ab 26 00 00       	call   f0102765 <cprintf>
	vcprintf(fmt, ap);
f01000ba:	83 c4 08             	add    $0x8,%esp
f01000bd:	53                   	push   %ebx
f01000be:	56                   	push   %esi
f01000bf:	e8 7b 26 00 00       	call   f010273f <vcprintf>
	cprintf("\n");
f01000c4:	c7 04 24 05 46 10 f0 	movl   $0xf0104605,(%esp)
f01000cb:	e8 95 26 00 00       	call   f0102765 <cprintf>
	va_end(ap);
f01000d0:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000d3:	83 ec 0c             	sub    $0xc,%esp
f01000d6:	6a 00                	push   $0x0
f01000d8:	e8 b7 06 00 00       	call   f0100794 <monitor>
f01000dd:	83 c4 10             	add    $0x10,%esp
f01000e0:	eb f1                	jmp    f01000d3 <_panic+0x48>

f01000e2 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01000e2:	55                   	push   %ebp
f01000e3:	89 e5                	mov    %esp,%ebp
f01000e5:	53                   	push   %ebx
f01000e6:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f01000e9:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f01000ec:	ff 75 0c             	pushl  0xc(%ebp)
f01000ef:	ff 75 08             	pushl  0x8(%ebp)
f01000f2:	68 f3 36 10 f0       	push   $0xf01036f3
f01000f7:	e8 69 26 00 00       	call   f0102765 <cprintf>
	vcprintf(fmt, ap);
f01000fc:	83 c4 08             	add    $0x8,%esp
f01000ff:	53                   	push   %ebx
f0100100:	ff 75 10             	pushl  0x10(%ebp)
f0100103:	e8 37 26 00 00       	call   f010273f <vcprintf>
	cprintf("\n");
f0100108:	c7 04 24 05 46 10 f0 	movl   $0xf0104605,(%esp)
f010010f:	e8 51 26 00 00       	call   f0102765 <cprintf>
	va_end(ap);
}
f0100114:	83 c4 10             	add    $0x10,%esp
f0100117:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010011a:	c9                   	leave  
f010011b:	c3                   	ret    

f010011c <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f010011c:	55                   	push   %ebp
f010011d:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010011f:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100124:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100125:	a8 01                	test   $0x1,%al
f0100127:	74 0b                	je     f0100134 <serial_proc_data+0x18>
f0100129:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010012e:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f010012f:	0f b6 c0             	movzbl %al,%eax
f0100132:	eb 05                	jmp    f0100139 <serial_proc_data+0x1d>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100134:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f0100139:	5d                   	pop    %ebp
f010013a:	c3                   	ret    

f010013b <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010013b:	55                   	push   %ebp
f010013c:	89 e5                	mov    %esp,%ebp
f010013e:	53                   	push   %ebx
f010013f:	83 ec 04             	sub    $0x4,%esp
f0100142:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100144:	eb 2b                	jmp    f0100171 <cons_intr+0x36>
		if (c == 0)
f0100146:	85 c0                	test   %eax,%eax
f0100148:	74 27                	je     f0100171 <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f010014a:	8b 0d 24 65 11 f0    	mov    0xf0116524,%ecx
f0100150:	8d 51 01             	lea    0x1(%ecx),%edx
f0100153:	89 15 24 65 11 f0    	mov    %edx,0xf0116524
f0100159:	88 81 20 63 11 f0    	mov    %al,-0xfee9ce0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f010015f:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100165:	75 0a                	jne    f0100171 <cons_intr+0x36>
			cons.wpos = 0;
f0100167:	c7 05 24 65 11 f0 00 	movl   $0x0,0xf0116524
f010016e:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f0100171:	ff d3                	call   *%ebx
f0100173:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100176:	75 ce                	jne    f0100146 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f0100178:	83 c4 04             	add    $0x4,%esp
f010017b:	5b                   	pop    %ebx
f010017c:	5d                   	pop    %ebp
f010017d:	c3                   	ret    

f010017e <kbd_proc_data>:
f010017e:	ba 64 00 00 00       	mov    $0x64,%edx
f0100183:	ec                   	in     (%dx),%al
	int c;
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
f0100184:	a8 01                	test   $0x1,%al
f0100186:	0f 84 f8 00 00 00    	je     f0100284 <kbd_proc_data+0x106>
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
f010018c:	a8 20                	test   $0x20,%al
f010018e:	0f 85 f6 00 00 00    	jne    f010028a <kbd_proc_data+0x10c>
f0100194:	ba 60 00 00 00       	mov    $0x60,%edx
f0100199:	ec                   	in     (%dx),%al
f010019a:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f010019c:	3c e0                	cmp    $0xe0,%al
f010019e:	75 0d                	jne    f01001ad <kbd_proc_data+0x2f>
		// E0 escape character
		shift |= E0ESC;
f01001a0:	83 0d 00 63 11 f0 40 	orl    $0x40,0xf0116300
		return 0;
f01001a7:	b8 00 00 00 00       	mov    $0x0,%eax
f01001ac:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01001ad:	55                   	push   %ebp
f01001ae:	89 e5                	mov    %esp,%ebp
f01001b0:	53                   	push   %ebx
f01001b1:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f01001b4:	84 c0                	test   %al,%al
f01001b6:	79 36                	jns    f01001ee <kbd_proc_data+0x70>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01001b8:	8b 0d 00 63 11 f0    	mov    0xf0116300,%ecx
f01001be:	89 cb                	mov    %ecx,%ebx
f01001c0:	83 e3 40             	and    $0x40,%ebx
f01001c3:	83 e0 7f             	and    $0x7f,%eax
f01001c6:	85 db                	test   %ebx,%ebx
f01001c8:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01001cb:	0f b6 d2             	movzbl %dl,%edx
f01001ce:	0f b6 82 60 38 10 f0 	movzbl -0xfefc7a0(%edx),%eax
f01001d5:	83 c8 40             	or     $0x40,%eax
f01001d8:	0f b6 c0             	movzbl %al,%eax
f01001db:	f7 d0                	not    %eax
f01001dd:	21 c8                	and    %ecx,%eax
f01001df:	a3 00 63 11 f0       	mov    %eax,0xf0116300
		return 0;
f01001e4:	b8 00 00 00 00       	mov    $0x0,%eax
f01001e9:	e9 a4 00 00 00       	jmp    f0100292 <kbd_proc_data+0x114>
	} else if (shift & E0ESC) {
f01001ee:	8b 0d 00 63 11 f0    	mov    0xf0116300,%ecx
f01001f4:	f6 c1 40             	test   $0x40,%cl
f01001f7:	74 0e                	je     f0100207 <kbd_proc_data+0x89>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f01001f9:	83 c8 80             	or     $0xffffff80,%eax
f01001fc:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f01001fe:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100201:	89 0d 00 63 11 f0    	mov    %ecx,0xf0116300
	}

	shift |= shiftcode[data];
f0100207:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f010020a:	0f b6 82 60 38 10 f0 	movzbl -0xfefc7a0(%edx),%eax
f0100211:	0b 05 00 63 11 f0    	or     0xf0116300,%eax
f0100217:	0f b6 8a 60 37 10 f0 	movzbl -0xfefc8a0(%edx),%ecx
f010021e:	31 c8                	xor    %ecx,%eax
f0100220:	a3 00 63 11 f0       	mov    %eax,0xf0116300

	c = charcode[shift & (CTL | SHIFT)][data];
f0100225:	89 c1                	mov    %eax,%ecx
f0100227:	83 e1 03             	and    $0x3,%ecx
f010022a:	8b 0c 8d 40 37 10 f0 	mov    -0xfefc8c0(,%ecx,4),%ecx
f0100231:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0100235:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100238:	a8 08                	test   $0x8,%al
f010023a:	74 1b                	je     f0100257 <kbd_proc_data+0xd9>
		if ('a' <= c && c <= 'z')
f010023c:	89 da                	mov    %ebx,%edx
f010023e:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100241:	83 f9 19             	cmp    $0x19,%ecx
f0100244:	77 05                	ja     f010024b <kbd_proc_data+0xcd>
			c += 'A' - 'a';
f0100246:	83 eb 20             	sub    $0x20,%ebx
f0100249:	eb 0c                	jmp    f0100257 <kbd_proc_data+0xd9>
		else if ('A' <= c && c <= 'Z')
f010024b:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f010024e:	8d 4b 20             	lea    0x20(%ebx),%ecx
f0100251:	83 fa 19             	cmp    $0x19,%edx
f0100254:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100257:	f7 d0                	not    %eax
f0100259:	a8 06                	test   $0x6,%al
f010025b:	75 33                	jne    f0100290 <kbd_proc_data+0x112>
f010025d:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100263:	75 2b                	jne    f0100290 <kbd_proc_data+0x112>
		cprintf("Rebooting!\n");
f0100265:	83 ec 0c             	sub    $0xc,%esp
f0100268:	68 0d 37 10 f0       	push   $0xf010370d
f010026d:	e8 f3 24 00 00       	call   f0102765 <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100272:	ba 92 00 00 00       	mov    $0x92,%edx
f0100277:	b8 03 00 00 00       	mov    $0x3,%eax
f010027c:	ee                   	out    %al,(%dx)
f010027d:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100280:	89 d8                	mov    %ebx,%eax
f0100282:	eb 0e                	jmp    f0100292 <kbd_proc_data+0x114>
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
f0100284:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100289:	c3                   	ret    
	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
		return -1;
f010028a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010028f:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100290:	89 d8                	mov    %ebx,%eax
}
f0100292:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100295:	c9                   	leave  
f0100296:	c3                   	ret    

f0100297 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100297:	55                   	push   %ebp
f0100298:	89 e5                	mov    %esp,%ebp
f010029a:	57                   	push   %edi
f010029b:	56                   	push   %esi
f010029c:	53                   	push   %ebx
f010029d:	83 ec 1c             	sub    $0x1c,%esp
f01002a0:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01002a2:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002a7:	be fd 03 00 00       	mov    $0x3fd,%esi
f01002ac:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002b1:	eb 09                	jmp    f01002bc <cons_putc+0x25>
f01002b3:	89 ca                	mov    %ecx,%edx
f01002b5:	ec                   	in     (%dx),%al
f01002b6:	ec                   	in     (%dx),%al
f01002b7:	ec                   	in     (%dx),%al
f01002b8:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f01002b9:	83 c3 01             	add    $0x1,%ebx
f01002bc:	89 f2                	mov    %esi,%edx
f01002be:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01002bf:	a8 20                	test   $0x20,%al
f01002c1:	75 08                	jne    f01002cb <cons_putc+0x34>
f01002c3:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01002c9:	7e e8                	jle    f01002b3 <cons_putc+0x1c>
f01002cb:	89 f8                	mov    %edi,%eax
f01002cd:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002d0:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01002d5:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01002d6:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002db:	be 79 03 00 00       	mov    $0x379,%esi
f01002e0:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002e5:	eb 09                	jmp    f01002f0 <cons_putc+0x59>
f01002e7:	89 ca                	mov    %ecx,%edx
f01002e9:	ec                   	in     (%dx),%al
f01002ea:	ec                   	in     (%dx),%al
f01002eb:	ec                   	in     (%dx),%al
f01002ec:	ec                   	in     (%dx),%al
f01002ed:	83 c3 01             	add    $0x1,%ebx
f01002f0:	89 f2                	mov    %esi,%edx
f01002f2:	ec                   	in     (%dx),%al
f01002f3:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01002f9:	7f 04                	jg     f01002ff <cons_putc+0x68>
f01002fb:	84 c0                	test   %al,%al
f01002fd:	79 e8                	jns    f01002e7 <cons_putc+0x50>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002ff:	ba 78 03 00 00       	mov    $0x378,%edx
f0100304:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f0100308:	ee                   	out    %al,(%dx)
f0100309:	ba 7a 03 00 00       	mov    $0x37a,%edx
f010030e:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100313:	ee                   	out    %al,(%dx)
f0100314:	b8 08 00 00 00       	mov    $0x8,%eax
f0100319:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f010031a:	89 fa                	mov    %edi,%edx
f010031c:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100322:	89 f8                	mov    %edi,%eax
f0100324:	80 cc 07             	or     $0x7,%ah
f0100327:	85 d2                	test   %edx,%edx
f0100329:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f010032c:	89 f8                	mov    %edi,%eax
f010032e:	0f b6 c0             	movzbl %al,%eax
f0100331:	83 f8 09             	cmp    $0x9,%eax
f0100334:	74 74                	je     f01003aa <cons_putc+0x113>
f0100336:	83 f8 09             	cmp    $0x9,%eax
f0100339:	7f 0a                	jg     f0100345 <cons_putc+0xae>
f010033b:	83 f8 08             	cmp    $0x8,%eax
f010033e:	74 14                	je     f0100354 <cons_putc+0xbd>
f0100340:	e9 99 00 00 00       	jmp    f01003de <cons_putc+0x147>
f0100345:	83 f8 0a             	cmp    $0xa,%eax
f0100348:	74 3a                	je     f0100384 <cons_putc+0xed>
f010034a:	83 f8 0d             	cmp    $0xd,%eax
f010034d:	74 3d                	je     f010038c <cons_putc+0xf5>
f010034f:	e9 8a 00 00 00       	jmp    f01003de <cons_putc+0x147>
	case '\b':
		if (crt_pos > 0) {
f0100354:	0f b7 05 28 65 11 f0 	movzwl 0xf0116528,%eax
f010035b:	66 85 c0             	test   %ax,%ax
f010035e:	0f 84 e6 00 00 00    	je     f010044a <cons_putc+0x1b3>
			crt_pos--;
f0100364:	83 e8 01             	sub    $0x1,%eax
f0100367:	66 a3 28 65 11 f0    	mov    %ax,0xf0116528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f010036d:	0f b7 c0             	movzwl %ax,%eax
f0100370:	66 81 e7 00 ff       	and    $0xff00,%di
f0100375:	83 cf 20             	or     $0x20,%edi
f0100378:	8b 15 2c 65 11 f0    	mov    0xf011652c,%edx
f010037e:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100382:	eb 78                	jmp    f01003fc <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100384:	66 83 05 28 65 11 f0 	addw   $0x50,0xf0116528
f010038b:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f010038c:	0f b7 05 28 65 11 f0 	movzwl 0xf0116528,%eax
f0100393:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100399:	c1 e8 16             	shr    $0x16,%eax
f010039c:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010039f:	c1 e0 04             	shl    $0x4,%eax
f01003a2:	66 a3 28 65 11 f0    	mov    %ax,0xf0116528
f01003a8:	eb 52                	jmp    f01003fc <cons_putc+0x165>
		break;
	case '\t':
		cons_putc(' ');
f01003aa:	b8 20 00 00 00       	mov    $0x20,%eax
f01003af:	e8 e3 fe ff ff       	call   f0100297 <cons_putc>
		cons_putc(' ');
f01003b4:	b8 20 00 00 00       	mov    $0x20,%eax
f01003b9:	e8 d9 fe ff ff       	call   f0100297 <cons_putc>
		cons_putc(' ');
f01003be:	b8 20 00 00 00       	mov    $0x20,%eax
f01003c3:	e8 cf fe ff ff       	call   f0100297 <cons_putc>
		cons_putc(' ');
f01003c8:	b8 20 00 00 00       	mov    $0x20,%eax
f01003cd:	e8 c5 fe ff ff       	call   f0100297 <cons_putc>
		cons_putc(' ');
f01003d2:	b8 20 00 00 00       	mov    $0x20,%eax
f01003d7:	e8 bb fe ff ff       	call   f0100297 <cons_putc>
f01003dc:	eb 1e                	jmp    f01003fc <cons_putc+0x165>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f01003de:	0f b7 05 28 65 11 f0 	movzwl 0xf0116528,%eax
f01003e5:	8d 50 01             	lea    0x1(%eax),%edx
f01003e8:	66 89 15 28 65 11 f0 	mov    %dx,0xf0116528
f01003ef:	0f b7 c0             	movzwl %ax,%eax
f01003f2:	8b 15 2c 65 11 f0    	mov    0xf011652c,%edx
f01003f8:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	// if the screen is full
	if (crt_pos >= CRT_SIZE) {
f01003fc:	66 81 3d 28 65 11 f0 	cmpw   $0x7cf,0xf0116528
f0100403:	cf 07 
f0100405:	76 43                	jbe    f010044a <cons_putc+0x1b3>
		int i;
		// move all the content one line above
		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100407:	a1 2c 65 11 f0       	mov    0xf011652c,%eax
f010040c:	83 ec 04             	sub    $0x4,%esp
f010040f:	68 00 0f 00 00       	push   $0xf00
f0100414:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010041a:	52                   	push   %edx
f010041b:	50                   	push   %eax
f010041c:	e8 4a 2e 00 00       	call   f010326b <memmove>
		// clear the last line and set the cursor
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100421:	8b 15 2c 65 11 f0    	mov    0xf011652c,%edx
f0100427:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f010042d:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f0100433:	83 c4 10             	add    $0x10,%esp
f0100436:	66 c7 00 20 07       	movw   $0x720,(%eax)
f010043b:	83 c0 02             	add    $0x2,%eax
	if (crt_pos >= CRT_SIZE) {
		int i;
		// move all the content one line above
		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		// clear the last line and set the cursor
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010043e:	39 d0                	cmp    %edx,%eax
f0100440:	75 f4                	jne    f0100436 <cons_putc+0x19f>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100442:	66 83 2d 28 65 11 f0 	subw   $0x50,0xf0116528
f0100449:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f010044a:	8b 0d 30 65 11 f0    	mov    0xf0116530,%ecx
f0100450:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100455:	89 ca                	mov    %ecx,%edx
f0100457:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100458:	0f b7 1d 28 65 11 f0 	movzwl 0xf0116528,%ebx
f010045f:	8d 71 01             	lea    0x1(%ecx),%esi
f0100462:	89 d8                	mov    %ebx,%eax
f0100464:	66 c1 e8 08          	shr    $0x8,%ax
f0100468:	89 f2                	mov    %esi,%edx
f010046a:	ee                   	out    %al,(%dx)
f010046b:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100470:	89 ca                	mov    %ecx,%edx
f0100472:	ee                   	out    %al,(%dx)
f0100473:	89 d8                	mov    %ebx,%eax
f0100475:	89 f2                	mov    %esi,%edx
f0100477:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f0100478:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010047b:	5b                   	pop    %ebx
f010047c:	5e                   	pop    %esi
f010047d:	5f                   	pop    %edi
f010047e:	5d                   	pop    %ebp
f010047f:	c3                   	ret    

f0100480 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f0100480:	80 3d 34 65 11 f0 00 	cmpb   $0x0,0xf0116534
f0100487:	74 11                	je     f010049a <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f0100489:	55                   	push   %ebp
f010048a:	89 e5                	mov    %esp,%ebp
f010048c:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f010048f:	b8 1c 01 10 f0       	mov    $0xf010011c,%eax
f0100494:	e8 a2 fc ff ff       	call   f010013b <cons_intr>
}
f0100499:	c9                   	leave  
f010049a:	f3 c3                	repz ret 

f010049c <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f010049c:	55                   	push   %ebp
f010049d:	89 e5                	mov    %esp,%ebp
f010049f:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004a2:	b8 7e 01 10 f0       	mov    $0xf010017e,%eax
f01004a7:	e8 8f fc ff ff       	call   f010013b <cons_intr>
}
f01004ac:	c9                   	leave  
f01004ad:	c3                   	ret    

f01004ae <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004ae:	55                   	push   %ebp
f01004af:	89 e5                	mov    %esp,%ebp
f01004b1:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004b4:	e8 c7 ff ff ff       	call   f0100480 <serial_intr>
	kbd_intr();
f01004b9:	e8 de ff ff ff       	call   f010049c <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004be:	a1 20 65 11 f0       	mov    0xf0116520,%eax
f01004c3:	3b 05 24 65 11 f0    	cmp    0xf0116524,%eax
f01004c9:	74 26                	je     f01004f1 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01004cb:	8d 50 01             	lea    0x1(%eax),%edx
f01004ce:	89 15 20 65 11 f0    	mov    %edx,0xf0116520
f01004d4:	0f b6 88 20 63 11 f0 	movzbl -0xfee9ce0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f01004db:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f01004dd:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01004e3:	75 11                	jne    f01004f6 <cons_getc+0x48>
			cons.rpos = 0;
f01004e5:	c7 05 20 65 11 f0 00 	movl   $0x0,0xf0116520
f01004ec:	00 00 00 
f01004ef:	eb 05                	jmp    f01004f6 <cons_getc+0x48>
		return c;
	}
	return 0;
f01004f1:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01004f6:	c9                   	leave  
f01004f7:	c3                   	ret    

f01004f8 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f01004f8:	55                   	push   %ebp
f01004f9:	89 e5                	mov    %esp,%ebp
f01004fb:	57                   	push   %edi
f01004fc:	56                   	push   %esi
f01004fd:	53                   	push   %ebx
f01004fe:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100501:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f0100508:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f010050f:	5a a5 
	if (*cp != 0xA55A) {
f0100511:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f0100518:	66 3d 5a a5          	cmp    $0xa55a,%ax
f010051c:	74 11                	je     f010052f <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f010051e:	c7 05 30 65 11 f0 b4 	movl   $0x3b4,0xf0116530
f0100525:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100528:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f010052d:	eb 16                	jmp    f0100545 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f010052f:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100536:	c7 05 30 65 11 f0 d4 	movl   $0x3d4,0xf0116530
f010053d:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100540:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f0100545:	8b 3d 30 65 11 f0    	mov    0xf0116530,%edi
f010054b:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100550:	89 fa                	mov    %edi,%edx
f0100552:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100553:	8d 5f 01             	lea    0x1(%edi),%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100556:	89 da                	mov    %ebx,%edx
f0100558:	ec                   	in     (%dx),%al
f0100559:	0f b6 c8             	movzbl %al,%ecx
f010055c:	c1 e1 08             	shl    $0x8,%ecx
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010055f:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100564:	89 fa                	mov    %edi,%edx
f0100566:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100567:	89 da                	mov    %ebx,%edx
f0100569:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f010056a:	89 35 2c 65 11 f0    	mov    %esi,0xf011652c
	crt_pos = pos;
f0100570:	0f b6 c0             	movzbl %al,%eax
f0100573:	09 c8                	or     %ecx,%eax
f0100575:	66 a3 28 65 11 f0    	mov    %ax,0xf0116528
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010057b:	be fa 03 00 00       	mov    $0x3fa,%esi
f0100580:	b8 00 00 00 00       	mov    $0x0,%eax
f0100585:	89 f2                	mov    %esi,%edx
f0100587:	ee                   	out    %al,(%dx)
f0100588:	ba fb 03 00 00       	mov    $0x3fb,%edx
f010058d:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100592:	ee                   	out    %al,(%dx)
f0100593:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f0100598:	b8 0c 00 00 00       	mov    $0xc,%eax
f010059d:	89 da                	mov    %ebx,%edx
f010059f:	ee                   	out    %al,(%dx)
f01005a0:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005a5:	b8 00 00 00 00       	mov    $0x0,%eax
f01005aa:	ee                   	out    %al,(%dx)
f01005ab:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005b0:	b8 03 00 00 00       	mov    $0x3,%eax
f01005b5:	ee                   	out    %al,(%dx)
f01005b6:	ba fc 03 00 00       	mov    $0x3fc,%edx
f01005bb:	b8 00 00 00 00       	mov    $0x0,%eax
f01005c0:	ee                   	out    %al,(%dx)
f01005c1:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005c6:	b8 01 00 00 00       	mov    $0x1,%eax
f01005cb:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005cc:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01005d1:	ec                   	in     (%dx),%al
f01005d2:	89 c1                	mov    %eax,%ecx
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005d4:	3c ff                	cmp    $0xff,%al
f01005d6:	0f 95 05 34 65 11 f0 	setne  0xf0116534
f01005dd:	89 f2                	mov    %esi,%edx
f01005df:	ec                   	in     (%dx),%al
f01005e0:	89 da                	mov    %ebx,%edx
f01005e2:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01005e3:	80 f9 ff             	cmp    $0xff,%cl
f01005e6:	75 10                	jne    f01005f8 <cons_init+0x100>
		cprintf("Serial port does not exist!\n");
f01005e8:	83 ec 0c             	sub    $0xc,%esp
f01005eb:	68 19 37 10 f0       	push   $0xf0103719
f01005f0:	e8 70 21 00 00       	call   f0102765 <cprintf>
f01005f5:	83 c4 10             	add    $0x10,%esp
}
f01005f8:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01005fb:	5b                   	pop    %ebx
f01005fc:	5e                   	pop    %esi
f01005fd:	5f                   	pop    %edi
f01005fe:	5d                   	pop    %ebp
f01005ff:	c3                   	ret    

f0100600 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100600:	55                   	push   %ebp
f0100601:	89 e5                	mov    %esp,%ebp
f0100603:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100606:	8b 45 08             	mov    0x8(%ebp),%eax
f0100609:	e8 89 fc ff ff       	call   f0100297 <cons_putc>
}
f010060e:	c9                   	leave  
f010060f:	c3                   	ret    

f0100610 <getchar>:

int
getchar(void)
{
f0100610:	55                   	push   %ebp
f0100611:	89 e5                	mov    %esp,%ebp
f0100613:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100616:	e8 93 fe ff ff       	call   f01004ae <cons_getc>
f010061b:	85 c0                	test   %eax,%eax
f010061d:	74 f7                	je     f0100616 <getchar+0x6>
		/* do nothing */;
	return c;
}
f010061f:	c9                   	leave  
f0100620:	c3                   	ret    

f0100621 <iscons>:

int
iscons(int fdnum)
{
f0100621:	55                   	push   %ebp
f0100622:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100624:	b8 01 00 00 00       	mov    $0x1,%eax
f0100629:	5d                   	pop    %ebp
f010062a:	c3                   	ret    

f010062b <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f010062b:	55                   	push   %ebp
f010062c:	89 e5                	mov    %esp,%ebp
f010062e:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100631:	68 60 39 10 f0       	push   $0xf0103960
f0100636:	68 7e 39 10 f0       	push   $0xf010397e
f010063b:	68 83 39 10 f0       	push   $0xf0103983
f0100640:	e8 20 21 00 00       	call   f0102765 <cprintf>
f0100645:	83 c4 0c             	add    $0xc,%esp
f0100648:	68 10 3a 10 f0       	push   $0xf0103a10
f010064d:	68 8c 39 10 f0       	push   $0xf010398c
f0100652:	68 83 39 10 f0       	push   $0xf0103983
f0100657:	e8 09 21 00 00       	call   f0102765 <cprintf>
	return 0;
}
f010065c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100661:	c9                   	leave  
f0100662:	c3                   	ret    

f0100663 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100663:	55                   	push   %ebp
f0100664:	89 e5                	mov    %esp,%ebp
f0100666:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100669:	68 95 39 10 f0       	push   $0xf0103995
f010066e:	e8 f2 20 00 00       	call   f0102765 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100673:	83 c4 08             	add    $0x8,%esp
f0100676:	68 0c 00 10 00       	push   $0x10000c
f010067b:	68 38 3a 10 f0       	push   $0xf0103a38
f0100680:	e8 e0 20 00 00       	call   f0102765 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100685:	83 c4 0c             	add    $0xc,%esp
f0100688:	68 0c 00 10 00       	push   $0x10000c
f010068d:	68 0c 00 10 f0       	push   $0xf010000c
f0100692:	68 60 3a 10 f0       	push   $0xf0103a60
f0100697:	e8 c9 20 00 00       	call   f0102765 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f010069c:	83 c4 0c             	add    $0xc,%esp
f010069f:	68 a1 36 10 00       	push   $0x1036a1
f01006a4:	68 a1 36 10 f0       	push   $0xf01036a1
f01006a9:	68 84 3a 10 f0       	push   $0xf0103a84
f01006ae:	e8 b2 20 00 00       	call   f0102765 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006b3:	83 c4 0c             	add    $0xc,%esp
f01006b6:	68 00 63 11 00       	push   $0x116300
f01006bb:	68 00 63 11 f0       	push   $0xf0116300
f01006c0:	68 a8 3a 10 f0       	push   $0xf0103aa8
f01006c5:	e8 9b 20 00 00       	call   f0102765 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006ca:	83 c4 0c             	add    $0xc,%esp
f01006cd:	68 60 69 11 00       	push   $0x116960
f01006d2:	68 60 69 11 f0       	push   $0xf0116960
f01006d7:	68 cc 3a 10 f0       	push   $0xf0103acc
f01006dc:	e8 84 20 00 00       	call   f0102765 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f01006e1:	b8 5f 6d 11 f0       	mov    $0xf0116d5f,%eax
f01006e6:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f01006eb:	83 c4 08             	add    $0x8,%esp
f01006ee:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f01006f3:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f01006f9:	85 c0                	test   %eax,%eax
f01006fb:	0f 48 c2             	cmovs  %edx,%eax
f01006fe:	c1 f8 0a             	sar    $0xa,%eax
f0100701:	50                   	push   %eax
f0100702:	68 f0 3a 10 f0       	push   $0xf0103af0
f0100707:	e8 59 20 00 00       	call   f0102765 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f010070c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100711:	c9                   	leave  
f0100712:	c3                   	ret    

f0100713 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100713:	55                   	push   %ebp
f0100714:	89 e5                	mov    %esp,%ebp
f0100716:	56                   	push   %esi
f0100717:	53                   	push   %ebx
f0100718:	83 ec 2c             	sub    $0x2c,%esp

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f010071b:	89 eb                	mov    %ebp,%ebx
		ebp f0109ed8  eip f01000d6  args 00000000 00000000 f0100058 f0109f28 00000061
  ...
	*/
	uint32_t ebp=read_ebp(); // current func's start 
	struct Eipdebuginfo info;
	cprintf("Stack backtrace:\n");
f010071d:	68 ae 39 10 f0       	push   $0xf01039ae
f0100722:	e8 3e 20 00 00       	call   f0102765 <cprintf>
	while (ebp != 0) {
f0100727:	83 c4 10             	add    $0x10,%esp
		cprintf("  ebp %08x  eip %08x  args %08x %08x %08x %08x %08x\n", ebp, *((uint32_t*)ebp+1),\
		*((uint32_t*)ebp+2),*((uint32_t*)ebp+3),*((uint32_t*)ebp+4), *((uint32_t*)ebp+5), *((uint32_t*)ebp+6));
		
		if (debuginfo_eip(*((uint32_t*)ebp+1), &info) == 0) {
f010072a:	8d 75 e0             	lea    -0x20(%ebp),%esi
  ...
	*/
	uint32_t ebp=read_ebp(); // current func's start 
	struct Eipdebuginfo info;
	cprintf("Stack backtrace:\n");
	while (ebp != 0) {
f010072d:	eb 55                	jmp    f0100784 <mon_backtrace+0x71>
		cprintf("  ebp %08x  eip %08x  args %08x %08x %08x %08x %08x\n", ebp, *((uint32_t*)ebp+1),\
f010072f:	ff 73 18             	pushl  0x18(%ebx)
f0100732:	ff 73 14             	pushl  0x14(%ebx)
f0100735:	ff 73 10             	pushl  0x10(%ebx)
f0100738:	ff 73 0c             	pushl  0xc(%ebx)
f010073b:	ff 73 08             	pushl  0x8(%ebx)
f010073e:	ff 73 04             	pushl  0x4(%ebx)
f0100741:	53                   	push   %ebx
f0100742:	68 1c 3b 10 f0       	push   $0xf0103b1c
f0100747:	e8 19 20 00 00       	call   f0102765 <cprintf>
		*((uint32_t*)ebp+2),*((uint32_t*)ebp+3),*((uint32_t*)ebp+4), *((uint32_t*)ebp+5), *((uint32_t*)ebp+6));
		
		if (debuginfo_eip(*((uint32_t*)ebp+1), &info) == 0) {
f010074c:	83 c4 18             	add    $0x18,%esp
f010074f:	56                   	push   %esi
f0100750:	ff 73 04             	pushl  0x4(%ebx)
f0100753:	e8 17 21 00 00       	call   f010286f <debuginfo_eip>
f0100758:	83 c4 10             	add    $0x10,%esp
f010075b:	85 c0                	test   %eax,%eax
f010075d:	75 23                	jne    f0100782 <mon_backtrace+0x6f>
            uint32_t fn_offset = *((uint32_t*)ebp+1) - info.eip_fn_addr;
            cprintf("\t\t %s:%d: %.*s+%d\n", info.eip_file, info.eip_line,info.eip_fn_namelen,  info.eip_fn_name, fn_offset);
f010075f:	83 ec 08             	sub    $0x8,%esp
f0100762:	8b 43 04             	mov    0x4(%ebx),%eax
f0100765:	2b 45 f0             	sub    -0x10(%ebp),%eax
f0100768:	50                   	push   %eax
f0100769:	ff 75 e8             	pushl  -0x18(%ebp)
f010076c:	ff 75 ec             	pushl  -0x14(%ebp)
f010076f:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100772:	ff 75 e0             	pushl  -0x20(%ebp)
f0100775:	68 c0 39 10 f0       	push   $0xf01039c0
f010077a:	e8 e6 1f 00 00       	call   f0102765 <cprintf>
f010077f:	83 c4 20             	add    $0x20,%esp
        }
		ebp = *(uint32_t*)ebp;
f0100782:	8b 1b                	mov    (%ebx),%ebx
  ...
	*/
	uint32_t ebp=read_ebp(); // current func's start 
	struct Eipdebuginfo info;
	cprintf("Stack backtrace:\n");
	while (ebp != 0) {
f0100784:	85 db                	test   %ebx,%ebx
f0100786:	75 a7                	jne    f010072f <mon_backtrace+0x1c>
        }
		ebp = *(uint32_t*)ebp;
	}

	return 0;
}
f0100788:	b8 00 00 00 00       	mov    $0x0,%eax
f010078d:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100790:	5b                   	pop    %ebx
f0100791:	5e                   	pop    %esi
f0100792:	5d                   	pop    %ebp
f0100793:	c3                   	ret    

f0100794 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100794:	55                   	push   %ebp
f0100795:	89 e5                	mov    %esp,%ebp
f0100797:	57                   	push   %edi
f0100798:	56                   	push   %esi
f0100799:	53                   	push   %ebx
f010079a:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f010079d:	68 54 3b 10 f0       	push   $0xf0103b54
f01007a2:	e8 be 1f 00 00       	call   f0102765 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007a7:	c7 04 24 78 3b 10 f0 	movl   $0xf0103b78,(%esp)
f01007ae:	e8 b2 1f 00 00       	call   f0102765 <cprintf>
f01007b3:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f01007b6:	83 ec 0c             	sub    $0xc,%esp
f01007b9:	68 d3 39 10 f0       	push   $0xf01039d3
f01007be:	e8 04 28 00 00       	call   f0102fc7 <readline>
f01007c3:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f01007c5:	83 c4 10             	add    $0x10,%esp
f01007c8:	85 c0                	test   %eax,%eax
f01007ca:	74 ea                	je     f01007b6 <monitor+0x22>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f01007cc:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f01007d3:	be 00 00 00 00       	mov    $0x0,%esi
f01007d8:	eb 0a                	jmp    f01007e4 <monitor+0x50>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f01007da:	c6 03 00             	movb   $0x0,(%ebx)
f01007dd:	89 f7                	mov    %esi,%edi
f01007df:	8d 5b 01             	lea    0x1(%ebx),%ebx
f01007e2:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f01007e4:	0f b6 03             	movzbl (%ebx),%eax
f01007e7:	84 c0                	test   %al,%al
f01007e9:	74 63                	je     f010084e <monitor+0xba>
f01007eb:	83 ec 08             	sub    $0x8,%esp
f01007ee:	0f be c0             	movsbl %al,%eax
f01007f1:	50                   	push   %eax
f01007f2:	68 d7 39 10 f0       	push   $0xf01039d7
f01007f7:	e8 e5 29 00 00       	call   f01031e1 <strchr>
f01007fc:	83 c4 10             	add    $0x10,%esp
f01007ff:	85 c0                	test   %eax,%eax
f0100801:	75 d7                	jne    f01007da <monitor+0x46>
			*buf++ = 0;
		if (*buf == 0)
f0100803:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100806:	74 46                	je     f010084e <monitor+0xba>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100808:	83 fe 0f             	cmp    $0xf,%esi
f010080b:	75 14                	jne    f0100821 <monitor+0x8d>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f010080d:	83 ec 08             	sub    $0x8,%esp
f0100810:	6a 10                	push   $0x10
f0100812:	68 dc 39 10 f0       	push   $0xf01039dc
f0100817:	e8 49 1f 00 00       	call   f0102765 <cprintf>
f010081c:	83 c4 10             	add    $0x10,%esp
f010081f:	eb 95                	jmp    f01007b6 <monitor+0x22>
			return 0;
		}
		argv[argc++] = buf;
f0100821:	8d 7e 01             	lea    0x1(%esi),%edi
f0100824:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100828:	eb 03                	jmp    f010082d <monitor+0x99>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f010082a:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f010082d:	0f b6 03             	movzbl (%ebx),%eax
f0100830:	84 c0                	test   %al,%al
f0100832:	74 ae                	je     f01007e2 <monitor+0x4e>
f0100834:	83 ec 08             	sub    $0x8,%esp
f0100837:	0f be c0             	movsbl %al,%eax
f010083a:	50                   	push   %eax
f010083b:	68 d7 39 10 f0       	push   $0xf01039d7
f0100840:	e8 9c 29 00 00       	call   f01031e1 <strchr>
f0100845:	83 c4 10             	add    $0x10,%esp
f0100848:	85 c0                	test   %eax,%eax
f010084a:	74 de                	je     f010082a <monitor+0x96>
f010084c:	eb 94                	jmp    f01007e2 <monitor+0x4e>
			buf++;
	}
	argv[argc] = 0;
f010084e:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100855:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100856:	85 f6                	test   %esi,%esi
f0100858:	0f 84 58 ff ff ff    	je     f01007b6 <monitor+0x22>
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f010085e:	83 ec 08             	sub    $0x8,%esp
f0100861:	68 7e 39 10 f0       	push   $0xf010397e
f0100866:	ff 75 a8             	pushl  -0x58(%ebp)
f0100869:	e8 15 29 00 00       	call   f0103183 <strcmp>
f010086e:	83 c4 10             	add    $0x10,%esp
f0100871:	85 c0                	test   %eax,%eax
f0100873:	74 1e                	je     f0100893 <monitor+0xff>
f0100875:	83 ec 08             	sub    $0x8,%esp
f0100878:	68 8c 39 10 f0       	push   $0xf010398c
f010087d:	ff 75 a8             	pushl  -0x58(%ebp)
f0100880:	e8 fe 28 00 00       	call   f0103183 <strcmp>
f0100885:	83 c4 10             	add    $0x10,%esp
f0100888:	85 c0                	test   %eax,%eax
f010088a:	75 2f                	jne    f01008bb <monitor+0x127>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f010088c:	b8 01 00 00 00       	mov    $0x1,%eax
f0100891:	eb 05                	jmp    f0100898 <monitor+0x104>
		if (strcmp(argv[0], commands[i].name) == 0)
f0100893:	b8 00 00 00 00       	mov    $0x0,%eax
			return commands[i].func(argc, argv, tf);
f0100898:	83 ec 04             	sub    $0x4,%esp
f010089b:	8d 14 00             	lea    (%eax,%eax,1),%edx
f010089e:	01 d0                	add    %edx,%eax
f01008a0:	ff 75 08             	pushl  0x8(%ebp)
f01008a3:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f01008a6:	51                   	push   %ecx
f01008a7:	56                   	push   %esi
f01008a8:	ff 14 85 a8 3b 10 f0 	call   *-0xfefc458(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f01008af:	83 c4 10             	add    $0x10,%esp
f01008b2:	85 c0                	test   %eax,%eax
f01008b4:	78 1d                	js     f01008d3 <monitor+0x13f>
f01008b6:	e9 fb fe ff ff       	jmp    f01007b6 <monitor+0x22>
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f01008bb:	83 ec 08             	sub    $0x8,%esp
f01008be:	ff 75 a8             	pushl  -0x58(%ebp)
f01008c1:	68 f9 39 10 f0       	push   $0xf01039f9
f01008c6:	e8 9a 1e 00 00       	call   f0102765 <cprintf>
f01008cb:	83 c4 10             	add    $0x10,%esp
f01008ce:	e9 e3 fe ff ff       	jmp    f01007b6 <monitor+0x22>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f01008d3:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01008d6:	5b                   	pop    %ebx
f01008d7:	5e                   	pop    %esi
f01008d8:	5f                   	pop    %edi
f01008d9:	5d                   	pop    %ebp
f01008da:	c3                   	ret    

f01008db <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f01008db:	55                   	push   %ebp
f01008dc:	89 e5                	mov    %esp,%ebp
f01008de:	89 c2                	mov    %eax,%edx
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f01008e0:	83 3d 38 65 11 f0 00 	cmpl   $0x0,0xf0116538
f01008e7:	75 0f                	jne    f01008f8 <boot_alloc+0x1d>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f01008e9:	b8 5f 79 11 f0       	mov    $0xf011795f,%eax
f01008ee:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01008f3:	a3 38 65 11 f0       	mov    %eax,0xf0116538
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	result = nextfree;
f01008f8:	a1 38 65 11 f0       	mov    0xf0116538,%eax
	if (n > 0) {
f01008fd:	85 d2                	test   %edx,%edx
f01008ff:	74 14                	je     f0100915 <boot_alloc+0x3a>
		nextfree += ROUNDUP(n, PGSIZE);
f0100901:	81 c2 ff 0f 00 00    	add    $0xfff,%edx
f0100907:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010090d:	01 c2                	add    %eax,%edx
f010090f:	89 15 38 65 11 f0    	mov    %edx,0xf0116538
	}

	return result;
}
f0100915:	5d                   	pop    %ebp
f0100916:	c3                   	ret    

f0100917 <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f0100917:	55                   	push   %ebp
f0100918:	89 e5                	mov    %esp,%ebp
f010091a:	56                   	push   %esi
f010091b:	53                   	push   %ebx
f010091c:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f010091e:	83 ec 0c             	sub    $0xc,%esp
f0100921:	50                   	push   %eax
f0100922:	e8 d7 1d 00 00       	call   f01026fe <mc146818_read>
f0100927:	89 c6                	mov    %eax,%esi
f0100929:	83 c3 01             	add    $0x1,%ebx
f010092c:	89 1c 24             	mov    %ebx,(%esp)
f010092f:	e8 ca 1d 00 00       	call   f01026fe <mc146818_read>
f0100934:	c1 e0 08             	shl    $0x8,%eax
f0100937:	09 f0                	or     %esi,%eax
}
f0100939:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010093c:	5b                   	pop    %ebx
f010093d:	5e                   	pop    %esi
f010093e:	5d                   	pop    %ebp
f010093f:	c3                   	ret    

f0100940 <check_va2pa>:
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f0100940:	89 d1                	mov    %edx,%ecx
f0100942:	c1 e9 16             	shr    $0x16,%ecx
f0100945:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0100948:	a8 01                	test   $0x1,%al
f010094a:	74 52                	je     f010099e <check_va2pa+0x5e>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f010094c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100951:	89 c1                	mov    %eax,%ecx
f0100953:	c1 e9 0c             	shr    $0xc,%ecx
f0100956:	3b 0d 68 69 11 f0    	cmp    0xf0116968,%ecx
f010095c:	72 1b                	jb     f0100979 <check_va2pa+0x39>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f010095e:	55                   	push   %ebp
f010095f:	89 e5                	mov    %esp,%ebp
f0100961:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100964:	50                   	push   %eax
f0100965:	68 b8 3b 10 f0       	push   $0xf0103bb8
f010096a:	68 df 02 00 00       	push   $0x2df
f010096f:	68 54 43 10 f0       	push   $0xf0104354
f0100974:	e8 12 f7 ff ff       	call   f010008b <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f0100979:	c1 ea 0c             	shr    $0xc,%edx
f010097c:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100982:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100989:	89 c2                	mov    %eax,%edx
f010098b:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f010098e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100993:	85 d2                	test   %edx,%edx
f0100995:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f010099a:	0f 44 c2             	cmove  %edx,%eax
f010099d:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f010099e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f01009a3:	c3                   	ret    

f01009a4 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f01009a4:	55                   	push   %ebp
f01009a5:	89 e5                	mov    %esp,%ebp
f01009a7:	57                   	push   %edi
f01009a8:	56                   	push   %esi
f01009a9:	53                   	push   %ebx
f01009aa:	83 ec 2c             	sub    $0x2c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f01009ad:	84 c0                	test   %al,%al
f01009af:	0f 85 81 02 00 00    	jne    f0100c36 <check_page_free_list+0x292>
f01009b5:	e9 8e 02 00 00       	jmp    f0100c48 <check_page_free_list+0x2a4>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f01009ba:	83 ec 04             	sub    $0x4,%esp
f01009bd:	68 dc 3b 10 f0       	push   $0xf0103bdc
f01009c2:	68 20 02 00 00       	push   $0x220
f01009c7:	68 54 43 10 f0       	push   $0xf0104354
f01009cc:	e8 ba f6 ff ff       	call   f010008b <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f01009d1:	8d 55 d8             	lea    -0x28(%ebp),%edx
f01009d4:	89 55 e0             	mov    %edx,-0x20(%ebp)
f01009d7:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01009da:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f01009dd:	89 c2                	mov    %eax,%edx
f01009df:	2b 15 70 69 11 f0    	sub    0xf0116970,%edx
f01009e5:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f01009eb:	0f 95 c2             	setne  %dl
f01009ee:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f01009f1:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f01009f5:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f01009f7:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f01009fb:	8b 00                	mov    (%eax),%eax
f01009fd:	85 c0                	test   %eax,%eax
f01009ff:	75 dc                	jne    f01009dd <check_page_free_list+0x39>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100a01:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a04:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100a0a:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100a0d:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100a10:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100a12:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100a15:	a3 3c 65 11 f0       	mov    %eax,0xf011653c
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100a1a:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100a1f:	8b 1d 3c 65 11 f0    	mov    0xf011653c,%ebx
f0100a25:	eb 53                	jmp    f0100a7a <check_page_free_list+0xd6>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100a27:	89 d8                	mov    %ebx,%eax
f0100a29:	2b 05 70 69 11 f0    	sub    0xf0116970,%eax
f0100a2f:	c1 f8 03             	sar    $0x3,%eax
f0100a32:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100a35:	89 c2                	mov    %eax,%edx
f0100a37:	c1 ea 16             	shr    $0x16,%edx
f0100a3a:	39 f2                	cmp    %esi,%edx
f0100a3c:	73 3a                	jae    f0100a78 <check_page_free_list+0xd4>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100a3e:	89 c2                	mov    %eax,%edx
f0100a40:	c1 ea 0c             	shr    $0xc,%edx
f0100a43:	3b 15 68 69 11 f0    	cmp    0xf0116968,%edx
f0100a49:	72 12                	jb     f0100a5d <check_page_free_list+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100a4b:	50                   	push   %eax
f0100a4c:	68 b8 3b 10 f0       	push   $0xf0103bb8
f0100a51:	6a 52                	push   $0x52
f0100a53:	68 60 43 10 f0       	push   $0xf0104360
f0100a58:	e8 2e f6 ff ff       	call   f010008b <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100a5d:	83 ec 04             	sub    $0x4,%esp
f0100a60:	68 80 00 00 00       	push   $0x80
f0100a65:	68 97 00 00 00       	push   $0x97
f0100a6a:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100a6f:	50                   	push   %eax
f0100a70:	e8 a9 27 00 00       	call   f010321e <memset>
f0100a75:	83 c4 10             	add    $0x10,%esp
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100a78:	8b 1b                	mov    (%ebx),%ebx
f0100a7a:	85 db                	test   %ebx,%ebx
f0100a7c:	75 a9                	jne    f0100a27 <check_page_free_list+0x83>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100a7e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100a83:	e8 53 fe ff ff       	call   f01008db <boot_alloc>
f0100a88:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100a8b:	8b 15 3c 65 11 f0    	mov    0xf011653c,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100a91:	8b 0d 70 69 11 f0    	mov    0xf0116970,%ecx
		assert(pp < pages + npages);
f0100a97:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f0100a9c:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100a9f:	8d 3c c1             	lea    (%ecx,%eax,8),%edi
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100aa2:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100aa5:	be 00 00 00 00       	mov    $0x0,%esi
f0100aaa:	89 5d d0             	mov    %ebx,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100aad:	e9 30 01 00 00       	jmp    f0100be2 <check_page_free_list+0x23e>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100ab2:	39 ca                	cmp    %ecx,%edx
f0100ab4:	73 19                	jae    f0100acf <check_page_free_list+0x12b>
f0100ab6:	68 6e 43 10 f0       	push   $0xf010436e
f0100abb:	68 7a 43 10 f0       	push   $0xf010437a
f0100ac0:	68 3a 02 00 00       	push   $0x23a
f0100ac5:	68 54 43 10 f0       	push   $0xf0104354
f0100aca:	e8 bc f5 ff ff       	call   f010008b <_panic>
		assert(pp < pages + npages);
f0100acf:	39 fa                	cmp    %edi,%edx
f0100ad1:	72 19                	jb     f0100aec <check_page_free_list+0x148>
f0100ad3:	68 8f 43 10 f0       	push   $0xf010438f
f0100ad8:	68 7a 43 10 f0       	push   $0xf010437a
f0100add:	68 3b 02 00 00       	push   $0x23b
f0100ae2:	68 54 43 10 f0       	push   $0xf0104354
f0100ae7:	e8 9f f5 ff ff       	call   f010008b <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100aec:	89 d0                	mov    %edx,%eax
f0100aee:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100af1:	a8 07                	test   $0x7,%al
f0100af3:	74 19                	je     f0100b0e <check_page_free_list+0x16a>
f0100af5:	68 00 3c 10 f0       	push   $0xf0103c00
f0100afa:	68 7a 43 10 f0       	push   $0xf010437a
f0100aff:	68 3c 02 00 00       	push   $0x23c
f0100b04:	68 54 43 10 f0       	push   $0xf0104354
f0100b09:	e8 7d f5 ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100b0e:	c1 f8 03             	sar    $0x3,%eax
f0100b11:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100b14:	85 c0                	test   %eax,%eax
f0100b16:	75 19                	jne    f0100b31 <check_page_free_list+0x18d>
f0100b18:	68 a3 43 10 f0       	push   $0xf01043a3
f0100b1d:	68 7a 43 10 f0       	push   $0xf010437a
f0100b22:	68 3f 02 00 00       	push   $0x23f
f0100b27:	68 54 43 10 f0       	push   $0xf0104354
f0100b2c:	e8 5a f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100b31:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100b36:	75 19                	jne    f0100b51 <check_page_free_list+0x1ad>
f0100b38:	68 b4 43 10 f0       	push   $0xf01043b4
f0100b3d:	68 7a 43 10 f0       	push   $0xf010437a
f0100b42:	68 40 02 00 00       	push   $0x240
f0100b47:	68 54 43 10 f0       	push   $0xf0104354
f0100b4c:	e8 3a f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100b51:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100b56:	75 19                	jne    f0100b71 <check_page_free_list+0x1cd>
f0100b58:	68 34 3c 10 f0       	push   $0xf0103c34
f0100b5d:	68 7a 43 10 f0       	push   $0xf010437a
f0100b62:	68 41 02 00 00       	push   $0x241
f0100b67:	68 54 43 10 f0       	push   $0xf0104354
f0100b6c:	e8 1a f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100b71:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100b76:	75 19                	jne    f0100b91 <check_page_free_list+0x1ed>
f0100b78:	68 cd 43 10 f0       	push   $0xf01043cd
f0100b7d:	68 7a 43 10 f0       	push   $0xf010437a
f0100b82:	68 42 02 00 00       	push   $0x242
f0100b87:	68 54 43 10 f0       	push   $0xf0104354
f0100b8c:	e8 fa f4 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100b91:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100b96:	76 3f                	jbe    f0100bd7 <check_page_free_list+0x233>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100b98:	89 c3                	mov    %eax,%ebx
f0100b9a:	c1 eb 0c             	shr    $0xc,%ebx
f0100b9d:	39 5d c8             	cmp    %ebx,-0x38(%ebp)
f0100ba0:	77 12                	ja     f0100bb4 <check_page_free_list+0x210>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ba2:	50                   	push   %eax
f0100ba3:	68 b8 3b 10 f0       	push   $0xf0103bb8
f0100ba8:	6a 52                	push   $0x52
f0100baa:	68 60 43 10 f0       	push   $0xf0104360
f0100baf:	e8 d7 f4 ff ff       	call   f010008b <_panic>
f0100bb4:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100bb9:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100bbc:	76 1e                	jbe    f0100bdc <check_page_free_list+0x238>
f0100bbe:	68 58 3c 10 f0       	push   $0xf0103c58
f0100bc3:	68 7a 43 10 f0       	push   $0xf010437a
f0100bc8:	68 43 02 00 00       	push   $0x243
f0100bcd:	68 54 43 10 f0       	push   $0xf0104354
f0100bd2:	e8 b4 f4 ff ff       	call   f010008b <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100bd7:	83 c6 01             	add    $0x1,%esi
f0100bda:	eb 04                	jmp    f0100be0 <check_page_free_list+0x23c>
		else
			++nfree_extmem;
f0100bdc:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100be0:	8b 12                	mov    (%edx),%edx
f0100be2:	85 d2                	test   %edx,%edx
f0100be4:	0f 85 c8 fe ff ff    	jne    f0100ab2 <check_page_free_list+0x10e>
f0100bea:	8b 5d d0             	mov    -0x30(%ebp),%ebx
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100bed:	85 f6                	test   %esi,%esi
f0100bef:	7f 19                	jg     f0100c0a <check_page_free_list+0x266>
f0100bf1:	68 e7 43 10 f0       	push   $0xf01043e7
f0100bf6:	68 7a 43 10 f0       	push   $0xf010437a
f0100bfb:	68 4b 02 00 00       	push   $0x24b
f0100c00:	68 54 43 10 f0       	push   $0xf0104354
f0100c05:	e8 81 f4 ff ff       	call   f010008b <_panic>
	assert(nfree_extmem > 0);
f0100c0a:	85 db                	test   %ebx,%ebx
f0100c0c:	7f 19                	jg     f0100c27 <check_page_free_list+0x283>
f0100c0e:	68 f9 43 10 f0       	push   $0xf01043f9
f0100c13:	68 7a 43 10 f0       	push   $0xf010437a
f0100c18:	68 4c 02 00 00       	push   $0x24c
f0100c1d:	68 54 43 10 f0       	push   $0xf0104354
f0100c22:	e8 64 f4 ff ff       	call   f010008b <_panic>

	cprintf("check_page_free_list() succeeded!\n");
f0100c27:	83 ec 0c             	sub    $0xc,%esp
f0100c2a:	68 a0 3c 10 f0       	push   $0xf0103ca0
f0100c2f:	e8 31 1b 00 00       	call   f0102765 <cprintf>
}
f0100c34:	eb 29                	jmp    f0100c5f <check_page_free_list+0x2bb>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100c36:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f0100c3b:	85 c0                	test   %eax,%eax
f0100c3d:	0f 85 8e fd ff ff    	jne    f01009d1 <check_page_free_list+0x2d>
f0100c43:	e9 72 fd ff ff       	jmp    f01009ba <check_page_free_list+0x16>
f0100c48:	83 3d 3c 65 11 f0 00 	cmpl   $0x0,0xf011653c
f0100c4f:	0f 84 65 fd ff ff    	je     f01009ba <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100c55:	be 00 04 00 00       	mov    $0x400,%esi
f0100c5a:	e9 c0 fd ff ff       	jmp    f0100a1f <check_page_free_list+0x7b>

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);

	cprintf("check_page_free_list() succeeded!\n");
}
f0100c5f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100c62:	5b                   	pop    %ebx
f0100c63:	5e                   	pop    %esi
f0100c64:	5f                   	pop    %edi
f0100c65:	5d                   	pop    %ebp
f0100c66:	c3                   	ret    

f0100c67 <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100c67:	55                   	push   %ebp
f0100c68:	89 e5                	mov    %esp,%ebp
f0100c6a:	56                   	push   %esi
f0100c6b:	53                   	push   %ebx
	// The example code here marks all physical pages as free.
	// However this is not truly the case.  What memory is free?
	//  1) Mark physical page 0 as in use.
	size_t i;
	pages[0].pp_ref = 1;
f0100c6c:	a1 70 69 11 f0       	mov    0xf0116970,%eax
f0100c71:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
	//     This way we preserve the real-mode IDT and BIOS structures
	//     in case we ever need them.  (Currently we don't, but...)
	//  2) The rest of base memory, [PGSIZE, npages_basemem * PGSIZE)
	//     is free.
	for (i = 1; i < npages_basemem; i++) {
f0100c77:	8b 35 40 65 11 f0    	mov    0xf0116540,%esi
f0100c7d:	8b 1d 3c 65 11 f0    	mov    0xf011653c,%ebx
f0100c83:	ba 00 00 00 00       	mov    $0x0,%edx
f0100c88:	b8 01 00 00 00       	mov    $0x1,%eax
f0100c8d:	eb 27                	jmp    f0100cb6 <page_init+0x4f>
		pages[i].pp_ref = 0;
f0100c8f:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
f0100c96:	89 d1                	mov    %edx,%ecx
f0100c98:	03 0d 70 69 11 f0    	add    0xf0116970,%ecx
f0100c9e:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = page_free_list;
f0100ca4:	89 19                	mov    %ebx,(%ecx)
	pages[0].pp_ref = 1;
	//     This way we preserve the real-mode IDT and BIOS structures
	//     in case we ever need them.  (Currently we don't, but...)
	//  2) The rest of base memory, [PGSIZE, npages_basemem * PGSIZE)
	//     is free.
	for (i = 1; i < npages_basemem; i++) {
f0100ca6:	83 c0 01             	add    $0x1,%eax
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
f0100ca9:	89 d3                	mov    %edx,%ebx
f0100cab:	03 1d 70 69 11 f0    	add    0xf0116970,%ebx
f0100cb1:	ba 01 00 00 00       	mov    $0x1,%edx
	pages[0].pp_ref = 1;
	//     This way we preserve the real-mode IDT and BIOS structures
	//     in case we ever need them.  (Currently we don't, but...)
	//  2) The rest of base memory, [PGSIZE, npages_basemem * PGSIZE)
	//     is free.
	for (i = 1; i < npages_basemem; i++) {
f0100cb6:	39 f0                	cmp    %esi,%eax
f0100cb8:	72 d5                	jb     f0100c8f <page_init+0x28>
f0100cba:	84 d2                	test   %dl,%dl
f0100cbc:	74 06                	je     f0100cc4 <page_init+0x5d>
f0100cbe:	89 1d 3c 65 11 f0    	mov    %ebx,0xf011653c
		page_free_list = &pages[i];
	}
	//  3) Then comes the IO hole [IOPHYSMEM, EXTPHYSMEM), which must
	//     never be allocated.
	for (i = IOPHYSMEM / (PGSIZE); i < EXTPHYSMEM / (PGSIZE); i++)
		pages[i].pp_ref = 1;
f0100cc4:	8b 15 70 69 11 f0    	mov    0xf0116970,%edx
f0100cca:	8d 82 04 05 00 00    	lea    0x504(%edx),%eax
f0100cd0:	81 c2 04 08 00 00    	add    $0x804,%edx
f0100cd6:	66 c7 00 01 00       	movw   $0x1,(%eax)
f0100cdb:	83 c0 08             	add    $0x8,%eax
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
	//  3) Then comes the IO hole [IOPHYSMEM, EXTPHYSMEM), which must
	//     never be allocated.
	for (i = IOPHYSMEM / (PGSIZE); i < EXTPHYSMEM / (PGSIZE); i++)
f0100cde:	39 d0                	cmp    %edx,%eax
f0100ce0:	75 f4                	jne    f0100cd6 <page_init+0x6f>
	//  4) Then extended memory [EXTPHYSMEM, ...).
	//     Some of it is in use, some is free. Where is the kernel
	//     in physical memory?  Which pages are already in use for
	//     page tables and other data structures?
	//	up to kern.text 0x1000000
	size_t nextfree = PADDR(boot_alloc(0));
f0100ce2:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ce7:	e8 ef fb ff ff       	call   f01008db <boot_alloc>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100cec:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100cf1:	77 15                	ja     f0100d08 <page_init+0xa1>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100cf3:	50                   	push   %eax
f0100cf4:	68 c4 3c 10 f0       	push   $0xf0103cc4
f0100cf9:	68 08 01 00 00       	push   $0x108
f0100cfe:	68 54 43 10 f0       	push   $0xf0104354
f0100d03:	e8 83 f3 ff ff       	call   f010008b <_panic>
	for (i = EXTPHYSMEM / (PGSIZE); i < nextfree / (PGSIZE); i++)
f0100d08:	05 00 00 00 10       	add    $0x10000000,%eax
f0100d0d:	c1 e8 0c             	shr    $0xc,%eax
		pages[i].pp_ref = 1;
f0100d10:	8b 0d 70 69 11 f0    	mov    0xf0116970,%ecx
	//     Some of it is in use, some is free. Where is the kernel
	//     in physical memory?  Which pages are already in use for
	//     page tables and other data structures?
	//	up to kern.text 0x1000000
	size_t nextfree = PADDR(boot_alloc(0));
	for (i = EXTPHYSMEM / (PGSIZE); i < nextfree / (PGSIZE); i++)
f0100d16:	ba 00 01 00 00       	mov    $0x100,%edx
f0100d1b:	eb 0a                	jmp    f0100d27 <page_init+0xc0>
		pages[i].pp_ref = 1;
f0100d1d:	66 c7 44 d1 04 01 00 	movw   $0x1,0x4(%ecx,%edx,8)
	//     Some of it is in use, some is free. Where is the kernel
	//     in physical memory?  Which pages are already in use for
	//     page tables and other data structures?
	//	up to kern.text 0x1000000
	size_t nextfree = PADDR(boot_alloc(0));
	for (i = EXTPHYSMEM / (PGSIZE); i < nextfree / (PGSIZE); i++)
f0100d24:	83 c2 01             	add    $0x1,%edx
f0100d27:	39 c2                	cmp    %eax,%edx
f0100d29:	72 f2                	jb     f0100d1d <page_init+0xb6>
f0100d2b:	8b 1d 3c 65 11 f0    	mov    0xf011653c,%ebx
f0100d31:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
f0100d38:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100d3d:	eb 23                	jmp    f0100d62 <page_init+0xfb>
		pages[i].pp_ref = 1;
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	for (i = nextfree / (PGSIZE); i < npages; i++) {
		pages[i].pp_ref = 0;
f0100d3f:	89 d1                	mov    %edx,%ecx
f0100d41:	03 0d 70 69 11 f0    	add    0xf0116970,%ecx
f0100d47:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = page_free_list;
f0100d4d:	89 19                	mov    %ebx,(%ecx)
		page_free_list = &pages[i];
f0100d4f:	89 d3                	mov    %edx,%ebx
f0100d51:	03 1d 70 69 11 f0    	add    0xf0116970,%ebx
	for (i = EXTPHYSMEM / (PGSIZE); i < nextfree / (PGSIZE); i++)
		pages[i].pp_ref = 1;
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	for (i = nextfree / (PGSIZE); i < npages; i++) {
f0100d57:	83 c0 01             	add    $0x1,%eax
f0100d5a:	83 c2 08             	add    $0x8,%edx
f0100d5d:	b9 01 00 00 00       	mov    $0x1,%ecx
f0100d62:	3b 05 68 69 11 f0    	cmp    0xf0116968,%eax
f0100d68:	72 d5                	jb     f0100d3f <page_init+0xd8>
f0100d6a:	84 c9                	test   %cl,%cl
f0100d6c:	74 06                	je     f0100d74 <page_init+0x10d>
f0100d6e:	89 1d 3c 65 11 f0    	mov    %ebx,0xf011653c
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
}
f0100d74:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100d77:	5b                   	pop    %ebx
f0100d78:	5e                   	pop    %esi
f0100d79:	5d                   	pop    %ebp
f0100d7a:	c3                   	ret    

f0100d7b <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100d7b:	55                   	push   %ebp
f0100d7c:	89 e5                	mov    %esp,%ebp
f0100d7e:	53                   	push   %ebx
f0100d7f:	83 ec 04             	sub    $0x4,%esp
	// Fill this function in
	if (page_free_list == NULL)
f0100d82:	8b 1d 3c 65 11 f0    	mov    0xf011653c,%ebx
f0100d88:	85 db                	test   %ebx,%ebx
f0100d8a:	74 58                	je     f0100de4 <page_alloc+0x69>
		return NULL;
	struct PageInfo * freepg = page_free_list;
	page_free_list = page_free_list->pp_link;
f0100d8c:	8b 03                	mov    (%ebx),%eax
f0100d8e:	a3 3c 65 11 f0       	mov    %eax,0xf011653c

	freepg->pp_link = NULL;
f0100d93:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	if (ALLOC_ZERO & alloc_flags)
f0100d99:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100d9d:	74 45                	je     f0100de4 <page_alloc+0x69>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100d9f:	89 d8                	mov    %ebx,%eax
f0100da1:	2b 05 70 69 11 f0    	sub    0xf0116970,%eax
f0100da7:	c1 f8 03             	sar    $0x3,%eax
f0100daa:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100dad:	89 c2                	mov    %eax,%edx
f0100daf:	c1 ea 0c             	shr    $0xc,%edx
f0100db2:	3b 15 68 69 11 f0    	cmp    0xf0116968,%edx
f0100db8:	72 12                	jb     f0100dcc <page_alloc+0x51>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100dba:	50                   	push   %eax
f0100dbb:	68 b8 3b 10 f0       	push   $0xf0103bb8
f0100dc0:	6a 52                	push   $0x52
f0100dc2:	68 60 43 10 f0       	push   $0xf0104360
f0100dc7:	e8 bf f2 ff ff       	call   f010008b <_panic>
		memset(page2kva(freepg), 0 , PGSIZE);
f0100dcc:	83 ec 04             	sub    $0x4,%esp
f0100dcf:	68 00 10 00 00       	push   $0x1000
f0100dd4:	6a 00                	push   $0x0
f0100dd6:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100ddb:	50                   	push   %eax
f0100ddc:	e8 3d 24 00 00       	call   f010321e <memset>
f0100de1:	83 c4 10             	add    $0x10,%esp
	return freepg;
}
f0100de4:	89 d8                	mov    %ebx,%eax
f0100de6:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100de9:	c9                   	leave  
f0100dea:	c3                   	ret    

f0100deb <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100deb:	55                   	push   %ebp
f0100dec:	89 e5                	mov    %esp,%ebp
f0100dee:	83 ec 08             	sub    $0x8,%esp
f0100df1:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	if (pp->pp_link || pp->pp_ref)
f0100df4:	83 38 00             	cmpl   $0x0,(%eax)
f0100df7:	75 07                	jne    f0100e00 <page_free+0x15>
f0100df9:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100dfe:	74 17                	je     f0100e17 <page_free+0x2c>
		panic("page to be free is not free at all\n");
f0100e00:	83 ec 04             	sub    $0x4,%esp
f0100e03:	68 e8 3c 10 f0       	push   $0xf0103ce8
f0100e08:	68 3a 01 00 00       	push   $0x13a
f0100e0d:	68 54 43 10 f0       	push   $0xf0104354
f0100e12:	e8 74 f2 ff ff       	call   f010008b <_panic>
	// pp->pp_link is not NULL.
	pp->pp_link = page_free_list;
f0100e17:	8b 15 3c 65 11 f0    	mov    0xf011653c,%edx
f0100e1d:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;	
f0100e1f:	a3 3c 65 11 f0       	mov    %eax,0xf011653c
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100e24:	2b 05 70 69 11 f0    	sub    0xf0116970,%eax
f0100e2a:	c1 f8 03             	sar    $0x3,%eax
f0100e2d:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100e30:	89 c2                	mov    %eax,%edx
f0100e32:	c1 ea 0c             	shr    $0xc,%edx
f0100e35:	3b 15 68 69 11 f0    	cmp    0xf0116968,%edx
f0100e3b:	72 12                	jb     f0100e4f <page_free+0x64>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100e3d:	50                   	push   %eax
f0100e3e:	68 b8 3b 10 f0       	push   $0xf0103bb8
f0100e43:	6a 52                	push   $0x52
f0100e45:	68 60 43 10 f0       	push   $0xf0104360
f0100e4a:	e8 3c f2 ff ff       	call   f010008b <_panic>
	memset(page2kva(pp), 0 , PGSIZE);
f0100e4f:	83 ec 04             	sub    $0x4,%esp
f0100e52:	68 00 10 00 00       	push   $0x1000
f0100e57:	6a 00                	push   $0x0
f0100e59:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100e5e:	50                   	push   %eax
f0100e5f:	e8 ba 23 00 00       	call   f010321e <memset>
}
f0100e64:	83 c4 10             	add    $0x10,%esp
f0100e67:	c9                   	leave  
f0100e68:	c3                   	ret    

f0100e69 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0100e69:	55                   	push   %ebp
f0100e6a:	89 e5                	mov    %esp,%ebp
f0100e6c:	83 ec 08             	sub    $0x8,%esp
f0100e6f:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0100e72:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0100e76:	83 e8 01             	sub    $0x1,%eax
f0100e79:	66 89 42 04          	mov    %ax,0x4(%edx)
f0100e7d:	66 85 c0             	test   %ax,%ax
f0100e80:	75 0c                	jne    f0100e8e <page_decref+0x25>
		page_free(pp);
f0100e82:	83 ec 0c             	sub    $0xc,%esp
f0100e85:	52                   	push   %edx
f0100e86:	e8 60 ff ff ff       	call   f0100deb <page_free>
f0100e8b:	83 c4 10             	add    $0x10,%esp
}
f0100e8e:	c9                   	leave  
f0100e8f:	c3                   	ret    

f0100e90 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that manipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100e90:	55                   	push   %ebp
f0100e91:	89 e5                	mov    %esp,%ebp
f0100e93:	57                   	push   %edi
f0100e94:	56                   	push   %esi
f0100e95:	53                   	push   %ebx
f0100e96:	83 ec 0c             	sub    $0xc,%esp
	// Fill this function in
	pde_t *pde = &pgdir[PDX(va)];
f0100e99:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100e9c:	c1 eb 16             	shr    $0x16,%ebx
f0100e9f:	c1 e3 02             	shl    $0x2,%ebx
f0100ea2:	03 5d 08             	add    0x8(%ebp),%ebx
	pde_t *pgtab;
	struct PageInfo* freepg;
	if (*pde & PTE_P) // page table present
f0100ea5:	8b 33                	mov    (%ebx),%esi
f0100ea7:	f7 c6 01 00 00 00    	test   $0x1,%esi
f0100ead:	74 30                	je     f0100edf <pgdir_walk+0x4f>
		pgtab = (pte_t*)KADDR(PTE_ADDR(*pde));
f0100eaf:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100eb5:	89 f0                	mov    %esi,%eax
f0100eb7:	c1 e8 0c             	shr    $0xc,%eax
f0100eba:	39 05 68 69 11 f0    	cmp    %eax,0xf0116968
f0100ec0:	77 15                	ja     f0100ed7 <pgdir_walk+0x47>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ec2:	56                   	push   %esi
f0100ec3:	68 b8 3b 10 f0       	push   $0xf0103bb8
f0100ec8:	68 6a 01 00 00       	push   $0x16a
f0100ecd:	68 54 43 10 f0       	push   $0xf0104354
f0100ed2:	e8 b4 f1 ff ff       	call   f010008b <_panic>
	return (void *)(pa + KERNBASE);
f0100ed7:	81 ee 00 00 00 10    	sub    $0x10000000,%esi
f0100edd:	eb 67                	jmp    f0100f46 <pgdir_walk+0xb6>


	else {
		if (!create || (freepg = page_alloc(ALLOC_ZERO)) == NULL) {
f0100edf:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100ee3:	74 70                	je     f0100f55 <pgdir_walk+0xc5>
f0100ee5:	83 ec 0c             	sub    $0xc,%esp
f0100ee8:	6a 01                	push   $0x1
f0100eea:	e8 8c fe ff ff       	call   f0100d7b <page_alloc>
f0100eef:	89 c7                	mov    %eax,%edi
f0100ef1:	83 c4 10             	add    $0x10,%esp
f0100ef4:	85 c0                	test   %eax,%eax
f0100ef6:	74 64                	je     f0100f5c <pgdir_walk+0xcc>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100ef8:	2b 05 70 69 11 f0    	sub    0xf0116970,%eax
f0100efe:	c1 f8 03             	sar    $0x3,%eax
f0100f01:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100f04:	89 c2                	mov    %eax,%edx
f0100f06:	c1 ea 0c             	shr    $0xc,%edx
f0100f09:	3b 15 68 69 11 f0    	cmp    0xf0116968,%edx
f0100f0f:	72 12                	jb     f0100f23 <pgdir_walk+0x93>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100f11:	50                   	push   %eax
f0100f12:	68 b8 3b 10 f0       	push   $0xf0103bb8
f0100f17:	6a 52                	push   $0x52
f0100f19:	68 60 43 10 f0       	push   $0xf0104360
f0100f1e:	e8 68 f1 ff ff       	call   f010008b <_panic>
	return (void *)(pa + KERNBASE);
f0100f23:	8d b0 00 00 00 f0    	lea    -0x10000000(%eax),%esi
			return NULL;
		}
		pgtab = page2kva(freepg);
		*pde = page2pa(freepg) | PTE_P | PTE_W | PTE_U; // in directory
f0100f29:	83 c8 07             	or     $0x7,%eax
f0100f2c:	89 03                	mov    %eax,(%ebx)
		memset(pgtab, 0 , PGSIZE);
f0100f2e:	83 ec 04             	sub    $0x4,%esp
f0100f31:	68 00 10 00 00       	push   $0x1000
f0100f36:	6a 00                	push   $0x0
f0100f38:	56                   	push   %esi
f0100f39:	e8 e0 22 00 00       	call   f010321e <memset>
		freepg->pp_ref++;
f0100f3e:	66 83 47 04 01       	addw   $0x1,0x4(%edi)
f0100f43:	83 c4 10             	add    $0x10,%esp
	}
	return &pgtab[PTX(va)];
f0100f46:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100f49:	c1 e8 0a             	shr    $0xa,%eax
f0100f4c:	25 fc 0f 00 00       	and    $0xffc,%eax
f0100f51:	01 f0                	add    %esi,%eax
f0100f53:	eb 0c                	jmp    f0100f61 <pgdir_walk+0xd1>
		pgtab = (pte_t*)KADDR(PTE_ADDR(*pde));


	else {
		if (!create || (freepg = page_alloc(ALLOC_ZERO)) == NULL) {
			return NULL;
f0100f55:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f5a:	eb 05                	jmp    f0100f61 <pgdir_walk+0xd1>
f0100f5c:	b8 00 00 00 00       	mov    $0x0,%eax
		*pde = page2pa(freepg) | PTE_P | PTE_W | PTE_U; // in directory
		memset(pgtab, 0 , PGSIZE);
		freepg->pp_ref++;
	}
	return &pgtab[PTX(va)];
}
f0100f61:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100f64:	5b                   	pop    %ebx
f0100f65:	5e                   	pop    %esi
f0100f66:	5f                   	pop    %edi
f0100f67:	5d                   	pop    %ebp
f0100f68:	c3                   	ret    

f0100f69 <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0100f69:	55                   	push   %ebp
f0100f6a:	89 e5                	mov    %esp,%ebp
f0100f6c:	57                   	push   %edi
f0100f6d:	56                   	push   %esi
f0100f6e:	53                   	push   %ebx
f0100f6f:	83 ec 1c             	sub    $0x1c,%esp
f0100f72:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100f75:	8b 45 08             	mov    0x8(%ebp),%eax
		*pte = pa | perm | PTE_P;
	}
	*/
	 // Fill this function in
    pte_t *pgtab;
    size_t pg_num = PGNUM(size);
f0100f78:	c1 e9 0c             	shr    $0xc,%ecx
f0100f7b:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
    //cprintf("map region size = %d, %d pages\n",size, pg_num);
    for (size_t i=0; i<pg_num; i++) {
f0100f7e:	89 c3                	mov    %eax,%ebx
f0100f80:	be 00 00 00 00       	mov    $0x0,%esi
        pgtab = pgdir_walk(pgdir, (void *)va, 1);
f0100f85:	89 d7                	mov    %edx,%edi
f0100f87:	29 c7                	sub    %eax,%edi
        if (!pgtab) {
            return;
        }
        //cprintf("va = %p to pa = %p\n", va, pa);
        *pgtab = pa | perm | PTE_P;
f0100f89:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100f8c:	83 c8 01             	or     $0x1,%eax
f0100f8f:	89 45 dc             	mov    %eax,-0x24(%ebp)
	*/
	 // Fill this function in
    pte_t *pgtab;
    size_t pg_num = PGNUM(size);
    //cprintf("map region size = %d, %d pages\n",size, pg_num);
    for (size_t i=0; i<pg_num; i++) {
f0100f92:	eb 28                	jmp    f0100fbc <boot_map_region+0x53>
        pgtab = pgdir_walk(pgdir, (void *)va, 1);
f0100f94:	83 ec 04             	sub    $0x4,%esp
f0100f97:	6a 01                	push   $0x1
f0100f99:	8d 04 1f             	lea    (%edi,%ebx,1),%eax
f0100f9c:	50                   	push   %eax
f0100f9d:	ff 75 e0             	pushl  -0x20(%ebp)
f0100fa0:	e8 eb fe ff ff       	call   f0100e90 <pgdir_walk>
        if (!pgtab) {
f0100fa5:	83 c4 10             	add    $0x10,%esp
f0100fa8:	85 c0                	test   %eax,%eax
f0100faa:	74 15                	je     f0100fc1 <boot_map_region+0x58>
            return;
        }
        //cprintf("va = %p to pa = %p\n", va, pa);
        *pgtab = pa | perm | PTE_P;
f0100fac:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100faf:	09 da                	or     %ebx,%edx
f0100fb1:	89 10                	mov    %edx,(%eax)
        va += PGSIZE;
        pa += PGSIZE;
f0100fb3:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	*/
	 // Fill this function in
    pte_t *pgtab;
    size_t pg_num = PGNUM(size);
    //cprintf("map region size = %d, %d pages\n",size, pg_num);
    for (size_t i=0; i<pg_num; i++) {
f0100fb9:	83 c6 01             	add    $0x1,%esi
f0100fbc:	3b 75 e4             	cmp    -0x1c(%ebp),%esi
f0100fbf:	75 d3                	jne    f0100f94 <boot_map_region+0x2b>
        //cprintf("va = %p to pa = %p\n", va, pa);
        *pgtab = pa | perm | PTE_P;
        va += PGSIZE;
        pa += PGSIZE;
    }
}
f0100fc1:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100fc4:	5b                   	pop    %ebx
f0100fc5:	5e                   	pop    %esi
f0100fc6:	5f                   	pop    %edi
f0100fc7:	5d                   	pop    %ebp
f0100fc8:	c3                   	ret    

f0100fc9 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0100fc9:	55                   	push   %ebp
f0100fca:	89 e5                	mov    %esp,%ebp
f0100fcc:	83 ec 0c             	sub    $0xc,%esp
	// Fill this function in
	pte_t *pte;
	if ((pte = pgdir_walk(pgdir, (void*)va, 0)) == NULL)
f0100fcf:	6a 00                	push   $0x0
f0100fd1:	ff 75 0c             	pushl  0xc(%ebp)
f0100fd4:	ff 75 08             	pushl  0x8(%ebp)
f0100fd7:	e8 b4 fe ff ff       	call   f0100e90 <pgdir_walk>
f0100fdc:	83 c4 10             	add    $0x10,%esp
f0100fdf:	85 c0                	test   %eax,%eax
f0100fe1:	74 31                	je     f0101014 <page_lookup+0x4b>
		return NULL;
	*pte_store = pte;
f0100fe3:	8b 55 10             	mov    0x10(%ebp),%edx
f0100fe6:	89 02                	mov    %eax,(%edx)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100fe8:	8b 00                	mov    (%eax),%eax
f0100fea:	c1 e8 0c             	shr    $0xc,%eax
f0100fed:	3b 05 68 69 11 f0    	cmp    0xf0116968,%eax
f0100ff3:	72 14                	jb     f0101009 <page_lookup+0x40>
		panic("pa2page called with invalid pa");
f0100ff5:	83 ec 04             	sub    $0x4,%esp
f0100ff8:	68 0c 3d 10 f0       	push   $0xf0103d0c
f0100ffd:	6a 4b                	push   $0x4b
f0100fff:	68 60 43 10 f0       	push   $0xf0104360
f0101004:	e8 82 f0 ff ff       	call   f010008b <_panic>
	return &pages[PGNUM(pa)];
f0101009:	8b 15 70 69 11 f0    	mov    0xf0116970,%edx
f010100f:	8d 04 c2             	lea    (%edx,%eax,8),%eax

	return pa2page(PTE_ADDR(*pte));
f0101012:	eb 05                	jmp    f0101019 <page_lookup+0x50>
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
	// Fill this function in
	pte_t *pte;
	if ((pte = pgdir_walk(pgdir, (void*)va, 0)) == NULL)
		return NULL;
f0101014:	b8 00 00 00 00       	mov    $0x0,%eax
	*pte_store = pte;

	return pa2page(PTE_ADDR(*pte));
}
f0101019:	c9                   	leave  
f010101a:	c3                   	ret    

f010101b <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f010101b:	55                   	push   %ebp
f010101c:	89 e5                	mov    %esp,%ebp
f010101e:	53                   	push   %ebx
f010101f:	83 ec 18             	sub    $0x18,%esp
f0101022:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
	pte_t *pte;
	struct PageInfo *pg;

	pg = page_lookup(pgdir, va, &pte);
f0101025:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101028:	50                   	push   %eax
f0101029:	53                   	push   %ebx
f010102a:	ff 75 08             	pushl  0x8(%ebp)
f010102d:	e8 97 ff ff ff       	call   f0100fc9 <page_lookup>
	
	if (!pg) return;
f0101032:	83 c4 10             	add    $0x10,%esp
f0101035:	85 c0                	test   %eax,%eax
f0101037:	74 18                	je     f0101051 <page_remove+0x36>
	page_decref(pg);
f0101039:	83 ec 0c             	sub    $0xc,%esp
f010103c:	50                   	push   %eax
f010103d:	e8 27 fe ff ff       	call   f0100e69 <page_decref>
	*pte = 0x0;
f0101042:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101045:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f010104b:	0f 01 3b             	invlpg (%ebx)
f010104e:	83 c4 10             	add    $0x10,%esp
	tlb_invalidate(pgdir, va);
}
f0101051:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101054:	c9                   	leave  
f0101055:	c3                   	ret    

f0101056 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f0101056:	55                   	push   %ebp
f0101057:	89 e5                	mov    %esp,%ebp
f0101059:	57                   	push   %edi
f010105a:	56                   	push   %esi
f010105b:	53                   	push   %ebx
f010105c:	83 ec 10             	sub    $0x10,%esp
f010105f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101062:	8b 7d 10             	mov    0x10(%ebp),%edi
	// Fill this function in

	pte_t *pte;

	if ((pte = pgdir_walk(pgdir, (void*)va, 1)) == NULL)
f0101065:	6a 01                	push   $0x1
f0101067:	57                   	push   %edi
f0101068:	ff 75 08             	pushl  0x8(%ebp)
f010106b:	e8 20 fe ff ff       	call   f0100e90 <pgdir_walk>
f0101070:	83 c4 10             	add    $0x10,%esp
f0101073:	85 c0                	test   %eax,%eax
f0101075:	74 38                	je     f01010af <page_insert+0x59>
f0101077:	89 c6                	mov    %eax,%esi
		return -E_NO_MEM;
	++pp->pp_ref;
f0101079:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
	if (*pte & PTE_P) {
f010107e:	f6 00 01             	testb  $0x1,(%eax)
f0101081:	74 0f                	je     f0101092 <page_insert+0x3c>
		page_remove(pgdir, va);
f0101083:	83 ec 08             	sub    $0x8,%esp
f0101086:	57                   	push   %edi
f0101087:	ff 75 08             	pushl  0x8(%ebp)
f010108a:	e8 8c ff ff ff       	call   f010101b <page_remove>
f010108f:	83 c4 10             	add    $0x10,%esp
	}
	*pte = page2pa(pp) | perm | PTE_P;
f0101092:	2b 1d 70 69 11 f0    	sub    0xf0116970,%ebx
f0101098:	c1 fb 03             	sar    $0x3,%ebx
f010109b:	c1 e3 0c             	shl    $0xc,%ebx
f010109e:	8b 45 14             	mov    0x14(%ebp),%eax
f01010a1:	83 c8 01             	or     $0x1,%eax
f01010a4:	09 c3                	or     %eax,%ebx
f01010a6:	89 1e                	mov    %ebx,(%esi)
	
	return 0;
f01010a8:	b8 00 00 00 00       	mov    $0x0,%eax
f01010ad:	eb 05                	jmp    f01010b4 <page_insert+0x5e>
	// Fill this function in

	pte_t *pte;

	if ((pte = pgdir_walk(pgdir, (void*)va, 1)) == NULL)
		return -E_NO_MEM;
f01010af:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
		page_remove(pgdir, va);
	}
	*pte = page2pa(pp) | perm | PTE_P;
	
	return 0;
}
f01010b4:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01010b7:	5b                   	pop    %ebx
f01010b8:	5e                   	pop    %esi
f01010b9:	5f                   	pop    %edi
f01010ba:	5d                   	pop    %ebp
f01010bb:	c3                   	ret    

f01010bc <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f01010bc:	55                   	push   %ebp
f01010bd:	89 e5                	mov    %esp,%ebp
f01010bf:	57                   	push   %edi
f01010c0:	56                   	push   %esi
f01010c1:	53                   	push   %ebx
f01010c2:	83 ec 2c             	sub    $0x2c,%esp
{
	size_t basemem, extmem, ext16mem, totalmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	basemem = nvram_read(NVRAM_BASELO);
f01010c5:	b8 15 00 00 00       	mov    $0x15,%eax
f01010ca:	e8 48 f8 ff ff       	call   f0100917 <nvram_read>
f01010cf:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f01010d1:	b8 17 00 00 00       	mov    $0x17,%eax
f01010d6:	e8 3c f8 ff ff       	call   f0100917 <nvram_read>
f01010db:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f01010dd:	b8 34 00 00 00       	mov    $0x34,%eax
f01010e2:	e8 30 f8 ff ff       	call   f0100917 <nvram_read>
f01010e7:	c1 e0 06             	shl    $0x6,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (ext16mem)
f01010ea:	85 c0                	test   %eax,%eax
f01010ec:	74 07                	je     f01010f5 <mem_init+0x39>
		totalmem = 16 * 1024 + ext16mem;
f01010ee:	05 00 40 00 00       	add    $0x4000,%eax
f01010f3:	eb 0b                	jmp    f0101100 <mem_init+0x44>
	else if (extmem)
		totalmem = 1 * 1024 + extmem;
f01010f5:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f01010fb:	85 f6                	test   %esi,%esi
f01010fd:	0f 44 c3             	cmove  %ebx,%eax
	else
		totalmem = basemem;

	npages = totalmem / (PGSIZE / 1024);
f0101100:	89 c2                	mov    %eax,%edx
f0101102:	c1 ea 02             	shr    $0x2,%edx
f0101105:	89 15 68 69 11 f0    	mov    %edx,0xf0116968
	npages_basemem = basemem / (PGSIZE / 1024);
f010110b:	89 da                	mov    %ebx,%edx
f010110d:	c1 ea 02             	shr    $0x2,%edx
f0101110:	89 15 40 65 11 f0    	mov    %edx,0xf0116540

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101116:	89 c2                	mov    %eax,%edx
f0101118:	29 da                	sub    %ebx,%edx
f010111a:	52                   	push   %edx
f010111b:	53                   	push   %ebx
f010111c:	50                   	push   %eax
f010111d:	68 2c 3d 10 f0       	push   $0xf0103d2c
f0101122:	e8 3e 16 00 00       	call   f0102765 <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0101127:	b8 00 10 00 00       	mov    $0x1000,%eax
f010112c:	e8 aa f7 ff ff       	call   f01008db <boot_alloc>
f0101131:	a3 6c 69 11 f0       	mov    %eax,0xf011696c
	memset(kern_pgdir, 0, PGSIZE);
f0101136:	83 c4 0c             	add    $0xc,%esp
f0101139:	68 00 10 00 00       	push   $0x1000
f010113e:	6a 00                	push   $0x0
f0101140:	50                   	push   %eax
f0101141:	e8 d8 20 00 00       	call   f010321e <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0101146:	a1 6c 69 11 f0       	mov    0xf011696c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010114b:	83 c4 10             	add    $0x10,%esp
f010114e:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101153:	77 15                	ja     f010116a <mem_init+0xae>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101155:	50                   	push   %eax
f0101156:	68 c4 3c 10 f0       	push   $0xf0103cc4
f010115b:	68 92 00 00 00       	push   $0x92
f0101160:	68 54 43 10 f0       	push   $0xf0104354
f0101165:	e8 21 ef ff ff       	call   f010008b <_panic>
f010116a:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0101170:	83 ca 05             	or     $0x5,%edx
f0101173:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	pages = (struct PageInfo*)boot_alloc(npages * sizeof(struct PageInfo));
f0101179:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f010117e:	c1 e0 03             	shl    $0x3,%eax
f0101181:	e8 55 f7 ff ff       	call   f01008db <boot_alloc>
f0101186:	a3 70 69 11 f0       	mov    %eax,0xf0116970
	memset((void*)pages, 0, sizeof(npages * sizeof(struct PageInfo)));
f010118b:	83 ec 04             	sub    $0x4,%esp
f010118e:	6a 04                	push   $0x4
f0101190:	6a 00                	push   $0x0
f0101192:	50                   	push   %eax
f0101193:	e8 86 20 00 00       	call   f010321e <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f0101198:	e8 ca fa ff ff       	call   f0100c67 <page_init>

	check_page_free_list(1);
f010119d:	b8 01 00 00 00       	mov    $0x1,%eax
f01011a2:	e8 fd f7 ff ff       	call   f01009a4 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f01011a7:	83 c4 10             	add    $0x10,%esp
f01011aa:	83 3d 70 69 11 f0 00 	cmpl   $0x0,0xf0116970
f01011b1:	75 17                	jne    f01011ca <mem_init+0x10e>
		panic("'pages' is a null pointer!");
f01011b3:	83 ec 04             	sub    $0x4,%esp
f01011b6:	68 0a 44 10 f0       	push   $0xf010440a
f01011bb:	68 5f 02 00 00       	push   $0x25f
f01011c0:	68 54 43 10 f0       	push   $0xf0104354
f01011c5:	e8 c1 ee ff ff       	call   f010008b <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01011ca:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f01011cf:	bb 00 00 00 00       	mov    $0x0,%ebx
f01011d4:	eb 05                	jmp    f01011db <mem_init+0x11f>
		++nfree;
f01011d6:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01011d9:	8b 00                	mov    (%eax),%eax
f01011db:	85 c0                	test   %eax,%eax
f01011dd:	75 f7                	jne    f01011d6 <mem_init+0x11a>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01011df:	83 ec 0c             	sub    $0xc,%esp
f01011e2:	6a 00                	push   $0x0
f01011e4:	e8 92 fb ff ff       	call   f0100d7b <page_alloc>
f01011e9:	89 c7                	mov    %eax,%edi
f01011eb:	83 c4 10             	add    $0x10,%esp
f01011ee:	85 c0                	test   %eax,%eax
f01011f0:	75 19                	jne    f010120b <mem_init+0x14f>
f01011f2:	68 25 44 10 f0       	push   $0xf0104425
f01011f7:	68 7a 43 10 f0       	push   $0xf010437a
f01011fc:	68 67 02 00 00       	push   $0x267
f0101201:	68 54 43 10 f0       	push   $0xf0104354
f0101206:	e8 80 ee ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f010120b:	83 ec 0c             	sub    $0xc,%esp
f010120e:	6a 00                	push   $0x0
f0101210:	e8 66 fb ff ff       	call   f0100d7b <page_alloc>
f0101215:	89 c6                	mov    %eax,%esi
f0101217:	83 c4 10             	add    $0x10,%esp
f010121a:	85 c0                	test   %eax,%eax
f010121c:	75 19                	jne    f0101237 <mem_init+0x17b>
f010121e:	68 3b 44 10 f0       	push   $0xf010443b
f0101223:	68 7a 43 10 f0       	push   $0xf010437a
f0101228:	68 68 02 00 00       	push   $0x268
f010122d:	68 54 43 10 f0       	push   $0xf0104354
f0101232:	e8 54 ee ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0101237:	83 ec 0c             	sub    $0xc,%esp
f010123a:	6a 00                	push   $0x0
f010123c:	e8 3a fb ff ff       	call   f0100d7b <page_alloc>
f0101241:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101244:	83 c4 10             	add    $0x10,%esp
f0101247:	85 c0                	test   %eax,%eax
f0101249:	75 19                	jne    f0101264 <mem_init+0x1a8>
f010124b:	68 51 44 10 f0       	push   $0xf0104451
f0101250:	68 7a 43 10 f0       	push   $0xf010437a
f0101255:	68 69 02 00 00       	push   $0x269
f010125a:	68 54 43 10 f0       	push   $0xf0104354
f010125f:	e8 27 ee ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101264:	39 f7                	cmp    %esi,%edi
f0101266:	75 19                	jne    f0101281 <mem_init+0x1c5>
f0101268:	68 67 44 10 f0       	push   $0xf0104467
f010126d:	68 7a 43 10 f0       	push   $0xf010437a
f0101272:	68 6c 02 00 00       	push   $0x26c
f0101277:	68 54 43 10 f0       	push   $0xf0104354
f010127c:	e8 0a ee ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101281:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101284:	39 c6                	cmp    %eax,%esi
f0101286:	74 04                	je     f010128c <mem_init+0x1d0>
f0101288:	39 c7                	cmp    %eax,%edi
f010128a:	75 19                	jne    f01012a5 <mem_init+0x1e9>
f010128c:	68 68 3d 10 f0       	push   $0xf0103d68
f0101291:	68 7a 43 10 f0       	push   $0xf010437a
f0101296:	68 6d 02 00 00       	push   $0x26d
f010129b:	68 54 43 10 f0       	push   $0xf0104354
f01012a0:	e8 e6 ed ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01012a5:	8b 0d 70 69 11 f0    	mov    0xf0116970,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f01012ab:	8b 15 68 69 11 f0    	mov    0xf0116968,%edx
f01012b1:	c1 e2 0c             	shl    $0xc,%edx
f01012b4:	89 f8                	mov    %edi,%eax
f01012b6:	29 c8                	sub    %ecx,%eax
f01012b8:	c1 f8 03             	sar    $0x3,%eax
f01012bb:	c1 e0 0c             	shl    $0xc,%eax
f01012be:	39 d0                	cmp    %edx,%eax
f01012c0:	72 19                	jb     f01012db <mem_init+0x21f>
f01012c2:	68 79 44 10 f0       	push   $0xf0104479
f01012c7:	68 7a 43 10 f0       	push   $0xf010437a
f01012cc:	68 6e 02 00 00       	push   $0x26e
f01012d1:	68 54 43 10 f0       	push   $0xf0104354
f01012d6:	e8 b0 ed ff ff       	call   f010008b <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f01012db:	89 f0                	mov    %esi,%eax
f01012dd:	29 c8                	sub    %ecx,%eax
f01012df:	c1 f8 03             	sar    $0x3,%eax
f01012e2:	c1 e0 0c             	shl    $0xc,%eax
f01012e5:	39 c2                	cmp    %eax,%edx
f01012e7:	77 19                	ja     f0101302 <mem_init+0x246>
f01012e9:	68 96 44 10 f0       	push   $0xf0104496
f01012ee:	68 7a 43 10 f0       	push   $0xf010437a
f01012f3:	68 6f 02 00 00       	push   $0x26f
f01012f8:	68 54 43 10 f0       	push   $0xf0104354
f01012fd:	e8 89 ed ff ff       	call   f010008b <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f0101302:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101305:	29 c8                	sub    %ecx,%eax
f0101307:	c1 f8 03             	sar    $0x3,%eax
f010130a:	c1 e0 0c             	shl    $0xc,%eax
f010130d:	39 c2                	cmp    %eax,%edx
f010130f:	77 19                	ja     f010132a <mem_init+0x26e>
f0101311:	68 b3 44 10 f0       	push   $0xf01044b3
f0101316:	68 7a 43 10 f0       	push   $0xf010437a
f010131b:	68 70 02 00 00       	push   $0x270
f0101320:	68 54 43 10 f0       	push   $0xf0104354
f0101325:	e8 61 ed ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f010132a:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f010132f:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101332:	c7 05 3c 65 11 f0 00 	movl   $0x0,0xf011653c
f0101339:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f010133c:	83 ec 0c             	sub    $0xc,%esp
f010133f:	6a 00                	push   $0x0
f0101341:	e8 35 fa ff ff       	call   f0100d7b <page_alloc>
f0101346:	83 c4 10             	add    $0x10,%esp
f0101349:	85 c0                	test   %eax,%eax
f010134b:	74 19                	je     f0101366 <mem_init+0x2aa>
f010134d:	68 d0 44 10 f0       	push   $0xf01044d0
f0101352:	68 7a 43 10 f0       	push   $0xf010437a
f0101357:	68 77 02 00 00       	push   $0x277
f010135c:	68 54 43 10 f0       	push   $0xf0104354
f0101361:	e8 25 ed ff ff       	call   f010008b <_panic>

	// free and re-allocate?
	page_free(pp0);
f0101366:	83 ec 0c             	sub    $0xc,%esp
f0101369:	57                   	push   %edi
f010136a:	e8 7c fa ff ff       	call   f0100deb <page_free>
	page_free(pp1);
f010136f:	89 34 24             	mov    %esi,(%esp)
f0101372:	e8 74 fa ff ff       	call   f0100deb <page_free>
	page_free(pp2);
f0101377:	83 c4 04             	add    $0x4,%esp
f010137a:	ff 75 d4             	pushl  -0x2c(%ebp)
f010137d:	e8 69 fa ff ff       	call   f0100deb <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101382:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101389:	e8 ed f9 ff ff       	call   f0100d7b <page_alloc>
f010138e:	89 c6                	mov    %eax,%esi
f0101390:	83 c4 10             	add    $0x10,%esp
f0101393:	85 c0                	test   %eax,%eax
f0101395:	75 19                	jne    f01013b0 <mem_init+0x2f4>
f0101397:	68 25 44 10 f0       	push   $0xf0104425
f010139c:	68 7a 43 10 f0       	push   $0xf010437a
f01013a1:	68 7e 02 00 00       	push   $0x27e
f01013a6:	68 54 43 10 f0       	push   $0xf0104354
f01013ab:	e8 db ec ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f01013b0:	83 ec 0c             	sub    $0xc,%esp
f01013b3:	6a 00                	push   $0x0
f01013b5:	e8 c1 f9 ff ff       	call   f0100d7b <page_alloc>
f01013ba:	89 c7                	mov    %eax,%edi
f01013bc:	83 c4 10             	add    $0x10,%esp
f01013bf:	85 c0                	test   %eax,%eax
f01013c1:	75 19                	jne    f01013dc <mem_init+0x320>
f01013c3:	68 3b 44 10 f0       	push   $0xf010443b
f01013c8:	68 7a 43 10 f0       	push   $0xf010437a
f01013cd:	68 7f 02 00 00       	push   $0x27f
f01013d2:	68 54 43 10 f0       	push   $0xf0104354
f01013d7:	e8 af ec ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f01013dc:	83 ec 0c             	sub    $0xc,%esp
f01013df:	6a 00                	push   $0x0
f01013e1:	e8 95 f9 ff ff       	call   f0100d7b <page_alloc>
f01013e6:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01013e9:	83 c4 10             	add    $0x10,%esp
f01013ec:	85 c0                	test   %eax,%eax
f01013ee:	75 19                	jne    f0101409 <mem_init+0x34d>
f01013f0:	68 51 44 10 f0       	push   $0xf0104451
f01013f5:	68 7a 43 10 f0       	push   $0xf010437a
f01013fa:	68 80 02 00 00       	push   $0x280
f01013ff:	68 54 43 10 f0       	push   $0xf0104354
f0101404:	e8 82 ec ff ff       	call   f010008b <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101409:	39 fe                	cmp    %edi,%esi
f010140b:	75 19                	jne    f0101426 <mem_init+0x36a>
f010140d:	68 67 44 10 f0       	push   $0xf0104467
f0101412:	68 7a 43 10 f0       	push   $0xf010437a
f0101417:	68 82 02 00 00       	push   $0x282
f010141c:	68 54 43 10 f0       	push   $0xf0104354
f0101421:	e8 65 ec ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101426:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101429:	39 c7                	cmp    %eax,%edi
f010142b:	74 04                	je     f0101431 <mem_init+0x375>
f010142d:	39 c6                	cmp    %eax,%esi
f010142f:	75 19                	jne    f010144a <mem_init+0x38e>
f0101431:	68 68 3d 10 f0       	push   $0xf0103d68
f0101436:	68 7a 43 10 f0       	push   $0xf010437a
f010143b:	68 83 02 00 00       	push   $0x283
f0101440:	68 54 43 10 f0       	push   $0xf0104354
f0101445:	e8 41 ec ff ff       	call   f010008b <_panic>
	assert(!page_alloc(0));
f010144a:	83 ec 0c             	sub    $0xc,%esp
f010144d:	6a 00                	push   $0x0
f010144f:	e8 27 f9 ff ff       	call   f0100d7b <page_alloc>
f0101454:	83 c4 10             	add    $0x10,%esp
f0101457:	85 c0                	test   %eax,%eax
f0101459:	74 19                	je     f0101474 <mem_init+0x3b8>
f010145b:	68 d0 44 10 f0       	push   $0xf01044d0
f0101460:	68 7a 43 10 f0       	push   $0xf010437a
f0101465:	68 84 02 00 00       	push   $0x284
f010146a:	68 54 43 10 f0       	push   $0xf0104354
f010146f:	e8 17 ec ff ff       	call   f010008b <_panic>
f0101474:	89 f0                	mov    %esi,%eax
f0101476:	2b 05 70 69 11 f0    	sub    0xf0116970,%eax
f010147c:	c1 f8 03             	sar    $0x3,%eax
f010147f:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101482:	89 c2                	mov    %eax,%edx
f0101484:	c1 ea 0c             	shr    $0xc,%edx
f0101487:	3b 15 68 69 11 f0    	cmp    0xf0116968,%edx
f010148d:	72 12                	jb     f01014a1 <mem_init+0x3e5>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010148f:	50                   	push   %eax
f0101490:	68 b8 3b 10 f0       	push   $0xf0103bb8
f0101495:	6a 52                	push   $0x52
f0101497:	68 60 43 10 f0       	push   $0xf0104360
f010149c:	e8 ea eb ff ff       	call   f010008b <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f01014a1:	83 ec 04             	sub    $0x4,%esp
f01014a4:	68 00 10 00 00       	push   $0x1000
f01014a9:	6a 01                	push   $0x1
f01014ab:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01014b0:	50                   	push   %eax
f01014b1:	e8 68 1d 00 00       	call   f010321e <memset>
	page_free(pp0);
f01014b6:	89 34 24             	mov    %esi,(%esp)
f01014b9:	e8 2d f9 ff ff       	call   f0100deb <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01014be:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01014c5:	e8 b1 f8 ff ff       	call   f0100d7b <page_alloc>
f01014ca:	83 c4 10             	add    $0x10,%esp
f01014cd:	85 c0                	test   %eax,%eax
f01014cf:	75 19                	jne    f01014ea <mem_init+0x42e>
f01014d1:	68 df 44 10 f0       	push   $0xf01044df
f01014d6:	68 7a 43 10 f0       	push   $0xf010437a
f01014db:	68 89 02 00 00       	push   $0x289
f01014e0:	68 54 43 10 f0       	push   $0xf0104354
f01014e5:	e8 a1 eb ff ff       	call   f010008b <_panic>
	assert(pp && pp0 == pp);
f01014ea:	39 c6                	cmp    %eax,%esi
f01014ec:	74 19                	je     f0101507 <mem_init+0x44b>
f01014ee:	68 fd 44 10 f0       	push   $0xf01044fd
f01014f3:	68 7a 43 10 f0       	push   $0xf010437a
f01014f8:	68 8a 02 00 00       	push   $0x28a
f01014fd:	68 54 43 10 f0       	push   $0xf0104354
f0101502:	e8 84 eb ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101507:	89 f0                	mov    %esi,%eax
f0101509:	2b 05 70 69 11 f0    	sub    0xf0116970,%eax
f010150f:	c1 f8 03             	sar    $0x3,%eax
f0101512:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101515:	89 c2                	mov    %eax,%edx
f0101517:	c1 ea 0c             	shr    $0xc,%edx
f010151a:	3b 15 68 69 11 f0    	cmp    0xf0116968,%edx
f0101520:	72 12                	jb     f0101534 <mem_init+0x478>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101522:	50                   	push   %eax
f0101523:	68 b8 3b 10 f0       	push   $0xf0103bb8
f0101528:	6a 52                	push   $0x52
f010152a:	68 60 43 10 f0       	push   $0xf0104360
f010152f:	e8 57 eb ff ff       	call   f010008b <_panic>
f0101534:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f010153a:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f0101540:	80 38 00             	cmpb   $0x0,(%eax)
f0101543:	74 19                	je     f010155e <mem_init+0x4a2>
f0101545:	68 0d 45 10 f0       	push   $0xf010450d
f010154a:	68 7a 43 10 f0       	push   $0xf010437a
f010154f:	68 8d 02 00 00       	push   $0x28d
f0101554:	68 54 43 10 f0       	push   $0xf0104354
f0101559:	e8 2d eb ff ff       	call   f010008b <_panic>
f010155e:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f0101561:	39 d0                	cmp    %edx,%eax
f0101563:	75 db                	jne    f0101540 <mem_init+0x484>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101565:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101568:	a3 3c 65 11 f0       	mov    %eax,0xf011653c

	// free the pages we took
	page_free(pp0);
f010156d:	83 ec 0c             	sub    $0xc,%esp
f0101570:	56                   	push   %esi
f0101571:	e8 75 f8 ff ff       	call   f0100deb <page_free>
	page_free(pp1);
f0101576:	89 3c 24             	mov    %edi,(%esp)
f0101579:	e8 6d f8 ff ff       	call   f0100deb <page_free>
	page_free(pp2);
f010157e:	83 c4 04             	add    $0x4,%esp
f0101581:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101584:	e8 62 f8 ff ff       	call   f0100deb <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101589:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f010158e:	83 c4 10             	add    $0x10,%esp
f0101591:	eb 05                	jmp    f0101598 <mem_init+0x4dc>
		--nfree;
f0101593:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101596:	8b 00                	mov    (%eax),%eax
f0101598:	85 c0                	test   %eax,%eax
f010159a:	75 f7                	jne    f0101593 <mem_init+0x4d7>
		--nfree;
	assert(nfree == 0);
f010159c:	85 db                	test   %ebx,%ebx
f010159e:	74 19                	je     f01015b9 <mem_init+0x4fd>
f01015a0:	68 17 45 10 f0       	push   $0xf0104517
f01015a5:	68 7a 43 10 f0       	push   $0xf010437a
f01015aa:	68 9a 02 00 00       	push   $0x29a
f01015af:	68 54 43 10 f0       	push   $0xf0104354
f01015b4:	e8 d2 ea ff ff       	call   f010008b <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f01015b9:	83 ec 0c             	sub    $0xc,%esp
f01015bc:	68 88 3d 10 f0       	push   $0xf0103d88
f01015c1:	e8 9f 11 00 00       	call   f0102765 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01015c6:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01015cd:	e8 a9 f7 ff ff       	call   f0100d7b <page_alloc>
f01015d2:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01015d5:	83 c4 10             	add    $0x10,%esp
f01015d8:	85 c0                	test   %eax,%eax
f01015da:	75 19                	jne    f01015f5 <mem_init+0x539>
f01015dc:	68 25 44 10 f0       	push   $0xf0104425
f01015e1:	68 7a 43 10 f0       	push   $0xf010437a
f01015e6:	68 f3 02 00 00       	push   $0x2f3
f01015eb:	68 54 43 10 f0       	push   $0xf0104354
f01015f0:	e8 96 ea ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f01015f5:	83 ec 0c             	sub    $0xc,%esp
f01015f8:	6a 00                	push   $0x0
f01015fa:	e8 7c f7 ff ff       	call   f0100d7b <page_alloc>
f01015ff:	89 c3                	mov    %eax,%ebx
f0101601:	83 c4 10             	add    $0x10,%esp
f0101604:	85 c0                	test   %eax,%eax
f0101606:	75 19                	jne    f0101621 <mem_init+0x565>
f0101608:	68 3b 44 10 f0       	push   $0xf010443b
f010160d:	68 7a 43 10 f0       	push   $0xf010437a
f0101612:	68 f4 02 00 00       	push   $0x2f4
f0101617:	68 54 43 10 f0       	push   $0xf0104354
f010161c:	e8 6a ea ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0101621:	83 ec 0c             	sub    $0xc,%esp
f0101624:	6a 00                	push   $0x0
f0101626:	e8 50 f7 ff ff       	call   f0100d7b <page_alloc>
f010162b:	89 c6                	mov    %eax,%esi
f010162d:	83 c4 10             	add    $0x10,%esp
f0101630:	85 c0                	test   %eax,%eax
f0101632:	75 19                	jne    f010164d <mem_init+0x591>
f0101634:	68 51 44 10 f0       	push   $0xf0104451
f0101639:	68 7a 43 10 f0       	push   $0xf010437a
f010163e:	68 f5 02 00 00       	push   $0x2f5
f0101643:	68 54 43 10 f0       	push   $0xf0104354
f0101648:	e8 3e ea ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010164d:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0101650:	75 19                	jne    f010166b <mem_init+0x5af>
f0101652:	68 67 44 10 f0       	push   $0xf0104467
f0101657:	68 7a 43 10 f0       	push   $0xf010437a
f010165c:	68 f8 02 00 00       	push   $0x2f8
f0101661:	68 54 43 10 f0       	push   $0xf0104354
f0101666:	e8 20 ea ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010166b:	39 c3                	cmp    %eax,%ebx
f010166d:	74 05                	je     f0101674 <mem_init+0x5b8>
f010166f:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101672:	75 19                	jne    f010168d <mem_init+0x5d1>
f0101674:	68 68 3d 10 f0       	push   $0xf0103d68
f0101679:	68 7a 43 10 f0       	push   $0xf010437a
f010167e:	68 f9 02 00 00       	push   $0x2f9
f0101683:	68 54 43 10 f0       	push   $0xf0104354
f0101688:	e8 fe e9 ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f010168d:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f0101692:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101695:	c7 05 3c 65 11 f0 00 	movl   $0x0,0xf011653c
f010169c:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f010169f:	83 ec 0c             	sub    $0xc,%esp
f01016a2:	6a 00                	push   $0x0
f01016a4:	e8 d2 f6 ff ff       	call   f0100d7b <page_alloc>
f01016a9:	83 c4 10             	add    $0x10,%esp
f01016ac:	85 c0                	test   %eax,%eax
f01016ae:	74 19                	je     f01016c9 <mem_init+0x60d>
f01016b0:	68 d0 44 10 f0       	push   $0xf01044d0
f01016b5:	68 7a 43 10 f0       	push   $0xf010437a
f01016ba:	68 00 03 00 00       	push   $0x300
f01016bf:	68 54 43 10 f0       	push   $0xf0104354
f01016c4:	e8 c2 e9 ff ff       	call   f010008b <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f01016c9:	83 ec 04             	sub    $0x4,%esp
f01016cc:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01016cf:	50                   	push   %eax
f01016d0:	6a 00                	push   $0x0
f01016d2:	ff 35 6c 69 11 f0    	pushl  0xf011696c
f01016d8:	e8 ec f8 ff ff       	call   f0100fc9 <page_lookup>
f01016dd:	83 c4 10             	add    $0x10,%esp
f01016e0:	85 c0                	test   %eax,%eax
f01016e2:	74 19                	je     f01016fd <mem_init+0x641>
f01016e4:	68 a8 3d 10 f0       	push   $0xf0103da8
f01016e9:	68 7a 43 10 f0       	push   $0xf010437a
f01016ee:	68 03 03 00 00       	push   $0x303
f01016f3:	68 54 43 10 f0       	push   $0xf0104354
f01016f8:	e8 8e e9 ff ff       	call   f010008b <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f01016fd:	6a 02                	push   $0x2
f01016ff:	6a 00                	push   $0x0
f0101701:	53                   	push   %ebx
f0101702:	ff 35 6c 69 11 f0    	pushl  0xf011696c
f0101708:	e8 49 f9 ff ff       	call   f0101056 <page_insert>
f010170d:	83 c4 10             	add    $0x10,%esp
f0101710:	85 c0                	test   %eax,%eax
f0101712:	78 19                	js     f010172d <mem_init+0x671>
f0101714:	68 e0 3d 10 f0       	push   $0xf0103de0
f0101719:	68 7a 43 10 f0       	push   $0xf010437a
f010171e:	68 06 03 00 00       	push   $0x306
f0101723:	68 54 43 10 f0       	push   $0xf0104354
f0101728:	e8 5e e9 ff ff       	call   f010008b <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f010172d:	83 ec 0c             	sub    $0xc,%esp
f0101730:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101733:	e8 b3 f6 ff ff       	call   f0100deb <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101738:	6a 02                	push   $0x2
f010173a:	6a 00                	push   $0x0
f010173c:	53                   	push   %ebx
f010173d:	ff 35 6c 69 11 f0    	pushl  0xf011696c
f0101743:	e8 0e f9 ff ff       	call   f0101056 <page_insert>
f0101748:	83 c4 20             	add    $0x20,%esp
f010174b:	85 c0                	test   %eax,%eax
f010174d:	74 19                	je     f0101768 <mem_init+0x6ac>
f010174f:	68 10 3e 10 f0       	push   $0xf0103e10
f0101754:	68 7a 43 10 f0       	push   $0xf010437a
f0101759:	68 0a 03 00 00       	push   $0x30a
f010175e:	68 54 43 10 f0       	push   $0xf0104354
f0101763:	e8 23 e9 ff ff       	call   f010008b <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101768:	8b 3d 6c 69 11 f0    	mov    0xf011696c,%edi
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010176e:	a1 70 69 11 f0       	mov    0xf0116970,%eax
f0101773:	89 c1                	mov    %eax,%ecx
f0101775:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101778:	8b 17                	mov    (%edi),%edx
f010177a:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101780:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101783:	29 c8                	sub    %ecx,%eax
f0101785:	c1 f8 03             	sar    $0x3,%eax
f0101788:	c1 e0 0c             	shl    $0xc,%eax
f010178b:	39 c2                	cmp    %eax,%edx
f010178d:	74 19                	je     f01017a8 <mem_init+0x6ec>
f010178f:	68 40 3e 10 f0       	push   $0xf0103e40
f0101794:	68 7a 43 10 f0       	push   $0xf010437a
f0101799:	68 0b 03 00 00       	push   $0x30b
f010179e:	68 54 43 10 f0       	push   $0xf0104354
f01017a3:	e8 e3 e8 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f01017a8:	ba 00 00 00 00       	mov    $0x0,%edx
f01017ad:	89 f8                	mov    %edi,%eax
f01017af:	e8 8c f1 ff ff       	call   f0100940 <check_va2pa>
f01017b4:	89 da                	mov    %ebx,%edx
f01017b6:	2b 55 cc             	sub    -0x34(%ebp),%edx
f01017b9:	c1 fa 03             	sar    $0x3,%edx
f01017bc:	c1 e2 0c             	shl    $0xc,%edx
f01017bf:	39 d0                	cmp    %edx,%eax
f01017c1:	74 19                	je     f01017dc <mem_init+0x720>
f01017c3:	68 68 3e 10 f0       	push   $0xf0103e68
f01017c8:	68 7a 43 10 f0       	push   $0xf010437a
f01017cd:	68 0c 03 00 00       	push   $0x30c
f01017d2:	68 54 43 10 f0       	push   $0xf0104354
f01017d7:	e8 af e8 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f01017dc:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01017e1:	74 19                	je     f01017fc <mem_init+0x740>
f01017e3:	68 22 45 10 f0       	push   $0xf0104522
f01017e8:	68 7a 43 10 f0       	push   $0xf010437a
f01017ed:	68 0d 03 00 00       	push   $0x30d
f01017f2:	68 54 43 10 f0       	push   $0xf0104354
f01017f7:	e8 8f e8 ff ff       	call   f010008b <_panic>
	assert(pp0->pp_ref == 1);
f01017fc:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01017ff:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101804:	74 19                	je     f010181f <mem_init+0x763>
f0101806:	68 33 45 10 f0       	push   $0xf0104533
f010180b:	68 7a 43 10 f0       	push   $0xf010437a
f0101810:	68 0e 03 00 00       	push   $0x30e
f0101815:	68 54 43 10 f0       	push   $0xf0104354
f010181a:	e8 6c e8 ff ff       	call   f010008b <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f010181f:	6a 02                	push   $0x2
f0101821:	68 00 10 00 00       	push   $0x1000
f0101826:	56                   	push   %esi
f0101827:	57                   	push   %edi
f0101828:	e8 29 f8 ff ff       	call   f0101056 <page_insert>
f010182d:	83 c4 10             	add    $0x10,%esp
f0101830:	85 c0                	test   %eax,%eax
f0101832:	74 19                	je     f010184d <mem_init+0x791>
f0101834:	68 98 3e 10 f0       	push   $0xf0103e98
f0101839:	68 7a 43 10 f0       	push   $0xf010437a
f010183e:	68 11 03 00 00       	push   $0x311
f0101843:	68 54 43 10 f0       	push   $0xf0104354
f0101848:	e8 3e e8 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f010184d:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101852:	a1 6c 69 11 f0       	mov    0xf011696c,%eax
f0101857:	e8 e4 f0 ff ff       	call   f0100940 <check_va2pa>
f010185c:	89 f2                	mov    %esi,%edx
f010185e:	2b 15 70 69 11 f0    	sub    0xf0116970,%edx
f0101864:	c1 fa 03             	sar    $0x3,%edx
f0101867:	c1 e2 0c             	shl    $0xc,%edx
f010186a:	39 d0                	cmp    %edx,%eax
f010186c:	74 19                	je     f0101887 <mem_init+0x7cb>
f010186e:	68 d4 3e 10 f0       	push   $0xf0103ed4
f0101873:	68 7a 43 10 f0       	push   $0xf010437a
f0101878:	68 12 03 00 00       	push   $0x312
f010187d:	68 54 43 10 f0       	push   $0xf0104354
f0101882:	e8 04 e8 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f0101887:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f010188c:	74 19                	je     f01018a7 <mem_init+0x7eb>
f010188e:	68 44 45 10 f0       	push   $0xf0104544
f0101893:	68 7a 43 10 f0       	push   $0xf010437a
f0101898:	68 13 03 00 00       	push   $0x313
f010189d:	68 54 43 10 f0       	push   $0xf0104354
f01018a2:	e8 e4 e7 ff ff       	call   f010008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f01018a7:	83 ec 0c             	sub    $0xc,%esp
f01018aa:	6a 00                	push   $0x0
f01018ac:	e8 ca f4 ff ff       	call   f0100d7b <page_alloc>
f01018b1:	83 c4 10             	add    $0x10,%esp
f01018b4:	85 c0                	test   %eax,%eax
f01018b6:	74 19                	je     f01018d1 <mem_init+0x815>
f01018b8:	68 d0 44 10 f0       	push   $0xf01044d0
f01018bd:	68 7a 43 10 f0       	push   $0xf010437a
f01018c2:	68 16 03 00 00       	push   $0x316
f01018c7:	68 54 43 10 f0       	push   $0xf0104354
f01018cc:	e8 ba e7 ff ff       	call   f010008b <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01018d1:	6a 02                	push   $0x2
f01018d3:	68 00 10 00 00       	push   $0x1000
f01018d8:	56                   	push   %esi
f01018d9:	ff 35 6c 69 11 f0    	pushl  0xf011696c
f01018df:	e8 72 f7 ff ff       	call   f0101056 <page_insert>
f01018e4:	83 c4 10             	add    $0x10,%esp
f01018e7:	85 c0                	test   %eax,%eax
f01018e9:	74 19                	je     f0101904 <mem_init+0x848>
f01018eb:	68 98 3e 10 f0       	push   $0xf0103e98
f01018f0:	68 7a 43 10 f0       	push   $0xf010437a
f01018f5:	68 19 03 00 00       	push   $0x319
f01018fa:	68 54 43 10 f0       	push   $0xf0104354
f01018ff:	e8 87 e7 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101904:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101909:	a1 6c 69 11 f0       	mov    0xf011696c,%eax
f010190e:	e8 2d f0 ff ff       	call   f0100940 <check_va2pa>
f0101913:	89 f2                	mov    %esi,%edx
f0101915:	2b 15 70 69 11 f0    	sub    0xf0116970,%edx
f010191b:	c1 fa 03             	sar    $0x3,%edx
f010191e:	c1 e2 0c             	shl    $0xc,%edx
f0101921:	39 d0                	cmp    %edx,%eax
f0101923:	74 19                	je     f010193e <mem_init+0x882>
f0101925:	68 d4 3e 10 f0       	push   $0xf0103ed4
f010192a:	68 7a 43 10 f0       	push   $0xf010437a
f010192f:	68 1a 03 00 00       	push   $0x31a
f0101934:	68 54 43 10 f0       	push   $0xf0104354
f0101939:	e8 4d e7 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f010193e:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101943:	74 19                	je     f010195e <mem_init+0x8a2>
f0101945:	68 44 45 10 f0       	push   $0xf0104544
f010194a:	68 7a 43 10 f0       	push   $0xf010437a
f010194f:	68 1b 03 00 00       	push   $0x31b
f0101954:	68 54 43 10 f0       	push   $0xf0104354
f0101959:	e8 2d e7 ff ff       	call   f010008b <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f010195e:	83 ec 0c             	sub    $0xc,%esp
f0101961:	6a 00                	push   $0x0
f0101963:	e8 13 f4 ff ff       	call   f0100d7b <page_alloc>
f0101968:	83 c4 10             	add    $0x10,%esp
f010196b:	85 c0                	test   %eax,%eax
f010196d:	74 19                	je     f0101988 <mem_init+0x8cc>
f010196f:	68 d0 44 10 f0       	push   $0xf01044d0
f0101974:	68 7a 43 10 f0       	push   $0xf010437a
f0101979:	68 1f 03 00 00       	push   $0x31f
f010197e:	68 54 43 10 f0       	push   $0xf0104354
f0101983:	e8 03 e7 ff ff       	call   f010008b <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101988:	8b 15 6c 69 11 f0    	mov    0xf011696c,%edx
f010198e:	8b 02                	mov    (%edx),%eax
f0101990:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101995:	89 c1                	mov    %eax,%ecx
f0101997:	c1 e9 0c             	shr    $0xc,%ecx
f010199a:	3b 0d 68 69 11 f0    	cmp    0xf0116968,%ecx
f01019a0:	72 15                	jb     f01019b7 <mem_init+0x8fb>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01019a2:	50                   	push   %eax
f01019a3:	68 b8 3b 10 f0       	push   $0xf0103bb8
f01019a8:	68 22 03 00 00       	push   $0x322
f01019ad:	68 54 43 10 f0       	push   $0xf0104354
f01019b2:	e8 d4 e6 ff ff       	call   f010008b <_panic>
f01019b7:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01019bc:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f01019bf:	83 ec 04             	sub    $0x4,%esp
f01019c2:	6a 00                	push   $0x0
f01019c4:	68 00 10 00 00       	push   $0x1000
f01019c9:	52                   	push   %edx
f01019ca:	e8 c1 f4 ff ff       	call   f0100e90 <pgdir_walk>
f01019cf:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f01019d2:	8d 51 04             	lea    0x4(%ecx),%edx
f01019d5:	83 c4 10             	add    $0x10,%esp
f01019d8:	39 d0                	cmp    %edx,%eax
f01019da:	74 19                	je     f01019f5 <mem_init+0x939>
f01019dc:	68 04 3f 10 f0       	push   $0xf0103f04
f01019e1:	68 7a 43 10 f0       	push   $0xf010437a
f01019e6:	68 23 03 00 00       	push   $0x323
f01019eb:	68 54 43 10 f0       	push   $0xf0104354
f01019f0:	e8 96 e6 ff ff       	call   f010008b <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f01019f5:	6a 06                	push   $0x6
f01019f7:	68 00 10 00 00       	push   $0x1000
f01019fc:	56                   	push   %esi
f01019fd:	ff 35 6c 69 11 f0    	pushl  0xf011696c
f0101a03:	e8 4e f6 ff ff       	call   f0101056 <page_insert>
f0101a08:	83 c4 10             	add    $0x10,%esp
f0101a0b:	85 c0                	test   %eax,%eax
f0101a0d:	74 19                	je     f0101a28 <mem_init+0x96c>
f0101a0f:	68 44 3f 10 f0       	push   $0xf0103f44
f0101a14:	68 7a 43 10 f0       	push   $0xf010437a
f0101a19:	68 26 03 00 00       	push   $0x326
f0101a1e:	68 54 43 10 f0       	push   $0xf0104354
f0101a23:	e8 63 e6 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101a28:	8b 3d 6c 69 11 f0    	mov    0xf011696c,%edi
f0101a2e:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101a33:	89 f8                	mov    %edi,%eax
f0101a35:	e8 06 ef ff ff       	call   f0100940 <check_va2pa>
f0101a3a:	89 f2                	mov    %esi,%edx
f0101a3c:	2b 15 70 69 11 f0    	sub    0xf0116970,%edx
f0101a42:	c1 fa 03             	sar    $0x3,%edx
f0101a45:	c1 e2 0c             	shl    $0xc,%edx
f0101a48:	39 d0                	cmp    %edx,%eax
f0101a4a:	74 19                	je     f0101a65 <mem_init+0x9a9>
f0101a4c:	68 d4 3e 10 f0       	push   $0xf0103ed4
f0101a51:	68 7a 43 10 f0       	push   $0xf010437a
f0101a56:	68 27 03 00 00       	push   $0x327
f0101a5b:	68 54 43 10 f0       	push   $0xf0104354
f0101a60:	e8 26 e6 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f0101a65:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101a6a:	74 19                	je     f0101a85 <mem_init+0x9c9>
f0101a6c:	68 44 45 10 f0       	push   $0xf0104544
f0101a71:	68 7a 43 10 f0       	push   $0xf010437a
f0101a76:	68 28 03 00 00       	push   $0x328
f0101a7b:	68 54 43 10 f0       	push   $0xf0104354
f0101a80:	e8 06 e6 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101a85:	83 ec 04             	sub    $0x4,%esp
f0101a88:	6a 00                	push   $0x0
f0101a8a:	68 00 10 00 00       	push   $0x1000
f0101a8f:	57                   	push   %edi
f0101a90:	e8 fb f3 ff ff       	call   f0100e90 <pgdir_walk>
f0101a95:	83 c4 10             	add    $0x10,%esp
f0101a98:	f6 00 04             	testb  $0x4,(%eax)
f0101a9b:	75 19                	jne    f0101ab6 <mem_init+0x9fa>
f0101a9d:	68 84 3f 10 f0       	push   $0xf0103f84
f0101aa2:	68 7a 43 10 f0       	push   $0xf010437a
f0101aa7:	68 29 03 00 00       	push   $0x329
f0101aac:	68 54 43 10 f0       	push   $0xf0104354
f0101ab1:	e8 d5 e5 ff ff       	call   f010008b <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101ab6:	a1 6c 69 11 f0       	mov    0xf011696c,%eax
f0101abb:	f6 00 04             	testb  $0x4,(%eax)
f0101abe:	75 19                	jne    f0101ad9 <mem_init+0xa1d>
f0101ac0:	68 55 45 10 f0       	push   $0xf0104555
f0101ac5:	68 7a 43 10 f0       	push   $0xf010437a
f0101aca:	68 2a 03 00 00       	push   $0x32a
f0101acf:	68 54 43 10 f0       	push   $0xf0104354
f0101ad4:	e8 b2 e5 ff ff       	call   f010008b <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101ad9:	6a 02                	push   $0x2
f0101adb:	68 00 10 00 00       	push   $0x1000
f0101ae0:	56                   	push   %esi
f0101ae1:	50                   	push   %eax
f0101ae2:	e8 6f f5 ff ff       	call   f0101056 <page_insert>
f0101ae7:	83 c4 10             	add    $0x10,%esp
f0101aea:	85 c0                	test   %eax,%eax
f0101aec:	74 19                	je     f0101b07 <mem_init+0xa4b>
f0101aee:	68 98 3e 10 f0       	push   $0xf0103e98
f0101af3:	68 7a 43 10 f0       	push   $0xf010437a
f0101af8:	68 2d 03 00 00       	push   $0x32d
f0101afd:	68 54 43 10 f0       	push   $0xf0104354
f0101b02:	e8 84 e5 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101b07:	83 ec 04             	sub    $0x4,%esp
f0101b0a:	6a 00                	push   $0x0
f0101b0c:	68 00 10 00 00       	push   $0x1000
f0101b11:	ff 35 6c 69 11 f0    	pushl  0xf011696c
f0101b17:	e8 74 f3 ff ff       	call   f0100e90 <pgdir_walk>
f0101b1c:	83 c4 10             	add    $0x10,%esp
f0101b1f:	f6 00 02             	testb  $0x2,(%eax)
f0101b22:	75 19                	jne    f0101b3d <mem_init+0xa81>
f0101b24:	68 b8 3f 10 f0       	push   $0xf0103fb8
f0101b29:	68 7a 43 10 f0       	push   $0xf010437a
f0101b2e:	68 2e 03 00 00       	push   $0x32e
f0101b33:	68 54 43 10 f0       	push   $0xf0104354
f0101b38:	e8 4e e5 ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101b3d:	83 ec 04             	sub    $0x4,%esp
f0101b40:	6a 00                	push   $0x0
f0101b42:	68 00 10 00 00       	push   $0x1000
f0101b47:	ff 35 6c 69 11 f0    	pushl  0xf011696c
f0101b4d:	e8 3e f3 ff ff       	call   f0100e90 <pgdir_walk>
f0101b52:	83 c4 10             	add    $0x10,%esp
f0101b55:	f6 00 04             	testb  $0x4,(%eax)
f0101b58:	74 19                	je     f0101b73 <mem_init+0xab7>
f0101b5a:	68 ec 3f 10 f0       	push   $0xf0103fec
f0101b5f:	68 7a 43 10 f0       	push   $0xf010437a
f0101b64:	68 2f 03 00 00       	push   $0x32f
f0101b69:	68 54 43 10 f0       	push   $0xf0104354
f0101b6e:	e8 18 e5 ff ff       	call   f010008b <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101b73:	6a 02                	push   $0x2
f0101b75:	68 00 00 40 00       	push   $0x400000
f0101b7a:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101b7d:	ff 35 6c 69 11 f0    	pushl  0xf011696c
f0101b83:	e8 ce f4 ff ff       	call   f0101056 <page_insert>
f0101b88:	83 c4 10             	add    $0x10,%esp
f0101b8b:	85 c0                	test   %eax,%eax
f0101b8d:	78 19                	js     f0101ba8 <mem_init+0xaec>
f0101b8f:	68 24 40 10 f0       	push   $0xf0104024
f0101b94:	68 7a 43 10 f0       	push   $0xf010437a
f0101b99:	68 32 03 00 00       	push   $0x332
f0101b9e:	68 54 43 10 f0       	push   $0xf0104354
f0101ba3:	e8 e3 e4 ff ff       	call   f010008b <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101ba8:	6a 02                	push   $0x2
f0101baa:	68 00 10 00 00       	push   $0x1000
f0101baf:	53                   	push   %ebx
f0101bb0:	ff 35 6c 69 11 f0    	pushl  0xf011696c
f0101bb6:	e8 9b f4 ff ff       	call   f0101056 <page_insert>
f0101bbb:	83 c4 10             	add    $0x10,%esp
f0101bbe:	85 c0                	test   %eax,%eax
f0101bc0:	74 19                	je     f0101bdb <mem_init+0xb1f>
f0101bc2:	68 5c 40 10 f0       	push   $0xf010405c
f0101bc7:	68 7a 43 10 f0       	push   $0xf010437a
f0101bcc:	68 35 03 00 00       	push   $0x335
f0101bd1:	68 54 43 10 f0       	push   $0xf0104354
f0101bd6:	e8 b0 e4 ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101bdb:	83 ec 04             	sub    $0x4,%esp
f0101bde:	6a 00                	push   $0x0
f0101be0:	68 00 10 00 00       	push   $0x1000
f0101be5:	ff 35 6c 69 11 f0    	pushl  0xf011696c
f0101beb:	e8 a0 f2 ff ff       	call   f0100e90 <pgdir_walk>
f0101bf0:	83 c4 10             	add    $0x10,%esp
f0101bf3:	f6 00 04             	testb  $0x4,(%eax)
f0101bf6:	74 19                	je     f0101c11 <mem_init+0xb55>
f0101bf8:	68 ec 3f 10 f0       	push   $0xf0103fec
f0101bfd:	68 7a 43 10 f0       	push   $0xf010437a
f0101c02:	68 36 03 00 00       	push   $0x336
f0101c07:	68 54 43 10 f0       	push   $0xf0104354
f0101c0c:	e8 7a e4 ff ff       	call   f010008b <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101c11:	8b 3d 6c 69 11 f0    	mov    0xf011696c,%edi
f0101c17:	ba 00 00 00 00       	mov    $0x0,%edx
f0101c1c:	89 f8                	mov    %edi,%eax
f0101c1e:	e8 1d ed ff ff       	call   f0100940 <check_va2pa>
f0101c23:	89 c1                	mov    %eax,%ecx
f0101c25:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101c28:	89 d8                	mov    %ebx,%eax
f0101c2a:	2b 05 70 69 11 f0    	sub    0xf0116970,%eax
f0101c30:	c1 f8 03             	sar    $0x3,%eax
f0101c33:	c1 e0 0c             	shl    $0xc,%eax
f0101c36:	39 c1                	cmp    %eax,%ecx
f0101c38:	74 19                	je     f0101c53 <mem_init+0xb97>
f0101c3a:	68 98 40 10 f0       	push   $0xf0104098
f0101c3f:	68 7a 43 10 f0       	push   $0xf010437a
f0101c44:	68 39 03 00 00       	push   $0x339
f0101c49:	68 54 43 10 f0       	push   $0xf0104354
f0101c4e:	e8 38 e4 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101c53:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c58:	89 f8                	mov    %edi,%eax
f0101c5a:	e8 e1 ec ff ff       	call   f0100940 <check_va2pa>
f0101c5f:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101c62:	74 19                	je     f0101c7d <mem_init+0xbc1>
f0101c64:	68 c4 40 10 f0       	push   $0xf01040c4
f0101c69:	68 7a 43 10 f0       	push   $0xf010437a
f0101c6e:	68 3a 03 00 00       	push   $0x33a
f0101c73:	68 54 43 10 f0       	push   $0xf0104354
f0101c78:	e8 0e e4 ff ff       	call   f010008b <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101c7d:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101c82:	74 19                	je     f0101c9d <mem_init+0xbe1>
f0101c84:	68 6b 45 10 f0       	push   $0xf010456b
f0101c89:	68 7a 43 10 f0       	push   $0xf010437a
f0101c8e:	68 3c 03 00 00       	push   $0x33c
f0101c93:	68 54 43 10 f0       	push   $0xf0104354
f0101c98:	e8 ee e3 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101c9d:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101ca2:	74 19                	je     f0101cbd <mem_init+0xc01>
f0101ca4:	68 7c 45 10 f0       	push   $0xf010457c
f0101ca9:	68 7a 43 10 f0       	push   $0xf010437a
f0101cae:	68 3d 03 00 00       	push   $0x33d
f0101cb3:	68 54 43 10 f0       	push   $0xf0104354
f0101cb8:	e8 ce e3 ff ff       	call   f010008b <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101cbd:	83 ec 0c             	sub    $0xc,%esp
f0101cc0:	6a 00                	push   $0x0
f0101cc2:	e8 b4 f0 ff ff       	call   f0100d7b <page_alloc>
f0101cc7:	83 c4 10             	add    $0x10,%esp
f0101cca:	85 c0                	test   %eax,%eax
f0101ccc:	74 04                	je     f0101cd2 <mem_init+0xc16>
f0101cce:	39 c6                	cmp    %eax,%esi
f0101cd0:	74 19                	je     f0101ceb <mem_init+0xc2f>
f0101cd2:	68 f4 40 10 f0       	push   $0xf01040f4
f0101cd7:	68 7a 43 10 f0       	push   $0xf010437a
f0101cdc:	68 40 03 00 00       	push   $0x340
f0101ce1:	68 54 43 10 f0       	push   $0xf0104354
f0101ce6:	e8 a0 e3 ff ff       	call   f010008b <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101ceb:	83 ec 08             	sub    $0x8,%esp
f0101cee:	6a 00                	push   $0x0
f0101cf0:	ff 35 6c 69 11 f0    	pushl  0xf011696c
f0101cf6:	e8 20 f3 ff ff       	call   f010101b <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101cfb:	8b 3d 6c 69 11 f0    	mov    0xf011696c,%edi
f0101d01:	ba 00 00 00 00       	mov    $0x0,%edx
f0101d06:	89 f8                	mov    %edi,%eax
f0101d08:	e8 33 ec ff ff       	call   f0100940 <check_va2pa>
f0101d0d:	83 c4 10             	add    $0x10,%esp
f0101d10:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101d13:	74 19                	je     f0101d2e <mem_init+0xc72>
f0101d15:	68 18 41 10 f0       	push   $0xf0104118
f0101d1a:	68 7a 43 10 f0       	push   $0xf010437a
f0101d1f:	68 44 03 00 00       	push   $0x344
f0101d24:	68 54 43 10 f0       	push   $0xf0104354
f0101d29:	e8 5d e3 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101d2e:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101d33:	89 f8                	mov    %edi,%eax
f0101d35:	e8 06 ec ff ff       	call   f0100940 <check_va2pa>
f0101d3a:	89 da                	mov    %ebx,%edx
f0101d3c:	2b 15 70 69 11 f0    	sub    0xf0116970,%edx
f0101d42:	c1 fa 03             	sar    $0x3,%edx
f0101d45:	c1 e2 0c             	shl    $0xc,%edx
f0101d48:	39 d0                	cmp    %edx,%eax
f0101d4a:	74 19                	je     f0101d65 <mem_init+0xca9>
f0101d4c:	68 c4 40 10 f0       	push   $0xf01040c4
f0101d51:	68 7a 43 10 f0       	push   $0xf010437a
f0101d56:	68 45 03 00 00       	push   $0x345
f0101d5b:	68 54 43 10 f0       	push   $0xf0104354
f0101d60:	e8 26 e3 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f0101d65:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101d6a:	74 19                	je     f0101d85 <mem_init+0xcc9>
f0101d6c:	68 22 45 10 f0       	push   $0xf0104522
f0101d71:	68 7a 43 10 f0       	push   $0xf010437a
f0101d76:	68 46 03 00 00       	push   $0x346
f0101d7b:	68 54 43 10 f0       	push   $0xf0104354
f0101d80:	e8 06 e3 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101d85:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101d8a:	74 19                	je     f0101da5 <mem_init+0xce9>
f0101d8c:	68 7c 45 10 f0       	push   $0xf010457c
f0101d91:	68 7a 43 10 f0       	push   $0xf010437a
f0101d96:	68 47 03 00 00       	push   $0x347
f0101d9b:	68 54 43 10 f0       	push   $0xf0104354
f0101da0:	e8 e6 e2 ff ff       	call   f010008b <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101da5:	6a 00                	push   $0x0
f0101da7:	68 00 10 00 00       	push   $0x1000
f0101dac:	53                   	push   %ebx
f0101dad:	57                   	push   %edi
f0101dae:	e8 a3 f2 ff ff       	call   f0101056 <page_insert>
f0101db3:	83 c4 10             	add    $0x10,%esp
f0101db6:	85 c0                	test   %eax,%eax
f0101db8:	74 19                	je     f0101dd3 <mem_init+0xd17>
f0101dba:	68 3c 41 10 f0       	push   $0xf010413c
f0101dbf:	68 7a 43 10 f0       	push   $0xf010437a
f0101dc4:	68 4a 03 00 00       	push   $0x34a
f0101dc9:	68 54 43 10 f0       	push   $0xf0104354
f0101dce:	e8 b8 e2 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref);
f0101dd3:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101dd8:	75 19                	jne    f0101df3 <mem_init+0xd37>
f0101dda:	68 8d 45 10 f0       	push   $0xf010458d
f0101ddf:	68 7a 43 10 f0       	push   $0xf010437a
f0101de4:	68 4b 03 00 00       	push   $0x34b
f0101de9:	68 54 43 10 f0       	push   $0xf0104354
f0101dee:	e8 98 e2 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_link == NULL);
f0101df3:	83 3b 00             	cmpl   $0x0,(%ebx)
f0101df6:	74 19                	je     f0101e11 <mem_init+0xd55>
f0101df8:	68 99 45 10 f0       	push   $0xf0104599
f0101dfd:	68 7a 43 10 f0       	push   $0xf010437a
f0101e02:	68 4c 03 00 00       	push   $0x34c
f0101e07:	68 54 43 10 f0       	push   $0xf0104354
f0101e0c:	e8 7a e2 ff ff       	call   f010008b <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101e11:	83 ec 08             	sub    $0x8,%esp
f0101e14:	68 00 10 00 00       	push   $0x1000
f0101e19:	ff 35 6c 69 11 f0    	pushl  0xf011696c
f0101e1f:	e8 f7 f1 ff ff       	call   f010101b <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101e24:	8b 3d 6c 69 11 f0    	mov    0xf011696c,%edi
f0101e2a:	ba 00 00 00 00       	mov    $0x0,%edx
f0101e2f:	89 f8                	mov    %edi,%eax
f0101e31:	e8 0a eb ff ff       	call   f0100940 <check_va2pa>
f0101e36:	83 c4 10             	add    $0x10,%esp
f0101e39:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e3c:	74 19                	je     f0101e57 <mem_init+0xd9b>
f0101e3e:	68 18 41 10 f0       	push   $0xf0104118
f0101e43:	68 7a 43 10 f0       	push   $0xf010437a
f0101e48:	68 50 03 00 00       	push   $0x350
f0101e4d:	68 54 43 10 f0       	push   $0xf0104354
f0101e52:	e8 34 e2 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101e57:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e5c:	89 f8                	mov    %edi,%eax
f0101e5e:	e8 dd ea ff ff       	call   f0100940 <check_va2pa>
f0101e63:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e66:	74 19                	je     f0101e81 <mem_init+0xdc5>
f0101e68:	68 74 41 10 f0       	push   $0xf0104174
f0101e6d:	68 7a 43 10 f0       	push   $0xf010437a
f0101e72:	68 51 03 00 00       	push   $0x351
f0101e77:	68 54 43 10 f0       	push   $0xf0104354
f0101e7c:	e8 0a e2 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 0);
f0101e81:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101e86:	74 19                	je     f0101ea1 <mem_init+0xde5>
f0101e88:	68 ae 45 10 f0       	push   $0xf01045ae
f0101e8d:	68 7a 43 10 f0       	push   $0xf010437a
f0101e92:	68 52 03 00 00       	push   $0x352
f0101e97:	68 54 43 10 f0       	push   $0xf0104354
f0101e9c:	e8 ea e1 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101ea1:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101ea6:	74 19                	je     f0101ec1 <mem_init+0xe05>
f0101ea8:	68 7c 45 10 f0       	push   $0xf010457c
f0101ead:	68 7a 43 10 f0       	push   $0xf010437a
f0101eb2:	68 53 03 00 00       	push   $0x353
f0101eb7:	68 54 43 10 f0       	push   $0xf0104354
f0101ebc:	e8 ca e1 ff ff       	call   f010008b <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101ec1:	83 ec 0c             	sub    $0xc,%esp
f0101ec4:	6a 00                	push   $0x0
f0101ec6:	e8 b0 ee ff ff       	call   f0100d7b <page_alloc>
f0101ecb:	83 c4 10             	add    $0x10,%esp
f0101ece:	39 c3                	cmp    %eax,%ebx
f0101ed0:	75 04                	jne    f0101ed6 <mem_init+0xe1a>
f0101ed2:	85 c0                	test   %eax,%eax
f0101ed4:	75 19                	jne    f0101eef <mem_init+0xe33>
f0101ed6:	68 9c 41 10 f0       	push   $0xf010419c
f0101edb:	68 7a 43 10 f0       	push   $0xf010437a
f0101ee0:	68 56 03 00 00       	push   $0x356
f0101ee5:	68 54 43 10 f0       	push   $0xf0104354
f0101eea:	e8 9c e1 ff ff       	call   f010008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101eef:	83 ec 0c             	sub    $0xc,%esp
f0101ef2:	6a 00                	push   $0x0
f0101ef4:	e8 82 ee ff ff       	call   f0100d7b <page_alloc>
f0101ef9:	83 c4 10             	add    $0x10,%esp
f0101efc:	85 c0                	test   %eax,%eax
f0101efe:	74 19                	je     f0101f19 <mem_init+0xe5d>
f0101f00:	68 d0 44 10 f0       	push   $0xf01044d0
f0101f05:	68 7a 43 10 f0       	push   $0xf010437a
f0101f0a:	68 59 03 00 00       	push   $0x359
f0101f0f:	68 54 43 10 f0       	push   $0xf0104354
f0101f14:	e8 72 e1 ff ff       	call   f010008b <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101f19:	8b 0d 6c 69 11 f0    	mov    0xf011696c,%ecx
f0101f1f:	8b 11                	mov    (%ecx),%edx
f0101f21:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101f27:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f2a:	2b 05 70 69 11 f0    	sub    0xf0116970,%eax
f0101f30:	c1 f8 03             	sar    $0x3,%eax
f0101f33:	c1 e0 0c             	shl    $0xc,%eax
f0101f36:	39 c2                	cmp    %eax,%edx
f0101f38:	74 19                	je     f0101f53 <mem_init+0xe97>
f0101f3a:	68 40 3e 10 f0       	push   $0xf0103e40
f0101f3f:	68 7a 43 10 f0       	push   $0xf010437a
f0101f44:	68 5c 03 00 00       	push   $0x35c
f0101f49:	68 54 43 10 f0       	push   $0xf0104354
f0101f4e:	e8 38 e1 ff ff       	call   f010008b <_panic>
	kern_pgdir[0] = 0;
f0101f53:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0101f59:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f5c:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101f61:	74 19                	je     f0101f7c <mem_init+0xec0>
f0101f63:	68 33 45 10 f0       	push   $0xf0104533
f0101f68:	68 7a 43 10 f0       	push   $0xf010437a
f0101f6d:	68 5e 03 00 00       	push   $0x35e
f0101f72:	68 54 43 10 f0       	push   $0xf0104354
f0101f77:	e8 0f e1 ff ff       	call   f010008b <_panic>
	pp0->pp_ref = 0;
f0101f7c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f7f:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0101f85:	83 ec 0c             	sub    $0xc,%esp
f0101f88:	50                   	push   %eax
f0101f89:	e8 5d ee ff ff       	call   f0100deb <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0101f8e:	83 c4 0c             	add    $0xc,%esp
f0101f91:	6a 01                	push   $0x1
f0101f93:	68 00 10 40 00       	push   $0x401000
f0101f98:	ff 35 6c 69 11 f0    	pushl  0xf011696c
f0101f9e:	e8 ed ee ff ff       	call   f0100e90 <pgdir_walk>
f0101fa3:	89 c7                	mov    %eax,%edi
f0101fa5:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0101fa8:	a1 6c 69 11 f0       	mov    0xf011696c,%eax
f0101fad:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101fb0:	8b 40 04             	mov    0x4(%eax),%eax
f0101fb3:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101fb8:	8b 0d 68 69 11 f0    	mov    0xf0116968,%ecx
f0101fbe:	89 c2                	mov    %eax,%edx
f0101fc0:	c1 ea 0c             	shr    $0xc,%edx
f0101fc3:	83 c4 10             	add    $0x10,%esp
f0101fc6:	39 ca                	cmp    %ecx,%edx
f0101fc8:	72 15                	jb     f0101fdf <mem_init+0xf23>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101fca:	50                   	push   %eax
f0101fcb:	68 b8 3b 10 f0       	push   $0xf0103bb8
f0101fd0:	68 65 03 00 00       	push   $0x365
f0101fd5:	68 54 43 10 f0       	push   $0xf0104354
f0101fda:	e8 ac e0 ff ff       	call   f010008b <_panic>
	assert(ptep == ptep1 + PTX(va));
f0101fdf:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f0101fe4:	39 c7                	cmp    %eax,%edi
f0101fe6:	74 19                	je     f0102001 <mem_init+0xf45>
f0101fe8:	68 bf 45 10 f0       	push   $0xf01045bf
f0101fed:	68 7a 43 10 f0       	push   $0xf010437a
f0101ff2:	68 66 03 00 00       	push   $0x366
f0101ff7:	68 54 43 10 f0       	push   $0xf0104354
f0101ffc:	e8 8a e0 ff ff       	call   f010008b <_panic>
	kern_pgdir[PDX(va)] = 0;
f0102001:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102004:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f010200b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010200e:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102014:	2b 05 70 69 11 f0    	sub    0xf0116970,%eax
f010201a:	c1 f8 03             	sar    $0x3,%eax
f010201d:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102020:	89 c2                	mov    %eax,%edx
f0102022:	c1 ea 0c             	shr    $0xc,%edx
f0102025:	39 d1                	cmp    %edx,%ecx
f0102027:	77 12                	ja     f010203b <mem_init+0xf7f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102029:	50                   	push   %eax
f010202a:	68 b8 3b 10 f0       	push   $0xf0103bb8
f010202f:	6a 52                	push   $0x52
f0102031:	68 60 43 10 f0       	push   $0xf0104360
f0102036:	e8 50 e0 ff ff       	call   f010008b <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f010203b:	83 ec 04             	sub    $0x4,%esp
f010203e:	68 00 10 00 00       	push   $0x1000
f0102043:	68 ff 00 00 00       	push   $0xff
f0102048:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010204d:	50                   	push   %eax
f010204e:	e8 cb 11 00 00       	call   f010321e <memset>
	page_free(pp0);
f0102053:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102056:	89 3c 24             	mov    %edi,(%esp)
f0102059:	e8 8d ed ff ff       	call   f0100deb <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f010205e:	83 c4 0c             	add    $0xc,%esp
f0102061:	6a 01                	push   $0x1
f0102063:	6a 00                	push   $0x0
f0102065:	ff 35 6c 69 11 f0    	pushl  0xf011696c
f010206b:	e8 20 ee ff ff       	call   f0100e90 <pgdir_walk>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102070:	89 fa                	mov    %edi,%edx
f0102072:	2b 15 70 69 11 f0    	sub    0xf0116970,%edx
f0102078:	c1 fa 03             	sar    $0x3,%edx
f010207b:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010207e:	89 d0                	mov    %edx,%eax
f0102080:	c1 e8 0c             	shr    $0xc,%eax
f0102083:	83 c4 10             	add    $0x10,%esp
f0102086:	3b 05 68 69 11 f0    	cmp    0xf0116968,%eax
f010208c:	72 12                	jb     f01020a0 <mem_init+0xfe4>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010208e:	52                   	push   %edx
f010208f:	68 b8 3b 10 f0       	push   $0xf0103bb8
f0102094:	6a 52                	push   $0x52
f0102096:	68 60 43 10 f0       	push   $0xf0104360
f010209b:	e8 eb df ff ff       	call   f010008b <_panic>
	return (void *)(pa + KERNBASE);
f01020a0:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f01020a6:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01020a9:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f01020af:	f6 00 01             	testb  $0x1,(%eax)
f01020b2:	74 19                	je     f01020cd <mem_init+0x1011>
f01020b4:	68 d7 45 10 f0       	push   $0xf01045d7
f01020b9:	68 7a 43 10 f0       	push   $0xf010437a
f01020be:	68 70 03 00 00       	push   $0x370
f01020c3:	68 54 43 10 f0       	push   $0xf0104354
f01020c8:	e8 be df ff ff       	call   f010008b <_panic>
f01020cd:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f01020d0:	39 d0                	cmp    %edx,%eax
f01020d2:	75 db                	jne    f01020af <mem_init+0xff3>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f01020d4:	a1 6c 69 11 f0       	mov    0xf011696c,%eax
f01020d9:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f01020df:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01020e2:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f01020e8:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f01020eb:	89 0d 3c 65 11 f0    	mov    %ecx,0xf011653c

	// free the pages we took
	page_free(pp0);
f01020f1:	83 ec 0c             	sub    $0xc,%esp
f01020f4:	50                   	push   %eax
f01020f5:	e8 f1 ec ff ff       	call   f0100deb <page_free>
	page_free(pp1);
f01020fa:	89 1c 24             	mov    %ebx,(%esp)
f01020fd:	e8 e9 ec ff ff       	call   f0100deb <page_free>
	page_free(pp2);
f0102102:	89 34 24             	mov    %esi,(%esp)
f0102105:	e8 e1 ec ff ff       	call   f0100deb <page_free>

	cprintf("check_page() succeeded!\n");
f010210a:	c7 04 24 ee 45 10 f0 	movl   $0xf01045ee,(%esp)
f0102111:	e8 4f 06 00 00       	call   f0102765 <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, (uintptr_t) UPAGES, npages*sizeof(struct PageInfo), PADDR(pages), PTE_U);
f0102116:	a1 70 69 11 f0       	mov    0xf0116970,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010211b:	83 c4 10             	add    $0x10,%esp
f010211e:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102123:	77 15                	ja     f010213a <mem_init+0x107e>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102125:	50                   	push   %eax
f0102126:	68 c4 3c 10 f0       	push   $0xf0103cc4
f010212b:	68 b4 00 00 00       	push   $0xb4
f0102130:	68 54 43 10 f0       	push   $0xf0104354
f0102135:	e8 51 df ff ff       	call   f010008b <_panic>
f010213a:	8b 0d 68 69 11 f0    	mov    0xf0116968,%ecx
f0102140:	c1 e1 03             	shl    $0x3,%ecx
f0102143:	83 ec 08             	sub    $0x8,%esp
f0102146:	6a 04                	push   $0x4
f0102148:	05 00 00 00 10       	add    $0x10000000,%eax
f010214d:	50                   	push   %eax
f010214e:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102153:	a1 6c 69 11 f0       	mov    0xf011696c,%eax
f0102158:	e8 0c ee ff ff       	call   f0100f69 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010215d:	83 c4 10             	add    $0x10,%esp
f0102160:	b8 00 c0 10 f0       	mov    $0xf010c000,%eax
f0102165:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010216a:	77 15                	ja     f0102181 <mem_init+0x10c5>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010216c:	50                   	push   %eax
f010216d:	68 c4 3c 10 f0       	push   $0xf0103cc4
f0102172:	68 c0 00 00 00       	push   $0xc0
f0102177:	68 54 43 10 f0       	push   $0xf0104354
f010217c:	e8 0a df ff ff       	call   f010008b <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, (uintptr_t) (KSTACKTOP-KSTKSIZE), KSTKSIZE, PADDR(bootstack), PTE_W);	//////////////////////////////////////////////////////////////////////
f0102181:	83 ec 08             	sub    $0x8,%esp
f0102184:	6a 02                	push   $0x2
f0102186:	68 00 c0 10 00       	push   $0x10c000
f010218b:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102190:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f0102195:	a1 6c 69 11 f0       	mov    0xf011696c,%eax
f010219a:	e8 ca ed ff ff       	call   f0100f69 <boot_map_region>
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, (uintptr_t) KERNBASE, ROUNDUP(0xffffffff - KERNBASE, PGSIZE), 0, PTE_W);
f010219f:	83 c4 08             	add    $0x8,%esp
f01021a2:	6a 02                	push   $0x2
f01021a4:	6a 00                	push   $0x0
f01021a6:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f01021ab:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f01021b0:	a1 6c 69 11 f0       	mov    0xf011696c,%eax
f01021b5:	e8 af ed ff ff       	call   f0100f69 <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f01021ba:	8b 35 6c 69 11 f0    	mov    0xf011696c,%esi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f01021c0:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f01021c5:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01021c8:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f01021cf:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01021d4:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01021d7:	8b 3d 70 69 11 f0    	mov    0xf0116970,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01021dd:	89 7d d0             	mov    %edi,-0x30(%ebp)
f01021e0:	83 c4 10             	add    $0x10,%esp

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01021e3:	bb 00 00 00 00       	mov    $0x0,%ebx
f01021e8:	eb 55                	jmp    f010223f <mem_init+0x1183>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01021ea:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
f01021f0:	89 f0                	mov    %esi,%eax
f01021f2:	e8 49 e7 ff ff       	call   f0100940 <check_va2pa>
f01021f7:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f01021fe:	77 15                	ja     f0102215 <mem_init+0x1159>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102200:	57                   	push   %edi
f0102201:	68 c4 3c 10 f0       	push   $0xf0103cc4
f0102206:	68 b2 02 00 00       	push   $0x2b2
f010220b:	68 54 43 10 f0       	push   $0xf0104354
f0102210:	e8 76 de ff ff       	call   f010008b <_panic>
f0102215:	8d 94 1f 00 00 00 10 	lea    0x10000000(%edi,%ebx,1),%edx
f010221c:	39 c2                	cmp    %eax,%edx
f010221e:	74 19                	je     f0102239 <mem_init+0x117d>
f0102220:	68 c0 41 10 f0       	push   $0xf01041c0
f0102225:	68 7a 43 10 f0       	push   $0xf010437a
f010222a:	68 b2 02 00 00       	push   $0x2b2
f010222f:	68 54 43 10 f0       	push   $0xf0104354
f0102234:	e8 52 de ff ff       	call   f010008b <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102239:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f010223f:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0102242:	77 a6                	ja     f01021ea <mem_init+0x112e>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102244:	8b 7d cc             	mov    -0x34(%ebp),%edi
f0102247:	c1 e7 0c             	shl    $0xc,%edi
f010224a:	bb 00 00 00 00       	mov    $0x0,%ebx
f010224f:	eb 30                	jmp    f0102281 <mem_init+0x11c5>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102251:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
f0102257:	89 f0                	mov    %esi,%eax
f0102259:	e8 e2 e6 ff ff       	call   f0100940 <check_va2pa>
f010225e:	39 c3                	cmp    %eax,%ebx
f0102260:	74 19                	je     f010227b <mem_init+0x11bf>
f0102262:	68 f4 41 10 f0       	push   $0xf01041f4
f0102267:	68 7a 43 10 f0       	push   $0xf010437a
f010226c:	68 b7 02 00 00       	push   $0x2b7
f0102271:	68 54 43 10 f0       	push   $0xf0104354
f0102276:	e8 10 de ff ff       	call   f010008b <_panic>
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f010227b:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102281:	39 fb                	cmp    %edi,%ebx
f0102283:	72 cc                	jb     f0102251 <mem_init+0x1195>
f0102285:	bb 00 80 ff ef       	mov    $0xefff8000,%ebx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f010228a:	89 da                	mov    %ebx,%edx
f010228c:	89 f0                	mov    %esi,%eax
f010228e:	e8 ad e6 ff ff       	call   f0100940 <check_va2pa>
f0102293:	8d 93 00 40 11 10    	lea    0x10114000(%ebx),%edx
f0102299:	39 c2                	cmp    %eax,%edx
f010229b:	74 19                	je     f01022b6 <mem_init+0x11fa>
f010229d:	68 1c 42 10 f0       	push   $0xf010421c
f01022a2:	68 7a 43 10 f0       	push   $0xf010437a
f01022a7:	68 bb 02 00 00       	push   $0x2bb
f01022ac:	68 54 43 10 f0       	push   $0xf0104354
f01022b1:	e8 d5 dd ff ff       	call   f010008b <_panic>
f01022b6:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f01022bc:	81 fb 00 00 00 f0    	cmp    $0xf0000000,%ebx
f01022c2:	75 c6                	jne    f010228a <mem_init+0x11ce>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f01022c4:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f01022c9:	89 f0                	mov    %esi,%eax
f01022cb:	e8 70 e6 ff ff       	call   f0100940 <check_va2pa>
f01022d0:	83 f8 ff             	cmp    $0xffffffff,%eax
f01022d3:	74 51                	je     f0102326 <mem_init+0x126a>
f01022d5:	68 64 42 10 f0       	push   $0xf0104264
f01022da:	68 7a 43 10 f0       	push   $0xf010437a
f01022df:	68 bc 02 00 00       	push   $0x2bc
f01022e4:	68 54 43 10 f0       	push   $0xf0104354
f01022e9:	e8 9d dd ff ff       	call   f010008b <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f01022ee:	3d bc 03 00 00       	cmp    $0x3bc,%eax
f01022f3:	72 36                	jb     f010232b <mem_init+0x126f>
f01022f5:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f01022fa:	76 07                	jbe    f0102303 <mem_init+0x1247>
f01022fc:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102301:	75 28                	jne    f010232b <mem_init+0x126f>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
f0102303:	f6 04 86 01          	testb  $0x1,(%esi,%eax,4)
f0102307:	0f 85 83 00 00 00    	jne    f0102390 <mem_init+0x12d4>
f010230d:	68 07 46 10 f0       	push   $0xf0104607
f0102312:	68 7a 43 10 f0       	push   $0xf010437a
f0102317:	68 c4 02 00 00       	push   $0x2c4
f010231c:	68 54 43 10 f0       	push   $0xf0104354
f0102321:	e8 65 dd ff ff       	call   f010008b <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102326:	b8 00 00 00 00       	mov    $0x0,%eax
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f010232b:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102330:	76 3f                	jbe    f0102371 <mem_init+0x12b5>
				assert(pgdir[i] & PTE_P);
f0102332:	8b 14 86             	mov    (%esi,%eax,4),%edx
f0102335:	f6 c2 01             	test   $0x1,%dl
f0102338:	75 19                	jne    f0102353 <mem_init+0x1297>
f010233a:	68 07 46 10 f0       	push   $0xf0104607
f010233f:	68 7a 43 10 f0       	push   $0xf010437a
f0102344:	68 c8 02 00 00       	push   $0x2c8
f0102349:	68 54 43 10 f0       	push   $0xf0104354
f010234e:	e8 38 dd ff ff       	call   f010008b <_panic>
				assert(pgdir[i] & PTE_W);
f0102353:	f6 c2 02             	test   $0x2,%dl
f0102356:	75 38                	jne    f0102390 <mem_init+0x12d4>
f0102358:	68 18 46 10 f0       	push   $0xf0104618
f010235d:	68 7a 43 10 f0       	push   $0xf010437a
f0102362:	68 c9 02 00 00       	push   $0x2c9
f0102367:	68 54 43 10 f0       	push   $0xf0104354
f010236c:	e8 1a dd ff ff       	call   f010008b <_panic>
			} else
				assert(pgdir[i] == 0);
f0102371:	83 3c 86 00          	cmpl   $0x0,(%esi,%eax,4)
f0102375:	74 19                	je     f0102390 <mem_init+0x12d4>
f0102377:	68 29 46 10 f0       	push   $0xf0104629
f010237c:	68 7a 43 10 f0       	push   $0xf010437a
f0102381:	68 cb 02 00 00       	push   $0x2cb
f0102386:	68 54 43 10 f0       	push   $0xf0104354
f010238b:	e8 fb dc ff ff       	call   f010008b <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0102390:	83 c0 01             	add    $0x1,%eax
f0102393:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f0102398:	0f 86 50 ff ff ff    	jbe    f01022ee <mem_init+0x1232>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f010239e:	83 ec 0c             	sub    $0xc,%esp
f01023a1:	68 94 42 10 f0       	push   $0xf0104294
f01023a6:	e8 ba 03 00 00       	call   f0102765 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f01023ab:	a1 6c 69 11 f0       	mov    0xf011696c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01023b0:	83 c4 10             	add    $0x10,%esp
f01023b3:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01023b8:	77 15                	ja     f01023cf <mem_init+0x1313>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01023ba:	50                   	push   %eax
f01023bb:	68 c4 3c 10 f0       	push   $0xf0103cc4
f01023c0:	68 d3 00 00 00       	push   $0xd3
f01023c5:	68 54 43 10 f0       	push   $0xf0104354
f01023ca:	e8 bc dc ff ff       	call   f010008b <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f01023cf:	05 00 00 00 10       	add    $0x10000000,%eax
f01023d4:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f01023d7:	b8 00 00 00 00       	mov    $0x0,%eax
f01023dc:	e8 c3 e5 ff ff       	call   f01009a4 <check_page_free_list>

static inline uint32_t
rcr0(void)
{
	uint32_t val;
	asm volatile("movl %%cr0,%0" : "=r" (val));
f01023e1:	0f 20 c0             	mov    %cr0,%eax
f01023e4:	83 e0 f3             	and    $0xfffffff3,%eax
}

static inline void
lcr0(uint32_t val)
{
	asm volatile("movl %0,%%cr0" : : "r" (val));
f01023e7:	0d 23 00 05 80       	or     $0x80050023,%eax
f01023ec:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01023ef:	83 ec 0c             	sub    $0xc,%esp
f01023f2:	6a 00                	push   $0x0
f01023f4:	e8 82 e9 ff ff       	call   f0100d7b <page_alloc>
f01023f9:	89 c3                	mov    %eax,%ebx
f01023fb:	83 c4 10             	add    $0x10,%esp
f01023fe:	85 c0                	test   %eax,%eax
f0102400:	75 19                	jne    f010241b <mem_init+0x135f>
f0102402:	68 25 44 10 f0       	push   $0xf0104425
f0102407:	68 7a 43 10 f0       	push   $0xf010437a
f010240c:	68 8b 03 00 00       	push   $0x38b
f0102411:	68 54 43 10 f0       	push   $0xf0104354
f0102416:	e8 70 dc ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f010241b:	83 ec 0c             	sub    $0xc,%esp
f010241e:	6a 00                	push   $0x0
f0102420:	e8 56 e9 ff ff       	call   f0100d7b <page_alloc>
f0102425:	89 c7                	mov    %eax,%edi
f0102427:	83 c4 10             	add    $0x10,%esp
f010242a:	85 c0                	test   %eax,%eax
f010242c:	75 19                	jne    f0102447 <mem_init+0x138b>
f010242e:	68 3b 44 10 f0       	push   $0xf010443b
f0102433:	68 7a 43 10 f0       	push   $0xf010437a
f0102438:	68 8c 03 00 00       	push   $0x38c
f010243d:	68 54 43 10 f0       	push   $0xf0104354
f0102442:	e8 44 dc ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0102447:	83 ec 0c             	sub    $0xc,%esp
f010244a:	6a 00                	push   $0x0
f010244c:	e8 2a e9 ff ff       	call   f0100d7b <page_alloc>
f0102451:	89 c6                	mov    %eax,%esi
f0102453:	83 c4 10             	add    $0x10,%esp
f0102456:	85 c0                	test   %eax,%eax
f0102458:	75 19                	jne    f0102473 <mem_init+0x13b7>
f010245a:	68 51 44 10 f0       	push   $0xf0104451
f010245f:	68 7a 43 10 f0       	push   $0xf010437a
f0102464:	68 8d 03 00 00       	push   $0x38d
f0102469:	68 54 43 10 f0       	push   $0xf0104354
f010246e:	e8 18 dc ff ff       	call   f010008b <_panic>
	page_free(pp0);
f0102473:	83 ec 0c             	sub    $0xc,%esp
f0102476:	53                   	push   %ebx
f0102477:	e8 6f e9 ff ff       	call   f0100deb <page_free>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010247c:	89 f8                	mov    %edi,%eax
f010247e:	2b 05 70 69 11 f0    	sub    0xf0116970,%eax
f0102484:	c1 f8 03             	sar    $0x3,%eax
f0102487:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010248a:	89 c2                	mov    %eax,%edx
f010248c:	c1 ea 0c             	shr    $0xc,%edx
f010248f:	83 c4 10             	add    $0x10,%esp
f0102492:	3b 15 68 69 11 f0    	cmp    0xf0116968,%edx
f0102498:	72 12                	jb     f01024ac <mem_init+0x13f0>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010249a:	50                   	push   %eax
f010249b:	68 b8 3b 10 f0       	push   $0xf0103bb8
f01024a0:	6a 52                	push   $0x52
f01024a2:	68 60 43 10 f0       	push   $0xf0104360
f01024a7:	e8 df db ff ff       	call   f010008b <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f01024ac:	83 ec 04             	sub    $0x4,%esp
f01024af:	68 00 10 00 00       	push   $0x1000
f01024b4:	6a 01                	push   $0x1
f01024b6:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01024bb:	50                   	push   %eax
f01024bc:	e8 5d 0d 00 00       	call   f010321e <memset>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01024c1:	89 f0                	mov    %esi,%eax
f01024c3:	2b 05 70 69 11 f0    	sub    0xf0116970,%eax
f01024c9:	c1 f8 03             	sar    $0x3,%eax
f01024cc:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01024cf:	89 c2                	mov    %eax,%edx
f01024d1:	c1 ea 0c             	shr    $0xc,%edx
f01024d4:	83 c4 10             	add    $0x10,%esp
f01024d7:	3b 15 68 69 11 f0    	cmp    0xf0116968,%edx
f01024dd:	72 12                	jb     f01024f1 <mem_init+0x1435>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01024df:	50                   	push   %eax
f01024e0:	68 b8 3b 10 f0       	push   $0xf0103bb8
f01024e5:	6a 52                	push   $0x52
f01024e7:	68 60 43 10 f0       	push   $0xf0104360
f01024ec:	e8 9a db ff ff       	call   f010008b <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f01024f1:	83 ec 04             	sub    $0x4,%esp
f01024f4:	68 00 10 00 00       	push   $0x1000
f01024f9:	6a 02                	push   $0x2
f01024fb:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102500:	50                   	push   %eax
f0102501:	e8 18 0d 00 00       	call   f010321e <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102506:	6a 02                	push   $0x2
f0102508:	68 00 10 00 00       	push   $0x1000
f010250d:	57                   	push   %edi
f010250e:	ff 35 6c 69 11 f0    	pushl  0xf011696c
f0102514:	e8 3d eb ff ff       	call   f0101056 <page_insert>
	assert(pp1->pp_ref == 1);
f0102519:	83 c4 20             	add    $0x20,%esp
f010251c:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102521:	74 19                	je     f010253c <mem_init+0x1480>
f0102523:	68 22 45 10 f0       	push   $0xf0104522
f0102528:	68 7a 43 10 f0       	push   $0xf010437a
f010252d:	68 92 03 00 00       	push   $0x392
f0102532:	68 54 43 10 f0       	push   $0xf0104354
f0102537:	e8 4f db ff ff       	call   f010008b <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f010253c:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102543:	01 01 01 
f0102546:	74 19                	je     f0102561 <mem_init+0x14a5>
f0102548:	68 b4 42 10 f0       	push   $0xf01042b4
f010254d:	68 7a 43 10 f0       	push   $0xf010437a
f0102552:	68 93 03 00 00       	push   $0x393
f0102557:	68 54 43 10 f0       	push   $0xf0104354
f010255c:	e8 2a db ff ff       	call   f010008b <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102561:	6a 02                	push   $0x2
f0102563:	68 00 10 00 00       	push   $0x1000
f0102568:	56                   	push   %esi
f0102569:	ff 35 6c 69 11 f0    	pushl  0xf011696c
f010256f:	e8 e2 ea ff ff       	call   f0101056 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102574:	83 c4 10             	add    $0x10,%esp
f0102577:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f010257e:	02 02 02 
f0102581:	74 19                	je     f010259c <mem_init+0x14e0>
f0102583:	68 d8 42 10 f0       	push   $0xf01042d8
f0102588:	68 7a 43 10 f0       	push   $0xf010437a
f010258d:	68 95 03 00 00       	push   $0x395
f0102592:	68 54 43 10 f0       	push   $0xf0104354
f0102597:	e8 ef da ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f010259c:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01025a1:	74 19                	je     f01025bc <mem_init+0x1500>
f01025a3:	68 44 45 10 f0       	push   $0xf0104544
f01025a8:	68 7a 43 10 f0       	push   $0xf010437a
f01025ad:	68 96 03 00 00       	push   $0x396
f01025b2:	68 54 43 10 f0       	push   $0xf0104354
f01025b7:	e8 cf da ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 0);
f01025bc:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f01025c1:	74 19                	je     f01025dc <mem_init+0x1520>
f01025c3:	68 ae 45 10 f0       	push   $0xf01045ae
f01025c8:	68 7a 43 10 f0       	push   $0xf010437a
f01025cd:	68 97 03 00 00       	push   $0x397
f01025d2:	68 54 43 10 f0       	push   $0xf0104354
f01025d7:	e8 af da ff ff       	call   f010008b <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f01025dc:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f01025e3:	03 03 03 
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01025e6:	89 f0                	mov    %esi,%eax
f01025e8:	2b 05 70 69 11 f0    	sub    0xf0116970,%eax
f01025ee:	c1 f8 03             	sar    $0x3,%eax
f01025f1:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01025f4:	89 c2                	mov    %eax,%edx
f01025f6:	c1 ea 0c             	shr    $0xc,%edx
f01025f9:	3b 15 68 69 11 f0    	cmp    0xf0116968,%edx
f01025ff:	72 12                	jb     f0102613 <mem_init+0x1557>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102601:	50                   	push   %eax
f0102602:	68 b8 3b 10 f0       	push   $0xf0103bb8
f0102607:	6a 52                	push   $0x52
f0102609:	68 60 43 10 f0       	push   $0xf0104360
f010260e:	e8 78 da ff ff       	call   f010008b <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102613:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f010261a:	03 03 03 
f010261d:	74 19                	je     f0102638 <mem_init+0x157c>
f010261f:	68 fc 42 10 f0       	push   $0xf01042fc
f0102624:	68 7a 43 10 f0       	push   $0xf010437a
f0102629:	68 99 03 00 00       	push   $0x399
f010262e:	68 54 43 10 f0       	push   $0xf0104354
f0102633:	e8 53 da ff ff       	call   f010008b <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102638:	83 ec 08             	sub    $0x8,%esp
f010263b:	68 00 10 00 00       	push   $0x1000
f0102640:	ff 35 6c 69 11 f0    	pushl  0xf011696c
f0102646:	e8 d0 e9 ff ff       	call   f010101b <page_remove>
	assert(pp2->pp_ref == 0);
f010264b:	83 c4 10             	add    $0x10,%esp
f010264e:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102653:	74 19                	je     f010266e <mem_init+0x15b2>
f0102655:	68 7c 45 10 f0       	push   $0xf010457c
f010265a:	68 7a 43 10 f0       	push   $0xf010437a
f010265f:	68 9b 03 00 00       	push   $0x39b
f0102664:	68 54 43 10 f0       	push   $0xf0104354
f0102669:	e8 1d da ff ff       	call   f010008b <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010266e:	8b 0d 6c 69 11 f0    	mov    0xf011696c,%ecx
f0102674:	8b 11                	mov    (%ecx),%edx
f0102676:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010267c:	89 d8                	mov    %ebx,%eax
f010267e:	2b 05 70 69 11 f0    	sub    0xf0116970,%eax
f0102684:	c1 f8 03             	sar    $0x3,%eax
f0102687:	c1 e0 0c             	shl    $0xc,%eax
f010268a:	39 c2                	cmp    %eax,%edx
f010268c:	74 19                	je     f01026a7 <mem_init+0x15eb>
f010268e:	68 40 3e 10 f0       	push   $0xf0103e40
f0102693:	68 7a 43 10 f0       	push   $0xf010437a
f0102698:	68 9e 03 00 00       	push   $0x39e
f010269d:	68 54 43 10 f0       	push   $0xf0104354
f01026a2:	e8 e4 d9 ff ff       	call   f010008b <_panic>
	kern_pgdir[0] = 0;
f01026a7:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f01026ad:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01026b2:	74 19                	je     f01026cd <mem_init+0x1611>
f01026b4:	68 33 45 10 f0       	push   $0xf0104533
f01026b9:	68 7a 43 10 f0       	push   $0xf010437a
f01026be:	68 a0 03 00 00       	push   $0x3a0
f01026c3:	68 54 43 10 f0       	push   $0xf0104354
f01026c8:	e8 be d9 ff ff       	call   f010008b <_panic>
	pp0->pp_ref = 0;
f01026cd:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f01026d3:	83 ec 0c             	sub    $0xc,%esp
f01026d6:	53                   	push   %ebx
f01026d7:	e8 0f e7 ff ff       	call   f0100deb <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f01026dc:	c7 04 24 28 43 10 f0 	movl   $0xf0104328,(%esp)
f01026e3:	e8 7d 00 00 00       	call   f0102765 <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f01026e8:	83 c4 10             	add    $0x10,%esp
f01026eb:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01026ee:	5b                   	pop    %ebx
f01026ef:	5e                   	pop    %esi
f01026f0:	5f                   	pop    %edi
f01026f1:	5d                   	pop    %ebp
f01026f2:	c3                   	ret    

f01026f3 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f01026f3:	55                   	push   %ebp
f01026f4:	89 e5                	mov    %esp,%ebp
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01026f6:	8b 45 0c             	mov    0xc(%ebp),%eax
f01026f9:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f01026fc:	5d                   	pop    %ebp
f01026fd:	c3                   	ret    

f01026fe <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f01026fe:	55                   	push   %ebp
f01026ff:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102701:	ba 70 00 00 00       	mov    $0x70,%edx
f0102706:	8b 45 08             	mov    0x8(%ebp),%eax
f0102709:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010270a:	ba 71 00 00 00       	mov    $0x71,%edx
f010270f:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0102710:	0f b6 c0             	movzbl %al,%eax
}
f0102713:	5d                   	pop    %ebp
f0102714:	c3                   	ret    

f0102715 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102715:	55                   	push   %ebp
f0102716:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102718:	ba 70 00 00 00       	mov    $0x70,%edx
f010271d:	8b 45 08             	mov    0x8(%ebp),%eax
f0102720:	ee                   	out    %al,(%dx)
f0102721:	ba 71 00 00 00       	mov    $0x71,%edx
f0102726:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102729:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f010272a:	5d                   	pop    %ebp
f010272b:	c3                   	ret    

f010272c <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f010272c:	55                   	push   %ebp
f010272d:	89 e5                	mov    %esp,%ebp
f010272f:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0102732:	ff 75 08             	pushl  0x8(%ebp)
f0102735:	e8 c6 de ff ff       	call   f0100600 <cputchar>
	*cnt++;
}
f010273a:	83 c4 10             	add    $0x10,%esp
f010273d:	c9                   	leave  
f010273e:	c3                   	ret    

f010273f <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f010273f:	55                   	push   %ebp
f0102740:	89 e5                	mov    %esp,%ebp
f0102742:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0102745:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f010274c:	ff 75 0c             	pushl  0xc(%ebp)
f010274f:	ff 75 08             	pushl  0x8(%ebp)
f0102752:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102755:	50                   	push   %eax
f0102756:	68 2c 27 10 f0       	push   $0xf010272c
f010275b:	e8 52 04 00 00       	call   f0102bb2 <vprintfmt>
	return cnt;
}
f0102760:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102763:	c9                   	leave  
f0102764:	c3                   	ret    

f0102765 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0102765:	55                   	push   %ebp
f0102766:	89 e5                	mov    %esp,%ebp
f0102768:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f010276b:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f010276e:	50                   	push   %eax
f010276f:	ff 75 08             	pushl  0x8(%ebp)
f0102772:	e8 c8 ff ff ff       	call   f010273f <vcprintf>
	va_end(ap);

	return cnt;
}
f0102777:	c9                   	leave  
f0102778:	c3                   	ret    

f0102779 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0102779:	55                   	push   %ebp
f010277a:	89 e5                	mov    %esp,%ebp
f010277c:	57                   	push   %edi
f010277d:	56                   	push   %esi
f010277e:	53                   	push   %ebx
f010277f:	83 ec 14             	sub    $0x14,%esp
f0102782:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0102785:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0102788:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f010278b:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f010278e:	8b 1a                	mov    (%edx),%ebx
f0102790:	8b 01                	mov    (%ecx),%eax
f0102792:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102795:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f010279c:	eb 7f                	jmp    f010281d <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f010279e:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01027a1:	01 d8                	add    %ebx,%eax
f01027a3:	89 c6                	mov    %eax,%esi
f01027a5:	c1 ee 1f             	shr    $0x1f,%esi
f01027a8:	01 c6                	add    %eax,%esi
f01027aa:	d1 fe                	sar    %esi
f01027ac:	8d 04 76             	lea    (%esi,%esi,2),%eax
f01027af:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01027b2:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f01027b5:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01027b7:	eb 03                	jmp    f01027bc <stab_binsearch+0x43>
			m--;
f01027b9:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01027bc:	39 c3                	cmp    %eax,%ebx
f01027be:	7f 0d                	jg     f01027cd <stab_binsearch+0x54>
f01027c0:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01027c4:	83 ea 0c             	sub    $0xc,%edx
f01027c7:	39 f9                	cmp    %edi,%ecx
f01027c9:	75 ee                	jne    f01027b9 <stab_binsearch+0x40>
f01027cb:	eb 05                	jmp    f01027d2 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f01027cd:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f01027d0:	eb 4b                	jmp    f010281d <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01027d2:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01027d5:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01027d8:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f01027dc:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01027df:	76 11                	jbe    f01027f2 <stab_binsearch+0x79>
			*region_left = m;
f01027e1:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01027e4:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f01027e6:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01027e9:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01027f0:	eb 2b                	jmp    f010281d <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f01027f2:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01027f5:	73 14                	jae    f010280b <stab_binsearch+0x92>
			*region_right = m - 1;
f01027f7:	83 e8 01             	sub    $0x1,%eax
f01027fa:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01027fd:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0102800:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102802:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0102809:	eb 12                	jmp    f010281d <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f010280b:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010280e:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0102810:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0102814:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102816:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f010281d:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0102820:	0f 8e 78 ff ff ff    	jle    f010279e <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0102826:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f010282a:	75 0f                	jne    f010283b <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f010282c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010282f:	8b 00                	mov    (%eax),%eax
f0102831:	83 e8 01             	sub    $0x1,%eax
f0102834:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0102837:	89 06                	mov    %eax,(%esi)
f0102839:	eb 2c                	jmp    f0102867 <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010283b:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010283e:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0102840:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0102843:	8b 0e                	mov    (%esi),%ecx
f0102845:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0102848:	8b 75 ec             	mov    -0x14(%ebp),%esi
f010284b:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010284e:	eb 03                	jmp    f0102853 <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0102850:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102853:	39 c8                	cmp    %ecx,%eax
f0102855:	7e 0b                	jle    f0102862 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f0102857:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f010285b:	83 ea 0c             	sub    $0xc,%edx
f010285e:	39 df                	cmp    %ebx,%edi
f0102860:	75 ee                	jne    f0102850 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f0102862:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0102865:	89 06                	mov    %eax,(%esi)
	}
}
f0102867:	83 c4 14             	add    $0x14,%esp
f010286a:	5b                   	pop    %ebx
f010286b:	5e                   	pop    %esi
f010286c:	5f                   	pop    %edi
f010286d:	5d                   	pop    %ebp
f010286e:	c3                   	ret    

f010286f <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f010286f:	55                   	push   %ebp
f0102870:	89 e5                	mov    %esp,%ebp
f0102872:	57                   	push   %edi
f0102873:	56                   	push   %esi
f0102874:	53                   	push   %ebx
f0102875:	83 ec 3c             	sub    $0x3c,%esp
f0102878:	8b 75 08             	mov    0x8(%ebp),%esi
f010287b:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f010287e:	c7 03 37 46 10 f0    	movl   $0xf0104637,(%ebx)
	info->eip_line = 0;
f0102884:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f010288b:	c7 43 08 37 46 10 f0 	movl   $0xf0104637,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0102892:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0102899:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f010289c:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f01028a3:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f01028a9:	76 11                	jbe    f01028bc <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01028ab:	b8 be bf 10 f0       	mov    $0xf010bfbe,%eax
f01028b0:	3d d1 a1 10 f0       	cmp    $0xf010a1d1,%eax
f01028b5:	77 19                	ja     f01028d0 <debuginfo_eip+0x61>
f01028b7:	e9 aa 01 00 00       	jmp    f0102a66 <debuginfo_eip+0x1f7>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f01028bc:	83 ec 04             	sub    $0x4,%esp
f01028bf:	68 41 46 10 f0       	push   $0xf0104641
f01028c4:	6a 7f                	push   $0x7f
f01028c6:	68 4e 46 10 f0       	push   $0xf010464e
f01028cb:	e8 bb d7 ff ff       	call   f010008b <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01028d0:	80 3d bd bf 10 f0 00 	cmpb   $0x0,0xf010bfbd
f01028d7:	0f 85 90 01 00 00    	jne    f0102a6d <debuginfo_eip+0x1fe>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f01028dd:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f01028e4:	b8 d0 a1 10 f0       	mov    $0xf010a1d0,%eax
f01028e9:	2d 6c 48 10 f0       	sub    $0xf010486c,%eax
f01028ee:	c1 f8 02             	sar    $0x2,%eax
f01028f1:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f01028f7:	83 e8 01             	sub    $0x1,%eax
f01028fa:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f01028fd:	83 ec 08             	sub    $0x8,%esp
f0102900:	56                   	push   %esi
f0102901:	6a 64                	push   $0x64
f0102903:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0102906:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0102909:	b8 6c 48 10 f0       	mov    $0xf010486c,%eax
f010290e:	e8 66 fe ff ff       	call   f0102779 <stab_binsearch>
	if (lfile == 0)
f0102913:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102916:	83 c4 10             	add    $0x10,%esp
f0102919:	85 c0                	test   %eax,%eax
f010291b:	0f 84 53 01 00 00    	je     f0102a74 <debuginfo_eip+0x205>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0102921:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0102924:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102927:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f010292a:	83 ec 08             	sub    $0x8,%esp
f010292d:	56                   	push   %esi
f010292e:	6a 24                	push   $0x24
f0102930:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0102933:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0102936:	b8 6c 48 10 f0       	mov    $0xf010486c,%eax
f010293b:	e8 39 fe ff ff       	call   f0102779 <stab_binsearch>

	if (lfun <= rfun) {
f0102940:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0102943:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102946:	83 c4 10             	add    $0x10,%esp
f0102949:	39 d0                	cmp    %edx,%eax
f010294b:	7f 40                	jg     f010298d <debuginfo_eip+0x11e>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f010294d:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f0102950:	c1 e1 02             	shl    $0x2,%ecx
f0102953:	8d b9 6c 48 10 f0    	lea    -0xfefb794(%ecx),%edi
f0102959:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f010295c:	8b b9 6c 48 10 f0    	mov    -0xfefb794(%ecx),%edi
f0102962:	b9 be bf 10 f0       	mov    $0xf010bfbe,%ecx
f0102967:	81 e9 d1 a1 10 f0    	sub    $0xf010a1d1,%ecx
f010296d:	39 cf                	cmp    %ecx,%edi
f010296f:	73 09                	jae    f010297a <debuginfo_eip+0x10b>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0102971:	81 c7 d1 a1 10 f0    	add    $0xf010a1d1,%edi
f0102977:	89 7b 08             	mov    %edi,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f010297a:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f010297d:	8b 4f 08             	mov    0x8(%edi),%ecx
f0102980:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0102983:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0102985:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0102988:	89 55 d0             	mov    %edx,-0x30(%ebp)
f010298b:	eb 0f                	jmp    f010299c <debuginfo_eip+0x12d>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f010298d:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0102990:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102993:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0102996:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102999:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f010299c:	83 ec 08             	sub    $0x8,%esp
f010299f:	6a 3a                	push   $0x3a
f01029a1:	ff 73 08             	pushl  0x8(%ebx)
f01029a4:	e8 59 08 00 00       	call   f0103202 <strfind>
f01029a9:	2b 43 08             	sub    0x8(%ebx),%eax
f01029ac:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f01029af:	83 c4 08             	add    $0x8,%esp
f01029b2:	56                   	push   %esi
f01029b3:	6a 44                	push   $0x44
f01029b5:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f01029b8:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f01029bb:	b8 6c 48 10 f0       	mov    $0xf010486c,%eax
f01029c0:	e8 b4 fd ff ff       	call   f0102779 <stab_binsearch>
    if (lline <= rline) {
f01029c5:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01029c8:	83 c4 10             	add    $0x10,%esp
f01029cb:	3b 55 d0             	cmp    -0x30(%ebp),%edx
f01029ce:	0f 8f a7 00 00 00    	jg     f0102a7b <debuginfo_eip+0x20c>
        info->eip_line = stabs[lline].n_desc;
f01029d4:	8d 04 52             	lea    (%edx,%edx,2),%eax
f01029d7:	8d 04 85 6c 48 10 f0 	lea    -0xfefb794(,%eax,4),%eax
f01029de:	0f b7 48 06          	movzwl 0x6(%eax),%ecx
f01029e2:	89 4b 04             	mov    %ecx,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01029e5:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01029e8:	eb 06                	jmp    f01029f0 <debuginfo_eip+0x181>
f01029ea:	83 ea 01             	sub    $0x1,%edx
f01029ed:	83 e8 0c             	sub    $0xc,%eax
f01029f0:	39 d6                	cmp    %edx,%esi
f01029f2:	7f 34                	jg     f0102a28 <debuginfo_eip+0x1b9>
	       && stabs[lline].n_type != N_SOL
f01029f4:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f01029f8:	80 f9 84             	cmp    $0x84,%cl
f01029fb:	74 0b                	je     f0102a08 <debuginfo_eip+0x199>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f01029fd:	80 f9 64             	cmp    $0x64,%cl
f0102a00:	75 e8                	jne    f01029ea <debuginfo_eip+0x17b>
f0102a02:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0102a06:	74 e2                	je     f01029ea <debuginfo_eip+0x17b>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0102a08:	8d 04 52             	lea    (%edx,%edx,2),%eax
f0102a0b:	8b 14 85 6c 48 10 f0 	mov    -0xfefb794(,%eax,4),%edx
f0102a12:	b8 be bf 10 f0       	mov    $0xf010bfbe,%eax
f0102a17:	2d d1 a1 10 f0       	sub    $0xf010a1d1,%eax
f0102a1c:	39 c2                	cmp    %eax,%edx
f0102a1e:	73 08                	jae    f0102a28 <debuginfo_eip+0x1b9>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0102a20:	81 c2 d1 a1 10 f0    	add    $0xf010a1d1,%edx
f0102a26:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0102a28:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102a2b:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102a2e:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0102a33:	39 f2                	cmp    %esi,%edx
f0102a35:	7d 50                	jge    f0102a87 <debuginfo_eip+0x218>
		for (lline = lfun + 1;
f0102a37:	83 c2 01             	add    $0x1,%edx
f0102a3a:	89 d0                	mov    %edx,%eax
f0102a3c:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0102a3f:	8d 14 95 6c 48 10 f0 	lea    -0xfefb794(,%edx,4),%edx
f0102a46:	eb 04                	jmp    f0102a4c <debuginfo_eip+0x1dd>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0102a48:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0102a4c:	39 c6                	cmp    %eax,%esi
f0102a4e:	7e 32                	jle    f0102a82 <debuginfo_eip+0x213>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0102a50:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0102a54:	83 c0 01             	add    $0x1,%eax
f0102a57:	83 c2 0c             	add    $0xc,%edx
f0102a5a:	80 f9 a0             	cmp    $0xa0,%cl
f0102a5d:	74 e9                	je     f0102a48 <debuginfo_eip+0x1d9>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102a5f:	b8 00 00 00 00       	mov    $0x0,%eax
f0102a64:	eb 21                	jmp    f0102a87 <debuginfo_eip+0x218>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0102a66:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102a6b:	eb 1a                	jmp    f0102a87 <debuginfo_eip+0x218>
f0102a6d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102a72:	eb 13                	jmp    f0102a87 <debuginfo_eip+0x218>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0102a74:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102a79:	eb 0c                	jmp    f0102a87 <debuginfo_eip+0x218>
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
    if (lline <= rline) {
        info->eip_line = stabs[lline].n_desc;
    } else {
        return -1;
f0102a7b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102a80:	eb 05                	jmp    f0102a87 <debuginfo_eip+0x218>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102a82:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102a87:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102a8a:	5b                   	pop    %ebx
f0102a8b:	5e                   	pop    %esi
f0102a8c:	5f                   	pop    %edi
f0102a8d:	5d                   	pop    %ebp
f0102a8e:	c3                   	ret    

f0102a8f <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0102a8f:	55                   	push   %ebp
f0102a90:	89 e5                	mov    %esp,%ebp
f0102a92:	57                   	push   %edi
f0102a93:	56                   	push   %esi
f0102a94:	53                   	push   %ebx
f0102a95:	83 ec 1c             	sub    $0x1c,%esp
f0102a98:	89 c7                	mov    %eax,%edi
f0102a9a:	89 d6                	mov    %edx,%esi
f0102a9c:	8b 45 08             	mov    0x8(%ebp),%eax
f0102a9f:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102aa2:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102aa5:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0102aa8:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0102aab:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102ab0:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0102ab3:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0102ab6:	39 d3                	cmp    %edx,%ebx
f0102ab8:	72 05                	jb     f0102abf <printnum+0x30>
f0102aba:	39 45 10             	cmp    %eax,0x10(%ebp)
f0102abd:	77 45                	ja     f0102b04 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0102abf:	83 ec 0c             	sub    $0xc,%esp
f0102ac2:	ff 75 18             	pushl  0x18(%ebp)
f0102ac5:	8b 45 14             	mov    0x14(%ebp),%eax
f0102ac8:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0102acb:	53                   	push   %ebx
f0102acc:	ff 75 10             	pushl  0x10(%ebp)
f0102acf:	83 ec 08             	sub    $0x8,%esp
f0102ad2:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102ad5:	ff 75 e0             	pushl  -0x20(%ebp)
f0102ad8:	ff 75 dc             	pushl  -0x24(%ebp)
f0102adb:	ff 75 d8             	pushl  -0x28(%ebp)
f0102ade:	e8 3d 09 00 00       	call   f0103420 <__udivdi3>
f0102ae3:	83 c4 18             	add    $0x18,%esp
f0102ae6:	52                   	push   %edx
f0102ae7:	50                   	push   %eax
f0102ae8:	89 f2                	mov    %esi,%edx
f0102aea:	89 f8                	mov    %edi,%eax
f0102aec:	e8 9e ff ff ff       	call   f0102a8f <printnum>
f0102af1:	83 c4 20             	add    $0x20,%esp
f0102af4:	eb 18                	jmp    f0102b0e <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0102af6:	83 ec 08             	sub    $0x8,%esp
f0102af9:	56                   	push   %esi
f0102afa:	ff 75 18             	pushl  0x18(%ebp)
f0102afd:	ff d7                	call   *%edi
f0102aff:	83 c4 10             	add    $0x10,%esp
f0102b02:	eb 03                	jmp    f0102b07 <printnum+0x78>
f0102b04:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0102b07:	83 eb 01             	sub    $0x1,%ebx
f0102b0a:	85 db                	test   %ebx,%ebx
f0102b0c:	7f e8                	jg     f0102af6 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0102b0e:	83 ec 08             	sub    $0x8,%esp
f0102b11:	56                   	push   %esi
f0102b12:	83 ec 04             	sub    $0x4,%esp
f0102b15:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102b18:	ff 75 e0             	pushl  -0x20(%ebp)
f0102b1b:	ff 75 dc             	pushl  -0x24(%ebp)
f0102b1e:	ff 75 d8             	pushl  -0x28(%ebp)
f0102b21:	e8 2a 0a 00 00       	call   f0103550 <__umoddi3>
f0102b26:	83 c4 14             	add    $0x14,%esp
f0102b29:	0f be 80 5c 46 10 f0 	movsbl -0xfefb9a4(%eax),%eax
f0102b30:	50                   	push   %eax
f0102b31:	ff d7                	call   *%edi
}
f0102b33:	83 c4 10             	add    $0x10,%esp
f0102b36:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102b39:	5b                   	pop    %ebx
f0102b3a:	5e                   	pop    %esi
f0102b3b:	5f                   	pop    %edi
f0102b3c:	5d                   	pop    %ebp
f0102b3d:	c3                   	ret    

f0102b3e <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0102b3e:	55                   	push   %ebp
f0102b3f:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0102b41:	83 fa 01             	cmp    $0x1,%edx
f0102b44:	7e 0e                	jle    f0102b54 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0102b46:	8b 10                	mov    (%eax),%edx
f0102b48:	8d 4a 08             	lea    0x8(%edx),%ecx
f0102b4b:	89 08                	mov    %ecx,(%eax)
f0102b4d:	8b 02                	mov    (%edx),%eax
f0102b4f:	8b 52 04             	mov    0x4(%edx),%edx
f0102b52:	eb 22                	jmp    f0102b76 <getuint+0x38>
	else if (lflag)
f0102b54:	85 d2                	test   %edx,%edx
f0102b56:	74 10                	je     f0102b68 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0102b58:	8b 10                	mov    (%eax),%edx
f0102b5a:	8d 4a 04             	lea    0x4(%edx),%ecx
f0102b5d:	89 08                	mov    %ecx,(%eax)
f0102b5f:	8b 02                	mov    (%edx),%eax
f0102b61:	ba 00 00 00 00       	mov    $0x0,%edx
f0102b66:	eb 0e                	jmp    f0102b76 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0102b68:	8b 10                	mov    (%eax),%edx
f0102b6a:	8d 4a 04             	lea    0x4(%edx),%ecx
f0102b6d:	89 08                	mov    %ecx,(%eax)
f0102b6f:	8b 02                	mov    (%edx),%eax
f0102b71:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0102b76:	5d                   	pop    %ebp
f0102b77:	c3                   	ret    

f0102b78 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0102b78:	55                   	push   %ebp
f0102b79:	89 e5                	mov    %esp,%ebp
f0102b7b:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0102b7e:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0102b82:	8b 10                	mov    (%eax),%edx
f0102b84:	3b 50 04             	cmp    0x4(%eax),%edx
f0102b87:	73 0a                	jae    f0102b93 <sprintputch+0x1b>
		*b->buf++ = ch;
f0102b89:	8d 4a 01             	lea    0x1(%edx),%ecx
f0102b8c:	89 08                	mov    %ecx,(%eax)
f0102b8e:	8b 45 08             	mov    0x8(%ebp),%eax
f0102b91:	88 02                	mov    %al,(%edx)
}
f0102b93:	5d                   	pop    %ebp
f0102b94:	c3                   	ret    

f0102b95 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0102b95:	55                   	push   %ebp
f0102b96:	89 e5                	mov    %esp,%ebp
f0102b98:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0102b9b:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0102b9e:	50                   	push   %eax
f0102b9f:	ff 75 10             	pushl  0x10(%ebp)
f0102ba2:	ff 75 0c             	pushl  0xc(%ebp)
f0102ba5:	ff 75 08             	pushl  0x8(%ebp)
f0102ba8:	e8 05 00 00 00       	call   f0102bb2 <vprintfmt>
	va_end(ap);
}
f0102bad:	83 c4 10             	add    $0x10,%esp
f0102bb0:	c9                   	leave  
f0102bb1:	c3                   	ret    

f0102bb2 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0102bb2:	55                   	push   %ebp
f0102bb3:	89 e5                	mov    %esp,%ebp
f0102bb5:	57                   	push   %edi
f0102bb6:	56                   	push   %esi
f0102bb7:	53                   	push   %ebx
f0102bb8:	83 ec 2c             	sub    $0x2c,%esp
f0102bbb:	8b 75 08             	mov    0x8(%ebp),%esi
f0102bbe:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102bc1:	8b 7d 10             	mov    0x10(%ebp),%edi
f0102bc4:	eb 12                	jmp    f0102bd8 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0102bc6:	85 c0                	test   %eax,%eax
f0102bc8:	0f 84 89 03 00 00    	je     f0102f57 <vprintfmt+0x3a5>
				return;
			putch(ch, putdat);
f0102bce:	83 ec 08             	sub    $0x8,%esp
f0102bd1:	53                   	push   %ebx
f0102bd2:	50                   	push   %eax
f0102bd3:	ff d6                	call   *%esi
f0102bd5:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0102bd8:	83 c7 01             	add    $0x1,%edi
f0102bdb:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0102bdf:	83 f8 25             	cmp    $0x25,%eax
f0102be2:	75 e2                	jne    f0102bc6 <vprintfmt+0x14>
f0102be4:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0102be8:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0102bef:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102bf6:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0102bfd:	ba 00 00 00 00       	mov    $0x0,%edx
f0102c02:	eb 07                	jmp    f0102c0b <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c04:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0102c07:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c0b:	8d 47 01             	lea    0x1(%edi),%eax
f0102c0e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102c11:	0f b6 07             	movzbl (%edi),%eax
f0102c14:	0f b6 c8             	movzbl %al,%ecx
f0102c17:	83 e8 23             	sub    $0x23,%eax
f0102c1a:	3c 55                	cmp    $0x55,%al
f0102c1c:	0f 87 1a 03 00 00    	ja     f0102f3c <vprintfmt+0x38a>
f0102c22:	0f b6 c0             	movzbl %al,%eax
f0102c25:	ff 24 85 e8 46 10 f0 	jmp    *-0xfefb918(,%eax,4)
f0102c2c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0102c2f:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0102c33:	eb d6                	jmp    f0102c0b <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c35:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102c38:	b8 00 00 00 00       	mov    $0x0,%eax
f0102c3d:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0102c40:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0102c43:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0102c47:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0102c4a:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0102c4d:	83 fa 09             	cmp    $0x9,%edx
f0102c50:	77 39                	ja     f0102c8b <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0102c52:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0102c55:	eb e9                	jmp    f0102c40 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0102c57:	8b 45 14             	mov    0x14(%ebp),%eax
f0102c5a:	8d 48 04             	lea    0x4(%eax),%ecx
f0102c5d:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0102c60:	8b 00                	mov    (%eax),%eax
f0102c62:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c65:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0102c68:	eb 27                	jmp    f0102c91 <vprintfmt+0xdf>
f0102c6a:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102c6d:	85 c0                	test   %eax,%eax
f0102c6f:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102c74:	0f 49 c8             	cmovns %eax,%ecx
f0102c77:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c7a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102c7d:	eb 8c                	jmp    f0102c0b <vprintfmt+0x59>
f0102c7f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0102c82:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0102c89:	eb 80                	jmp    f0102c0b <vprintfmt+0x59>
f0102c8b:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0102c8e:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0102c91:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102c95:	0f 89 70 ff ff ff    	jns    f0102c0b <vprintfmt+0x59>
				width = precision, precision = -1;
f0102c9b:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102c9e:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102ca1:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102ca8:	e9 5e ff ff ff       	jmp    f0102c0b <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0102cad:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102cb0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0102cb3:	e9 53 ff ff ff       	jmp    f0102c0b <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0102cb8:	8b 45 14             	mov    0x14(%ebp),%eax
f0102cbb:	8d 50 04             	lea    0x4(%eax),%edx
f0102cbe:	89 55 14             	mov    %edx,0x14(%ebp)
f0102cc1:	83 ec 08             	sub    $0x8,%esp
f0102cc4:	53                   	push   %ebx
f0102cc5:	ff 30                	pushl  (%eax)
f0102cc7:	ff d6                	call   *%esi
			break;
f0102cc9:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102ccc:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0102ccf:	e9 04 ff ff ff       	jmp    f0102bd8 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0102cd4:	8b 45 14             	mov    0x14(%ebp),%eax
f0102cd7:	8d 50 04             	lea    0x4(%eax),%edx
f0102cda:	89 55 14             	mov    %edx,0x14(%ebp)
f0102cdd:	8b 00                	mov    (%eax),%eax
f0102cdf:	99                   	cltd   
f0102ce0:	31 d0                	xor    %edx,%eax
f0102ce2:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0102ce4:	83 f8 06             	cmp    $0x6,%eax
f0102ce7:	7f 0b                	jg     f0102cf4 <vprintfmt+0x142>
f0102ce9:	8b 14 85 40 48 10 f0 	mov    -0xfefb7c0(,%eax,4),%edx
f0102cf0:	85 d2                	test   %edx,%edx
f0102cf2:	75 18                	jne    f0102d0c <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f0102cf4:	50                   	push   %eax
f0102cf5:	68 74 46 10 f0       	push   $0xf0104674
f0102cfa:	53                   	push   %ebx
f0102cfb:	56                   	push   %esi
f0102cfc:	e8 94 fe ff ff       	call   f0102b95 <printfmt>
f0102d01:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102d04:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0102d07:	e9 cc fe ff ff       	jmp    f0102bd8 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0102d0c:	52                   	push   %edx
f0102d0d:	68 8c 43 10 f0       	push   $0xf010438c
f0102d12:	53                   	push   %ebx
f0102d13:	56                   	push   %esi
f0102d14:	e8 7c fe ff ff       	call   f0102b95 <printfmt>
f0102d19:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102d1c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102d1f:	e9 b4 fe ff ff       	jmp    f0102bd8 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0102d24:	8b 45 14             	mov    0x14(%ebp),%eax
f0102d27:	8d 50 04             	lea    0x4(%eax),%edx
f0102d2a:	89 55 14             	mov    %edx,0x14(%ebp)
f0102d2d:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0102d2f:	85 ff                	test   %edi,%edi
f0102d31:	b8 6d 46 10 f0       	mov    $0xf010466d,%eax
f0102d36:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0102d39:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102d3d:	0f 8e 94 00 00 00    	jle    f0102dd7 <vprintfmt+0x225>
f0102d43:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0102d47:	0f 84 98 00 00 00    	je     f0102de5 <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
f0102d4d:	83 ec 08             	sub    $0x8,%esp
f0102d50:	ff 75 d0             	pushl  -0x30(%ebp)
f0102d53:	57                   	push   %edi
f0102d54:	e8 5f 03 00 00       	call   f01030b8 <strnlen>
f0102d59:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0102d5c:	29 c1                	sub    %eax,%ecx
f0102d5e:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0102d61:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0102d64:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0102d68:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102d6b:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0102d6e:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102d70:	eb 0f                	jmp    f0102d81 <vprintfmt+0x1cf>
					putch(padc, putdat);
f0102d72:	83 ec 08             	sub    $0x8,%esp
f0102d75:	53                   	push   %ebx
f0102d76:	ff 75 e0             	pushl  -0x20(%ebp)
f0102d79:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102d7b:	83 ef 01             	sub    $0x1,%edi
f0102d7e:	83 c4 10             	add    $0x10,%esp
f0102d81:	85 ff                	test   %edi,%edi
f0102d83:	7f ed                	jg     f0102d72 <vprintfmt+0x1c0>
f0102d85:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102d88:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0102d8b:	85 c9                	test   %ecx,%ecx
f0102d8d:	b8 00 00 00 00       	mov    $0x0,%eax
f0102d92:	0f 49 c1             	cmovns %ecx,%eax
f0102d95:	29 c1                	sub    %eax,%ecx
f0102d97:	89 75 08             	mov    %esi,0x8(%ebp)
f0102d9a:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102d9d:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102da0:	89 cb                	mov    %ecx,%ebx
f0102da2:	eb 4d                	jmp    f0102df1 <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0102da4:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0102da8:	74 1b                	je     f0102dc5 <vprintfmt+0x213>
f0102daa:	0f be c0             	movsbl %al,%eax
f0102dad:	83 e8 20             	sub    $0x20,%eax
f0102db0:	83 f8 5e             	cmp    $0x5e,%eax
f0102db3:	76 10                	jbe    f0102dc5 <vprintfmt+0x213>
					putch('?', putdat);
f0102db5:	83 ec 08             	sub    $0x8,%esp
f0102db8:	ff 75 0c             	pushl  0xc(%ebp)
f0102dbb:	6a 3f                	push   $0x3f
f0102dbd:	ff 55 08             	call   *0x8(%ebp)
f0102dc0:	83 c4 10             	add    $0x10,%esp
f0102dc3:	eb 0d                	jmp    f0102dd2 <vprintfmt+0x220>
				else
					putch(ch, putdat);
f0102dc5:	83 ec 08             	sub    $0x8,%esp
f0102dc8:	ff 75 0c             	pushl  0xc(%ebp)
f0102dcb:	52                   	push   %edx
f0102dcc:	ff 55 08             	call   *0x8(%ebp)
f0102dcf:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0102dd2:	83 eb 01             	sub    $0x1,%ebx
f0102dd5:	eb 1a                	jmp    f0102df1 <vprintfmt+0x23f>
f0102dd7:	89 75 08             	mov    %esi,0x8(%ebp)
f0102dda:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102ddd:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102de0:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102de3:	eb 0c                	jmp    f0102df1 <vprintfmt+0x23f>
f0102de5:	89 75 08             	mov    %esi,0x8(%ebp)
f0102de8:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102deb:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102dee:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102df1:	83 c7 01             	add    $0x1,%edi
f0102df4:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0102df8:	0f be d0             	movsbl %al,%edx
f0102dfb:	85 d2                	test   %edx,%edx
f0102dfd:	74 23                	je     f0102e22 <vprintfmt+0x270>
f0102dff:	85 f6                	test   %esi,%esi
f0102e01:	78 a1                	js     f0102da4 <vprintfmt+0x1f2>
f0102e03:	83 ee 01             	sub    $0x1,%esi
f0102e06:	79 9c                	jns    f0102da4 <vprintfmt+0x1f2>
f0102e08:	89 df                	mov    %ebx,%edi
f0102e0a:	8b 75 08             	mov    0x8(%ebp),%esi
f0102e0d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102e10:	eb 18                	jmp    f0102e2a <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0102e12:	83 ec 08             	sub    $0x8,%esp
f0102e15:	53                   	push   %ebx
f0102e16:	6a 20                	push   $0x20
f0102e18:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0102e1a:	83 ef 01             	sub    $0x1,%edi
f0102e1d:	83 c4 10             	add    $0x10,%esp
f0102e20:	eb 08                	jmp    f0102e2a <vprintfmt+0x278>
f0102e22:	89 df                	mov    %ebx,%edi
f0102e24:	8b 75 08             	mov    0x8(%ebp),%esi
f0102e27:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102e2a:	85 ff                	test   %edi,%edi
f0102e2c:	7f e4                	jg     f0102e12 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102e2e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102e31:	e9 a2 fd ff ff       	jmp    f0102bd8 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0102e36:	83 fa 01             	cmp    $0x1,%edx
f0102e39:	7e 16                	jle    f0102e51 <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f0102e3b:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e3e:	8d 50 08             	lea    0x8(%eax),%edx
f0102e41:	89 55 14             	mov    %edx,0x14(%ebp)
f0102e44:	8b 50 04             	mov    0x4(%eax),%edx
f0102e47:	8b 00                	mov    (%eax),%eax
f0102e49:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102e4c:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0102e4f:	eb 32                	jmp    f0102e83 <vprintfmt+0x2d1>
	else if (lflag)
f0102e51:	85 d2                	test   %edx,%edx
f0102e53:	74 18                	je     f0102e6d <vprintfmt+0x2bb>
		return va_arg(*ap, long);
f0102e55:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e58:	8d 50 04             	lea    0x4(%eax),%edx
f0102e5b:	89 55 14             	mov    %edx,0x14(%ebp)
f0102e5e:	8b 00                	mov    (%eax),%eax
f0102e60:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102e63:	89 c1                	mov    %eax,%ecx
f0102e65:	c1 f9 1f             	sar    $0x1f,%ecx
f0102e68:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0102e6b:	eb 16                	jmp    f0102e83 <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
f0102e6d:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e70:	8d 50 04             	lea    0x4(%eax),%edx
f0102e73:	89 55 14             	mov    %edx,0x14(%ebp)
f0102e76:	8b 00                	mov    (%eax),%eax
f0102e78:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102e7b:	89 c1                	mov    %eax,%ecx
f0102e7d:	c1 f9 1f             	sar    $0x1f,%ecx
f0102e80:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0102e83:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102e86:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0102e89:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0102e8e:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0102e92:	79 74                	jns    f0102f08 <vprintfmt+0x356>
				putch('-', putdat);
f0102e94:	83 ec 08             	sub    $0x8,%esp
f0102e97:	53                   	push   %ebx
f0102e98:	6a 2d                	push   $0x2d
f0102e9a:	ff d6                	call   *%esi
				num = -(long long) num;
f0102e9c:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102e9f:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102ea2:	f7 d8                	neg    %eax
f0102ea4:	83 d2 00             	adc    $0x0,%edx
f0102ea7:	f7 da                	neg    %edx
f0102ea9:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0102eac:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0102eb1:	eb 55                	jmp    f0102f08 <vprintfmt+0x356>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0102eb3:	8d 45 14             	lea    0x14(%ebp),%eax
f0102eb6:	e8 83 fc ff ff       	call   f0102b3e <getuint>
			base = 10;
f0102ebb:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0102ec0:	eb 46                	jmp    f0102f08 <vprintfmt+0x356>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f0102ec2:	8d 45 14             	lea    0x14(%ebp),%eax
f0102ec5:	e8 74 fc ff ff       	call   f0102b3e <getuint>
			base = 8;
f0102eca:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0102ecf:	eb 37                	jmp    f0102f08 <vprintfmt+0x356>

		// pointer
		case 'p':
			putch('0', putdat);
f0102ed1:	83 ec 08             	sub    $0x8,%esp
f0102ed4:	53                   	push   %ebx
f0102ed5:	6a 30                	push   $0x30
f0102ed7:	ff d6                	call   *%esi
			putch('x', putdat);
f0102ed9:	83 c4 08             	add    $0x8,%esp
f0102edc:	53                   	push   %ebx
f0102edd:	6a 78                	push   $0x78
f0102edf:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0102ee1:	8b 45 14             	mov    0x14(%ebp),%eax
f0102ee4:	8d 50 04             	lea    0x4(%eax),%edx
f0102ee7:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0102eea:	8b 00                	mov    (%eax),%eax
f0102eec:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0102ef1:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0102ef4:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0102ef9:	eb 0d                	jmp    f0102f08 <vprintfmt+0x356>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0102efb:	8d 45 14             	lea    0x14(%ebp),%eax
f0102efe:	e8 3b fc ff ff       	call   f0102b3e <getuint>
			base = 16;
f0102f03:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0102f08:	83 ec 0c             	sub    $0xc,%esp
f0102f0b:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0102f0f:	57                   	push   %edi
f0102f10:	ff 75 e0             	pushl  -0x20(%ebp)
f0102f13:	51                   	push   %ecx
f0102f14:	52                   	push   %edx
f0102f15:	50                   	push   %eax
f0102f16:	89 da                	mov    %ebx,%edx
f0102f18:	89 f0                	mov    %esi,%eax
f0102f1a:	e8 70 fb ff ff       	call   f0102a8f <printnum>
			break;
f0102f1f:	83 c4 20             	add    $0x20,%esp
f0102f22:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102f25:	e9 ae fc ff ff       	jmp    f0102bd8 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0102f2a:	83 ec 08             	sub    $0x8,%esp
f0102f2d:	53                   	push   %ebx
f0102f2e:	51                   	push   %ecx
f0102f2f:	ff d6                	call   *%esi
			break;
f0102f31:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102f34:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0102f37:	e9 9c fc ff ff       	jmp    f0102bd8 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0102f3c:	83 ec 08             	sub    $0x8,%esp
f0102f3f:	53                   	push   %ebx
f0102f40:	6a 25                	push   $0x25
f0102f42:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0102f44:	83 c4 10             	add    $0x10,%esp
f0102f47:	eb 03                	jmp    f0102f4c <vprintfmt+0x39a>
f0102f49:	83 ef 01             	sub    $0x1,%edi
f0102f4c:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0102f50:	75 f7                	jne    f0102f49 <vprintfmt+0x397>
f0102f52:	e9 81 fc ff ff       	jmp    f0102bd8 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0102f57:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102f5a:	5b                   	pop    %ebx
f0102f5b:	5e                   	pop    %esi
f0102f5c:	5f                   	pop    %edi
f0102f5d:	5d                   	pop    %ebp
f0102f5e:	c3                   	ret    

f0102f5f <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0102f5f:	55                   	push   %ebp
f0102f60:	89 e5                	mov    %esp,%ebp
f0102f62:	83 ec 18             	sub    $0x18,%esp
f0102f65:	8b 45 08             	mov    0x8(%ebp),%eax
f0102f68:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0102f6b:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0102f6e:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0102f72:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0102f75:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0102f7c:	85 c0                	test   %eax,%eax
f0102f7e:	74 26                	je     f0102fa6 <vsnprintf+0x47>
f0102f80:	85 d2                	test   %edx,%edx
f0102f82:	7e 22                	jle    f0102fa6 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0102f84:	ff 75 14             	pushl  0x14(%ebp)
f0102f87:	ff 75 10             	pushl  0x10(%ebp)
f0102f8a:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0102f8d:	50                   	push   %eax
f0102f8e:	68 78 2b 10 f0       	push   $0xf0102b78
f0102f93:	e8 1a fc ff ff       	call   f0102bb2 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0102f98:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0102f9b:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0102f9e:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102fa1:	83 c4 10             	add    $0x10,%esp
f0102fa4:	eb 05                	jmp    f0102fab <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0102fa6:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0102fab:	c9                   	leave  
f0102fac:	c3                   	ret    

f0102fad <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0102fad:	55                   	push   %ebp
f0102fae:	89 e5                	mov    %esp,%ebp
f0102fb0:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0102fb3:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0102fb6:	50                   	push   %eax
f0102fb7:	ff 75 10             	pushl  0x10(%ebp)
f0102fba:	ff 75 0c             	pushl  0xc(%ebp)
f0102fbd:	ff 75 08             	pushl  0x8(%ebp)
f0102fc0:	e8 9a ff ff ff       	call   f0102f5f <vsnprintf>
	va_end(ap);

	return rc;
}
f0102fc5:	c9                   	leave  
f0102fc6:	c3                   	ret    

f0102fc7 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0102fc7:	55                   	push   %ebp
f0102fc8:	89 e5                	mov    %esp,%ebp
f0102fca:	57                   	push   %edi
f0102fcb:	56                   	push   %esi
f0102fcc:	53                   	push   %ebx
f0102fcd:	83 ec 0c             	sub    $0xc,%esp
f0102fd0:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0102fd3:	85 c0                	test   %eax,%eax
f0102fd5:	74 11                	je     f0102fe8 <readline+0x21>
		cprintf("%s", prompt);
f0102fd7:	83 ec 08             	sub    $0x8,%esp
f0102fda:	50                   	push   %eax
f0102fdb:	68 8c 43 10 f0       	push   $0xf010438c
f0102fe0:	e8 80 f7 ff ff       	call   f0102765 <cprintf>
f0102fe5:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0102fe8:	83 ec 0c             	sub    $0xc,%esp
f0102feb:	6a 00                	push   $0x0
f0102fed:	e8 2f d6 ff ff       	call   f0100621 <iscons>
f0102ff2:	89 c7                	mov    %eax,%edi
f0102ff4:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0102ff7:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0102ffc:	e8 0f d6 ff ff       	call   f0100610 <getchar>
f0103001:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0103003:	85 c0                	test   %eax,%eax
f0103005:	79 18                	jns    f010301f <readline+0x58>
			cprintf("read error: %e\n", c);
f0103007:	83 ec 08             	sub    $0x8,%esp
f010300a:	50                   	push   %eax
f010300b:	68 5c 48 10 f0       	push   $0xf010485c
f0103010:	e8 50 f7 ff ff       	call   f0102765 <cprintf>
			return NULL;
f0103015:	83 c4 10             	add    $0x10,%esp
f0103018:	b8 00 00 00 00       	mov    $0x0,%eax
f010301d:	eb 79                	jmp    f0103098 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f010301f:	83 f8 08             	cmp    $0x8,%eax
f0103022:	0f 94 c2             	sete   %dl
f0103025:	83 f8 7f             	cmp    $0x7f,%eax
f0103028:	0f 94 c0             	sete   %al
f010302b:	08 c2                	or     %al,%dl
f010302d:	74 1a                	je     f0103049 <readline+0x82>
f010302f:	85 f6                	test   %esi,%esi
f0103031:	7e 16                	jle    f0103049 <readline+0x82>
			if (echoing)
f0103033:	85 ff                	test   %edi,%edi
f0103035:	74 0d                	je     f0103044 <readline+0x7d>
				cputchar('\b');
f0103037:	83 ec 0c             	sub    $0xc,%esp
f010303a:	6a 08                	push   $0x8
f010303c:	e8 bf d5 ff ff       	call   f0100600 <cputchar>
f0103041:	83 c4 10             	add    $0x10,%esp
			i--;
f0103044:	83 ee 01             	sub    $0x1,%esi
f0103047:	eb b3                	jmp    f0102ffc <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0103049:	83 fb 1f             	cmp    $0x1f,%ebx
f010304c:	7e 23                	jle    f0103071 <readline+0xaa>
f010304e:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0103054:	7f 1b                	jg     f0103071 <readline+0xaa>
			if (echoing)
f0103056:	85 ff                	test   %edi,%edi
f0103058:	74 0c                	je     f0103066 <readline+0x9f>
				cputchar(c);
f010305a:	83 ec 0c             	sub    $0xc,%esp
f010305d:	53                   	push   %ebx
f010305e:	e8 9d d5 ff ff       	call   f0100600 <cputchar>
f0103063:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0103066:	88 9e 60 65 11 f0    	mov    %bl,-0xfee9aa0(%esi)
f010306c:	8d 76 01             	lea    0x1(%esi),%esi
f010306f:	eb 8b                	jmp    f0102ffc <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0103071:	83 fb 0a             	cmp    $0xa,%ebx
f0103074:	74 05                	je     f010307b <readline+0xb4>
f0103076:	83 fb 0d             	cmp    $0xd,%ebx
f0103079:	75 81                	jne    f0102ffc <readline+0x35>
			if (echoing)
f010307b:	85 ff                	test   %edi,%edi
f010307d:	74 0d                	je     f010308c <readline+0xc5>
				cputchar('\n');
f010307f:	83 ec 0c             	sub    $0xc,%esp
f0103082:	6a 0a                	push   $0xa
f0103084:	e8 77 d5 ff ff       	call   f0100600 <cputchar>
f0103089:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f010308c:	c6 86 60 65 11 f0 00 	movb   $0x0,-0xfee9aa0(%esi)
			return buf;
f0103093:	b8 60 65 11 f0       	mov    $0xf0116560,%eax
		}
	}
}
f0103098:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010309b:	5b                   	pop    %ebx
f010309c:	5e                   	pop    %esi
f010309d:	5f                   	pop    %edi
f010309e:	5d                   	pop    %ebp
f010309f:	c3                   	ret    

f01030a0 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01030a0:	55                   	push   %ebp
f01030a1:	89 e5                	mov    %esp,%ebp
f01030a3:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01030a6:	b8 00 00 00 00       	mov    $0x0,%eax
f01030ab:	eb 03                	jmp    f01030b0 <strlen+0x10>
		n++;
f01030ad:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01030b0:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01030b4:	75 f7                	jne    f01030ad <strlen+0xd>
		n++;
	return n;
}
f01030b6:	5d                   	pop    %ebp
f01030b7:	c3                   	ret    

f01030b8 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01030b8:	55                   	push   %ebp
f01030b9:	89 e5                	mov    %esp,%ebp
f01030bb:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01030be:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01030c1:	ba 00 00 00 00       	mov    $0x0,%edx
f01030c6:	eb 03                	jmp    f01030cb <strnlen+0x13>
		n++;
f01030c8:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01030cb:	39 c2                	cmp    %eax,%edx
f01030cd:	74 08                	je     f01030d7 <strnlen+0x1f>
f01030cf:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f01030d3:	75 f3                	jne    f01030c8 <strnlen+0x10>
f01030d5:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f01030d7:	5d                   	pop    %ebp
f01030d8:	c3                   	ret    

f01030d9 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01030d9:	55                   	push   %ebp
f01030da:	89 e5                	mov    %esp,%ebp
f01030dc:	53                   	push   %ebx
f01030dd:	8b 45 08             	mov    0x8(%ebp),%eax
f01030e0:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01030e3:	89 c2                	mov    %eax,%edx
f01030e5:	83 c2 01             	add    $0x1,%edx
f01030e8:	83 c1 01             	add    $0x1,%ecx
f01030eb:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f01030ef:	88 5a ff             	mov    %bl,-0x1(%edx)
f01030f2:	84 db                	test   %bl,%bl
f01030f4:	75 ef                	jne    f01030e5 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f01030f6:	5b                   	pop    %ebx
f01030f7:	5d                   	pop    %ebp
f01030f8:	c3                   	ret    

f01030f9 <strcat>:

char *
strcat(char *dst, const char *src)
{
f01030f9:	55                   	push   %ebp
f01030fa:	89 e5                	mov    %esp,%ebp
f01030fc:	53                   	push   %ebx
f01030fd:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0103100:	53                   	push   %ebx
f0103101:	e8 9a ff ff ff       	call   f01030a0 <strlen>
f0103106:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0103109:	ff 75 0c             	pushl  0xc(%ebp)
f010310c:	01 d8                	add    %ebx,%eax
f010310e:	50                   	push   %eax
f010310f:	e8 c5 ff ff ff       	call   f01030d9 <strcpy>
	return dst;
}
f0103114:	89 d8                	mov    %ebx,%eax
f0103116:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103119:	c9                   	leave  
f010311a:	c3                   	ret    

f010311b <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f010311b:	55                   	push   %ebp
f010311c:	89 e5                	mov    %esp,%ebp
f010311e:	56                   	push   %esi
f010311f:	53                   	push   %ebx
f0103120:	8b 75 08             	mov    0x8(%ebp),%esi
f0103123:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103126:	89 f3                	mov    %esi,%ebx
f0103128:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f010312b:	89 f2                	mov    %esi,%edx
f010312d:	eb 0f                	jmp    f010313e <strncpy+0x23>
		*dst++ = *src;
f010312f:	83 c2 01             	add    $0x1,%edx
f0103132:	0f b6 01             	movzbl (%ecx),%eax
f0103135:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0103138:	80 39 01             	cmpb   $0x1,(%ecx)
f010313b:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f010313e:	39 da                	cmp    %ebx,%edx
f0103140:	75 ed                	jne    f010312f <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0103142:	89 f0                	mov    %esi,%eax
f0103144:	5b                   	pop    %ebx
f0103145:	5e                   	pop    %esi
f0103146:	5d                   	pop    %ebp
f0103147:	c3                   	ret    

f0103148 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0103148:	55                   	push   %ebp
f0103149:	89 e5                	mov    %esp,%ebp
f010314b:	56                   	push   %esi
f010314c:	53                   	push   %ebx
f010314d:	8b 75 08             	mov    0x8(%ebp),%esi
f0103150:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103153:	8b 55 10             	mov    0x10(%ebp),%edx
f0103156:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0103158:	85 d2                	test   %edx,%edx
f010315a:	74 21                	je     f010317d <strlcpy+0x35>
f010315c:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0103160:	89 f2                	mov    %esi,%edx
f0103162:	eb 09                	jmp    f010316d <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0103164:	83 c2 01             	add    $0x1,%edx
f0103167:	83 c1 01             	add    $0x1,%ecx
f010316a:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f010316d:	39 c2                	cmp    %eax,%edx
f010316f:	74 09                	je     f010317a <strlcpy+0x32>
f0103171:	0f b6 19             	movzbl (%ecx),%ebx
f0103174:	84 db                	test   %bl,%bl
f0103176:	75 ec                	jne    f0103164 <strlcpy+0x1c>
f0103178:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f010317a:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f010317d:	29 f0                	sub    %esi,%eax
}
f010317f:	5b                   	pop    %ebx
f0103180:	5e                   	pop    %esi
f0103181:	5d                   	pop    %ebp
f0103182:	c3                   	ret    

f0103183 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0103183:	55                   	push   %ebp
f0103184:	89 e5                	mov    %esp,%ebp
f0103186:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103189:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f010318c:	eb 06                	jmp    f0103194 <strcmp+0x11>
		p++, q++;
f010318e:	83 c1 01             	add    $0x1,%ecx
f0103191:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0103194:	0f b6 01             	movzbl (%ecx),%eax
f0103197:	84 c0                	test   %al,%al
f0103199:	74 04                	je     f010319f <strcmp+0x1c>
f010319b:	3a 02                	cmp    (%edx),%al
f010319d:	74 ef                	je     f010318e <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f010319f:	0f b6 c0             	movzbl %al,%eax
f01031a2:	0f b6 12             	movzbl (%edx),%edx
f01031a5:	29 d0                	sub    %edx,%eax
}
f01031a7:	5d                   	pop    %ebp
f01031a8:	c3                   	ret    

f01031a9 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01031a9:	55                   	push   %ebp
f01031aa:	89 e5                	mov    %esp,%ebp
f01031ac:	53                   	push   %ebx
f01031ad:	8b 45 08             	mov    0x8(%ebp),%eax
f01031b0:	8b 55 0c             	mov    0xc(%ebp),%edx
f01031b3:	89 c3                	mov    %eax,%ebx
f01031b5:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01031b8:	eb 06                	jmp    f01031c0 <strncmp+0x17>
		n--, p++, q++;
f01031ba:	83 c0 01             	add    $0x1,%eax
f01031bd:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01031c0:	39 d8                	cmp    %ebx,%eax
f01031c2:	74 15                	je     f01031d9 <strncmp+0x30>
f01031c4:	0f b6 08             	movzbl (%eax),%ecx
f01031c7:	84 c9                	test   %cl,%cl
f01031c9:	74 04                	je     f01031cf <strncmp+0x26>
f01031cb:	3a 0a                	cmp    (%edx),%cl
f01031cd:	74 eb                	je     f01031ba <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01031cf:	0f b6 00             	movzbl (%eax),%eax
f01031d2:	0f b6 12             	movzbl (%edx),%edx
f01031d5:	29 d0                	sub    %edx,%eax
f01031d7:	eb 05                	jmp    f01031de <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f01031d9:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01031de:	5b                   	pop    %ebx
f01031df:	5d                   	pop    %ebp
f01031e0:	c3                   	ret    

f01031e1 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01031e1:	55                   	push   %ebp
f01031e2:	89 e5                	mov    %esp,%ebp
f01031e4:	8b 45 08             	mov    0x8(%ebp),%eax
f01031e7:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01031eb:	eb 07                	jmp    f01031f4 <strchr+0x13>
		if (*s == c)
f01031ed:	38 ca                	cmp    %cl,%dl
f01031ef:	74 0f                	je     f0103200 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01031f1:	83 c0 01             	add    $0x1,%eax
f01031f4:	0f b6 10             	movzbl (%eax),%edx
f01031f7:	84 d2                	test   %dl,%dl
f01031f9:	75 f2                	jne    f01031ed <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f01031fb:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103200:	5d                   	pop    %ebp
f0103201:	c3                   	ret    

f0103202 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0103202:	55                   	push   %ebp
f0103203:	89 e5                	mov    %esp,%ebp
f0103205:	8b 45 08             	mov    0x8(%ebp),%eax
f0103208:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010320c:	eb 03                	jmp    f0103211 <strfind+0xf>
f010320e:	83 c0 01             	add    $0x1,%eax
f0103211:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0103214:	38 ca                	cmp    %cl,%dl
f0103216:	74 04                	je     f010321c <strfind+0x1a>
f0103218:	84 d2                	test   %dl,%dl
f010321a:	75 f2                	jne    f010320e <strfind+0xc>
			break;
	return (char *) s;
}
f010321c:	5d                   	pop    %ebp
f010321d:	c3                   	ret    

f010321e <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f010321e:	55                   	push   %ebp
f010321f:	89 e5                	mov    %esp,%ebp
f0103221:	57                   	push   %edi
f0103222:	56                   	push   %esi
f0103223:	53                   	push   %ebx
f0103224:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103227:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f010322a:	85 c9                	test   %ecx,%ecx
f010322c:	74 36                	je     f0103264 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f010322e:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0103234:	75 28                	jne    f010325e <memset+0x40>
f0103236:	f6 c1 03             	test   $0x3,%cl
f0103239:	75 23                	jne    f010325e <memset+0x40>
		c &= 0xFF;
f010323b:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f010323f:	89 d3                	mov    %edx,%ebx
f0103241:	c1 e3 08             	shl    $0x8,%ebx
f0103244:	89 d6                	mov    %edx,%esi
f0103246:	c1 e6 18             	shl    $0x18,%esi
f0103249:	89 d0                	mov    %edx,%eax
f010324b:	c1 e0 10             	shl    $0x10,%eax
f010324e:	09 f0                	or     %esi,%eax
f0103250:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f0103252:	89 d8                	mov    %ebx,%eax
f0103254:	09 d0                	or     %edx,%eax
f0103256:	c1 e9 02             	shr    $0x2,%ecx
f0103259:	fc                   	cld    
f010325a:	f3 ab                	rep stos %eax,%es:(%edi)
f010325c:	eb 06                	jmp    f0103264 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f010325e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103261:	fc                   	cld    
f0103262:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0103264:	89 f8                	mov    %edi,%eax
f0103266:	5b                   	pop    %ebx
f0103267:	5e                   	pop    %esi
f0103268:	5f                   	pop    %edi
f0103269:	5d                   	pop    %ebp
f010326a:	c3                   	ret    

f010326b <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f010326b:	55                   	push   %ebp
f010326c:	89 e5                	mov    %esp,%ebp
f010326e:	57                   	push   %edi
f010326f:	56                   	push   %esi
f0103270:	8b 45 08             	mov    0x8(%ebp),%eax
f0103273:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103276:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0103279:	39 c6                	cmp    %eax,%esi
f010327b:	73 35                	jae    f01032b2 <memmove+0x47>
f010327d:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0103280:	39 d0                	cmp    %edx,%eax
f0103282:	73 2e                	jae    f01032b2 <memmove+0x47>
		s += n;
		d += n;
f0103284:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103287:	89 d6                	mov    %edx,%esi
f0103289:	09 fe                	or     %edi,%esi
f010328b:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0103291:	75 13                	jne    f01032a6 <memmove+0x3b>
f0103293:	f6 c1 03             	test   $0x3,%cl
f0103296:	75 0e                	jne    f01032a6 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f0103298:	83 ef 04             	sub    $0x4,%edi
f010329b:	8d 72 fc             	lea    -0x4(%edx),%esi
f010329e:	c1 e9 02             	shr    $0x2,%ecx
f01032a1:	fd                   	std    
f01032a2:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01032a4:	eb 09                	jmp    f01032af <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01032a6:	83 ef 01             	sub    $0x1,%edi
f01032a9:	8d 72 ff             	lea    -0x1(%edx),%esi
f01032ac:	fd                   	std    
f01032ad:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01032af:	fc                   	cld    
f01032b0:	eb 1d                	jmp    f01032cf <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01032b2:	89 f2                	mov    %esi,%edx
f01032b4:	09 c2                	or     %eax,%edx
f01032b6:	f6 c2 03             	test   $0x3,%dl
f01032b9:	75 0f                	jne    f01032ca <memmove+0x5f>
f01032bb:	f6 c1 03             	test   $0x3,%cl
f01032be:	75 0a                	jne    f01032ca <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f01032c0:	c1 e9 02             	shr    $0x2,%ecx
f01032c3:	89 c7                	mov    %eax,%edi
f01032c5:	fc                   	cld    
f01032c6:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01032c8:	eb 05                	jmp    f01032cf <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01032ca:	89 c7                	mov    %eax,%edi
f01032cc:	fc                   	cld    
f01032cd:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01032cf:	5e                   	pop    %esi
f01032d0:	5f                   	pop    %edi
f01032d1:	5d                   	pop    %ebp
f01032d2:	c3                   	ret    

f01032d3 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01032d3:	55                   	push   %ebp
f01032d4:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f01032d6:	ff 75 10             	pushl  0x10(%ebp)
f01032d9:	ff 75 0c             	pushl  0xc(%ebp)
f01032dc:	ff 75 08             	pushl  0x8(%ebp)
f01032df:	e8 87 ff ff ff       	call   f010326b <memmove>
}
f01032e4:	c9                   	leave  
f01032e5:	c3                   	ret    

f01032e6 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01032e6:	55                   	push   %ebp
f01032e7:	89 e5                	mov    %esp,%ebp
f01032e9:	56                   	push   %esi
f01032ea:	53                   	push   %ebx
f01032eb:	8b 45 08             	mov    0x8(%ebp),%eax
f01032ee:	8b 55 0c             	mov    0xc(%ebp),%edx
f01032f1:	89 c6                	mov    %eax,%esi
f01032f3:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01032f6:	eb 1a                	jmp    f0103312 <memcmp+0x2c>
		if (*s1 != *s2)
f01032f8:	0f b6 08             	movzbl (%eax),%ecx
f01032fb:	0f b6 1a             	movzbl (%edx),%ebx
f01032fe:	38 d9                	cmp    %bl,%cl
f0103300:	74 0a                	je     f010330c <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0103302:	0f b6 c1             	movzbl %cl,%eax
f0103305:	0f b6 db             	movzbl %bl,%ebx
f0103308:	29 d8                	sub    %ebx,%eax
f010330a:	eb 0f                	jmp    f010331b <memcmp+0x35>
		s1++, s2++;
f010330c:	83 c0 01             	add    $0x1,%eax
f010330f:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103312:	39 f0                	cmp    %esi,%eax
f0103314:	75 e2                	jne    f01032f8 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0103316:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010331b:	5b                   	pop    %ebx
f010331c:	5e                   	pop    %esi
f010331d:	5d                   	pop    %ebp
f010331e:	c3                   	ret    

f010331f <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f010331f:	55                   	push   %ebp
f0103320:	89 e5                	mov    %esp,%ebp
f0103322:	53                   	push   %ebx
f0103323:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0103326:	89 c1                	mov    %eax,%ecx
f0103328:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f010332b:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010332f:	eb 0a                	jmp    f010333b <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f0103331:	0f b6 10             	movzbl (%eax),%edx
f0103334:	39 da                	cmp    %ebx,%edx
f0103336:	74 07                	je     f010333f <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0103338:	83 c0 01             	add    $0x1,%eax
f010333b:	39 c8                	cmp    %ecx,%eax
f010333d:	72 f2                	jb     f0103331 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f010333f:	5b                   	pop    %ebx
f0103340:	5d                   	pop    %ebp
f0103341:	c3                   	ret    

f0103342 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0103342:	55                   	push   %ebp
f0103343:	89 e5                	mov    %esp,%ebp
f0103345:	57                   	push   %edi
f0103346:	56                   	push   %esi
f0103347:	53                   	push   %ebx
f0103348:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010334b:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010334e:	eb 03                	jmp    f0103353 <strtol+0x11>
		s++;
f0103350:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103353:	0f b6 01             	movzbl (%ecx),%eax
f0103356:	3c 20                	cmp    $0x20,%al
f0103358:	74 f6                	je     f0103350 <strtol+0xe>
f010335a:	3c 09                	cmp    $0x9,%al
f010335c:	74 f2                	je     f0103350 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f010335e:	3c 2b                	cmp    $0x2b,%al
f0103360:	75 0a                	jne    f010336c <strtol+0x2a>
		s++;
f0103362:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0103365:	bf 00 00 00 00       	mov    $0x0,%edi
f010336a:	eb 11                	jmp    f010337d <strtol+0x3b>
f010336c:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0103371:	3c 2d                	cmp    $0x2d,%al
f0103373:	75 08                	jne    f010337d <strtol+0x3b>
		s++, neg = 1;
f0103375:	83 c1 01             	add    $0x1,%ecx
f0103378:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f010337d:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0103383:	75 15                	jne    f010339a <strtol+0x58>
f0103385:	80 39 30             	cmpb   $0x30,(%ecx)
f0103388:	75 10                	jne    f010339a <strtol+0x58>
f010338a:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f010338e:	75 7c                	jne    f010340c <strtol+0xca>
		s += 2, base = 16;
f0103390:	83 c1 02             	add    $0x2,%ecx
f0103393:	bb 10 00 00 00       	mov    $0x10,%ebx
f0103398:	eb 16                	jmp    f01033b0 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f010339a:	85 db                	test   %ebx,%ebx
f010339c:	75 12                	jne    f01033b0 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f010339e:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01033a3:	80 39 30             	cmpb   $0x30,(%ecx)
f01033a6:	75 08                	jne    f01033b0 <strtol+0x6e>
		s++, base = 8;
f01033a8:	83 c1 01             	add    $0x1,%ecx
f01033ab:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f01033b0:	b8 00 00 00 00       	mov    $0x0,%eax
f01033b5:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f01033b8:	0f b6 11             	movzbl (%ecx),%edx
f01033bb:	8d 72 d0             	lea    -0x30(%edx),%esi
f01033be:	89 f3                	mov    %esi,%ebx
f01033c0:	80 fb 09             	cmp    $0x9,%bl
f01033c3:	77 08                	ja     f01033cd <strtol+0x8b>
			dig = *s - '0';
f01033c5:	0f be d2             	movsbl %dl,%edx
f01033c8:	83 ea 30             	sub    $0x30,%edx
f01033cb:	eb 22                	jmp    f01033ef <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f01033cd:	8d 72 9f             	lea    -0x61(%edx),%esi
f01033d0:	89 f3                	mov    %esi,%ebx
f01033d2:	80 fb 19             	cmp    $0x19,%bl
f01033d5:	77 08                	ja     f01033df <strtol+0x9d>
			dig = *s - 'a' + 10;
f01033d7:	0f be d2             	movsbl %dl,%edx
f01033da:	83 ea 57             	sub    $0x57,%edx
f01033dd:	eb 10                	jmp    f01033ef <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f01033df:	8d 72 bf             	lea    -0x41(%edx),%esi
f01033e2:	89 f3                	mov    %esi,%ebx
f01033e4:	80 fb 19             	cmp    $0x19,%bl
f01033e7:	77 16                	ja     f01033ff <strtol+0xbd>
			dig = *s - 'A' + 10;
f01033e9:	0f be d2             	movsbl %dl,%edx
f01033ec:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f01033ef:	3b 55 10             	cmp    0x10(%ebp),%edx
f01033f2:	7d 0b                	jge    f01033ff <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f01033f4:	83 c1 01             	add    $0x1,%ecx
f01033f7:	0f af 45 10          	imul   0x10(%ebp),%eax
f01033fb:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f01033fd:	eb b9                	jmp    f01033b8 <strtol+0x76>

	if (endptr)
f01033ff:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0103403:	74 0d                	je     f0103412 <strtol+0xd0>
		*endptr = (char *) s;
f0103405:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103408:	89 0e                	mov    %ecx,(%esi)
f010340a:	eb 06                	jmp    f0103412 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f010340c:	85 db                	test   %ebx,%ebx
f010340e:	74 98                	je     f01033a8 <strtol+0x66>
f0103410:	eb 9e                	jmp    f01033b0 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f0103412:	89 c2                	mov    %eax,%edx
f0103414:	f7 da                	neg    %edx
f0103416:	85 ff                	test   %edi,%edi
f0103418:	0f 45 c2             	cmovne %edx,%eax
}
f010341b:	5b                   	pop    %ebx
f010341c:	5e                   	pop    %esi
f010341d:	5f                   	pop    %edi
f010341e:	5d                   	pop    %ebp
f010341f:	c3                   	ret    

f0103420 <__udivdi3>:
f0103420:	55                   	push   %ebp
f0103421:	57                   	push   %edi
f0103422:	56                   	push   %esi
f0103423:	53                   	push   %ebx
f0103424:	83 ec 1c             	sub    $0x1c,%esp
f0103427:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f010342b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f010342f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0103433:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0103437:	85 f6                	test   %esi,%esi
f0103439:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010343d:	89 ca                	mov    %ecx,%edx
f010343f:	89 f8                	mov    %edi,%eax
f0103441:	75 3d                	jne    f0103480 <__udivdi3+0x60>
f0103443:	39 cf                	cmp    %ecx,%edi
f0103445:	0f 87 c5 00 00 00    	ja     f0103510 <__udivdi3+0xf0>
f010344b:	85 ff                	test   %edi,%edi
f010344d:	89 fd                	mov    %edi,%ebp
f010344f:	75 0b                	jne    f010345c <__udivdi3+0x3c>
f0103451:	b8 01 00 00 00       	mov    $0x1,%eax
f0103456:	31 d2                	xor    %edx,%edx
f0103458:	f7 f7                	div    %edi
f010345a:	89 c5                	mov    %eax,%ebp
f010345c:	89 c8                	mov    %ecx,%eax
f010345e:	31 d2                	xor    %edx,%edx
f0103460:	f7 f5                	div    %ebp
f0103462:	89 c1                	mov    %eax,%ecx
f0103464:	89 d8                	mov    %ebx,%eax
f0103466:	89 cf                	mov    %ecx,%edi
f0103468:	f7 f5                	div    %ebp
f010346a:	89 c3                	mov    %eax,%ebx
f010346c:	89 d8                	mov    %ebx,%eax
f010346e:	89 fa                	mov    %edi,%edx
f0103470:	83 c4 1c             	add    $0x1c,%esp
f0103473:	5b                   	pop    %ebx
f0103474:	5e                   	pop    %esi
f0103475:	5f                   	pop    %edi
f0103476:	5d                   	pop    %ebp
f0103477:	c3                   	ret    
f0103478:	90                   	nop
f0103479:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103480:	39 ce                	cmp    %ecx,%esi
f0103482:	77 74                	ja     f01034f8 <__udivdi3+0xd8>
f0103484:	0f bd fe             	bsr    %esi,%edi
f0103487:	83 f7 1f             	xor    $0x1f,%edi
f010348a:	0f 84 98 00 00 00    	je     f0103528 <__udivdi3+0x108>
f0103490:	bb 20 00 00 00       	mov    $0x20,%ebx
f0103495:	89 f9                	mov    %edi,%ecx
f0103497:	89 c5                	mov    %eax,%ebp
f0103499:	29 fb                	sub    %edi,%ebx
f010349b:	d3 e6                	shl    %cl,%esi
f010349d:	89 d9                	mov    %ebx,%ecx
f010349f:	d3 ed                	shr    %cl,%ebp
f01034a1:	89 f9                	mov    %edi,%ecx
f01034a3:	d3 e0                	shl    %cl,%eax
f01034a5:	09 ee                	or     %ebp,%esi
f01034a7:	89 d9                	mov    %ebx,%ecx
f01034a9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01034ad:	89 d5                	mov    %edx,%ebp
f01034af:	8b 44 24 08          	mov    0x8(%esp),%eax
f01034b3:	d3 ed                	shr    %cl,%ebp
f01034b5:	89 f9                	mov    %edi,%ecx
f01034b7:	d3 e2                	shl    %cl,%edx
f01034b9:	89 d9                	mov    %ebx,%ecx
f01034bb:	d3 e8                	shr    %cl,%eax
f01034bd:	09 c2                	or     %eax,%edx
f01034bf:	89 d0                	mov    %edx,%eax
f01034c1:	89 ea                	mov    %ebp,%edx
f01034c3:	f7 f6                	div    %esi
f01034c5:	89 d5                	mov    %edx,%ebp
f01034c7:	89 c3                	mov    %eax,%ebx
f01034c9:	f7 64 24 0c          	mull   0xc(%esp)
f01034cd:	39 d5                	cmp    %edx,%ebp
f01034cf:	72 10                	jb     f01034e1 <__udivdi3+0xc1>
f01034d1:	8b 74 24 08          	mov    0x8(%esp),%esi
f01034d5:	89 f9                	mov    %edi,%ecx
f01034d7:	d3 e6                	shl    %cl,%esi
f01034d9:	39 c6                	cmp    %eax,%esi
f01034db:	73 07                	jae    f01034e4 <__udivdi3+0xc4>
f01034dd:	39 d5                	cmp    %edx,%ebp
f01034df:	75 03                	jne    f01034e4 <__udivdi3+0xc4>
f01034e1:	83 eb 01             	sub    $0x1,%ebx
f01034e4:	31 ff                	xor    %edi,%edi
f01034e6:	89 d8                	mov    %ebx,%eax
f01034e8:	89 fa                	mov    %edi,%edx
f01034ea:	83 c4 1c             	add    $0x1c,%esp
f01034ed:	5b                   	pop    %ebx
f01034ee:	5e                   	pop    %esi
f01034ef:	5f                   	pop    %edi
f01034f0:	5d                   	pop    %ebp
f01034f1:	c3                   	ret    
f01034f2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01034f8:	31 ff                	xor    %edi,%edi
f01034fa:	31 db                	xor    %ebx,%ebx
f01034fc:	89 d8                	mov    %ebx,%eax
f01034fe:	89 fa                	mov    %edi,%edx
f0103500:	83 c4 1c             	add    $0x1c,%esp
f0103503:	5b                   	pop    %ebx
f0103504:	5e                   	pop    %esi
f0103505:	5f                   	pop    %edi
f0103506:	5d                   	pop    %ebp
f0103507:	c3                   	ret    
f0103508:	90                   	nop
f0103509:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103510:	89 d8                	mov    %ebx,%eax
f0103512:	f7 f7                	div    %edi
f0103514:	31 ff                	xor    %edi,%edi
f0103516:	89 c3                	mov    %eax,%ebx
f0103518:	89 d8                	mov    %ebx,%eax
f010351a:	89 fa                	mov    %edi,%edx
f010351c:	83 c4 1c             	add    $0x1c,%esp
f010351f:	5b                   	pop    %ebx
f0103520:	5e                   	pop    %esi
f0103521:	5f                   	pop    %edi
f0103522:	5d                   	pop    %ebp
f0103523:	c3                   	ret    
f0103524:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103528:	39 ce                	cmp    %ecx,%esi
f010352a:	72 0c                	jb     f0103538 <__udivdi3+0x118>
f010352c:	31 db                	xor    %ebx,%ebx
f010352e:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0103532:	0f 87 34 ff ff ff    	ja     f010346c <__udivdi3+0x4c>
f0103538:	bb 01 00 00 00       	mov    $0x1,%ebx
f010353d:	e9 2a ff ff ff       	jmp    f010346c <__udivdi3+0x4c>
f0103542:	66 90                	xchg   %ax,%ax
f0103544:	66 90                	xchg   %ax,%ax
f0103546:	66 90                	xchg   %ax,%ax
f0103548:	66 90                	xchg   %ax,%ax
f010354a:	66 90                	xchg   %ax,%ax
f010354c:	66 90                	xchg   %ax,%ax
f010354e:	66 90                	xchg   %ax,%ax

f0103550 <__umoddi3>:
f0103550:	55                   	push   %ebp
f0103551:	57                   	push   %edi
f0103552:	56                   	push   %esi
f0103553:	53                   	push   %ebx
f0103554:	83 ec 1c             	sub    $0x1c,%esp
f0103557:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010355b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010355f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0103563:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0103567:	85 d2                	test   %edx,%edx
f0103569:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010356d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103571:	89 f3                	mov    %esi,%ebx
f0103573:	89 3c 24             	mov    %edi,(%esp)
f0103576:	89 74 24 04          	mov    %esi,0x4(%esp)
f010357a:	75 1c                	jne    f0103598 <__umoddi3+0x48>
f010357c:	39 f7                	cmp    %esi,%edi
f010357e:	76 50                	jbe    f01035d0 <__umoddi3+0x80>
f0103580:	89 c8                	mov    %ecx,%eax
f0103582:	89 f2                	mov    %esi,%edx
f0103584:	f7 f7                	div    %edi
f0103586:	89 d0                	mov    %edx,%eax
f0103588:	31 d2                	xor    %edx,%edx
f010358a:	83 c4 1c             	add    $0x1c,%esp
f010358d:	5b                   	pop    %ebx
f010358e:	5e                   	pop    %esi
f010358f:	5f                   	pop    %edi
f0103590:	5d                   	pop    %ebp
f0103591:	c3                   	ret    
f0103592:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103598:	39 f2                	cmp    %esi,%edx
f010359a:	89 d0                	mov    %edx,%eax
f010359c:	77 52                	ja     f01035f0 <__umoddi3+0xa0>
f010359e:	0f bd ea             	bsr    %edx,%ebp
f01035a1:	83 f5 1f             	xor    $0x1f,%ebp
f01035a4:	75 5a                	jne    f0103600 <__umoddi3+0xb0>
f01035a6:	3b 54 24 04          	cmp    0x4(%esp),%edx
f01035aa:	0f 82 e0 00 00 00    	jb     f0103690 <__umoddi3+0x140>
f01035b0:	39 0c 24             	cmp    %ecx,(%esp)
f01035b3:	0f 86 d7 00 00 00    	jbe    f0103690 <__umoddi3+0x140>
f01035b9:	8b 44 24 08          	mov    0x8(%esp),%eax
f01035bd:	8b 54 24 04          	mov    0x4(%esp),%edx
f01035c1:	83 c4 1c             	add    $0x1c,%esp
f01035c4:	5b                   	pop    %ebx
f01035c5:	5e                   	pop    %esi
f01035c6:	5f                   	pop    %edi
f01035c7:	5d                   	pop    %ebp
f01035c8:	c3                   	ret    
f01035c9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01035d0:	85 ff                	test   %edi,%edi
f01035d2:	89 fd                	mov    %edi,%ebp
f01035d4:	75 0b                	jne    f01035e1 <__umoddi3+0x91>
f01035d6:	b8 01 00 00 00       	mov    $0x1,%eax
f01035db:	31 d2                	xor    %edx,%edx
f01035dd:	f7 f7                	div    %edi
f01035df:	89 c5                	mov    %eax,%ebp
f01035e1:	89 f0                	mov    %esi,%eax
f01035e3:	31 d2                	xor    %edx,%edx
f01035e5:	f7 f5                	div    %ebp
f01035e7:	89 c8                	mov    %ecx,%eax
f01035e9:	f7 f5                	div    %ebp
f01035eb:	89 d0                	mov    %edx,%eax
f01035ed:	eb 99                	jmp    f0103588 <__umoddi3+0x38>
f01035ef:	90                   	nop
f01035f0:	89 c8                	mov    %ecx,%eax
f01035f2:	89 f2                	mov    %esi,%edx
f01035f4:	83 c4 1c             	add    $0x1c,%esp
f01035f7:	5b                   	pop    %ebx
f01035f8:	5e                   	pop    %esi
f01035f9:	5f                   	pop    %edi
f01035fa:	5d                   	pop    %ebp
f01035fb:	c3                   	ret    
f01035fc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103600:	8b 34 24             	mov    (%esp),%esi
f0103603:	bf 20 00 00 00       	mov    $0x20,%edi
f0103608:	89 e9                	mov    %ebp,%ecx
f010360a:	29 ef                	sub    %ebp,%edi
f010360c:	d3 e0                	shl    %cl,%eax
f010360e:	89 f9                	mov    %edi,%ecx
f0103610:	89 f2                	mov    %esi,%edx
f0103612:	d3 ea                	shr    %cl,%edx
f0103614:	89 e9                	mov    %ebp,%ecx
f0103616:	09 c2                	or     %eax,%edx
f0103618:	89 d8                	mov    %ebx,%eax
f010361a:	89 14 24             	mov    %edx,(%esp)
f010361d:	89 f2                	mov    %esi,%edx
f010361f:	d3 e2                	shl    %cl,%edx
f0103621:	89 f9                	mov    %edi,%ecx
f0103623:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103627:	8b 54 24 0c          	mov    0xc(%esp),%edx
f010362b:	d3 e8                	shr    %cl,%eax
f010362d:	89 e9                	mov    %ebp,%ecx
f010362f:	89 c6                	mov    %eax,%esi
f0103631:	d3 e3                	shl    %cl,%ebx
f0103633:	89 f9                	mov    %edi,%ecx
f0103635:	89 d0                	mov    %edx,%eax
f0103637:	d3 e8                	shr    %cl,%eax
f0103639:	89 e9                	mov    %ebp,%ecx
f010363b:	09 d8                	or     %ebx,%eax
f010363d:	89 d3                	mov    %edx,%ebx
f010363f:	89 f2                	mov    %esi,%edx
f0103641:	f7 34 24             	divl   (%esp)
f0103644:	89 d6                	mov    %edx,%esi
f0103646:	d3 e3                	shl    %cl,%ebx
f0103648:	f7 64 24 04          	mull   0x4(%esp)
f010364c:	39 d6                	cmp    %edx,%esi
f010364e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0103652:	89 d1                	mov    %edx,%ecx
f0103654:	89 c3                	mov    %eax,%ebx
f0103656:	72 08                	jb     f0103660 <__umoddi3+0x110>
f0103658:	75 11                	jne    f010366b <__umoddi3+0x11b>
f010365a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f010365e:	73 0b                	jae    f010366b <__umoddi3+0x11b>
f0103660:	2b 44 24 04          	sub    0x4(%esp),%eax
f0103664:	1b 14 24             	sbb    (%esp),%edx
f0103667:	89 d1                	mov    %edx,%ecx
f0103669:	89 c3                	mov    %eax,%ebx
f010366b:	8b 54 24 08          	mov    0x8(%esp),%edx
f010366f:	29 da                	sub    %ebx,%edx
f0103671:	19 ce                	sbb    %ecx,%esi
f0103673:	89 f9                	mov    %edi,%ecx
f0103675:	89 f0                	mov    %esi,%eax
f0103677:	d3 e0                	shl    %cl,%eax
f0103679:	89 e9                	mov    %ebp,%ecx
f010367b:	d3 ea                	shr    %cl,%edx
f010367d:	89 e9                	mov    %ebp,%ecx
f010367f:	d3 ee                	shr    %cl,%esi
f0103681:	09 d0                	or     %edx,%eax
f0103683:	89 f2                	mov    %esi,%edx
f0103685:	83 c4 1c             	add    $0x1c,%esp
f0103688:	5b                   	pop    %ebx
f0103689:	5e                   	pop    %esi
f010368a:	5f                   	pop    %edi
f010368b:	5d                   	pop    %ebp
f010368c:	c3                   	ret    
f010368d:	8d 76 00             	lea    0x0(%esi),%esi
f0103690:	29 f9                	sub    %edi,%ecx
f0103692:	19 d6                	sbb    %edx,%esi
f0103694:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103698:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010369c:	e9 18 ff ff ff       	jmp    f01035b9 <__umoddi3+0x69>

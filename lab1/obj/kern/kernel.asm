
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
f0100058:	e8 c5 31 00 00       	call   f0103222 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 96 04 00 00       	call   f01004f8 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 c0 36 10 f0       	push   $0xf01036c0
f010006f:	e8 f5 26 00 00       	call   f0102769 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 47 10 00 00       	call   f01010c0 <mem_init>
f0100079:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f010007c:	83 ec 0c             	sub    $0xc,%esp
f010007f:	6a 00                	push   $0x0
f0100081:	e8 25 07 00 00       	call   f01007ab <monitor>
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
f01000b5:	e8 af 26 00 00       	call   f0102769 <cprintf>
	vcprintf(fmt, ap);
f01000ba:	83 c4 08             	add    $0x8,%esp
f01000bd:	53                   	push   %ebx
f01000be:	56                   	push   %esi
f01000bf:	e8 7f 26 00 00       	call   f0102743 <vcprintf>
	cprintf("\n");
f01000c4:	c7 04 24 31 46 10 f0 	movl   $0xf0104631,(%esp)
f01000cb:	e8 99 26 00 00       	call   f0102769 <cprintf>
	va_end(ap);
f01000d0:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000d3:	83 ec 0c             	sub    $0xc,%esp
f01000d6:	6a 00                	push   $0x0
f01000d8:	e8 ce 06 00 00       	call   f01007ab <monitor>
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
f01000f7:	e8 6d 26 00 00       	call   f0102769 <cprintf>
	vcprintf(fmt, ap);
f01000fc:	83 c4 08             	add    $0x8,%esp
f01000ff:	53                   	push   %ebx
f0100100:	ff 75 10             	pushl  0x10(%ebp)
f0100103:	e8 3b 26 00 00       	call   f0102743 <vcprintf>
	cprintf("\n");
f0100108:	c7 04 24 31 46 10 f0 	movl   $0xf0104631,(%esp)
f010010f:	e8 55 26 00 00       	call   f0102769 <cprintf>
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
f010026d:	e8 f7 24 00 00       	call   f0102769 <cprintf>
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
	if (crt_pos >= CRT_SIZE) {
f01003fc:	66 81 3d 28 65 11 f0 	cmpw   $0x7cf,0xf0116528
f0100403:	cf 07 
f0100405:	76 43                	jbe    f010044a <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100407:	a1 2c 65 11 f0       	mov    0xf011652c,%eax
f010040c:	83 ec 04             	sub    $0x4,%esp
f010040f:	68 00 0f 00 00       	push   $0xf00
f0100414:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010041a:	52                   	push   %edx
f010041b:	50                   	push   %eax
f010041c:	e8 4e 2e 00 00       	call   f010326f <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100421:	8b 15 2c 65 11 f0    	mov    0xf011652c,%edx
f0100427:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f010042d:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f0100433:	83 c4 10             	add    $0x10,%esp
f0100436:	66 c7 00 20 07       	movw   $0x720,(%eax)
f010043b:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
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
f01005f0:	e8 74 21 00 00       	call   f0102769 <cprintf>
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
f0100640:	e8 24 21 00 00       	call   f0102769 <cprintf>
f0100645:	83 c4 0c             	add    $0xc,%esp
f0100648:	68 30 3a 10 f0       	push   $0xf0103a30
f010064d:	68 8c 39 10 f0       	push   $0xf010398c
f0100652:	68 83 39 10 f0       	push   $0xf0103983
f0100657:	e8 0d 21 00 00       	call   f0102769 <cprintf>
f010065c:	83 c4 0c             	add    $0xc,%esp
f010065f:	68 95 39 10 f0       	push   $0xf0103995
f0100664:	68 ac 39 10 f0       	push   $0xf01039ac
f0100669:	68 83 39 10 f0       	push   $0xf0103983
f010066e:	e8 f6 20 00 00       	call   f0102769 <cprintf>
	return 0;
}
f0100673:	b8 00 00 00 00       	mov    $0x0,%eax
f0100678:	c9                   	leave  
f0100679:	c3                   	ret    

f010067a <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f010067a:	55                   	push   %ebp
f010067b:	89 e5                	mov    %esp,%ebp
f010067d:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100680:	68 b6 39 10 f0       	push   $0xf01039b6
f0100685:	e8 df 20 00 00       	call   f0102769 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f010068a:	83 c4 08             	add    $0x8,%esp
f010068d:	68 0c 00 10 00       	push   $0x10000c
f0100692:	68 58 3a 10 f0       	push   $0xf0103a58
f0100697:	e8 cd 20 00 00       	call   f0102769 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f010069c:	83 c4 0c             	add    $0xc,%esp
f010069f:	68 0c 00 10 00       	push   $0x10000c
f01006a4:	68 0c 00 10 f0       	push   $0xf010000c
f01006a9:	68 80 3a 10 f0       	push   $0xf0103a80
f01006ae:	e8 b6 20 00 00       	call   f0102769 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006b3:	83 c4 0c             	add    $0xc,%esp
f01006b6:	68 b1 36 10 00       	push   $0x1036b1
f01006bb:	68 b1 36 10 f0       	push   $0xf01036b1
f01006c0:	68 a4 3a 10 f0       	push   $0xf0103aa4
f01006c5:	e8 9f 20 00 00       	call   f0102769 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006ca:	83 c4 0c             	add    $0xc,%esp
f01006cd:	68 00 63 11 00       	push   $0x116300
f01006d2:	68 00 63 11 f0       	push   $0xf0116300
f01006d7:	68 c8 3a 10 f0       	push   $0xf0103ac8
f01006dc:	e8 88 20 00 00       	call   f0102769 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006e1:	83 c4 0c             	add    $0xc,%esp
f01006e4:	68 60 69 11 00       	push   $0x116960
f01006e9:	68 60 69 11 f0       	push   $0xf0116960
f01006ee:	68 ec 3a 10 f0       	push   $0xf0103aec
f01006f3:	e8 71 20 00 00       	call   f0102769 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f01006f8:	b8 5f 6d 11 f0       	mov    $0xf0116d5f,%eax
f01006fd:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100702:	83 c4 08             	add    $0x8,%esp
f0100705:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f010070a:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100710:	85 c0                	test   %eax,%eax
f0100712:	0f 48 c2             	cmovs  %edx,%eax
f0100715:	c1 f8 0a             	sar    $0xa,%eax
f0100718:	50                   	push   %eax
f0100719:	68 10 3b 10 f0       	push   $0xf0103b10
f010071e:	e8 46 20 00 00       	call   f0102769 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100723:	b8 00 00 00 00       	mov    $0x0,%eax
f0100728:	c9                   	leave  
f0100729:	c3                   	ret    

f010072a <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f010072a:	55                   	push   %ebp
f010072b:	89 e5                	mov    %esp,%ebp
f010072d:	56                   	push   %esi
f010072e:	53                   	push   %ebx
f010072f:	83 ec 2c             	sub    $0x2c,%esp

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f0100732:	89 eb                	mov    %ebp,%ebx
		ebp f0109ed8  eip f01000d6  args 00000000 00000000 f0100058 f0109f28 00000061
  ...
	*/
	uint32_t ebp=read_ebp(); // current func's start 
	struct Eipdebuginfo info;
	cprintf("Stack backtrace:\n");
f0100734:	68 cf 39 10 f0       	push   $0xf01039cf
f0100739:	e8 2b 20 00 00       	call   f0102769 <cprintf>
	while (ebp != 0) {
f010073e:	83 c4 10             	add    $0x10,%esp
		cprintf("  ebp %08x  eip %08x  args %08x %08x %08x %08x %08x\n", ebp, *((uint32_t*)ebp+1),\
		*((uint32_t*)ebp+2),*((uint32_t*)ebp+3),*((uint32_t*)ebp+4), *((uint32_t*)ebp+5), *((uint32_t*)ebp+6));
		
		if (debuginfo_eip(*((uint32_t*)ebp+1), &info) == 0) {
f0100741:	8d 75 e0             	lea    -0x20(%ebp),%esi
  ...
	*/
	uint32_t ebp=read_ebp(); // current func's start 
	struct Eipdebuginfo info;
	cprintf("Stack backtrace:\n");
	while (ebp != 0) {
f0100744:	eb 55                	jmp    f010079b <mon_backtrace+0x71>
		cprintf("  ebp %08x  eip %08x  args %08x %08x %08x %08x %08x\n", ebp, *((uint32_t*)ebp+1),\
f0100746:	ff 73 18             	pushl  0x18(%ebx)
f0100749:	ff 73 14             	pushl  0x14(%ebx)
f010074c:	ff 73 10             	pushl  0x10(%ebx)
f010074f:	ff 73 0c             	pushl  0xc(%ebx)
f0100752:	ff 73 08             	pushl  0x8(%ebx)
f0100755:	ff 73 04             	pushl  0x4(%ebx)
f0100758:	53                   	push   %ebx
f0100759:	68 3c 3b 10 f0       	push   $0xf0103b3c
f010075e:	e8 06 20 00 00       	call   f0102769 <cprintf>
		*((uint32_t*)ebp+2),*((uint32_t*)ebp+3),*((uint32_t*)ebp+4), *((uint32_t*)ebp+5), *((uint32_t*)ebp+6));
		
		if (debuginfo_eip(*((uint32_t*)ebp+1), &info) == 0) {
f0100763:	83 c4 18             	add    $0x18,%esp
f0100766:	56                   	push   %esi
f0100767:	ff 73 04             	pushl  0x4(%ebx)
f010076a:	e8 04 21 00 00       	call   f0102873 <debuginfo_eip>
f010076f:	83 c4 10             	add    $0x10,%esp
f0100772:	85 c0                	test   %eax,%eax
f0100774:	75 23                	jne    f0100799 <mon_backtrace+0x6f>
            uint32_t fn_offset = *((uint32_t*)ebp+1) - info.eip_fn_addr;
            cprintf("\t\t %s:%d: %.*s+%d\n", info.eip_file, info.eip_line,info.eip_fn_namelen,  info.eip_fn_name, fn_offset);
f0100776:	83 ec 08             	sub    $0x8,%esp
f0100779:	8b 43 04             	mov    0x4(%ebx),%eax
f010077c:	2b 45 f0             	sub    -0x10(%ebp),%eax
f010077f:	50                   	push   %eax
f0100780:	ff 75 e8             	pushl  -0x18(%ebp)
f0100783:	ff 75 ec             	pushl  -0x14(%ebp)
f0100786:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100789:	ff 75 e0             	pushl  -0x20(%ebp)
f010078c:	68 e1 39 10 f0       	push   $0xf01039e1
f0100791:	e8 d3 1f 00 00       	call   f0102769 <cprintf>
f0100796:	83 c4 20             	add    $0x20,%esp
        }
		ebp = *(uint32_t*)ebp;
f0100799:	8b 1b                	mov    (%ebx),%ebx
  ...
	*/
	uint32_t ebp=read_ebp(); // current func's start 
	struct Eipdebuginfo info;
	cprintf("Stack backtrace:\n");
	while (ebp != 0) {
f010079b:	85 db                	test   %ebx,%ebx
f010079d:	75 a7                	jne    f0100746 <mon_backtrace+0x1c>
        }
		ebp = *(uint32_t*)ebp;
	}

	return 0;
}
f010079f:	b8 00 00 00 00       	mov    $0x0,%eax
f01007a4:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01007a7:	5b                   	pop    %ebx
f01007a8:	5e                   	pop    %esi
f01007a9:	5d                   	pop    %ebp
f01007aa:	c3                   	ret    

f01007ab <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01007ab:	55                   	push   %ebp
f01007ac:	89 e5                	mov    %esp,%ebp
f01007ae:	57                   	push   %edi
f01007af:	56                   	push   %esi
f01007b0:	53                   	push   %ebx
f01007b1:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01007b4:	68 74 3b 10 f0       	push   $0xf0103b74
f01007b9:	e8 ab 1f 00 00       	call   f0102769 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007be:	c7 04 24 98 3b 10 f0 	movl   $0xf0103b98,(%esp)
f01007c5:	e8 9f 1f 00 00       	call   f0102769 <cprintf>
f01007ca:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f01007cd:	83 ec 0c             	sub    $0xc,%esp
f01007d0:	68 f4 39 10 f0       	push   $0xf01039f4
f01007d5:	e8 f1 27 00 00       	call   f0102fcb <readline>
f01007da:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f01007dc:	83 c4 10             	add    $0x10,%esp
f01007df:	85 c0                	test   %eax,%eax
f01007e1:	74 ea                	je     f01007cd <monitor+0x22>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f01007e3:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f01007ea:	be 00 00 00 00       	mov    $0x0,%esi
f01007ef:	eb 0a                	jmp    f01007fb <monitor+0x50>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f01007f1:	c6 03 00             	movb   $0x0,(%ebx)
f01007f4:	89 f7                	mov    %esi,%edi
f01007f6:	8d 5b 01             	lea    0x1(%ebx),%ebx
f01007f9:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f01007fb:	0f b6 03             	movzbl (%ebx),%eax
f01007fe:	84 c0                	test   %al,%al
f0100800:	74 63                	je     f0100865 <monitor+0xba>
f0100802:	83 ec 08             	sub    $0x8,%esp
f0100805:	0f be c0             	movsbl %al,%eax
f0100808:	50                   	push   %eax
f0100809:	68 f8 39 10 f0       	push   $0xf01039f8
f010080e:	e8 d2 29 00 00       	call   f01031e5 <strchr>
f0100813:	83 c4 10             	add    $0x10,%esp
f0100816:	85 c0                	test   %eax,%eax
f0100818:	75 d7                	jne    f01007f1 <monitor+0x46>
			*buf++ = 0;
		if (*buf == 0)
f010081a:	80 3b 00             	cmpb   $0x0,(%ebx)
f010081d:	74 46                	je     f0100865 <monitor+0xba>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f010081f:	83 fe 0f             	cmp    $0xf,%esi
f0100822:	75 14                	jne    f0100838 <monitor+0x8d>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100824:	83 ec 08             	sub    $0x8,%esp
f0100827:	6a 10                	push   $0x10
f0100829:	68 fd 39 10 f0       	push   $0xf01039fd
f010082e:	e8 36 1f 00 00       	call   f0102769 <cprintf>
f0100833:	83 c4 10             	add    $0x10,%esp
f0100836:	eb 95                	jmp    f01007cd <monitor+0x22>
			return 0;
		}
		argv[argc++] = buf;
f0100838:	8d 7e 01             	lea    0x1(%esi),%edi
f010083b:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f010083f:	eb 03                	jmp    f0100844 <monitor+0x99>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f0100841:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100844:	0f b6 03             	movzbl (%ebx),%eax
f0100847:	84 c0                	test   %al,%al
f0100849:	74 ae                	je     f01007f9 <monitor+0x4e>
f010084b:	83 ec 08             	sub    $0x8,%esp
f010084e:	0f be c0             	movsbl %al,%eax
f0100851:	50                   	push   %eax
f0100852:	68 f8 39 10 f0       	push   $0xf01039f8
f0100857:	e8 89 29 00 00       	call   f01031e5 <strchr>
f010085c:	83 c4 10             	add    $0x10,%esp
f010085f:	85 c0                	test   %eax,%eax
f0100861:	74 de                	je     f0100841 <monitor+0x96>
f0100863:	eb 94                	jmp    f01007f9 <monitor+0x4e>
			buf++;
	}
	argv[argc] = 0;
f0100865:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f010086c:	00 

	// Lookup and invoke the command
	if (argc == 0)
f010086d:	85 f6                	test   %esi,%esi
f010086f:	0f 84 58 ff ff ff    	je     f01007cd <monitor+0x22>
f0100875:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f010087a:	83 ec 08             	sub    $0x8,%esp
f010087d:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100880:	ff 34 85 c0 3b 10 f0 	pushl  -0xfefc440(,%eax,4)
f0100887:	ff 75 a8             	pushl  -0x58(%ebp)
f010088a:	e8 f8 28 00 00       	call   f0103187 <strcmp>
f010088f:	83 c4 10             	add    $0x10,%esp
f0100892:	85 c0                	test   %eax,%eax
f0100894:	75 21                	jne    f01008b7 <monitor+0x10c>
			return commands[i].func(argc, argv, tf);
f0100896:	83 ec 04             	sub    $0x4,%esp
f0100899:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f010089c:	ff 75 08             	pushl  0x8(%ebp)
f010089f:	8d 55 a8             	lea    -0x58(%ebp),%edx
f01008a2:	52                   	push   %edx
f01008a3:	56                   	push   %esi
f01008a4:	ff 14 85 c8 3b 10 f0 	call   *-0xfefc438(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f01008ab:	83 c4 10             	add    $0x10,%esp
f01008ae:	85 c0                	test   %eax,%eax
f01008b0:	78 25                	js     f01008d7 <monitor+0x12c>
f01008b2:	e9 16 ff ff ff       	jmp    f01007cd <monitor+0x22>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f01008b7:	83 c3 01             	add    $0x1,%ebx
f01008ba:	83 fb 03             	cmp    $0x3,%ebx
f01008bd:	75 bb                	jne    f010087a <monitor+0xcf>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f01008bf:	83 ec 08             	sub    $0x8,%esp
f01008c2:	ff 75 a8             	pushl  -0x58(%ebp)
f01008c5:	68 1a 3a 10 f0       	push   $0xf0103a1a
f01008ca:	e8 9a 1e 00 00       	call   f0102769 <cprintf>
f01008cf:	83 c4 10             	add    $0x10,%esp
f01008d2:	e9 f6 fe ff ff       	jmp    f01007cd <monitor+0x22>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f01008d7:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01008da:	5b                   	pop    %ebx
f01008db:	5e                   	pop    %esi
f01008dc:	5f                   	pop    %edi
f01008dd:	5d                   	pop    %ebp
f01008de:	c3                   	ret    

f01008df <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f01008df:	55                   	push   %ebp
f01008e0:	89 e5                	mov    %esp,%ebp
f01008e2:	89 c2                	mov    %eax,%edx
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f01008e4:	83 3d 38 65 11 f0 00 	cmpl   $0x0,0xf0116538
f01008eb:	75 0f                	jne    f01008fc <boot_alloc+0x1d>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f01008ed:	b8 5f 79 11 f0       	mov    $0xf011795f,%eax
f01008f2:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01008f7:	a3 38 65 11 f0       	mov    %eax,0xf0116538
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	result = nextfree;
f01008fc:	a1 38 65 11 f0       	mov    0xf0116538,%eax
	if (n > 0) {
f0100901:	85 d2                	test   %edx,%edx
f0100903:	74 14                	je     f0100919 <boot_alloc+0x3a>
		nextfree += ROUNDUP(n, PGSIZE);
f0100905:	81 c2 ff 0f 00 00    	add    $0xfff,%edx
f010090b:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100911:	01 c2                	add    %eax,%edx
f0100913:	89 15 38 65 11 f0    	mov    %edx,0xf0116538
	}

	return result;
}
f0100919:	5d                   	pop    %ebp
f010091a:	c3                   	ret    

f010091b <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f010091b:	55                   	push   %ebp
f010091c:	89 e5                	mov    %esp,%ebp
f010091e:	56                   	push   %esi
f010091f:	53                   	push   %ebx
f0100920:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100922:	83 ec 0c             	sub    $0xc,%esp
f0100925:	50                   	push   %eax
f0100926:	e8 d7 1d 00 00       	call   f0102702 <mc146818_read>
f010092b:	89 c6                	mov    %eax,%esi
f010092d:	83 c3 01             	add    $0x1,%ebx
f0100930:	89 1c 24             	mov    %ebx,(%esp)
f0100933:	e8 ca 1d 00 00       	call   f0102702 <mc146818_read>
f0100938:	c1 e0 08             	shl    $0x8,%eax
f010093b:	09 f0                	or     %esi,%eax
}
f010093d:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100940:	5b                   	pop    %ebx
f0100941:	5e                   	pop    %esi
f0100942:	5d                   	pop    %ebp
f0100943:	c3                   	ret    

f0100944 <check_va2pa>:
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f0100944:	89 d1                	mov    %edx,%ecx
f0100946:	c1 e9 16             	shr    $0x16,%ecx
f0100949:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f010094c:	a8 01                	test   $0x1,%al
f010094e:	74 52                	je     f01009a2 <check_va2pa+0x5e>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100950:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100955:	89 c1                	mov    %eax,%ecx
f0100957:	c1 e9 0c             	shr    $0xc,%ecx
f010095a:	3b 0d 68 69 11 f0    	cmp    0xf0116968,%ecx
f0100960:	72 1b                	jb     f010097d <check_va2pa+0x39>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100962:	55                   	push   %ebp
f0100963:	89 e5                	mov    %esp,%ebp
f0100965:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100968:	50                   	push   %eax
f0100969:	68 e4 3b 10 f0       	push   $0xf0103be4
f010096e:	68 eb 02 00 00       	push   $0x2eb
f0100973:	68 80 43 10 f0       	push   $0xf0104380
f0100978:	e8 0e f7 ff ff       	call   f010008b <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f010097d:	c1 ea 0c             	shr    $0xc,%edx
f0100980:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100986:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f010098d:	89 c2                	mov    %eax,%edx
f010098f:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100992:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100997:	85 d2                	test   %edx,%edx
f0100999:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f010099e:	0f 44 c2             	cmove  %edx,%eax
f01009a1:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f01009a2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f01009a7:	c3                   	ret    

f01009a8 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f01009a8:	55                   	push   %ebp
f01009a9:	89 e5                	mov    %esp,%ebp
f01009ab:	57                   	push   %edi
f01009ac:	56                   	push   %esi
f01009ad:	53                   	push   %ebx
f01009ae:	83 ec 2c             	sub    $0x2c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f01009b1:	84 c0                	test   %al,%al
f01009b3:	0f 85 81 02 00 00    	jne    f0100c3a <check_page_free_list+0x292>
f01009b9:	e9 8e 02 00 00       	jmp    f0100c4c <check_page_free_list+0x2a4>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f01009be:	83 ec 04             	sub    $0x4,%esp
f01009c1:	68 08 3c 10 f0       	push   $0xf0103c08
f01009c6:	68 2c 02 00 00       	push   $0x22c
f01009cb:	68 80 43 10 f0       	push   $0xf0104380
f01009d0:	e8 b6 f6 ff ff       	call   f010008b <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f01009d5:	8d 55 d8             	lea    -0x28(%ebp),%edx
f01009d8:	89 55 e0             	mov    %edx,-0x20(%ebp)
f01009db:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01009de:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f01009e1:	89 c2                	mov    %eax,%edx
f01009e3:	2b 15 70 69 11 f0    	sub    0xf0116970,%edx
f01009e9:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f01009ef:	0f 95 c2             	setne  %dl
f01009f2:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f01009f5:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f01009f9:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f01009fb:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f01009ff:	8b 00                	mov    (%eax),%eax
f0100a01:	85 c0                	test   %eax,%eax
f0100a03:	75 dc                	jne    f01009e1 <check_page_free_list+0x39>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100a05:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a08:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100a0e:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100a11:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100a14:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100a16:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100a19:	a3 3c 65 11 f0       	mov    %eax,0xf011653c
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100a1e:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100a23:	8b 1d 3c 65 11 f0    	mov    0xf011653c,%ebx
f0100a29:	eb 53                	jmp    f0100a7e <check_page_free_list+0xd6>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100a2b:	89 d8                	mov    %ebx,%eax
f0100a2d:	2b 05 70 69 11 f0    	sub    0xf0116970,%eax
f0100a33:	c1 f8 03             	sar    $0x3,%eax
f0100a36:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100a39:	89 c2                	mov    %eax,%edx
f0100a3b:	c1 ea 16             	shr    $0x16,%edx
f0100a3e:	39 f2                	cmp    %esi,%edx
f0100a40:	73 3a                	jae    f0100a7c <check_page_free_list+0xd4>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100a42:	89 c2                	mov    %eax,%edx
f0100a44:	c1 ea 0c             	shr    $0xc,%edx
f0100a47:	3b 15 68 69 11 f0    	cmp    0xf0116968,%edx
f0100a4d:	72 12                	jb     f0100a61 <check_page_free_list+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100a4f:	50                   	push   %eax
f0100a50:	68 e4 3b 10 f0       	push   $0xf0103be4
f0100a55:	6a 53                	push   $0x53
f0100a57:	68 8c 43 10 f0       	push   $0xf010438c
f0100a5c:	e8 2a f6 ff ff       	call   f010008b <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100a61:	83 ec 04             	sub    $0x4,%esp
f0100a64:	68 80 00 00 00       	push   $0x80
f0100a69:	68 97 00 00 00       	push   $0x97
f0100a6e:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100a73:	50                   	push   %eax
f0100a74:	e8 a9 27 00 00       	call   f0103222 <memset>
f0100a79:	83 c4 10             	add    $0x10,%esp
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100a7c:	8b 1b                	mov    (%ebx),%ebx
f0100a7e:	85 db                	test   %ebx,%ebx
f0100a80:	75 a9                	jne    f0100a2b <check_page_free_list+0x83>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100a82:	b8 00 00 00 00       	mov    $0x0,%eax
f0100a87:	e8 53 fe ff ff       	call   f01008df <boot_alloc>
f0100a8c:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100a8f:	8b 15 3c 65 11 f0    	mov    0xf011653c,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100a95:	8b 0d 70 69 11 f0    	mov    0xf0116970,%ecx
		assert(pp < pages + npages);
f0100a9b:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f0100aa0:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100aa3:	8d 3c c1             	lea    (%ecx,%eax,8),%edi
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100aa6:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100aa9:	be 00 00 00 00       	mov    $0x0,%esi
f0100aae:	89 5d d0             	mov    %ebx,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100ab1:	e9 30 01 00 00       	jmp    f0100be6 <check_page_free_list+0x23e>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100ab6:	39 ca                	cmp    %ecx,%edx
f0100ab8:	73 19                	jae    f0100ad3 <check_page_free_list+0x12b>
f0100aba:	68 9a 43 10 f0       	push   $0xf010439a
f0100abf:	68 a6 43 10 f0       	push   $0xf01043a6
f0100ac4:	68 46 02 00 00       	push   $0x246
f0100ac9:	68 80 43 10 f0       	push   $0xf0104380
f0100ace:	e8 b8 f5 ff ff       	call   f010008b <_panic>
		assert(pp < pages + npages);
f0100ad3:	39 fa                	cmp    %edi,%edx
f0100ad5:	72 19                	jb     f0100af0 <check_page_free_list+0x148>
f0100ad7:	68 bb 43 10 f0       	push   $0xf01043bb
f0100adc:	68 a6 43 10 f0       	push   $0xf01043a6
f0100ae1:	68 47 02 00 00       	push   $0x247
f0100ae6:	68 80 43 10 f0       	push   $0xf0104380
f0100aeb:	e8 9b f5 ff ff       	call   f010008b <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100af0:	89 d0                	mov    %edx,%eax
f0100af2:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100af5:	a8 07                	test   $0x7,%al
f0100af7:	74 19                	je     f0100b12 <check_page_free_list+0x16a>
f0100af9:	68 2c 3c 10 f0       	push   $0xf0103c2c
f0100afe:	68 a6 43 10 f0       	push   $0xf01043a6
f0100b03:	68 48 02 00 00       	push   $0x248
f0100b08:	68 80 43 10 f0       	push   $0xf0104380
f0100b0d:	e8 79 f5 ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100b12:	c1 f8 03             	sar    $0x3,%eax
f0100b15:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100b18:	85 c0                	test   %eax,%eax
f0100b1a:	75 19                	jne    f0100b35 <check_page_free_list+0x18d>
f0100b1c:	68 cf 43 10 f0       	push   $0xf01043cf
f0100b21:	68 a6 43 10 f0       	push   $0xf01043a6
f0100b26:	68 4b 02 00 00       	push   $0x24b
f0100b2b:	68 80 43 10 f0       	push   $0xf0104380
f0100b30:	e8 56 f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100b35:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100b3a:	75 19                	jne    f0100b55 <check_page_free_list+0x1ad>
f0100b3c:	68 e0 43 10 f0       	push   $0xf01043e0
f0100b41:	68 a6 43 10 f0       	push   $0xf01043a6
f0100b46:	68 4c 02 00 00       	push   $0x24c
f0100b4b:	68 80 43 10 f0       	push   $0xf0104380
f0100b50:	e8 36 f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100b55:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100b5a:	75 19                	jne    f0100b75 <check_page_free_list+0x1cd>
f0100b5c:	68 60 3c 10 f0       	push   $0xf0103c60
f0100b61:	68 a6 43 10 f0       	push   $0xf01043a6
f0100b66:	68 4d 02 00 00       	push   $0x24d
f0100b6b:	68 80 43 10 f0       	push   $0xf0104380
f0100b70:	e8 16 f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100b75:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100b7a:	75 19                	jne    f0100b95 <check_page_free_list+0x1ed>
f0100b7c:	68 f9 43 10 f0       	push   $0xf01043f9
f0100b81:	68 a6 43 10 f0       	push   $0xf01043a6
f0100b86:	68 4e 02 00 00       	push   $0x24e
f0100b8b:	68 80 43 10 f0       	push   $0xf0104380
f0100b90:	e8 f6 f4 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100b95:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100b9a:	76 3f                	jbe    f0100bdb <check_page_free_list+0x233>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100b9c:	89 c3                	mov    %eax,%ebx
f0100b9e:	c1 eb 0c             	shr    $0xc,%ebx
f0100ba1:	39 5d c8             	cmp    %ebx,-0x38(%ebp)
f0100ba4:	77 12                	ja     f0100bb8 <check_page_free_list+0x210>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ba6:	50                   	push   %eax
f0100ba7:	68 e4 3b 10 f0       	push   $0xf0103be4
f0100bac:	6a 53                	push   $0x53
f0100bae:	68 8c 43 10 f0       	push   $0xf010438c
f0100bb3:	e8 d3 f4 ff ff       	call   f010008b <_panic>
f0100bb8:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100bbd:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100bc0:	76 1e                	jbe    f0100be0 <check_page_free_list+0x238>
f0100bc2:	68 84 3c 10 f0       	push   $0xf0103c84
f0100bc7:	68 a6 43 10 f0       	push   $0xf01043a6
f0100bcc:	68 4f 02 00 00       	push   $0x24f
f0100bd1:	68 80 43 10 f0       	push   $0xf0104380
f0100bd6:	e8 b0 f4 ff ff       	call   f010008b <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100bdb:	83 c6 01             	add    $0x1,%esi
f0100bde:	eb 04                	jmp    f0100be4 <check_page_free_list+0x23c>
		else
			++nfree_extmem;
f0100be0:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100be4:	8b 12                	mov    (%edx),%edx
f0100be6:	85 d2                	test   %edx,%edx
f0100be8:	0f 85 c8 fe ff ff    	jne    f0100ab6 <check_page_free_list+0x10e>
f0100bee:	8b 5d d0             	mov    -0x30(%ebp),%ebx
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100bf1:	85 f6                	test   %esi,%esi
f0100bf3:	7f 19                	jg     f0100c0e <check_page_free_list+0x266>
f0100bf5:	68 13 44 10 f0       	push   $0xf0104413
f0100bfa:	68 a6 43 10 f0       	push   $0xf01043a6
f0100bff:	68 57 02 00 00       	push   $0x257
f0100c04:	68 80 43 10 f0       	push   $0xf0104380
f0100c09:	e8 7d f4 ff ff       	call   f010008b <_panic>
	assert(nfree_extmem > 0);
f0100c0e:	85 db                	test   %ebx,%ebx
f0100c10:	7f 19                	jg     f0100c2b <check_page_free_list+0x283>
f0100c12:	68 25 44 10 f0       	push   $0xf0104425
f0100c17:	68 a6 43 10 f0       	push   $0xf01043a6
f0100c1c:	68 58 02 00 00       	push   $0x258
f0100c21:	68 80 43 10 f0       	push   $0xf0104380
f0100c26:	e8 60 f4 ff ff       	call   f010008b <_panic>

	cprintf("check_page_free_list() succeeded!\n");
f0100c2b:	83 ec 0c             	sub    $0xc,%esp
f0100c2e:	68 cc 3c 10 f0       	push   $0xf0103ccc
f0100c33:	e8 31 1b 00 00       	call   f0102769 <cprintf>
}
f0100c38:	eb 29                	jmp    f0100c63 <check_page_free_list+0x2bb>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100c3a:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f0100c3f:	85 c0                	test   %eax,%eax
f0100c41:	0f 85 8e fd ff ff    	jne    f01009d5 <check_page_free_list+0x2d>
f0100c47:	e9 72 fd ff ff       	jmp    f01009be <check_page_free_list+0x16>
f0100c4c:	83 3d 3c 65 11 f0 00 	cmpl   $0x0,0xf011653c
f0100c53:	0f 84 65 fd ff ff    	je     f01009be <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100c59:	be 00 04 00 00       	mov    $0x400,%esi
f0100c5e:	e9 c0 fd ff ff       	jmp    f0100a23 <check_page_free_list+0x7b>

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);

	cprintf("check_page_free_list() succeeded!\n");
}
f0100c63:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100c66:	5b                   	pop    %ebx
f0100c67:	5e                   	pop    %esi
f0100c68:	5f                   	pop    %edi
f0100c69:	5d                   	pop    %ebp
f0100c6a:	c3                   	ret    

f0100c6b <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100c6b:	55                   	push   %ebp
f0100c6c:	89 e5                	mov    %esp,%ebp
f0100c6e:	56                   	push   %esi
f0100c6f:	53                   	push   %ebx
	// The example code here marks all physical pages as free.
	// However this is not truly the case.  What memory is free?
	//  1) Mark physical page 0 as in use.
	size_t i;
	pages[0].pp_ref = 1;
f0100c70:	a1 70 69 11 f0       	mov    0xf0116970,%eax
f0100c75:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
	//     This way we preserve the real-mode IDT and BIOS structures
	//     in case we ever need them.  (Currently we don't, but...)
	//  2) The rest of base memory, [PGSIZE, npages_basemem * PGSIZE)
	//     is free.
	for (i = 1; i < npages_basemem; i++) {
f0100c7b:	8b 35 40 65 11 f0    	mov    0xf0116540,%esi
f0100c81:	8b 1d 3c 65 11 f0    	mov    0xf011653c,%ebx
f0100c87:	ba 00 00 00 00       	mov    $0x0,%edx
f0100c8c:	b8 01 00 00 00       	mov    $0x1,%eax
f0100c91:	eb 27                	jmp    f0100cba <page_init+0x4f>
		pages[i].pp_ref = 0;
f0100c93:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
f0100c9a:	89 d1                	mov    %edx,%ecx
f0100c9c:	03 0d 70 69 11 f0    	add    0xf0116970,%ecx
f0100ca2:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = page_free_list;
f0100ca8:	89 19                	mov    %ebx,(%ecx)
	pages[0].pp_ref = 1;
	//     This way we preserve the real-mode IDT and BIOS structures
	//     in case we ever need them.  (Currently we don't, but...)
	//  2) The rest of base memory, [PGSIZE, npages_basemem * PGSIZE)
	//     is free.
	for (i = 1; i < npages_basemem; i++) {
f0100caa:	83 c0 01             	add    $0x1,%eax
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
f0100cad:	89 d3                	mov    %edx,%ebx
f0100caf:	03 1d 70 69 11 f0    	add    0xf0116970,%ebx
f0100cb5:	ba 01 00 00 00       	mov    $0x1,%edx
	pages[0].pp_ref = 1;
	//     This way we preserve the real-mode IDT and BIOS structures
	//     in case we ever need them.  (Currently we don't, but...)
	//  2) The rest of base memory, [PGSIZE, npages_basemem * PGSIZE)
	//     is free.
	for (i = 1; i < npages_basemem; i++) {
f0100cba:	39 f0                	cmp    %esi,%eax
f0100cbc:	72 d5                	jb     f0100c93 <page_init+0x28>
f0100cbe:	84 d2                	test   %dl,%dl
f0100cc0:	74 06                	je     f0100cc8 <page_init+0x5d>
f0100cc2:	89 1d 3c 65 11 f0    	mov    %ebx,0xf011653c
		page_free_list = &pages[i];
	}
	//  3) Then comes the IO hole [IOPHYSMEM, EXTPHYSMEM), which must
	//     never be allocated.
	for (i = IOPHYSMEM / (PGSIZE); i < EXTPHYSMEM / (PGSIZE); i++)
		pages[i].pp_ref = 1;
f0100cc8:	8b 15 70 69 11 f0    	mov    0xf0116970,%edx
f0100cce:	8d 82 04 05 00 00    	lea    0x504(%edx),%eax
f0100cd4:	81 c2 04 08 00 00    	add    $0x804,%edx
f0100cda:	66 c7 00 01 00       	movw   $0x1,(%eax)
f0100cdf:	83 c0 08             	add    $0x8,%eax
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
	//  3) Then comes the IO hole [IOPHYSMEM, EXTPHYSMEM), which must
	//     never be allocated.
	for (i = IOPHYSMEM / (PGSIZE); i < EXTPHYSMEM / (PGSIZE); i++)
f0100ce2:	39 d0                	cmp    %edx,%eax
f0100ce4:	75 f4                	jne    f0100cda <page_init+0x6f>
	//  4) Then extended memory [EXTPHYSMEM, ...).
	//     Some of it is in use, some is free. Where is the kernel
	//     in physical memory?  Which pages are already in use for
	//     page tables and other data structures?
	//	up to kern.text 0x1000000
	size_t nextfree = PADDR(boot_alloc(0));
f0100ce6:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ceb:	e8 ef fb ff ff       	call   f01008df <boot_alloc>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100cf0:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100cf5:	77 15                	ja     f0100d0c <page_init+0xa1>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100cf7:	50                   	push   %eax
f0100cf8:	68 f0 3c 10 f0       	push   $0xf0103cf0
f0100cfd:	68 11 01 00 00       	push   $0x111
f0100d02:	68 80 43 10 f0       	push   $0xf0104380
f0100d07:	e8 7f f3 ff ff       	call   f010008b <_panic>
	for (i = EXTPHYSMEM / (PGSIZE); i < nextfree / (PGSIZE); i++)
f0100d0c:	05 00 00 00 10       	add    $0x10000000,%eax
f0100d11:	c1 e8 0c             	shr    $0xc,%eax
		pages[i].pp_ref = 1;
f0100d14:	8b 0d 70 69 11 f0    	mov    0xf0116970,%ecx
	//     Some of it is in use, some is free. Where is the kernel
	//     in physical memory?  Which pages are already in use for
	//     page tables and other data structures?
	//	up to kern.text 0x1000000
	size_t nextfree = PADDR(boot_alloc(0));
	for (i = EXTPHYSMEM / (PGSIZE); i < nextfree / (PGSIZE); i++)
f0100d1a:	ba 00 01 00 00       	mov    $0x100,%edx
f0100d1f:	eb 0a                	jmp    f0100d2b <page_init+0xc0>
		pages[i].pp_ref = 1;
f0100d21:	66 c7 44 d1 04 01 00 	movw   $0x1,0x4(%ecx,%edx,8)
	//     Some of it is in use, some is free. Where is the kernel
	//     in physical memory?  Which pages are already in use for
	//     page tables and other data structures?
	//	up to kern.text 0x1000000
	size_t nextfree = PADDR(boot_alloc(0));
	for (i = EXTPHYSMEM / (PGSIZE); i < nextfree / (PGSIZE); i++)
f0100d28:	83 c2 01             	add    $0x1,%edx
f0100d2b:	39 c2                	cmp    %eax,%edx
f0100d2d:	72 f2                	jb     f0100d21 <page_init+0xb6>
f0100d2f:	8b 1d 3c 65 11 f0    	mov    0xf011653c,%ebx
f0100d35:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
f0100d3c:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100d41:	eb 23                	jmp    f0100d66 <page_init+0xfb>
		pages[i].pp_ref = 1;
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	for (i = nextfree / (PGSIZE); i < npages; i++) {
		pages[i].pp_ref = 0;
f0100d43:	89 d1                	mov    %edx,%ecx
f0100d45:	03 0d 70 69 11 f0    	add    0xf0116970,%ecx
f0100d4b:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = page_free_list;
f0100d51:	89 19                	mov    %ebx,(%ecx)
		page_free_list = &pages[i];
f0100d53:	89 d3                	mov    %edx,%ebx
f0100d55:	03 1d 70 69 11 f0    	add    0xf0116970,%ebx
	for (i = EXTPHYSMEM / (PGSIZE); i < nextfree / (PGSIZE); i++)
		pages[i].pp_ref = 1;
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	for (i = nextfree / (PGSIZE); i < npages; i++) {
f0100d5b:	83 c0 01             	add    $0x1,%eax
f0100d5e:	83 c2 08             	add    $0x8,%edx
f0100d61:	b9 01 00 00 00       	mov    $0x1,%ecx
f0100d66:	3b 05 68 69 11 f0    	cmp    0xf0116968,%eax
f0100d6c:	72 d5                	jb     f0100d43 <page_init+0xd8>
f0100d6e:	84 c9                	test   %cl,%cl
f0100d70:	74 06                	je     f0100d78 <page_init+0x10d>
f0100d72:	89 1d 3c 65 11 f0    	mov    %ebx,0xf011653c
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
	
}
f0100d78:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100d7b:	5b                   	pop    %ebx
f0100d7c:	5e                   	pop    %esi
f0100d7d:	5d                   	pop    %ebp
f0100d7e:	c3                   	ret    

f0100d7f <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100d7f:	55                   	push   %ebp
f0100d80:	89 e5                	mov    %esp,%ebp
f0100d82:	53                   	push   %ebx
f0100d83:	83 ec 04             	sub    $0x4,%esp
	// Fill this function in
	if (page_free_list == NULL)
f0100d86:	8b 1d 3c 65 11 f0    	mov    0xf011653c,%ebx
f0100d8c:	85 db                	test   %ebx,%ebx
f0100d8e:	74 58                	je     f0100de8 <page_alloc+0x69>
		return NULL;
	struct PageInfo * freepg = page_free_list;
	page_free_list = page_free_list->pp_link;
f0100d90:	8b 03                	mov    (%ebx),%eax
f0100d92:	a3 3c 65 11 f0       	mov    %eax,0xf011653c

	freepg->pp_link = NULL;
f0100d97:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	if (ALLOC_ZERO & alloc_flags)
f0100d9d:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100da1:	74 45                	je     f0100de8 <page_alloc+0x69>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100da3:	89 d8                	mov    %ebx,%eax
f0100da5:	2b 05 70 69 11 f0    	sub    0xf0116970,%eax
f0100dab:	c1 f8 03             	sar    $0x3,%eax
f0100dae:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100db1:	89 c2                	mov    %eax,%edx
f0100db3:	c1 ea 0c             	shr    $0xc,%edx
f0100db6:	3b 15 68 69 11 f0    	cmp    0xf0116968,%edx
f0100dbc:	72 12                	jb     f0100dd0 <page_alloc+0x51>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100dbe:	50                   	push   %eax
f0100dbf:	68 e4 3b 10 f0       	push   $0xf0103be4
f0100dc4:	6a 53                	push   $0x53
f0100dc6:	68 8c 43 10 f0       	push   $0xf010438c
f0100dcb:	e8 bb f2 ff ff       	call   f010008b <_panic>
		memset(page2kva(freepg), 0 , PGSIZE);
f0100dd0:	83 ec 04             	sub    $0x4,%esp
f0100dd3:	68 00 10 00 00       	push   $0x1000
f0100dd8:	6a 00                	push   $0x0
f0100dda:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100ddf:	50                   	push   %eax
f0100de0:	e8 3d 24 00 00       	call   f0103222 <memset>
f0100de5:	83 c4 10             	add    $0x10,%esp
	return freepg;
}
f0100de8:	89 d8                	mov    %ebx,%eax
f0100dea:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100ded:	c9                   	leave  
f0100dee:	c3                   	ret    

f0100def <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100def:	55                   	push   %ebp
f0100df0:	89 e5                	mov    %esp,%ebp
f0100df2:	83 ec 08             	sub    $0x8,%esp
f0100df5:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	if (pp->pp_link || pp->pp_ref)
f0100df8:	83 38 00             	cmpl   $0x0,(%eax)
f0100dfb:	75 07                	jne    f0100e04 <page_free+0x15>
f0100dfd:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100e02:	74 17                	je     f0100e1b <page_free+0x2c>
		panic("page to be free is not free at all\n");
f0100e04:	83 ec 04             	sub    $0x4,%esp
f0100e07:	68 14 3d 10 f0       	push   $0xf0103d14
f0100e0c:	68 44 01 00 00       	push   $0x144
f0100e11:	68 80 43 10 f0       	push   $0xf0104380
f0100e16:	e8 70 f2 ff ff       	call   f010008b <_panic>
	// pp->pp_link is not NULL.
	pp->pp_link = page_free_list;
f0100e1b:	8b 15 3c 65 11 f0    	mov    0xf011653c,%edx
f0100e21:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;	
f0100e23:	a3 3c 65 11 f0       	mov    %eax,0xf011653c
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100e28:	2b 05 70 69 11 f0    	sub    0xf0116970,%eax
f0100e2e:	c1 f8 03             	sar    $0x3,%eax
f0100e31:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100e34:	89 c2                	mov    %eax,%edx
f0100e36:	c1 ea 0c             	shr    $0xc,%edx
f0100e39:	3b 15 68 69 11 f0    	cmp    0xf0116968,%edx
f0100e3f:	72 12                	jb     f0100e53 <page_free+0x64>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100e41:	50                   	push   %eax
f0100e42:	68 e4 3b 10 f0       	push   $0xf0103be4
f0100e47:	6a 53                	push   $0x53
f0100e49:	68 8c 43 10 f0       	push   $0xf010438c
f0100e4e:	e8 38 f2 ff ff       	call   f010008b <_panic>
	memset(page2kva(pp), 0 , PGSIZE);
f0100e53:	83 ec 04             	sub    $0x4,%esp
f0100e56:	68 00 10 00 00       	push   $0x1000
f0100e5b:	6a 00                	push   $0x0
f0100e5d:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100e62:	50                   	push   %eax
f0100e63:	e8 ba 23 00 00       	call   f0103222 <memset>
}
f0100e68:	83 c4 10             	add    $0x10,%esp
f0100e6b:	c9                   	leave  
f0100e6c:	c3                   	ret    

f0100e6d <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0100e6d:	55                   	push   %ebp
f0100e6e:	89 e5                	mov    %esp,%ebp
f0100e70:	83 ec 08             	sub    $0x8,%esp
f0100e73:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0100e76:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0100e7a:	83 e8 01             	sub    $0x1,%eax
f0100e7d:	66 89 42 04          	mov    %ax,0x4(%edx)
f0100e81:	66 85 c0             	test   %ax,%ax
f0100e84:	75 0c                	jne    f0100e92 <page_decref+0x25>
		page_free(pp);
f0100e86:	83 ec 0c             	sub    $0xc,%esp
f0100e89:	52                   	push   %edx
f0100e8a:	e8 60 ff ff ff       	call   f0100def <page_free>
f0100e8f:	83 c4 10             	add    $0x10,%esp
}
f0100e92:	c9                   	leave  
f0100e93:	c3                   	ret    

f0100e94 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that manipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100e94:	55                   	push   %ebp
f0100e95:	89 e5                	mov    %esp,%ebp
f0100e97:	57                   	push   %edi
f0100e98:	56                   	push   %esi
f0100e99:	53                   	push   %ebx
f0100e9a:	83 ec 0c             	sub    $0xc,%esp
	// Fill this function in
	pde_t *pde = &pgdir[PDX(va)];
f0100e9d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100ea0:	c1 eb 16             	shr    $0x16,%ebx
f0100ea3:	c1 e3 02             	shl    $0x2,%ebx
f0100ea6:	03 5d 08             	add    0x8(%ebp),%ebx
	pde_t *pgtab;
	struct PageInfo* freepg;
	if (*pde & PTE_P) // page table present
f0100ea9:	8b 33                	mov    (%ebx),%esi
f0100eab:	f7 c6 01 00 00 00    	test   $0x1,%esi
f0100eb1:	74 30                	je     f0100ee3 <pgdir_walk+0x4f>
		pgtab = (pte_t*)KADDR(PTE_ADDR(*pde));
f0100eb3:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100eb9:	89 f0                	mov    %esi,%eax
f0100ebb:	c1 e8 0c             	shr    $0xc,%eax
f0100ebe:	39 05 68 69 11 f0    	cmp    %eax,0xf0116968
f0100ec4:	77 15                	ja     f0100edb <pgdir_walk+0x47>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ec6:	56                   	push   %esi
f0100ec7:	68 e4 3b 10 f0       	push   $0xf0103be4
f0100ecc:	68 74 01 00 00       	push   $0x174
f0100ed1:	68 80 43 10 f0       	push   $0xf0104380
f0100ed6:	e8 b0 f1 ff ff       	call   f010008b <_panic>
	return (void *)(pa + KERNBASE);
f0100edb:	81 ee 00 00 00 10    	sub    $0x10000000,%esi
f0100ee1:	eb 67                	jmp    f0100f4a <pgdir_walk+0xb6>


	else {
		if (!create || (freepg = page_alloc(ALLOC_ZERO)) == NULL) {
f0100ee3:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100ee7:	74 70                	je     f0100f59 <pgdir_walk+0xc5>
f0100ee9:	83 ec 0c             	sub    $0xc,%esp
f0100eec:	6a 01                	push   $0x1
f0100eee:	e8 8c fe ff ff       	call   f0100d7f <page_alloc>
f0100ef3:	89 c7                	mov    %eax,%edi
f0100ef5:	83 c4 10             	add    $0x10,%esp
f0100ef8:	85 c0                	test   %eax,%eax
f0100efa:	74 64                	je     f0100f60 <pgdir_walk+0xcc>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100efc:	2b 05 70 69 11 f0    	sub    0xf0116970,%eax
f0100f02:	c1 f8 03             	sar    $0x3,%eax
f0100f05:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100f08:	89 c2                	mov    %eax,%edx
f0100f0a:	c1 ea 0c             	shr    $0xc,%edx
f0100f0d:	3b 15 68 69 11 f0    	cmp    0xf0116968,%edx
f0100f13:	72 12                	jb     f0100f27 <pgdir_walk+0x93>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100f15:	50                   	push   %eax
f0100f16:	68 e4 3b 10 f0       	push   $0xf0103be4
f0100f1b:	6a 53                	push   $0x53
f0100f1d:	68 8c 43 10 f0       	push   $0xf010438c
f0100f22:	e8 64 f1 ff ff       	call   f010008b <_panic>
	return (void *)(pa + KERNBASE);
f0100f27:	8d b0 00 00 00 f0    	lea    -0x10000000(%eax),%esi
			return NULL;
		}
		pgtab = page2kva(freepg);
		*pde = page2pa(freepg) | PTE_P | PTE_W | PTE_U; // in directory
f0100f2d:	83 c8 07             	or     $0x7,%eax
f0100f30:	89 03                	mov    %eax,(%ebx)
		memset(pgtab, 0 , PGSIZE);
f0100f32:	83 ec 04             	sub    $0x4,%esp
f0100f35:	68 00 10 00 00       	push   $0x1000
f0100f3a:	6a 00                	push   $0x0
f0100f3c:	56                   	push   %esi
f0100f3d:	e8 e0 22 00 00       	call   f0103222 <memset>
		freepg->pp_ref++;
f0100f42:	66 83 47 04 01       	addw   $0x1,0x4(%edi)
f0100f47:	83 c4 10             	add    $0x10,%esp
	}
	return &pgtab[PTX(va)];
f0100f4a:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100f4d:	c1 e8 0a             	shr    $0xa,%eax
f0100f50:	25 fc 0f 00 00       	and    $0xffc,%eax
f0100f55:	01 f0                	add    %esi,%eax
f0100f57:	eb 0c                	jmp    f0100f65 <pgdir_walk+0xd1>
		pgtab = (pte_t*)KADDR(PTE_ADDR(*pde));


	else {
		if (!create || (freepg = page_alloc(ALLOC_ZERO)) == NULL) {
			return NULL;
f0100f59:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f5e:	eb 05                	jmp    f0100f65 <pgdir_walk+0xd1>
f0100f60:	b8 00 00 00 00       	mov    $0x0,%eax
		*pde = page2pa(freepg) | PTE_P | PTE_W | PTE_U; // in directory
		memset(pgtab, 0 , PGSIZE);
		freepg->pp_ref++;
	}
	return &pgtab[PTX(va)];
}
f0100f65:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100f68:	5b                   	pop    %ebx
f0100f69:	5e                   	pop    %esi
f0100f6a:	5f                   	pop    %edi
f0100f6b:	5d                   	pop    %ebp
f0100f6c:	c3                   	ret    

f0100f6d <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0100f6d:	55                   	push   %ebp
f0100f6e:	89 e5                	mov    %esp,%ebp
f0100f70:	57                   	push   %edi
f0100f71:	56                   	push   %esi
f0100f72:	53                   	push   %ebx
f0100f73:	83 ec 1c             	sub    $0x1c,%esp
f0100f76:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100f79:	8b 45 08             	mov    0x8(%ebp),%eax
		*pte = pa | perm | PTE_P;
	}
	*/
	 // Fill this function in
    pte_t *pgtab;
    size_t pg_num = PGNUM(size);
f0100f7c:	c1 e9 0c             	shr    $0xc,%ecx
f0100f7f:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
    //cprintf("map region size = %d, %d pages\n",size, pg_num);
    for (size_t i=0; i<pg_num; i++) {
f0100f82:	89 c3                	mov    %eax,%ebx
f0100f84:	be 00 00 00 00       	mov    $0x0,%esi
        pgtab = pgdir_walk(pgdir, (void *)va, 1);
f0100f89:	89 d7                	mov    %edx,%edi
f0100f8b:	29 c7                	sub    %eax,%edi
        if (!pgtab) {
            return;
        }
        //cprintf("va = %p to pa = %p\n", va, pa);
        *pgtab = pa | perm | PTE_P;
f0100f8d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100f90:	83 c8 01             	or     $0x1,%eax
f0100f93:	89 45 dc             	mov    %eax,-0x24(%ebp)
	*/
	 // Fill this function in
    pte_t *pgtab;
    size_t pg_num = PGNUM(size);
    //cprintf("map region size = %d, %d pages\n",size, pg_num);
    for (size_t i=0; i<pg_num; i++) {
f0100f96:	eb 28                	jmp    f0100fc0 <boot_map_region+0x53>
        pgtab = pgdir_walk(pgdir, (void *)va, 1);
f0100f98:	83 ec 04             	sub    $0x4,%esp
f0100f9b:	6a 01                	push   $0x1
f0100f9d:	8d 04 1f             	lea    (%edi,%ebx,1),%eax
f0100fa0:	50                   	push   %eax
f0100fa1:	ff 75 e0             	pushl  -0x20(%ebp)
f0100fa4:	e8 eb fe ff ff       	call   f0100e94 <pgdir_walk>
        if (!pgtab) {
f0100fa9:	83 c4 10             	add    $0x10,%esp
f0100fac:	85 c0                	test   %eax,%eax
f0100fae:	74 15                	je     f0100fc5 <boot_map_region+0x58>
            return;
        }
        //cprintf("va = %p to pa = %p\n", va, pa);
        *pgtab = pa | perm | PTE_P;
f0100fb0:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100fb3:	09 da                	or     %ebx,%edx
f0100fb5:	89 10                	mov    %edx,(%eax)
        va += PGSIZE;
        pa += PGSIZE;
f0100fb7:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	*/
	 // Fill this function in
    pte_t *pgtab;
    size_t pg_num = PGNUM(size);
    //cprintf("map region size = %d, %d pages\n",size, pg_num);
    for (size_t i=0; i<pg_num; i++) {
f0100fbd:	83 c6 01             	add    $0x1,%esi
f0100fc0:	3b 75 e4             	cmp    -0x1c(%ebp),%esi
f0100fc3:	75 d3                	jne    f0100f98 <boot_map_region+0x2b>
        *pgtab = pa | perm | PTE_P;
        va += PGSIZE;
        pa += PGSIZE;
    }
	
}
f0100fc5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100fc8:	5b                   	pop    %ebx
f0100fc9:	5e                   	pop    %esi
f0100fca:	5f                   	pop    %edi
f0100fcb:	5d                   	pop    %ebp
f0100fcc:	c3                   	ret    

f0100fcd <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0100fcd:	55                   	push   %ebp
f0100fce:	89 e5                	mov    %esp,%ebp
f0100fd0:	83 ec 0c             	sub    $0xc,%esp
	// Fill this function in
	pte_t *pte;
	if ((pte = pgdir_walk(pgdir, (void*)va, 0)) == NULL)
f0100fd3:	6a 00                	push   $0x0
f0100fd5:	ff 75 0c             	pushl  0xc(%ebp)
f0100fd8:	ff 75 08             	pushl  0x8(%ebp)
f0100fdb:	e8 b4 fe ff ff       	call   f0100e94 <pgdir_walk>
f0100fe0:	83 c4 10             	add    $0x10,%esp
f0100fe3:	85 c0                	test   %eax,%eax
f0100fe5:	74 31                	je     f0101018 <page_lookup+0x4b>
		return NULL;
	*pte_store = pte;
f0100fe7:	8b 55 10             	mov    0x10(%ebp),%edx
f0100fea:	89 02                	mov    %eax,(%edx)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100fec:	8b 00                	mov    (%eax),%eax
f0100fee:	c1 e8 0c             	shr    $0xc,%eax
f0100ff1:	3b 05 68 69 11 f0    	cmp    0xf0116968,%eax
f0100ff7:	72 14                	jb     f010100d <page_lookup+0x40>
		panic("pa2page called with invalid pa");
f0100ff9:	83 ec 04             	sub    $0x4,%esp
f0100ffc:	68 38 3d 10 f0       	push   $0xf0103d38
f0101001:	6a 4c                	push   $0x4c
f0101003:	68 8c 43 10 f0       	push   $0xf010438c
f0101008:	e8 7e f0 ff ff       	call   f010008b <_panic>
	return &pages[PGNUM(pa)];
f010100d:	8b 15 70 69 11 f0    	mov    0xf0116970,%edx
f0101013:	8d 04 c2             	lea    (%edx,%eax,8),%eax

	return pa2page(PTE_ADDR(*pte));
f0101016:	eb 05                	jmp    f010101d <page_lookup+0x50>
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
	// Fill this function in
	pte_t *pte;
	if ((pte = pgdir_walk(pgdir, (void*)va, 0)) == NULL)
		return NULL;
f0101018:	b8 00 00 00 00       	mov    $0x0,%eax
	*pte_store = pte;

	return pa2page(PTE_ADDR(*pte));
}
f010101d:	c9                   	leave  
f010101e:	c3                   	ret    

f010101f <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f010101f:	55                   	push   %ebp
f0101020:	89 e5                	mov    %esp,%ebp
f0101022:	53                   	push   %ebx
f0101023:	83 ec 18             	sub    $0x18,%esp
f0101026:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
	pte_t *pte;
	struct PageInfo *pg;

	pg = page_lookup(pgdir, va, &pte);
f0101029:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010102c:	50                   	push   %eax
f010102d:	53                   	push   %ebx
f010102e:	ff 75 08             	pushl  0x8(%ebp)
f0101031:	e8 97 ff ff ff       	call   f0100fcd <page_lookup>
	
	if (!pg) return;
f0101036:	83 c4 10             	add    $0x10,%esp
f0101039:	85 c0                	test   %eax,%eax
f010103b:	74 18                	je     f0101055 <page_remove+0x36>
	page_decref(pg);
f010103d:	83 ec 0c             	sub    $0xc,%esp
f0101040:	50                   	push   %eax
f0101041:	e8 27 fe ff ff       	call   f0100e6d <page_decref>
	*pte = 0x0;
f0101046:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101049:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f010104f:	0f 01 3b             	invlpg (%ebx)
f0101052:	83 c4 10             	add    $0x10,%esp
	tlb_invalidate(pgdir, va);
}
f0101055:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101058:	c9                   	leave  
f0101059:	c3                   	ret    

f010105a <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f010105a:	55                   	push   %ebp
f010105b:	89 e5                	mov    %esp,%ebp
f010105d:	57                   	push   %edi
f010105e:	56                   	push   %esi
f010105f:	53                   	push   %ebx
f0101060:	83 ec 10             	sub    $0x10,%esp
f0101063:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101066:	8b 7d 10             	mov    0x10(%ebp),%edi
	// Fill this function in

	pte_t *pte;

	if ((pte = pgdir_walk(pgdir, (void*)va, 1)) == NULL)
f0101069:	6a 01                	push   $0x1
f010106b:	57                   	push   %edi
f010106c:	ff 75 08             	pushl  0x8(%ebp)
f010106f:	e8 20 fe ff ff       	call   f0100e94 <pgdir_walk>
f0101074:	83 c4 10             	add    $0x10,%esp
f0101077:	85 c0                	test   %eax,%eax
f0101079:	74 38                	je     f01010b3 <page_insert+0x59>
f010107b:	89 c6                	mov    %eax,%esi
		return -E_NO_MEM;
	++pp->pp_ref;
f010107d:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
	if (*pte & PTE_P) {
f0101082:	f6 00 01             	testb  $0x1,(%eax)
f0101085:	74 0f                	je     f0101096 <page_insert+0x3c>
		page_remove(pgdir, va);
f0101087:	83 ec 08             	sub    $0x8,%esp
f010108a:	57                   	push   %edi
f010108b:	ff 75 08             	pushl  0x8(%ebp)
f010108e:	e8 8c ff ff ff       	call   f010101f <page_remove>
f0101093:	83 c4 10             	add    $0x10,%esp
	}
	*pte = page2pa(pp) | perm | PTE_P;
f0101096:	2b 1d 70 69 11 f0    	sub    0xf0116970,%ebx
f010109c:	c1 fb 03             	sar    $0x3,%ebx
f010109f:	c1 e3 0c             	shl    $0xc,%ebx
f01010a2:	8b 45 14             	mov    0x14(%ebp),%eax
f01010a5:	83 c8 01             	or     $0x1,%eax
f01010a8:	09 c3                	or     %eax,%ebx
f01010aa:	89 1e                	mov    %ebx,(%esi)
	
	return 0;
f01010ac:	b8 00 00 00 00       	mov    $0x0,%eax
f01010b1:	eb 05                	jmp    f01010b8 <page_insert+0x5e>
	// Fill this function in

	pte_t *pte;

	if ((pte = pgdir_walk(pgdir, (void*)va, 1)) == NULL)
		return -E_NO_MEM;
f01010b3:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	}
	*pte = page2pa(pp) | perm | PTE_P;
	
	return 0;
	
}
f01010b8:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01010bb:	5b                   	pop    %ebx
f01010bc:	5e                   	pop    %esi
f01010bd:	5f                   	pop    %edi
f01010be:	5d                   	pop    %ebp
f01010bf:	c3                   	ret    

f01010c0 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f01010c0:	55                   	push   %ebp
f01010c1:	89 e5                	mov    %esp,%ebp
f01010c3:	57                   	push   %edi
f01010c4:	56                   	push   %esi
f01010c5:	53                   	push   %ebx
f01010c6:	83 ec 2c             	sub    $0x2c,%esp
{
	size_t basemem, extmem, ext16mem, totalmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	basemem = nvram_read(NVRAM_BASELO);
f01010c9:	b8 15 00 00 00       	mov    $0x15,%eax
f01010ce:	e8 48 f8 ff ff       	call   f010091b <nvram_read>
f01010d3:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f01010d5:	b8 17 00 00 00       	mov    $0x17,%eax
f01010da:	e8 3c f8 ff ff       	call   f010091b <nvram_read>
f01010df:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f01010e1:	b8 34 00 00 00       	mov    $0x34,%eax
f01010e6:	e8 30 f8 ff ff       	call   f010091b <nvram_read>
f01010eb:	c1 e0 06             	shl    $0x6,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (ext16mem)
f01010ee:	85 c0                	test   %eax,%eax
f01010f0:	74 07                	je     f01010f9 <mem_init+0x39>
		totalmem = 16 * 1024 + ext16mem;
f01010f2:	05 00 40 00 00       	add    $0x4000,%eax
f01010f7:	eb 0b                	jmp    f0101104 <mem_init+0x44>
	else if (extmem)
		totalmem = 1 * 1024 + extmem;
f01010f9:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f01010ff:	85 f6                	test   %esi,%esi
f0101101:	0f 44 c3             	cmove  %ebx,%eax
	else
		totalmem = basemem;

	npages = totalmem / (PGSIZE / 1024); // in KB / KB
f0101104:	89 c2                	mov    %eax,%edx
f0101106:	c1 ea 02             	shr    $0x2,%edx
f0101109:	89 15 68 69 11 f0    	mov    %edx,0xf0116968
	npages_basemem = basemem / (PGSIZE / 1024);
f010110f:	89 da                	mov    %ebx,%edx
f0101111:	c1 ea 02             	shr    $0x2,%edx
f0101114:	89 15 40 65 11 f0    	mov    %edx,0xf0116540

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f010111a:	89 c2                	mov    %eax,%edx
f010111c:	29 da                	sub    %ebx,%edx
f010111e:	52                   	push   %edx
f010111f:	53                   	push   %ebx
f0101120:	50                   	push   %eax
f0101121:	68 58 3d 10 f0       	push   $0xf0103d58
f0101126:	e8 3e 16 00 00       	call   f0102769 <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE); // va
f010112b:	b8 00 10 00 00       	mov    $0x1000,%eax
f0101130:	e8 aa f7 ff ff       	call   f01008df <boot_alloc>
f0101135:	a3 6c 69 11 f0       	mov    %eax,0xf011696c
	memset(kern_pgdir, 0, PGSIZE);
f010113a:	83 c4 0c             	add    $0xc,%esp
f010113d:	68 00 10 00 00       	push   $0x1000
f0101142:	6a 00                	push   $0x0
f0101144:	50                   	push   %eax
f0101145:	e8 d8 20 00 00       	call   f0103222 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f010114a:	a1 6c 69 11 f0       	mov    0xf011696c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010114f:	83 c4 10             	add    $0x10,%esp
f0101152:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101157:	77 15                	ja     f010116e <mem_init+0xae>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101159:	50                   	push   %eax
f010115a:	68 f0 3c 10 f0       	push   $0xf0103cf0
f010115f:	68 94 00 00 00       	push   $0x94
f0101164:	68 80 43 10 f0       	push   $0xf0104380
f0101169:	e8 1d ef ff ff       	call   f010008b <_panic>
f010116e:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0101174:	83 ca 05             	or     $0x5,%edx
f0101177:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	pages = (struct PageInfo*)boot_alloc(npages * sizeof(struct PageInfo));
f010117d:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f0101182:	c1 e0 03             	shl    $0x3,%eax
f0101185:	e8 55 f7 ff ff       	call   f01008df <boot_alloc>
f010118a:	a3 70 69 11 f0       	mov    %eax,0xf0116970
	memset((void*)pages, 0, sizeof(npages * sizeof(struct PageInfo)));
f010118f:	83 ec 04             	sub    $0x4,%esp
f0101192:	6a 04                	push   $0x4
f0101194:	6a 00                	push   $0x0
f0101196:	50                   	push   %eax
f0101197:	e8 86 20 00 00       	call   f0103222 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f010119c:	e8 ca fa ff ff       	call   f0100c6b <page_init>

	check_page_free_list(1);
f01011a1:	b8 01 00 00 00       	mov    $0x1,%eax
f01011a6:	e8 fd f7 ff ff       	call   f01009a8 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f01011ab:	83 c4 10             	add    $0x10,%esp
f01011ae:	83 3d 70 69 11 f0 00 	cmpl   $0x0,0xf0116970
f01011b5:	75 17                	jne    f01011ce <mem_init+0x10e>
		panic("'pages' is a null pointer!");
f01011b7:	83 ec 04             	sub    $0x4,%esp
f01011ba:	68 36 44 10 f0       	push   $0xf0104436
f01011bf:	68 6b 02 00 00       	push   $0x26b
f01011c4:	68 80 43 10 f0       	push   $0xf0104380
f01011c9:	e8 bd ee ff ff       	call   f010008b <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01011ce:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f01011d3:	bb 00 00 00 00       	mov    $0x0,%ebx
f01011d8:	eb 05                	jmp    f01011df <mem_init+0x11f>
		++nfree;
f01011da:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01011dd:	8b 00                	mov    (%eax),%eax
f01011df:	85 c0                	test   %eax,%eax
f01011e1:	75 f7                	jne    f01011da <mem_init+0x11a>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01011e3:	83 ec 0c             	sub    $0xc,%esp
f01011e6:	6a 00                	push   $0x0
f01011e8:	e8 92 fb ff ff       	call   f0100d7f <page_alloc>
f01011ed:	89 c7                	mov    %eax,%edi
f01011ef:	83 c4 10             	add    $0x10,%esp
f01011f2:	85 c0                	test   %eax,%eax
f01011f4:	75 19                	jne    f010120f <mem_init+0x14f>
f01011f6:	68 51 44 10 f0       	push   $0xf0104451
f01011fb:	68 a6 43 10 f0       	push   $0xf01043a6
f0101200:	68 73 02 00 00       	push   $0x273
f0101205:	68 80 43 10 f0       	push   $0xf0104380
f010120a:	e8 7c ee ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f010120f:	83 ec 0c             	sub    $0xc,%esp
f0101212:	6a 00                	push   $0x0
f0101214:	e8 66 fb ff ff       	call   f0100d7f <page_alloc>
f0101219:	89 c6                	mov    %eax,%esi
f010121b:	83 c4 10             	add    $0x10,%esp
f010121e:	85 c0                	test   %eax,%eax
f0101220:	75 19                	jne    f010123b <mem_init+0x17b>
f0101222:	68 67 44 10 f0       	push   $0xf0104467
f0101227:	68 a6 43 10 f0       	push   $0xf01043a6
f010122c:	68 74 02 00 00       	push   $0x274
f0101231:	68 80 43 10 f0       	push   $0xf0104380
f0101236:	e8 50 ee ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f010123b:	83 ec 0c             	sub    $0xc,%esp
f010123e:	6a 00                	push   $0x0
f0101240:	e8 3a fb ff ff       	call   f0100d7f <page_alloc>
f0101245:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101248:	83 c4 10             	add    $0x10,%esp
f010124b:	85 c0                	test   %eax,%eax
f010124d:	75 19                	jne    f0101268 <mem_init+0x1a8>
f010124f:	68 7d 44 10 f0       	push   $0xf010447d
f0101254:	68 a6 43 10 f0       	push   $0xf01043a6
f0101259:	68 75 02 00 00       	push   $0x275
f010125e:	68 80 43 10 f0       	push   $0xf0104380
f0101263:	e8 23 ee ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101268:	39 f7                	cmp    %esi,%edi
f010126a:	75 19                	jne    f0101285 <mem_init+0x1c5>
f010126c:	68 93 44 10 f0       	push   $0xf0104493
f0101271:	68 a6 43 10 f0       	push   $0xf01043a6
f0101276:	68 78 02 00 00       	push   $0x278
f010127b:	68 80 43 10 f0       	push   $0xf0104380
f0101280:	e8 06 ee ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101285:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101288:	39 c6                	cmp    %eax,%esi
f010128a:	74 04                	je     f0101290 <mem_init+0x1d0>
f010128c:	39 c7                	cmp    %eax,%edi
f010128e:	75 19                	jne    f01012a9 <mem_init+0x1e9>
f0101290:	68 94 3d 10 f0       	push   $0xf0103d94
f0101295:	68 a6 43 10 f0       	push   $0xf01043a6
f010129a:	68 79 02 00 00       	push   $0x279
f010129f:	68 80 43 10 f0       	push   $0xf0104380
f01012a4:	e8 e2 ed ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01012a9:	8b 0d 70 69 11 f0    	mov    0xf0116970,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f01012af:	8b 15 68 69 11 f0    	mov    0xf0116968,%edx
f01012b5:	c1 e2 0c             	shl    $0xc,%edx
f01012b8:	89 f8                	mov    %edi,%eax
f01012ba:	29 c8                	sub    %ecx,%eax
f01012bc:	c1 f8 03             	sar    $0x3,%eax
f01012bf:	c1 e0 0c             	shl    $0xc,%eax
f01012c2:	39 d0                	cmp    %edx,%eax
f01012c4:	72 19                	jb     f01012df <mem_init+0x21f>
f01012c6:	68 a5 44 10 f0       	push   $0xf01044a5
f01012cb:	68 a6 43 10 f0       	push   $0xf01043a6
f01012d0:	68 7a 02 00 00       	push   $0x27a
f01012d5:	68 80 43 10 f0       	push   $0xf0104380
f01012da:	e8 ac ed ff ff       	call   f010008b <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f01012df:	89 f0                	mov    %esi,%eax
f01012e1:	29 c8                	sub    %ecx,%eax
f01012e3:	c1 f8 03             	sar    $0x3,%eax
f01012e6:	c1 e0 0c             	shl    $0xc,%eax
f01012e9:	39 c2                	cmp    %eax,%edx
f01012eb:	77 19                	ja     f0101306 <mem_init+0x246>
f01012ed:	68 c2 44 10 f0       	push   $0xf01044c2
f01012f2:	68 a6 43 10 f0       	push   $0xf01043a6
f01012f7:	68 7b 02 00 00       	push   $0x27b
f01012fc:	68 80 43 10 f0       	push   $0xf0104380
f0101301:	e8 85 ed ff ff       	call   f010008b <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f0101306:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101309:	29 c8                	sub    %ecx,%eax
f010130b:	c1 f8 03             	sar    $0x3,%eax
f010130e:	c1 e0 0c             	shl    $0xc,%eax
f0101311:	39 c2                	cmp    %eax,%edx
f0101313:	77 19                	ja     f010132e <mem_init+0x26e>
f0101315:	68 df 44 10 f0       	push   $0xf01044df
f010131a:	68 a6 43 10 f0       	push   $0xf01043a6
f010131f:	68 7c 02 00 00       	push   $0x27c
f0101324:	68 80 43 10 f0       	push   $0xf0104380
f0101329:	e8 5d ed ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f010132e:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f0101333:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101336:	c7 05 3c 65 11 f0 00 	movl   $0x0,0xf011653c
f010133d:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101340:	83 ec 0c             	sub    $0xc,%esp
f0101343:	6a 00                	push   $0x0
f0101345:	e8 35 fa ff ff       	call   f0100d7f <page_alloc>
f010134a:	83 c4 10             	add    $0x10,%esp
f010134d:	85 c0                	test   %eax,%eax
f010134f:	74 19                	je     f010136a <mem_init+0x2aa>
f0101351:	68 fc 44 10 f0       	push   $0xf01044fc
f0101356:	68 a6 43 10 f0       	push   $0xf01043a6
f010135b:	68 83 02 00 00       	push   $0x283
f0101360:	68 80 43 10 f0       	push   $0xf0104380
f0101365:	e8 21 ed ff ff       	call   f010008b <_panic>

	// free and re-allocate?
	page_free(pp0);
f010136a:	83 ec 0c             	sub    $0xc,%esp
f010136d:	57                   	push   %edi
f010136e:	e8 7c fa ff ff       	call   f0100def <page_free>
	page_free(pp1);
f0101373:	89 34 24             	mov    %esi,(%esp)
f0101376:	e8 74 fa ff ff       	call   f0100def <page_free>
	page_free(pp2);
f010137b:	83 c4 04             	add    $0x4,%esp
f010137e:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101381:	e8 69 fa ff ff       	call   f0100def <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101386:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010138d:	e8 ed f9 ff ff       	call   f0100d7f <page_alloc>
f0101392:	89 c6                	mov    %eax,%esi
f0101394:	83 c4 10             	add    $0x10,%esp
f0101397:	85 c0                	test   %eax,%eax
f0101399:	75 19                	jne    f01013b4 <mem_init+0x2f4>
f010139b:	68 51 44 10 f0       	push   $0xf0104451
f01013a0:	68 a6 43 10 f0       	push   $0xf01043a6
f01013a5:	68 8a 02 00 00       	push   $0x28a
f01013aa:	68 80 43 10 f0       	push   $0xf0104380
f01013af:	e8 d7 ec ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f01013b4:	83 ec 0c             	sub    $0xc,%esp
f01013b7:	6a 00                	push   $0x0
f01013b9:	e8 c1 f9 ff ff       	call   f0100d7f <page_alloc>
f01013be:	89 c7                	mov    %eax,%edi
f01013c0:	83 c4 10             	add    $0x10,%esp
f01013c3:	85 c0                	test   %eax,%eax
f01013c5:	75 19                	jne    f01013e0 <mem_init+0x320>
f01013c7:	68 67 44 10 f0       	push   $0xf0104467
f01013cc:	68 a6 43 10 f0       	push   $0xf01043a6
f01013d1:	68 8b 02 00 00       	push   $0x28b
f01013d6:	68 80 43 10 f0       	push   $0xf0104380
f01013db:	e8 ab ec ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f01013e0:	83 ec 0c             	sub    $0xc,%esp
f01013e3:	6a 00                	push   $0x0
f01013e5:	e8 95 f9 ff ff       	call   f0100d7f <page_alloc>
f01013ea:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01013ed:	83 c4 10             	add    $0x10,%esp
f01013f0:	85 c0                	test   %eax,%eax
f01013f2:	75 19                	jne    f010140d <mem_init+0x34d>
f01013f4:	68 7d 44 10 f0       	push   $0xf010447d
f01013f9:	68 a6 43 10 f0       	push   $0xf01043a6
f01013fe:	68 8c 02 00 00       	push   $0x28c
f0101403:	68 80 43 10 f0       	push   $0xf0104380
f0101408:	e8 7e ec ff ff       	call   f010008b <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010140d:	39 fe                	cmp    %edi,%esi
f010140f:	75 19                	jne    f010142a <mem_init+0x36a>
f0101411:	68 93 44 10 f0       	push   $0xf0104493
f0101416:	68 a6 43 10 f0       	push   $0xf01043a6
f010141b:	68 8e 02 00 00       	push   $0x28e
f0101420:	68 80 43 10 f0       	push   $0xf0104380
f0101425:	e8 61 ec ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010142a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010142d:	39 c7                	cmp    %eax,%edi
f010142f:	74 04                	je     f0101435 <mem_init+0x375>
f0101431:	39 c6                	cmp    %eax,%esi
f0101433:	75 19                	jne    f010144e <mem_init+0x38e>
f0101435:	68 94 3d 10 f0       	push   $0xf0103d94
f010143a:	68 a6 43 10 f0       	push   $0xf01043a6
f010143f:	68 8f 02 00 00       	push   $0x28f
f0101444:	68 80 43 10 f0       	push   $0xf0104380
f0101449:	e8 3d ec ff ff       	call   f010008b <_panic>
	assert(!page_alloc(0));
f010144e:	83 ec 0c             	sub    $0xc,%esp
f0101451:	6a 00                	push   $0x0
f0101453:	e8 27 f9 ff ff       	call   f0100d7f <page_alloc>
f0101458:	83 c4 10             	add    $0x10,%esp
f010145b:	85 c0                	test   %eax,%eax
f010145d:	74 19                	je     f0101478 <mem_init+0x3b8>
f010145f:	68 fc 44 10 f0       	push   $0xf01044fc
f0101464:	68 a6 43 10 f0       	push   $0xf01043a6
f0101469:	68 90 02 00 00       	push   $0x290
f010146e:	68 80 43 10 f0       	push   $0xf0104380
f0101473:	e8 13 ec ff ff       	call   f010008b <_panic>
f0101478:	89 f0                	mov    %esi,%eax
f010147a:	2b 05 70 69 11 f0    	sub    0xf0116970,%eax
f0101480:	c1 f8 03             	sar    $0x3,%eax
f0101483:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101486:	89 c2                	mov    %eax,%edx
f0101488:	c1 ea 0c             	shr    $0xc,%edx
f010148b:	3b 15 68 69 11 f0    	cmp    0xf0116968,%edx
f0101491:	72 12                	jb     f01014a5 <mem_init+0x3e5>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101493:	50                   	push   %eax
f0101494:	68 e4 3b 10 f0       	push   $0xf0103be4
f0101499:	6a 53                	push   $0x53
f010149b:	68 8c 43 10 f0       	push   $0xf010438c
f01014a0:	e8 e6 eb ff ff       	call   f010008b <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f01014a5:	83 ec 04             	sub    $0x4,%esp
f01014a8:	68 00 10 00 00       	push   $0x1000
f01014ad:	6a 01                	push   $0x1
f01014af:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01014b4:	50                   	push   %eax
f01014b5:	e8 68 1d 00 00       	call   f0103222 <memset>
	page_free(pp0);
f01014ba:	89 34 24             	mov    %esi,(%esp)
f01014bd:	e8 2d f9 ff ff       	call   f0100def <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01014c2:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01014c9:	e8 b1 f8 ff ff       	call   f0100d7f <page_alloc>
f01014ce:	83 c4 10             	add    $0x10,%esp
f01014d1:	85 c0                	test   %eax,%eax
f01014d3:	75 19                	jne    f01014ee <mem_init+0x42e>
f01014d5:	68 0b 45 10 f0       	push   $0xf010450b
f01014da:	68 a6 43 10 f0       	push   $0xf01043a6
f01014df:	68 95 02 00 00       	push   $0x295
f01014e4:	68 80 43 10 f0       	push   $0xf0104380
f01014e9:	e8 9d eb ff ff       	call   f010008b <_panic>
	assert(pp && pp0 == pp);
f01014ee:	39 c6                	cmp    %eax,%esi
f01014f0:	74 19                	je     f010150b <mem_init+0x44b>
f01014f2:	68 29 45 10 f0       	push   $0xf0104529
f01014f7:	68 a6 43 10 f0       	push   $0xf01043a6
f01014fc:	68 96 02 00 00       	push   $0x296
f0101501:	68 80 43 10 f0       	push   $0xf0104380
f0101506:	e8 80 eb ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010150b:	89 f0                	mov    %esi,%eax
f010150d:	2b 05 70 69 11 f0    	sub    0xf0116970,%eax
f0101513:	c1 f8 03             	sar    $0x3,%eax
f0101516:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101519:	89 c2                	mov    %eax,%edx
f010151b:	c1 ea 0c             	shr    $0xc,%edx
f010151e:	3b 15 68 69 11 f0    	cmp    0xf0116968,%edx
f0101524:	72 12                	jb     f0101538 <mem_init+0x478>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101526:	50                   	push   %eax
f0101527:	68 e4 3b 10 f0       	push   $0xf0103be4
f010152c:	6a 53                	push   $0x53
f010152e:	68 8c 43 10 f0       	push   $0xf010438c
f0101533:	e8 53 eb ff ff       	call   f010008b <_panic>
f0101538:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f010153e:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f0101544:	80 38 00             	cmpb   $0x0,(%eax)
f0101547:	74 19                	je     f0101562 <mem_init+0x4a2>
f0101549:	68 39 45 10 f0       	push   $0xf0104539
f010154e:	68 a6 43 10 f0       	push   $0xf01043a6
f0101553:	68 99 02 00 00       	push   $0x299
f0101558:	68 80 43 10 f0       	push   $0xf0104380
f010155d:	e8 29 eb ff ff       	call   f010008b <_panic>
f0101562:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f0101565:	39 d0                	cmp    %edx,%eax
f0101567:	75 db                	jne    f0101544 <mem_init+0x484>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101569:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010156c:	a3 3c 65 11 f0       	mov    %eax,0xf011653c

	// free the pages we took
	page_free(pp0);
f0101571:	83 ec 0c             	sub    $0xc,%esp
f0101574:	56                   	push   %esi
f0101575:	e8 75 f8 ff ff       	call   f0100def <page_free>
	page_free(pp1);
f010157a:	89 3c 24             	mov    %edi,(%esp)
f010157d:	e8 6d f8 ff ff       	call   f0100def <page_free>
	page_free(pp2);
f0101582:	83 c4 04             	add    $0x4,%esp
f0101585:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101588:	e8 62 f8 ff ff       	call   f0100def <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010158d:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f0101592:	83 c4 10             	add    $0x10,%esp
f0101595:	eb 05                	jmp    f010159c <mem_init+0x4dc>
		--nfree;
f0101597:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010159a:	8b 00                	mov    (%eax),%eax
f010159c:	85 c0                	test   %eax,%eax
f010159e:	75 f7                	jne    f0101597 <mem_init+0x4d7>
		--nfree;
	assert(nfree == 0);
f01015a0:	85 db                	test   %ebx,%ebx
f01015a2:	74 19                	je     f01015bd <mem_init+0x4fd>
f01015a4:	68 43 45 10 f0       	push   $0xf0104543
f01015a9:	68 a6 43 10 f0       	push   $0xf01043a6
f01015ae:	68 a6 02 00 00       	push   $0x2a6
f01015b3:	68 80 43 10 f0       	push   $0xf0104380
f01015b8:	e8 ce ea ff ff       	call   f010008b <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f01015bd:	83 ec 0c             	sub    $0xc,%esp
f01015c0:	68 b4 3d 10 f0       	push   $0xf0103db4
f01015c5:	e8 9f 11 00 00       	call   f0102769 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01015ca:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01015d1:	e8 a9 f7 ff ff       	call   f0100d7f <page_alloc>
f01015d6:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01015d9:	83 c4 10             	add    $0x10,%esp
f01015dc:	85 c0                	test   %eax,%eax
f01015de:	75 19                	jne    f01015f9 <mem_init+0x539>
f01015e0:	68 51 44 10 f0       	push   $0xf0104451
f01015e5:	68 a6 43 10 f0       	push   $0xf01043a6
f01015ea:	68 ff 02 00 00       	push   $0x2ff
f01015ef:	68 80 43 10 f0       	push   $0xf0104380
f01015f4:	e8 92 ea ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f01015f9:	83 ec 0c             	sub    $0xc,%esp
f01015fc:	6a 00                	push   $0x0
f01015fe:	e8 7c f7 ff ff       	call   f0100d7f <page_alloc>
f0101603:	89 c3                	mov    %eax,%ebx
f0101605:	83 c4 10             	add    $0x10,%esp
f0101608:	85 c0                	test   %eax,%eax
f010160a:	75 19                	jne    f0101625 <mem_init+0x565>
f010160c:	68 67 44 10 f0       	push   $0xf0104467
f0101611:	68 a6 43 10 f0       	push   $0xf01043a6
f0101616:	68 00 03 00 00       	push   $0x300
f010161b:	68 80 43 10 f0       	push   $0xf0104380
f0101620:	e8 66 ea ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0101625:	83 ec 0c             	sub    $0xc,%esp
f0101628:	6a 00                	push   $0x0
f010162a:	e8 50 f7 ff ff       	call   f0100d7f <page_alloc>
f010162f:	89 c6                	mov    %eax,%esi
f0101631:	83 c4 10             	add    $0x10,%esp
f0101634:	85 c0                	test   %eax,%eax
f0101636:	75 19                	jne    f0101651 <mem_init+0x591>
f0101638:	68 7d 44 10 f0       	push   $0xf010447d
f010163d:	68 a6 43 10 f0       	push   $0xf01043a6
f0101642:	68 01 03 00 00       	push   $0x301
f0101647:	68 80 43 10 f0       	push   $0xf0104380
f010164c:	e8 3a ea ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101651:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0101654:	75 19                	jne    f010166f <mem_init+0x5af>
f0101656:	68 93 44 10 f0       	push   $0xf0104493
f010165b:	68 a6 43 10 f0       	push   $0xf01043a6
f0101660:	68 04 03 00 00       	push   $0x304
f0101665:	68 80 43 10 f0       	push   $0xf0104380
f010166a:	e8 1c ea ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010166f:	39 c3                	cmp    %eax,%ebx
f0101671:	74 05                	je     f0101678 <mem_init+0x5b8>
f0101673:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101676:	75 19                	jne    f0101691 <mem_init+0x5d1>
f0101678:	68 94 3d 10 f0       	push   $0xf0103d94
f010167d:	68 a6 43 10 f0       	push   $0xf01043a6
f0101682:	68 05 03 00 00       	push   $0x305
f0101687:	68 80 43 10 f0       	push   $0xf0104380
f010168c:	e8 fa e9 ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101691:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f0101696:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101699:	c7 05 3c 65 11 f0 00 	movl   $0x0,0xf011653c
f01016a0:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01016a3:	83 ec 0c             	sub    $0xc,%esp
f01016a6:	6a 00                	push   $0x0
f01016a8:	e8 d2 f6 ff ff       	call   f0100d7f <page_alloc>
f01016ad:	83 c4 10             	add    $0x10,%esp
f01016b0:	85 c0                	test   %eax,%eax
f01016b2:	74 19                	je     f01016cd <mem_init+0x60d>
f01016b4:	68 fc 44 10 f0       	push   $0xf01044fc
f01016b9:	68 a6 43 10 f0       	push   $0xf01043a6
f01016be:	68 0c 03 00 00       	push   $0x30c
f01016c3:	68 80 43 10 f0       	push   $0xf0104380
f01016c8:	e8 be e9 ff ff       	call   f010008b <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f01016cd:	83 ec 04             	sub    $0x4,%esp
f01016d0:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01016d3:	50                   	push   %eax
f01016d4:	6a 00                	push   $0x0
f01016d6:	ff 35 6c 69 11 f0    	pushl  0xf011696c
f01016dc:	e8 ec f8 ff ff       	call   f0100fcd <page_lookup>
f01016e1:	83 c4 10             	add    $0x10,%esp
f01016e4:	85 c0                	test   %eax,%eax
f01016e6:	74 19                	je     f0101701 <mem_init+0x641>
f01016e8:	68 d4 3d 10 f0       	push   $0xf0103dd4
f01016ed:	68 a6 43 10 f0       	push   $0xf01043a6
f01016f2:	68 0f 03 00 00       	push   $0x30f
f01016f7:	68 80 43 10 f0       	push   $0xf0104380
f01016fc:	e8 8a e9 ff ff       	call   f010008b <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101701:	6a 02                	push   $0x2
f0101703:	6a 00                	push   $0x0
f0101705:	53                   	push   %ebx
f0101706:	ff 35 6c 69 11 f0    	pushl  0xf011696c
f010170c:	e8 49 f9 ff ff       	call   f010105a <page_insert>
f0101711:	83 c4 10             	add    $0x10,%esp
f0101714:	85 c0                	test   %eax,%eax
f0101716:	78 19                	js     f0101731 <mem_init+0x671>
f0101718:	68 0c 3e 10 f0       	push   $0xf0103e0c
f010171d:	68 a6 43 10 f0       	push   $0xf01043a6
f0101722:	68 12 03 00 00       	push   $0x312
f0101727:	68 80 43 10 f0       	push   $0xf0104380
f010172c:	e8 5a e9 ff ff       	call   f010008b <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101731:	83 ec 0c             	sub    $0xc,%esp
f0101734:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101737:	e8 b3 f6 ff ff       	call   f0100def <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f010173c:	6a 02                	push   $0x2
f010173e:	6a 00                	push   $0x0
f0101740:	53                   	push   %ebx
f0101741:	ff 35 6c 69 11 f0    	pushl  0xf011696c
f0101747:	e8 0e f9 ff ff       	call   f010105a <page_insert>
f010174c:	83 c4 20             	add    $0x20,%esp
f010174f:	85 c0                	test   %eax,%eax
f0101751:	74 19                	je     f010176c <mem_init+0x6ac>
f0101753:	68 3c 3e 10 f0       	push   $0xf0103e3c
f0101758:	68 a6 43 10 f0       	push   $0xf01043a6
f010175d:	68 16 03 00 00       	push   $0x316
f0101762:	68 80 43 10 f0       	push   $0xf0104380
f0101767:	e8 1f e9 ff ff       	call   f010008b <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010176c:	8b 3d 6c 69 11 f0    	mov    0xf011696c,%edi
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101772:	a1 70 69 11 f0       	mov    0xf0116970,%eax
f0101777:	89 c1                	mov    %eax,%ecx
f0101779:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010177c:	8b 17                	mov    (%edi),%edx
f010177e:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101784:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101787:	29 c8                	sub    %ecx,%eax
f0101789:	c1 f8 03             	sar    $0x3,%eax
f010178c:	c1 e0 0c             	shl    $0xc,%eax
f010178f:	39 c2                	cmp    %eax,%edx
f0101791:	74 19                	je     f01017ac <mem_init+0x6ec>
f0101793:	68 6c 3e 10 f0       	push   $0xf0103e6c
f0101798:	68 a6 43 10 f0       	push   $0xf01043a6
f010179d:	68 17 03 00 00       	push   $0x317
f01017a2:	68 80 43 10 f0       	push   $0xf0104380
f01017a7:	e8 df e8 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f01017ac:	ba 00 00 00 00       	mov    $0x0,%edx
f01017b1:	89 f8                	mov    %edi,%eax
f01017b3:	e8 8c f1 ff ff       	call   f0100944 <check_va2pa>
f01017b8:	89 da                	mov    %ebx,%edx
f01017ba:	2b 55 cc             	sub    -0x34(%ebp),%edx
f01017bd:	c1 fa 03             	sar    $0x3,%edx
f01017c0:	c1 e2 0c             	shl    $0xc,%edx
f01017c3:	39 d0                	cmp    %edx,%eax
f01017c5:	74 19                	je     f01017e0 <mem_init+0x720>
f01017c7:	68 94 3e 10 f0       	push   $0xf0103e94
f01017cc:	68 a6 43 10 f0       	push   $0xf01043a6
f01017d1:	68 18 03 00 00       	push   $0x318
f01017d6:	68 80 43 10 f0       	push   $0xf0104380
f01017db:	e8 ab e8 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f01017e0:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01017e5:	74 19                	je     f0101800 <mem_init+0x740>
f01017e7:	68 4e 45 10 f0       	push   $0xf010454e
f01017ec:	68 a6 43 10 f0       	push   $0xf01043a6
f01017f1:	68 19 03 00 00       	push   $0x319
f01017f6:	68 80 43 10 f0       	push   $0xf0104380
f01017fb:	e8 8b e8 ff ff       	call   f010008b <_panic>
	assert(pp0->pp_ref == 1);
f0101800:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101803:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101808:	74 19                	je     f0101823 <mem_init+0x763>
f010180a:	68 5f 45 10 f0       	push   $0xf010455f
f010180f:	68 a6 43 10 f0       	push   $0xf01043a6
f0101814:	68 1a 03 00 00       	push   $0x31a
f0101819:	68 80 43 10 f0       	push   $0xf0104380
f010181e:	e8 68 e8 ff ff       	call   f010008b <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101823:	6a 02                	push   $0x2
f0101825:	68 00 10 00 00       	push   $0x1000
f010182a:	56                   	push   %esi
f010182b:	57                   	push   %edi
f010182c:	e8 29 f8 ff ff       	call   f010105a <page_insert>
f0101831:	83 c4 10             	add    $0x10,%esp
f0101834:	85 c0                	test   %eax,%eax
f0101836:	74 19                	je     f0101851 <mem_init+0x791>
f0101838:	68 c4 3e 10 f0       	push   $0xf0103ec4
f010183d:	68 a6 43 10 f0       	push   $0xf01043a6
f0101842:	68 1d 03 00 00       	push   $0x31d
f0101847:	68 80 43 10 f0       	push   $0xf0104380
f010184c:	e8 3a e8 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101851:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101856:	a1 6c 69 11 f0       	mov    0xf011696c,%eax
f010185b:	e8 e4 f0 ff ff       	call   f0100944 <check_va2pa>
f0101860:	89 f2                	mov    %esi,%edx
f0101862:	2b 15 70 69 11 f0    	sub    0xf0116970,%edx
f0101868:	c1 fa 03             	sar    $0x3,%edx
f010186b:	c1 e2 0c             	shl    $0xc,%edx
f010186e:	39 d0                	cmp    %edx,%eax
f0101870:	74 19                	je     f010188b <mem_init+0x7cb>
f0101872:	68 00 3f 10 f0       	push   $0xf0103f00
f0101877:	68 a6 43 10 f0       	push   $0xf01043a6
f010187c:	68 1e 03 00 00       	push   $0x31e
f0101881:	68 80 43 10 f0       	push   $0xf0104380
f0101886:	e8 00 e8 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f010188b:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101890:	74 19                	je     f01018ab <mem_init+0x7eb>
f0101892:	68 70 45 10 f0       	push   $0xf0104570
f0101897:	68 a6 43 10 f0       	push   $0xf01043a6
f010189c:	68 1f 03 00 00       	push   $0x31f
f01018a1:	68 80 43 10 f0       	push   $0xf0104380
f01018a6:	e8 e0 e7 ff ff       	call   f010008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f01018ab:	83 ec 0c             	sub    $0xc,%esp
f01018ae:	6a 00                	push   $0x0
f01018b0:	e8 ca f4 ff ff       	call   f0100d7f <page_alloc>
f01018b5:	83 c4 10             	add    $0x10,%esp
f01018b8:	85 c0                	test   %eax,%eax
f01018ba:	74 19                	je     f01018d5 <mem_init+0x815>
f01018bc:	68 fc 44 10 f0       	push   $0xf01044fc
f01018c1:	68 a6 43 10 f0       	push   $0xf01043a6
f01018c6:	68 22 03 00 00       	push   $0x322
f01018cb:	68 80 43 10 f0       	push   $0xf0104380
f01018d0:	e8 b6 e7 ff ff       	call   f010008b <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01018d5:	6a 02                	push   $0x2
f01018d7:	68 00 10 00 00       	push   $0x1000
f01018dc:	56                   	push   %esi
f01018dd:	ff 35 6c 69 11 f0    	pushl  0xf011696c
f01018e3:	e8 72 f7 ff ff       	call   f010105a <page_insert>
f01018e8:	83 c4 10             	add    $0x10,%esp
f01018eb:	85 c0                	test   %eax,%eax
f01018ed:	74 19                	je     f0101908 <mem_init+0x848>
f01018ef:	68 c4 3e 10 f0       	push   $0xf0103ec4
f01018f4:	68 a6 43 10 f0       	push   $0xf01043a6
f01018f9:	68 25 03 00 00       	push   $0x325
f01018fe:	68 80 43 10 f0       	push   $0xf0104380
f0101903:	e8 83 e7 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101908:	ba 00 10 00 00       	mov    $0x1000,%edx
f010190d:	a1 6c 69 11 f0       	mov    0xf011696c,%eax
f0101912:	e8 2d f0 ff ff       	call   f0100944 <check_va2pa>
f0101917:	89 f2                	mov    %esi,%edx
f0101919:	2b 15 70 69 11 f0    	sub    0xf0116970,%edx
f010191f:	c1 fa 03             	sar    $0x3,%edx
f0101922:	c1 e2 0c             	shl    $0xc,%edx
f0101925:	39 d0                	cmp    %edx,%eax
f0101927:	74 19                	je     f0101942 <mem_init+0x882>
f0101929:	68 00 3f 10 f0       	push   $0xf0103f00
f010192e:	68 a6 43 10 f0       	push   $0xf01043a6
f0101933:	68 26 03 00 00       	push   $0x326
f0101938:	68 80 43 10 f0       	push   $0xf0104380
f010193d:	e8 49 e7 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f0101942:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101947:	74 19                	je     f0101962 <mem_init+0x8a2>
f0101949:	68 70 45 10 f0       	push   $0xf0104570
f010194e:	68 a6 43 10 f0       	push   $0xf01043a6
f0101953:	68 27 03 00 00       	push   $0x327
f0101958:	68 80 43 10 f0       	push   $0xf0104380
f010195d:	e8 29 e7 ff ff       	call   f010008b <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101962:	83 ec 0c             	sub    $0xc,%esp
f0101965:	6a 00                	push   $0x0
f0101967:	e8 13 f4 ff ff       	call   f0100d7f <page_alloc>
f010196c:	83 c4 10             	add    $0x10,%esp
f010196f:	85 c0                	test   %eax,%eax
f0101971:	74 19                	je     f010198c <mem_init+0x8cc>
f0101973:	68 fc 44 10 f0       	push   $0xf01044fc
f0101978:	68 a6 43 10 f0       	push   $0xf01043a6
f010197d:	68 2b 03 00 00       	push   $0x32b
f0101982:	68 80 43 10 f0       	push   $0xf0104380
f0101987:	e8 ff e6 ff ff       	call   f010008b <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f010198c:	8b 15 6c 69 11 f0    	mov    0xf011696c,%edx
f0101992:	8b 02                	mov    (%edx),%eax
f0101994:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101999:	89 c1                	mov    %eax,%ecx
f010199b:	c1 e9 0c             	shr    $0xc,%ecx
f010199e:	3b 0d 68 69 11 f0    	cmp    0xf0116968,%ecx
f01019a4:	72 15                	jb     f01019bb <mem_init+0x8fb>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01019a6:	50                   	push   %eax
f01019a7:	68 e4 3b 10 f0       	push   $0xf0103be4
f01019ac:	68 2e 03 00 00       	push   $0x32e
f01019b1:	68 80 43 10 f0       	push   $0xf0104380
f01019b6:	e8 d0 e6 ff ff       	call   f010008b <_panic>
f01019bb:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01019c0:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f01019c3:	83 ec 04             	sub    $0x4,%esp
f01019c6:	6a 00                	push   $0x0
f01019c8:	68 00 10 00 00       	push   $0x1000
f01019cd:	52                   	push   %edx
f01019ce:	e8 c1 f4 ff ff       	call   f0100e94 <pgdir_walk>
f01019d3:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f01019d6:	8d 51 04             	lea    0x4(%ecx),%edx
f01019d9:	83 c4 10             	add    $0x10,%esp
f01019dc:	39 d0                	cmp    %edx,%eax
f01019de:	74 19                	je     f01019f9 <mem_init+0x939>
f01019e0:	68 30 3f 10 f0       	push   $0xf0103f30
f01019e5:	68 a6 43 10 f0       	push   $0xf01043a6
f01019ea:	68 2f 03 00 00       	push   $0x32f
f01019ef:	68 80 43 10 f0       	push   $0xf0104380
f01019f4:	e8 92 e6 ff ff       	call   f010008b <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f01019f9:	6a 06                	push   $0x6
f01019fb:	68 00 10 00 00       	push   $0x1000
f0101a00:	56                   	push   %esi
f0101a01:	ff 35 6c 69 11 f0    	pushl  0xf011696c
f0101a07:	e8 4e f6 ff ff       	call   f010105a <page_insert>
f0101a0c:	83 c4 10             	add    $0x10,%esp
f0101a0f:	85 c0                	test   %eax,%eax
f0101a11:	74 19                	je     f0101a2c <mem_init+0x96c>
f0101a13:	68 70 3f 10 f0       	push   $0xf0103f70
f0101a18:	68 a6 43 10 f0       	push   $0xf01043a6
f0101a1d:	68 32 03 00 00       	push   $0x332
f0101a22:	68 80 43 10 f0       	push   $0xf0104380
f0101a27:	e8 5f e6 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101a2c:	8b 3d 6c 69 11 f0    	mov    0xf011696c,%edi
f0101a32:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101a37:	89 f8                	mov    %edi,%eax
f0101a39:	e8 06 ef ff ff       	call   f0100944 <check_va2pa>
f0101a3e:	89 f2                	mov    %esi,%edx
f0101a40:	2b 15 70 69 11 f0    	sub    0xf0116970,%edx
f0101a46:	c1 fa 03             	sar    $0x3,%edx
f0101a49:	c1 e2 0c             	shl    $0xc,%edx
f0101a4c:	39 d0                	cmp    %edx,%eax
f0101a4e:	74 19                	je     f0101a69 <mem_init+0x9a9>
f0101a50:	68 00 3f 10 f0       	push   $0xf0103f00
f0101a55:	68 a6 43 10 f0       	push   $0xf01043a6
f0101a5a:	68 33 03 00 00       	push   $0x333
f0101a5f:	68 80 43 10 f0       	push   $0xf0104380
f0101a64:	e8 22 e6 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f0101a69:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101a6e:	74 19                	je     f0101a89 <mem_init+0x9c9>
f0101a70:	68 70 45 10 f0       	push   $0xf0104570
f0101a75:	68 a6 43 10 f0       	push   $0xf01043a6
f0101a7a:	68 34 03 00 00       	push   $0x334
f0101a7f:	68 80 43 10 f0       	push   $0xf0104380
f0101a84:	e8 02 e6 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101a89:	83 ec 04             	sub    $0x4,%esp
f0101a8c:	6a 00                	push   $0x0
f0101a8e:	68 00 10 00 00       	push   $0x1000
f0101a93:	57                   	push   %edi
f0101a94:	e8 fb f3 ff ff       	call   f0100e94 <pgdir_walk>
f0101a99:	83 c4 10             	add    $0x10,%esp
f0101a9c:	f6 00 04             	testb  $0x4,(%eax)
f0101a9f:	75 19                	jne    f0101aba <mem_init+0x9fa>
f0101aa1:	68 b0 3f 10 f0       	push   $0xf0103fb0
f0101aa6:	68 a6 43 10 f0       	push   $0xf01043a6
f0101aab:	68 35 03 00 00       	push   $0x335
f0101ab0:	68 80 43 10 f0       	push   $0xf0104380
f0101ab5:	e8 d1 e5 ff ff       	call   f010008b <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101aba:	a1 6c 69 11 f0       	mov    0xf011696c,%eax
f0101abf:	f6 00 04             	testb  $0x4,(%eax)
f0101ac2:	75 19                	jne    f0101add <mem_init+0xa1d>
f0101ac4:	68 81 45 10 f0       	push   $0xf0104581
f0101ac9:	68 a6 43 10 f0       	push   $0xf01043a6
f0101ace:	68 36 03 00 00       	push   $0x336
f0101ad3:	68 80 43 10 f0       	push   $0xf0104380
f0101ad8:	e8 ae e5 ff ff       	call   f010008b <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101add:	6a 02                	push   $0x2
f0101adf:	68 00 10 00 00       	push   $0x1000
f0101ae4:	56                   	push   %esi
f0101ae5:	50                   	push   %eax
f0101ae6:	e8 6f f5 ff ff       	call   f010105a <page_insert>
f0101aeb:	83 c4 10             	add    $0x10,%esp
f0101aee:	85 c0                	test   %eax,%eax
f0101af0:	74 19                	je     f0101b0b <mem_init+0xa4b>
f0101af2:	68 c4 3e 10 f0       	push   $0xf0103ec4
f0101af7:	68 a6 43 10 f0       	push   $0xf01043a6
f0101afc:	68 39 03 00 00       	push   $0x339
f0101b01:	68 80 43 10 f0       	push   $0xf0104380
f0101b06:	e8 80 e5 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101b0b:	83 ec 04             	sub    $0x4,%esp
f0101b0e:	6a 00                	push   $0x0
f0101b10:	68 00 10 00 00       	push   $0x1000
f0101b15:	ff 35 6c 69 11 f0    	pushl  0xf011696c
f0101b1b:	e8 74 f3 ff ff       	call   f0100e94 <pgdir_walk>
f0101b20:	83 c4 10             	add    $0x10,%esp
f0101b23:	f6 00 02             	testb  $0x2,(%eax)
f0101b26:	75 19                	jne    f0101b41 <mem_init+0xa81>
f0101b28:	68 e4 3f 10 f0       	push   $0xf0103fe4
f0101b2d:	68 a6 43 10 f0       	push   $0xf01043a6
f0101b32:	68 3a 03 00 00       	push   $0x33a
f0101b37:	68 80 43 10 f0       	push   $0xf0104380
f0101b3c:	e8 4a e5 ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101b41:	83 ec 04             	sub    $0x4,%esp
f0101b44:	6a 00                	push   $0x0
f0101b46:	68 00 10 00 00       	push   $0x1000
f0101b4b:	ff 35 6c 69 11 f0    	pushl  0xf011696c
f0101b51:	e8 3e f3 ff ff       	call   f0100e94 <pgdir_walk>
f0101b56:	83 c4 10             	add    $0x10,%esp
f0101b59:	f6 00 04             	testb  $0x4,(%eax)
f0101b5c:	74 19                	je     f0101b77 <mem_init+0xab7>
f0101b5e:	68 18 40 10 f0       	push   $0xf0104018
f0101b63:	68 a6 43 10 f0       	push   $0xf01043a6
f0101b68:	68 3b 03 00 00       	push   $0x33b
f0101b6d:	68 80 43 10 f0       	push   $0xf0104380
f0101b72:	e8 14 e5 ff ff       	call   f010008b <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101b77:	6a 02                	push   $0x2
f0101b79:	68 00 00 40 00       	push   $0x400000
f0101b7e:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101b81:	ff 35 6c 69 11 f0    	pushl  0xf011696c
f0101b87:	e8 ce f4 ff ff       	call   f010105a <page_insert>
f0101b8c:	83 c4 10             	add    $0x10,%esp
f0101b8f:	85 c0                	test   %eax,%eax
f0101b91:	78 19                	js     f0101bac <mem_init+0xaec>
f0101b93:	68 50 40 10 f0       	push   $0xf0104050
f0101b98:	68 a6 43 10 f0       	push   $0xf01043a6
f0101b9d:	68 3e 03 00 00       	push   $0x33e
f0101ba2:	68 80 43 10 f0       	push   $0xf0104380
f0101ba7:	e8 df e4 ff ff       	call   f010008b <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101bac:	6a 02                	push   $0x2
f0101bae:	68 00 10 00 00       	push   $0x1000
f0101bb3:	53                   	push   %ebx
f0101bb4:	ff 35 6c 69 11 f0    	pushl  0xf011696c
f0101bba:	e8 9b f4 ff ff       	call   f010105a <page_insert>
f0101bbf:	83 c4 10             	add    $0x10,%esp
f0101bc2:	85 c0                	test   %eax,%eax
f0101bc4:	74 19                	je     f0101bdf <mem_init+0xb1f>
f0101bc6:	68 88 40 10 f0       	push   $0xf0104088
f0101bcb:	68 a6 43 10 f0       	push   $0xf01043a6
f0101bd0:	68 41 03 00 00       	push   $0x341
f0101bd5:	68 80 43 10 f0       	push   $0xf0104380
f0101bda:	e8 ac e4 ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101bdf:	83 ec 04             	sub    $0x4,%esp
f0101be2:	6a 00                	push   $0x0
f0101be4:	68 00 10 00 00       	push   $0x1000
f0101be9:	ff 35 6c 69 11 f0    	pushl  0xf011696c
f0101bef:	e8 a0 f2 ff ff       	call   f0100e94 <pgdir_walk>
f0101bf4:	83 c4 10             	add    $0x10,%esp
f0101bf7:	f6 00 04             	testb  $0x4,(%eax)
f0101bfa:	74 19                	je     f0101c15 <mem_init+0xb55>
f0101bfc:	68 18 40 10 f0       	push   $0xf0104018
f0101c01:	68 a6 43 10 f0       	push   $0xf01043a6
f0101c06:	68 42 03 00 00       	push   $0x342
f0101c0b:	68 80 43 10 f0       	push   $0xf0104380
f0101c10:	e8 76 e4 ff ff       	call   f010008b <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101c15:	8b 3d 6c 69 11 f0    	mov    0xf011696c,%edi
f0101c1b:	ba 00 00 00 00       	mov    $0x0,%edx
f0101c20:	89 f8                	mov    %edi,%eax
f0101c22:	e8 1d ed ff ff       	call   f0100944 <check_va2pa>
f0101c27:	89 c1                	mov    %eax,%ecx
f0101c29:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101c2c:	89 d8                	mov    %ebx,%eax
f0101c2e:	2b 05 70 69 11 f0    	sub    0xf0116970,%eax
f0101c34:	c1 f8 03             	sar    $0x3,%eax
f0101c37:	c1 e0 0c             	shl    $0xc,%eax
f0101c3a:	39 c1                	cmp    %eax,%ecx
f0101c3c:	74 19                	je     f0101c57 <mem_init+0xb97>
f0101c3e:	68 c4 40 10 f0       	push   $0xf01040c4
f0101c43:	68 a6 43 10 f0       	push   $0xf01043a6
f0101c48:	68 45 03 00 00       	push   $0x345
f0101c4d:	68 80 43 10 f0       	push   $0xf0104380
f0101c52:	e8 34 e4 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101c57:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c5c:	89 f8                	mov    %edi,%eax
f0101c5e:	e8 e1 ec ff ff       	call   f0100944 <check_va2pa>
f0101c63:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101c66:	74 19                	je     f0101c81 <mem_init+0xbc1>
f0101c68:	68 f0 40 10 f0       	push   $0xf01040f0
f0101c6d:	68 a6 43 10 f0       	push   $0xf01043a6
f0101c72:	68 46 03 00 00       	push   $0x346
f0101c77:	68 80 43 10 f0       	push   $0xf0104380
f0101c7c:	e8 0a e4 ff ff       	call   f010008b <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101c81:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101c86:	74 19                	je     f0101ca1 <mem_init+0xbe1>
f0101c88:	68 97 45 10 f0       	push   $0xf0104597
f0101c8d:	68 a6 43 10 f0       	push   $0xf01043a6
f0101c92:	68 48 03 00 00       	push   $0x348
f0101c97:	68 80 43 10 f0       	push   $0xf0104380
f0101c9c:	e8 ea e3 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101ca1:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101ca6:	74 19                	je     f0101cc1 <mem_init+0xc01>
f0101ca8:	68 a8 45 10 f0       	push   $0xf01045a8
f0101cad:	68 a6 43 10 f0       	push   $0xf01043a6
f0101cb2:	68 49 03 00 00       	push   $0x349
f0101cb7:	68 80 43 10 f0       	push   $0xf0104380
f0101cbc:	e8 ca e3 ff ff       	call   f010008b <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101cc1:	83 ec 0c             	sub    $0xc,%esp
f0101cc4:	6a 00                	push   $0x0
f0101cc6:	e8 b4 f0 ff ff       	call   f0100d7f <page_alloc>
f0101ccb:	83 c4 10             	add    $0x10,%esp
f0101cce:	85 c0                	test   %eax,%eax
f0101cd0:	74 04                	je     f0101cd6 <mem_init+0xc16>
f0101cd2:	39 c6                	cmp    %eax,%esi
f0101cd4:	74 19                	je     f0101cef <mem_init+0xc2f>
f0101cd6:	68 20 41 10 f0       	push   $0xf0104120
f0101cdb:	68 a6 43 10 f0       	push   $0xf01043a6
f0101ce0:	68 4c 03 00 00       	push   $0x34c
f0101ce5:	68 80 43 10 f0       	push   $0xf0104380
f0101cea:	e8 9c e3 ff ff       	call   f010008b <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101cef:	83 ec 08             	sub    $0x8,%esp
f0101cf2:	6a 00                	push   $0x0
f0101cf4:	ff 35 6c 69 11 f0    	pushl  0xf011696c
f0101cfa:	e8 20 f3 ff ff       	call   f010101f <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101cff:	8b 3d 6c 69 11 f0    	mov    0xf011696c,%edi
f0101d05:	ba 00 00 00 00       	mov    $0x0,%edx
f0101d0a:	89 f8                	mov    %edi,%eax
f0101d0c:	e8 33 ec ff ff       	call   f0100944 <check_va2pa>
f0101d11:	83 c4 10             	add    $0x10,%esp
f0101d14:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101d17:	74 19                	je     f0101d32 <mem_init+0xc72>
f0101d19:	68 44 41 10 f0       	push   $0xf0104144
f0101d1e:	68 a6 43 10 f0       	push   $0xf01043a6
f0101d23:	68 50 03 00 00       	push   $0x350
f0101d28:	68 80 43 10 f0       	push   $0xf0104380
f0101d2d:	e8 59 e3 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101d32:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101d37:	89 f8                	mov    %edi,%eax
f0101d39:	e8 06 ec ff ff       	call   f0100944 <check_va2pa>
f0101d3e:	89 da                	mov    %ebx,%edx
f0101d40:	2b 15 70 69 11 f0    	sub    0xf0116970,%edx
f0101d46:	c1 fa 03             	sar    $0x3,%edx
f0101d49:	c1 e2 0c             	shl    $0xc,%edx
f0101d4c:	39 d0                	cmp    %edx,%eax
f0101d4e:	74 19                	je     f0101d69 <mem_init+0xca9>
f0101d50:	68 f0 40 10 f0       	push   $0xf01040f0
f0101d55:	68 a6 43 10 f0       	push   $0xf01043a6
f0101d5a:	68 51 03 00 00       	push   $0x351
f0101d5f:	68 80 43 10 f0       	push   $0xf0104380
f0101d64:	e8 22 e3 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f0101d69:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101d6e:	74 19                	je     f0101d89 <mem_init+0xcc9>
f0101d70:	68 4e 45 10 f0       	push   $0xf010454e
f0101d75:	68 a6 43 10 f0       	push   $0xf01043a6
f0101d7a:	68 52 03 00 00       	push   $0x352
f0101d7f:	68 80 43 10 f0       	push   $0xf0104380
f0101d84:	e8 02 e3 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101d89:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101d8e:	74 19                	je     f0101da9 <mem_init+0xce9>
f0101d90:	68 a8 45 10 f0       	push   $0xf01045a8
f0101d95:	68 a6 43 10 f0       	push   $0xf01043a6
f0101d9a:	68 53 03 00 00       	push   $0x353
f0101d9f:	68 80 43 10 f0       	push   $0xf0104380
f0101da4:	e8 e2 e2 ff ff       	call   f010008b <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101da9:	6a 00                	push   $0x0
f0101dab:	68 00 10 00 00       	push   $0x1000
f0101db0:	53                   	push   %ebx
f0101db1:	57                   	push   %edi
f0101db2:	e8 a3 f2 ff ff       	call   f010105a <page_insert>
f0101db7:	83 c4 10             	add    $0x10,%esp
f0101dba:	85 c0                	test   %eax,%eax
f0101dbc:	74 19                	je     f0101dd7 <mem_init+0xd17>
f0101dbe:	68 68 41 10 f0       	push   $0xf0104168
f0101dc3:	68 a6 43 10 f0       	push   $0xf01043a6
f0101dc8:	68 56 03 00 00       	push   $0x356
f0101dcd:	68 80 43 10 f0       	push   $0xf0104380
f0101dd2:	e8 b4 e2 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref);
f0101dd7:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101ddc:	75 19                	jne    f0101df7 <mem_init+0xd37>
f0101dde:	68 b9 45 10 f0       	push   $0xf01045b9
f0101de3:	68 a6 43 10 f0       	push   $0xf01043a6
f0101de8:	68 57 03 00 00       	push   $0x357
f0101ded:	68 80 43 10 f0       	push   $0xf0104380
f0101df2:	e8 94 e2 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_link == NULL);
f0101df7:	83 3b 00             	cmpl   $0x0,(%ebx)
f0101dfa:	74 19                	je     f0101e15 <mem_init+0xd55>
f0101dfc:	68 c5 45 10 f0       	push   $0xf01045c5
f0101e01:	68 a6 43 10 f0       	push   $0xf01043a6
f0101e06:	68 58 03 00 00       	push   $0x358
f0101e0b:	68 80 43 10 f0       	push   $0xf0104380
f0101e10:	e8 76 e2 ff ff       	call   f010008b <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101e15:	83 ec 08             	sub    $0x8,%esp
f0101e18:	68 00 10 00 00       	push   $0x1000
f0101e1d:	ff 35 6c 69 11 f0    	pushl  0xf011696c
f0101e23:	e8 f7 f1 ff ff       	call   f010101f <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101e28:	8b 3d 6c 69 11 f0    	mov    0xf011696c,%edi
f0101e2e:	ba 00 00 00 00       	mov    $0x0,%edx
f0101e33:	89 f8                	mov    %edi,%eax
f0101e35:	e8 0a eb ff ff       	call   f0100944 <check_va2pa>
f0101e3a:	83 c4 10             	add    $0x10,%esp
f0101e3d:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e40:	74 19                	je     f0101e5b <mem_init+0xd9b>
f0101e42:	68 44 41 10 f0       	push   $0xf0104144
f0101e47:	68 a6 43 10 f0       	push   $0xf01043a6
f0101e4c:	68 5c 03 00 00       	push   $0x35c
f0101e51:	68 80 43 10 f0       	push   $0xf0104380
f0101e56:	e8 30 e2 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101e5b:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e60:	89 f8                	mov    %edi,%eax
f0101e62:	e8 dd ea ff ff       	call   f0100944 <check_va2pa>
f0101e67:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e6a:	74 19                	je     f0101e85 <mem_init+0xdc5>
f0101e6c:	68 a0 41 10 f0       	push   $0xf01041a0
f0101e71:	68 a6 43 10 f0       	push   $0xf01043a6
f0101e76:	68 5d 03 00 00       	push   $0x35d
f0101e7b:	68 80 43 10 f0       	push   $0xf0104380
f0101e80:	e8 06 e2 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 0);
f0101e85:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101e8a:	74 19                	je     f0101ea5 <mem_init+0xde5>
f0101e8c:	68 da 45 10 f0       	push   $0xf01045da
f0101e91:	68 a6 43 10 f0       	push   $0xf01043a6
f0101e96:	68 5e 03 00 00       	push   $0x35e
f0101e9b:	68 80 43 10 f0       	push   $0xf0104380
f0101ea0:	e8 e6 e1 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101ea5:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101eaa:	74 19                	je     f0101ec5 <mem_init+0xe05>
f0101eac:	68 a8 45 10 f0       	push   $0xf01045a8
f0101eb1:	68 a6 43 10 f0       	push   $0xf01043a6
f0101eb6:	68 5f 03 00 00       	push   $0x35f
f0101ebb:	68 80 43 10 f0       	push   $0xf0104380
f0101ec0:	e8 c6 e1 ff ff       	call   f010008b <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101ec5:	83 ec 0c             	sub    $0xc,%esp
f0101ec8:	6a 00                	push   $0x0
f0101eca:	e8 b0 ee ff ff       	call   f0100d7f <page_alloc>
f0101ecf:	83 c4 10             	add    $0x10,%esp
f0101ed2:	39 c3                	cmp    %eax,%ebx
f0101ed4:	75 04                	jne    f0101eda <mem_init+0xe1a>
f0101ed6:	85 c0                	test   %eax,%eax
f0101ed8:	75 19                	jne    f0101ef3 <mem_init+0xe33>
f0101eda:	68 c8 41 10 f0       	push   $0xf01041c8
f0101edf:	68 a6 43 10 f0       	push   $0xf01043a6
f0101ee4:	68 62 03 00 00       	push   $0x362
f0101ee9:	68 80 43 10 f0       	push   $0xf0104380
f0101eee:	e8 98 e1 ff ff       	call   f010008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101ef3:	83 ec 0c             	sub    $0xc,%esp
f0101ef6:	6a 00                	push   $0x0
f0101ef8:	e8 82 ee ff ff       	call   f0100d7f <page_alloc>
f0101efd:	83 c4 10             	add    $0x10,%esp
f0101f00:	85 c0                	test   %eax,%eax
f0101f02:	74 19                	je     f0101f1d <mem_init+0xe5d>
f0101f04:	68 fc 44 10 f0       	push   $0xf01044fc
f0101f09:	68 a6 43 10 f0       	push   $0xf01043a6
f0101f0e:	68 65 03 00 00       	push   $0x365
f0101f13:	68 80 43 10 f0       	push   $0xf0104380
f0101f18:	e8 6e e1 ff ff       	call   f010008b <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101f1d:	8b 0d 6c 69 11 f0    	mov    0xf011696c,%ecx
f0101f23:	8b 11                	mov    (%ecx),%edx
f0101f25:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101f2b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f2e:	2b 05 70 69 11 f0    	sub    0xf0116970,%eax
f0101f34:	c1 f8 03             	sar    $0x3,%eax
f0101f37:	c1 e0 0c             	shl    $0xc,%eax
f0101f3a:	39 c2                	cmp    %eax,%edx
f0101f3c:	74 19                	je     f0101f57 <mem_init+0xe97>
f0101f3e:	68 6c 3e 10 f0       	push   $0xf0103e6c
f0101f43:	68 a6 43 10 f0       	push   $0xf01043a6
f0101f48:	68 68 03 00 00       	push   $0x368
f0101f4d:	68 80 43 10 f0       	push   $0xf0104380
f0101f52:	e8 34 e1 ff ff       	call   f010008b <_panic>
	kern_pgdir[0] = 0;
f0101f57:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0101f5d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f60:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101f65:	74 19                	je     f0101f80 <mem_init+0xec0>
f0101f67:	68 5f 45 10 f0       	push   $0xf010455f
f0101f6c:	68 a6 43 10 f0       	push   $0xf01043a6
f0101f71:	68 6a 03 00 00       	push   $0x36a
f0101f76:	68 80 43 10 f0       	push   $0xf0104380
f0101f7b:	e8 0b e1 ff ff       	call   f010008b <_panic>
	pp0->pp_ref = 0;
f0101f80:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f83:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0101f89:	83 ec 0c             	sub    $0xc,%esp
f0101f8c:	50                   	push   %eax
f0101f8d:	e8 5d ee ff ff       	call   f0100def <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0101f92:	83 c4 0c             	add    $0xc,%esp
f0101f95:	6a 01                	push   $0x1
f0101f97:	68 00 10 40 00       	push   $0x401000
f0101f9c:	ff 35 6c 69 11 f0    	pushl  0xf011696c
f0101fa2:	e8 ed ee ff ff       	call   f0100e94 <pgdir_walk>
f0101fa7:	89 c7                	mov    %eax,%edi
f0101fa9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0101fac:	a1 6c 69 11 f0       	mov    0xf011696c,%eax
f0101fb1:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101fb4:	8b 40 04             	mov    0x4(%eax),%eax
f0101fb7:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101fbc:	8b 0d 68 69 11 f0    	mov    0xf0116968,%ecx
f0101fc2:	89 c2                	mov    %eax,%edx
f0101fc4:	c1 ea 0c             	shr    $0xc,%edx
f0101fc7:	83 c4 10             	add    $0x10,%esp
f0101fca:	39 ca                	cmp    %ecx,%edx
f0101fcc:	72 15                	jb     f0101fe3 <mem_init+0xf23>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101fce:	50                   	push   %eax
f0101fcf:	68 e4 3b 10 f0       	push   $0xf0103be4
f0101fd4:	68 71 03 00 00       	push   $0x371
f0101fd9:	68 80 43 10 f0       	push   $0xf0104380
f0101fde:	e8 a8 e0 ff ff       	call   f010008b <_panic>
	assert(ptep == ptep1 + PTX(va));
f0101fe3:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f0101fe8:	39 c7                	cmp    %eax,%edi
f0101fea:	74 19                	je     f0102005 <mem_init+0xf45>
f0101fec:	68 eb 45 10 f0       	push   $0xf01045eb
f0101ff1:	68 a6 43 10 f0       	push   $0xf01043a6
f0101ff6:	68 72 03 00 00       	push   $0x372
f0101ffb:	68 80 43 10 f0       	push   $0xf0104380
f0102000:	e8 86 e0 ff ff       	call   f010008b <_panic>
	kern_pgdir[PDX(va)] = 0;
f0102005:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102008:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f010200f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102012:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102018:	2b 05 70 69 11 f0    	sub    0xf0116970,%eax
f010201e:	c1 f8 03             	sar    $0x3,%eax
f0102021:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102024:	89 c2                	mov    %eax,%edx
f0102026:	c1 ea 0c             	shr    $0xc,%edx
f0102029:	39 d1                	cmp    %edx,%ecx
f010202b:	77 12                	ja     f010203f <mem_init+0xf7f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010202d:	50                   	push   %eax
f010202e:	68 e4 3b 10 f0       	push   $0xf0103be4
f0102033:	6a 53                	push   $0x53
f0102035:	68 8c 43 10 f0       	push   $0xf010438c
f010203a:	e8 4c e0 ff ff       	call   f010008b <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f010203f:	83 ec 04             	sub    $0x4,%esp
f0102042:	68 00 10 00 00       	push   $0x1000
f0102047:	68 ff 00 00 00       	push   $0xff
f010204c:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102051:	50                   	push   %eax
f0102052:	e8 cb 11 00 00       	call   f0103222 <memset>
	page_free(pp0);
f0102057:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010205a:	89 3c 24             	mov    %edi,(%esp)
f010205d:	e8 8d ed ff ff       	call   f0100def <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0102062:	83 c4 0c             	add    $0xc,%esp
f0102065:	6a 01                	push   $0x1
f0102067:	6a 00                	push   $0x0
f0102069:	ff 35 6c 69 11 f0    	pushl  0xf011696c
f010206f:	e8 20 ee ff ff       	call   f0100e94 <pgdir_walk>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102074:	89 fa                	mov    %edi,%edx
f0102076:	2b 15 70 69 11 f0    	sub    0xf0116970,%edx
f010207c:	c1 fa 03             	sar    $0x3,%edx
f010207f:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102082:	89 d0                	mov    %edx,%eax
f0102084:	c1 e8 0c             	shr    $0xc,%eax
f0102087:	83 c4 10             	add    $0x10,%esp
f010208a:	3b 05 68 69 11 f0    	cmp    0xf0116968,%eax
f0102090:	72 12                	jb     f01020a4 <mem_init+0xfe4>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102092:	52                   	push   %edx
f0102093:	68 e4 3b 10 f0       	push   $0xf0103be4
f0102098:	6a 53                	push   $0x53
f010209a:	68 8c 43 10 f0       	push   $0xf010438c
f010209f:	e8 e7 df ff ff       	call   f010008b <_panic>
	return (void *)(pa + KERNBASE);
f01020a4:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f01020aa:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01020ad:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f01020b3:	f6 00 01             	testb  $0x1,(%eax)
f01020b6:	74 19                	je     f01020d1 <mem_init+0x1011>
f01020b8:	68 03 46 10 f0       	push   $0xf0104603
f01020bd:	68 a6 43 10 f0       	push   $0xf01043a6
f01020c2:	68 7c 03 00 00       	push   $0x37c
f01020c7:	68 80 43 10 f0       	push   $0xf0104380
f01020cc:	e8 ba df ff ff       	call   f010008b <_panic>
f01020d1:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f01020d4:	39 d0                	cmp    %edx,%eax
f01020d6:	75 db                	jne    f01020b3 <mem_init+0xff3>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f01020d8:	a1 6c 69 11 f0       	mov    0xf011696c,%eax
f01020dd:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f01020e3:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01020e6:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f01020ec:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f01020ef:	89 0d 3c 65 11 f0    	mov    %ecx,0xf011653c

	// free the pages we took
	page_free(pp0);
f01020f5:	83 ec 0c             	sub    $0xc,%esp
f01020f8:	50                   	push   %eax
f01020f9:	e8 f1 ec ff ff       	call   f0100def <page_free>
	page_free(pp1);
f01020fe:	89 1c 24             	mov    %ebx,(%esp)
f0102101:	e8 e9 ec ff ff       	call   f0100def <page_free>
	page_free(pp2);
f0102106:	89 34 24             	mov    %esi,(%esp)
f0102109:	e8 e1 ec ff ff       	call   f0100def <page_free>

	cprintf("check_page() succeeded!\n");
f010210e:	c7 04 24 1a 46 10 f0 	movl   $0xf010461a,(%esp)
f0102115:	e8 4f 06 00 00       	call   f0102769 <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, (uintptr_t) UPAGES, npages*sizeof(struct PageInfo), PADDR(pages), PTE_U);
f010211a:	a1 70 69 11 f0       	mov    0xf0116970,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010211f:	83 c4 10             	add    $0x10,%esp
f0102122:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102127:	77 15                	ja     f010213e <mem_init+0x107e>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102129:	50                   	push   %eax
f010212a:	68 f0 3c 10 f0       	push   $0xf0103cf0
f010212f:	68 b6 00 00 00       	push   $0xb6
f0102134:	68 80 43 10 f0       	push   $0xf0104380
f0102139:	e8 4d df ff ff       	call   f010008b <_panic>
f010213e:	8b 0d 68 69 11 f0    	mov    0xf0116968,%ecx
f0102144:	c1 e1 03             	shl    $0x3,%ecx
f0102147:	83 ec 08             	sub    $0x8,%esp
f010214a:	6a 04                	push   $0x4
f010214c:	05 00 00 00 10       	add    $0x10000000,%eax
f0102151:	50                   	push   %eax
f0102152:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102157:	a1 6c 69 11 f0       	mov    0xf011696c,%eax
f010215c:	e8 0c ee ff ff       	call   f0100f6d <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102161:	83 c4 10             	add    $0x10,%esp
f0102164:	b8 00 c0 10 f0       	mov    $0xf010c000,%eax
f0102169:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010216e:	77 15                	ja     f0102185 <mem_init+0x10c5>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102170:	50                   	push   %eax
f0102171:	68 f0 3c 10 f0       	push   $0xf0103cf0
f0102176:	68 c3 00 00 00       	push   $0xc3
f010217b:	68 80 43 10 f0       	push   $0xf0104380
f0102180:	e8 06 df ff ff       	call   f010008b <_panic>
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:

	boot_map_region(kern_pgdir, (uintptr_t) (KSTACKTOP-KSTKSIZE), KSTKSIZE, PADDR(bootstack), PTE_W);
f0102185:	83 ec 08             	sub    $0x8,%esp
f0102188:	6a 02                	push   $0x2
f010218a:	68 00 c0 10 00       	push   $0x10c000
f010218f:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102194:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f0102199:	a1 6c 69 11 f0       	mov    0xf011696c,%eax
f010219e:	e8 ca ed ff ff       	call   f0100f6d <boot_map_region>
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, (uintptr_t) KERNBASE, ROUNDUP(0xffffffff - KERNBASE, PGSIZE), 0, PTE_W);
f01021a3:	83 c4 08             	add    $0x8,%esp
f01021a6:	6a 02                	push   $0x2
f01021a8:	6a 00                	push   $0x0
f01021aa:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f01021af:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f01021b4:	a1 6c 69 11 f0       	mov    0xf011696c,%eax
f01021b9:	e8 af ed ff ff       	call   f0100f6d <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f01021be:	8b 35 6c 69 11 f0    	mov    0xf011696c,%esi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f01021c4:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f01021c9:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01021cc:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f01021d3:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01021d8:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01021db:	8b 3d 70 69 11 f0    	mov    0xf0116970,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01021e1:	89 7d d0             	mov    %edi,-0x30(%ebp)
f01021e4:	83 c4 10             	add    $0x10,%esp

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01021e7:	bb 00 00 00 00       	mov    $0x0,%ebx
f01021ec:	eb 55                	jmp    f0102243 <mem_init+0x1183>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01021ee:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
f01021f4:	89 f0                	mov    %esi,%eax
f01021f6:	e8 49 e7 ff ff       	call   f0100944 <check_va2pa>
f01021fb:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f0102202:	77 15                	ja     f0102219 <mem_init+0x1159>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102204:	57                   	push   %edi
f0102205:	68 f0 3c 10 f0       	push   $0xf0103cf0
f010220a:	68 be 02 00 00       	push   $0x2be
f010220f:	68 80 43 10 f0       	push   $0xf0104380
f0102214:	e8 72 de ff ff       	call   f010008b <_panic>
f0102219:	8d 94 1f 00 00 00 10 	lea    0x10000000(%edi,%ebx,1),%edx
f0102220:	39 c2                	cmp    %eax,%edx
f0102222:	74 19                	je     f010223d <mem_init+0x117d>
f0102224:	68 ec 41 10 f0       	push   $0xf01041ec
f0102229:	68 a6 43 10 f0       	push   $0xf01043a6
f010222e:	68 be 02 00 00       	push   $0x2be
f0102233:	68 80 43 10 f0       	push   $0xf0104380
f0102238:	e8 4e de ff ff       	call   f010008b <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f010223d:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102243:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0102246:	77 a6                	ja     f01021ee <mem_init+0x112e>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102248:	8b 7d cc             	mov    -0x34(%ebp),%edi
f010224b:	c1 e7 0c             	shl    $0xc,%edi
f010224e:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102253:	eb 30                	jmp    f0102285 <mem_init+0x11c5>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102255:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
f010225b:	89 f0                	mov    %esi,%eax
f010225d:	e8 e2 e6 ff ff       	call   f0100944 <check_va2pa>
f0102262:	39 c3                	cmp    %eax,%ebx
f0102264:	74 19                	je     f010227f <mem_init+0x11bf>
f0102266:	68 20 42 10 f0       	push   $0xf0104220
f010226b:	68 a6 43 10 f0       	push   $0xf01043a6
f0102270:	68 c3 02 00 00       	push   $0x2c3
f0102275:	68 80 43 10 f0       	push   $0xf0104380
f010227a:	e8 0c de ff ff       	call   f010008b <_panic>
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f010227f:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102285:	39 fb                	cmp    %edi,%ebx
f0102287:	72 cc                	jb     f0102255 <mem_init+0x1195>
f0102289:	bb 00 80 ff ef       	mov    $0xefff8000,%ebx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f010228e:	89 da                	mov    %ebx,%edx
f0102290:	89 f0                	mov    %esi,%eax
f0102292:	e8 ad e6 ff ff       	call   f0100944 <check_va2pa>
f0102297:	8d 93 00 40 11 10    	lea    0x10114000(%ebx),%edx
f010229d:	39 c2                	cmp    %eax,%edx
f010229f:	74 19                	je     f01022ba <mem_init+0x11fa>
f01022a1:	68 48 42 10 f0       	push   $0xf0104248
f01022a6:	68 a6 43 10 f0       	push   $0xf01043a6
f01022ab:	68 c7 02 00 00       	push   $0x2c7
f01022b0:	68 80 43 10 f0       	push   $0xf0104380
f01022b5:	e8 d1 dd ff ff       	call   f010008b <_panic>
f01022ba:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f01022c0:	81 fb 00 00 00 f0    	cmp    $0xf0000000,%ebx
f01022c6:	75 c6                	jne    f010228e <mem_init+0x11ce>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f01022c8:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f01022cd:	89 f0                	mov    %esi,%eax
f01022cf:	e8 70 e6 ff ff       	call   f0100944 <check_va2pa>
f01022d4:	83 f8 ff             	cmp    $0xffffffff,%eax
f01022d7:	74 51                	je     f010232a <mem_init+0x126a>
f01022d9:	68 90 42 10 f0       	push   $0xf0104290
f01022de:	68 a6 43 10 f0       	push   $0xf01043a6
f01022e3:	68 c8 02 00 00       	push   $0x2c8
f01022e8:	68 80 43 10 f0       	push   $0xf0104380
f01022ed:	e8 99 dd ff ff       	call   f010008b <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f01022f2:	3d bc 03 00 00       	cmp    $0x3bc,%eax
f01022f7:	72 36                	jb     f010232f <mem_init+0x126f>
f01022f9:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f01022fe:	76 07                	jbe    f0102307 <mem_init+0x1247>
f0102300:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102305:	75 28                	jne    f010232f <mem_init+0x126f>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
f0102307:	f6 04 86 01          	testb  $0x1,(%esi,%eax,4)
f010230b:	0f 85 83 00 00 00    	jne    f0102394 <mem_init+0x12d4>
f0102311:	68 33 46 10 f0       	push   $0xf0104633
f0102316:	68 a6 43 10 f0       	push   $0xf01043a6
f010231b:	68 d0 02 00 00       	push   $0x2d0
f0102320:	68 80 43 10 f0       	push   $0xf0104380
f0102325:	e8 61 dd ff ff       	call   f010008b <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f010232a:	b8 00 00 00 00       	mov    $0x0,%eax
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f010232f:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102334:	76 3f                	jbe    f0102375 <mem_init+0x12b5>
				assert(pgdir[i] & PTE_P);
f0102336:	8b 14 86             	mov    (%esi,%eax,4),%edx
f0102339:	f6 c2 01             	test   $0x1,%dl
f010233c:	75 19                	jne    f0102357 <mem_init+0x1297>
f010233e:	68 33 46 10 f0       	push   $0xf0104633
f0102343:	68 a6 43 10 f0       	push   $0xf01043a6
f0102348:	68 d4 02 00 00       	push   $0x2d4
f010234d:	68 80 43 10 f0       	push   $0xf0104380
f0102352:	e8 34 dd ff ff       	call   f010008b <_panic>
				assert(pgdir[i] & PTE_W);
f0102357:	f6 c2 02             	test   $0x2,%dl
f010235a:	75 38                	jne    f0102394 <mem_init+0x12d4>
f010235c:	68 44 46 10 f0       	push   $0xf0104644
f0102361:	68 a6 43 10 f0       	push   $0xf01043a6
f0102366:	68 d5 02 00 00       	push   $0x2d5
f010236b:	68 80 43 10 f0       	push   $0xf0104380
f0102370:	e8 16 dd ff ff       	call   f010008b <_panic>
			} else
				assert(pgdir[i] == 0);
f0102375:	83 3c 86 00          	cmpl   $0x0,(%esi,%eax,4)
f0102379:	74 19                	je     f0102394 <mem_init+0x12d4>
f010237b:	68 55 46 10 f0       	push   $0xf0104655
f0102380:	68 a6 43 10 f0       	push   $0xf01043a6
f0102385:	68 d7 02 00 00       	push   $0x2d7
f010238a:	68 80 43 10 f0       	push   $0xf0104380
f010238f:	e8 f7 dc ff ff       	call   f010008b <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0102394:	83 c0 01             	add    $0x1,%eax
f0102397:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f010239c:	0f 86 50 ff ff ff    	jbe    f01022f2 <mem_init+0x1232>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f01023a2:	83 ec 0c             	sub    $0xc,%esp
f01023a5:	68 c0 42 10 f0       	push   $0xf01042c0
f01023aa:	e8 ba 03 00 00       	call   f0102769 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f01023af:	a1 6c 69 11 f0       	mov    0xf011696c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01023b4:	83 c4 10             	add    $0x10,%esp
f01023b7:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01023bc:	77 15                	ja     f01023d3 <mem_init+0x1313>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01023be:	50                   	push   %eax
f01023bf:	68 f0 3c 10 f0       	push   $0xf0103cf0
f01023c4:	68 dc 00 00 00       	push   $0xdc
f01023c9:	68 80 43 10 f0       	push   $0xf0104380
f01023ce:	e8 b8 dc ff ff       	call   f010008b <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f01023d3:	05 00 00 00 10       	add    $0x10000000,%eax
f01023d8:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f01023db:	b8 00 00 00 00       	mov    $0x0,%eax
f01023e0:	e8 c3 e5 ff ff       	call   f01009a8 <check_page_free_list>

static inline uint32_t
rcr0(void)
{
	uint32_t val;
	asm volatile("movl %%cr0,%0" : "=r" (val));
f01023e5:	0f 20 c0             	mov    %cr0,%eax
f01023e8:	83 e0 f3             	and    $0xfffffff3,%eax
}

static inline void
lcr0(uint32_t val)
{
	asm volatile("movl %0,%%cr0" : : "r" (val));
f01023eb:	0d 23 00 05 80       	or     $0x80050023,%eax
f01023f0:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01023f3:	83 ec 0c             	sub    $0xc,%esp
f01023f6:	6a 00                	push   $0x0
f01023f8:	e8 82 e9 ff ff       	call   f0100d7f <page_alloc>
f01023fd:	89 c3                	mov    %eax,%ebx
f01023ff:	83 c4 10             	add    $0x10,%esp
f0102402:	85 c0                	test   %eax,%eax
f0102404:	75 19                	jne    f010241f <mem_init+0x135f>
f0102406:	68 51 44 10 f0       	push   $0xf0104451
f010240b:	68 a6 43 10 f0       	push   $0xf01043a6
f0102410:	68 97 03 00 00       	push   $0x397
f0102415:	68 80 43 10 f0       	push   $0xf0104380
f010241a:	e8 6c dc ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f010241f:	83 ec 0c             	sub    $0xc,%esp
f0102422:	6a 00                	push   $0x0
f0102424:	e8 56 e9 ff ff       	call   f0100d7f <page_alloc>
f0102429:	89 c7                	mov    %eax,%edi
f010242b:	83 c4 10             	add    $0x10,%esp
f010242e:	85 c0                	test   %eax,%eax
f0102430:	75 19                	jne    f010244b <mem_init+0x138b>
f0102432:	68 67 44 10 f0       	push   $0xf0104467
f0102437:	68 a6 43 10 f0       	push   $0xf01043a6
f010243c:	68 98 03 00 00       	push   $0x398
f0102441:	68 80 43 10 f0       	push   $0xf0104380
f0102446:	e8 40 dc ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f010244b:	83 ec 0c             	sub    $0xc,%esp
f010244e:	6a 00                	push   $0x0
f0102450:	e8 2a e9 ff ff       	call   f0100d7f <page_alloc>
f0102455:	89 c6                	mov    %eax,%esi
f0102457:	83 c4 10             	add    $0x10,%esp
f010245a:	85 c0                	test   %eax,%eax
f010245c:	75 19                	jne    f0102477 <mem_init+0x13b7>
f010245e:	68 7d 44 10 f0       	push   $0xf010447d
f0102463:	68 a6 43 10 f0       	push   $0xf01043a6
f0102468:	68 99 03 00 00       	push   $0x399
f010246d:	68 80 43 10 f0       	push   $0xf0104380
f0102472:	e8 14 dc ff ff       	call   f010008b <_panic>
	page_free(pp0);
f0102477:	83 ec 0c             	sub    $0xc,%esp
f010247a:	53                   	push   %ebx
f010247b:	e8 6f e9 ff ff       	call   f0100def <page_free>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102480:	89 f8                	mov    %edi,%eax
f0102482:	2b 05 70 69 11 f0    	sub    0xf0116970,%eax
f0102488:	c1 f8 03             	sar    $0x3,%eax
f010248b:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010248e:	89 c2                	mov    %eax,%edx
f0102490:	c1 ea 0c             	shr    $0xc,%edx
f0102493:	83 c4 10             	add    $0x10,%esp
f0102496:	3b 15 68 69 11 f0    	cmp    0xf0116968,%edx
f010249c:	72 12                	jb     f01024b0 <mem_init+0x13f0>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010249e:	50                   	push   %eax
f010249f:	68 e4 3b 10 f0       	push   $0xf0103be4
f01024a4:	6a 53                	push   $0x53
f01024a6:	68 8c 43 10 f0       	push   $0xf010438c
f01024ab:	e8 db db ff ff       	call   f010008b <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f01024b0:	83 ec 04             	sub    $0x4,%esp
f01024b3:	68 00 10 00 00       	push   $0x1000
f01024b8:	6a 01                	push   $0x1
f01024ba:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01024bf:	50                   	push   %eax
f01024c0:	e8 5d 0d 00 00       	call   f0103222 <memset>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01024c5:	89 f0                	mov    %esi,%eax
f01024c7:	2b 05 70 69 11 f0    	sub    0xf0116970,%eax
f01024cd:	c1 f8 03             	sar    $0x3,%eax
f01024d0:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01024d3:	89 c2                	mov    %eax,%edx
f01024d5:	c1 ea 0c             	shr    $0xc,%edx
f01024d8:	83 c4 10             	add    $0x10,%esp
f01024db:	3b 15 68 69 11 f0    	cmp    0xf0116968,%edx
f01024e1:	72 12                	jb     f01024f5 <mem_init+0x1435>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01024e3:	50                   	push   %eax
f01024e4:	68 e4 3b 10 f0       	push   $0xf0103be4
f01024e9:	6a 53                	push   $0x53
f01024eb:	68 8c 43 10 f0       	push   $0xf010438c
f01024f0:	e8 96 db ff ff       	call   f010008b <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f01024f5:	83 ec 04             	sub    $0x4,%esp
f01024f8:	68 00 10 00 00       	push   $0x1000
f01024fd:	6a 02                	push   $0x2
f01024ff:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102504:	50                   	push   %eax
f0102505:	e8 18 0d 00 00       	call   f0103222 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f010250a:	6a 02                	push   $0x2
f010250c:	68 00 10 00 00       	push   $0x1000
f0102511:	57                   	push   %edi
f0102512:	ff 35 6c 69 11 f0    	pushl  0xf011696c
f0102518:	e8 3d eb ff ff       	call   f010105a <page_insert>
	assert(pp1->pp_ref == 1);
f010251d:	83 c4 20             	add    $0x20,%esp
f0102520:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102525:	74 19                	je     f0102540 <mem_init+0x1480>
f0102527:	68 4e 45 10 f0       	push   $0xf010454e
f010252c:	68 a6 43 10 f0       	push   $0xf01043a6
f0102531:	68 9e 03 00 00       	push   $0x39e
f0102536:	68 80 43 10 f0       	push   $0xf0104380
f010253b:	e8 4b db ff ff       	call   f010008b <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102540:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102547:	01 01 01 
f010254a:	74 19                	je     f0102565 <mem_init+0x14a5>
f010254c:	68 e0 42 10 f0       	push   $0xf01042e0
f0102551:	68 a6 43 10 f0       	push   $0xf01043a6
f0102556:	68 9f 03 00 00       	push   $0x39f
f010255b:	68 80 43 10 f0       	push   $0xf0104380
f0102560:	e8 26 db ff ff       	call   f010008b <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102565:	6a 02                	push   $0x2
f0102567:	68 00 10 00 00       	push   $0x1000
f010256c:	56                   	push   %esi
f010256d:	ff 35 6c 69 11 f0    	pushl  0xf011696c
f0102573:	e8 e2 ea ff ff       	call   f010105a <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102578:	83 c4 10             	add    $0x10,%esp
f010257b:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102582:	02 02 02 
f0102585:	74 19                	je     f01025a0 <mem_init+0x14e0>
f0102587:	68 04 43 10 f0       	push   $0xf0104304
f010258c:	68 a6 43 10 f0       	push   $0xf01043a6
f0102591:	68 a1 03 00 00       	push   $0x3a1
f0102596:	68 80 43 10 f0       	push   $0xf0104380
f010259b:	e8 eb da ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f01025a0:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01025a5:	74 19                	je     f01025c0 <mem_init+0x1500>
f01025a7:	68 70 45 10 f0       	push   $0xf0104570
f01025ac:	68 a6 43 10 f0       	push   $0xf01043a6
f01025b1:	68 a2 03 00 00       	push   $0x3a2
f01025b6:	68 80 43 10 f0       	push   $0xf0104380
f01025bb:	e8 cb da ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 0);
f01025c0:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f01025c5:	74 19                	je     f01025e0 <mem_init+0x1520>
f01025c7:	68 da 45 10 f0       	push   $0xf01045da
f01025cc:	68 a6 43 10 f0       	push   $0xf01043a6
f01025d1:	68 a3 03 00 00       	push   $0x3a3
f01025d6:	68 80 43 10 f0       	push   $0xf0104380
f01025db:	e8 ab da ff ff       	call   f010008b <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f01025e0:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f01025e7:	03 03 03 
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01025ea:	89 f0                	mov    %esi,%eax
f01025ec:	2b 05 70 69 11 f0    	sub    0xf0116970,%eax
f01025f2:	c1 f8 03             	sar    $0x3,%eax
f01025f5:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01025f8:	89 c2                	mov    %eax,%edx
f01025fa:	c1 ea 0c             	shr    $0xc,%edx
f01025fd:	3b 15 68 69 11 f0    	cmp    0xf0116968,%edx
f0102603:	72 12                	jb     f0102617 <mem_init+0x1557>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102605:	50                   	push   %eax
f0102606:	68 e4 3b 10 f0       	push   $0xf0103be4
f010260b:	6a 53                	push   $0x53
f010260d:	68 8c 43 10 f0       	push   $0xf010438c
f0102612:	e8 74 da ff ff       	call   f010008b <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102617:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f010261e:	03 03 03 
f0102621:	74 19                	je     f010263c <mem_init+0x157c>
f0102623:	68 28 43 10 f0       	push   $0xf0104328
f0102628:	68 a6 43 10 f0       	push   $0xf01043a6
f010262d:	68 a5 03 00 00       	push   $0x3a5
f0102632:	68 80 43 10 f0       	push   $0xf0104380
f0102637:	e8 4f da ff ff       	call   f010008b <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f010263c:	83 ec 08             	sub    $0x8,%esp
f010263f:	68 00 10 00 00       	push   $0x1000
f0102644:	ff 35 6c 69 11 f0    	pushl  0xf011696c
f010264a:	e8 d0 e9 ff ff       	call   f010101f <page_remove>
	assert(pp2->pp_ref == 0);
f010264f:	83 c4 10             	add    $0x10,%esp
f0102652:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102657:	74 19                	je     f0102672 <mem_init+0x15b2>
f0102659:	68 a8 45 10 f0       	push   $0xf01045a8
f010265e:	68 a6 43 10 f0       	push   $0xf01043a6
f0102663:	68 a7 03 00 00       	push   $0x3a7
f0102668:	68 80 43 10 f0       	push   $0xf0104380
f010266d:	e8 19 da ff ff       	call   f010008b <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102672:	8b 0d 6c 69 11 f0    	mov    0xf011696c,%ecx
f0102678:	8b 11                	mov    (%ecx),%edx
f010267a:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102680:	89 d8                	mov    %ebx,%eax
f0102682:	2b 05 70 69 11 f0    	sub    0xf0116970,%eax
f0102688:	c1 f8 03             	sar    $0x3,%eax
f010268b:	c1 e0 0c             	shl    $0xc,%eax
f010268e:	39 c2                	cmp    %eax,%edx
f0102690:	74 19                	je     f01026ab <mem_init+0x15eb>
f0102692:	68 6c 3e 10 f0       	push   $0xf0103e6c
f0102697:	68 a6 43 10 f0       	push   $0xf01043a6
f010269c:	68 aa 03 00 00       	push   $0x3aa
f01026a1:	68 80 43 10 f0       	push   $0xf0104380
f01026a6:	e8 e0 d9 ff ff       	call   f010008b <_panic>
	kern_pgdir[0] = 0;
f01026ab:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f01026b1:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01026b6:	74 19                	je     f01026d1 <mem_init+0x1611>
f01026b8:	68 5f 45 10 f0       	push   $0xf010455f
f01026bd:	68 a6 43 10 f0       	push   $0xf01043a6
f01026c2:	68 ac 03 00 00       	push   $0x3ac
f01026c7:	68 80 43 10 f0       	push   $0xf0104380
f01026cc:	e8 ba d9 ff ff       	call   f010008b <_panic>
	pp0->pp_ref = 0;
f01026d1:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f01026d7:	83 ec 0c             	sub    $0xc,%esp
f01026da:	53                   	push   %ebx
f01026db:	e8 0f e7 ff ff       	call   f0100def <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f01026e0:	c7 04 24 54 43 10 f0 	movl   $0xf0104354,(%esp)
f01026e7:	e8 7d 00 00 00       	call   f0102769 <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f01026ec:	83 c4 10             	add    $0x10,%esp
f01026ef:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01026f2:	5b                   	pop    %ebx
f01026f3:	5e                   	pop    %esi
f01026f4:	5f                   	pop    %edi
f01026f5:	5d                   	pop    %ebp
f01026f6:	c3                   	ret    

f01026f7 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f01026f7:	55                   	push   %ebp
f01026f8:	89 e5                	mov    %esp,%ebp
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01026fa:	8b 45 0c             	mov    0xc(%ebp),%eax
f01026fd:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f0102700:	5d                   	pop    %ebp
f0102701:	c3                   	ret    

f0102702 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102702:	55                   	push   %ebp
f0102703:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102705:	ba 70 00 00 00       	mov    $0x70,%edx
f010270a:	8b 45 08             	mov    0x8(%ebp),%eax
f010270d:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010270e:	ba 71 00 00 00       	mov    $0x71,%edx
f0102713:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0102714:	0f b6 c0             	movzbl %al,%eax
}
f0102717:	5d                   	pop    %ebp
f0102718:	c3                   	ret    

f0102719 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102719:	55                   	push   %ebp
f010271a:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010271c:	ba 70 00 00 00       	mov    $0x70,%edx
f0102721:	8b 45 08             	mov    0x8(%ebp),%eax
f0102724:	ee                   	out    %al,(%dx)
f0102725:	ba 71 00 00 00       	mov    $0x71,%edx
f010272a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010272d:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f010272e:	5d                   	pop    %ebp
f010272f:	c3                   	ret    

f0102730 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0102730:	55                   	push   %ebp
f0102731:	89 e5                	mov    %esp,%ebp
f0102733:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0102736:	ff 75 08             	pushl  0x8(%ebp)
f0102739:	e8 c2 de ff ff       	call   f0100600 <cputchar>
	*cnt++;
}
f010273e:	83 c4 10             	add    $0x10,%esp
f0102741:	c9                   	leave  
f0102742:	c3                   	ret    

f0102743 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102743:	55                   	push   %ebp
f0102744:	89 e5                	mov    %esp,%ebp
f0102746:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0102749:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102750:	ff 75 0c             	pushl  0xc(%ebp)
f0102753:	ff 75 08             	pushl  0x8(%ebp)
f0102756:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102759:	50                   	push   %eax
f010275a:	68 30 27 10 f0       	push   $0xf0102730
f010275f:	e8 52 04 00 00       	call   f0102bb6 <vprintfmt>
	return cnt;
}
f0102764:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102767:	c9                   	leave  
f0102768:	c3                   	ret    

f0102769 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0102769:	55                   	push   %ebp
f010276a:	89 e5                	mov    %esp,%ebp
f010276c:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f010276f:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102772:	50                   	push   %eax
f0102773:	ff 75 08             	pushl  0x8(%ebp)
f0102776:	e8 c8 ff ff ff       	call   f0102743 <vcprintf>
	va_end(ap);

	return cnt;
}
f010277b:	c9                   	leave  
f010277c:	c3                   	ret    

f010277d <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f010277d:	55                   	push   %ebp
f010277e:	89 e5                	mov    %esp,%ebp
f0102780:	57                   	push   %edi
f0102781:	56                   	push   %esi
f0102782:	53                   	push   %ebx
f0102783:	83 ec 14             	sub    $0x14,%esp
f0102786:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0102789:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f010278c:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f010278f:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0102792:	8b 1a                	mov    (%edx),%ebx
f0102794:	8b 01                	mov    (%ecx),%eax
f0102796:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102799:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f01027a0:	eb 7f                	jmp    f0102821 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f01027a2:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01027a5:	01 d8                	add    %ebx,%eax
f01027a7:	89 c6                	mov    %eax,%esi
f01027a9:	c1 ee 1f             	shr    $0x1f,%esi
f01027ac:	01 c6                	add    %eax,%esi
f01027ae:	d1 fe                	sar    %esi
f01027b0:	8d 04 76             	lea    (%esi,%esi,2),%eax
f01027b3:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01027b6:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f01027b9:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01027bb:	eb 03                	jmp    f01027c0 <stab_binsearch+0x43>
			m--;
f01027bd:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01027c0:	39 c3                	cmp    %eax,%ebx
f01027c2:	7f 0d                	jg     f01027d1 <stab_binsearch+0x54>
f01027c4:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01027c8:	83 ea 0c             	sub    $0xc,%edx
f01027cb:	39 f9                	cmp    %edi,%ecx
f01027cd:	75 ee                	jne    f01027bd <stab_binsearch+0x40>
f01027cf:	eb 05                	jmp    f01027d6 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f01027d1:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f01027d4:	eb 4b                	jmp    f0102821 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01027d6:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01027d9:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01027dc:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f01027e0:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01027e3:	76 11                	jbe    f01027f6 <stab_binsearch+0x79>
			*region_left = m;
f01027e5:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01027e8:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f01027ea:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01027ed:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01027f4:	eb 2b                	jmp    f0102821 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f01027f6:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01027f9:	73 14                	jae    f010280f <stab_binsearch+0x92>
			*region_right = m - 1;
f01027fb:	83 e8 01             	sub    $0x1,%eax
f01027fe:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102801:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0102804:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102806:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f010280d:	eb 12                	jmp    f0102821 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f010280f:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0102812:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0102814:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0102818:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010281a:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0102821:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0102824:	0f 8e 78 ff ff ff    	jle    f01027a2 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f010282a:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f010282e:	75 0f                	jne    f010283f <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f0102830:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102833:	8b 00                	mov    (%eax),%eax
f0102835:	83 e8 01             	sub    $0x1,%eax
f0102838:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010283b:	89 06                	mov    %eax,(%esi)
f010283d:	eb 2c                	jmp    f010286b <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010283f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102842:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0102844:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0102847:	8b 0e                	mov    (%esi),%ecx
f0102849:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010284c:	8b 75 ec             	mov    -0x14(%ebp),%esi
f010284f:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102852:	eb 03                	jmp    f0102857 <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0102854:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102857:	39 c8                	cmp    %ecx,%eax
f0102859:	7e 0b                	jle    f0102866 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f010285b:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f010285f:	83 ea 0c             	sub    $0xc,%edx
f0102862:	39 df                	cmp    %ebx,%edi
f0102864:	75 ee                	jne    f0102854 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f0102866:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0102869:	89 06                	mov    %eax,(%esi)
	}
}
f010286b:	83 c4 14             	add    $0x14,%esp
f010286e:	5b                   	pop    %ebx
f010286f:	5e                   	pop    %esi
f0102870:	5f                   	pop    %edi
f0102871:	5d                   	pop    %ebp
f0102872:	c3                   	ret    

f0102873 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0102873:	55                   	push   %ebp
f0102874:	89 e5                	mov    %esp,%ebp
f0102876:	57                   	push   %edi
f0102877:	56                   	push   %esi
f0102878:	53                   	push   %ebx
f0102879:	83 ec 3c             	sub    $0x3c,%esp
f010287c:	8b 75 08             	mov    0x8(%ebp),%esi
f010287f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0102882:	c7 03 63 46 10 f0    	movl   $0xf0104663,(%ebx)
	info->eip_line = 0;
f0102888:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f010288f:	c7 43 08 63 46 10 f0 	movl   $0xf0104663,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0102896:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f010289d:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f01028a0:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f01028a7:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f01028ad:	76 11                	jbe    f01028c0 <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01028af:	b8 de bf 10 f0       	mov    $0xf010bfde,%eax
f01028b4:	3d f1 a1 10 f0       	cmp    $0xf010a1f1,%eax
f01028b9:	77 19                	ja     f01028d4 <debuginfo_eip+0x61>
f01028bb:	e9 aa 01 00 00       	jmp    f0102a6a <debuginfo_eip+0x1f7>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f01028c0:	83 ec 04             	sub    $0x4,%esp
f01028c3:	68 6d 46 10 f0       	push   $0xf010466d
f01028c8:	6a 7f                	push   $0x7f
f01028ca:	68 7a 46 10 f0       	push   $0xf010467a
f01028cf:	e8 b7 d7 ff ff       	call   f010008b <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01028d4:	80 3d dd bf 10 f0 00 	cmpb   $0x0,0xf010bfdd
f01028db:	0f 85 90 01 00 00    	jne    f0102a71 <debuginfo_eip+0x1fe>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f01028e1:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f01028e8:	b8 f0 a1 10 f0       	mov    $0xf010a1f0,%eax
f01028ed:	2d 98 48 10 f0       	sub    $0xf0104898,%eax
f01028f2:	c1 f8 02             	sar    $0x2,%eax
f01028f5:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f01028fb:	83 e8 01             	sub    $0x1,%eax
f01028fe:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0102901:	83 ec 08             	sub    $0x8,%esp
f0102904:	56                   	push   %esi
f0102905:	6a 64                	push   $0x64
f0102907:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f010290a:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f010290d:	b8 98 48 10 f0       	mov    $0xf0104898,%eax
f0102912:	e8 66 fe ff ff       	call   f010277d <stab_binsearch>
	if (lfile == 0)
f0102917:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010291a:	83 c4 10             	add    $0x10,%esp
f010291d:	85 c0                	test   %eax,%eax
f010291f:	0f 84 53 01 00 00    	je     f0102a78 <debuginfo_eip+0x205>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0102925:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0102928:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010292b:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f010292e:	83 ec 08             	sub    $0x8,%esp
f0102931:	56                   	push   %esi
f0102932:	6a 24                	push   $0x24
f0102934:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0102937:	8d 55 dc             	lea    -0x24(%ebp),%edx
f010293a:	b8 98 48 10 f0       	mov    $0xf0104898,%eax
f010293f:	e8 39 fe ff ff       	call   f010277d <stab_binsearch>

	if (lfun <= rfun) {
f0102944:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0102947:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010294a:	83 c4 10             	add    $0x10,%esp
f010294d:	39 d0                	cmp    %edx,%eax
f010294f:	7f 40                	jg     f0102991 <debuginfo_eip+0x11e>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0102951:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f0102954:	c1 e1 02             	shl    $0x2,%ecx
f0102957:	8d b9 98 48 10 f0    	lea    -0xfefb768(%ecx),%edi
f010295d:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f0102960:	8b b9 98 48 10 f0    	mov    -0xfefb768(%ecx),%edi
f0102966:	b9 de bf 10 f0       	mov    $0xf010bfde,%ecx
f010296b:	81 e9 f1 a1 10 f0    	sub    $0xf010a1f1,%ecx
f0102971:	39 cf                	cmp    %ecx,%edi
f0102973:	73 09                	jae    f010297e <debuginfo_eip+0x10b>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0102975:	81 c7 f1 a1 10 f0    	add    $0xf010a1f1,%edi
f010297b:	89 7b 08             	mov    %edi,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f010297e:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0102981:	8b 4f 08             	mov    0x8(%edi),%ecx
f0102984:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0102987:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0102989:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f010298c:	89 55 d0             	mov    %edx,-0x30(%ebp)
f010298f:	eb 0f                	jmp    f01029a0 <debuginfo_eip+0x12d>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0102991:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0102994:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102997:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f010299a:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010299d:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f01029a0:	83 ec 08             	sub    $0x8,%esp
f01029a3:	6a 3a                	push   $0x3a
f01029a5:	ff 73 08             	pushl  0x8(%ebx)
f01029a8:	e8 59 08 00 00       	call   f0103206 <strfind>
f01029ad:	2b 43 08             	sub    0x8(%ebx),%eax
f01029b0:	89 43 0c             	mov    %eax,0xc(%ebx)

	// Search within [lline, rline] for the line number stab.
	// If found, set info->eip_line to the right line number.
	// If not found, return -1.
	//
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f01029b3:	83 c4 08             	add    $0x8,%esp
f01029b6:	56                   	push   %esi
f01029b7:	6a 44                	push   $0x44
f01029b9:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f01029bc:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f01029bf:	b8 98 48 10 f0       	mov    $0xf0104898,%eax
f01029c4:	e8 b4 fd ff ff       	call   f010277d <stab_binsearch>
    if (lline <= rline) {
f01029c9:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01029cc:	83 c4 10             	add    $0x10,%esp
f01029cf:	3b 55 d0             	cmp    -0x30(%ebp),%edx
f01029d2:	0f 8f a7 00 00 00    	jg     f0102a7f <debuginfo_eip+0x20c>
        info->eip_line = stabs[lline].n_desc;
f01029d8:	8d 04 52             	lea    (%edx,%edx,2),%eax
f01029db:	8d 04 85 98 48 10 f0 	lea    -0xfefb768(,%eax,4),%eax
f01029e2:	0f b7 48 06          	movzwl 0x6(%eax),%ecx
f01029e6:	89 4b 04             	mov    %ecx,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01029e9:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01029ec:	eb 06                	jmp    f01029f4 <debuginfo_eip+0x181>
f01029ee:	83 ea 01             	sub    $0x1,%edx
f01029f1:	83 e8 0c             	sub    $0xc,%eax
f01029f4:	39 d6                	cmp    %edx,%esi
f01029f6:	7f 34                	jg     f0102a2c <debuginfo_eip+0x1b9>
	       && stabs[lline].n_type != N_SOL
f01029f8:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f01029fc:	80 f9 84             	cmp    $0x84,%cl
f01029ff:	74 0b                	je     f0102a0c <debuginfo_eip+0x199>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0102a01:	80 f9 64             	cmp    $0x64,%cl
f0102a04:	75 e8                	jne    f01029ee <debuginfo_eip+0x17b>
f0102a06:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0102a0a:	74 e2                	je     f01029ee <debuginfo_eip+0x17b>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0102a0c:	8d 04 52             	lea    (%edx,%edx,2),%eax
f0102a0f:	8b 14 85 98 48 10 f0 	mov    -0xfefb768(,%eax,4),%edx
f0102a16:	b8 de bf 10 f0       	mov    $0xf010bfde,%eax
f0102a1b:	2d f1 a1 10 f0       	sub    $0xf010a1f1,%eax
f0102a20:	39 c2                	cmp    %eax,%edx
f0102a22:	73 08                	jae    f0102a2c <debuginfo_eip+0x1b9>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0102a24:	81 c2 f1 a1 10 f0    	add    $0xf010a1f1,%edx
f0102a2a:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0102a2c:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102a2f:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102a32:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0102a37:	39 f2                	cmp    %esi,%edx
f0102a39:	7d 50                	jge    f0102a8b <debuginfo_eip+0x218>
		for (lline = lfun + 1;
f0102a3b:	83 c2 01             	add    $0x1,%edx
f0102a3e:	89 d0                	mov    %edx,%eax
f0102a40:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0102a43:	8d 14 95 98 48 10 f0 	lea    -0xfefb768(,%edx,4),%edx
f0102a4a:	eb 04                	jmp    f0102a50 <debuginfo_eip+0x1dd>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0102a4c:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0102a50:	39 c6                	cmp    %eax,%esi
f0102a52:	7e 32                	jle    f0102a86 <debuginfo_eip+0x213>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0102a54:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0102a58:	83 c0 01             	add    $0x1,%eax
f0102a5b:	83 c2 0c             	add    $0xc,%edx
f0102a5e:	80 f9 a0             	cmp    $0xa0,%cl
f0102a61:	74 e9                	je     f0102a4c <debuginfo_eip+0x1d9>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102a63:	b8 00 00 00 00       	mov    $0x0,%eax
f0102a68:	eb 21                	jmp    f0102a8b <debuginfo_eip+0x218>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0102a6a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102a6f:	eb 1a                	jmp    f0102a8b <debuginfo_eip+0x218>
f0102a71:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102a76:	eb 13                	jmp    f0102a8b <debuginfo_eip+0x218>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0102a78:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102a7d:	eb 0c                	jmp    f0102a8b <debuginfo_eip+0x218>
	//
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
    if (lline <= rline) {
        info->eip_line = stabs[lline].n_desc;
    } else {
        return -1;
f0102a7f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102a84:	eb 05                	jmp    f0102a8b <debuginfo_eip+0x218>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102a86:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102a8b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102a8e:	5b                   	pop    %ebx
f0102a8f:	5e                   	pop    %esi
f0102a90:	5f                   	pop    %edi
f0102a91:	5d                   	pop    %ebp
f0102a92:	c3                   	ret    

f0102a93 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0102a93:	55                   	push   %ebp
f0102a94:	89 e5                	mov    %esp,%ebp
f0102a96:	57                   	push   %edi
f0102a97:	56                   	push   %esi
f0102a98:	53                   	push   %ebx
f0102a99:	83 ec 1c             	sub    $0x1c,%esp
f0102a9c:	89 c7                	mov    %eax,%edi
f0102a9e:	89 d6                	mov    %edx,%esi
f0102aa0:	8b 45 08             	mov    0x8(%ebp),%eax
f0102aa3:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102aa6:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102aa9:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0102aac:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0102aaf:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102ab4:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0102ab7:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0102aba:	39 d3                	cmp    %edx,%ebx
f0102abc:	72 05                	jb     f0102ac3 <printnum+0x30>
f0102abe:	39 45 10             	cmp    %eax,0x10(%ebp)
f0102ac1:	77 45                	ja     f0102b08 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0102ac3:	83 ec 0c             	sub    $0xc,%esp
f0102ac6:	ff 75 18             	pushl  0x18(%ebp)
f0102ac9:	8b 45 14             	mov    0x14(%ebp),%eax
f0102acc:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0102acf:	53                   	push   %ebx
f0102ad0:	ff 75 10             	pushl  0x10(%ebp)
f0102ad3:	83 ec 08             	sub    $0x8,%esp
f0102ad6:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102ad9:	ff 75 e0             	pushl  -0x20(%ebp)
f0102adc:	ff 75 dc             	pushl  -0x24(%ebp)
f0102adf:	ff 75 d8             	pushl  -0x28(%ebp)
f0102ae2:	e8 49 09 00 00       	call   f0103430 <__udivdi3>
f0102ae7:	83 c4 18             	add    $0x18,%esp
f0102aea:	52                   	push   %edx
f0102aeb:	50                   	push   %eax
f0102aec:	89 f2                	mov    %esi,%edx
f0102aee:	89 f8                	mov    %edi,%eax
f0102af0:	e8 9e ff ff ff       	call   f0102a93 <printnum>
f0102af5:	83 c4 20             	add    $0x20,%esp
f0102af8:	eb 18                	jmp    f0102b12 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0102afa:	83 ec 08             	sub    $0x8,%esp
f0102afd:	56                   	push   %esi
f0102afe:	ff 75 18             	pushl  0x18(%ebp)
f0102b01:	ff d7                	call   *%edi
f0102b03:	83 c4 10             	add    $0x10,%esp
f0102b06:	eb 03                	jmp    f0102b0b <printnum+0x78>
f0102b08:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0102b0b:	83 eb 01             	sub    $0x1,%ebx
f0102b0e:	85 db                	test   %ebx,%ebx
f0102b10:	7f e8                	jg     f0102afa <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0102b12:	83 ec 08             	sub    $0x8,%esp
f0102b15:	56                   	push   %esi
f0102b16:	83 ec 04             	sub    $0x4,%esp
f0102b19:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102b1c:	ff 75 e0             	pushl  -0x20(%ebp)
f0102b1f:	ff 75 dc             	pushl  -0x24(%ebp)
f0102b22:	ff 75 d8             	pushl  -0x28(%ebp)
f0102b25:	e8 36 0a 00 00       	call   f0103560 <__umoddi3>
f0102b2a:	83 c4 14             	add    $0x14,%esp
f0102b2d:	0f be 80 88 46 10 f0 	movsbl -0xfefb978(%eax),%eax
f0102b34:	50                   	push   %eax
f0102b35:	ff d7                	call   *%edi
}
f0102b37:	83 c4 10             	add    $0x10,%esp
f0102b3a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102b3d:	5b                   	pop    %ebx
f0102b3e:	5e                   	pop    %esi
f0102b3f:	5f                   	pop    %edi
f0102b40:	5d                   	pop    %ebp
f0102b41:	c3                   	ret    

f0102b42 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0102b42:	55                   	push   %ebp
f0102b43:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0102b45:	83 fa 01             	cmp    $0x1,%edx
f0102b48:	7e 0e                	jle    f0102b58 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0102b4a:	8b 10                	mov    (%eax),%edx
f0102b4c:	8d 4a 08             	lea    0x8(%edx),%ecx
f0102b4f:	89 08                	mov    %ecx,(%eax)
f0102b51:	8b 02                	mov    (%edx),%eax
f0102b53:	8b 52 04             	mov    0x4(%edx),%edx
f0102b56:	eb 22                	jmp    f0102b7a <getuint+0x38>
	else if (lflag)
f0102b58:	85 d2                	test   %edx,%edx
f0102b5a:	74 10                	je     f0102b6c <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0102b5c:	8b 10                	mov    (%eax),%edx
f0102b5e:	8d 4a 04             	lea    0x4(%edx),%ecx
f0102b61:	89 08                	mov    %ecx,(%eax)
f0102b63:	8b 02                	mov    (%edx),%eax
f0102b65:	ba 00 00 00 00       	mov    $0x0,%edx
f0102b6a:	eb 0e                	jmp    f0102b7a <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0102b6c:	8b 10                	mov    (%eax),%edx
f0102b6e:	8d 4a 04             	lea    0x4(%edx),%ecx
f0102b71:	89 08                	mov    %ecx,(%eax)
f0102b73:	8b 02                	mov    (%edx),%eax
f0102b75:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0102b7a:	5d                   	pop    %ebp
f0102b7b:	c3                   	ret    

f0102b7c <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0102b7c:	55                   	push   %ebp
f0102b7d:	89 e5                	mov    %esp,%ebp
f0102b7f:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0102b82:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0102b86:	8b 10                	mov    (%eax),%edx
f0102b88:	3b 50 04             	cmp    0x4(%eax),%edx
f0102b8b:	73 0a                	jae    f0102b97 <sprintputch+0x1b>
		*b->buf++ = ch;
f0102b8d:	8d 4a 01             	lea    0x1(%edx),%ecx
f0102b90:	89 08                	mov    %ecx,(%eax)
f0102b92:	8b 45 08             	mov    0x8(%ebp),%eax
f0102b95:	88 02                	mov    %al,(%edx)
}
f0102b97:	5d                   	pop    %ebp
f0102b98:	c3                   	ret    

f0102b99 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0102b99:	55                   	push   %ebp
f0102b9a:	89 e5                	mov    %esp,%ebp
f0102b9c:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0102b9f:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0102ba2:	50                   	push   %eax
f0102ba3:	ff 75 10             	pushl  0x10(%ebp)
f0102ba6:	ff 75 0c             	pushl  0xc(%ebp)
f0102ba9:	ff 75 08             	pushl  0x8(%ebp)
f0102bac:	e8 05 00 00 00       	call   f0102bb6 <vprintfmt>
	va_end(ap);
}
f0102bb1:	83 c4 10             	add    $0x10,%esp
f0102bb4:	c9                   	leave  
f0102bb5:	c3                   	ret    

f0102bb6 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0102bb6:	55                   	push   %ebp
f0102bb7:	89 e5                	mov    %esp,%ebp
f0102bb9:	57                   	push   %edi
f0102bba:	56                   	push   %esi
f0102bbb:	53                   	push   %ebx
f0102bbc:	83 ec 2c             	sub    $0x2c,%esp
f0102bbf:	8b 75 08             	mov    0x8(%ebp),%esi
f0102bc2:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102bc5:	8b 7d 10             	mov    0x10(%ebp),%edi
f0102bc8:	eb 12                	jmp    f0102bdc <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0102bca:	85 c0                	test   %eax,%eax
f0102bcc:	0f 84 89 03 00 00    	je     f0102f5b <vprintfmt+0x3a5>
				return;
			putch(ch, putdat);
f0102bd2:	83 ec 08             	sub    $0x8,%esp
f0102bd5:	53                   	push   %ebx
f0102bd6:	50                   	push   %eax
f0102bd7:	ff d6                	call   *%esi
f0102bd9:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0102bdc:	83 c7 01             	add    $0x1,%edi
f0102bdf:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0102be3:	83 f8 25             	cmp    $0x25,%eax
f0102be6:	75 e2                	jne    f0102bca <vprintfmt+0x14>
f0102be8:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0102bec:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0102bf3:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102bfa:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0102c01:	ba 00 00 00 00       	mov    $0x0,%edx
f0102c06:	eb 07                	jmp    f0102c0f <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c08:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0102c0b:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c0f:	8d 47 01             	lea    0x1(%edi),%eax
f0102c12:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102c15:	0f b6 07             	movzbl (%edi),%eax
f0102c18:	0f b6 c8             	movzbl %al,%ecx
f0102c1b:	83 e8 23             	sub    $0x23,%eax
f0102c1e:	3c 55                	cmp    $0x55,%al
f0102c20:	0f 87 1a 03 00 00    	ja     f0102f40 <vprintfmt+0x38a>
f0102c26:	0f b6 c0             	movzbl %al,%eax
f0102c29:	ff 24 85 14 47 10 f0 	jmp    *-0xfefb8ec(,%eax,4)
f0102c30:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0102c33:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0102c37:	eb d6                	jmp    f0102c0f <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c39:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102c3c:	b8 00 00 00 00       	mov    $0x0,%eax
f0102c41:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0102c44:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0102c47:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0102c4b:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0102c4e:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0102c51:	83 fa 09             	cmp    $0x9,%edx
f0102c54:	77 39                	ja     f0102c8f <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0102c56:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0102c59:	eb e9                	jmp    f0102c44 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0102c5b:	8b 45 14             	mov    0x14(%ebp),%eax
f0102c5e:	8d 48 04             	lea    0x4(%eax),%ecx
f0102c61:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0102c64:	8b 00                	mov    (%eax),%eax
f0102c66:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c69:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0102c6c:	eb 27                	jmp    f0102c95 <vprintfmt+0xdf>
f0102c6e:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102c71:	85 c0                	test   %eax,%eax
f0102c73:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102c78:	0f 49 c8             	cmovns %eax,%ecx
f0102c7b:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c7e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102c81:	eb 8c                	jmp    f0102c0f <vprintfmt+0x59>
f0102c83:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0102c86:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0102c8d:	eb 80                	jmp    f0102c0f <vprintfmt+0x59>
f0102c8f:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0102c92:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0102c95:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102c99:	0f 89 70 ff ff ff    	jns    f0102c0f <vprintfmt+0x59>
				width = precision, precision = -1;
f0102c9f:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102ca2:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102ca5:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102cac:	e9 5e ff ff ff       	jmp    f0102c0f <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0102cb1:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102cb4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0102cb7:	e9 53 ff ff ff       	jmp    f0102c0f <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0102cbc:	8b 45 14             	mov    0x14(%ebp),%eax
f0102cbf:	8d 50 04             	lea    0x4(%eax),%edx
f0102cc2:	89 55 14             	mov    %edx,0x14(%ebp)
f0102cc5:	83 ec 08             	sub    $0x8,%esp
f0102cc8:	53                   	push   %ebx
f0102cc9:	ff 30                	pushl  (%eax)
f0102ccb:	ff d6                	call   *%esi
			break;
f0102ccd:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102cd0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0102cd3:	e9 04 ff ff ff       	jmp    f0102bdc <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0102cd8:	8b 45 14             	mov    0x14(%ebp),%eax
f0102cdb:	8d 50 04             	lea    0x4(%eax),%edx
f0102cde:	89 55 14             	mov    %edx,0x14(%ebp)
f0102ce1:	8b 00                	mov    (%eax),%eax
f0102ce3:	99                   	cltd   
f0102ce4:	31 d0                	xor    %edx,%eax
f0102ce6:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0102ce8:	83 f8 06             	cmp    $0x6,%eax
f0102ceb:	7f 0b                	jg     f0102cf8 <vprintfmt+0x142>
f0102ced:	8b 14 85 6c 48 10 f0 	mov    -0xfefb794(,%eax,4),%edx
f0102cf4:	85 d2                	test   %edx,%edx
f0102cf6:	75 18                	jne    f0102d10 <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f0102cf8:	50                   	push   %eax
f0102cf9:	68 a0 46 10 f0       	push   $0xf01046a0
f0102cfe:	53                   	push   %ebx
f0102cff:	56                   	push   %esi
f0102d00:	e8 94 fe ff ff       	call   f0102b99 <printfmt>
f0102d05:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102d08:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0102d0b:	e9 cc fe ff ff       	jmp    f0102bdc <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0102d10:	52                   	push   %edx
f0102d11:	68 b8 43 10 f0       	push   $0xf01043b8
f0102d16:	53                   	push   %ebx
f0102d17:	56                   	push   %esi
f0102d18:	e8 7c fe ff ff       	call   f0102b99 <printfmt>
f0102d1d:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102d20:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102d23:	e9 b4 fe ff ff       	jmp    f0102bdc <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0102d28:	8b 45 14             	mov    0x14(%ebp),%eax
f0102d2b:	8d 50 04             	lea    0x4(%eax),%edx
f0102d2e:	89 55 14             	mov    %edx,0x14(%ebp)
f0102d31:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0102d33:	85 ff                	test   %edi,%edi
f0102d35:	b8 99 46 10 f0       	mov    $0xf0104699,%eax
f0102d3a:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0102d3d:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102d41:	0f 8e 94 00 00 00    	jle    f0102ddb <vprintfmt+0x225>
f0102d47:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0102d4b:	0f 84 98 00 00 00    	je     f0102de9 <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
f0102d51:	83 ec 08             	sub    $0x8,%esp
f0102d54:	ff 75 d0             	pushl  -0x30(%ebp)
f0102d57:	57                   	push   %edi
f0102d58:	e8 5f 03 00 00       	call   f01030bc <strnlen>
f0102d5d:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0102d60:	29 c1                	sub    %eax,%ecx
f0102d62:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0102d65:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0102d68:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0102d6c:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102d6f:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0102d72:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102d74:	eb 0f                	jmp    f0102d85 <vprintfmt+0x1cf>
					putch(padc, putdat);
f0102d76:	83 ec 08             	sub    $0x8,%esp
f0102d79:	53                   	push   %ebx
f0102d7a:	ff 75 e0             	pushl  -0x20(%ebp)
f0102d7d:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102d7f:	83 ef 01             	sub    $0x1,%edi
f0102d82:	83 c4 10             	add    $0x10,%esp
f0102d85:	85 ff                	test   %edi,%edi
f0102d87:	7f ed                	jg     f0102d76 <vprintfmt+0x1c0>
f0102d89:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102d8c:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0102d8f:	85 c9                	test   %ecx,%ecx
f0102d91:	b8 00 00 00 00       	mov    $0x0,%eax
f0102d96:	0f 49 c1             	cmovns %ecx,%eax
f0102d99:	29 c1                	sub    %eax,%ecx
f0102d9b:	89 75 08             	mov    %esi,0x8(%ebp)
f0102d9e:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102da1:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102da4:	89 cb                	mov    %ecx,%ebx
f0102da6:	eb 4d                	jmp    f0102df5 <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0102da8:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0102dac:	74 1b                	je     f0102dc9 <vprintfmt+0x213>
f0102dae:	0f be c0             	movsbl %al,%eax
f0102db1:	83 e8 20             	sub    $0x20,%eax
f0102db4:	83 f8 5e             	cmp    $0x5e,%eax
f0102db7:	76 10                	jbe    f0102dc9 <vprintfmt+0x213>
					putch('?', putdat);
f0102db9:	83 ec 08             	sub    $0x8,%esp
f0102dbc:	ff 75 0c             	pushl  0xc(%ebp)
f0102dbf:	6a 3f                	push   $0x3f
f0102dc1:	ff 55 08             	call   *0x8(%ebp)
f0102dc4:	83 c4 10             	add    $0x10,%esp
f0102dc7:	eb 0d                	jmp    f0102dd6 <vprintfmt+0x220>
				else
					putch(ch, putdat);
f0102dc9:	83 ec 08             	sub    $0x8,%esp
f0102dcc:	ff 75 0c             	pushl  0xc(%ebp)
f0102dcf:	52                   	push   %edx
f0102dd0:	ff 55 08             	call   *0x8(%ebp)
f0102dd3:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0102dd6:	83 eb 01             	sub    $0x1,%ebx
f0102dd9:	eb 1a                	jmp    f0102df5 <vprintfmt+0x23f>
f0102ddb:	89 75 08             	mov    %esi,0x8(%ebp)
f0102dde:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102de1:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102de4:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102de7:	eb 0c                	jmp    f0102df5 <vprintfmt+0x23f>
f0102de9:	89 75 08             	mov    %esi,0x8(%ebp)
f0102dec:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102def:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102df2:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102df5:	83 c7 01             	add    $0x1,%edi
f0102df8:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0102dfc:	0f be d0             	movsbl %al,%edx
f0102dff:	85 d2                	test   %edx,%edx
f0102e01:	74 23                	je     f0102e26 <vprintfmt+0x270>
f0102e03:	85 f6                	test   %esi,%esi
f0102e05:	78 a1                	js     f0102da8 <vprintfmt+0x1f2>
f0102e07:	83 ee 01             	sub    $0x1,%esi
f0102e0a:	79 9c                	jns    f0102da8 <vprintfmt+0x1f2>
f0102e0c:	89 df                	mov    %ebx,%edi
f0102e0e:	8b 75 08             	mov    0x8(%ebp),%esi
f0102e11:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102e14:	eb 18                	jmp    f0102e2e <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0102e16:	83 ec 08             	sub    $0x8,%esp
f0102e19:	53                   	push   %ebx
f0102e1a:	6a 20                	push   $0x20
f0102e1c:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0102e1e:	83 ef 01             	sub    $0x1,%edi
f0102e21:	83 c4 10             	add    $0x10,%esp
f0102e24:	eb 08                	jmp    f0102e2e <vprintfmt+0x278>
f0102e26:	89 df                	mov    %ebx,%edi
f0102e28:	8b 75 08             	mov    0x8(%ebp),%esi
f0102e2b:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102e2e:	85 ff                	test   %edi,%edi
f0102e30:	7f e4                	jg     f0102e16 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102e32:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102e35:	e9 a2 fd ff ff       	jmp    f0102bdc <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0102e3a:	83 fa 01             	cmp    $0x1,%edx
f0102e3d:	7e 16                	jle    f0102e55 <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f0102e3f:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e42:	8d 50 08             	lea    0x8(%eax),%edx
f0102e45:	89 55 14             	mov    %edx,0x14(%ebp)
f0102e48:	8b 50 04             	mov    0x4(%eax),%edx
f0102e4b:	8b 00                	mov    (%eax),%eax
f0102e4d:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102e50:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0102e53:	eb 32                	jmp    f0102e87 <vprintfmt+0x2d1>
	else if (lflag)
f0102e55:	85 d2                	test   %edx,%edx
f0102e57:	74 18                	je     f0102e71 <vprintfmt+0x2bb>
		return va_arg(*ap, long);
f0102e59:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e5c:	8d 50 04             	lea    0x4(%eax),%edx
f0102e5f:	89 55 14             	mov    %edx,0x14(%ebp)
f0102e62:	8b 00                	mov    (%eax),%eax
f0102e64:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102e67:	89 c1                	mov    %eax,%ecx
f0102e69:	c1 f9 1f             	sar    $0x1f,%ecx
f0102e6c:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0102e6f:	eb 16                	jmp    f0102e87 <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
f0102e71:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e74:	8d 50 04             	lea    0x4(%eax),%edx
f0102e77:	89 55 14             	mov    %edx,0x14(%ebp)
f0102e7a:	8b 00                	mov    (%eax),%eax
f0102e7c:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102e7f:	89 c1                	mov    %eax,%ecx
f0102e81:	c1 f9 1f             	sar    $0x1f,%ecx
f0102e84:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0102e87:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102e8a:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0102e8d:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0102e92:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0102e96:	79 74                	jns    f0102f0c <vprintfmt+0x356>
				putch('-', putdat);
f0102e98:	83 ec 08             	sub    $0x8,%esp
f0102e9b:	53                   	push   %ebx
f0102e9c:	6a 2d                	push   $0x2d
f0102e9e:	ff d6                	call   *%esi
				num = -(long long) num;
f0102ea0:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102ea3:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102ea6:	f7 d8                	neg    %eax
f0102ea8:	83 d2 00             	adc    $0x0,%edx
f0102eab:	f7 da                	neg    %edx
f0102ead:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0102eb0:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0102eb5:	eb 55                	jmp    f0102f0c <vprintfmt+0x356>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0102eb7:	8d 45 14             	lea    0x14(%ebp),%eax
f0102eba:	e8 83 fc ff ff       	call   f0102b42 <getuint>
			base = 10;
f0102ebf:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0102ec4:	eb 46                	jmp    f0102f0c <vprintfmt+0x356>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f0102ec6:	8d 45 14             	lea    0x14(%ebp),%eax
f0102ec9:	e8 74 fc ff ff       	call   f0102b42 <getuint>
			base = 8;
f0102ece:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0102ed3:	eb 37                	jmp    f0102f0c <vprintfmt+0x356>

		// pointer
		case 'p':
			putch('0', putdat);
f0102ed5:	83 ec 08             	sub    $0x8,%esp
f0102ed8:	53                   	push   %ebx
f0102ed9:	6a 30                	push   $0x30
f0102edb:	ff d6                	call   *%esi
			putch('x', putdat);
f0102edd:	83 c4 08             	add    $0x8,%esp
f0102ee0:	53                   	push   %ebx
f0102ee1:	6a 78                	push   $0x78
f0102ee3:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0102ee5:	8b 45 14             	mov    0x14(%ebp),%eax
f0102ee8:	8d 50 04             	lea    0x4(%eax),%edx
f0102eeb:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0102eee:	8b 00                	mov    (%eax),%eax
f0102ef0:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0102ef5:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0102ef8:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0102efd:	eb 0d                	jmp    f0102f0c <vprintfmt+0x356>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0102eff:	8d 45 14             	lea    0x14(%ebp),%eax
f0102f02:	e8 3b fc ff ff       	call   f0102b42 <getuint>
			base = 16;
f0102f07:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0102f0c:	83 ec 0c             	sub    $0xc,%esp
f0102f0f:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0102f13:	57                   	push   %edi
f0102f14:	ff 75 e0             	pushl  -0x20(%ebp)
f0102f17:	51                   	push   %ecx
f0102f18:	52                   	push   %edx
f0102f19:	50                   	push   %eax
f0102f1a:	89 da                	mov    %ebx,%edx
f0102f1c:	89 f0                	mov    %esi,%eax
f0102f1e:	e8 70 fb ff ff       	call   f0102a93 <printnum>
			break;
f0102f23:	83 c4 20             	add    $0x20,%esp
f0102f26:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102f29:	e9 ae fc ff ff       	jmp    f0102bdc <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0102f2e:	83 ec 08             	sub    $0x8,%esp
f0102f31:	53                   	push   %ebx
f0102f32:	51                   	push   %ecx
f0102f33:	ff d6                	call   *%esi
			break;
f0102f35:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102f38:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0102f3b:	e9 9c fc ff ff       	jmp    f0102bdc <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0102f40:	83 ec 08             	sub    $0x8,%esp
f0102f43:	53                   	push   %ebx
f0102f44:	6a 25                	push   $0x25
f0102f46:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0102f48:	83 c4 10             	add    $0x10,%esp
f0102f4b:	eb 03                	jmp    f0102f50 <vprintfmt+0x39a>
f0102f4d:	83 ef 01             	sub    $0x1,%edi
f0102f50:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0102f54:	75 f7                	jne    f0102f4d <vprintfmt+0x397>
f0102f56:	e9 81 fc ff ff       	jmp    f0102bdc <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0102f5b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102f5e:	5b                   	pop    %ebx
f0102f5f:	5e                   	pop    %esi
f0102f60:	5f                   	pop    %edi
f0102f61:	5d                   	pop    %ebp
f0102f62:	c3                   	ret    

f0102f63 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0102f63:	55                   	push   %ebp
f0102f64:	89 e5                	mov    %esp,%ebp
f0102f66:	83 ec 18             	sub    $0x18,%esp
f0102f69:	8b 45 08             	mov    0x8(%ebp),%eax
f0102f6c:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0102f6f:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0102f72:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0102f76:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0102f79:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0102f80:	85 c0                	test   %eax,%eax
f0102f82:	74 26                	je     f0102faa <vsnprintf+0x47>
f0102f84:	85 d2                	test   %edx,%edx
f0102f86:	7e 22                	jle    f0102faa <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0102f88:	ff 75 14             	pushl  0x14(%ebp)
f0102f8b:	ff 75 10             	pushl  0x10(%ebp)
f0102f8e:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0102f91:	50                   	push   %eax
f0102f92:	68 7c 2b 10 f0       	push   $0xf0102b7c
f0102f97:	e8 1a fc ff ff       	call   f0102bb6 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0102f9c:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0102f9f:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0102fa2:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102fa5:	83 c4 10             	add    $0x10,%esp
f0102fa8:	eb 05                	jmp    f0102faf <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0102faa:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0102faf:	c9                   	leave  
f0102fb0:	c3                   	ret    

f0102fb1 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0102fb1:	55                   	push   %ebp
f0102fb2:	89 e5                	mov    %esp,%ebp
f0102fb4:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0102fb7:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0102fba:	50                   	push   %eax
f0102fbb:	ff 75 10             	pushl  0x10(%ebp)
f0102fbe:	ff 75 0c             	pushl  0xc(%ebp)
f0102fc1:	ff 75 08             	pushl  0x8(%ebp)
f0102fc4:	e8 9a ff ff ff       	call   f0102f63 <vsnprintf>
	va_end(ap);

	return rc;
}
f0102fc9:	c9                   	leave  
f0102fca:	c3                   	ret    

f0102fcb <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0102fcb:	55                   	push   %ebp
f0102fcc:	89 e5                	mov    %esp,%ebp
f0102fce:	57                   	push   %edi
f0102fcf:	56                   	push   %esi
f0102fd0:	53                   	push   %ebx
f0102fd1:	83 ec 0c             	sub    $0xc,%esp
f0102fd4:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0102fd7:	85 c0                	test   %eax,%eax
f0102fd9:	74 11                	je     f0102fec <readline+0x21>
		cprintf("%s", prompt);
f0102fdb:	83 ec 08             	sub    $0x8,%esp
f0102fde:	50                   	push   %eax
f0102fdf:	68 b8 43 10 f0       	push   $0xf01043b8
f0102fe4:	e8 80 f7 ff ff       	call   f0102769 <cprintf>
f0102fe9:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0102fec:	83 ec 0c             	sub    $0xc,%esp
f0102fef:	6a 00                	push   $0x0
f0102ff1:	e8 2b d6 ff ff       	call   f0100621 <iscons>
f0102ff6:	89 c7                	mov    %eax,%edi
f0102ff8:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0102ffb:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0103000:	e8 0b d6 ff ff       	call   f0100610 <getchar>
f0103005:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0103007:	85 c0                	test   %eax,%eax
f0103009:	79 18                	jns    f0103023 <readline+0x58>
			cprintf("read error: %e\n", c);
f010300b:	83 ec 08             	sub    $0x8,%esp
f010300e:	50                   	push   %eax
f010300f:	68 88 48 10 f0       	push   $0xf0104888
f0103014:	e8 50 f7 ff ff       	call   f0102769 <cprintf>
			return NULL;
f0103019:	83 c4 10             	add    $0x10,%esp
f010301c:	b8 00 00 00 00       	mov    $0x0,%eax
f0103021:	eb 79                	jmp    f010309c <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0103023:	83 f8 08             	cmp    $0x8,%eax
f0103026:	0f 94 c2             	sete   %dl
f0103029:	83 f8 7f             	cmp    $0x7f,%eax
f010302c:	0f 94 c0             	sete   %al
f010302f:	08 c2                	or     %al,%dl
f0103031:	74 1a                	je     f010304d <readline+0x82>
f0103033:	85 f6                	test   %esi,%esi
f0103035:	7e 16                	jle    f010304d <readline+0x82>
			if (echoing)
f0103037:	85 ff                	test   %edi,%edi
f0103039:	74 0d                	je     f0103048 <readline+0x7d>
				cputchar('\b');
f010303b:	83 ec 0c             	sub    $0xc,%esp
f010303e:	6a 08                	push   $0x8
f0103040:	e8 bb d5 ff ff       	call   f0100600 <cputchar>
f0103045:	83 c4 10             	add    $0x10,%esp
			i--;
f0103048:	83 ee 01             	sub    $0x1,%esi
f010304b:	eb b3                	jmp    f0103000 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f010304d:	83 fb 1f             	cmp    $0x1f,%ebx
f0103050:	7e 23                	jle    f0103075 <readline+0xaa>
f0103052:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0103058:	7f 1b                	jg     f0103075 <readline+0xaa>
			if (echoing)
f010305a:	85 ff                	test   %edi,%edi
f010305c:	74 0c                	je     f010306a <readline+0x9f>
				cputchar(c);
f010305e:	83 ec 0c             	sub    $0xc,%esp
f0103061:	53                   	push   %ebx
f0103062:	e8 99 d5 ff ff       	call   f0100600 <cputchar>
f0103067:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f010306a:	88 9e 60 65 11 f0    	mov    %bl,-0xfee9aa0(%esi)
f0103070:	8d 76 01             	lea    0x1(%esi),%esi
f0103073:	eb 8b                	jmp    f0103000 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0103075:	83 fb 0a             	cmp    $0xa,%ebx
f0103078:	74 05                	je     f010307f <readline+0xb4>
f010307a:	83 fb 0d             	cmp    $0xd,%ebx
f010307d:	75 81                	jne    f0103000 <readline+0x35>
			if (echoing)
f010307f:	85 ff                	test   %edi,%edi
f0103081:	74 0d                	je     f0103090 <readline+0xc5>
				cputchar('\n');
f0103083:	83 ec 0c             	sub    $0xc,%esp
f0103086:	6a 0a                	push   $0xa
f0103088:	e8 73 d5 ff ff       	call   f0100600 <cputchar>
f010308d:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0103090:	c6 86 60 65 11 f0 00 	movb   $0x0,-0xfee9aa0(%esi)
			return buf;
f0103097:	b8 60 65 11 f0       	mov    $0xf0116560,%eax
		}
	}
}
f010309c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010309f:	5b                   	pop    %ebx
f01030a0:	5e                   	pop    %esi
f01030a1:	5f                   	pop    %edi
f01030a2:	5d                   	pop    %ebp
f01030a3:	c3                   	ret    

f01030a4 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01030a4:	55                   	push   %ebp
f01030a5:	89 e5                	mov    %esp,%ebp
f01030a7:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01030aa:	b8 00 00 00 00       	mov    $0x0,%eax
f01030af:	eb 03                	jmp    f01030b4 <strlen+0x10>
		n++;
f01030b1:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01030b4:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01030b8:	75 f7                	jne    f01030b1 <strlen+0xd>
		n++;
	return n;
}
f01030ba:	5d                   	pop    %ebp
f01030bb:	c3                   	ret    

f01030bc <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01030bc:	55                   	push   %ebp
f01030bd:	89 e5                	mov    %esp,%ebp
f01030bf:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01030c2:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01030c5:	ba 00 00 00 00       	mov    $0x0,%edx
f01030ca:	eb 03                	jmp    f01030cf <strnlen+0x13>
		n++;
f01030cc:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01030cf:	39 c2                	cmp    %eax,%edx
f01030d1:	74 08                	je     f01030db <strnlen+0x1f>
f01030d3:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f01030d7:	75 f3                	jne    f01030cc <strnlen+0x10>
f01030d9:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f01030db:	5d                   	pop    %ebp
f01030dc:	c3                   	ret    

f01030dd <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01030dd:	55                   	push   %ebp
f01030de:	89 e5                	mov    %esp,%ebp
f01030e0:	53                   	push   %ebx
f01030e1:	8b 45 08             	mov    0x8(%ebp),%eax
f01030e4:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01030e7:	89 c2                	mov    %eax,%edx
f01030e9:	83 c2 01             	add    $0x1,%edx
f01030ec:	83 c1 01             	add    $0x1,%ecx
f01030ef:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f01030f3:	88 5a ff             	mov    %bl,-0x1(%edx)
f01030f6:	84 db                	test   %bl,%bl
f01030f8:	75 ef                	jne    f01030e9 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f01030fa:	5b                   	pop    %ebx
f01030fb:	5d                   	pop    %ebp
f01030fc:	c3                   	ret    

f01030fd <strcat>:

char *
strcat(char *dst, const char *src)
{
f01030fd:	55                   	push   %ebp
f01030fe:	89 e5                	mov    %esp,%ebp
f0103100:	53                   	push   %ebx
f0103101:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0103104:	53                   	push   %ebx
f0103105:	e8 9a ff ff ff       	call   f01030a4 <strlen>
f010310a:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f010310d:	ff 75 0c             	pushl  0xc(%ebp)
f0103110:	01 d8                	add    %ebx,%eax
f0103112:	50                   	push   %eax
f0103113:	e8 c5 ff ff ff       	call   f01030dd <strcpy>
	return dst;
}
f0103118:	89 d8                	mov    %ebx,%eax
f010311a:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010311d:	c9                   	leave  
f010311e:	c3                   	ret    

f010311f <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f010311f:	55                   	push   %ebp
f0103120:	89 e5                	mov    %esp,%ebp
f0103122:	56                   	push   %esi
f0103123:	53                   	push   %ebx
f0103124:	8b 75 08             	mov    0x8(%ebp),%esi
f0103127:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010312a:	89 f3                	mov    %esi,%ebx
f010312c:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f010312f:	89 f2                	mov    %esi,%edx
f0103131:	eb 0f                	jmp    f0103142 <strncpy+0x23>
		*dst++ = *src;
f0103133:	83 c2 01             	add    $0x1,%edx
f0103136:	0f b6 01             	movzbl (%ecx),%eax
f0103139:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f010313c:	80 39 01             	cmpb   $0x1,(%ecx)
f010313f:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103142:	39 da                	cmp    %ebx,%edx
f0103144:	75 ed                	jne    f0103133 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0103146:	89 f0                	mov    %esi,%eax
f0103148:	5b                   	pop    %ebx
f0103149:	5e                   	pop    %esi
f010314a:	5d                   	pop    %ebp
f010314b:	c3                   	ret    

f010314c <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010314c:	55                   	push   %ebp
f010314d:	89 e5                	mov    %esp,%ebp
f010314f:	56                   	push   %esi
f0103150:	53                   	push   %ebx
f0103151:	8b 75 08             	mov    0x8(%ebp),%esi
f0103154:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103157:	8b 55 10             	mov    0x10(%ebp),%edx
f010315a:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f010315c:	85 d2                	test   %edx,%edx
f010315e:	74 21                	je     f0103181 <strlcpy+0x35>
f0103160:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0103164:	89 f2                	mov    %esi,%edx
f0103166:	eb 09                	jmp    f0103171 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0103168:	83 c2 01             	add    $0x1,%edx
f010316b:	83 c1 01             	add    $0x1,%ecx
f010316e:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0103171:	39 c2                	cmp    %eax,%edx
f0103173:	74 09                	je     f010317e <strlcpy+0x32>
f0103175:	0f b6 19             	movzbl (%ecx),%ebx
f0103178:	84 db                	test   %bl,%bl
f010317a:	75 ec                	jne    f0103168 <strlcpy+0x1c>
f010317c:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f010317e:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0103181:	29 f0                	sub    %esi,%eax
}
f0103183:	5b                   	pop    %ebx
f0103184:	5e                   	pop    %esi
f0103185:	5d                   	pop    %ebp
f0103186:	c3                   	ret    

f0103187 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0103187:	55                   	push   %ebp
f0103188:	89 e5                	mov    %esp,%ebp
f010318a:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010318d:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0103190:	eb 06                	jmp    f0103198 <strcmp+0x11>
		p++, q++;
f0103192:	83 c1 01             	add    $0x1,%ecx
f0103195:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0103198:	0f b6 01             	movzbl (%ecx),%eax
f010319b:	84 c0                	test   %al,%al
f010319d:	74 04                	je     f01031a3 <strcmp+0x1c>
f010319f:	3a 02                	cmp    (%edx),%al
f01031a1:	74 ef                	je     f0103192 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01031a3:	0f b6 c0             	movzbl %al,%eax
f01031a6:	0f b6 12             	movzbl (%edx),%edx
f01031a9:	29 d0                	sub    %edx,%eax
}
f01031ab:	5d                   	pop    %ebp
f01031ac:	c3                   	ret    

f01031ad <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01031ad:	55                   	push   %ebp
f01031ae:	89 e5                	mov    %esp,%ebp
f01031b0:	53                   	push   %ebx
f01031b1:	8b 45 08             	mov    0x8(%ebp),%eax
f01031b4:	8b 55 0c             	mov    0xc(%ebp),%edx
f01031b7:	89 c3                	mov    %eax,%ebx
f01031b9:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01031bc:	eb 06                	jmp    f01031c4 <strncmp+0x17>
		n--, p++, q++;
f01031be:	83 c0 01             	add    $0x1,%eax
f01031c1:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01031c4:	39 d8                	cmp    %ebx,%eax
f01031c6:	74 15                	je     f01031dd <strncmp+0x30>
f01031c8:	0f b6 08             	movzbl (%eax),%ecx
f01031cb:	84 c9                	test   %cl,%cl
f01031cd:	74 04                	je     f01031d3 <strncmp+0x26>
f01031cf:	3a 0a                	cmp    (%edx),%cl
f01031d1:	74 eb                	je     f01031be <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01031d3:	0f b6 00             	movzbl (%eax),%eax
f01031d6:	0f b6 12             	movzbl (%edx),%edx
f01031d9:	29 d0                	sub    %edx,%eax
f01031db:	eb 05                	jmp    f01031e2 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f01031dd:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01031e2:	5b                   	pop    %ebx
f01031e3:	5d                   	pop    %ebp
f01031e4:	c3                   	ret    

f01031e5 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01031e5:	55                   	push   %ebp
f01031e6:	89 e5                	mov    %esp,%ebp
f01031e8:	8b 45 08             	mov    0x8(%ebp),%eax
f01031eb:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01031ef:	eb 07                	jmp    f01031f8 <strchr+0x13>
		if (*s == c)
f01031f1:	38 ca                	cmp    %cl,%dl
f01031f3:	74 0f                	je     f0103204 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01031f5:	83 c0 01             	add    $0x1,%eax
f01031f8:	0f b6 10             	movzbl (%eax),%edx
f01031fb:	84 d2                	test   %dl,%dl
f01031fd:	75 f2                	jne    f01031f1 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f01031ff:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103204:	5d                   	pop    %ebp
f0103205:	c3                   	ret    

f0103206 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0103206:	55                   	push   %ebp
f0103207:	89 e5                	mov    %esp,%ebp
f0103209:	8b 45 08             	mov    0x8(%ebp),%eax
f010320c:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103210:	eb 03                	jmp    f0103215 <strfind+0xf>
f0103212:	83 c0 01             	add    $0x1,%eax
f0103215:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0103218:	38 ca                	cmp    %cl,%dl
f010321a:	74 04                	je     f0103220 <strfind+0x1a>
f010321c:	84 d2                	test   %dl,%dl
f010321e:	75 f2                	jne    f0103212 <strfind+0xc>
			break;
	return (char *) s;
}
f0103220:	5d                   	pop    %ebp
f0103221:	c3                   	ret    

f0103222 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0103222:	55                   	push   %ebp
f0103223:	89 e5                	mov    %esp,%ebp
f0103225:	57                   	push   %edi
f0103226:	56                   	push   %esi
f0103227:	53                   	push   %ebx
f0103228:	8b 7d 08             	mov    0x8(%ebp),%edi
f010322b:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f010322e:	85 c9                	test   %ecx,%ecx
f0103230:	74 36                	je     f0103268 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0103232:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0103238:	75 28                	jne    f0103262 <memset+0x40>
f010323a:	f6 c1 03             	test   $0x3,%cl
f010323d:	75 23                	jne    f0103262 <memset+0x40>
		c &= 0xFF;
f010323f:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0103243:	89 d3                	mov    %edx,%ebx
f0103245:	c1 e3 08             	shl    $0x8,%ebx
f0103248:	89 d6                	mov    %edx,%esi
f010324a:	c1 e6 18             	shl    $0x18,%esi
f010324d:	89 d0                	mov    %edx,%eax
f010324f:	c1 e0 10             	shl    $0x10,%eax
f0103252:	09 f0                	or     %esi,%eax
f0103254:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f0103256:	89 d8                	mov    %ebx,%eax
f0103258:	09 d0                	or     %edx,%eax
f010325a:	c1 e9 02             	shr    $0x2,%ecx
f010325d:	fc                   	cld    
f010325e:	f3 ab                	rep stos %eax,%es:(%edi)
f0103260:	eb 06                	jmp    f0103268 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0103262:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103265:	fc                   	cld    
f0103266:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0103268:	89 f8                	mov    %edi,%eax
f010326a:	5b                   	pop    %ebx
f010326b:	5e                   	pop    %esi
f010326c:	5f                   	pop    %edi
f010326d:	5d                   	pop    %ebp
f010326e:	c3                   	ret    

f010326f <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f010326f:	55                   	push   %ebp
f0103270:	89 e5                	mov    %esp,%ebp
f0103272:	57                   	push   %edi
f0103273:	56                   	push   %esi
f0103274:	8b 45 08             	mov    0x8(%ebp),%eax
f0103277:	8b 75 0c             	mov    0xc(%ebp),%esi
f010327a:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f010327d:	39 c6                	cmp    %eax,%esi
f010327f:	73 35                	jae    f01032b6 <memmove+0x47>
f0103281:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0103284:	39 d0                	cmp    %edx,%eax
f0103286:	73 2e                	jae    f01032b6 <memmove+0x47>
		s += n;
		d += n;
f0103288:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010328b:	89 d6                	mov    %edx,%esi
f010328d:	09 fe                	or     %edi,%esi
f010328f:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0103295:	75 13                	jne    f01032aa <memmove+0x3b>
f0103297:	f6 c1 03             	test   $0x3,%cl
f010329a:	75 0e                	jne    f01032aa <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f010329c:	83 ef 04             	sub    $0x4,%edi
f010329f:	8d 72 fc             	lea    -0x4(%edx),%esi
f01032a2:	c1 e9 02             	shr    $0x2,%ecx
f01032a5:	fd                   	std    
f01032a6:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01032a8:	eb 09                	jmp    f01032b3 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01032aa:	83 ef 01             	sub    $0x1,%edi
f01032ad:	8d 72 ff             	lea    -0x1(%edx),%esi
f01032b0:	fd                   	std    
f01032b1:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01032b3:	fc                   	cld    
f01032b4:	eb 1d                	jmp    f01032d3 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01032b6:	89 f2                	mov    %esi,%edx
f01032b8:	09 c2                	or     %eax,%edx
f01032ba:	f6 c2 03             	test   $0x3,%dl
f01032bd:	75 0f                	jne    f01032ce <memmove+0x5f>
f01032bf:	f6 c1 03             	test   $0x3,%cl
f01032c2:	75 0a                	jne    f01032ce <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f01032c4:	c1 e9 02             	shr    $0x2,%ecx
f01032c7:	89 c7                	mov    %eax,%edi
f01032c9:	fc                   	cld    
f01032ca:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01032cc:	eb 05                	jmp    f01032d3 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01032ce:	89 c7                	mov    %eax,%edi
f01032d0:	fc                   	cld    
f01032d1:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01032d3:	5e                   	pop    %esi
f01032d4:	5f                   	pop    %edi
f01032d5:	5d                   	pop    %ebp
f01032d6:	c3                   	ret    

f01032d7 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01032d7:	55                   	push   %ebp
f01032d8:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f01032da:	ff 75 10             	pushl  0x10(%ebp)
f01032dd:	ff 75 0c             	pushl  0xc(%ebp)
f01032e0:	ff 75 08             	pushl  0x8(%ebp)
f01032e3:	e8 87 ff ff ff       	call   f010326f <memmove>
}
f01032e8:	c9                   	leave  
f01032e9:	c3                   	ret    

f01032ea <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01032ea:	55                   	push   %ebp
f01032eb:	89 e5                	mov    %esp,%ebp
f01032ed:	56                   	push   %esi
f01032ee:	53                   	push   %ebx
f01032ef:	8b 45 08             	mov    0x8(%ebp),%eax
f01032f2:	8b 55 0c             	mov    0xc(%ebp),%edx
f01032f5:	89 c6                	mov    %eax,%esi
f01032f7:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01032fa:	eb 1a                	jmp    f0103316 <memcmp+0x2c>
		if (*s1 != *s2)
f01032fc:	0f b6 08             	movzbl (%eax),%ecx
f01032ff:	0f b6 1a             	movzbl (%edx),%ebx
f0103302:	38 d9                	cmp    %bl,%cl
f0103304:	74 0a                	je     f0103310 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0103306:	0f b6 c1             	movzbl %cl,%eax
f0103309:	0f b6 db             	movzbl %bl,%ebx
f010330c:	29 d8                	sub    %ebx,%eax
f010330e:	eb 0f                	jmp    f010331f <memcmp+0x35>
		s1++, s2++;
f0103310:	83 c0 01             	add    $0x1,%eax
f0103313:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103316:	39 f0                	cmp    %esi,%eax
f0103318:	75 e2                	jne    f01032fc <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f010331a:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010331f:	5b                   	pop    %ebx
f0103320:	5e                   	pop    %esi
f0103321:	5d                   	pop    %ebp
f0103322:	c3                   	ret    

f0103323 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0103323:	55                   	push   %ebp
f0103324:	89 e5                	mov    %esp,%ebp
f0103326:	53                   	push   %ebx
f0103327:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f010332a:	89 c1                	mov    %eax,%ecx
f010332c:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f010332f:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0103333:	eb 0a                	jmp    f010333f <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f0103335:	0f b6 10             	movzbl (%eax),%edx
f0103338:	39 da                	cmp    %ebx,%edx
f010333a:	74 07                	je     f0103343 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010333c:	83 c0 01             	add    $0x1,%eax
f010333f:	39 c8                	cmp    %ecx,%eax
f0103341:	72 f2                	jb     f0103335 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0103343:	5b                   	pop    %ebx
f0103344:	5d                   	pop    %ebp
f0103345:	c3                   	ret    

f0103346 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0103346:	55                   	push   %ebp
f0103347:	89 e5                	mov    %esp,%ebp
f0103349:	57                   	push   %edi
f010334a:	56                   	push   %esi
f010334b:	53                   	push   %ebx
f010334c:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010334f:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103352:	eb 03                	jmp    f0103357 <strtol+0x11>
		s++;
f0103354:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103357:	0f b6 01             	movzbl (%ecx),%eax
f010335a:	3c 20                	cmp    $0x20,%al
f010335c:	74 f6                	je     f0103354 <strtol+0xe>
f010335e:	3c 09                	cmp    $0x9,%al
f0103360:	74 f2                	je     f0103354 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0103362:	3c 2b                	cmp    $0x2b,%al
f0103364:	75 0a                	jne    f0103370 <strtol+0x2a>
		s++;
f0103366:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0103369:	bf 00 00 00 00       	mov    $0x0,%edi
f010336e:	eb 11                	jmp    f0103381 <strtol+0x3b>
f0103370:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0103375:	3c 2d                	cmp    $0x2d,%al
f0103377:	75 08                	jne    f0103381 <strtol+0x3b>
		s++, neg = 1;
f0103379:	83 c1 01             	add    $0x1,%ecx
f010337c:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103381:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0103387:	75 15                	jne    f010339e <strtol+0x58>
f0103389:	80 39 30             	cmpb   $0x30,(%ecx)
f010338c:	75 10                	jne    f010339e <strtol+0x58>
f010338e:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0103392:	75 7c                	jne    f0103410 <strtol+0xca>
		s += 2, base = 16;
f0103394:	83 c1 02             	add    $0x2,%ecx
f0103397:	bb 10 00 00 00       	mov    $0x10,%ebx
f010339c:	eb 16                	jmp    f01033b4 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f010339e:	85 db                	test   %ebx,%ebx
f01033a0:	75 12                	jne    f01033b4 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01033a2:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01033a7:	80 39 30             	cmpb   $0x30,(%ecx)
f01033aa:	75 08                	jne    f01033b4 <strtol+0x6e>
		s++, base = 8;
f01033ac:	83 c1 01             	add    $0x1,%ecx
f01033af:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f01033b4:	b8 00 00 00 00       	mov    $0x0,%eax
f01033b9:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f01033bc:	0f b6 11             	movzbl (%ecx),%edx
f01033bf:	8d 72 d0             	lea    -0x30(%edx),%esi
f01033c2:	89 f3                	mov    %esi,%ebx
f01033c4:	80 fb 09             	cmp    $0x9,%bl
f01033c7:	77 08                	ja     f01033d1 <strtol+0x8b>
			dig = *s - '0';
f01033c9:	0f be d2             	movsbl %dl,%edx
f01033cc:	83 ea 30             	sub    $0x30,%edx
f01033cf:	eb 22                	jmp    f01033f3 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f01033d1:	8d 72 9f             	lea    -0x61(%edx),%esi
f01033d4:	89 f3                	mov    %esi,%ebx
f01033d6:	80 fb 19             	cmp    $0x19,%bl
f01033d9:	77 08                	ja     f01033e3 <strtol+0x9d>
			dig = *s - 'a' + 10;
f01033db:	0f be d2             	movsbl %dl,%edx
f01033de:	83 ea 57             	sub    $0x57,%edx
f01033e1:	eb 10                	jmp    f01033f3 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f01033e3:	8d 72 bf             	lea    -0x41(%edx),%esi
f01033e6:	89 f3                	mov    %esi,%ebx
f01033e8:	80 fb 19             	cmp    $0x19,%bl
f01033eb:	77 16                	ja     f0103403 <strtol+0xbd>
			dig = *s - 'A' + 10;
f01033ed:	0f be d2             	movsbl %dl,%edx
f01033f0:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f01033f3:	3b 55 10             	cmp    0x10(%ebp),%edx
f01033f6:	7d 0b                	jge    f0103403 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f01033f8:	83 c1 01             	add    $0x1,%ecx
f01033fb:	0f af 45 10          	imul   0x10(%ebp),%eax
f01033ff:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f0103401:	eb b9                	jmp    f01033bc <strtol+0x76>

	if (endptr)
f0103403:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0103407:	74 0d                	je     f0103416 <strtol+0xd0>
		*endptr = (char *) s;
f0103409:	8b 75 0c             	mov    0xc(%ebp),%esi
f010340c:	89 0e                	mov    %ecx,(%esi)
f010340e:	eb 06                	jmp    f0103416 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0103410:	85 db                	test   %ebx,%ebx
f0103412:	74 98                	je     f01033ac <strtol+0x66>
f0103414:	eb 9e                	jmp    f01033b4 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f0103416:	89 c2                	mov    %eax,%edx
f0103418:	f7 da                	neg    %edx
f010341a:	85 ff                	test   %edi,%edi
f010341c:	0f 45 c2             	cmovne %edx,%eax
}
f010341f:	5b                   	pop    %ebx
f0103420:	5e                   	pop    %esi
f0103421:	5f                   	pop    %edi
f0103422:	5d                   	pop    %ebp
f0103423:	c3                   	ret    
f0103424:	66 90                	xchg   %ax,%ax
f0103426:	66 90                	xchg   %ax,%ax
f0103428:	66 90                	xchg   %ax,%ax
f010342a:	66 90                	xchg   %ax,%ax
f010342c:	66 90                	xchg   %ax,%ax
f010342e:	66 90                	xchg   %ax,%ax

f0103430 <__udivdi3>:
f0103430:	55                   	push   %ebp
f0103431:	57                   	push   %edi
f0103432:	56                   	push   %esi
f0103433:	53                   	push   %ebx
f0103434:	83 ec 1c             	sub    $0x1c,%esp
f0103437:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f010343b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f010343f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0103443:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0103447:	85 f6                	test   %esi,%esi
f0103449:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010344d:	89 ca                	mov    %ecx,%edx
f010344f:	89 f8                	mov    %edi,%eax
f0103451:	75 3d                	jne    f0103490 <__udivdi3+0x60>
f0103453:	39 cf                	cmp    %ecx,%edi
f0103455:	0f 87 c5 00 00 00    	ja     f0103520 <__udivdi3+0xf0>
f010345b:	85 ff                	test   %edi,%edi
f010345d:	89 fd                	mov    %edi,%ebp
f010345f:	75 0b                	jne    f010346c <__udivdi3+0x3c>
f0103461:	b8 01 00 00 00       	mov    $0x1,%eax
f0103466:	31 d2                	xor    %edx,%edx
f0103468:	f7 f7                	div    %edi
f010346a:	89 c5                	mov    %eax,%ebp
f010346c:	89 c8                	mov    %ecx,%eax
f010346e:	31 d2                	xor    %edx,%edx
f0103470:	f7 f5                	div    %ebp
f0103472:	89 c1                	mov    %eax,%ecx
f0103474:	89 d8                	mov    %ebx,%eax
f0103476:	89 cf                	mov    %ecx,%edi
f0103478:	f7 f5                	div    %ebp
f010347a:	89 c3                	mov    %eax,%ebx
f010347c:	89 d8                	mov    %ebx,%eax
f010347e:	89 fa                	mov    %edi,%edx
f0103480:	83 c4 1c             	add    $0x1c,%esp
f0103483:	5b                   	pop    %ebx
f0103484:	5e                   	pop    %esi
f0103485:	5f                   	pop    %edi
f0103486:	5d                   	pop    %ebp
f0103487:	c3                   	ret    
f0103488:	90                   	nop
f0103489:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103490:	39 ce                	cmp    %ecx,%esi
f0103492:	77 74                	ja     f0103508 <__udivdi3+0xd8>
f0103494:	0f bd fe             	bsr    %esi,%edi
f0103497:	83 f7 1f             	xor    $0x1f,%edi
f010349a:	0f 84 98 00 00 00    	je     f0103538 <__udivdi3+0x108>
f01034a0:	bb 20 00 00 00       	mov    $0x20,%ebx
f01034a5:	89 f9                	mov    %edi,%ecx
f01034a7:	89 c5                	mov    %eax,%ebp
f01034a9:	29 fb                	sub    %edi,%ebx
f01034ab:	d3 e6                	shl    %cl,%esi
f01034ad:	89 d9                	mov    %ebx,%ecx
f01034af:	d3 ed                	shr    %cl,%ebp
f01034b1:	89 f9                	mov    %edi,%ecx
f01034b3:	d3 e0                	shl    %cl,%eax
f01034b5:	09 ee                	or     %ebp,%esi
f01034b7:	89 d9                	mov    %ebx,%ecx
f01034b9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01034bd:	89 d5                	mov    %edx,%ebp
f01034bf:	8b 44 24 08          	mov    0x8(%esp),%eax
f01034c3:	d3 ed                	shr    %cl,%ebp
f01034c5:	89 f9                	mov    %edi,%ecx
f01034c7:	d3 e2                	shl    %cl,%edx
f01034c9:	89 d9                	mov    %ebx,%ecx
f01034cb:	d3 e8                	shr    %cl,%eax
f01034cd:	09 c2                	or     %eax,%edx
f01034cf:	89 d0                	mov    %edx,%eax
f01034d1:	89 ea                	mov    %ebp,%edx
f01034d3:	f7 f6                	div    %esi
f01034d5:	89 d5                	mov    %edx,%ebp
f01034d7:	89 c3                	mov    %eax,%ebx
f01034d9:	f7 64 24 0c          	mull   0xc(%esp)
f01034dd:	39 d5                	cmp    %edx,%ebp
f01034df:	72 10                	jb     f01034f1 <__udivdi3+0xc1>
f01034e1:	8b 74 24 08          	mov    0x8(%esp),%esi
f01034e5:	89 f9                	mov    %edi,%ecx
f01034e7:	d3 e6                	shl    %cl,%esi
f01034e9:	39 c6                	cmp    %eax,%esi
f01034eb:	73 07                	jae    f01034f4 <__udivdi3+0xc4>
f01034ed:	39 d5                	cmp    %edx,%ebp
f01034ef:	75 03                	jne    f01034f4 <__udivdi3+0xc4>
f01034f1:	83 eb 01             	sub    $0x1,%ebx
f01034f4:	31 ff                	xor    %edi,%edi
f01034f6:	89 d8                	mov    %ebx,%eax
f01034f8:	89 fa                	mov    %edi,%edx
f01034fa:	83 c4 1c             	add    $0x1c,%esp
f01034fd:	5b                   	pop    %ebx
f01034fe:	5e                   	pop    %esi
f01034ff:	5f                   	pop    %edi
f0103500:	5d                   	pop    %ebp
f0103501:	c3                   	ret    
f0103502:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103508:	31 ff                	xor    %edi,%edi
f010350a:	31 db                	xor    %ebx,%ebx
f010350c:	89 d8                	mov    %ebx,%eax
f010350e:	89 fa                	mov    %edi,%edx
f0103510:	83 c4 1c             	add    $0x1c,%esp
f0103513:	5b                   	pop    %ebx
f0103514:	5e                   	pop    %esi
f0103515:	5f                   	pop    %edi
f0103516:	5d                   	pop    %ebp
f0103517:	c3                   	ret    
f0103518:	90                   	nop
f0103519:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103520:	89 d8                	mov    %ebx,%eax
f0103522:	f7 f7                	div    %edi
f0103524:	31 ff                	xor    %edi,%edi
f0103526:	89 c3                	mov    %eax,%ebx
f0103528:	89 d8                	mov    %ebx,%eax
f010352a:	89 fa                	mov    %edi,%edx
f010352c:	83 c4 1c             	add    $0x1c,%esp
f010352f:	5b                   	pop    %ebx
f0103530:	5e                   	pop    %esi
f0103531:	5f                   	pop    %edi
f0103532:	5d                   	pop    %ebp
f0103533:	c3                   	ret    
f0103534:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103538:	39 ce                	cmp    %ecx,%esi
f010353a:	72 0c                	jb     f0103548 <__udivdi3+0x118>
f010353c:	31 db                	xor    %ebx,%ebx
f010353e:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0103542:	0f 87 34 ff ff ff    	ja     f010347c <__udivdi3+0x4c>
f0103548:	bb 01 00 00 00       	mov    $0x1,%ebx
f010354d:	e9 2a ff ff ff       	jmp    f010347c <__udivdi3+0x4c>
f0103552:	66 90                	xchg   %ax,%ax
f0103554:	66 90                	xchg   %ax,%ax
f0103556:	66 90                	xchg   %ax,%ax
f0103558:	66 90                	xchg   %ax,%ax
f010355a:	66 90                	xchg   %ax,%ax
f010355c:	66 90                	xchg   %ax,%ax
f010355e:	66 90                	xchg   %ax,%ax

f0103560 <__umoddi3>:
f0103560:	55                   	push   %ebp
f0103561:	57                   	push   %edi
f0103562:	56                   	push   %esi
f0103563:	53                   	push   %ebx
f0103564:	83 ec 1c             	sub    $0x1c,%esp
f0103567:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010356b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010356f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0103573:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0103577:	85 d2                	test   %edx,%edx
f0103579:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010357d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103581:	89 f3                	mov    %esi,%ebx
f0103583:	89 3c 24             	mov    %edi,(%esp)
f0103586:	89 74 24 04          	mov    %esi,0x4(%esp)
f010358a:	75 1c                	jne    f01035a8 <__umoddi3+0x48>
f010358c:	39 f7                	cmp    %esi,%edi
f010358e:	76 50                	jbe    f01035e0 <__umoddi3+0x80>
f0103590:	89 c8                	mov    %ecx,%eax
f0103592:	89 f2                	mov    %esi,%edx
f0103594:	f7 f7                	div    %edi
f0103596:	89 d0                	mov    %edx,%eax
f0103598:	31 d2                	xor    %edx,%edx
f010359a:	83 c4 1c             	add    $0x1c,%esp
f010359d:	5b                   	pop    %ebx
f010359e:	5e                   	pop    %esi
f010359f:	5f                   	pop    %edi
f01035a0:	5d                   	pop    %ebp
f01035a1:	c3                   	ret    
f01035a2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01035a8:	39 f2                	cmp    %esi,%edx
f01035aa:	89 d0                	mov    %edx,%eax
f01035ac:	77 52                	ja     f0103600 <__umoddi3+0xa0>
f01035ae:	0f bd ea             	bsr    %edx,%ebp
f01035b1:	83 f5 1f             	xor    $0x1f,%ebp
f01035b4:	75 5a                	jne    f0103610 <__umoddi3+0xb0>
f01035b6:	3b 54 24 04          	cmp    0x4(%esp),%edx
f01035ba:	0f 82 e0 00 00 00    	jb     f01036a0 <__umoddi3+0x140>
f01035c0:	39 0c 24             	cmp    %ecx,(%esp)
f01035c3:	0f 86 d7 00 00 00    	jbe    f01036a0 <__umoddi3+0x140>
f01035c9:	8b 44 24 08          	mov    0x8(%esp),%eax
f01035cd:	8b 54 24 04          	mov    0x4(%esp),%edx
f01035d1:	83 c4 1c             	add    $0x1c,%esp
f01035d4:	5b                   	pop    %ebx
f01035d5:	5e                   	pop    %esi
f01035d6:	5f                   	pop    %edi
f01035d7:	5d                   	pop    %ebp
f01035d8:	c3                   	ret    
f01035d9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01035e0:	85 ff                	test   %edi,%edi
f01035e2:	89 fd                	mov    %edi,%ebp
f01035e4:	75 0b                	jne    f01035f1 <__umoddi3+0x91>
f01035e6:	b8 01 00 00 00       	mov    $0x1,%eax
f01035eb:	31 d2                	xor    %edx,%edx
f01035ed:	f7 f7                	div    %edi
f01035ef:	89 c5                	mov    %eax,%ebp
f01035f1:	89 f0                	mov    %esi,%eax
f01035f3:	31 d2                	xor    %edx,%edx
f01035f5:	f7 f5                	div    %ebp
f01035f7:	89 c8                	mov    %ecx,%eax
f01035f9:	f7 f5                	div    %ebp
f01035fb:	89 d0                	mov    %edx,%eax
f01035fd:	eb 99                	jmp    f0103598 <__umoddi3+0x38>
f01035ff:	90                   	nop
f0103600:	89 c8                	mov    %ecx,%eax
f0103602:	89 f2                	mov    %esi,%edx
f0103604:	83 c4 1c             	add    $0x1c,%esp
f0103607:	5b                   	pop    %ebx
f0103608:	5e                   	pop    %esi
f0103609:	5f                   	pop    %edi
f010360a:	5d                   	pop    %ebp
f010360b:	c3                   	ret    
f010360c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103610:	8b 34 24             	mov    (%esp),%esi
f0103613:	bf 20 00 00 00       	mov    $0x20,%edi
f0103618:	89 e9                	mov    %ebp,%ecx
f010361a:	29 ef                	sub    %ebp,%edi
f010361c:	d3 e0                	shl    %cl,%eax
f010361e:	89 f9                	mov    %edi,%ecx
f0103620:	89 f2                	mov    %esi,%edx
f0103622:	d3 ea                	shr    %cl,%edx
f0103624:	89 e9                	mov    %ebp,%ecx
f0103626:	09 c2                	or     %eax,%edx
f0103628:	89 d8                	mov    %ebx,%eax
f010362a:	89 14 24             	mov    %edx,(%esp)
f010362d:	89 f2                	mov    %esi,%edx
f010362f:	d3 e2                	shl    %cl,%edx
f0103631:	89 f9                	mov    %edi,%ecx
f0103633:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103637:	8b 54 24 0c          	mov    0xc(%esp),%edx
f010363b:	d3 e8                	shr    %cl,%eax
f010363d:	89 e9                	mov    %ebp,%ecx
f010363f:	89 c6                	mov    %eax,%esi
f0103641:	d3 e3                	shl    %cl,%ebx
f0103643:	89 f9                	mov    %edi,%ecx
f0103645:	89 d0                	mov    %edx,%eax
f0103647:	d3 e8                	shr    %cl,%eax
f0103649:	89 e9                	mov    %ebp,%ecx
f010364b:	09 d8                	or     %ebx,%eax
f010364d:	89 d3                	mov    %edx,%ebx
f010364f:	89 f2                	mov    %esi,%edx
f0103651:	f7 34 24             	divl   (%esp)
f0103654:	89 d6                	mov    %edx,%esi
f0103656:	d3 e3                	shl    %cl,%ebx
f0103658:	f7 64 24 04          	mull   0x4(%esp)
f010365c:	39 d6                	cmp    %edx,%esi
f010365e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0103662:	89 d1                	mov    %edx,%ecx
f0103664:	89 c3                	mov    %eax,%ebx
f0103666:	72 08                	jb     f0103670 <__umoddi3+0x110>
f0103668:	75 11                	jne    f010367b <__umoddi3+0x11b>
f010366a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f010366e:	73 0b                	jae    f010367b <__umoddi3+0x11b>
f0103670:	2b 44 24 04          	sub    0x4(%esp),%eax
f0103674:	1b 14 24             	sbb    (%esp),%edx
f0103677:	89 d1                	mov    %edx,%ecx
f0103679:	89 c3                	mov    %eax,%ebx
f010367b:	8b 54 24 08          	mov    0x8(%esp),%edx
f010367f:	29 da                	sub    %ebx,%edx
f0103681:	19 ce                	sbb    %ecx,%esi
f0103683:	89 f9                	mov    %edi,%ecx
f0103685:	89 f0                	mov    %esi,%eax
f0103687:	d3 e0                	shl    %cl,%eax
f0103689:	89 e9                	mov    %ebp,%ecx
f010368b:	d3 ea                	shr    %cl,%edx
f010368d:	89 e9                	mov    %ebp,%ecx
f010368f:	d3 ee                	shr    %cl,%esi
f0103691:	09 d0                	or     %edx,%eax
f0103693:	89 f2                	mov    %esi,%edx
f0103695:	83 c4 1c             	add    $0x1c,%esp
f0103698:	5b                   	pop    %ebx
f0103699:	5e                   	pop    %esi
f010369a:	5f                   	pop    %edi
f010369b:	5d                   	pop    %ebp
f010369c:	c3                   	ret    
f010369d:	8d 76 00             	lea    0x0(%esi),%esi
f01036a0:	29 f9                	sub    %edi,%ecx
f01036a2:	19 d6                	sbb    %edx,%esi
f01036a4:	89 74 24 04          	mov    %esi,0x4(%esp)
f01036a8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01036ac:	e9 18 ff ff ff       	jmp    f01035c9 <__umoddi3+0x69>


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
f0100015:	b8 00 00 11 00       	mov    $0x110000,%eax
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
f0100034:	bc 00 00 11 f0       	mov    $0xf0110000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 56 00 00 00       	call   f0100094 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <test_backtrace>:
#include <kern/console.h>

// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	53                   	push   %ebx
f0100044:	83 ec 0c             	sub    $0xc,%esp
f0100047:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("entering test_backtrace %d\n", x);
f010004a:	53                   	push   %ebx
f010004b:	68 c0 18 10 f0       	push   $0xf01018c0
f0100050:	e8 1a 09 00 00       	call   f010096f <cprintf>
	if (x > 0)
f0100055:	83 c4 10             	add    $0x10,%esp
f0100058:	85 db                	test   %ebx,%ebx
f010005a:	7e 11                	jle    f010006d <test_backtrace+0x2d>
		test_backtrace(x-1);
f010005c:	83 ec 0c             	sub    $0xc,%esp
f010005f:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0100062:	50                   	push   %eax
f0100063:	e8 d8 ff ff ff       	call   f0100040 <test_backtrace>
f0100068:	83 c4 10             	add    $0x10,%esp
f010006b:	eb 11                	jmp    f010007e <test_backtrace+0x3e>
	else
		mon_backtrace(0, 0, 0);
f010006d:	83 ec 04             	sub    $0x4,%esp
f0100070:	6a 00                	push   $0x0
f0100072:	6a 00                	push   $0x0
f0100074:	6a 00                	push   $0x0
f0100076:	e8 f3 06 00 00       	call   f010076e <mon_backtrace>
f010007b:	83 c4 10             	add    $0x10,%esp
	cprintf("leaving test_backtrace %d\n", x);
f010007e:	83 ec 08             	sub    $0x8,%esp
f0100081:	53                   	push   %ebx
f0100082:	68 dc 18 10 f0       	push   $0xf01018dc
f0100087:	e8 e3 08 00 00       	call   f010096f <cprintf>
}
f010008c:	83 c4 10             	add    $0x10,%esp
f010008f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100092:	c9                   	leave  
f0100093:	c3                   	ret    

f0100094 <i386_init>:

void
i386_init(void)
{
f0100094:	55                   	push   %ebp
f0100095:	89 e5                	mov    %esp,%ebp
f0100097:	83 ec 0c             	sub    $0xc,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f010009a:	b8 40 29 11 f0       	mov    $0xf0112940,%eax
f010009f:	2d 00 23 11 f0       	sub    $0xf0112300,%eax
f01000a4:	50                   	push   %eax
f01000a5:	6a 00                	push   $0x0
f01000a7:	68 00 23 11 f0       	push   $0xf0112300
f01000ac:	e8 77 13 00 00       	call   f0101428 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000b1:	e8 9d 04 00 00       	call   f0100553 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000b6:	83 c4 08             	add    $0x8,%esp
f01000b9:	68 ac 1a 00 00       	push   $0x1aac
f01000be:	68 f7 18 10 f0       	push   $0xf01018f7
f01000c3:	e8 a7 08 00 00       	call   f010096f <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000c8:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000cf:	e8 6c ff ff ff       	call   f0100040 <test_backtrace>
f01000d4:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000d7:	83 ec 0c             	sub    $0xc,%esp
f01000da:	6a 00                	push   $0x0
f01000dc:	e8 0e 07 00 00       	call   f01007ef <monitor>
f01000e1:	83 c4 10             	add    $0x10,%esp
f01000e4:	eb f1                	jmp    f01000d7 <i386_init+0x43>

f01000e6 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000e6:	55                   	push   %ebp
f01000e7:	89 e5                	mov    %esp,%ebp
f01000e9:	56                   	push   %esi
f01000ea:	53                   	push   %ebx
f01000eb:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f01000ee:	83 3d 44 29 11 f0 00 	cmpl   $0x0,0xf0112944
f01000f5:	75 37                	jne    f010012e <_panic+0x48>
		goto dead;
	panicstr = fmt;
f01000f7:	89 35 44 29 11 f0    	mov    %esi,0xf0112944

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f01000fd:	fa                   	cli    
f01000fe:	fc                   	cld    

	va_start(ap, fmt);
f01000ff:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f0100102:	83 ec 04             	sub    $0x4,%esp
f0100105:	ff 75 0c             	pushl  0xc(%ebp)
f0100108:	ff 75 08             	pushl  0x8(%ebp)
f010010b:	68 12 19 10 f0       	push   $0xf0101912
f0100110:	e8 5a 08 00 00       	call   f010096f <cprintf>
	vcprintf(fmt, ap);
f0100115:	83 c4 08             	add    $0x8,%esp
f0100118:	53                   	push   %ebx
f0100119:	56                   	push   %esi
f010011a:	e8 2a 08 00 00       	call   f0100949 <vcprintf>
	cprintf("\n");
f010011f:	c7 04 24 4e 19 10 f0 	movl   $0xf010194e,(%esp)
f0100126:	e8 44 08 00 00       	call   f010096f <cprintf>
	va_end(ap);
f010012b:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010012e:	83 ec 0c             	sub    $0xc,%esp
f0100131:	6a 00                	push   $0x0
f0100133:	e8 b7 06 00 00       	call   f01007ef <monitor>
f0100138:	83 c4 10             	add    $0x10,%esp
f010013b:	eb f1                	jmp    f010012e <_panic+0x48>

f010013d <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f010013d:	55                   	push   %ebp
f010013e:	89 e5                	mov    %esp,%ebp
f0100140:	53                   	push   %ebx
f0100141:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100144:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100147:	ff 75 0c             	pushl  0xc(%ebp)
f010014a:	ff 75 08             	pushl  0x8(%ebp)
f010014d:	68 2a 19 10 f0       	push   $0xf010192a
f0100152:	e8 18 08 00 00       	call   f010096f <cprintf>
	vcprintf(fmt, ap);
f0100157:	83 c4 08             	add    $0x8,%esp
f010015a:	53                   	push   %ebx
f010015b:	ff 75 10             	pushl  0x10(%ebp)
f010015e:	e8 e6 07 00 00       	call   f0100949 <vcprintf>
	cprintf("\n");
f0100163:	c7 04 24 4e 19 10 f0 	movl   $0xf010194e,(%esp)
f010016a:	e8 00 08 00 00       	call   f010096f <cprintf>
	va_end(ap);
}
f010016f:	83 c4 10             	add    $0x10,%esp
f0100172:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100175:	c9                   	leave  
f0100176:	c3                   	ret    

f0100177 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100177:	55                   	push   %ebp
f0100178:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010017a:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010017f:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100180:	a8 01                	test   $0x1,%al
f0100182:	74 0b                	je     f010018f <serial_proc_data+0x18>
f0100184:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100189:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f010018a:	0f b6 c0             	movzbl %al,%eax
f010018d:	eb 05                	jmp    f0100194 <serial_proc_data+0x1d>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f010018f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f0100194:	5d                   	pop    %ebp
f0100195:	c3                   	ret    

f0100196 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f0100196:	55                   	push   %ebp
f0100197:	89 e5                	mov    %esp,%ebp
f0100199:	53                   	push   %ebx
f010019a:	83 ec 04             	sub    $0x4,%esp
f010019d:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f010019f:	eb 2b                	jmp    f01001cc <cons_intr+0x36>
		if (c == 0)
f01001a1:	85 c0                	test   %eax,%eax
f01001a3:	74 27                	je     f01001cc <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f01001a5:	8b 0d 24 25 11 f0    	mov    0xf0112524,%ecx
f01001ab:	8d 51 01             	lea    0x1(%ecx),%edx
f01001ae:	89 15 24 25 11 f0    	mov    %edx,0xf0112524
f01001b4:	88 81 20 23 11 f0    	mov    %al,-0xfeedce0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f01001ba:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01001c0:	75 0a                	jne    f01001cc <cons_intr+0x36>
			cons.wpos = 0;
f01001c2:	c7 05 24 25 11 f0 00 	movl   $0x0,0xf0112524
f01001c9:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01001cc:	ff d3                	call   *%ebx
f01001ce:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001d1:	75 ce                	jne    f01001a1 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01001d3:	83 c4 04             	add    $0x4,%esp
f01001d6:	5b                   	pop    %ebx
f01001d7:	5d                   	pop    %ebp
f01001d8:	c3                   	ret    

f01001d9 <kbd_proc_data>:
f01001d9:	ba 64 00 00 00       	mov    $0x64,%edx
f01001de:	ec                   	in     (%dx),%al
	int c;
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
f01001df:	a8 01                	test   $0x1,%al
f01001e1:	0f 84 f8 00 00 00    	je     f01002df <kbd_proc_data+0x106>
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
f01001e7:	a8 20                	test   $0x20,%al
f01001e9:	0f 85 f6 00 00 00    	jne    f01002e5 <kbd_proc_data+0x10c>
f01001ef:	ba 60 00 00 00       	mov    $0x60,%edx
f01001f4:	ec                   	in     (%dx),%al
f01001f5:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01001f7:	3c e0                	cmp    $0xe0,%al
f01001f9:	75 0d                	jne    f0100208 <kbd_proc_data+0x2f>
		// E0 escape character
		shift |= E0ESC;
f01001fb:	83 0d 00 23 11 f0 40 	orl    $0x40,0xf0112300
		return 0;
f0100202:	b8 00 00 00 00       	mov    $0x0,%eax
f0100207:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f0100208:	55                   	push   %ebp
f0100209:	89 e5                	mov    %esp,%ebp
f010020b:	53                   	push   %ebx
f010020c:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f010020f:	84 c0                	test   %al,%al
f0100211:	79 36                	jns    f0100249 <kbd_proc_data+0x70>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f0100213:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f0100219:	89 cb                	mov    %ecx,%ebx
f010021b:	83 e3 40             	and    $0x40,%ebx
f010021e:	83 e0 7f             	and    $0x7f,%eax
f0100221:	85 db                	test   %ebx,%ebx
f0100223:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100226:	0f b6 d2             	movzbl %dl,%edx
f0100229:	0f b6 82 a0 1a 10 f0 	movzbl -0xfefe560(%edx),%eax
f0100230:	83 c8 40             	or     $0x40,%eax
f0100233:	0f b6 c0             	movzbl %al,%eax
f0100236:	f7 d0                	not    %eax
f0100238:	21 c8                	and    %ecx,%eax
f010023a:	a3 00 23 11 f0       	mov    %eax,0xf0112300
		return 0;
f010023f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100244:	e9 a4 00 00 00       	jmp    f01002ed <kbd_proc_data+0x114>
	} else if (shift & E0ESC) {
f0100249:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f010024f:	f6 c1 40             	test   $0x40,%cl
f0100252:	74 0e                	je     f0100262 <kbd_proc_data+0x89>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100254:	83 c8 80             	or     $0xffffff80,%eax
f0100257:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100259:	83 e1 bf             	and    $0xffffffbf,%ecx
f010025c:	89 0d 00 23 11 f0    	mov    %ecx,0xf0112300
	}

	shift |= shiftcode[data];
f0100262:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f0100265:	0f b6 82 a0 1a 10 f0 	movzbl -0xfefe560(%edx),%eax
f010026c:	0b 05 00 23 11 f0    	or     0xf0112300,%eax
f0100272:	0f b6 8a a0 19 10 f0 	movzbl -0xfefe660(%edx),%ecx
f0100279:	31 c8                	xor    %ecx,%eax
f010027b:	a3 00 23 11 f0       	mov    %eax,0xf0112300

	c = charcode[shift & (CTL | SHIFT)][data];
f0100280:	89 c1                	mov    %eax,%ecx
f0100282:	83 e1 03             	and    $0x3,%ecx
f0100285:	8b 0c 8d 80 19 10 f0 	mov    -0xfefe680(,%ecx,4),%ecx
f010028c:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0100290:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100293:	a8 08                	test   $0x8,%al
f0100295:	74 1b                	je     f01002b2 <kbd_proc_data+0xd9>
		if ('a' <= c && c <= 'z')
f0100297:	89 da                	mov    %ebx,%edx
f0100299:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f010029c:	83 f9 19             	cmp    $0x19,%ecx
f010029f:	77 05                	ja     f01002a6 <kbd_proc_data+0xcd>
			c += 'A' - 'a';
f01002a1:	83 eb 20             	sub    $0x20,%ebx
f01002a4:	eb 0c                	jmp    f01002b2 <kbd_proc_data+0xd9>
		else if ('A' <= c && c <= 'Z')
f01002a6:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f01002a9:	8d 4b 20             	lea    0x20(%ebx),%ecx
f01002ac:	83 fa 19             	cmp    $0x19,%edx
f01002af:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002b2:	f7 d0                	not    %eax
f01002b4:	a8 06                	test   $0x6,%al
f01002b6:	75 33                	jne    f01002eb <kbd_proc_data+0x112>
f01002b8:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01002be:	75 2b                	jne    f01002eb <kbd_proc_data+0x112>
		cprintf("Rebooting!\n");
f01002c0:	83 ec 0c             	sub    $0xc,%esp
f01002c3:	68 44 19 10 f0       	push   $0xf0101944
f01002c8:	e8 a2 06 00 00       	call   f010096f <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002cd:	ba 92 00 00 00       	mov    $0x92,%edx
f01002d2:	b8 03 00 00 00       	mov    $0x3,%eax
f01002d7:	ee                   	out    %al,(%dx)
f01002d8:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002db:	89 d8                	mov    %ebx,%eax
f01002dd:	eb 0e                	jmp    f01002ed <kbd_proc_data+0x114>
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
f01002df:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01002e4:	c3                   	ret    
	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
		return -1;
f01002e5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01002ea:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002eb:	89 d8                	mov    %ebx,%eax
}
f01002ed:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01002f0:	c9                   	leave  
f01002f1:	c3                   	ret    

f01002f2 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01002f2:	55                   	push   %ebp
f01002f3:	89 e5                	mov    %esp,%ebp
f01002f5:	57                   	push   %edi
f01002f6:	56                   	push   %esi
f01002f7:	53                   	push   %ebx
f01002f8:	83 ec 1c             	sub    $0x1c,%esp
f01002fb:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01002fd:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100302:	be fd 03 00 00       	mov    $0x3fd,%esi
f0100307:	b9 84 00 00 00       	mov    $0x84,%ecx
f010030c:	eb 09                	jmp    f0100317 <cons_putc+0x25>
f010030e:	89 ca                	mov    %ecx,%edx
f0100310:	ec                   	in     (%dx),%al
f0100311:	ec                   	in     (%dx),%al
f0100312:	ec                   	in     (%dx),%al
f0100313:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f0100314:	83 c3 01             	add    $0x1,%ebx
f0100317:	89 f2                	mov    %esi,%edx
f0100319:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f010031a:	a8 20                	test   $0x20,%al
f010031c:	75 08                	jne    f0100326 <cons_putc+0x34>
f010031e:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100324:	7e e8                	jle    f010030e <cons_putc+0x1c>
f0100326:	89 f8                	mov    %edi,%eax
f0100328:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010032b:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100330:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100331:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100336:	be 79 03 00 00       	mov    $0x379,%esi
f010033b:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100340:	eb 09                	jmp    f010034b <cons_putc+0x59>
f0100342:	89 ca                	mov    %ecx,%edx
f0100344:	ec                   	in     (%dx),%al
f0100345:	ec                   	in     (%dx),%al
f0100346:	ec                   	in     (%dx),%al
f0100347:	ec                   	in     (%dx),%al
f0100348:	83 c3 01             	add    $0x1,%ebx
f010034b:	89 f2                	mov    %esi,%edx
f010034d:	ec                   	in     (%dx),%al
f010034e:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100354:	7f 04                	jg     f010035a <cons_putc+0x68>
f0100356:	84 c0                	test   %al,%al
f0100358:	79 e8                	jns    f0100342 <cons_putc+0x50>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010035a:	ba 78 03 00 00       	mov    $0x378,%edx
f010035f:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f0100363:	ee                   	out    %al,(%dx)
f0100364:	ba 7a 03 00 00       	mov    $0x37a,%edx
f0100369:	b8 0d 00 00 00       	mov    $0xd,%eax
f010036e:	ee                   	out    %al,(%dx)
f010036f:	b8 08 00 00 00       	mov    $0x8,%eax
f0100374:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100375:	89 fa                	mov    %edi,%edx
f0100377:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f010037d:	89 f8                	mov    %edi,%eax
f010037f:	80 cc 07             	or     $0x7,%ah
f0100382:	85 d2                	test   %edx,%edx
f0100384:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100387:	89 f8                	mov    %edi,%eax
f0100389:	0f b6 c0             	movzbl %al,%eax
f010038c:	83 f8 09             	cmp    $0x9,%eax
f010038f:	74 74                	je     f0100405 <cons_putc+0x113>
f0100391:	83 f8 09             	cmp    $0x9,%eax
f0100394:	7f 0a                	jg     f01003a0 <cons_putc+0xae>
f0100396:	83 f8 08             	cmp    $0x8,%eax
f0100399:	74 14                	je     f01003af <cons_putc+0xbd>
f010039b:	e9 99 00 00 00       	jmp    f0100439 <cons_putc+0x147>
f01003a0:	83 f8 0a             	cmp    $0xa,%eax
f01003a3:	74 3a                	je     f01003df <cons_putc+0xed>
f01003a5:	83 f8 0d             	cmp    $0xd,%eax
f01003a8:	74 3d                	je     f01003e7 <cons_putc+0xf5>
f01003aa:	e9 8a 00 00 00       	jmp    f0100439 <cons_putc+0x147>
	case '\b':
		if (crt_pos > 0) {
f01003af:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f01003b6:	66 85 c0             	test   %ax,%ax
f01003b9:	0f 84 e6 00 00 00    	je     f01004a5 <cons_putc+0x1b3>
			crt_pos--;
f01003bf:	83 e8 01             	sub    $0x1,%eax
f01003c2:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01003c8:	0f b7 c0             	movzwl %ax,%eax
f01003cb:	66 81 e7 00 ff       	and    $0xff00,%di
f01003d0:	83 cf 20             	or     $0x20,%edi
f01003d3:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f01003d9:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01003dd:	eb 78                	jmp    f0100457 <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01003df:	66 83 05 28 25 11 f0 	addw   $0x50,0xf0112528
f01003e6:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01003e7:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f01003ee:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003f4:	c1 e8 16             	shr    $0x16,%eax
f01003f7:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003fa:	c1 e0 04             	shl    $0x4,%eax
f01003fd:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
f0100403:	eb 52                	jmp    f0100457 <cons_putc+0x165>
		break;
	case '\t':
		cons_putc(' ');
f0100405:	b8 20 00 00 00       	mov    $0x20,%eax
f010040a:	e8 e3 fe ff ff       	call   f01002f2 <cons_putc>
		cons_putc(' ');
f010040f:	b8 20 00 00 00       	mov    $0x20,%eax
f0100414:	e8 d9 fe ff ff       	call   f01002f2 <cons_putc>
		cons_putc(' ');
f0100419:	b8 20 00 00 00       	mov    $0x20,%eax
f010041e:	e8 cf fe ff ff       	call   f01002f2 <cons_putc>
		cons_putc(' ');
f0100423:	b8 20 00 00 00       	mov    $0x20,%eax
f0100428:	e8 c5 fe ff ff       	call   f01002f2 <cons_putc>
		cons_putc(' ');
f010042d:	b8 20 00 00 00       	mov    $0x20,%eax
f0100432:	e8 bb fe ff ff       	call   f01002f2 <cons_putc>
f0100437:	eb 1e                	jmp    f0100457 <cons_putc+0x165>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100439:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f0100440:	8d 50 01             	lea    0x1(%eax),%edx
f0100443:	66 89 15 28 25 11 f0 	mov    %dx,0xf0112528
f010044a:	0f b7 c0             	movzwl %ax,%eax
f010044d:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f0100453:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	// if the screen is full
	if (crt_pos >= CRT_SIZE) {
f0100457:	66 81 3d 28 25 11 f0 	cmpw   $0x7cf,0xf0112528
f010045e:	cf 07 
f0100460:	76 43                	jbe    f01004a5 <cons_putc+0x1b3>
		int i;
		// move all the content one line above
		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100462:	a1 2c 25 11 f0       	mov    0xf011252c,%eax
f0100467:	83 ec 04             	sub    $0x4,%esp
f010046a:	68 00 0f 00 00       	push   $0xf00
f010046f:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100475:	52                   	push   %edx
f0100476:	50                   	push   %eax
f0100477:	e8 f9 0f 00 00       	call   f0101475 <memmove>
		// clear the last line and set the cursor
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f010047c:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f0100482:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f0100488:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f010048e:	83 c4 10             	add    $0x10,%esp
f0100491:	66 c7 00 20 07       	movw   $0x720,(%eax)
f0100496:	83 c0 02             	add    $0x2,%eax
	if (crt_pos >= CRT_SIZE) {
		int i;
		// move all the content one line above
		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		// clear the last line and set the cursor
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100499:	39 d0                	cmp    %edx,%eax
f010049b:	75 f4                	jne    f0100491 <cons_putc+0x19f>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f010049d:	66 83 2d 28 25 11 f0 	subw   $0x50,0xf0112528
f01004a4:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f01004a5:	8b 0d 30 25 11 f0    	mov    0xf0112530,%ecx
f01004ab:	b8 0e 00 00 00       	mov    $0xe,%eax
f01004b0:	89 ca                	mov    %ecx,%edx
f01004b2:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01004b3:	0f b7 1d 28 25 11 f0 	movzwl 0xf0112528,%ebx
f01004ba:	8d 71 01             	lea    0x1(%ecx),%esi
f01004bd:	89 d8                	mov    %ebx,%eax
f01004bf:	66 c1 e8 08          	shr    $0x8,%ax
f01004c3:	89 f2                	mov    %esi,%edx
f01004c5:	ee                   	out    %al,(%dx)
f01004c6:	b8 0f 00 00 00       	mov    $0xf,%eax
f01004cb:	89 ca                	mov    %ecx,%edx
f01004cd:	ee                   	out    %al,(%dx)
f01004ce:	89 d8                	mov    %ebx,%eax
f01004d0:	89 f2                	mov    %esi,%edx
f01004d2:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01004d3:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01004d6:	5b                   	pop    %ebx
f01004d7:	5e                   	pop    %esi
f01004d8:	5f                   	pop    %edi
f01004d9:	5d                   	pop    %ebp
f01004da:	c3                   	ret    

f01004db <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01004db:	80 3d 34 25 11 f0 00 	cmpb   $0x0,0xf0112534
f01004e2:	74 11                	je     f01004f5 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01004e4:	55                   	push   %ebp
f01004e5:	89 e5                	mov    %esp,%ebp
f01004e7:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f01004ea:	b8 77 01 10 f0       	mov    $0xf0100177,%eax
f01004ef:	e8 a2 fc ff ff       	call   f0100196 <cons_intr>
}
f01004f4:	c9                   	leave  
f01004f5:	f3 c3                	repz ret 

f01004f7 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01004f7:	55                   	push   %ebp
f01004f8:	89 e5                	mov    %esp,%ebp
f01004fa:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004fd:	b8 d9 01 10 f0       	mov    $0xf01001d9,%eax
f0100502:	e8 8f fc ff ff       	call   f0100196 <cons_intr>
}
f0100507:	c9                   	leave  
f0100508:	c3                   	ret    

f0100509 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f0100509:	55                   	push   %ebp
f010050a:	89 e5                	mov    %esp,%ebp
f010050c:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f010050f:	e8 c7 ff ff ff       	call   f01004db <serial_intr>
	kbd_intr();
f0100514:	e8 de ff ff ff       	call   f01004f7 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100519:	a1 20 25 11 f0       	mov    0xf0112520,%eax
f010051e:	3b 05 24 25 11 f0    	cmp    0xf0112524,%eax
f0100524:	74 26                	je     f010054c <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f0100526:	8d 50 01             	lea    0x1(%eax),%edx
f0100529:	89 15 20 25 11 f0    	mov    %edx,0xf0112520
f010052f:	0f b6 88 20 23 11 f0 	movzbl -0xfeedce0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f0100536:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f0100538:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010053e:	75 11                	jne    f0100551 <cons_getc+0x48>
			cons.rpos = 0;
f0100540:	c7 05 20 25 11 f0 00 	movl   $0x0,0xf0112520
f0100547:	00 00 00 
f010054a:	eb 05                	jmp    f0100551 <cons_getc+0x48>
		return c;
	}
	return 0;
f010054c:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100551:	c9                   	leave  
f0100552:	c3                   	ret    

f0100553 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f0100553:	55                   	push   %ebp
f0100554:	89 e5                	mov    %esp,%ebp
f0100556:	57                   	push   %edi
f0100557:	56                   	push   %esi
f0100558:	53                   	push   %ebx
f0100559:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f010055c:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f0100563:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f010056a:	5a a5 
	if (*cp != 0xA55A) {
f010056c:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f0100573:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100577:	74 11                	je     f010058a <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100579:	c7 05 30 25 11 f0 b4 	movl   $0x3b4,0xf0112530
f0100580:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100583:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f0100588:	eb 16                	jmp    f01005a0 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f010058a:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100591:	c7 05 30 25 11 f0 d4 	movl   $0x3d4,0xf0112530
f0100598:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f010059b:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f01005a0:	8b 3d 30 25 11 f0    	mov    0xf0112530,%edi
f01005a6:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005ab:	89 fa                	mov    %edi,%edx
f01005ad:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01005ae:	8d 5f 01             	lea    0x1(%edi),%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005b1:	89 da                	mov    %ebx,%edx
f01005b3:	ec                   	in     (%dx),%al
f01005b4:	0f b6 c8             	movzbl %al,%ecx
f01005b7:	c1 e1 08             	shl    $0x8,%ecx
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005ba:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005bf:	89 fa                	mov    %edi,%edx
f01005c1:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005c2:	89 da                	mov    %ebx,%edx
f01005c4:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01005c5:	89 35 2c 25 11 f0    	mov    %esi,0xf011252c
	crt_pos = pos;
f01005cb:	0f b6 c0             	movzbl %al,%eax
f01005ce:	09 c8                	or     %ecx,%eax
f01005d0:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005d6:	be fa 03 00 00       	mov    $0x3fa,%esi
f01005db:	b8 00 00 00 00       	mov    $0x0,%eax
f01005e0:	89 f2                	mov    %esi,%edx
f01005e2:	ee                   	out    %al,(%dx)
f01005e3:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005e8:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01005ed:	ee                   	out    %al,(%dx)
f01005ee:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f01005f3:	b8 0c 00 00 00       	mov    $0xc,%eax
f01005f8:	89 da                	mov    %ebx,%edx
f01005fa:	ee                   	out    %al,(%dx)
f01005fb:	ba f9 03 00 00       	mov    $0x3f9,%edx
f0100600:	b8 00 00 00 00       	mov    $0x0,%eax
f0100605:	ee                   	out    %al,(%dx)
f0100606:	ba fb 03 00 00       	mov    $0x3fb,%edx
f010060b:	b8 03 00 00 00       	mov    $0x3,%eax
f0100610:	ee                   	out    %al,(%dx)
f0100611:	ba fc 03 00 00       	mov    $0x3fc,%edx
f0100616:	b8 00 00 00 00       	mov    $0x0,%eax
f010061b:	ee                   	out    %al,(%dx)
f010061c:	ba f9 03 00 00       	mov    $0x3f9,%edx
f0100621:	b8 01 00 00 00       	mov    $0x1,%eax
f0100626:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100627:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010062c:	ec                   	in     (%dx),%al
f010062d:	89 c1                	mov    %eax,%ecx
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f010062f:	3c ff                	cmp    $0xff,%al
f0100631:	0f 95 05 34 25 11 f0 	setne  0xf0112534
f0100638:	89 f2                	mov    %esi,%edx
f010063a:	ec                   	in     (%dx),%al
f010063b:	89 da                	mov    %ebx,%edx
f010063d:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f010063e:	80 f9 ff             	cmp    $0xff,%cl
f0100641:	75 10                	jne    f0100653 <cons_init+0x100>
		cprintf("Serial port does not exist!\n");
f0100643:	83 ec 0c             	sub    $0xc,%esp
f0100646:	68 50 19 10 f0       	push   $0xf0101950
f010064b:	e8 1f 03 00 00       	call   f010096f <cprintf>
f0100650:	83 c4 10             	add    $0x10,%esp
}
f0100653:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100656:	5b                   	pop    %ebx
f0100657:	5e                   	pop    %esi
f0100658:	5f                   	pop    %edi
f0100659:	5d                   	pop    %ebp
f010065a:	c3                   	ret    

f010065b <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f010065b:	55                   	push   %ebp
f010065c:	89 e5                	mov    %esp,%ebp
f010065e:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100661:	8b 45 08             	mov    0x8(%ebp),%eax
f0100664:	e8 89 fc ff ff       	call   f01002f2 <cons_putc>
}
f0100669:	c9                   	leave  
f010066a:	c3                   	ret    

f010066b <getchar>:

int
getchar(void)
{
f010066b:	55                   	push   %ebp
f010066c:	89 e5                	mov    %esp,%ebp
f010066e:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100671:	e8 93 fe ff ff       	call   f0100509 <cons_getc>
f0100676:	85 c0                	test   %eax,%eax
f0100678:	74 f7                	je     f0100671 <getchar+0x6>
		/* do nothing */;
	return c;
}
f010067a:	c9                   	leave  
f010067b:	c3                   	ret    

f010067c <iscons>:

int
iscons(int fdnum)
{
f010067c:	55                   	push   %ebp
f010067d:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f010067f:	b8 01 00 00 00       	mov    $0x1,%eax
f0100684:	5d                   	pop    %ebp
f0100685:	c3                   	ret    

f0100686 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100686:	55                   	push   %ebp
f0100687:	89 e5                	mov    %esp,%ebp
f0100689:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f010068c:	68 a0 1b 10 f0       	push   $0xf0101ba0
f0100691:	68 be 1b 10 f0       	push   $0xf0101bbe
f0100696:	68 c3 1b 10 f0       	push   $0xf0101bc3
f010069b:	e8 cf 02 00 00       	call   f010096f <cprintf>
f01006a0:	83 c4 0c             	add    $0xc,%esp
f01006a3:	68 50 1c 10 f0       	push   $0xf0101c50
f01006a8:	68 cc 1b 10 f0       	push   $0xf0101bcc
f01006ad:	68 c3 1b 10 f0       	push   $0xf0101bc3
f01006b2:	e8 b8 02 00 00       	call   f010096f <cprintf>
	return 0;
}
f01006b7:	b8 00 00 00 00       	mov    $0x0,%eax
f01006bc:	c9                   	leave  
f01006bd:	c3                   	ret    

f01006be <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01006be:	55                   	push   %ebp
f01006bf:	89 e5                	mov    %esp,%ebp
f01006c1:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01006c4:	68 d5 1b 10 f0       	push   $0xf0101bd5
f01006c9:	e8 a1 02 00 00       	call   f010096f <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01006ce:	83 c4 08             	add    $0x8,%esp
f01006d1:	68 0c 00 10 00       	push   $0x10000c
f01006d6:	68 78 1c 10 f0       	push   $0xf0101c78
f01006db:	e8 8f 02 00 00       	call   f010096f <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006e0:	83 c4 0c             	add    $0xc,%esp
f01006e3:	68 0c 00 10 00       	push   $0x10000c
f01006e8:	68 0c 00 10 f0       	push   $0xf010000c
f01006ed:	68 a0 1c 10 f0       	push   $0xf0101ca0
f01006f2:	e8 78 02 00 00       	call   f010096f <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006f7:	83 c4 0c             	add    $0xc,%esp
f01006fa:	68 b1 18 10 00       	push   $0x1018b1
f01006ff:	68 b1 18 10 f0       	push   $0xf01018b1
f0100704:	68 c4 1c 10 f0       	push   $0xf0101cc4
f0100709:	e8 61 02 00 00       	call   f010096f <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010070e:	83 c4 0c             	add    $0xc,%esp
f0100711:	68 00 23 11 00       	push   $0x112300
f0100716:	68 00 23 11 f0       	push   $0xf0112300
f010071b:	68 e8 1c 10 f0       	push   $0xf0101ce8
f0100720:	e8 4a 02 00 00       	call   f010096f <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100725:	83 c4 0c             	add    $0xc,%esp
f0100728:	68 40 29 11 00       	push   $0x112940
f010072d:	68 40 29 11 f0       	push   $0xf0112940
f0100732:	68 0c 1d 10 f0       	push   $0xf0101d0c
f0100737:	e8 33 02 00 00       	call   f010096f <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f010073c:	b8 3f 2d 11 f0       	mov    $0xf0112d3f,%eax
f0100741:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100746:	83 c4 08             	add    $0x8,%esp
f0100749:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f010074e:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100754:	85 c0                	test   %eax,%eax
f0100756:	0f 48 c2             	cmovs  %edx,%eax
f0100759:	c1 f8 0a             	sar    $0xa,%eax
f010075c:	50                   	push   %eax
f010075d:	68 30 1d 10 f0       	push   $0xf0101d30
f0100762:	e8 08 02 00 00       	call   f010096f <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100767:	b8 00 00 00 00       	mov    $0x0,%eax
f010076c:	c9                   	leave  
f010076d:	c3                   	ret    

f010076e <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f010076e:	55                   	push   %ebp
f010076f:	89 e5                	mov    %esp,%ebp
f0100771:	56                   	push   %esi
f0100772:	53                   	push   %ebx
f0100773:	83 ec 2c             	sub    $0x2c,%esp

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f0100776:	89 eb                	mov    %ebp,%ebx
		ebp f0109ed8  eip f01000d6  args 00000000 00000000 f0100058 f0109f28 00000061
  ...
	*/
	uint32_t ebp=read_ebp(); // current func's start 
	struct Eipdebuginfo info;
	cprintf("Stack backtrace:\n");
f0100778:	68 ee 1b 10 f0       	push   $0xf0101bee
f010077d:	e8 ed 01 00 00       	call   f010096f <cprintf>
	while (ebp != 0) {
f0100782:	83 c4 10             	add    $0x10,%esp
		cprintf("  ebp %08x  eip %08x  args %08x %08x %08x %08x %08x\n", ebp, *((uint32_t*)ebp+1),\
		*((uint32_t*)ebp+2),*((uint32_t*)ebp+3),*((uint32_t*)ebp+4), *((uint32_t*)ebp+5), *((uint32_t*)ebp+6));
		
		if (debuginfo_eip(*((uint32_t*)ebp+1), &info) == 0) {
f0100785:	8d 75 e0             	lea    -0x20(%ebp),%esi
  ...
	*/
	uint32_t ebp=read_ebp(); // current func's start 
	struct Eipdebuginfo info;
	cprintf("Stack backtrace:\n");
	while (ebp != 0) {
f0100788:	eb 55                	jmp    f01007df <mon_backtrace+0x71>
		cprintf("  ebp %08x  eip %08x  args %08x %08x %08x %08x %08x\n", ebp, *((uint32_t*)ebp+1),\
f010078a:	ff 73 18             	pushl  0x18(%ebx)
f010078d:	ff 73 14             	pushl  0x14(%ebx)
f0100790:	ff 73 10             	pushl  0x10(%ebx)
f0100793:	ff 73 0c             	pushl  0xc(%ebx)
f0100796:	ff 73 08             	pushl  0x8(%ebx)
f0100799:	ff 73 04             	pushl  0x4(%ebx)
f010079c:	53                   	push   %ebx
f010079d:	68 5c 1d 10 f0       	push   $0xf0101d5c
f01007a2:	e8 c8 01 00 00       	call   f010096f <cprintf>
		*((uint32_t*)ebp+2),*((uint32_t*)ebp+3),*((uint32_t*)ebp+4), *((uint32_t*)ebp+5), *((uint32_t*)ebp+6));
		
		if (debuginfo_eip(*((uint32_t*)ebp+1), &info) == 0) {
f01007a7:	83 c4 18             	add    $0x18,%esp
f01007aa:	56                   	push   %esi
f01007ab:	ff 73 04             	pushl  0x4(%ebx)
f01007ae:	e8 c6 02 00 00       	call   f0100a79 <debuginfo_eip>
f01007b3:	83 c4 10             	add    $0x10,%esp
f01007b6:	85 c0                	test   %eax,%eax
f01007b8:	75 23                	jne    f01007dd <mon_backtrace+0x6f>
            uint32_t fn_offset = *((uint32_t*)ebp+1) - info.eip_fn_addr;
            cprintf("\t\t %s:%d: %.*s+%d\n", info.eip_file, info.eip_line,info.eip_fn_namelen,  info.eip_fn_name, fn_offset);
f01007ba:	83 ec 08             	sub    $0x8,%esp
f01007bd:	8b 43 04             	mov    0x4(%ebx),%eax
f01007c0:	2b 45 f0             	sub    -0x10(%ebp),%eax
f01007c3:	50                   	push   %eax
f01007c4:	ff 75 e8             	pushl  -0x18(%ebp)
f01007c7:	ff 75 ec             	pushl  -0x14(%ebp)
f01007ca:	ff 75 e4             	pushl  -0x1c(%ebp)
f01007cd:	ff 75 e0             	pushl  -0x20(%ebp)
f01007d0:	68 00 1c 10 f0       	push   $0xf0101c00
f01007d5:	e8 95 01 00 00       	call   f010096f <cprintf>
f01007da:	83 c4 20             	add    $0x20,%esp
        }
		ebp = *(uint32_t*)ebp;
f01007dd:	8b 1b                	mov    (%ebx),%ebx
  ...
	*/
	uint32_t ebp=read_ebp(); // current func's start 
	struct Eipdebuginfo info;
	cprintf("Stack backtrace:\n");
	while (ebp != 0) {
f01007df:	85 db                	test   %ebx,%ebx
f01007e1:	75 a7                	jne    f010078a <mon_backtrace+0x1c>
        }
		ebp = *(uint32_t*)ebp;
	}

	return 0;
}
f01007e3:	b8 00 00 00 00       	mov    $0x0,%eax
f01007e8:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01007eb:	5b                   	pop    %ebx
f01007ec:	5e                   	pop    %esi
f01007ed:	5d                   	pop    %ebp
f01007ee:	c3                   	ret    

f01007ef <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01007ef:	55                   	push   %ebp
f01007f0:	89 e5                	mov    %esp,%ebp
f01007f2:	57                   	push   %edi
f01007f3:	56                   	push   %esi
f01007f4:	53                   	push   %ebx
f01007f5:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01007f8:	68 94 1d 10 f0       	push   $0xf0101d94
f01007fd:	e8 6d 01 00 00       	call   f010096f <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100802:	c7 04 24 b8 1d 10 f0 	movl   $0xf0101db8,(%esp)
f0100809:	e8 61 01 00 00       	call   f010096f <cprintf>
f010080e:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f0100811:	83 ec 0c             	sub    $0xc,%esp
f0100814:	68 13 1c 10 f0       	push   $0xf0101c13
f0100819:	e8 b3 09 00 00       	call   f01011d1 <readline>
f010081e:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100820:	83 c4 10             	add    $0x10,%esp
f0100823:	85 c0                	test   %eax,%eax
f0100825:	74 ea                	je     f0100811 <monitor+0x22>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100827:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f010082e:	be 00 00 00 00       	mov    $0x0,%esi
f0100833:	eb 0a                	jmp    f010083f <monitor+0x50>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100835:	c6 03 00             	movb   $0x0,(%ebx)
f0100838:	89 f7                	mov    %esi,%edi
f010083a:	8d 5b 01             	lea    0x1(%ebx),%ebx
f010083d:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f010083f:	0f b6 03             	movzbl (%ebx),%eax
f0100842:	84 c0                	test   %al,%al
f0100844:	74 63                	je     f01008a9 <monitor+0xba>
f0100846:	83 ec 08             	sub    $0x8,%esp
f0100849:	0f be c0             	movsbl %al,%eax
f010084c:	50                   	push   %eax
f010084d:	68 17 1c 10 f0       	push   $0xf0101c17
f0100852:	e8 94 0b 00 00       	call   f01013eb <strchr>
f0100857:	83 c4 10             	add    $0x10,%esp
f010085a:	85 c0                	test   %eax,%eax
f010085c:	75 d7                	jne    f0100835 <monitor+0x46>
			*buf++ = 0;
		if (*buf == 0)
f010085e:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100861:	74 46                	je     f01008a9 <monitor+0xba>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100863:	83 fe 0f             	cmp    $0xf,%esi
f0100866:	75 14                	jne    f010087c <monitor+0x8d>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100868:	83 ec 08             	sub    $0x8,%esp
f010086b:	6a 10                	push   $0x10
f010086d:	68 1c 1c 10 f0       	push   $0xf0101c1c
f0100872:	e8 f8 00 00 00       	call   f010096f <cprintf>
f0100877:	83 c4 10             	add    $0x10,%esp
f010087a:	eb 95                	jmp    f0100811 <monitor+0x22>
			return 0;
		}
		argv[argc++] = buf;
f010087c:	8d 7e 01             	lea    0x1(%esi),%edi
f010087f:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100883:	eb 03                	jmp    f0100888 <monitor+0x99>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f0100885:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100888:	0f b6 03             	movzbl (%ebx),%eax
f010088b:	84 c0                	test   %al,%al
f010088d:	74 ae                	je     f010083d <monitor+0x4e>
f010088f:	83 ec 08             	sub    $0x8,%esp
f0100892:	0f be c0             	movsbl %al,%eax
f0100895:	50                   	push   %eax
f0100896:	68 17 1c 10 f0       	push   $0xf0101c17
f010089b:	e8 4b 0b 00 00       	call   f01013eb <strchr>
f01008a0:	83 c4 10             	add    $0x10,%esp
f01008a3:	85 c0                	test   %eax,%eax
f01008a5:	74 de                	je     f0100885 <monitor+0x96>
f01008a7:	eb 94                	jmp    f010083d <monitor+0x4e>
			buf++;
	}
	argv[argc] = 0;
f01008a9:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01008b0:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01008b1:	85 f6                	test   %esi,%esi
f01008b3:	0f 84 58 ff ff ff    	je     f0100811 <monitor+0x22>
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01008b9:	83 ec 08             	sub    $0x8,%esp
f01008bc:	68 be 1b 10 f0       	push   $0xf0101bbe
f01008c1:	ff 75 a8             	pushl  -0x58(%ebp)
f01008c4:	e8 c4 0a 00 00       	call   f010138d <strcmp>
f01008c9:	83 c4 10             	add    $0x10,%esp
f01008cc:	85 c0                	test   %eax,%eax
f01008ce:	74 1e                	je     f01008ee <monitor+0xff>
f01008d0:	83 ec 08             	sub    $0x8,%esp
f01008d3:	68 cc 1b 10 f0       	push   $0xf0101bcc
f01008d8:	ff 75 a8             	pushl  -0x58(%ebp)
f01008db:	e8 ad 0a 00 00       	call   f010138d <strcmp>
f01008e0:	83 c4 10             	add    $0x10,%esp
f01008e3:	85 c0                	test   %eax,%eax
f01008e5:	75 2f                	jne    f0100916 <monitor+0x127>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f01008e7:	b8 01 00 00 00       	mov    $0x1,%eax
f01008ec:	eb 05                	jmp    f01008f3 <monitor+0x104>
		if (strcmp(argv[0], commands[i].name) == 0)
f01008ee:	b8 00 00 00 00       	mov    $0x0,%eax
			return commands[i].func(argc, argv, tf);
f01008f3:	83 ec 04             	sub    $0x4,%esp
f01008f6:	8d 14 00             	lea    (%eax,%eax,1),%edx
f01008f9:	01 d0                	add    %edx,%eax
f01008fb:	ff 75 08             	pushl  0x8(%ebp)
f01008fe:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f0100901:	51                   	push   %ecx
f0100902:	56                   	push   %esi
f0100903:	ff 14 85 e8 1d 10 f0 	call   *-0xfefe218(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f010090a:	83 c4 10             	add    $0x10,%esp
f010090d:	85 c0                	test   %eax,%eax
f010090f:	78 1d                	js     f010092e <monitor+0x13f>
f0100911:	e9 fb fe ff ff       	jmp    f0100811 <monitor+0x22>
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100916:	83 ec 08             	sub    $0x8,%esp
f0100919:	ff 75 a8             	pushl  -0x58(%ebp)
f010091c:	68 39 1c 10 f0       	push   $0xf0101c39
f0100921:	e8 49 00 00 00       	call   f010096f <cprintf>
f0100926:	83 c4 10             	add    $0x10,%esp
f0100929:	e9 e3 fe ff ff       	jmp    f0100811 <monitor+0x22>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f010092e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100931:	5b                   	pop    %ebx
f0100932:	5e                   	pop    %esi
f0100933:	5f                   	pop    %edi
f0100934:	5d                   	pop    %ebp
f0100935:	c3                   	ret    

f0100936 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100936:	55                   	push   %ebp
f0100937:	89 e5                	mov    %esp,%ebp
f0100939:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f010093c:	ff 75 08             	pushl  0x8(%ebp)
f010093f:	e8 17 fd ff ff       	call   f010065b <cputchar>
	*cnt++;
}
f0100944:	83 c4 10             	add    $0x10,%esp
f0100947:	c9                   	leave  
f0100948:	c3                   	ret    

f0100949 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0100949:	55                   	push   %ebp
f010094a:	89 e5                	mov    %esp,%ebp
f010094c:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f010094f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100956:	ff 75 0c             	pushl  0xc(%ebp)
f0100959:	ff 75 08             	pushl  0x8(%ebp)
f010095c:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010095f:	50                   	push   %eax
f0100960:	68 36 09 10 f0       	push   $0xf0100936
f0100965:	e8 52 04 00 00       	call   f0100dbc <vprintfmt>
	return cnt;
}
f010096a:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010096d:	c9                   	leave  
f010096e:	c3                   	ret    

f010096f <cprintf>:

int
cprintf(const char *fmt, ...)
{
f010096f:	55                   	push   %ebp
f0100970:	89 e5                	mov    %esp,%ebp
f0100972:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0100975:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0100978:	50                   	push   %eax
f0100979:	ff 75 08             	pushl  0x8(%ebp)
f010097c:	e8 c8 ff ff ff       	call   f0100949 <vcprintf>
	va_end(ap);

	return cnt;
}
f0100981:	c9                   	leave  
f0100982:	c3                   	ret    

f0100983 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100983:	55                   	push   %ebp
f0100984:	89 e5                	mov    %esp,%ebp
f0100986:	57                   	push   %edi
f0100987:	56                   	push   %esi
f0100988:	53                   	push   %ebx
f0100989:	83 ec 14             	sub    $0x14,%esp
f010098c:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010098f:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0100992:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100995:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100998:	8b 1a                	mov    (%edx),%ebx
f010099a:	8b 01                	mov    (%ecx),%eax
f010099c:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010099f:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f01009a6:	eb 7f                	jmp    f0100a27 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f01009a8:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01009ab:	01 d8                	add    %ebx,%eax
f01009ad:	89 c6                	mov    %eax,%esi
f01009af:	c1 ee 1f             	shr    $0x1f,%esi
f01009b2:	01 c6                	add    %eax,%esi
f01009b4:	d1 fe                	sar    %esi
f01009b6:	8d 04 76             	lea    (%esi,%esi,2),%eax
f01009b9:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01009bc:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f01009bf:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01009c1:	eb 03                	jmp    f01009c6 <stab_binsearch+0x43>
			m--;
f01009c3:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01009c6:	39 c3                	cmp    %eax,%ebx
f01009c8:	7f 0d                	jg     f01009d7 <stab_binsearch+0x54>
f01009ca:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01009ce:	83 ea 0c             	sub    $0xc,%edx
f01009d1:	39 f9                	cmp    %edi,%ecx
f01009d3:	75 ee                	jne    f01009c3 <stab_binsearch+0x40>
f01009d5:	eb 05                	jmp    f01009dc <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f01009d7:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f01009da:	eb 4b                	jmp    f0100a27 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01009dc:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01009df:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01009e2:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f01009e6:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01009e9:	76 11                	jbe    f01009fc <stab_binsearch+0x79>
			*region_left = m;
f01009eb:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01009ee:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f01009f0:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01009f3:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01009fa:	eb 2b                	jmp    f0100a27 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f01009fc:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01009ff:	73 14                	jae    f0100a15 <stab_binsearch+0x92>
			*region_right = m - 1;
f0100a01:	83 e8 01             	sub    $0x1,%eax
f0100a04:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100a07:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0100a0a:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a0c:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100a13:	eb 12                	jmp    f0100a27 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100a15:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100a18:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0100a1a:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0100a1e:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a20:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0100a27:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0100a2a:	0f 8e 78 ff ff ff    	jle    f01009a8 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100a30:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0100a34:	75 0f                	jne    f0100a45 <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f0100a36:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a39:	8b 00                	mov    (%eax),%eax
f0100a3b:	83 e8 01             	sub    $0x1,%eax
f0100a3e:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0100a41:	89 06                	mov    %eax,(%esi)
f0100a43:	eb 2c                	jmp    f0100a71 <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a45:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100a48:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100a4a:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100a4d:	8b 0e                	mov    (%esi),%ecx
f0100a4f:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100a52:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0100a55:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a58:	eb 03                	jmp    f0100a5d <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100a5a:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a5d:	39 c8                	cmp    %ecx,%eax
f0100a5f:	7e 0b                	jle    f0100a6c <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f0100a61:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0100a65:	83 ea 0c             	sub    $0xc,%edx
f0100a68:	39 df                	cmp    %ebx,%edi
f0100a6a:	75 ee                	jne    f0100a5a <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100a6c:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100a6f:	89 06                	mov    %eax,(%esi)
	}
}
f0100a71:	83 c4 14             	add    $0x14,%esp
f0100a74:	5b                   	pop    %ebx
f0100a75:	5e                   	pop    %esi
f0100a76:	5f                   	pop    %edi
f0100a77:	5d                   	pop    %ebp
f0100a78:	c3                   	ret    

f0100a79 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100a79:	55                   	push   %ebp
f0100a7a:	89 e5                	mov    %esp,%ebp
f0100a7c:	57                   	push   %edi
f0100a7d:	56                   	push   %esi
f0100a7e:	53                   	push   %ebx
f0100a7f:	83 ec 3c             	sub    $0x3c,%esp
f0100a82:	8b 75 08             	mov    0x8(%ebp),%esi
f0100a85:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100a88:	c7 03 f8 1d 10 f0    	movl   $0xf0101df8,(%ebx)
	info->eip_line = 0;
f0100a8e:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100a95:	c7 43 08 f8 1d 10 f0 	movl   $0xf0101df8,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100a9c:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100aa3:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100aa6:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100aad:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100ab3:	76 11                	jbe    f0100ac6 <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100ab5:	b8 cb 72 10 f0       	mov    $0xf01072cb,%eax
f0100aba:	3d b5 59 10 f0       	cmp    $0xf01059b5,%eax
f0100abf:	77 19                	ja     f0100ada <debuginfo_eip+0x61>
f0100ac1:	e9 aa 01 00 00       	jmp    f0100c70 <debuginfo_eip+0x1f7>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100ac6:	83 ec 04             	sub    $0x4,%esp
f0100ac9:	68 02 1e 10 f0       	push   $0xf0101e02
f0100ace:	6a 7f                	push   $0x7f
f0100ad0:	68 0f 1e 10 f0       	push   $0xf0101e0f
f0100ad5:	e8 0c f6 ff ff       	call   f01000e6 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100ada:	80 3d ca 72 10 f0 00 	cmpb   $0x0,0xf01072ca
f0100ae1:	0f 85 90 01 00 00    	jne    f0100c77 <debuginfo_eip+0x1fe>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100ae7:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100aee:	b8 b4 59 10 f0       	mov    $0xf01059b4,%eax
f0100af3:	2d 30 20 10 f0       	sub    $0xf0102030,%eax
f0100af8:	c1 f8 02             	sar    $0x2,%eax
f0100afb:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100b01:	83 e8 01             	sub    $0x1,%eax
f0100b04:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100b07:	83 ec 08             	sub    $0x8,%esp
f0100b0a:	56                   	push   %esi
f0100b0b:	6a 64                	push   $0x64
f0100b0d:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100b10:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100b13:	b8 30 20 10 f0       	mov    $0xf0102030,%eax
f0100b18:	e8 66 fe ff ff       	call   f0100983 <stab_binsearch>
	if (lfile == 0)
f0100b1d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100b20:	83 c4 10             	add    $0x10,%esp
f0100b23:	85 c0                	test   %eax,%eax
f0100b25:	0f 84 53 01 00 00    	je     f0100c7e <debuginfo_eip+0x205>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100b2b:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100b2e:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100b31:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100b34:	83 ec 08             	sub    $0x8,%esp
f0100b37:	56                   	push   %esi
f0100b38:	6a 24                	push   $0x24
f0100b3a:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100b3d:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100b40:	b8 30 20 10 f0       	mov    $0xf0102030,%eax
f0100b45:	e8 39 fe ff ff       	call   f0100983 <stab_binsearch>

	if (lfun <= rfun) {
f0100b4a:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100b4d:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100b50:	83 c4 10             	add    $0x10,%esp
f0100b53:	39 d0                	cmp    %edx,%eax
f0100b55:	7f 40                	jg     f0100b97 <debuginfo_eip+0x11e>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100b57:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f0100b5a:	c1 e1 02             	shl    $0x2,%ecx
f0100b5d:	8d b9 30 20 10 f0    	lea    -0xfefdfd0(%ecx),%edi
f0100b63:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f0100b66:	8b b9 30 20 10 f0    	mov    -0xfefdfd0(%ecx),%edi
f0100b6c:	b9 cb 72 10 f0       	mov    $0xf01072cb,%ecx
f0100b71:	81 e9 b5 59 10 f0    	sub    $0xf01059b5,%ecx
f0100b77:	39 cf                	cmp    %ecx,%edi
f0100b79:	73 09                	jae    f0100b84 <debuginfo_eip+0x10b>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100b7b:	81 c7 b5 59 10 f0    	add    $0xf01059b5,%edi
f0100b81:	89 7b 08             	mov    %edi,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100b84:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0100b87:	8b 4f 08             	mov    0x8(%edi),%ecx
f0100b8a:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0100b8d:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0100b8f:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0100b92:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0100b95:	eb 0f                	jmp    f0100ba6 <debuginfo_eip+0x12d>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100b97:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100b9a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100b9d:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0100ba0:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100ba3:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100ba6:	83 ec 08             	sub    $0x8,%esp
f0100ba9:	6a 3a                	push   $0x3a
f0100bab:	ff 73 08             	pushl  0x8(%ebx)
f0100bae:	e8 59 08 00 00       	call   f010140c <strfind>
f0100bb3:	2b 43 08             	sub    0x8(%ebx),%eax
f0100bb6:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0100bb9:	83 c4 08             	add    $0x8,%esp
f0100bbc:	56                   	push   %esi
f0100bbd:	6a 44                	push   $0x44
f0100bbf:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0100bc2:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0100bc5:	b8 30 20 10 f0       	mov    $0xf0102030,%eax
f0100bca:	e8 b4 fd ff ff       	call   f0100983 <stab_binsearch>
    if (lline <= rline) {
f0100bcf:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0100bd2:	83 c4 10             	add    $0x10,%esp
f0100bd5:	3b 55 d0             	cmp    -0x30(%ebp),%edx
f0100bd8:	0f 8f a7 00 00 00    	jg     f0100c85 <debuginfo_eip+0x20c>
        info->eip_line = stabs[lline].n_desc;
f0100bde:	8d 04 52             	lea    (%edx,%edx,2),%eax
f0100be1:	8d 04 85 30 20 10 f0 	lea    -0xfefdfd0(,%eax,4),%eax
f0100be8:	0f b7 48 06          	movzwl 0x6(%eax),%ecx
f0100bec:	89 4b 04             	mov    %ecx,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100bef:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100bf2:	eb 06                	jmp    f0100bfa <debuginfo_eip+0x181>
f0100bf4:	83 ea 01             	sub    $0x1,%edx
f0100bf7:	83 e8 0c             	sub    $0xc,%eax
f0100bfa:	39 d6                	cmp    %edx,%esi
f0100bfc:	7f 34                	jg     f0100c32 <debuginfo_eip+0x1b9>
	       && stabs[lline].n_type != N_SOL
f0100bfe:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f0100c02:	80 f9 84             	cmp    $0x84,%cl
f0100c05:	74 0b                	je     f0100c12 <debuginfo_eip+0x199>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100c07:	80 f9 64             	cmp    $0x64,%cl
f0100c0a:	75 e8                	jne    f0100bf4 <debuginfo_eip+0x17b>
f0100c0c:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0100c10:	74 e2                	je     f0100bf4 <debuginfo_eip+0x17b>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100c12:	8d 04 52             	lea    (%edx,%edx,2),%eax
f0100c15:	8b 14 85 30 20 10 f0 	mov    -0xfefdfd0(,%eax,4),%edx
f0100c1c:	b8 cb 72 10 f0       	mov    $0xf01072cb,%eax
f0100c21:	2d b5 59 10 f0       	sub    $0xf01059b5,%eax
f0100c26:	39 c2                	cmp    %eax,%edx
f0100c28:	73 08                	jae    f0100c32 <debuginfo_eip+0x1b9>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100c2a:	81 c2 b5 59 10 f0    	add    $0xf01059b5,%edx
f0100c30:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100c32:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100c35:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100c38:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100c3d:	39 f2                	cmp    %esi,%edx
f0100c3f:	7d 50                	jge    f0100c91 <debuginfo_eip+0x218>
		for (lline = lfun + 1;
f0100c41:	83 c2 01             	add    $0x1,%edx
f0100c44:	89 d0                	mov    %edx,%eax
f0100c46:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0100c49:	8d 14 95 30 20 10 f0 	lea    -0xfefdfd0(,%edx,4),%edx
f0100c50:	eb 04                	jmp    f0100c56 <debuginfo_eip+0x1dd>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0100c52:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100c56:	39 c6                	cmp    %eax,%esi
f0100c58:	7e 32                	jle    f0100c8c <debuginfo_eip+0x213>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100c5a:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0100c5e:	83 c0 01             	add    $0x1,%eax
f0100c61:	83 c2 0c             	add    $0xc,%edx
f0100c64:	80 f9 a0             	cmp    $0xa0,%cl
f0100c67:	74 e9                	je     f0100c52 <debuginfo_eip+0x1d9>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100c69:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c6e:	eb 21                	jmp    f0100c91 <debuginfo_eip+0x218>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100c70:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100c75:	eb 1a                	jmp    f0100c91 <debuginfo_eip+0x218>
f0100c77:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100c7c:	eb 13                	jmp    f0100c91 <debuginfo_eip+0x218>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0100c7e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100c83:	eb 0c                	jmp    f0100c91 <debuginfo_eip+0x218>
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
    if (lline <= rline) {
        info->eip_line = stabs[lline].n_desc;
    } else {
        return -1;
f0100c85:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100c8a:	eb 05                	jmp    f0100c91 <debuginfo_eip+0x218>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100c8c:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100c91:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100c94:	5b                   	pop    %ebx
f0100c95:	5e                   	pop    %esi
f0100c96:	5f                   	pop    %edi
f0100c97:	5d                   	pop    %ebp
f0100c98:	c3                   	ret    

f0100c99 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100c99:	55                   	push   %ebp
f0100c9a:	89 e5                	mov    %esp,%ebp
f0100c9c:	57                   	push   %edi
f0100c9d:	56                   	push   %esi
f0100c9e:	53                   	push   %ebx
f0100c9f:	83 ec 1c             	sub    $0x1c,%esp
f0100ca2:	89 c7                	mov    %eax,%edi
f0100ca4:	89 d6                	mov    %edx,%esi
f0100ca6:	8b 45 08             	mov    0x8(%ebp),%eax
f0100ca9:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100cac:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100caf:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100cb2:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0100cb5:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100cba:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100cbd:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0100cc0:	39 d3                	cmp    %edx,%ebx
f0100cc2:	72 05                	jb     f0100cc9 <printnum+0x30>
f0100cc4:	39 45 10             	cmp    %eax,0x10(%ebp)
f0100cc7:	77 45                	ja     f0100d0e <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100cc9:	83 ec 0c             	sub    $0xc,%esp
f0100ccc:	ff 75 18             	pushl  0x18(%ebp)
f0100ccf:	8b 45 14             	mov    0x14(%ebp),%eax
f0100cd2:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0100cd5:	53                   	push   %ebx
f0100cd6:	ff 75 10             	pushl  0x10(%ebp)
f0100cd9:	83 ec 08             	sub    $0x8,%esp
f0100cdc:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100cdf:	ff 75 e0             	pushl  -0x20(%ebp)
f0100ce2:	ff 75 dc             	pushl  -0x24(%ebp)
f0100ce5:	ff 75 d8             	pushl  -0x28(%ebp)
f0100ce8:	e8 43 09 00 00       	call   f0101630 <__udivdi3>
f0100ced:	83 c4 18             	add    $0x18,%esp
f0100cf0:	52                   	push   %edx
f0100cf1:	50                   	push   %eax
f0100cf2:	89 f2                	mov    %esi,%edx
f0100cf4:	89 f8                	mov    %edi,%eax
f0100cf6:	e8 9e ff ff ff       	call   f0100c99 <printnum>
f0100cfb:	83 c4 20             	add    $0x20,%esp
f0100cfe:	eb 18                	jmp    f0100d18 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100d00:	83 ec 08             	sub    $0x8,%esp
f0100d03:	56                   	push   %esi
f0100d04:	ff 75 18             	pushl  0x18(%ebp)
f0100d07:	ff d7                	call   *%edi
f0100d09:	83 c4 10             	add    $0x10,%esp
f0100d0c:	eb 03                	jmp    f0100d11 <printnum+0x78>
f0100d0e:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100d11:	83 eb 01             	sub    $0x1,%ebx
f0100d14:	85 db                	test   %ebx,%ebx
f0100d16:	7f e8                	jg     f0100d00 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100d18:	83 ec 08             	sub    $0x8,%esp
f0100d1b:	56                   	push   %esi
f0100d1c:	83 ec 04             	sub    $0x4,%esp
f0100d1f:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100d22:	ff 75 e0             	pushl  -0x20(%ebp)
f0100d25:	ff 75 dc             	pushl  -0x24(%ebp)
f0100d28:	ff 75 d8             	pushl  -0x28(%ebp)
f0100d2b:	e8 30 0a 00 00       	call   f0101760 <__umoddi3>
f0100d30:	83 c4 14             	add    $0x14,%esp
f0100d33:	0f be 80 1d 1e 10 f0 	movsbl -0xfefe1e3(%eax),%eax
f0100d3a:	50                   	push   %eax
f0100d3b:	ff d7                	call   *%edi
}
f0100d3d:	83 c4 10             	add    $0x10,%esp
f0100d40:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100d43:	5b                   	pop    %ebx
f0100d44:	5e                   	pop    %esi
f0100d45:	5f                   	pop    %edi
f0100d46:	5d                   	pop    %ebp
f0100d47:	c3                   	ret    

f0100d48 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0100d48:	55                   	push   %ebp
f0100d49:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0100d4b:	83 fa 01             	cmp    $0x1,%edx
f0100d4e:	7e 0e                	jle    f0100d5e <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0100d50:	8b 10                	mov    (%eax),%edx
f0100d52:	8d 4a 08             	lea    0x8(%edx),%ecx
f0100d55:	89 08                	mov    %ecx,(%eax)
f0100d57:	8b 02                	mov    (%edx),%eax
f0100d59:	8b 52 04             	mov    0x4(%edx),%edx
f0100d5c:	eb 22                	jmp    f0100d80 <getuint+0x38>
	else if (lflag)
f0100d5e:	85 d2                	test   %edx,%edx
f0100d60:	74 10                	je     f0100d72 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0100d62:	8b 10                	mov    (%eax),%edx
f0100d64:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100d67:	89 08                	mov    %ecx,(%eax)
f0100d69:	8b 02                	mov    (%edx),%eax
f0100d6b:	ba 00 00 00 00       	mov    $0x0,%edx
f0100d70:	eb 0e                	jmp    f0100d80 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0100d72:	8b 10                	mov    (%eax),%edx
f0100d74:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100d77:	89 08                	mov    %ecx,(%eax)
f0100d79:	8b 02                	mov    (%edx),%eax
f0100d7b:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0100d80:	5d                   	pop    %ebp
f0100d81:	c3                   	ret    

f0100d82 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100d82:	55                   	push   %ebp
f0100d83:	89 e5                	mov    %esp,%ebp
f0100d85:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100d88:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100d8c:	8b 10                	mov    (%eax),%edx
f0100d8e:	3b 50 04             	cmp    0x4(%eax),%edx
f0100d91:	73 0a                	jae    f0100d9d <sprintputch+0x1b>
		*b->buf++ = ch;
f0100d93:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100d96:	89 08                	mov    %ecx,(%eax)
f0100d98:	8b 45 08             	mov    0x8(%ebp),%eax
f0100d9b:	88 02                	mov    %al,(%edx)
}
f0100d9d:	5d                   	pop    %ebp
f0100d9e:	c3                   	ret    

f0100d9f <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100d9f:	55                   	push   %ebp
f0100da0:	89 e5                	mov    %esp,%ebp
f0100da2:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100da5:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100da8:	50                   	push   %eax
f0100da9:	ff 75 10             	pushl  0x10(%ebp)
f0100dac:	ff 75 0c             	pushl  0xc(%ebp)
f0100daf:	ff 75 08             	pushl  0x8(%ebp)
f0100db2:	e8 05 00 00 00       	call   f0100dbc <vprintfmt>
	va_end(ap);
}
f0100db7:	83 c4 10             	add    $0x10,%esp
f0100dba:	c9                   	leave  
f0100dbb:	c3                   	ret    

f0100dbc <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100dbc:	55                   	push   %ebp
f0100dbd:	89 e5                	mov    %esp,%ebp
f0100dbf:	57                   	push   %edi
f0100dc0:	56                   	push   %esi
f0100dc1:	53                   	push   %ebx
f0100dc2:	83 ec 2c             	sub    $0x2c,%esp
f0100dc5:	8b 75 08             	mov    0x8(%ebp),%esi
f0100dc8:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100dcb:	8b 7d 10             	mov    0x10(%ebp),%edi
f0100dce:	eb 12                	jmp    f0100de2 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0100dd0:	85 c0                	test   %eax,%eax
f0100dd2:	0f 84 89 03 00 00    	je     f0101161 <vprintfmt+0x3a5>
				return;
			putch(ch, putdat);
f0100dd8:	83 ec 08             	sub    $0x8,%esp
f0100ddb:	53                   	push   %ebx
f0100ddc:	50                   	push   %eax
f0100ddd:	ff d6                	call   *%esi
f0100ddf:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100de2:	83 c7 01             	add    $0x1,%edi
f0100de5:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0100de9:	83 f8 25             	cmp    $0x25,%eax
f0100dec:	75 e2                	jne    f0100dd0 <vprintfmt+0x14>
f0100dee:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0100df2:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0100df9:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0100e00:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0100e07:	ba 00 00 00 00       	mov    $0x0,%edx
f0100e0c:	eb 07                	jmp    f0100e15 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e0e:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0100e11:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e15:	8d 47 01             	lea    0x1(%edi),%eax
f0100e18:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100e1b:	0f b6 07             	movzbl (%edi),%eax
f0100e1e:	0f b6 c8             	movzbl %al,%ecx
f0100e21:	83 e8 23             	sub    $0x23,%eax
f0100e24:	3c 55                	cmp    $0x55,%al
f0100e26:	0f 87 1a 03 00 00    	ja     f0101146 <vprintfmt+0x38a>
f0100e2c:	0f b6 c0             	movzbl %al,%eax
f0100e2f:	ff 24 85 ac 1e 10 f0 	jmp    *-0xfefe154(,%eax,4)
f0100e36:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100e39:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0100e3d:	eb d6                	jmp    f0100e15 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e3f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100e42:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e47:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100e4a:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100e4d:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0100e51:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0100e54:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0100e57:	83 fa 09             	cmp    $0x9,%edx
f0100e5a:	77 39                	ja     f0100e95 <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100e5c:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0100e5f:	eb e9                	jmp    f0100e4a <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100e61:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e64:	8d 48 04             	lea    0x4(%eax),%ecx
f0100e67:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0100e6a:	8b 00                	mov    (%eax),%eax
f0100e6c:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e6f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0100e72:	eb 27                	jmp    f0100e9b <vprintfmt+0xdf>
f0100e74:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100e77:	85 c0                	test   %eax,%eax
f0100e79:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100e7e:	0f 49 c8             	cmovns %eax,%ecx
f0100e81:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e84:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100e87:	eb 8c                	jmp    f0100e15 <vprintfmt+0x59>
f0100e89:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100e8c:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0100e93:	eb 80                	jmp    f0100e15 <vprintfmt+0x59>
f0100e95:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0100e98:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0100e9b:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100e9f:	0f 89 70 ff ff ff    	jns    f0100e15 <vprintfmt+0x59>
				width = precision, precision = -1;
f0100ea5:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100ea8:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100eab:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0100eb2:	e9 5e ff ff ff       	jmp    f0100e15 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100eb7:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100eba:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0100ebd:	e9 53 ff ff ff       	jmp    f0100e15 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100ec2:	8b 45 14             	mov    0x14(%ebp),%eax
f0100ec5:	8d 50 04             	lea    0x4(%eax),%edx
f0100ec8:	89 55 14             	mov    %edx,0x14(%ebp)
f0100ecb:	83 ec 08             	sub    $0x8,%esp
f0100ece:	53                   	push   %ebx
f0100ecf:	ff 30                	pushl  (%eax)
f0100ed1:	ff d6                	call   *%esi
			break;
f0100ed3:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ed6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0100ed9:	e9 04 ff ff ff       	jmp    f0100de2 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100ede:	8b 45 14             	mov    0x14(%ebp),%eax
f0100ee1:	8d 50 04             	lea    0x4(%eax),%edx
f0100ee4:	89 55 14             	mov    %edx,0x14(%ebp)
f0100ee7:	8b 00                	mov    (%eax),%eax
f0100ee9:	99                   	cltd   
f0100eea:	31 d0                	xor    %edx,%eax
f0100eec:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100eee:	83 f8 06             	cmp    $0x6,%eax
f0100ef1:	7f 0b                	jg     f0100efe <vprintfmt+0x142>
f0100ef3:	8b 14 85 04 20 10 f0 	mov    -0xfefdffc(,%eax,4),%edx
f0100efa:	85 d2                	test   %edx,%edx
f0100efc:	75 18                	jne    f0100f16 <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f0100efe:	50                   	push   %eax
f0100eff:	68 35 1e 10 f0       	push   $0xf0101e35
f0100f04:	53                   	push   %ebx
f0100f05:	56                   	push   %esi
f0100f06:	e8 94 fe ff ff       	call   f0100d9f <printfmt>
f0100f0b:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f0e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0100f11:	e9 cc fe ff ff       	jmp    f0100de2 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0100f16:	52                   	push   %edx
f0100f17:	68 3e 1e 10 f0       	push   $0xf0101e3e
f0100f1c:	53                   	push   %ebx
f0100f1d:	56                   	push   %esi
f0100f1e:	e8 7c fe ff ff       	call   f0100d9f <printfmt>
f0100f23:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f26:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100f29:	e9 b4 fe ff ff       	jmp    f0100de2 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0100f2e:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f31:	8d 50 04             	lea    0x4(%eax),%edx
f0100f34:	89 55 14             	mov    %edx,0x14(%ebp)
f0100f37:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0100f39:	85 ff                	test   %edi,%edi
f0100f3b:	b8 2e 1e 10 f0       	mov    $0xf0101e2e,%eax
f0100f40:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0100f43:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100f47:	0f 8e 94 00 00 00    	jle    f0100fe1 <vprintfmt+0x225>
f0100f4d:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0100f51:	0f 84 98 00 00 00    	je     f0100fef <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
f0100f57:	83 ec 08             	sub    $0x8,%esp
f0100f5a:	ff 75 d0             	pushl  -0x30(%ebp)
f0100f5d:	57                   	push   %edi
f0100f5e:	e8 5f 03 00 00       	call   f01012c2 <strnlen>
f0100f63:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0100f66:	29 c1                	sub    %eax,%ecx
f0100f68:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0100f6b:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0100f6e:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0100f72:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100f75:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0100f78:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100f7a:	eb 0f                	jmp    f0100f8b <vprintfmt+0x1cf>
					putch(padc, putdat);
f0100f7c:	83 ec 08             	sub    $0x8,%esp
f0100f7f:	53                   	push   %ebx
f0100f80:	ff 75 e0             	pushl  -0x20(%ebp)
f0100f83:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100f85:	83 ef 01             	sub    $0x1,%edi
f0100f88:	83 c4 10             	add    $0x10,%esp
f0100f8b:	85 ff                	test   %edi,%edi
f0100f8d:	7f ed                	jg     f0100f7c <vprintfmt+0x1c0>
f0100f8f:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0100f92:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0100f95:	85 c9                	test   %ecx,%ecx
f0100f97:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f9c:	0f 49 c1             	cmovns %ecx,%eax
f0100f9f:	29 c1                	sub    %eax,%ecx
f0100fa1:	89 75 08             	mov    %esi,0x8(%ebp)
f0100fa4:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0100fa7:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0100faa:	89 cb                	mov    %ecx,%ebx
f0100fac:	eb 4d                	jmp    f0100ffb <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0100fae:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0100fb2:	74 1b                	je     f0100fcf <vprintfmt+0x213>
f0100fb4:	0f be c0             	movsbl %al,%eax
f0100fb7:	83 e8 20             	sub    $0x20,%eax
f0100fba:	83 f8 5e             	cmp    $0x5e,%eax
f0100fbd:	76 10                	jbe    f0100fcf <vprintfmt+0x213>
					putch('?', putdat);
f0100fbf:	83 ec 08             	sub    $0x8,%esp
f0100fc2:	ff 75 0c             	pushl  0xc(%ebp)
f0100fc5:	6a 3f                	push   $0x3f
f0100fc7:	ff 55 08             	call   *0x8(%ebp)
f0100fca:	83 c4 10             	add    $0x10,%esp
f0100fcd:	eb 0d                	jmp    f0100fdc <vprintfmt+0x220>
				else
					putch(ch, putdat);
f0100fcf:	83 ec 08             	sub    $0x8,%esp
f0100fd2:	ff 75 0c             	pushl  0xc(%ebp)
f0100fd5:	52                   	push   %edx
f0100fd6:	ff 55 08             	call   *0x8(%ebp)
f0100fd9:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0100fdc:	83 eb 01             	sub    $0x1,%ebx
f0100fdf:	eb 1a                	jmp    f0100ffb <vprintfmt+0x23f>
f0100fe1:	89 75 08             	mov    %esi,0x8(%ebp)
f0100fe4:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0100fe7:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0100fea:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0100fed:	eb 0c                	jmp    f0100ffb <vprintfmt+0x23f>
f0100fef:	89 75 08             	mov    %esi,0x8(%ebp)
f0100ff2:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0100ff5:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0100ff8:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0100ffb:	83 c7 01             	add    $0x1,%edi
f0100ffe:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0101002:	0f be d0             	movsbl %al,%edx
f0101005:	85 d2                	test   %edx,%edx
f0101007:	74 23                	je     f010102c <vprintfmt+0x270>
f0101009:	85 f6                	test   %esi,%esi
f010100b:	78 a1                	js     f0100fae <vprintfmt+0x1f2>
f010100d:	83 ee 01             	sub    $0x1,%esi
f0101010:	79 9c                	jns    f0100fae <vprintfmt+0x1f2>
f0101012:	89 df                	mov    %ebx,%edi
f0101014:	8b 75 08             	mov    0x8(%ebp),%esi
f0101017:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010101a:	eb 18                	jmp    f0101034 <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f010101c:	83 ec 08             	sub    $0x8,%esp
f010101f:	53                   	push   %ebx
f0101020:	6a 20                	push   $0x20
f0101022:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101024:	83 ef 01             	sub    $0x1,%edi
f0101027:	83 c4 10             	add    $0x10,%esp
f010102a:	eb 08                	jmp    f0101034 <vprintfmt+0x278>
f010102c:	89 df                	mov    %ebx,%edi
f010102e:	8b 75 08             	mov    0x8(%ebp),%esi
f0101031:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101034:	85 ff                	test   %edi,%edi
f0101036:	7f e4                	jg     f010101c <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101038:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010103b:	e9 a2 fd ff ff       	jmp    f0100de2 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0101040:	83 fa 01             	cmp    $0x1,%edx
f0101043:	7e 16                	jle    f010105b <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f0101045:	8b 45 14             	mov    0x14(%ebp),%eax
f0101048:	8d 50 08             	lea    0x8(%eax),%edx
f010104b:	89 55 14             	mov    %edx,0x14(%ebp)
f010104e:	8b 50 04             	mov    0x4(%eax),%edx
f0101051:	8b 00                	mov    (%eax),%eax
f0101053:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101056:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101059:	eb 32                	jmp    f010108d <vprintfmt+0x2d1>
	else if (lflag)
f010105b:	85 d2                	test   %edx,%edx
f010105d:	74 18                	je     f0101077 <vprintfmt+0x2bb>
		return va_arg(*ap, long);
f010105f:	8b 45 14             	mov    0x14(%ebp),%eax
f0101062:	8d 50 04             	lea    0x4(%eax),%edx
f0101065:	89 55 14             	mov    %edx,0x14(%ebp)
f0101068:	8b 00                	mov    (%eax),%eax
f010106a:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010106d:	89 c1                	mov    %eax,%ecx
f010106f:	c1 f9 1f             	sar    $0x1f,%ecx
f0101072:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0101075:	eb 16                	jmp    f010108d <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
f0101077:	8b 45 14             	mov    0x14(%ebp),%eax
f010107a:	8d 50 04             	lea    0x4(%eax),%edx
f010107d:	89 55 14             	mov    %edx,0x14(%ebp)
f0101080:	8b 00                	mov    (%eax),%eax
f0101082:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101085:	89 c1                	mov    %eax,%ecx
f0101087:	c1 f9 1f             	sar    $0x1f,%ecx
f010108a:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f010108d:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0101090:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0101093:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0101098:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f010109c:	79 74                	jns    f0101112 <vprintfmt+0x356>
				putch('-', putdat);
f010109e:	83 ec 08             	sub    $0x8,%esp
f01010a1:	53                   	push   %ebx
f01010a2:	6a 2d                	push   $0x2d
f01010a4:	ff d6                	call   *%esi
				num = -(long long) num;
f01010a6:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01010a9:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01010ac:	f7 d8                	neg    %eax
f01010ae:	83 d2 00             	adc    $0x0,%edx
f01010b1:	f7 da                	neg    %edx
f01010b3:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f01010b6:	b9 0a 00 00 00       	mov    $0xa,%ecx
f01010bb:	eb 55                	jmp    f0101112 <vprintfmt+0x356>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f01010bd:	8d 45 14             	lea    0x14(%ebp),%eax
f01010c0:	e8 83 fc ff ff       	call   f0100d48 <getuint>
			base = 10;
f01010c5:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f01010ca:	eb 46                	jmp    f0101112 <vprintfmt+0x356>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f01010cc:	8d 45 14             	lea    0x14(%ebp),%eax
f01010cf:	e8 74 fc ff ff       	call   f0100d48 <getuint>
			base = 8;
f01010d4:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f01010d9:	eb 37                	jmp    f0101112 <vprintfmt+0x356>

		// pointer
		case 'p':
			putch('0', putdat);
f01010db:	83 ec 08             	sub    $0x8,%esp
f01010de:	53                   	push   %ebx
f01010df:	6a 30                	push   $0x30
f01010e1:	ff d6                	call   *%esi
			putch('x', putdat);
f01010e3:	83 c4 08             	add    $0x8,%esp
f01010e6:	53                   	push   %ebx
f01010e7:	6a 78                	push   $0x78
f01010e9:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f01010eb:	8b 45 14             	mov    0x14(%ebp),%eax
f01010ee:	8d 50 04             	lea    0x4(%eax),%edx
f01010f1:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f01010f4:	8b 00                	mov    (%eax),%eax
f01010f6:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f01010fb:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f01010fe:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0101103:	eb 0d                	jmp    f0101112 <vprintfmt+0x356>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0101105:	8d 45 14             	lea    0x14(%ebp),%eax
f0101108:	e8 3b fc ff ff       	call   f0100d48 <getuint>
			base = 16;
f010110d:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0101112:	83 ec 0c             	sub    $0xc,%esp
f0101115:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0101119:	57                   	push   %edi
f010111a:	ff 75 e0             	pushl  -0x20(%ebp)
f010111d:	51                   	push   %ecx
f010111e:	52                   	push   %edx
f010111f:	50                   	push   %eax
f0101120:	89 da                	mov    %ebx,%edx
f0101122:	89 f0                	mov    %esi,%eax
f0101124:	e8 70 fb ff ff       	call   f0100c99 <printnum>
			break;
f0101129:	83 c4 20             	add    $0x20,%esp
f010112c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010112f:	e9 ae fc ff ff       	jmp    f0100de2 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0101134:	83 ec 08             	sub    $0x8,%esp
f0101137:	53                   	push   %ebx
f0101138:	51                   	push   %ecx
f0101139:	ff d6                	call   *%esi
			break;
f010113b:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010113e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0101141:	e9 9c fc ff ff       	jmp    f0100de2 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0101146:	83 ec 08             	sub    $0x8,%esp
f0101149:	53                   	push   %ebx
f010114a:	6a 25                	push   $0x25
f010114c:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f010114e:	83 c4 10             	add    $0x10,%esp
f0101151:	eb 03                	jmp    f0101156 <vprintfmt+0x39a>
f0101153:	83 ef 01             	sub    $0x1,%edi
f0101156:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f010115a:	75 f7                	jne    f0101153 <vprintfmt+0x397>
f010115c:	e9 81 fc ff ff       	jmp    f0100de2 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0101161:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101164:	5b                   	pop    %ebx
f0101165:	5e                   	pop    %esi
f0101166:	5f                   	pop    %edi
f0101167:	5d                   	pop    %ebp
f0101168:	c3                   	ret    

f0101169 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0101169:	55                   	push   %ebp
f010116a:	89 e5                	mov    %esp,%ebp
f010116c:	83 ec 18             	sub    $0x18,%esp
f010116f:	8b 45 08             	mov    0x8(%ebp),%eax
f0101172:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0101175:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101178:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f010117c:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f010117f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0101186:	85 c0                	test   %eax,%eax
f0101188:	74 26                	je     f01011b0 <vsnprintf+0x47>
f010118a:	85 d2                	test   %edx,%edx
f010118c:	7e 22                	jle    f01011b0 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f010118e:	ff 75 14             	pushl  0x14(%ebp)
f0101191:	ff 75 10             	pushl  0x10(%ebp)
f0101194:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0101197:	50                   	push   %eax
f0101198:	68 82 0d 10 f0       	push   $0xf0100d82
f010119d:	e8 1a fc ff ff       	call   f0100dbc <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01011a2:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01011a5:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01011a8:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01011ab:	83 c4 10             	add    $0x10,%esp
f01011ae:	eb 05                	jmp    f01011b5 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f01011b0:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f01011b5:	c9                   	leave  
f01011b6:	c3                   	ret    

f01011b7 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01011b7:	55                   	push   %ebp
f01011b8:	89 e5                	mov    %esp,%ebp
f01011ba:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01011bd:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01011c0:	50                   	push   %eax
f01011c1:	ff 75 10             	pushl  0x10(%ebp)
f01011c4:	ff 75 0c             	pushl  0xc(%ebp)
f01011c7:	ff 75 08             	pushl  0x8(%ebp)
f01011ca:	e8 9a ff ff ff       	call   f0101169 <vsnprintf>
	va_end(ap);

	return rc;
}
f01011cf:	c9                   	leave  
f01011d0:	c3                   	ret    

f01011d1 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01011d1:	55                   	push   %ebp
f01011d2:	89 e5                	mov    %esp,%ebp
f01011d4:	57                   	push   %edi
f01011d5:	56                   	push   %esi
f01011d6:	53                   	push   %ebx
f01011d7:	83 ec 0c             	sub    $0xc,%esp
f01011da:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01011dd:	85 c0                	test   %eax,%eax
f01011df:	74 11                	je     f01011f2 <readline+0x21>
		cprintf("%s", prompt);
f01011e1:	83 ec 08             	sub    $0x8,%esp
f01011e4:	50                   	push   %eax
f01011e5:	68 3e 1e 10 f0       	push   $0xf0101e3e
f01011ea:	e8 80 f7 ff ff       	call   f010096f <cprintf>
f01011ef:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f01011f2:	83 ec 0c             	sub    $0xc,%esp
f01011f5:	6a 00                	push   $0x0
f01011f7:	e8 80 f4 ff ff       	call   f010067c <iscons>
f01011fc:	89 c7                	mov    %eax,%edi
f01011fe:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0101201:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0101206:	e8 60 f4 ff ff       	call   f010066b <getchar>
f010120b:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010120d:	85 c0                	test   %eax,%eax
f010120f:	79 18                	jns    f0101229 <readline+0x58>
			cprintf("read error: %e\n", c);
f0101211:	83 ec 08             	sub    $0x8,%esp
f0101214:	50                   	push   %eax
f0101215:	68 20 20 10 f0       	push   $0xf0102020
f010121a:	e8 50 f7 ff ff       	call   f010096f <cprintf>
			return NULL;
f010121f:	83 c4 10             	add    $0x10,%esp
f0101222:	b8 00 00 00 00       	mov    $0x0,%eax
f0101227:	eb 79                	jmp    f01012a2 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101229:	83 f8 08             	cmp    $0x8,%eax
f010122c:	0f 94 c2             	sete   %dl
f010122f:	83 f8 7f             	cmp    $0x7f,%eax
f0101232:	0f 94 c0             	sete   %al
f0101235:	08 c2                	or     %al,%dl
f0101237:	74 1a                	je     f0101253 <readline+0x82>
f0101239:	85 f6                	test   %esi,%esi
f010123b:	7e 16                	jle    f0101253 <readline+0x82>
			if (echoing)
f010123d:	85 ff                	test   %edi,%edi
f010123f:	74 0d                	je     f010124e <readline+0x7d>
				cputchar('\b');
f0101241:	83 ec 0c             	sub    $0xc,%esp
f0101244:	6a 08                	push   $0x8
f0101246:	e8 10 f4 ff ff       	call   f010065b <cputchar>
f010124b:	83 c4 10             	add    $0x10,%esp
			i--;
f010124e:	83 ee 01             	sub    $0x1,%esi
f0101251:	eb b3                	jmp    f0101206 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101253:	83 fb 1f             	cmp    $0x1f,%ebx
f0101256:	7e 23                	jle    f010127b <readline+0xaa>
f0101258:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010125e:	7f 1b                	jg     f010127b <readline+0xaa>
			if (echoing)
f0101260:	85 ff                	test   %edi,%edi
f0101262:	74 0c                	je     f0101270 <readline+0x9f>
				cputchar(c);
f0101264:	83 ec 0c             	sub    $0xc,%esp
f0101267:	53                   	push   %ebx
f0101268:	e8 ee f3 ff ff       	call   f010065b <cputchar>
f010126d:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0101270:	88 9e 40 25 11 f0    	mov    %bl,-0xfeedac0(%esi)
f0101276:	8d 76 01             	lea    0x1(%esi),%esi
f0101279:	eb 8b                	jmp    f0101206 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f010127b:	83 fb 0a             	cmp    $0xa,%ebx
f010127e:	74 05                	je     f0101285 <readline+0xb4>
f0101280:	83 fb 0d             	cmp    $0xd,%ebx
f0101283:	75 81                	jne    f0101206 <readline+0x35>
			if (echoing)
f0101285:	85 ff                	test   %edi,%edi
f0101287:	74 0d                	je     f0101296 <readline+0xc5>
				cputchar('\n');
f0101289:	83 ec 0c             	sub    $0xc,%esp
f010128c:	6a 0a                	push   $0xa
f010128e:	e8 c8 f3 ff ff       	call   f010065b <cputchar>
f0101293:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0101296:	c6 86 40 25 11 f0 00 	movb   $0x0,-0xfeedac0(%esi)
			return buf;
f010129d:	b8 40 25 11 f0       	mov    $0xf0112540,%eax
		}
	}
}
f01012a2:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01012a5:	5b                   	pop    %ebx
f01012a6:	5e                   	pop    %esi
f01012a7:	5f                   	pop    %edi
f01012a8:	5d                   	pop    %ebp
f01012a9:	c3                   	ret    

f01012aa <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01012aa:	55                   	push   %ebp
f01012ab:	89 e5                	mov    %esp,%ebp
f01012ad:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01012b0:	b8 00 00 00 00       	mov    $0x0,%eax
f01012b5:	eb 03                	jmp    f01012ba <strlen+0x10>
		n++;
f01012b7:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01012ba:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01012be:	75 f7                	jne    f01012b7 <strlen+0xd>
		n++;
	return n;
}
f01012c0:	5d                   	pop    %ebp
f01012c1:	c3                   	ret    

f01012c2 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01012c2:	55                   	push   %ebp
f01012c3:	89 e5                	mov    %esp,%ebp
f01012c5:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01012c8:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01012cb:	ba 00 00 00 00       	mov    $0x0,%edx
f01012d0:	eb 03                	jmp    f01012d5 <strnlen+0x13>
		n++;
f01012d2:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01012d5:	39 c2                	cmp    %eax,%edx
f01012d7:	74 08                	je     f01012e1 <strnlen+0x1f>
f01012d9:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f01012dd:	75 f3                	jne    f01012d2 <strnlen+0x10>
f01012df:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f01012e1:	5d                   	pop    %ebp
f01012e2:	c3                   	ret    

f01012e3 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01012e3:	55                   	push   %ebp
f01012e4:	89 e5                	mov    %esp,%ebp
f01012e6:	53                   	push   %ebx
f01012e7:	8b 45 08             	mov    0x8(%ebp),%eax
f01012ea:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01012ed:	89 c2                	mov    %eax,%edx
f01012ef:	83 c2 01             	add    $0x1,%edx
f01012f2:	83 c1 01             	add    $0x1,%ecx
f01012f5:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f01012f9:	88 5a ff             	mov    %bl,-0x1(%edx)
f01012fc:	84 db                	test   %bl,%bl
f01012fe:	75 ef                	jne    f01012ef <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0101300:	5b                   	pop    %ebx
f0101301:	5d                   	pop    %ebp
f0101302:	c3                   	ret    

f0101303 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0101303:	55                   	push   %ebp
f0101304:	89 e5                	mov    %esp,%ebp
f0101306:	53                   	push   %ebx
f0101307:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f010130a:	53                   	push   %ebx
f010130b:	e8 9a ff ff ff       	call   f01012aa <strlen>
f0101310:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0101313:	ff 75 0c             	pushl  0xc(%ebp)
f0101316:	01 d8                	add    %ebx,%eax
f0101318:	50                   	push   %eax
f0101319:	e8 c5 ff ff ff       	call   f01012e3 <strcpy>
	return dst;
}
f010131e:	89 d8                	mov    %ebx,%eax
f0101320:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101323:	c9                   	leave  
f0101324:	c3                   	ret    

f0101325 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0101325:	55                   	push   %ebp
f0101326:	89 e5                	mov    %esp,%ebp
f0101328:	56                   	push   %esi
f0101329:	53                   	push   %ebx
f010132a:	8b 75 08             	mov    0x8(%ebp),%esi
f010132d:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101330:	89 f3                	mov    %esi,%ebx
f0101332:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101335:	89 f2                	mov    %esi,%edx
f0101337:	eb 0f                	jmp    f0101348 <strncpy+0x23>
		*dst++ = *src;
f0101339:	83 c2 01             	add    $0x1,%edx
f010133c:	0f b6 01             	movzbl (%ecx),%eax
f010133f:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0101342:	80 39 01             	cmpb   $0x1,(%ecx)
f0101345:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101348:	39 da                	cmp    %ebx,%edx
f010134a:	75 ed                	jne    f0101339 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f010134c:	89 f0                	mov    %esi,%eax
f010134e:	5b                   	pop    %ebx
f010134f:	5e                   	pop    %esi
f0101350:	5d                   	pop    %ebp
f0101351:	c3                   	ret    

f0101352 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0101352:	55                   	push   %ebp
f0101353:	89 e5                	mov    %esp,%ebp
f0101355:	56                   	push   %esi
f0101356:	53                   	push   %ebx
f0101357:	8b 75 08             	mov    0x8(%ebp),%esi
f010135a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010135d:	8b 55 10             	mov    0x10(%ebp),%edx
f0101360:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0101362:	85 d2                	test   %edx,%edx
f0101364:	74 21                	je     f0101387 <strlcpy+0x35>
f0101366:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f010136a:	89 f2                	mov    %esi,%edx
f010136c:	eb 09                	jmp    f0101377 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f010136e:	83 c2 01             	add    $0x1,%edx
f0101371:	83 c1 01             	add    $0x1,%ecx
f0101374:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0101377:	39 c2                	cmp    %eax,%edx
f0101379:	74 09                	je     f0101384 <strlcpy+0x32>
f010137b:	0f b6 19             	movzbl (%ecx),%ebx
f010137e:	84 db                	test   %bl,%bl
f0101380:	75 ec                	jne    f010136e <strlcpy+0x1c>
f0101382:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f0101384:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0101387:	29 f0                	sub    %esi,%eax
}
f0101389:	5b                   	pop    %ebx
f010138a:	5e                   	pop    %esi
f010138b:	5d                   	pop    %ebp
f010138c:	c3                   	ret    

f010138d <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010138d:	55                   	push   %ebp
f010138e:	89 e5                	mov    %esp,%ebp
f0101390:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101393:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0101396:	eb 06                	jmp    f010139e <strcmp+0x11>
		p++, q++;
f0101398:	83 c1 01             	add    $0x1,%ecx
f010139b:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f010139e:	0f b6 01             	movzbl (%ecx),%eax
f01013a1:	84 c0                	test   %al,%al
f01013a3:	74 04                	je     f01013a9 <strcmp+0x1c>
f01013a5:	3a 02                	cmp    (%edx),%al
f01013a7:	74 ef                	je     f0101398 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01013a9:	0f b6 c0             	movzbl %al,%eax
f01013ac:	0f b6 12             	movzbl (%edx),%edx
f01013af:	29 d0                	sub    %edx,%eax
}
f01013b1:	5d                   	pop    %ebp
f01013b2:	c3                   	ret    

f01013b3 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01013b3:	55                   	push   %ebp
f01013b4:	89 e5                	mov    %esp,%ebp
f01013b6:	53                   	push   %ebx
f01013b7:	8b 45 08             	mov    0x8(%ebp),%eax
f01013ba:	8b 55 0c             	mov    0xc(%ebp),%edx
f01013bd:	89 c3                	mov    %eax,%ebx
f01013bf:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01013c2:	eb 06                	jmp    f01013ca <strncmp+0x17>
		n--, p++, q++;
f01013c4:	83 c0 01             	add    $0x1,%eax
f01013c7:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01013ca:	39 d8                	cmp    %ebx,%eax
f01013cc:	74 15                	je     f01013e3 <strncmp+0x30>
f01013ce:	0f b6 08             	movzbl (%eax),%ecx
f01013d1:	84 c9                	test   %cl,%cl
f01013d3:	74 04                	je     f01013d9 <strncmp+0x26>
f01013d5:	3a 0a                	cmp    (%edx),%cl
f01013d7:	74 eb                	je     f01013c4 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01013d9:	0f b6 00             	movzbl (%eax),%eax
f01013dc:	0f b6 12             	movzbl (%edx),%edx
f01013df:	29 d0                	sub    %edx,%eax
f01013e1:	eb 05                	jmp    f01013e8 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f01013e3:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01013e8:	5b                   	pop    %ebx
f01013e9:	5d                   	pop    %ebp
f01013ea:	c3                   	ret    

f01013eb <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01013eb:	55                   	push   %ebp
f01013ec:	89 e5                	mov    %esp,%ebp
f01013ee:	8b 45 08             	mov    0x8(%ebp),%eax
f01013f1:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01013f5:	eb 07                	jmp    f01013fe <strchr+0x13>
		if (*s == c)
f01013f7:	38 ca                	cmp    %cl,%dl
f01013f9:	74 0f                	je     f010140a <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01013fb:	83 c0 01             	add    $0x1,%eax
f01013fe:	0f b6 10             	movzbl (%eax),%edx
f0101401:	84 d2                	test   %dl,%dl
f0101403:	75 f2                	jne    f01013f7 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0101405:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010140a:	5d                   	pop    %ebp
f010140b:	c3                   	ret    

f010140c <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010140c:	55                   	push   %ebp
f010140d:	89 e5                	mov    %esp,%ebp
f010140f:	8b 45 08             	mov    0x8(%ebp),%eax
f0101412:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101416:	eb 03                	jmp    f010141b <strfind+0xf>
f0101418:	83 c0 01             	add    $0x1,%eax
f010141b:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f010141e:	38 ca                	cmp    %cl,%dl
f0101420:	74 04                	je     f0101426 <strfind+0x1a>
f0101422:	84 d2                	test   %dl,%dl
f0101424:	75 f2                	jne    f0101418 <strfind+0xc>
			break;
	return (char *) s;
}
f0101426:	5d                   	pop    %ebp
f0101427:	c3                   	ret    

f0101428 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0101428:	55                   	push   %ebp
f0101429:	89 e5                	mov    %esp,%ebp
f010142b:	57                   	push   %edi
f010142c:	56                   	push   %esi
f010142d:	53                   	push   %ebx
f010142e:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101431:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0101434:	85 c9                	test   %ecx,%ecx
f0101436:	74 36                	je     f010146e <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0101438:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010143e:	75 28                	jne    f0101468 <memset+0x40>
f0101440:	f6 c1 03             	test   $0x3,%cl
f0101443:	75 23                	jne    f0101468 <memset+0x40>
		c &= 0xFF;
f0101445:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0101449:	89 d3                	mov    %edx,%ebx
f010144b:	c1 e3 08             	shl    $0x8,%ebx
f010144e:	89 d6                	mov    %edx,%esi
f0101450:	c1 e6 18             	shl    $0x18,%esi
f0101453:	89 d0                	mov    %edx,%eax
f0101455:	c1 e0 10             	shl    $0x10,%eax
f0101458:	09 f0                	or     %esi,%eax
f010145a:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f010145c:	89 d8                	mov    %ebx,%eax
f010145e:	09 d0                	or     %edx,%eax
f0101460:	c1 e9 02             	shr    $0x2,%ecx
f0101463:	fc                   	cld    
f0101464:	f3 ab                	rep stos %eax,%es:(%edi)
f0101466:	eb 06                	jmp    f010146e <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0101468:	8b 45 0c             	mov    0xc(%ebp),%eax
f010146b:	fc                   	cld    
f010146c:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f010146e:	89 f8                	mov    %edi,%eax
f0101470:	5b                   	pop    %ebx
f0101471:	5e                   	pop    %esi
f0101472:	5f                   	pop    %edi
f0101473:	5d                   	pop    %ebp
f0101474:	c3                   	ret    

f0101475 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0101475:	55                   	push   %ebp
f0101476:	89 e5                	mov    %esp,%ebp
f0101478:	57                   	push   %edi
f0101479:	56                   	push   %esi
f010147a:	8b 45 08             	mov    0x8(%ebp),%eax
f010147d:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101480:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0101483:	39 c6                	cmp    %eax,%esi
f0101485:	73 35                	jae    f01014bc <memmove+0x47>
f0101487:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f010148a:	39 d0                	cmp    %edx,%eax
f010148c:	73 2e                	jae    f01014bc <memmove+0x47>
		s += n;
		d += n;
f010148e:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101491:	89 d6                	mov    %edx,%esi
f0101493:	09 fe                	or     %edi,%esi
f0101495:	f7 c6 03 00 00 00    	test   $0x3,%esi
f010149b:	75 13                	jne    f01014b0 <memmove+0x3b>
f010149d:	f6 c1 03             	test   $0x3,%cl
f01014a0:	75 0e                	jne    f01014b0 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f01014a2:	83 ef 04             	sub    $0x4,%edi
f01014a5:	8d 72 fc             	lea    -0x4(%edx),%esi
f01014a8:	c1 e9 02             	shr    $0x2,%ecx
f01014ab:	fd                   	std    
f01014ac:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01014ae:	eb 09                	jmp    f01014b9 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01014b0:	83 ef 01             	sub    $0x1,%edi
f01014b3:	8d 72 ff             	lea    -0x1(%edx),%esi
f01014b6:	fd                   	std    
f01014b7:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01014b9:	fc                   	cld    
f01014ba:	eb 1d                	jmp    f01014d9 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01014bc:	89 f2                	mov    %esi,%edx
f01014be:	09 c2                	or     %eax,%edx
f01014c0:	f6 c2 03             	test   $0x3,%dl
f01014c3:	75 0f                	jne    f01014d4 <memmove+0x5f>
f01014c5:	f6 c1 03             	test   $0x3,%cl
f01014c8:	75 0a                	jne    f01014d4 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f01014ca:	c1 e9 02             	shr    $0x2,%ecx
f01014cd:	89 c7                	mov    %eax,%edi
f01014cf:	fc                   	cld    
f01014d0:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01014d2:	eb 05                	jmp    f01014d9 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01014d4:	89 c7                	mov    %eax,%edi
f01014d6:	fc                   	cld    
f01014d7:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01014d9:	5e                   	pop    %esi
f01014da:	5f                   	pop    %edi
f01014db:	5d                   	pop    %ebp
f01014dc:	c3                   	ret    

f01014dd <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01014dd:	55                   	push   %ebp
f01014de:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f01014e0:	ff 75 10             	pushl  0x10(%ebp)
f01014e3:	ff 75 0c             	pushl  0xc(%ebp)
f01014e6:	ff 75 08             	pushl  0x8(%ebp)
f01014e9:	e8 87 ff ff ff       	call   f0101475 <memmove>
}
f01014ee:	c9                   	leave  
f01014ef:	c3                   	ret    

f01014f0 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01014f0:	55                   	push   %ebp
f01014f1:	89 e5                	mov    %esp,%ebp
f01014f3:	56                   	push   %esi
f01014f4:	53                   	push   %ebx
f01014f5:	8b 45 08             	mov    0x8(%ebp),%eax
f01014f8:	8b 55 0c             	mov    0xc(%ebp),%edx
f01014fb:	89 c6                	mov    %eax,%esi
f01014fd:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101500:	eb 1a                	jmp    f010151c <memcmp+0x2c>
		if (*s1 != *s2)
f0101502:	0f b6 08             	movzbl (%eax),%ecx
f0101505:	0f b6 1a             	movzbl (%edx),%ebx
f0101508:	38 d9                	cmp    %bl,%cl
f010150a:	74 0a                	je     f0101516 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f010150c:	0f b6 c1             	movzbl %cl,%eax
f010150f:	0f b6 db             	movzbl %bl,%ebx
f0101512:	29 d8                	sub    %ebx,%eax
f0101514:	eb 0f                	jmp    f0101525 <memcmp+0x35>
		s1++, s2++;
f0101516:	83 c0 01             	add    $0x1,%eax
f0101519:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010151c:	39 f0                	cmp    %esi,%eax
f010151e:	75 e2                	jne    f0101502 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0101520:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101525:	5b                   	pop    %ebx
f0101526:	5e                   	pop    %esi
f0101527:	5d                   	pop    %ebp
f0101528:	c3                   	ret    

f0101529 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0101529:	55                   	push   %ebp
f010152a:	89 e5                	mov    %esp,%ebp
f010152c:	53                   	push   %ebx
f010152d:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0101530:	89 c1                	mov    %eax,%ecx
f0101532:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f0101535:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0101539:	eb 0a                	jmp    f0101545 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f010153b:	0f b6 10             	movzbl (%eax),%edx
f010153e:	39 da                	cmp    %ebx,%edx
f0101540:	74 07                	je     f0101549 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0101542:	83 c0 01             	add    $0x1,%eax
f0101545:	39 c8                	cmp    %ecx,%eax
f0101547:	72 f2                	jb     f010153b <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0101549:	5b                   	pop    %ebx
f010154a:	5d                   	pop    %ebp
f010154b:	c3                   	ret    

f010154c <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f010154c:	55                   	push   %ebp
f010154d:	89 e5                	mov    %esp,%ebp
f010154f:	57                   	push   %edi
f0101550:	56                   	push   %esi
f0101551:	53                   	push   %ebx
f0101552:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101555:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101558:	eb 03                	jmp    f010155d <strtol+0x11>
		s++;
f010155a:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010155d:	0f b6 01             	movzbl (%ecx),%eax
f0101560:	3c 20                	cmp    $0x20,%al
f0101562:	74 f6                	je     f010155a <strtol+0xe>
f0101564:	3c 09                	cmp    $0x9,%al
f0101566:	74 f2                	je     f010155a <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0101568:	3c 2b                	cmp    $0x2b,%al
f010156a:	75 0a                	jne    f0101576 <strtol+0x2a>
		s++;
f010156c:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f010156f:	bf 00 00 00 00       	mov    $0x0,%edi
f0101574:	eb 11                	jmp    f0101587 <strtol+0x3b>
f0101576:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f010157b:	3c 2d                	cmp    $0x2d,%al
f010157d:	75 08                	jne    f0101587 <strtol+0x3b>
		s++, neg = 1;
f010157f:	83 c1 01             	add    $0x1,%ecx
f0101582:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0101587:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f010158d:	75 15                	jne    f01015a4 <strtol+0x58>
f010158f:	80 39 30             	cmpb   $0x30,(%ecx)
f0101592:	75 10                	jne    f01015a4 <strtol+0x58>
f0101594:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0101598:	75 7c                	jne    f0101616 <strtol+0xca>
		s += 2, base = 16;
f010159a:	83 c1 02             	add    $0x2,%ecx
f010159d:	bb 10 00 00 00       	mov    $0x10,%ebx
f01015a2:	eb 16                	jmp    f01015ba <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f01015a4:	85 db                	test   %ebx,%ebx
f01015a6:	75 12                	jne    f01015ba <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01015a8:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01015ad:	80 39 30             	cmpb   $0x30,(%ecx)
f01015b0:	75 08                	jne    f01015ba <strtol+0x6e>
		s++, base = 8;
f01015b2:	83 c1 01             	add    $0x1,%ecx
f01015b5:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f01015ba:	b8 00 00 00 00       	mov    $0x0,%eax
f01015bf:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f01015c2:	0f b6 11             	movzbl (%ecx),%edx
f01015c5:	8d 72 d0             	lea    -0x30(%edx),%esi
f01015c8:	89 f3                	mov    %esi,%ebx
f01015ca:	80 fb 09             	cmp    $0x9,%bl
f01015cd:	77 08                	ja     f01015d7 <strtol+0x8b>
			dig = *s - '0';
f01015cf:	0f be d2             	movsbl %dl,%edx
f01015d2:	83 ea 30             	sub    $0x30,%edx
f01015d5:	eb 22                	jmp    f01015f9 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f01015d7:	8d 72 9f             	lea    -0x61(%edx),%esi
f01015da:	89 f3                	mov    %esi,%ebx
f01015dc:	80 fb 19             	cmp    $0x19,%bl
f01015df:	77 08                	ja     f01015e9 <strtol+0x9d>
			dig = *s - 'a' + 10;
f01015e1:	0f be d2             	movsbl %dl,%edx
f01015e4:	83 ea 57             	sub    $0x57,%edx
f01015e7:	eb 10                	jmp    f01015f9 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f01015e9:	8d 72 bf             	lea    -0x41(%edx),%esi
f01015ec:	89 f3                	mov    %esi,%ebx
f01015ee:	80 fb 19             	cmp    $0x19,%bl
f01015f1:	77 16                	ja     f0101609 <strtol+0xbd>
			dig = *s - 'A' + 10;
f01015f3:	0f be d2             	movsbl %dl,%edx
f01015f6:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f01015f9:	3b 55 10             	cmp    0x10(%ebp),%edx
f01015fc:	7d 0b                	jge    f0101609 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f01015fe:	83 c1 01             	add    $0x1,%ecx
f0101601:	0f af 45 10          	imul   0x10(%ebp),%eax
f0101605:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f0101607:	eb b9                	jmp    f01015c2 <strtol+0x76>

	if (endptr)
f0101609:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f010160d:	74 0d                	je     f010161c <strtol+0xd0>
		*endptr = (char *) s;
f010160f:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101612:	89 0e                	mov    %ecx,(%esi)
f0101614:	eb 06                	jmp    f010161c <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101616:	85 db                	test   %ebx,%ebx
f0101618:	74 98                	je     f01015b2 <strtol+0x66>
f010161a:	eb 9e                	jmp    f01015ba <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f010161c:	89 c2                	mov    %eax,%edx
f010161e:	f7 da                	neg    %edx
f0101620:	85 ff                	test   %edi,%edi
f0101622:	0f 45 c2             	cmovne %edx,%eax
}
f0101625:	5b                   	pop    %ebx
f0101626:	5e                   	pop    %esi
f0101627:	5f                   	pop    %edi
f0101628:	5d                   	pop    %ebp
f0101629:	c3                   	ret    
f010162a:	66 90                	xchg   %ax,%ax
f010162c:	66 90                	xchg   %ax,%ax
f010162e:	66 90                	xchg   %ax,%ax

f0101630 <__udivdi3>:
f0101630:	55                   	push   %ebp
f0101631:	57                   	push   %edi
f0101632:	56                   	push   %esi
f0101633:	53                   	push   %ebx
f0101634:	83 ec 1c             	sub    $0x1c,%esp
f0101637:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f010163b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f010163f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0101643:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0101647:	85 f6                	test   %esi,%esi
f0101649:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010164d:	89 ca                	mov    %ecx,%edx
f010164f:	89 f8                	mov    %edi,%eax
f0101651:	75 3d                	jne    f0101690 <__udivdi3+0x60>
f0101653:	39 cf                	cmp    %ecx,%edi
f0101655:	0f 87 c5 00 00 00    	ja     f0101720 <__udivdi3+0xf0>
f010165b:	85 ff                	test   %edi,%edi
f010165d:	89 fd                	mov    %edi,%ebp
f010165f:	75 0b                	jne    f010166c <__udivdi3+0x3c>
f0101661:	b8 01 00 00 00       	mov    $0x1,%eax
f0101666:	31 d2                	xor    %edx,%edx
f0101668:	f7 f7                	div    %edi
f010166a:	89 c5                	mov    %eax,%ebp
f010166c:	89 c8                	mov    %ecx,%eax
f010166e:	31 d2                	xor    %edx,%edx
f0101670:	f7 f5                	div    %ebp
f0101672:	89 c1                	mov    %eax,%ecx
f0101674:	89 d8                	mov    %ebx,%eax
f0101676:	89 cf                	mov    %ecx,%edi
f0101678:	f7 f5                	div    %ebp
f010167a:	89 c3                	mov    %eax,%ebx
f010167c:	89 d8                	mov    %ebx,%eax
f010167e:	89 fa                	mov    %edi,%edx
f0101680:	83 c4 1c             	add    $0x1c,%esp
f0101683:	5b                   	pop    %ebx
f0101684:	5e                   	pop    %esi
f0101685:	5f                   	pop    %edi
f0101686:	5d                   	pop    %ebp
f0101687:	c3                   	ret    
f0101688:	90                   	nop
f0101689:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101690:	39 ce                	cmp    %ecx,%esi
f0101692:	77 74                	ja     f0101708 <__udivdi3+0xd8>
f0101694:	0f bd fe             	bsr    %esi,%edi
f0101697:	83 f7 1f             	xor    $0x1f,%edi
f010169a:	0f 84 98 00 00 00    	je     f0101738 <__udivdi3+0x108>
f01016a0:	bb 20 00 00 00       	mov    $0x20,%ebx
f01016a5:	89 f9                	mov    %edi,%ecx
f01016a7:	89 c5                	mov    %eax,%ebp
f01016a9:	29 fb                	sub    %edi,%ebx
f01016ab:	d3 e6                	shl    %cl,%esi
f01016ad:	89 d9                	mov    %ebx,%ecx
f01016af:	d3 ed                	shr    %cl,%ebp
f01016b1:	89 f9                	mov    %edi,%ecx
f01016b3:	d3 e0                	shl    %cl,%eax
f01016b5:	09 ee                	or     %ebp,%esi
f01016b7:	89 d9                	mov    %ebx,%ecx
f01016b9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01016bd:	89 d5                	mov    %edx,%ebp
f01016bf:	8b 44 24 08          	mov    0x8(%esp),%eax
f01016c3:	d3 ed                	shr    %cl,%ebp
f01016c5:	89 f9                	mov    %edi,%ecx
f01016c7:	d3 e2                	shl    %cl,%edx
f01016c9:	89 d9                	mov    %ebx,%ecx
f01016cb:	d3 e8                	shr    %cl,%eax
f01016cd:	09 c2                	or     %eax,%edx
f01016cf:	89 d0                	mov    %edx,%eax
f01016d1:	89 ea                	mov    %ebp,%edx
f01016d3:	f7 f6                	div    %esi
f01016d5:	89 d5                	mov    %edx,%ebp
f01016d7:	89 c3                	mov    %eax,%ebx
f01016d9:	f7 64 24 0c          	mull   0xc(%esp)
f01016dd:	39 d5                	cmp    %edx,%ebp
f01016df:	72 10                	jb     f01016f1 <__udivdi3+0xc1>
f01016e1:	8b 74 24 08          	mov    0x8(%esp),%esi
f01016e5:	89 f9                	mov    %edi,%ecx
f01016e7:	d3 e6                	shl    %cl,%esi
f01016e9:	39 c6                	cmp    %eax,%esi
f01016eb:	73 07                	jae    f01016f4 <__udivdi3+0xc4>
f01016ed:	39 d5                	cmp    %edx,%ebp
f01016ef:	75 03                	jne    f01016f4 <__udivdi3+0xc4>
f01016f1:	83 eb 01             	sub    $0x1,%ebx
f01016f4:	31 ff                	xor    %edi,%edi
f01016f6:	89 d8                	mov    %ebx,%eax
f01016f8:	89 fa                	mov    %edi,%edx
f01016fa:	83 c4 1c             	add    $0x1c,%esp
f01016fd:	5b                   	pop    %ebx
f01016fe:	5e                   	pop    %esi
f01016ff:	5f                   	pop    %edi
f0101700:	5d                   	pop    %ebp
f0101701:	c3                   	ret    
f0101702:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101708:	31 ff                	xor    %edi,%edi
f010170a:	31 db                	xor    %ebx,%ebx
f010170c:	89 d8                	mov    %ebx,%eax
f010170e:	89 fa                	mov    %edi,%edx
f0101710:	83 c4 1c             	add    $0x1c,%esp
f0101713:	5b                   	pop    %ebx
f0101714:	5e                   	pop    %esi
f0101715:	5f                   	pop    %edi
f0101716:	5d                   	pop    %ebp
f0101717:	c3                   	ret    
f0101718:	90                   	nop
f0101719:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101720:	89 d8                	mov    %ebx,%eax
f0101722:	f7 f7                	div    %edi
f0101724:	31 ff                	xor    %edi,%edi
f0101726:	89 c3                	mov    %eax,%ebx
f0101728:	89 d8                	mov    %ebx,%eax
f010172a:	89 fa                	mov    %edi,%edx
f010172c:	83 c4 1c             	add    $0x1c,%esp
f010172f:	5b                   	pop    %ebx
f0101730:	5e                   	pop    %esi
f0101731:	5f                   	pop    %edi
f0101732:	5d                   	pop    %ebp
f0101733:	c3                   	ret    
f0101734:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101738:	39 ce                	cmp    %ecx,%esi
f010173a:	72 0c                	jb     f0101748 <__udivdi3+0x118>
f010173c:	31 db                	xor    %ebx,%ebx
f010173e:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0101742:	0f 87 34 ff ff ff    	ja     f010167c <__udivdi3+0x4c>
f0101748:	bb 01 00 00 00       	mov    $0x1,%ebx
f010174d:	e9 2a ff ff ff       	jmp    f010167c <__udivdi3+0x4c>
f0101752:	66 90                	xchg   %ax,%ax
f0101754:	66 90                	xchg   %ax,%ax
f0101756:	66 90                	xchg   %ax,%ax
f0101758:	66 90                	xchg   %ax,%ax
f010175a:	66 90                	xchg   %ax,%ax
f010175c:	66 90                	xchg   %ax,%ax
f010175e:	66 90                	xchg   %ax,%ax

f0101760 <__umoddi3>:
f0101760:	55                   	push   %ebp
f0101761:	57                   	push   %edi
f0101762:	56                   	push   %esi
f0101763:	53                   	push   %ebx
f0101764:	83 ec 1c             	sub    $0x1c,%esp
f0101767:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010176b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010176f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0101773:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0101777:	85 d2                	test   %edx,%edx
f0101779:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010177d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101781:	89 f3                	mov    %esi,%ebx
f0101783:	89 3c 24             	mov    %edi,(%esp)
f0101786:	89 74 24 04          	mov    %esi,0x4(%esp)
f010178a:	75 1c                	jne    f01017a8 <__umoddi3+0x48>
f010178c:	39 f7                	cmp    %esi,%edi
f010178e:	76 50                	jbe    f01017e0 <__umoddi3+0x80>
f0101790:	89 c8                	mov    %ecx,%eax
f0101792:	89 f2                	mov    %esi,%edx
f0101794:	f7 f7                	div    %edi
f0101796:	89 d0                	mov    %edx,%eax
f0101798:	31 d2                	xor    %edx,%edx
f010179a:	83 c4 1c             	add    $0x1c,%esp
f010179d:	5b                   	pop    %ebx
f010179e:	5e                   	pop    %esi
f010179f:	5f                   	pop    %edi
f01017a0:	5d                   	pop    %ebp
f01017a1:	c3                   	ret    
f01017a2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01017a8:	39 f2                	cmp    %esi,%edx
f01017aa:	89 d0                	mov    %edx,%eax
f01017ac:	77 52                	ja     f0101800 <__umoddi3+0xa0>
f01017ae:	0f bd ea             	bsr    %edx,%ebp
f01017b1:	83 f5 1f             	xor    $0x1f,%ebp
f01017b4:	75 5a                	jne    f0101810 <__umoddi3+0xb0>
f01017b6:	3b 54 24 04          	cmp    0x4(%esp),%edx
f01017ba:	0f 82 e0 00 00 00    	jb     f01018a0 <__umoddi3+0x140>
f01017c0:	39 0c 24             	cmp    %ecx,(%esp)
f01017c3:	0f 86 d7 00 00 00    	jbe    f01018a0 <__umoddi3+0x140>
f01017c9:	8b 44 24 08          	mov    0x8(%esp),%eax
f01017cd:	8b 54 24 04          	mov    0x4(%esp),%edx
f01017d1:	83 c4 1c             	add    $0x1c,%esp
f01017d4:	5b                   	pop    %ebx
f01017d5:	5e                   	pop    %esi
f01017d6:	5f                   	pop    %edi
f01017d7:	5d                   	pop    %ebp
f01017d8:	c3                   	ret    
f01017d9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01017e0:	85 ff                	test   %edi,%edi
f01017e2:	89 fd                	mov    %edi,%ebp
f01017e4:	75 0b                	jne    f01017f1 <__umoddi3+0x91>
f01017e6:	b8 01 00 00 00       	mov    $0x1,%eax
f01017eb:	31 d2                	xor    %edx,%edx
f01017ed:	f7 f7                	div    %edi
f01017ef:	89 c5                	mov    %eax,%ebp
f01017f1:	89 f0                	mov    %esi,%eax
f01017f3:	31 d2                	xor    %edx,%edx
f01017f5:	f7 f5                	div    %ebp
f01017f7:	89 c8                	mov    %ecx,%eax
f01017f9:	f7 f5                	div    %ebp
f01017fb:	89 d0                	mov    %edx,%eax
f01017fd:	eb 99                	jmp    f0101798 <__umoddi3+0x38>
f01017ff:	90                   	nop
f0101800:	89 c8                	mov    %ecx,%eax
f0101802:	89 f2                	mov    %esi,%edx
f0101804:	83 c4 1c             	add    $0x1c,%esp
f0101807:	5b                   	pop    %ebx
f0101808:	5e                   	pop    %esi
f0101809:	5f                   	pop    %edi
f010180a:	5d                   	pop    %ebp
f010180b:	c3                   	ret    
f010180c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101810:	8b 34 24             	mov    (%esp),%esi
f0101813:	bf 20 00 00 00       	mov    $0x20,%edi
f0101818:	89 e9                	mov    %ebp,%ecx
f010181a:	29 ef                	sub    %ebp,%edi
f010181c:	d3 e0                	shl    %cl,%eax
f010181e:	89 f9                	mov    %edi,%ecx
f0101820:	89 f2                	mov    %esi,%edx
f0101822:	d3 ea                	shr    %cl,%edx
f0101824:	89 e9                	mov    %ebp,%ecx
f0101826:	09 c2                	or     %eax,%edx
f0101828:	89 d8                	mov    %ebx,%eax
f010182a:	89 14 24             	mov    %edx,(%esp)
f010182d:	89 f2                	mov    %esi,%edx
f010182f:	d3 e2                	shl    %cl,%edx
f0101831:	89 f9                	mov    %edi,%ecx
f0101833:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101837:	8b 54 24 0c          	mov    0xc(%esp),%edx
f010183b:	d3 e8                	shr    %cl,%eax
f010183d:	89 e9                	mov    %ebp,%ecx
f010183f:	89 c6                	mov    %eax,%esi
f0101841:	d3 e3                	shl    %cl,%ebx
f0101843:	89 f9                	mov    %edi,%ecx
f0101845:	89 d0                	mov    %edx,%eax
f0101847:	d3 e8                	shr    %cl,%eax
f0101849:	89 e9                	mov    %ebp,%ecx
f010184b:	09 d8                	or     %ebx,%eax
f010184d:	89 d3                	mov    %edx,%ebx
f010184f:	89 f2                	mov    %esi,%edx
f0101851:	f7 34 24             	divl   (%esp)
f0101854:	89 d6                	mov    %edx,%esi
f0101856:	d3 e3                	shl    %cl,%ebx
f0101858:	f7 64 24 04          	mull   0x4(%esp)
f010185c:	39 d6                	cmp    %edx,%esi
f010185e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0101862:	89 d1                	mov    %edx,%ecx
f0101864:	89 c3                	mov    %eax,%ebx
f0101866:	72 08                	jb     f0101870 <__umoddi3+0x110>
f0101868:	75 11                	jne    f010187b <__umoddi3+0x11b>
f010186a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f010186e:	73 0b                	jae    f010187b <__umoddi3+0x11b>
f0101870:	2b 44 24 04          	sub    0x4(%esp),%eax
f0101874:	1b 14 24             	sbb    (%esp),%edx
f0101877:	89 d1                	mov    %edx,%ecx
f0101879:	89 c3                	mov    %eax,%ebx
f010187b:	8b 54 24 08          	mov    0x8(%esp),%edx
f010187f:	29 da                	sub    %ebx,%edx
f0101881:	19 ce                	sbb    %ecx,%esi
f0101883:	89 f9                	mov    %edi,%ecx
f0101885:	89 f0                	mov    %esi,%eax
f0101887:	d3 e0                	shl    %cl,%eax
f0101889:	89 e9                	mov    %ebp,%ecx
f010188b:	d3 ea                	shr    %cl,%edx
f010188d:	89 e9                	mov    %ebp,%ecx
f010188f:	d3 ee                	shr    %cl,%esi
f0101891:	09 d0                	or     %edx,%eax
f0101893:	89 f2                	mov    %esi,%edx
f0101895:	83 c4 1c             	add    $0x1c,%esp
f0101898:	5b                   	pop    %ebx
f0101899:	5e                   	pop    %esi
f010189a:	5f                   	pop    %edi
f010189b:	5d                   	pop    %ebp
f010189c:	c3                   	ret    
f010189d:	8d 76 00             	lea    0x0(%esi),%esi
f01018a0:	29 f9                	sub    %edi,%ecx
f01018a2:	19 d6                	sbb    %edx,%esi
f01018a4:	89 74 24 04          	mov    %esi,0x4(%esp)
f01018a8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01018ac:	e9 18 ff ff ff       	jmp    f01017c9 <__umoddi3+0x69>


kernel/kernel：     文件格式 elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	90013103          	ld	sp,-1792(sp) # 80008900 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	fde70713          	addi	a4,a4,-34 # 80009030 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	ebc78793          	addi	a5,a5,-324 # 80005f20 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd67d7>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	1dc78793          	addi	a5,a5,476 # 8000128a <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  timerinit();
    800000d8:	00000097          	auipc	ra,0x0
    800000dc:	f44080e7          	jalr	-188(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000e0:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000e4:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000e6:	823e                	mv	tp,a5
  asm volatile("mret");
    800000e8:	30200073          	mret
}
    800000ec:	60a2                	ld	ra,8(sp)
    800000ee:	6402                	ld	s0,0(sp)
    800000f0:	0141                	addi	sp,sp,16
    800000f2:	8082                	ret

00000000800000f4 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000f4:	715d                	addi	sp,sp,-80
    800000f6:	e486                	sd	ra,72(sp)
    800000f8:	e0a2                	sd	s0,64(sp)
    800000fa:	fc26                	sd	s1,56(sp)
    800000fc:	f84a                	sd	s2,48(sp)
    800000fe:	f44e                	sd	s3,40(sp)
    80000100:	f052                	sd	s4,32(sp)
    80000102:	ec56                	sd	s5,24(sp)
    80000104:	0880                	addi	s0,sp,80
    80000106:	8a2a                	mv	s4,a0
    80000108:	84ae                	mv	s1,a1
    8000010a:	89b2                	mv	s3,a2
  int i;

  acquire(&cons.lock);
    8000010c:	00011517          	auipc	a0,0x11
    80000110:	06450513          	addi	a0,a0,100 # 80011170 <cons>
    80000114:	00001097          	auipc	ra,0x1
    80000118:	be4080e7          	jalr	-1052(ra) # 80000cf8 <acquire>
  for(i = 0; i < n; i++){
    8000011c:	05305b63          	blez	s3,80000172 <consolewrite+0x7e>
    80000120:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000122:	5afd                	li	s5,-1
    80000124:	4685                	li	a3,1
    80000126:	8626                	mv	a2,s1
    80000128:	85d2                	mv	a1,s4
    8000012a:	fbf40513          	addi	a0,s0,-65
    8000012e:	00002097          	auipc	ra,0x2
    80000132:	6da080e7          	jalr	1754(ra) # 80002808 <either_copyin>
    80000136:	01550c63          	beq	a0,s5,8000014e <consolewrite+0x5a>
      break;
    uartputc(c);
    8000013a:	fbf44503          	lbu	a0,-65(s0)
    8000013e:	00000097          	auipc	ra,0x0
    80000142:	7aa080e7          	jalr	1962(ra) # 800008e8 <uartputc>
  for(i = 0; i < n; i++){
    80000146:	2905                	addiw	s2,s2,1
    80000148:	0485                	addi	s1,s1,1
    8000014a:	fd299de3          	bne	s3,s2,80000124 <consolewrite+0x30>
  }
  release(&cons.lock);
    8000014e:	00011517          	auipc	a0,0x11
    80000152:	02250513          	addi	a0,a0,34 # 80011170 <cons>
    80000156:	00001097          	auipc	ra,0x1
    8000015a:	c72080e7          	jalr	-910(ra) # 80000dc8 <release>

  return i;
}
    8000015e:	854a                	mv	a0,s2
    80000160:	60a6                	ld	ra,72(sp)
    80000162:	6406                	ld	s0,64(sp)
    80000164:	74e2                	ld	s1,56(sp)
    80000166:	7942                	ld	s2,48(sp)
    80000168:	79a2                	ld	s3,40(sp)
    8000016a:	7a02                	ld	s4,32(sp)
    8000016c:	6ae2                	ld	s5,24(sp)
    8000016e:	6161                	addi	sp,sp,80
    80000170:	8082                	ret
  for(i = 0; i < n; i++){
    80000172:	4901                	li	s2,0
    80000174:	bfe9                	j	8000014e <consolewrite+0x5a>

0000000080000176 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000176:	7119                	addi	sp,sp,-128
    80000178:	fc86                	sd	ra,120(sp)
    8000017a:	f8a2                	sd	s0,112(sp)
    8000017c:	f4a6                	sd	s1,104(sp)
    8000017e:	f0ca                	sd	s2,96(sp)
    80000180:	ecce                	sd	s3,88(sp)
    80000182:	e8d2                	sd	s4,80(sp)
    80000184:	e4d6                	sd	s5,72(sp)
    80000186:	e0da                	sd	s6,64(sp)
    80000188:	fc5e                	sd	s7,56(sp)
    8000018a:	f862                	sd	s8,48(sp)
    8000018c:	f466                	sd	s9,40(sp)
    8000018e:	f06a                	sd	s10,32(sp)
    80000190:	ec6e                	sd	s11,24(sp)
    80000192:	0100                	addi	s0,sp,128
    80000194:	8b2a                	mv	s6,a0
    80000196:	8aae                	mv	s5,a1
    80000198:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    8000019a:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000019e:	00011517          	auipc	a0,0x11
    800001a2:	fd250513          	addi	a0,a0,-46 # 80011170 <cons>
    800001a6:	00001097          	auipc	ra,0x1
    800001aa:	b52080e7          	jalr	-1198(ra) # 80000cf8 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    800001ae:	00011497          	auipc	s1,0x11
    800001b2:	fc248493          	addi	s1,s1,-62 # 80011170 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001b6:	89a6                	mv	s3,s1
    800001b8:	00011917          	auipc	s2,0x11
    800001bc:	05890913          	addi	s2,s2,88 # 80011210 <cons+0xa0>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001c0:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001c2:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001c4:	4da9                	li	s11,10
  while(n > 0){
    800001c6:	07405863          	blez	s4,80000236 <consoleread+0xc0>
    while(cons.r == cons.w){
    800001ca:	0a04a783          	lw	a5,160(s1)
    800001ce:	0a44a703          	lw	a4,164(s1)
    800001d2:	02f71463          	bne	a4,a5,800001fa <consoleread+0x84>
      if(myproc()->killed){
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	b6a080e7          	jalr	-1174(ra) # 80001d40 <myproc>
    800001de:	5d1c                	lw	a5,56(a0)
    800001e0:	e7b5                	bnez	a5,8000024c <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001e2:	85ce                	mv	a1,s3
    800001e4:	854a                	mv	a0,s2
    800001e6:	00002097          	auipc	ra,0x2
    800001ea:	36a080e7          	jalr	874(ra) # 80002550 <sleep>
    while(cons.r == cons.w){
    800001ee:	0a04a783          	lw	a5,160(s1)
    800001f2:	0a44a703          	lw	a4,164(s1)
    800001f6:	fef700e3          	beq	a4,a5,800001d6 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001fa:	0017871b          	addiw	a4,a5,1
    800001fe:	0ae4a023          	sw	a4,160(s1)
    80000202:	07f7f713          	andi	a4,a5,127
    80000206:	9726                	add	a4,a4,s1
    80000208:	02074703          	lbu	a4,32(a4)
    8000020c:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    80000210:	079c0663          	beq	s8,s9,8000027c <consoleread+0x106>
    cbuf = c;
    80000214:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000218:	4685                	li	a3,1
    8000021a:	f8f40613          	addi	a2,s0,-113
    8000021e:	85d6                	mv	a1,s5
    80000220:	855a                	mv	a0,s6
    80000222:	00002097          	auipc	ra,0x2
    80000226:	590080e7          	jalr	1424(ra) # 800027b2 <either_copyout>
    8000022a:	01a50663          	beq	a0,s10,80000236 <consoleread+0xc0>
    dst++;
    8000022e:	0a85                	addi	s5,s5,1
    --n;
    80000230:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000232:	f9bc1ae3          	bne	s8,s11,800001c6 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000236:	00011517          	auipc	a0,0x11
    8000023a:	f3a50513          	addi	a0,a0,-198 # 80011170 <cons>
    8000023e:	00001097          	auipc	ra,0x1
    80000242:	b8a080e7          	jalr	-1142(ra) # 80000dc8 <release>

  return target - n;
    80000246:	414b853b          	subw	a0,s7,s4
    8000024a:	a811                	j	8000025e <consoleread+0xe8>
        release(&cons.lock);
    8000024c:	00011517          	auipc	a0,0x11
    80000250:	f2450513          	addi	a0,a0,-220 # 80011170 <cons>
    80000254:	00001097          	auipc	ra,0x1
    80000258:	b74080e7          	jalr	-1164(ra) # 80000dc8 <release>
        return -1;
    8000025c:	557d                	li	a0,-1
}
    8000025e:	70e6                	ld	ra,120(sp)
    80000260:	7446                	ld	s0,112(sp)
    80000262:	74a6                	ld	s1,104(sp)
    80000264:	7906                	ld	s2,96(sp)
    80000266:	69e6                	ld	s3,88(sp)
    80000268:	6a46                	ld	s4,80(sp)
    8000026a:	6aa6                	ld	s5,72(sp)
    8000026c:	6b06                	ld	s6,64(sp)
    8000026e:	7be2                	ld	s7,56(sp)
    80000270:	7c42                	ld	s8,48(sp)
    80000272:	7ca2                	ld	s9,40(sp)
    80000274:	7d02                	ld	s10,32(sp)
    80000276:	6de2                	ld	s11,24(sp)
    80000278:	6109                	addi	sp,sp,128
    8000027a:	8082                	ret
      if(n < target){
    8000027c:	000a071b          	sext.w	a4,s4
    80000280:	fb777be3          	bgeu	a4,s7,80000236 <consoleread+0xc0>
        cons.r--;
    80000284:	00011717          	auipc	a4,0x11
    80000288:	f8f72623          	sw	a5,-116(a4) # 80011210 <cons+0xa0>
    8000028c:	b76d                	j	80000236 <consoleread+0xc0>

000000008000028e <consputc>:
{
    8000028e:	1141                	addi	sp,sp,-16
    80000290:	e406                	sd	ra,8(sp)
    80000292:	e022                	sd	s0,0(sp)
    80000294:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000296:	10000793          	li	a5,256
    8000029a:	00f50a63          	beq	a0,a5,800002ae <consputc+0x20>
    uartputc_sync(c);
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	564080e7          	jalr	1380(ra) # 80000802 <uartputc_sync>
}
    800002a6:	60a2                	ld	ra,8(sp)
    800002a8:	6402                	ld	s0,0(sp)
    800002aa:	0141                	addi	sp,sp,16
    800002ac:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800002ae:	4521                	li	a0,8
    800002b0:	00000097          	auipc	ra,0x0
    800002b4:	552080e7          	jalr	1362(ra) # 80000802 <uartputc_sync>
    800002b8:	02000513          	li	a0,32
    800002bc:	00000097          	auipc	ra,0x0
    800002c0:	546080e7          	jalr	1350(ra) # 80000802 <uartputc_sync>
    800002c4:	4521                	li	a0,8
    800002c6:	00000097          	auipc	ra,0x0
    800002ca:	53c080e7          	jalr	1340(ra) # 80000802 <uartputc_sync>
    800002ce:	bfe1                	j	800002a6 <consputc+0x18>

00000000800002d0 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002d0:	1101                	addi	sp,sp,-32
    800002d2:	ec06                	sd	ra,24(sp)
    800002d4:	e822                	sd	s0,16(sp)
    800002d6:	e426                	sd	s1,8(sp)
    800002d8:	e04a                	sd	s2,0(sp)
    800002da:	1000                	addi	s0,sp,32
    800002dc:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002de:	00011517          	auipc	a0,0x11
    800002e2:	e9250513          	addi	a0,a0,-366 # 80011170 <cons>
    800002e6:	00001097          	auipc	ra,0x1
    800002ea:	a12080e7          	jalr	-1518(ra) # 80000cf8 <acquire>

  switch(c){
    800002ee:	47d5                	li	a5,21
    800002f0:	0af48663          	beq	s1,a5,8000039c <consoleintr+0xcc>
    800002f4:	0297ca63          	blt	a5,s1,80000328 <consoleintr+0x58>
    800002f8:	47a1                	li	a5,8
    800002fa:	0ef48763          	beq	s1,a5,800003e8 <consoleintr+0x118>
    800002fe:	47c1                	li	a5,16
    80000300:	10f49a63          	bne	s1,a5,80000414 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    80000304:	00002097          	auipc	ra,0x2
    80000308:	55a080e7          	jalr	1370(ra) # 8000285e <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    8000030c:	00011517          	auipc	a0,0x11
    80000310:	e6450513          	addi	a0,a0,-412 # 80011170 <cons>
    80000314:	00001097          	auipc	ra,0x1
    80000318:	ab4080e7          	jalr	-1356(ra) # 80000dc8 <release>
}
    8000031c:	60e2                	ld	ra,24(sp)
    8000031e:	6442                	ld	s0,16(sp)
    80000320:	64a2                	ld	s1,8(sp)
    80000322:	6902                	ld	s2,0(sp)
    80000324:	6105                	addi	sp,sp,32
    80000326:	8082                	ret
  switch(c){
    80000328:	07f00793          	li	a5,127
    8000032c:	0af48e63          	beq	s1,a5,800003e8 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000330:	00011717          	auipc	a4,0x11
    80000334:	e4070713          	addi	a4,a4,-448 # 80011170 <cons>
    80000338:	0a872783          	lw	a5,168(a4)
    8000033c:	0a072703          	lw	a4,160(a4)
    80000340:	9f99                	subw	a5,a5,a4
    80000342:	07f00713          	li	a4,127
    80000346:	fcf763e3          	bltu	a4,a5,8000030c <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    8000034a:	47b5                	li	a5,13
    8000034c:	0cf48763          	beq	s1,a5,8000041a <consoleintr+0x14a>
      consputc(c);
    80000350:	8526                	mv	a0,s1
    80000352:	00000097          	auipc	ra,0x0
    80000356:	f3c080e7          	jalr	-196(ra) # 8000028e <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000035a:	00011797          	auipc	a5,0x11
    8000035e:	e1678793          	addi	a5,a5,-490 # 80011170 <cons>
    80000362:	0a87a703          	lw	a4,168(a5)
    80000366:	0017069b          	addiw	a3,a4,1
    8000036a:	0006861b          	sext.w	a2,a3
    8000036e:	0ad7a423          	sw	a3,168(a5)
    80000372:	07f77713          	andi	a4,a4,127
    80000376:	97ba                	add	a5,a5,a4
    80000378:	02978023          	sb	s1,32(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000037c:	47a9                	li	a5,10
    8000037e:	0cf48563          	beq	s1,a5,80000448 <consoleintr+0x178>
    80000382:	4791                	li	a5,4
    80000384:	0cf48263          	beq	s1,a5,80000448 <consoleintr+0x178>
    80000388:	00011797          	auipc	a5,0x11
    8000038c:	e887a783          	lw	a5,-376(a5) # 80011210 <cons+0xa0>
    80000390:	0807879b          	addiw	a5,a5,128
    80000394:	f6f61ce3          	bne	a2,a5,8000030c <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000398:	863e                	mv	a2,a5
    8000039a:	a07d                	j	80000448 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000039c:	00011717          	auipc	a4,0x11
    800003a0:	dd470713          	addi	a4,a4,-556 # 80011170 <cons>
    800003a4:	0a872783          	lw	a5,168(a4)
    800003a8:	0a472703          	lw	a4,164(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003ac:	00011497          	auipc	s1,0x11
    800003b0:	dc448493          	addi	s1,s1,-572 # 80011170 <cons>
    while(cons.e != cons.w &&
    800003b4:	4929                	li	s2,10
    800003b6:	f4f70be3          	beq	a4,a5,8000030c <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003ba:	37fd                	addiw	a5,a5,-1
    800003bc:	07f7f713          	andi	a4,a5,127
    800003c0:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003c2:	02074703          	lbu	a4,32(a4)
    800003c6:	f52703e3          	beq	a4,s2,8000030c <consoleintr+0x3c>
      cons.e--;
    800003ca:	0af4a423          	sw	a5,168(s1)
      consputc(BACKSPACE);
    800003ce:	10000513          	li	a0,256
    800003d2:	00000097          	auipc	ra,0x0
    800003d6:	ebc080e7          	jalr	-324(ra) # 8000028e <consputc>
    while(cons.e != cons.w &&
    800003da:	0a84a783          	lw	a5,168(s1)
    800003de:	0a44a703          	lw	a4,164(s1)
    800003e2:	fcf71ce3          	bne	a4,a5,800003ba <consoleintr+0xea>
    800003e6:	b71d                	j	8000030c <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003e8:	00011717          	auipc	a4,0x11
    800003ec:	d8870713          	addi	a4,a4,-632 # 80011170 <cons>
    800003f0:	0a872783          	lw	a5,168(a4)
    800003f4:	0a472703          	lw	a4,164(a4)
    800003f8:	f0f70ae3          	beq	a4,a5,8000030c <consoleintr+0x3c>
      cons.e--;
    800003fc:	37fd                	addiw	a5,a5,-1
    800003fe:	00011717          	auipc	a4,0x11
    80000402:	e0f72d23          	sw	a5,-486(a4) # 80011218 <cons+0xa8>
      consputc(BACKSPACE);
    80000406:	10000513          	li	a0,256
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e84080e7          	jalr	-380(ra) # 8000028e <consputc>
    80000412:	bded                	j	8000030c <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000414:	ee048ce3          	beqz	s1,8000030c <consoleintr+0x3c>
    80000418:	bf21                	j	80000330 <consoleintr+0x60>
      consputc(c);
    8000041a:	4529                	li	a0,10
    8000041c:	00000097          	auipc	ra,0x0
    80000420:	e72080e7          	jalr	-398(ra) # 8000028e <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000424:	00011797          	auipc	a5,0x11
    80000428:	d4c78793          	addi	a5,a5,-692 # 80011170 <cons>
    8000042c:	0a87a703          	lw	a4,168(a5)
    80000430:	0017069b          	addiw	a3,a4,1
    80000434:	0006861b          	sext.w	a2,a3
    80000438:	0ad7a423          	sw	a3,168(a5)
    8000043c:	07f77713          	andi	a4,a4,127
    80000440:	97ba                	add	a5,a5,a4
    80000442:	4729                	li	a4,10
    80000444:	02e78023          	sb	a4,32(a5)
        cons.w = cons.e;
    80000448:	00011797          	auipc	a5,0x11
    8000044c:	dcc7a623          	sw	a2,-564(a5) # 80011214 <cons+0xa4>
        wakeup(&cons.r);
    80000450:	00011517          	auipc	a0,0x11
    80000454:	dc050513          	addi	a0,a0,-576 # 80011210 <cons+0xa0>
    80000458:	00002097          	auipc	ra,0x2
    8000045c:	27e080e7          	jalr	638(ra) # 800026d6 <wakeup>
    80000460:	b575                	j	8000030c <consoleintr+0x3c>

0000000080000462 <consoleinit>:

void
consoleinit(void)
{
    80000462:	1141                	addi	sp,sp,-16
    80000464:	e406                	sd	ra,8(sp)
    80000466:	e022                	sd	s0,0(sp)
    80000468:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    8000046a:	00008597          	auipc	a1,0x8
    8000046e:	ba658593          	addi	a1,a1,-1114 # 80008010 <etext+0x10>
    80000472:	00011517          	auipc	a0,0x11
    80000476:	cfe50513          	addi	a0,a0,-770 # 80011170 <cons>
    8000047a:	00001097          	auipc	ra,0x1
    8000047e:	9fa080e7          	jalr	-1542(ra) # 80000e74 <initlock>

  uartinit();
    80000482:	00000097          	auipc	ra,0x0
    80000486:	330080e7          	jalr	816(ra) # 800007b2 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    8000048a:	00022797          	auipc	a5,0x22
    8000048e:	40e78793          	addi	a5,a5,1038 # 80022898 <devsw>
    80000492:	00000717          	auipc	a4,0x0
    80000496:	ce470713          	addi	a4,a4,-796 # 80000176 <consoleread>
    8000049a:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000049c:	00000717          	auipc	a4,0x0
    800004a0:	c5870713          	addi	a4,a4,-936 # 800000f4 <consolewrite>
    800004a4:	ef98                	sd	a4,24(a5)
}
    800004a6:	60a2                	ld	ra,8(sp)
    800004a8:	6402                	ld	s0,0(sp)
    800004aa:	0141                	addi	sp,sp,16
    800004ac:	8082                	ret

00000000800004ae <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800004ae:	7179                	addi	sp,sp,-48
    800004b0:	f406                	sd	ra,40(sp)
    800004b2:	f022                	sd	s0,32(sp)
    800004b4:	ec26                	sd	s1,24(sp)
    800004b6:	e84a                	sd	s2,16(sp)
    800004b8:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004ba:	c219                	beqz	a2,800004c0 <printint+0x12>
    800004bc:	08054663          	bltz	a0,80000548 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004c0:	2501                	sext.w	a0,a0
    800004c2:	4881                	li	a7,0
    800004c4:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004c8:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004ca:	2581                	sext.w	a1,a1
    800004cc:	00008617          	auipc	a2,0x8
    800004d0:	b7460613          	addi	a2,a2,-1164 # 80008040 <digits>
    800004d4:	883a                	mv	a6,a4
    800004d6:	2705                	addiw	a4,a4,1
    800004d8:	02b577bb          	remuw	a5,a0,a1
    800004dc:	1782                	slli	a5,a5,0x20
    800004de:	9381                	srli	a5,a5,0x20
    800004e0:	97b2                	add	a5,a5,a2
    800004e2:	0007c783          	lbu	a5,0(a5)
    800004e6:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004ea:	0005079b          	sext.w	a5,a0
    800004ee:	02b5553b          	divuw	a0,a0,a1
    800004f2:	0685                	addi	a3,a3,1
    800004f4:	feb7f0e3          	bgeu	a5,a1,800004d4 <printint+0x26>

  if(sign)
    800004f8:	00088b63          	beqz	a7,8000050e <printint+0x60>
    buf[i++] = '-';
    800004fc:	fe040793          	addi	a5,s0,-32
    80000500:	973e                	add	a4,a4,a5
    80000502:	02d00793          	li	a5,45
    80000506:	fef70823          	sb	a5,-16(a4)
    8000050a:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    8000050e:	02e05763          	blez	a4,8000053c <printint+0x8e>
    80000512:	fd040793          	addi	a5,s0,-48
    80000516:	00e784b3          	add	s1,a5,a4
    8000051a:	fff78913          	addi	s2,a5,-1
    8000051e:	993a                	add	s2,s2,a4
    80000520:	377d                	addiw	a4,a4,-1
    80000522:	1702                	slli	a4,a4,0x20
    80000524:	9301                	srli	a4,a4,0x20
    80000526:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000052a:	fff4c503          	lbu	a0,-1(s1)
    8000052e:	00000097          	auipc	ra,0x0
    80000532:	d60080e7          	jalr	-672(ra) # 8000028e <consputc>
  while(--i >= 0)
    80000536:	14fd                	addi	s1,s1,-1
    80000538:	ff2499e3          	bne	s1,s2,8000052a <printint+0x7c>
}
    8000053c:	70a2                	ld	ra,40(sp)
    8000053e:	7402                	ld	s0,32(sp)
    80000540:	64e2                	ld	s1,24(sp)
    80000542:	6942                	ld	s2,16(sp)
    80000544:	6145                	addi	sp,sp,48
    80000546:	8082                	ret
    x = -xx;
    80000548:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000054c:	4885                	li	a7,1
    x = -xx;
    8000054e:	bf9d                	j	800004c4 <printint+0x16>

0000000080000550 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000550:	1101                	addi	sp,sp,-32
    80000552:	ec06                	sd	ra,24(sp)
    80000554:	e822                	sd	s0,16(sp)
    80000556:	e426                	sd	s1,8(sp)
    80000558:	1000                	addi	s0,sp,32
    8000055a:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000055c:	00011797          	auipc	a5,0x11
    80000560:	ce07a223          	sw	zero,-796(a5) # 80011240 <pr+0x20>
  printf("panic: ");
    80000564:	00008517          	auipc	a0,0x8
    80000568:	ab450513          	addi	a0,a0,-1356 # 80008018 <etext+0x18>
    8000056c:	00000097          	auipc	ra,0x0
    80000570:	02e080e7          	jalr	46(ra) # 8000059a <printf>
  printf(s);
    80000574:	8526                	mv	a0,s1
    80000576:	00000097          	auipc	ra,0x0
    8000057a:	024080e7          	jalr	36(ra) # 8000059a <printf>
  printf("\n");
    8000057e:	00008517          	auipc	a0,0x8
    80000582:	be250513          	addi	a0,a0,-1054 # 80008160 <digits+0x120>
    80000586:	00000097          	auipc	ra,0x0
    8000058a:	014080e7          	jalr	20(ra) # 8000059a <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000058e:	4785                	li	a5,1
    80000590:	00009717          	auipc	a4,0x9
    80000594:	a6f72823          	sw	a5,-1424(a4) # 80009000 <panicked>
  for(;;)
    80000598:	a001                	j	80000598 <panic+0x48>

000000008000059a <printf>:
{
    8000059a:	7131                	addi	sp,sp,-192
    8000059c:	fc86                	sd	ra,120(sp)
    8000059e:	f8a2                	sd	s0,112(sp)
    800005a0:	f4a6                	sd	s1,104(sp)
    800005a2:	f0ca                	sd	s2,96(sp)
    800005a4:	ecce                	sd	s3,88(sp)
    800005a6:	e8d2                	sd	s4,80(sp)
    800005a8:	e4d6                	sd	s5,72(sp)
    800005aa:	e0da                	sd	s6,64(sp)
    800005ac:	fc5e                	sd	s7,56(sp)
    800005ae:	f862                	sd	s8,48(sp)
    800005b0:	f466                	sd	s9,40(sp)
    800005b2:	f06a                	sd	s10,32(sp)
    800005b4:	ec6e                	sd	s11,24(sp)
    800005b6:	0100                	addi	s0,sp,128
    800005b8:	8a2a                	mv	s4,a0
    800005ba:	e40c                	sd	a1,8(s0)
    800005bc:	e810                	sd	a2,16(s0)
    800005be:	ec14                	sd	a3,24(s0)
    800005c0:	f018                	sd	a4,32(s0)
    800005c2:	f41c                	sd	a5,40(s0)
    800005c4:	03043823          	sd	a6,48(s0)
    800005c8:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005cc:	00011d97          	auipc	s11,0x11
    800005d0:	c74dad83          	lw	s11,-908(s11) # 80011240 <pr+0x20>
  if(locking)
    800005d4:	020d9b63          	bnez	s11,8000060a <printf+0x70>
  if (fmt == 0)
    800005d8:	040a0263          	beqz	s4,8000061c <printf+0x82>
  va_start(ap, fmt);
    800005dc:	00840793          	addi	a5,s0,8
    800005e0:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005e4:	000a4503          	lbu	a0,0(s4)
    800005e8:	16050263          	beqz	a0,8000074c <printf+0x1b2>
    800005ec:	4481                	li	s1,0
    if(c != '%'){
    800005ee:	02500a93          	li	s5,37
    switch(c){
    800005f2:	07000b13          	li	s6,112
  consputc('x');
    800005f6:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005f8:	00008b97          	auipc	s7,0x8
    800005fc:	a48b8b93          	addi	s7,s7,-1464 # 80008040 <digits>
    switch(c){
    80000600:	07300c93          	li	s9,115
    80000604:	06400c13          	li	s8,100
    80000608:	a82d                	j	80000642 <printf+0xa8>
    acquire(&pr.lock);
    8000060a:	00011517          	auipc	a0,0x11
    8000060e:	c1650513          	addi	a0,a0,-1002 # 80011220 <pr>
    80000612:	00000097          	auipc	ra,0x0
    80000616:	6e6080e7          	jalr	1766(ra) # 80000cf8 <acquire>
    8000061a:	bf7d                	j	800005d8 <printf+0x3e>
    panic("null fmt");
    8000061c:	00008517          	auipc	a0,0x8
    80000620:	a0c50513          	addi	a0,a0,-1524 # 80008028 <etext+0x28>
    80000624:	00000097          	auipc	ra,0x0
    80000628:	f2c080e7          	jalr	-212(ra) # 80000550 <panic>
      consputc(c);
    8000062c:	00000097          	auipc	ra,0x0
    80000630:	c62080e7          	jalr	-926(ra) # 8000028e <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000634:	2485                	addiw	s1,s1,1
    80000636:	009a07b3          	add	a5,s4,s1
    8000063a:	0007c503          	lbu	a0,0(a5)
    8000063e:	10050763          	beqz	a0,8000074c <printf+0x1b2>
    if(c != '%'){
    80000642:	ff5515e3          	bne	a0,s5,8000062c <printf+0x92>
    c = fmt[++i] & 0xff;
    80000646:	2485                	addiw	s1,s1,1
    80000648:	009a07b3          	add	a5,s4,s1
    8000064c:	0007c783          	lbu	a5,0(a5)
    80000650:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000654:	cfe5                	beqz	a5,8000074c <printf+0x1b2>
    switch(c){
    80000656:	05678a63          	beq	a5,s6,800006aa <printf+0x110>
    8000065a:	02fb7663          	bgeu	s6,a5,80000686 <printf+0xec>
    8000065e:	09978963          	beq	a5,s9,800006f0 <printf+0x156>
    80000662:	07800713          	li	a4,120
    80000666:	0ce79863          	bne	a5,a4,80000736 <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    8000066a:	f8843783          	ld	a5,-120(s0)
    8000066e:	00878713          	addi	a4,a5,8
    80000672:	f8e43423          	sd	a4,-120(s0)
    80000676:	4605                	li	a2,1
    80000678:	85ea                	mv	a1,s10
    8000067a:	4388                	lw	a0,0(a5)
    8000067c:	00000097          	auipc	ra,0x0
    80000680:	e32080e7          	jalr	-462(ra) # 800004ae <printint>
      break;
    80000684:	bf45                	j	80000634 <printf+0x9a>
    switch(c){
    80000686:	0b578263          	beq	a5,s5,8000072a <printf+0x190>
    8000068a:	0b879663          	bne	a5,s8,80000736 <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    8000068e:	f8843783          	ld	a5,-120(s0)
    80000692:	00878713          	addi	a4,a5,8
    80000696:	f8e43423          	sd	a4,-120(s0)
    8000069a:	4605                	li	a2,1
    8000069c:	45a9                	li	a1,10
    8000069e:	4388                	lw	a0,0(a5)
    800006a0:	00000097          	auipc	ra,0x0
    800006a4:	e0e080e7          	jalr	-498(ra) # 800004ae <printint>
      break;
    800006a8:	b771                	j	80000634 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    800006aa:	f8843783          	ld	a5,-120(s0)
    800006ae:	00878713          	addi	a4,a5,8
    800006b2:	f8e43423          	sd	a4,-120(s0)
    800006b6:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006ba:	03000513          	li	a0,48
    800006be:	00000097          	auipc	ra,0x0
    800006c2:	bd0080e7          	jalr	-1072(ra) # 8000028e <consputc>
  consputc('x');
    800006c6:	07800513          	li	a0,120
    800006ca:	00000097          	auipc	ra,0x0
    800006ce:	bc4080e7          	jalr	-1084(ra) # 8000028e <consputc>
    800006d2:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006d4:	03c9d793          	srli	a5,s3,0x3c
    800006d8:	97de                	add	a5,a5,s7
    800006da:	0007c503          	lbu	a0,0(a5)
    800006de:	00000097          	auipc	ra,0x0
    800006e2:	bb0080e7          	jalr	-1104(ra) # 8000028e <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006e6:	0992                	slli	s3,s3,0x4
    800006e8:	397d                	addiw	s2,s2,-1
    800006ea:	fe0915e3          	bnez	s2,800006d4 <printf+0x13a>
    800006ee:	b799                	j	80000634 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006f0:	f8843783          	ld	a5,-120(s0)
    800006f4:	00878713          	addi	a4,a5,8
    800006f8:	f8e43423          	sd	a4,-120(s0)
    800006fc:	0007b903          	ld	s2,0(a5)
    80000700:	00090e63          	beqz	s2,8000071c <printf+0x182>
      for(; *s; s++)
    80000704:	00094503          	lbu	a0,0(s2)
    80000708:	d515                	beqz	a0,80000634 <printf+0x9a>
        consputc(*s);
    8000070a:	00000097          	auipc	ra,0x0
    8000070e:	b84080e7          	jalr	-1148(ra) # 8000028e <consputc>
      for(; *s; s++)
    80000712:	0905                	addi	s2,s2,1
    80000714:	00094503          	lbu	a0,0(s2)
    80000718:	f96d                	bnez	a0,8000070a <printf+0x170>
    8000071a:	bf29                	j	80000634 <printf+0x9a>
        s = "(null)";
    8000071c:	00008917          	auipc	s2,0x8
    80000720:	90490913          	addi	s2,s2,-1788 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000724:	02800513          	li	a0,40
    80000728:	b7cd                	j	8000070a <printf+0x170>
      consputc('%');
    8000072a:	8556                	mv	a0,s5
    8000072c:	00000097          	auipc	ra,0x0
    80000730:	b62080e7          	jalr	-1182(ra) # 8000028e <consputc>
      break;
    80000734:	b701                	j	80000634 <printf+0x9a>
      consputc('%');
    80000736:	8556                	mv	a0,s5
    80000738:	00000097          	auipc	ra,0x0
    8000073c:	b56080e7          	jalr	-1194(ra) # 8000028e <consputc>
      consputc(c);
    80000740:	854a                	mv	a0,s2
    80000742:	00000097          	auipc	ra,0x0
    80000746:	b4c080e7          	jalr	-1204(ra) # 8000028e <consputc>
      break;
    8000074a:	b5ed                	j	80000634 <printf+0x9a>
  if(locking)
    8000074c:	020d9163          	bnez	s11,8000076e <printf+0x1d4>
}
    80000750:	70e6                	ld	ra,120(sp)
    80000752:	7446                	ld	s0,112(sp)
    80000754:	74a6                	ld	s1,104(sp)
    80000756:	7906                	ld	s2,96(sp)
    80000758:	69e6                	ld	s3,88(sp)
    8000075a:	6a46                	ld	s4,80(sp)
    8000075c:	6aa6                	ld	s5,72(sp)
    8000075e:	6b06                	ld	s6,64(sp)
    80000760:	7be2                	ld	s7,56(sp)
    80000762:	7c42                	ld	s8,48(sp)
    80000764:	7ca2                	ld	s9,40(sp)
    80000766:	7d02                	ld	s10,32(sp)
    80000768:	6de2                	ld	s11,24(sp)
    8000076a:	6129                	addi	sp,sp,192
    8000076c:	8082                	ret
    release(&pr.lock);
    8000076e:	00011517          	auipc	a0,0x11
    80000772:	ab250513          	addi	a0,a0,-1358 # 80011220 <pr>
    80000776:	00000097          	auipc	ra,0x0
    8000077a:	652080e7          	jalr	1618(ra) # 80000dc8 <release>
}
    8000077e:	bfc9                	j	80000750 <printf+0x1b6>

0000000080000780 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000780:	1101                	addi	sp,sp,-32
    80000782:	ec06                	sd	ra,24(sp)
    80000784:	e822                	sd	s0,16(sp)
    80000786:	e426                	sd	s1,8(sp)
    80000788:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    8000078a:	00011497          	auipc	s1,0x11
    8000078e:	a9648493          	addi	s1,s1,-1386 # 80011220 <pr>
    80000792:	00008597          	auipc	a1,0x8
    80000796:	8a658593          	addi	a1,a1,-1882 # 80008038 <etext+0x38>
    8000079a:	8526                	mv	a0,s1
    8000079c:	00000097          	auipc	ra,0x0
    800007a0:	6d8080e7          	jalr	1752(ra) # 80000e74 <initlock>
  pr.locking = 1;
    800007a4:	4785                	li	a5,1
    800007a6:	d09c                	sw	a5,32(s1)
}
    800007a8:	60e2                	ld	ra,24(sp)
    800007aa:	6442                	ld	s0,16(sp)
    800007ac:	64a2                	ld	s1,8(sp)
    800007ae:	6105                	addi	sp,sp,32
    800007b0:	8082                	ret

00000000800007b2 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007b2:	1141                	addi	sp,sp,-16
    800007b4:	e406                	sd	ra,8(sp)
    800007b6:	e022                	sd	s0,0(sp)
    800007b8:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007ba:	100007b7          	lui	a5,0x10000
    800007be:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007c2:	f8000713          	li	a4,-128
    800007c6:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007ca:	470d                	li	a4,3
    800007cc:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007d0:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007d4:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007d8:	469d                	li	a3,7
    800007da:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007de:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007e2:	00008597          	auipc	a1,0x8
    800007e6:	87658593          	addi	a1,a1,-1930 # 80008058 <digits+0x18>
    800007ea:	00011517          	auipc	a0,0x11
    800007ee:	a5e50513          	addi	a0,a0,-1442 # 80011248 <uart_tx_lock>
    800007f2:	00000097          	auipc	ra,0x0
    800007f6:	682080e7          	jalr	1666(ra) # 80000e74 <initlock>
}
    800007fa:	60a2                	ld	ra,8(sp)
    800007fc:	6402                	ld	s0,0(sp)
    800007fe:	0141                	addi	sp,sp,16
    80000800:	8082                	ret

0000000080000802 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    80000802:	1101                	addi	sp,sp,-32
    80000804:	ec06                	sd	ra,24(sp)
    80000806:	e822                	sd	s0,16(sp)
    80000808:	e426                	sd	s1,8(sp)
    8000080a:	1000                	addi	s0,sp,32
    8000080c:	84aa                	mv	s1,a0
  push_off();
    8000080e:	00000097          	auipc	ra,0x0
    80000812:	49e080e7          	jalr	1182(ra) # 80000cac <push_off>

  if(panicked){
    80000816:	00008797          	auipc	a5,0x8
    8000081a:	7ea7a783          	lw	a5,2026(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000081e:	10000737          	lui	a4,0x10000
  if(panicked){
    80000822:	c391                	beqz	a5,80000826 <uartputc_sync+0x24>
    for(;;)
    80000824:	a001                	j	80000824 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000826:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    8000082a:	0ff7f793          	andi	a5,a5,255
    8000082e:	0207f793          	andi	a5,a5,32
    80000832:	dbf5                	beqz	a5,80000826 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000834:	0ff4f793          	andi	a5,s1,255
    80000838:	10000737          	lui	a4,0x10000
    8000083c:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    80000840:	00000097          	auipc	ra,0x0
    80000844:	528080e7          	jalr	1320(ra) # 80000d68 <pop_off>
}
    80000848:	60e2                	ld	ra,24(sp)
    8000084a:	6442                	ld	s0,16(sp)
    8000084c:	64a2                	ld	s1,8(sp)
    8000084e:	6105                	addi	sp,sp,32
    80000850:	8082                	ret

0000000080000852 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000852:	00008797          	auipc	a5,0x8
    80000856:	7b27a783          	lw	a5,1970(a5) # 80009004 <uart_tx_r>
    8000085a:	00008717          	auipc	a4,0x8
    8000085e:	7ae72703          	lw	a4,1966(a4) # 80009008 <uart_tx_w>
    80000862:	08f70263          	beq	a4,a5,800008e6 <uartstart+0x94>
{
    80000866:	7139                	addi	sp,sp,-64
    80000868:	fc06                	sd	ra,56(sp)
    8000086a:	f822                	sd	s0,48(sp)
    8000086c:	f426                	sd	s1,40(sp)
    8000086e:	f04a                	sd	s2,32(sp)
    80000870:	ec4e                	sd	s3,24(sp)
    80000872:	e852                	sd	s4,16(sp)
    80000874:	e456                	sd	s5,8(sp)
    80000876:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000878:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r];
    8000087c:	00011a17          	auipc	s4,0x11
    80000880:	9cca0a13          	addi	s4,s4,-1588 # 80011248 <uart_tx_lock>
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    80000884:	00008497          	auipc	s1,0x8
    80000888:	78048493          	addi	s1,s1,1920 # 80009004 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000088c:	00008997          	auipc	s3,0x8
    80000890:	77c98993          	addi	s3,s3,1916 # 80009008 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000894:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000898:	0ff77713          	andi	a4,a4,255
    8000089c:	02077713          	andi	a4,a4,32
    800008a0:	cb15                	beqz	a4,800008d4 <uartstart+0x82>
    int c = uart_tx_buf[uart_tx_r];
    800008a2:	00fa0733          	add	a4,s4,a5
    800008a6:	02074a83          	lbu	s5,32(a4)
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    800008aa:	2785                	addiw	a5,a5,1
    800008ac:	41f7d71b          	sraiw	a4,a5,0x1f
    800008b0:	01b7571b          	srliw	a4,a4,0x1b
    800008b4:	9fb9                	addw	a5,a5,a4
    800008b6:	8bfd                	andi	a5,a5,31
    800008b8:	9f99                	subw	a5,a5,a4
    800008ba:	c09c                	sw	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    800008bc:	8526                	mv	a0,s1
    800008be:	00002097          	auipc	ra,0x2
    800008c2:	e18080e7          	jalr	-488(ra) # 800026d6 <wakeup>
    
    WriteReg(THR, c);
    800008c6:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008ca:	409c                	lw	a5,0(s1)
    800008cc:	0009a703          	lw	a4,0(s3)
    800008d0:	fcf712e3          	bne	a4,a5,80000894 <uartstart+0x42>
  }
}
    800008d4:	70e2                	ld	ra,56(sp)
    800008d6:	7442                	ld	s0,48(sp)
    800008d8:	74a2                	ld	s1,40(sp)
    800008da:	7902                	ld	s2,32(sp)
    800008dc:	69e2                	ld	s3,24(sp)
    800008de:	6a42                	ld	s4,16(sp)
    800008e0:	6aa2                	ld	s5,8(sp)
    800008e2:	6121                	addi	sp,sp,64
    800008e4:	8082                	ret
    800008e6:	8082                	ret

00000000800008e8 <uartputc>:
{
    800008e8:	7179                	addi	sp,sp,-48
    800008ea:	f406                	sd	ra,40(sp)
    800008ec:	f022                	sd	s0,32(sp)
    800008ee:	ec26                	sd	s1,24(sp)
    800008f0:	e84a                	sd	s2,16(sp)
    800008f2:	e44e                	sd	s3,8(sp)
    800008f4:	e052                	sd	s4,0(sp)
    800008f6:	1800                	addi	s0,sp,48
    800008f8:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008fa:	00011517          	auipc	a0,0x11
    800008fe:	94e50513          	addi	a0,a0,-1714 # 80011248 <uart_tx_lock>
    80000902:	00000097          	auipc	ra,0x0
    80000906:	3f6080e7          	jalr	1014(ra) # 80000cf8 <acquire>
  if(panicked){
    8000090a:	00008797          	auipc	a5,0x8
    8000090e:	6f67a783          	lw	a5,1782(a5) # 80009000 <panicked>
    80000912:	c391                	beqz	a5,80000916 <uartputc+0x2e>
    for(;;)
    80000914:	a001                	j	80000914 <uartputc+0x2c>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000916:	00008717          	auipc	a4,0x8
    8000091a:	6f272703          	lw	a4,1778(a4) # 80009008 <uart_tx_w>
    8000091e:	0017079b          	addiw	a5,a4,1
    80000922:	41f7d69b          	sraiw	a3,a5,0x1f
    80000926:	01b6d69b          	srliw	a3,a3,0x1b
    8000092a:	9fb5                	addw	a5,a5,a3
    8000092c:	8bfd                	andi	a5,a5,31
    8000092e:	9f95                	subw	a5,a5,a3
    80000930:	00008697          	auipc	a3,0x8
    80000934:	6d46a683          	lw	a3,1748(a3) # 80009004 <uart_tx_r>
    80000938:	04f69263          	bne	a3,a5,8000097c <uartputc+0x94>
      sleep(&uart_tx_r, &uart_tx_lock);
    8000093c:	00011a17          	auipc	s4,0x11
    80000940:	90ca0a13          	addi	s4,s4,-1780 # 80011248 <uart_tx_lock>
    80000944:	00008497          	auipc	s1,0x8
    80000948:	6c048493          	addi	s1,s1,1728 # 80009004 <uart_tx_r>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    8000094c:	00008917          	auipc	s2,0x8
    80000950:	6bc90913          	addi	s2,s2,1724 # 80009008 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000954:	85d2                	mv	a1,s4
    80000956:	8526                	mv	a0,s1
    80000958:	00002097          	auipc	ra,0x2
    8000095c:	bf8080e7          	jalr	-1032(ra) # 80002550 <sleep>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000960:	00092703          	lw	a4,0(s2)
    80000964:	0017079b          	addiw	a5,a4,1
    80000968:	41f7d69b          	sraiw	a3,a5,0x1f
    8000096c:	01b6d69b          	srliw	a3,a3,0x1b
    80000970:	9fb5                	addw	a5,a5,a3
    80000972:	8bfd                	andi	a5,a5,31
    80000974:	9f95                	subw	a5,a5,a3
    80000976:	4094                	lw	a3,0(s1)
    80000978:	fcf68ee3          	beq	a3,a5,80000954 <uartputc+0x6c>
      uart_tx_buf[uart_tx_w] = c;
    8000097c:	00011497          	auipc	s1,0x11
    80000980:	8cc48493          	addi	s1,s1,-1844 # 80011248 <uart_tx_lock>
    80000984:	9726                	add	a4,a4,s1
    80000986:	03370023          	sb	s3,32(a4)
      uart_tx_w = (uart_tx_w + 1) % UART_TX_BUF_SIZE;
    8000098a:	00008717          	auipc	a4,0x8
    8000098e:	66f72f23          	sw	a5,1662(a4) # 80009008 <uart_tx_w>
      uartstart();
    80000992:	00000097          	auipc	ra,0x0
    80000996:	ec0080e7          	jalr	-320(ra) # 80000852 <uartstart>
      release(&uart_tx_lock);
    8000099a:	8526                	mv	a0,s1
    8000099c:	00000097          	auipc	ra,0x0
    800009a0:	42c080e7          	jalr	1068(ra) # 80000dc8 <release>
}
    800009a4:	70a2                	ld	ra,40(sp)
    800009a6:	7402                	ld	s0,32(sp)
    800009a8:	64e2                	ld	s1,24(sp)
    800009aa:	6942                	ld	s2,16(sp)
    800009ac:	69a2                	ld	s3,8(sp)
    800009ae:	6a02                	ld	s4,0(sp)
    800009b0:	6145                	addi	sp,sp,48
    800009b2:	8082                	ret

00000000800009b4 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    800009b4:	1141                	addi	sp,sp,-16
    800009b6:	e422                	sd	s0,8(sp)
    800009b8:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    800009ba:	100007b7          	lui	a5,0x10000
    800009be:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    800009c2:	8b85                	andi	a5,a5,1
    800009c4:	cb91                	beqz	a5,800009d8 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    800009c6:	100007b7          	lui	a5,0x10000
    800009ca:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    800009ce:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    800009d2:	6422                	ld	s0,8(sp)
    800009d4:	0141                	addi	sp,sp,16
    800009d6:	8082                	ret
    return -1;
    800009d8:	557d                	li	a0,-1
    800009da:	bfe5                	j	800009d2 <uartgetc+0x1e>

00000000800009dc <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009dc:	1101                	addi	sp,sp,-32
    800009de:	ec06                	sd	ra,24(sp)
    800009e0:	e822                	sd	s0,16(sp)
    800009e2:	e426                	sd	s1,8(sp)
    800009e4:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009e6:	54fd                	li	s1,-1
    int c = uartgetc();
    800009e8:	00000097          	auipc	ra,0x0
    800009ec:	fcc080e7          	jalr	-52(ra) # 800009b4 <uartgetc>
    if(c == -1)
    800009f0:	00950763          	beq	a0,s1,800009fe <uartintr+0x22>
      break;
    consoleintr(c);
    800009f4:	00000097          	auipc	ra,0x0
    800009f8:	8dc080e7          	jalr	-1828(ra) # 800002d0 <consoleintr>
  while(1){
    800009fc:	b7f5                	j	800009e8 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009fe:	00011497          	auipc	s1,0x11
    80000a02:	84a48493          	addi	s1,s1,-1974 # 80011248 <uart_tx_lock>
    80000a06:	8526                	mv	a0,s1
    80000a08:	00000097          	auipc	ra,0x0
    80000a0c:	2f0080e7          	jalr	752(ra) # 80000cf8 <acquire>
  uartstart();
    80000a10:	00000097          	auipc	ra,0x0
    80000a14:	e42080e7          	jalr	-446(ra) # 80000852 <uartstart>
  release(&uart_tx_lock);
    80000a18:	8526                	mv	a0,s1
    80000a1a:	00000097          	auipc	ra,0x0
    80000a1e:	3ae080e7          	jalr	942(ra) # 80000dc8 <release>
}
    80000a22:	60e2                	ld	ra,24(sp)
    80000a24:	6442                	ld	s0,16(sp)
    80000a26:	64a2                	ld	s1,8(sp)
    80000a28:	6105                	addi	sp,sp,32
    80000a2a:	8082                	ret

0000000080000a2c <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000a2c:	7139                	addi	sp,sp,-64
    80000a2e:	fc06                	sd	ra,56(sp)
    80000a30:	f822                	sd	s0,48(sp)
    80000a32:	f426                	sd	s1,40(sp)
    80000a34:	f04a                	sd	s2,32(sp)
    80000a36:	ec4e                	sd	s3,24(sp)
    80000a38:	e852                	sd	s4,16(sp)
    80000a3a:	e456                	sd	s5,8(sp)
    80000a3c:	0080                	addi	s0,sp,64
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a3e:	03451793          	slli	a5,a0,0x34
    80000a42:	e3c1                	bnez	a5,80000ac2 <kfree+0x96>
    80000a44:	84aa                	mv	s1,a0
    80000a46:	00027797          	auipc	a5,0x27
    80000a4a:	5e278793          	addi	a5,a5,1506 # 80028028 <end>
    80000a4e:	06f56a63          	bltu	a0,a5,80000ac2 <kfree+0x96>
    80000a52:	47c5                	li	a5,17
    80000a54:	07ee                	slli	a5,a5,0x1b
    80000a56:	06f57663          	bgeu	a0,a5,80000ac2 <kfree+0x96>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a5a:	6605                	lui	a2,0x1
    80000a5c:	4585                	li	a1,1
    80000a5e:	00000097          	auipc	ra,0x0
    80000a62:	67a080e7          	jalr	1658(ra) # 800010d8 <memset>

  r = (struct run*)pa;

  push_off();
    80000a66:	00000097          	auipc	ra,0x0
    80000a6a:	246080e7          	jalr	582(ra) # 80000cac <push_off>
  int cid = cpuid();
    80000a6e:	00001097          	auipc	ra,0x1
    80000a72:	2a6080e7          	jalr	678(ra) # 80001d14 <cpuid>
  acquire(&(kmemcpu[cid].lock));
    80000a76:	00011a97          	auipc	s5,0x11
    80000a7a:	812a8a93          	addi	s5,s5,-2030 # 80011288 <kmemcpu>
    80000a7e:	00251993          	slli	s3,a0,0x2
    80000a82:	00a98933          	add	s2,s3,a0
    80000a86:	090e                	slli	s2,s2,0x3
    80000a88:	9956                	add	s2,s2,s5
    80000a8a:	854a                	mv	a0,s2
    80000a8c:	00000097          	auipc	ra,0x0
    80000a90:	26c080e7          	jalr	620(ra) # 80000cf8 <acquire>
  r->next = kmemcpu[cid].freelist;
    80000a94:	02093783          	ld	a5,32(s2)
    80000a98:	e09c                	sd	a5,0(s1)
  kmemcpu[cid].freelist = r;
    80000a9a:	02993023          	sd	s1,32(s2)
  release(&(kmemcpu[cid].lock));
    80000a9e:	854a                	mv	a0,s2
    80000aa0:	00000097          	auipc	ra,0x0
    80000aa4:	328080e7          	jalr	808(ra) # 80000dc8 <release>
  pop_off();
    80000aa8:	00000097          	auipc	ra,0x0
    80000aac:	2c0080e7          	jalr	704(ra) # 80000d68 <pop_off>
}
    80000ab0:	70e2                	ld	ra,56(sp)
    80000ab2:	7442                	ld	s0,48(sp)
    80000ab4:	74a2                	ld	s1,40(sp)
    80000ab6:	7902                	ld	s2,32(sp)
    80000ab8:	69e2                	ld	s3,24(sp)
    80000aba:	6a42                	ld	s4,16(sp)
    80000abc:	6aa2                	ld	s5,8(sp)
    80000abe:	6121                	addi	sp,sp,64
    80000ac0:	8082                	ret
    panic("kfree");
    80000ac2:	00007517          	auipc	a0,0x7
    80000ac6:	59e50513          	addi	a0,a0,1438 # 80008060 <digits+0x20>
    80000aca:	00000097          	auipc	ra,0x0
    80000ace:	a86080e7          	jalr	-1402(ra) # 80000550 <panic>

0000000080000ad2 <freerange>:
{
    80000ad2:	7179                	addi	sp,sp,-48
    80000ad4:	f406                	sd	ra,40(sp)
    80000ad6:	f022                	sd	s0,32(sp)
    80000ad8:	ec26                	sd	s1,24(sp)
    80000ada:	e84a                	sd	s2,16(sp)
    80000adc:	e44e                	sd	s3,8(sp)
    80000ade:	e052                	sd	s4,0(sp)
    80000ae0:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000ae2:	6785                	lui	a5,0x1
    80000ae4:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000ae8:	94aa                	add	s1,s1,a0
    80000aea:	757d                	lui	a0,0xfffff
    80000aec:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aee:	94be                	add	s1,s1,a5
    80000af0:	0095ee63          	bltu	a1,s1,80000b0c <freerange+0x3a>
    80000af4:	892e                	mv	s2,a1
    kfree(p);
    80000af6:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000af8:	6985                	lui	s3,0x1
    kfree(p);
    80000afa:	01448533          	add	a0,s1,s4
    80000afe:	00000097          	auipc	ra,0x0
    80000b02:	f2e080e7          	jalr	-210(ra) # 80000a2c <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000b06:	94ce                	add	s1,s1,s3
    80000b08:	fe9979e3          	bgeu	s2,s1,80000afa <freerange+0x28>
}
    80000b0c:	70a2                	ld	ra,40(sp)
    80000b0e:	7402                	ld	s0,32(sp)
    80000b10:	64e2                	ld	s1,24(sp)
    80000b12:	6942                	ld	s2,16(sp)
    80000b14:	69a2                	ld	s3,8(sp)
    80000b16:	6a02                	ld	s4,0(sp)
    80000b18:	6145                	addi	sp,sp,48
    80000b1a:	8082                	ret

0000000080000b1c <kinit>:
{
    80000b1c:	7179                	addi	sp,sp,-48
    80000b1e:	f406                	sd	ra,40(sp)
    80000b20:	f022                	sd	s0,32(sp)
    80000b22:	ec26                	sd	s1,24(sp)
    80000b24:	e84a                	sd	s2,16(sp)
    80000b26:	e44e                	sd	s3,8(sp)
    80000b28:	1800                	addi	s0,sp,48
  for(int i = 0; i < NCPU; i++)
    80000b2a:	00010497          	auipc	s1,0x10
    80000b2e:	75e48493          	addi	s1,s1,1886 # 80011288 <kmemcpu>
    80000b32:	00011997          	auipc	s3,0x11
    80000b36:	89698993          	addi	s3,s3,-1898 # 800113c8 <lock_locks>
    initlock(&(kmemcpu[i].lock), "kmem");
    80000b3a:	00007917          	auipc	s2,0x7
    80000b3e:	52e90913          	addi	s2,s2,1326 # 80008068 <digits+0x28>
    80000b42:	85ca                	mv	a1,s2
    80000b44:	8526                	mv	a0,s1
    80000b46:	00000097          	auipc	ra,0x0
    80000b4a:	32e080e7          	jalr	814(ra) # 80000e74 <initlock>
  for(int i = 0; i < NCPU; i++)
    80000b4e:	02848493          	addi	s1,s1,40
    80000b52:	ff3498e3          	bne	s1,s3,80000b42 <kinit+0x26>
  freerange(end, (void*)PHYSTOP);
    80000b56:	45c5                	li	a1,17
    80000b58:	05ee                	slli	a1,a1,0x1b
    80000b5a:	00027517          	auipc	a0,0x27
    80000b5e:	4ce50513          	addi	a0,a0,1230 # 80028028 <end>
    80000b62:	00000097          	auipc	ra,0x0
    80000b66:	f70080e7          	jalr	-144(ra) # 80000ad2 <freerange>
}
    80000b6a:	70a2                	ld	ra,40(sp)
    80000b6c:	7402                	ld	s0,32(sp)
    80000b6e:	64e2                	ld	s1,24(sp)
    80000b70:	6942                	ld	s2,16(sp)
    80000b72:	69a2                	ld	s3,8(sp)
    80000b74:	6145                	addi	sp,sp,48
    80000b76:	8082                	ret

0000000080000b78 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b78:	7139                	addi	sp,sp,-64
    80000b7a:	fc06                	sd	ra,56(sp)
    80000b7c:	f822                	sd	s0,48(sp)
    80000b7e:	f426                	sd	s1,40(sp)
    80000b80:	f04a                	sd	s2,32(sp)
    80000b82:	ec4e                	sd	s3,24(sp)
    80000b84:	e852                	sd	s4,16(sp)
    80000b86:	e456                	sd	s5,8(sp)
    80000b88:	e05a                	sd	s6,0(sp)
    80000b8a:	0080                	addi	s0,sp,64
  struct run *r;

  push_off();
    80000b8c:	00000097          	auipc	ra,0x0
    80000b90:	120080e7          	jalr	288(ra) # 80000cac <push_off>
  int cid = cpuid();
    80000b94:	00001097          	auipc	ra,0x1
    80000b98:	180080e7          	jalr	384(ra) # 80001d14 <cpuid>
    80000b9c:	84aa                	mv	s1,a0
  acquire(&(kmemcpu[cid].lock));
    80000b9e:	00251913          	slli	s2,a0,0x2
    80000ba2:	992a                	add	s2,s2,a0
    80000ba4:	00391793          	slli	a5,s2,0x3
    80000ba8:	00010917          	auipc	s2,0x10
    80000bac:	6e090913          	addi	s2,s2,1760 # 80011288 <kmemcpu>
    80000bb0:	993e                	add	s2,s2,a5
    80000bb2:	854a                	mv	a0,s2
    80000bb4:	00000097          	auipc	ra,0x0
    80000bb8:	144080e7          	jalr	324(ra) # 80000cf8 <acquire>
  r = kmemcpu[cid].freelist;
    80000bbc:	02093983          	ld	s3,32(s2)
  int i = cid + 1;
  if(r){
    80000bc0:	04098163          	beqz	s3,80000c02 <kalloc+0x8a>
    kmemcpu[cid].freelist = r->next;
    80000bc4:	0009b703          	ld	a4,0(s3)
    80000bc8:	02e93023          	sd	a4,32(s2)
        release(&(kmemcpu[i].lock));
        break;
      }
    }
  }
  release(&(kmemcpu[cid].lock));
    80000bcc:	854a                	mv	a0,s2
    80000bce:	00000097          	auipc	ra,0x0
    80000bd2:	1fa080e7          	jalr	506(ra) # 80000dc8 <release>
  pop_off();
    80000bd6:	00000097          	auipc	ra,0x0
    80000bda:	192080e7          	jalr	402(ra) # 80000d68 <pop_off>
  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000bde:	6605                	lui	a2,0x1
    80000be0:	4595                	li	a1,5
    80000be2:	854e                	mv	a0,s3
    80000be4:	00000097          	auipc	ra,0x0
    80000be8:	4f4080e7          	jalr	1268(ra) # 800010d8 <memset>
  return (void*)r;
}
    80000bec:	854e                	mv	a0,s3
    80000bee:	70e2                	ld	ra,56(sp)
    80000bf0:	7442                	ld	s0,48(sp)
    80000bf2:	74a2                	ld	s1,40(sp)
    80000bf4:	7902                	ld	s2,32(sp)
    80000bf6:	69e2                	ld	s3,24(sp)
    80000bf8:	6a42                	ld	s4,16(sp)
    80000bfa:	6aa2                	ld	s5,8(sp)
    80000bfc:	6b02                	ld	s6,0(sp)
    80000bfe:	6121                	addi	sp,sp,64
    80000c00:	8082                	ret
  int i = cid + 1;
    80000c02:	2485                	addiw	s1,s1,1
    80000c04:	471d                	li	a4,7
      if(kmemcpu[i].freelist){
    80000c06:	00010697          	auipc	a3,0x10
    80000c0a:	68268693          	addi	a3,a3,1666 # 80011288 <kmemcpu>
      i = (i+1) % NCPU;
    80000c0e:	2485                	addiw	s1,s1,1
    80000c10:	41f4d51b          	sraiw	a0,s1,0x1f
    80000c14:	01d5551b          	srliw	a0,a0,0x1d
    80000c18:	9ca9                	addw	s1,s1,a0
    80000c1a:	889d                	andi	s1,s1,7
    80000c1c:	9c89                	subw	s1,s1,a0
      if(kmemcpu[i].freelist){
    80000c1e:	00249793          	slli	a5,s1,0x2
    80000c22:	97a6                	add	a5,a5,s1
    80000c24:	078e                	slli	a5,a5,0x3
    80000c26:	97b6                	add	a5,a5,a3
    80000c28:	0207b983          	ld	s3,32(a5)
    80000c2c:	00099e63          	bnez	s3,80000c48 <kalloc+0xd0>
    for(int j = 0; j < NCPU - 1; j++){
    80000c30:	377d                	addiw	a4,a4,-1
    80000c32:	ff71                	bnez	a4,80000c0e <kalloc+0x96>
  release(&(kmemcpu[cid].lock));
    80000c34:	854a                	mv	a0,s2
    80000c36:	00000097          	auipc	ra,0x0
    80000c3a:	192080e7          	jalr	402(ra) # 80000dc8 <release>
  pop_off();
    80000c3e:	00000097          	auipc	ra,0x0
    80000c42:	12a080e7          	jalr	298(ra) # 80000d68 <pop_off>
  if(r)
    80000c46:	b75d                	j	80000bec <kalloc+0x74>
        acquire(&(kmemcpu[i].lock));
    80000c48:	00010b17          	auipc	s6,0x10
    80000c4c:	640b0b13          	addi	s6,s6,1600 # 80011288 <kmemcpu>
    80000c50:	00249a93          	slli	s5,s1,0x2
    80000c54:	009a8a33          	add	s4,s5,s1
    80000c58:	0a0e                	slli	s4,s4,0x3
    80000c5a:	9a5a                	add	s4,s4,s6
    80000c5c:	8552                	mv	a0,s4
    80000c5e:	00000097          	auipc	ra,0x0
    80000c62:	09a080e7          	jalr	154(ra) # 80000cf8 <acquire>
        r = kmemcpu[i].freelist;
    80000c66:	020a3983          	ld	s3,32(s4) # fffffffffffff020 <end+0xffffffff7ffd6ff8>
        kmemcpu[i].freelist = r->next;
    80000c6a:	0009b783          	ld	a5,0(s3)
    80000c6e:	02fa3023          	sd	a5,32(s4)
        release(&(kmemcpu[i].lock));
    80000c72:	8552                	mv	a0,s4
    80000c74:	00000097          	auipc	ra,0x0
    80000c78:	154080e7          	jalr	340(ra) # 80000dc8 <release>
        break;
    80000c7c:	bf81                	j	80000bcc <kalloc+0x54>

0000000080000c7e <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000c7e:	411c                	lw	a5,0(a0)
    80000c80:	e399                	bnez	a5,80000c86 <holding+0x8>
    80000c82:	4501                	li	a0,0
  return r;
}
    80000c84:	8082                	ret
{
    80000c86:	1101                	addi	sp,sp,-32
    80000c88:	ec06                	sd	ra,24(sp)
    80000c8a:	e822                	sd	s0,16(sp)
    80000c8c:	e426                	sd	s1,8(sp)
    80000c8e:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000c90:	6904                	ld	s1,16(a0)
    80000c92:	00001097          	auipc	ra,0x1
    80000c96:	092080e7          	jalr	146(ra) # 80001d24 <mycpu>
    80000c9a:	40a48533          	sub	a0,s1,a0
    80000c9e:	00153513          	seqz	a0,a0
}
    80000ca2:	60e2                	ld	ra,24(sp)
    80000ca4:	6442                	ld	s0,16(sp)
    80000ca6:	64a2                	ld	s1,8(sp)
    80000ca8:	6105                	addi	sp,sp,32
    80000caa:	8082                	ret

0000000080000cac <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000cac:	1101                	addi	sp,sp,-32
    80000cae:	ec06                	sd	ra,24(sp)
    80000cb0:	e822                	sd	s0,16(sp)
    80000cb2:	e426                	sd	s1,8(sp)
    80000cb4:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000cb6:	100024f3          	csrr	s1,sstatus
    80000cba:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000cbe:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000cc0:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000cc4:	00001097          	auipc	ra,0x1
    80000cc8:	060080e7          	jalr	96(ra) # 80001d24 <mycpu>
    80000ccc:	5d3c                	lw	a5,120(a0)
    80000cce:	cf89                	beqz	a5,80000ce8 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000cd0:	00001097          	auipc	ra,0x1
    80000cd4:	054080e7          	jalr	84(ra) # 80001d24 <mycpu>
    80000cd8:	5d3c                	lw	a5,120(a0)
    80000cda:	2785                	addiw	a5,a5,1
    80000cdc:	dd3c                	sw	a5,120(a0)
}
    80000cde:	60e2                	ld	ra,24(sp)
    80000ce0:	6442                	ld	s0,16(sp)
    80000ce2:	64a2                	ld	s1,8(sp)
    80000ce4:	6105                	addi	sp,sp,32
    80000ce6:	8082                	ret
    mycpu()->intena = old;
    80000ce8:	00001097          	auipc	ra,0x1
    80000cec:	03c080e7          	jalr	60(ra) # 80001d24 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000cf0:	8085                	srli	s1,s1,0x1
    80000cf2:	8885                	andi	s1,s1,1
    80000cf4:	dd64                	sw	s1,124(a0)
    80000cf6:	bfe9                	j	80000cd0 <push_off+0x24>

0000000080000cf8 <acquire>:
{
    80000cf8:	1101                	addi	sp,sp,-32
    80000cfa:	ec06                	sd	ra,24(sp)
    80000cfc:	e822                	sd	s0,16(sp)
    80000cfe:	e426                	sd	s1,8(sp)
    80000d00:	1000                	addi	s0,sp,32
    80000d02:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000d04:	00000097          	auipc	ra,0x0
    80000d08:	fa8080e7          	jalr	-88(ra) # 80000cac <push_off>
  if(holding(lk))
    80000d0c:	8526                	mv	a0,s1
    80000d0e:	00000097          	auipc	ra,0x0
    80000d12:	f70080e7          	jalr	-144(ra) # 80000c7e <holding>
    80000d16:	e911                	bnez	a0,80000d2a <acquire+0x32>
    __sync_fetch_and_add(&(lk->n), 1);
    80000d18:	4785                	li	a5,1
    80000d1a:	01c48713          	addi	a4,s1,28
    80000d1e:	0f50000f          	fence	iorw,ow
    80000d22:	04f7202f          	amoadd.w.aq	zero,a5,(a4)
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0) {
    80000d26:	4705                	li	a4,1
    80000d28:	a839                	j	80000d46 <acquire+0x4e>
    panic("acquire");
    80000d2a:	00007517          	auipc	a0,0x7
    80000d2e:	34650513          	addi	a0,a0,838 # 80008070 <digits+0x30>
    80000d32:	00000097          	auipc	ra,0x0
    80000d36:	81e080e7          	jalr	-2018(ra) # 80000550 <panic>
    __sync_fetch_and_add(&(lk->nts), 1);
    80000d3a:	01848793          	addi	a5,s1,24
    80000d3e:	0f50000f          	fence	iorw,ow
    80000d42:	04e7a02f          	amoadd.w.aq	zero,a4,(a5)
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0) {
    80000d46:	87ba                	mv	a5,a4
    80000d48:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000d4c:	2781                	sext.w	a5,a5
    80000d4e:	f7f5                	bnez	a5,80000d3a <acquire+0x42>
  __sync_synchronize();
    80000d50:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000d54:	00001097          	auipc	ra,0x1
    80000d58:	fd0080e7          	jalr	-48(ra) # 80001d24 <mycpu>
    80000d5c:	e888                	sd	a0,16(s1)
}
    80000d5e:	60e2                	ld	ra,24(sp)
    80000d60:	6442                	ld	s0,16(sp)
    80000d62:	64a2                	ld	s1,8(sp)
    80000d64:	6105                	addi	sp,sp,32
    80000d66:	8082                	ret

0000000080000d68 <pop_off>:

void
pop_off(void)
{
    80000d68:	1141                	addi	sp,sp,-16
    80000d6a:	e406                	sd	ra,8(sp)
    80000d6c:	e022                	sd	s0,0(sp)
    80000d6e:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000d70:	00001097          	auipc	ra,0x1
    80000d74:	fb4080e7          	jalr	-76(ra) # 80001d24 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d78:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000d7c:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000d7e:	e78d                	bnez	a5,80000da8 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000d80:	5d3c                	lw	a5,120(a0)
    80000d82:	02f05b63          	blez	a5,80000db8 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000d86:	37fd                	addiw	a5,a5,-1
    80000d88:	0007871b          	sext.w	a4,a5
    80000d8c:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000d8e:	eb09                	bnez	a4,80000da0 <pop_off+0x38>
    80000d90:	5d7c                	lw	a5,124(a0)
    80000d92:	c799                	beqz	a5,80000da0 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d94:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000d98:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000d9c:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000da0:	60a2                	ld	ra,8(sp)
    80000da2:	6402                	ld	s0,0(sp)
    80000da4:	0141                	addi	sp,sp,16
    80000da6:	8082                	ret
    panic("pop_off - interruptible");
    80000da8:	00007517          	auipc	a0,0x7
    80000dac:	2d050513          	addi	a0,a0,720 # 80008078 <digits+0x38>
    80000db0:	fffff097          	auipc	ra,0xfffff
    80000db4:	7a0080e7          	jalr	1952(ra) # 80000550 <panic>
    panic("pop_off");
    80000db8:	00007517          	auipc	a0,0x7
    80000dbc:	2d850513          	addi	a0,a0,728 # 80008090 <digits+0x50>
    80000dc0:	fffff097          	auipc	ra,0xfffff
    80000dc4:	790080e7          	jalr	1936(ra) # 80000550 <panic>

0000000080000dc8 <release>:
{
    80000dc8:	1101                	addi	sp,sp,-32
    80000dca:	ec06                	sd	ra,24(sp)
    80000dcc:	e822                	sd	s0,16(sp)
    80000dce:	e426                	sd	s1,8(sp)
    80000dd0:	1000                	addi	s0,sp,32
    80000dd2:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000dd4:	00000097          	auipc	ra,0x0
    80000dd8:	eaa080e7          	jalr	-342(ra) # 80000c7e <holding>
    80000ddc:	c115                	beqz	a0,80000e00 <release+0x38>
  lk->cpu = 0;
    80000dde:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000de2:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000de6:	0f50000f          	fence	iorw,ow
    80000dea:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000dee:	00000097          	auipc	ra,0x0
    80000df2:	f7a080e7          	jalr	-134(ra) # 80000d68 <pop_off>
}
    80000df6:	60e2                	ld	ra,24(sp)
    80000df8:	6442                	ld	s0,16(sp)
    80000dfa:	64a2                	ld	s1,8(sp)
    80000dfc:	6105                	addi	sp,sp,32
    80000dfe:	8082                	ret
    panic("release");
    80000e00:	00007517          	auipc	a0,0x7
    80000e04:	29850513          	addi	a0,a0,664 # 80008098 <digits+0x58>
    80000e08:	fffff097          	auipc	ra,0xfffff
    80000e0c:	748080e7          	jalr	1864(ra) # 80000550 <panic>

0000000080000e10 <freelock>:
{
    80000e10:	1101                	addi	sp,sp,-32
    80000e12:	ec06                	sd	ra,24(sp)
    80000e14:	e822                	sd	s0,16(sp)
    80000e16:	e426                	sd	s1,8(sp)
    80000e18:	1000                	addi	s0,sp,32
    80000e1a:	84aa                	mv	s1,a0
  acquire(&lock_locks);
    80000e1c:	00010517          	auipc	a0,0x10
    80000e20:	5ac50513          	addi	a0,a0,1452 # 800113c8 <lock_locks>
    80000e24:	00000097          	auipc	ra,0x0
    80000e28:	ed4080e7          	jalr	-300(ra) # 80000cf8 <acquire>
  for (i = 0; i < NLOCK; i++) {
    80000e2c:	00010717          	auipc	a4,0x10
    80000e30:	5bc70713          	addi	a4,a4,1468 # 800113e8 <locks>
    80000e34:	4781                	li	a5,0
    80000e36:	1f400613          	li	a2,500
    if(locks[i] == lk) {
    80000e3a:	6314                	ld	a3,0(a4)
    80000e3c:	00968763          	beq	a3,s1,80000e4a <freelock+0x3a>
  for (i = 0; i < NLOCK; i++) {
    80000e40:	2785                	addiw	a5,a5,1
    80000e42:	0721                	addi	a4,a4,8
    80000e44:	fec79be3          	bne	a5,a2,80000e3a <freelock+0x2a>
    80000e48:	a809                	j	80000e5a <freelock+0x4a>
      locks[i] = 0;
    80000e4a:	078e                	slli	a5,a5,0x3
    80000e4c:	00010717          	auipc	a4,0x10
    80000e50:	59c70713          	addi	a4,a4,1436 # 800113e8 <locks>
    80000e54:	97ba                	add	a5,a5,a4
    80000e56:	0007b023          	sd	zero,0(a5)
  release(&lock_locks);
    80000e5a:	00010517          	auipc	a0,0x10
    80000e5e:	56e50513          	addi	a0,a0,1390 # 800113c8 <lock_locks>
    80000e62:	00000097          	auipc	ra,0x0
    80000e66:	f66080e7          	jalr	-154(ra) # 80000dc8 <release>
}
    80000e6a:	60e2                	ld	ra,24(sp)
    80000e6c:	6442                	ld	s0,16(sp)
    80000e6e:	64a2                	ld	s1,8(sp)
    80000e70:	6105                	addi	sp,sp,32
    80000e72:	8082                	ret

0000000080000e74 <initlock>:
{
    80000e74:	1101                	addi	sp,sp,-32
    80000e76:	ec06                	sd	ra,24(sp)
    80000e78:	e822                	sd	s0,16(sp)
    80000e7a:	e426                	sd	s1,8(sp)
    80000e7c:	1000                	addi	s0,sp,32
    80000e7e:	84aa                	mv	s1,a0
  lk->name = name;
    80000e80:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000e82:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000e86:	00053823          	sd	zero,16(a0)
  lk->nts = 0;
    80000e8a:	00052c23          	sw	zero,24(a0)
  lk->n = 0;
    80000e8e:	00052e23          	sw	zero,28(a0)
  acquire(&lock_locks);
    80000e92:	00010517          	auipc	a0,0x10
    80000e96:	53650513          	addi	a0,a0,1334 # 800113c8 <lock_locks>
    80000e9a:	00000097          	auipc	ra,0x0
    80000e9e:	e5e080e7          	jalr	-418(ra) # 80000cf8 <acquire>
  for (i = 0; i < NLOCK; i++) {
    80000ea2:	00010717          	auipc	a4,0x10
    80000ea6:	54670713          	addi	a4,a4,1350 # 800113e8 <locks>
    80000eaa:	4781                	li	a5,0
    80000eac:	1f400693          	li	a3,500
    if(locks[i] == 0) {
    80000eb0:	6310                	ld	a2,0(a4)
    80000eb2:	ce09                	beqz	a2,80000ecc <initlock+0x58>
  for (i = 0; i < NLOCK; i++) {
    80000eb4:	2785                	addiw	a5,a5,1
    80000eb6:	0721                	addi	a4,a4,8
    80000eb8:	fed79ce3          	bne	a5,a3,80000eb0 <initlock+0x3c>
  panic("findslot");
    80000ebc:	00007517          	auipc	a0,0x7
    80000ec0:	1e450513          	addi	a0,a0,484 # 800080a0 <digits+0x60>
    80000ec4:	fffff097          	auipc	ra,0xfffff
    80000ec8:	68c080e7          	jalr	1676(ra) # 80000550 <panic>
      locks[i] = lk;
    80000ecc:	078e                	slli	a5,a5,0x3
    80000ece:	00010717          	auipc	a4,0x10
    80000ed2:	51a70713          	addi	a4,a4,1306 # 800113e8 <locks>
    80000ed6:	97ba                	add	a5,a5,a4
    80000ed8:	e384                	sd	s1,0(a5)
      release(&lock_locks);
    80000eda:	00010517          	auipc	a0,0x10
    80000ede:	4ee50513          	addi	a0,a0,1262 # 800113c8 <lock_locks>
    80000ee2:	00000097          	auipc	ra,0x0
    80000ee6:	ee6080e7          	jalr	-282(ra) # 80000dc8 <release>
}
    80000eea:	60e2                	ld	ra,24(sp)
    80000eec:	6442                	ld	s0,16(sp)
    80000eee:	64a2                	ld	s1,8(sp)
    80000ef0:	6105                	addi	sp,sp,32
    80000ef2:	8082                	ret

0000000080000ef4 <snprint_lock>:
#ifdef LAB_LOCK
int
snprint_lock(char *buf, int sz, struct spinlock *lk)
{
  int n = 0;
  if(lk->n > 0) {
    80000ef4:	4e5c                	lw	a5,28(a2)
    80000ef6:	00f04463          	bgtz	a5,80000efe <snprint_lock+0xa>
  int n = 0;
    80000efa:	4501                	li	a0,0
    n = snprintf(buf, sz, "lock: %s: #fetch-and-add %d #acquire() %d\n",
                 lk->name, lk->nts, lk->n);
  }
  return n;
}
    80000efc:	8082                	ret
{
    80000efe:	1141                	addi	sp,sp,-16
    80000f00:	e406                	sd	ra,8(sp)
    80000f02:	e022                	sd	s0,0(sp)
    80000f04:	0800                	addi	s0,sp,16
    n = snprintf(buf, sz, "lock: %s: #fetch-and-add %d #acquire() %d\n",
    80000f06:	4e18                	lw	a4,24(a2)
    80000f08:	6614                	ld	a3,8(a2)
    80000f0a:	00007617          	auipc	a2,0x7
    80000f0e:	1a660613          	addi	a2,a2,422 # 800080b0 <digits+0x70>
    80000f12:	00006097          	auipc	ra,0x6
    80000f16:	810080e7          	jalr	-2032(ra) # 80006722 <snprintf>
}
    80000f1a:	60a2                	ld	ra,8(sp)
    80000f1c:	6402                	ld	s0,0(sp)
    80000f1e:	0141                	addi	sp,sp,16
    80000f20:	8082                	ret

0000000080000f22 <statslock>:

int
statslock(char *buf, int sz) {
    80000f22:	7159                	addi	sp,sp,-112
    80000f24:	f486                	sd	ra,104(sp)
    80000f26:	f0a2                	sd	s0,96(sp)
    80000f28:	eca6                	sd	s1,88(sp)
    80000f2a:	e8ca                	sd	s2,80(sp)
    80000f2c:	e4ce                	sd	s3,72(sp)
    80000f2e:	e0d2                	sd	s4,64(sp)
    80000f30:	fc56                	sd	s5,56(sp)
    80000f32:	f85a                	sd	s6,48(sp)
    80000f34:	f45e                	sd	s7,40(sp)
    80000f36:	f062                	sd	s8,32(sp)
    80000f38:	ec66                	sd	s9,24(sp)
    80000f3a:	e86a                	sd	s10,16(sp)
    80000f3c:	e46e                	sd	s11,8(sp)
    80000f3e:	1880                	addi	s0,sp,112
    80000f40:	8aaa                	mv	s5,a0
    80000f42:	8b2e                	mv	s6,a1
  int n;
  int tot = 0;

  acquire(&lock_locks);
    80000f44:	00010517          	auipc	a0,0x10
    80000f48:	48450513          	addi	a0,a0,1156 # 800113c8 <lock_locks>
    80000f4c:	00000097          	auipc	ra,0x0
    80000f50:	dac080e7          	jalr	-596(ra) # 80000cf8 <acquire>
  n = snprintf(buf, sz, "--- lock kmem/bcache stats\n");
    80000f54:	00007617          	auipc	a2,0x7
    80000f58:	18c60613          	addi	a2,a2,396 # 800080e0 <digits+0xa0>
    80000f5c:	85da                	mv	a1,s6
    80000f5e:	8556                	mv	a0,s5
    80000f60:	00005097          	auipc	ra,0x5
    80000f64:	7c2080e7          	jalr	1986(ra) # 80006722 <snprintf>
    80000f68:	892a                	mv	s2,a0
  for(int i = 0; i < NLOCK; i++) {
    80000f6a:	00010c97          	auipc	s9,0x10
    80000f6e:	47ec8c93          	addi	s9,s9,1150 # 800113e8 <locks>
    80000f72:	00011c17          	auipc	s8,0x11
    80000f76:	416c0c13          	addi	s8,s8,1046 # 80012388 <pid_lock>
  n = snprintf(buf, sz, "--- lock kmem/bcache stats\n");
    80000f7a:	84e6                	mv	s1,s9
  int tot = 0;
    80000f7c:	4a01                	li	s4,0
    if(locks[i] == 0)
      break;
    if(strncmp(locks[i]->name, "bcache", strlen("bcache")) == 0 ||
    80000f7e:	00007b97          	auipc	s7,0x7
    80000f82:	182b8b93          	addi	s7,s7,386 # 80008100 <digits+0xc0>
       strncmp(locks[i]->name, "kmem", strlen("kmem")) == 0) {
    80000f86:	00007d17          	auipc	s10,0x7
    80000f8a:	0e2d0d13          	addi	s10,s10,226 # 80008068 <digits+0x28>
    80000f8e:	a01d                	j	80000fb4 <statslock+0x92>
      tot += locks[i]->nts;
    80000f90:	0009b603          	ld	a2,0(s3)
    80000f94:	4e1c                	lw	a5,24(a2)
    80000f96:	01478a3b          	addw	s4,a5,s4
      n += snprint_lock(buf +n, sz-n, locks[i]);
    80000f9a:	412b05bb          	subw	a1,s6,s2
    80000f9e:	012a8533          	add	a0,s5,s2
    80000fa2:	00000097          	auipc	ra,0x0
    80000fa6:	f52080e7          	jalr	-174(ra) # 80000ef4 <snprint_lock>
    80000faa:	0125093b          	addw	s2,a0,s2
  for(int i = 0; i < NLOCK; i++) {
    80000fae:	04a1                	addi	s1,s1,8
    80000fb0:	05848763          	beq	s1,s8,80000ffe <statslock+0xdc>
    if(locks[i] == 0)
    80000fb4:	89a6                	mv	s3,s1
    80000fb6:	609c                	ld	a5,0(s1)
    80000fb8:	c3b9                	beqz	a5,80000ffe <statslock+0xdc>
    if(strncmp(locks[i]->name, "bcache", strlen("bcache")) == 0 ||
    80000fba:	0087bd83          	ld	s11,8(a5)
    80000fbe:	855e                	mv	a0,s7
    80000fc0:	00000097          	auipc	ra,0x0
    80000fc4:	2a0080e7          	jalr	672(ra) # 80001260 <strlen>
    80000fc8:	0005061b          	sext.w	a2,a0
    80000fcc:	85de                	mv	a1,s7
    80000fce:	856e                	mv	a0,s11
    80000fd0:	00000097          	auipc	ra,0x0
    80000fd4:	1e4080e7          	jalr	484(ra) # 800011b4 <strncmp>
    80000fd8:	dd45                	beqz	a0,80000f90 <statslock+0x6e>
       strncmp(locks[i]->name, "kmem", strlen("kmem")) == 0) {
    80000fda:	609c                	ld	a5,0(s1)
    80000fdc:	0087bd83          	ld	s11,8(a5)
    80000fe0:	856a                	mv	a0,s10
    80000fe2:	00000097          	auipc	ra,0x0
    80000fe6:	27e080e7          	jalr	638(ra) # 80001260 <strlen>
    80000fea:	0005061b          	sext.w	a2,a0
    80000fee:	85ea                	mv	a1,s10
    80000ff0:	856e                	mv	a0,s11
    80000ff2:	00000097          	auipc	ra,0x0
    80000ff6:	1c2080e7          	jalr	450(ra) # 800011b4 <strncmp>
    if(strncmp(locks[i]->name, "bcache", strlen("bcache")) == 0 ||
    80000ffa:	f955                	bnez	a0,80000fae <statslock+0x8c>
    80000ffc:	bf51                	j	80000f90 <statslock+0x6e>
    }
  }
  
  n += snprintf(buf+n, sz-n, "--- top 5 contended locks:\n");
    80000ffe:	00007617          	auipc	a2,0x7
    80001002:	10a60613          	addi	a2,a2,266 # 80008108 <digits+0xc8>
    80001006:	412b05bb          	subw	a1,s6,s2
    8000100a:	012a8533          	add	a0,s5,s2
    8000100e:	00005097          	auipc	ra,0x5
    80001012:	714080e7          	jalr	1812(ra) # 80006722 <snprintf>
    80001016:	012509bb          	addw	s3,a0,s2
    8000101a:	4b95                	li	s7,5
  int last = 100000000;
    8000101c:	05f5e537          	lui	a0,0x5f5e
    80001020:	10050513          	addi	a0,a0,256 # 5f5e100 <_entry-0x7a0a1f00>
  // stupid way to compute top 5 contended locks
  for(int t = 0; t < 5; t++) {
    int top = 0;
    for(int i = 0; i < NLOCK; i++) {
    80001024:	4c01                	li	s8,0
      if(locks[i] == 0)
        break;
      if(locks[i]->nts > locks[top]->nts && locks[i]->nts < last) {
    80001026:	00010497          	auipc	s1,0x10
    8000102a:	3c248493          	addi	s1,s1,962 # 800113e8 <locks>
    for(int i = 0; i < NLOCK; i++) {
    8000102e:	1f400913          	li	s2,500
    80001032:	a881                	j	80001082 <statslock+0x160>
    80001034:	2705                	addiw	a4,a4,1
    80001036:	06a1                	addi	a3,a3,8
    80001038:	03270063          	beq	a4,s2,80001058 <statslock+0x136>
      if(locks[i] == 0)
    8000103c:	629c                	ld	a5,0(a3)
    8000103e:	cf89                	beqz	a5,80001058 <statslock+0x136>
      if(locks[i]->nts > locks[top]->nts && locks[i]->nts < last) {
    80001040:	4f90                	lw	a2,24(a5)
    80001042:	00359793          	slli	a5,a1,0x3
    80001046:	97a6                	add	a5,a5,s1
    80001048:	639c                	ld	a5,0(a5)
    8000104a:	4f9c                	lw	a5,24(a5)
    8000104c:	fec7d4e3          	bge	a5,a2,80001034 <statslock+0x112>
    80001050:	fea652e3          	bge	a2,a0,80001034 <statslock+0x112>
    80001054:	85ba                	mv	a1,a4
    80001056:	bff9                	j	80001034 <statslock+0x112>
        top = i;
      }
    }
    n += snprint_lock(buf+n, sz-n, locks[top]);
    80001058:	058e                	slli	a1,a1,0x3
    8000105a:	00b48d33          	add	s10,s1,a1
    8000105e:	000d3603          	ld	a2,0(s10)
    80001062:	413b05bb          	subw	a1,s6,s3
    80001066:	013a8533          	add	a0,s5,s3
    8000106a:	00000097          	auipc	ra,0x0
    8000106e:	e8a080e7          	jalr	-374(ra) # 80000ef4 <snprint_lock>
    80001072:	013509bb          	addw	s3,a0,s3
    last = locks[top]->nts;
    80001076:	000d3783          	ld	a5,0(s10)
    8000107a:	4f88                	lw	a0,24(a5)
  for(int t = 0; t < 5; t++) {
    8000107c:	3bfd                	addiw	s7,s7,-1
    8000107e:	000b8663          	beqz	s7,8000108a <statslock+0x168>
  int tot = 0;
    80001082:	86e6                	mv	a3,s9
    for(int i = 0; i < NLOCK; i++) {
    80001084:	8762                	mv	a4,s8
    int top = 0;
    80001086:	85e2                	mv	a1,s8
    80001088:	bf55                	j	8000103c <statslock+0x11a>
  }
  n += snprintf(buf+n, sz-n, "tot= %d\n", tot);
    8000108a:	86d2                	mv	a3,s4
    8000108c:	00007617          	auipc	a2,0x7
    80001090:	09c60613          	addi	a2,a2,156 # 80008128 <digits+0xe8>
    80001094:	413b05bb          	subw	a1,s6,s3
    80001098:	013a8533          	add	a0,s5,s3
    8000109c:	00005097          	auipc	ra,0x5
    800010a0:	686080e7          	jalr	1670(ra) # 80006722 <snprintf>
    800010a4:	013509bb          	addw	s3,a0,s3
  release(&lock_locks);  
    800010a8:	00010517          	auipc	a0,0x10
    800010ac:	32050513          	addi	a0,a0,800 # 800113c8 <lock_locks>
    800010b0:	00000097          	auipc	ra,0x0
    800010b4:	d18080e7          	jalr	-744(ra) # 80000dc8 <release>
  return n;
}
    800010b8:	854e                	mv	a0,s3
    800010ba:	70a6                	ld	ra,104(sp)
    800010bc:	7406                	ld	s0,96(sp)
    800010be:	64e6                	ld	s1,88(sp)
    800010c0:	6946                	ld	s2,80(sp)
    800010c2:	69a6                	ld	s3,72(sp)
    800010c4:	6a06                	ld	s4,64(sp)
    800010c6:	7ae2                	ld	s5,56(sp)
    800010c8:	7b42                	ld	s6,48(sp)
    800010ca:	7ba2                	ld	s7,40(sp)
    800010cc:	7c02                	ld	s8,32(sp)
    800010ce:	6ce2                	ld	s9,24(sp)
    800010d0:	6d42                	ld	s10,16(sp)
    800010d2:	6da2                	ld	s11,8(sp)
    800010d4:	6165                	addi	sp,sp,112
    800010d6:	8082                	ret

00000000800010d8 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    800010d8:	1141                	addi	sp,sp,-16
    800010da:	e422                	sd	s0,8(sp)
    800010dc:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    800010de:	ce09                	beqz	a2,800010f8 <memset+0x20>
    800010e0:	87aa                	mv	a5,a0
    800010e2:	fff6071b          	addiw	a4,a2,-1
    800010e6:	1702                	slli	a4,a4,0x20
    800010e8:	9301                	srli	a4,a4,0x20
    800010ea:	0705                	addi	a4,a4,1
    800010ec:	972a                	add	a4,a4,a0
    cdst[i] = c;
    800010ee:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    800010f2:	0785                	addi	a5,a5,1
    800010f4:	fee79de3          	bne	a5,a4,800010ee <memset+0x16>
  }
  return dst;
}
    800010f8:	6422                	ld	s0,8(sp)
    800010fa:	0141                	addi	sp,sp,16
    800010fc:	8082                	ret

00000000800010fe <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    800010fe:	1141                	addi	sp,sp,-16
    80001100:	e422                	sd	s0,8(sp)
    80001102:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80001104:	ca05                	beqz	a2,80001134 <memcmp+0x36>
    80001106:	fff6069b          	addiw	a3,a2,-1
    8000110a:	1682                	slli	a3,a3,0x20
    8000110c:	9281                	srli	a3,a3,0x20
    8000110e:	0685                	addi	a3,a3,1
    80001110:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80001112:	00054783          	lbu	a5,0(a0)
    80001116:	0005c703          	lbu	a4,0(a1)
    8000111a:	00e79863          	bne	a5,a4,8000112a <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    8000111e:	0505                	addi	a0,a0,1
    80001120:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80001122:	fed518e3          	bne	a0,a3,80001112 <memcmp+0x14>
  }

  return 0;
    80001126:	4501                	li	a0,0
    80001128:	a019                	j	8000112e <memcmp+0x30>
      return *s1 - *s2;
    8000112a:	40e7853b          	subw	a0,a5,a4
}
    8000112e:	6422                	ld	s0,8(sp)
    80001130:	0141                	addi	sp,sp,16
    80001132:	8082                	ret
  return 0;
    80001134:	4501                	li	a0,0
    80001136:	bfe5                	j	8000112e <memcmp+0x30>

0000000080001138 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80001138:	1141                	addi	sp,sp,-16
    8000113a:	e422                	sd	s0,8(sp)
    8000113c:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    8000113e:	00a5f963          	bgeu	a1,a0,80001150 <memmove+0x18>
    80001142:	02061713          	slli	a4,a2,0x20
    80001146:	9301                	srli	a4,a4,0x20
    80001148:	00e587b3          	add	a5,a1,a4
    8000114c:	02f56563          	bltu	a0,a5,80001176 <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80001150:	fff6069b          	addiw	a3,a2,-1
    80001154:	ce11                	beqz	a2,80001170 <memmove+0x38>
    80001156:	1682                	slli	a3,a3,0x20
    80001158:	9281                	srli	a3,a3,0x20
    8000115a:	0685                	addi	a3,a3,1
    8000115c:	96ae                	add	a3,a3,a1
    8000115e:	87aa                	mv	a5,a0
      *d++ = *s++;
    80001160:	0585                	addi	a1,a1,1
    80001162:	0785                	addi	a5,a5,1
    80001164:	fff5c703          	lbu	a4,-1(a1)
    80001168:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    8000116c:	fed59ae3          	bne	a1,a3,80001160 <memmove+0x28>

  return dst;
}
    80001170:	6422                	ld	s0,8(sp)
    80001172:	0141                	addi	sp,sp,16
    80001174:	8082                	ret
    d += n;
    80001176:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80001178:	fff6069b          	addiw	a3,a2,-1
    8000117c:	da75                	beqz	a2,80001170 <memmove+0x38>
    8000117e:	02069613          	slli	a2,a3,0x20
    80001182:	9201                	srli	a2,a2,0x20
    80001184:	fff64613          	not	a2,a2
    80001188:	963e                	add	a2,a2,a5
      *--d = *--s;
    8000118a:	17fd                	addi	a5,a5,-1
    8000118c:	177d                	addi	a4,a4,-1
    8000118e:	0007c683          	lbu	a3,0(a5)
    80001192:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80001196:	fec79ae3          	bne	a5,a2,8000118a <memmove+0x52>
    8000119a:	bfd9                	j	80001170 <memmove+0x38>

000000008000119c <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    8000119c:	1141                	addi	sp,sp,-16
    8000119e:	e406                	sd	ra,8(sp)
    800011a0:	e022                	sd	s0,0(sp)
    800011a2:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    800011a4:	00000097          	auipc	ra,0x0
    800011a8:	f94080e7          	jalr	-108(ra) # 80001138 <memmove>
}
    800011ac:	60a2                	ld	ra,8(sp)
    800011ae:	6402                	ld	s0,0(sp)
    800011b0:	0141                	addi	sp,sp,16
    800011b2:	8082                	ret

00000000800011b4 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    800011b4:	1141                	addi	sp,sp,-16
    800011b6:	e422                	sd	s0,8(sp)
    800011b8:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    800011ba:	ce11                	beqz	a2,800011d6 <strncmp+0x22>
    800011bc:	00054783          	lbu	a5,0(a0)
    800011c0:	cf89                	beqz	a5,800011da <strncmp+0x26>
    800011c2:	0005c703          	lbu	a4,0(a1)
    800011c6:	00f71a63          	bne	a4,a5,800011da <strncmp+0x26>
    n--, p++, q++;
    800011ca:	367d                	addiw	a2,a2,-1
    800011cc:	0505                	addi	a0,a0,1
    800011ce:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    800011d0:	f675                	bnez	a2,800011bc <strncmp+0x8>
  if(n == 0)
    return 0;
    800011d2:	4501                	li	a0,0
    800011d4:	a809                	j	800011e6 <strncmp+0x32>
    800011d6:	4501                	li	a0,0
    800011d8:	a039                	j	800011e6 <strncmp+0x32>
  if(n == 0)
    800011da:	ca09                	beqz	a2,800011ec <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    800011dc:	00054503          	lbu	a0,0(a0)
    800011e0:	0005c783          	lbu	a5,0(a1)
    800011e4:	9d1d                	subw	a0,a0,a5
}
    800011e6:	6422                	ld	s0,8(sp)
    800011e8:	0141                	addi	sp,sp,16
    800011ea:	8082                	ret
    return 0;
    800011ec:	4501                	li	a0,0
    800011ee:	bfe5                	j	800011e6 <strncmp+0x32>

00000000800011f0 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    800011f0:	1141                	addi	sp,sp,-16
    800011f2:	e422                	sd	s0,8(sp)
    800011f4:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    800011f6:	872a                	mv	a4,a0
    800011f8:	8832                	mv	a6,a2
    800011fa:	367d                	addiw	a2,a2,-1
    800011fc:	01005963          	blez	a6,8000120e <strncpy+0x1e>
    80001200:	0705                	addi	a4,a4,1
    80001202:	0005c783          	lbu	a5,0(a1)
    80001206:	fef70fa3          	sb	a5,-1(a4)
    8000120a:	0585                	addi	a1,a1,1
    8000120c:	f7f5                	bnez	a5,800011f8 <strncpy+0x8>
    ;
  while(n-- > 0)
    8000120e:	00c05d63          	blez	a2,80001228 <strncpy+0x38>
    80001212:	86ba                	mv	a3,a4
    *s++ = 0;
    80001214:	0685                	addi	a3,a3,1
    80001216:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    8000121a:	fff6c793          	not	a5,a3
    8000121e:	9fb9                	addw	a5,a5,a4
    80001220:	010787bb          	addw	a5,a5,a6
    80001224:	fef048e3          	bgtz	a5,80001214 <strncpy+0x24>
  return os;
}
    80001228:	6422                	ld	s0,8(sp)
    8000122a:	0141                	addi	sp,sp,16
    8000122c:	8082                	ret

000000008000122e <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    8000122e:	1141                	addi	sp,sp,-16
    80001230:	e422                	sd	s0,8(sp)
    80001232:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80001234:	02c05363          	blez	a2,8000125a <safestrcpy+0x2c>
    80001238:	fff6069b          	addiw	a3,a2,-1
    8000123c:	1682                	slli	a3,a3,0x20
    8000123e:	9281                	srli	a3,a3,0x20
    80001240:	96ae                	add	a3,a3,a1
    80001242:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80001244:	00d58963          	beq	a1,a3,80001256 <safestrcpy+0x28>
    80001248:	0585                	addi	a1,a1,1
    8000124a:	0785                	addi	a5,a5,1
    8000124c:	fff5c703          	lbu	a4,-1(a1)
    80001250:	fee78fa3          	sb	a4,-1(a5)
    80001254:	fb65                	bnez	a4,80001244 <safestrcpy+0x16>
    ;
  *s = 0;
    80001256:	00078023          	sb	zero,0(a5)
  return os;
}
    8000125a:	6422                	ld	s0,8(sp)
    8000125c:	0141                	addi	sp,sp,16
    8000125e:	8082                	ret

0000000080001260 <strlen>:

int
strlen(const char *s)
{
    80001260:	1141                	addi	sp,sp,-16
    80001262:	e422                	sd	s0,8(sp)
    80001264:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80001266:	00054783          	lbu	a5,0(a0)
    8000126a:	cf91                	beqz	a5,80001286 <strlen+0x26>
    8000126c:	0505                	addi	a0,a0,1
    8000126e:	87aa                	mv	a5,a0
    80001270:	4685                	li	a3,1
    80001272:	9e89                	subw	a3,a3,a0
    80001274:	00f6853b          	addw	a0,a3,a5
    80001278:	0785                	addi	a5,a5,1
    8000127a:	fff7c703          	lbu	a4,-1(a5)
    8000127e:	fb7d                	bnez	a4,80001274 <strlen+0x14>
    ;
  return n;
}
    80001280:	6422                	ld	s0,8(sp)
    80001282:	0141                	addi	sp,sp,16
    80001284:	8082                	ret
  for(n = 0; s[n]; n++)
    80001286:	4501                	li	a0,0
    80001288:	bfe5                	j	80001280 <strlen+0x20>

000000008000128a <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    8000128a:	1141                	addi	sp,sp,-16
    8000128c:	e406                	sd	ra,8(sp)
    8000128e:	e022                	sd	s0,0(sp)
    80001290:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80001292:	00001097          	auipc	ra,0x1
    80001296:	a82080e7          	jalr	-1406(ra) # 80001d14 <cpuid>
#endif    
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    8000129a:	00008717          	auipc	a4,0x8
    8000129e:	d7270713          	addi	a4,a4,-654 # 8000900c <started>
  if(cpuid() == 0){
    800012a2:	c139                	beqz	a0,800012e8 <main+0x5e>
    while(started == 0)
    800012a4:	431c                	lw	a5,0(a4)
    800012a6:	2781                	sext.w	a5,a5
    800012a8:	dff5                	beqz	a5,800012a4 <main+0x1a>
      ;
    __sync_synchronize();
    800012aa:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    800012ae:	00001097          	auipc	ra,0x1
    800012b2:	a66080e7          	jalr	-1434(ra) # 80001d14 <cpuid>
    800012b6:	85aa                	mv	a1,a0
    800012b8:	00007517          	auipc	a0,0x7
    800012bc:	e9850513          	addi	a0,a0,-360 # 80008150 <digits+0x110>
    800012c0:	fffff097          	auipc	ra,0xfffff
    800012c4:	2da080e7          	jalr	730(ra) # 8000059a <printf>
    kvminithart();    // turn on paging
    800012c8:	00000097          	auipc	ra,0x0
    800012cc:	186080e7          	jalr	390(ra) # 8000144e <kvminithart>
    trapinithart();   // install kernel trap vector
    800012d0:	00001097          	auipc	ra,0x1
    800012d4:	6ce080e7          	jalr	1742(ra) # 8000299e <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    800012d8:	00005097          	auipc	ra,0x5
    800012dc:	c88080e7          	jalr	-888(ra) # 80005f60 <plicinithart>
  }

  scheduler();        
    800012e0:	00001097          	auipc	ra,0x1
    800012e4:	f90080e7          	jalr	-112(ra) # 80002270 <scheduler>
    consoleinit();
    800012e8:	fffff097          	auipc	ra,0xfffff
    800012ec:	17a080e7          	jalr	378(ra) # 80000462 <consoleinit>
    statsinit();
    800012f0:	00005097          	auipc	ra,0x5
    800012f4:	356080e7          	jalr	854(ra) # 80006646 <statsinit>
    printfinit();
    800012f8:	fffff097          	auipc	ra,0xfffff
    800012fc:	488080e7          	jalr	1160(ra) # 80000780 <printfinit>
    printf("\n");
    80001300:	00007517          	auipc	a0,0x7
    80001304:	e6050513          	addi	a0,a0,-416 # 80008160 <digits+0x120>
    80001308:	fffff097          	auipc	ra,0xfffff
    8000130c:	292080e7          	jalr	658(ra) # 8000059a <printf>
    printf("xv6 kernel is booting\n");
    80001310:	00007517          	auipc	a0,0x7
    80001314:	e2850513          	addi	a0,a0,-472 # 80008138 <digits+0xf8>
    80001318:	fffff097          	auipc	ra,0xfffff
    8000131c:	282080e7          	jalr	642(ra) # 8000059a <printf>
    printf("\n");
    80001320:	00007517          	auipc	a0,0x7
    80001324:	e4050513          	addi	a0,a0,-448 # 80008160 <digits+0x120>
    80001328:	fffff097          	auipc	ra,0xfffff
    8000132c:	272080e7          	jalr	626(ra) # 8000059a <printf>
    kinit();         // physical page allocator
    80001330:	fffff097          	auipc	ra,0xfffff
    80001334:	7ec080e7          	jalr	2028(ra) # 80000b1c <kinit>
    kvminit();       // create kernel page table
    80001338:	00000097          	auipc	ra,0x0
    8000133c:	242080e7          	jalr	578(ra) # 8000157a <kvminit>
    kvminithart();   // turn on paging
    80001340:	00000097          	auipc	ra,0x0
    80001344:	10e080e7          	jalr	270(ra) # 8000144e <kvminithart>
    procinit();      // process table
    80001348:	00001097          	auipc	ra,0x1
    8000134c:	8fc080e7          	jalr	-1796(ra) # 80001c44 <procinit>
    trapinit();      // trap vectors
    80001350:	00001097          	auipc	ra,0x1
    80001354:	626080e7          	jalr	1574(ra) # 80002976 <trapinit>
    trapinithart();  // install kernel trap vector
    80001358:	00001097          	auipc	ra,0x1
    8000135c:	646080e7          	jalr	1606(ra) # 8000299e <trapinithart>
    plicinit();      // set up interrupt controller
    80001360:	00005097          	auipc	ra,0x5
    80001364:	bea080e7          	jalr	-1046(ra) # 80005f4a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80001368:	00005097          	auipc	ra,0x5
    8000136c:	bf8080e7          	jalr	-1032(ra) # 80005f60 <plicinithart>
    binit();         // buffer cache
    80001370:	00002097          	auipc	ra,0x2
    80001374:	d70080e7          	jalr	-656(ra) # 800030e0 <binit>
    iinit();         // inode cache
    80001378:	00002097          	auipc	ra,0x2
    8000137c:	400080e7          	jalr	1024(ra) # 80003778 <iinit>
    fileinit();      // file table
    80001380:	00003097          	auipc	ra,0x3
    80001384:	3b0080e7          	jalr	944(ra) # 80004730 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80001388:	00005097          	auipc	ra,0x5
    8000138c:	cfa080e7          	jalr	-774(ra) # 80006082 <virtio_disk_init>
    userinit();      // first user process
    80001390:	00001097          	auipc	ra,0x1
    80001394:	c7a080e7          	jalr	-902(ra) # 8000200a <userinit>
    __sync_synchronize();
    80001398:	0ff0000f          	fence
    started = 1;
    8000139c:	4785                	li	a5,1
    8000139e:	00008717          	auipc	a4,0x8
    800013a2:	c6f72723          	sw	a5,-914(a4) # 8000900c <started>
    800013a6:	bf2d                	j	800012e0 <main+0x56>

00000000800013a8 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
static pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    800013a8:	7139                	addi	sp,sp,-64
    800013aa:	fc06                	sd	ra,56(sp)
    800013ac:	f822                	sd	s0,48(sp)
    800013ae:	f426                	sd	s1,40(sp)
    800013b0:	f04a                	sd	s2,32(sp)
    800013b2:	ec4e                	sd	s3,24(sp)
    800013b4:	e852                	sd	s4,16(sp)
    800013b6:	e456                	sd	s5,8(sp)
    800013b8:	e05a                	sd	s6,0(sp)
    800013ba:	0080                	addi	s0,sp,64
    800013bc:	84aa                	mv	s1,a0
    800013be:	89ae                	mv	s3,a1
    800013c0:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    800013c2:	57fd                	li	a5,-1
    800013c4:	83e9                	srli	a5,a5,0x1a
    800013c6:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    800013c8:	4b31                	li	s6,12
  if(va >= MAXVA)
    800013ca:	04b7f263          	bgeu	a5,a1,8000140e <walk+0x66>
    panic("walk");
    800013ce:	00007517          	auipc	a0,0x7
    800013d2:	d9a50513          	addi	a0,a0,-614 # 80008168 <digits+0x128>
    800013d6:	fffff097          	auipc	ra,0xfffff
    800013da:	17a080e7          	jalr	378(ra) # 80000550 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    800013de:	060a8663          	beqz	s5,8000144a <walk+0xa2>
    800013e2:	fffff097          	auipc	ra,0xfffff
    800013e6:	796080e7          	jalr	1942(ra) # 80000b78 <kalloc>
    800013ea:	84aa                	mv	s1,a0
    800013ec:	c529                	beqz	a0,80001436 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    800013ee:	6605                	lui	a2,0x1
    800013f0:	4581                	li	a1,0
    800013f2:	00000097          	auipc	ra,0x0
    800013f6:	ce6080e7          	jalr	-794(ra) # 800010d8 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    800013fa:	00c4d793          	srli	a5,s1,0xc
    800013fe:	07aa                	slli	a5,a5,0xa
    80001400:	0017e793          	ori	a5,a5,1
    80001404:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001408:	3a5d                	addiw	s4,s4,-9
    8000140a:	036a0063          	beq	s4,s6,8000142a <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000140e:	0149d933          	srl	s2,s3,s4
    80001412:	1ff97913          	andi	s2,s2,511
    80001416:	090e                	slli	s2,s2,0x3
    80001418:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000141a:	00093483          	ld	s1,0(s2)
    8000141e:	0014f793          	andi	a5,s1,1
    80001422:	dfd5                	beqz	a5,800013de <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001424:	80a9                	srli	s1,s1,0xa
    80001426:	04b2                	slli	s1,s1,0xc
    80001428:	b7c5                	j	80001408 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000142a:	00c9d513          	srli	a0,s3,0xc
    8000142e:	1ff57513          	andi	a0,a0,511
    80001432:	050e                	slli	a0,a0,0x3
    80001434:	9526                	add	a0,a0,s1
}
    80001436:	70e2                	ld	ra,56(sp)
    80001438:	7442                	ld	s0,48(sp)
    8000143a:	74a2                	ld	s1,40(sp)
    8000143c:	7902                	ld	s2,32(sp)
    8000143e:	69e2                	ld	s3,24(sp)
    80001440:	6a42                	ld	s4,16(sp)
    80001442:	6aa2                	ld	s5,8(sp)
    80001444:	6b02                	ld	s6,0(sp)
    80001446:	6121                	addi	sp,sp,64
    80001448:	8082                	ret
        return 0;
    8000144a:	4501                	li	a0,0
    8000144c:	b7ed                	j	80001436 <walk+0x8e>

000000008000144e <kvminithart>:
{
    8000144e:	1141                	addi	sp,sp,-16
    80001450:	e422                	sd	s0,8(sp)
    80001452:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80001454:	00008797          	auipc	a5,0x8
    80001458:	bbc7b783          	ld	a5,-1092(a5) # 80009010 <kernel_pagetable>
    8000145c:	83b1                	srli	a5,a5,0xc
    8000145e:	577d                	li	a4,-1
    80001460:	177e                	slli	a4,a4,0x3f
    80001462:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80001464:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80001468:	12000073          	sfence.vma
}
    8000146c:	6422                	ld	s0,8(sp)
    8000146e:	0141                	addi	sp,sp,16
    80001470:	8082                	ret

0000000080001472 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001472:	57fd                	li	a5,-1
    80001474:	83e9                	srli	a5,a5,0x1a
    80001476:	00b7f463          	bgeu	a5,a1,8000147e <walkaddr+0xc>
    return 0;
    8000147a:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    8000147c:	8082                	ret
{
    8000147e:	1141                	addi	sp,sp,-16
    80001480:	e406                	sd	ra,8(sp)
    80001482:	e022                	sd	s0,0(sp)
    80001484:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001486:	4601                	li	a2,0
    80001488:	00000097          	auipc	ra,0x0
    8000148c:	f20080e7          	jalr	-224(ra) # 800013a8 <walk>
  if(pte == 0)
    80001490:	c105                	beqz	a0,800014b0 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001492:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001494:	0117f693          	andi	a3,a5,17
    80001498:	4745                	li	a4,17
    return 0;
    8000149a:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    8000149c:	00e68663          	beq	a3,a4,800014a8 <walkaddr+0x36>
}
    800014a0:	60a2                	ld	ra,8(sp)
    800014a2:	6402                	ld	s0,0(sp)
    800014a4:	0141                	addi	sp,sp,16
    800014a6:	8082                	ret
  pa = PTE2PA(*pte);
    800014a8:	00a7d513          	srli	a0,a5,0xa
    800014ac:	0532                	slli	a0,a0,0xc
  return pa;
    800014ae:	bfcd                	j	800014a0 <walkaddr+0x2e>
    return 0;
    800014b0:	4501                	li	a0,0
    800014b2:	b7fd                	j	800014a0 <walkaddr+0x2e>

00000000800014b4 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800014b4:	715d                	addi	sp,sp,-80
    800014b6:	e486                	sd	ra,72(sp)
    800014b8:	e0a2                	sd	s0,64(sp)
    800014ba:	fc26                	sd	s1,56(sp)
    800014bc:	f84a                	sd	s2,48(sp)
    800014be:	f44e                	sd	s3,40(sp)
    800014c0:	f052                	sd	s4,32(sp)
    800014c2:	ec56                	sd	s5,24(sp)
    800014c4:	e85a                	sd	s6,16(sp)
    800014c6:	e45e                	sd	s7,8(sp)
    800014c8:	0880                	addi	s0,sp,80
    800014ca:	8aaa                	mv	s5,a0
    800014cc:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    800014ce:	777d                	lui	a4,0xfffff
    800014d0:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800014d4:	167d                	addi	a2,a2,-1
    800014d6:	00b609b3          	add	s3,a2,a1
    800014da:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800014de:	893e                	mv	s2,a5
    800014e0:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800014e4:	6b85                	lui	s7,0x1
    800014e6:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800014ea:	4605                	li	a2,1
    800014ec:	85ca                	mv	a1,s2
    800014ee:	8556                	mv	a0,s5
    800014f0:	00000097          	auipc	ra,0x0
    800014f4:	eb8080e7          	jalr	-328(ra) # 800013a8 <walk>
    800014f8:	c51d                	beqz	a0,80001526 <mappages+0x72>
    if(*pte & PTE_V)
    800014fa:	611c                	ld	a5,0(a0)
    800014fc:	8b85                	andi	a5,a5,1
    800014fe:	ef81                	bnez	a5,80001516 <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001500:	80b1                	srli	s1,s1,0xc
    80001502:	04aa                	slli	s1,s1,0xa
    80001504:	0164e4b3          	or	s1,s1,s6
    80001508:	0014e493          	ori	s1,s1,1
    8000150c:	e104                	sd	s1,0(a0)
    if(a == last)
    8000150e:	03390863          	beq	s2,s3,8000153e <mappages+0x8a>
    a += PGSIZE;
    80001512:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001514:	bfc9                	j	800014e6 <mappages+0x32>
      panic("remap");
    80001516:	00007517          	auipc	a0,0x7
    8000151a:	c5a50513          	addi	a0,a0,-934 # 80008170 <digits+0x130>
    8000151e:	fffff097          	auipc	ra,0xfffff
    80001522:	032080e7          	jalr	50(ra) # 80000550 <panic>
      return -1;
    80001526:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001528:	60a6                	ld	ra,72(sp)
    8000152a:	6406                	ld	s0,64(sp)
    8000152c:	74e2                	ld	s1,56(sp)
    8000152e:	7942                	ld	s2,48(sp)
    80001530:	79a2                	ld	s3,40(sp)
    80001532:	7a02                	ld	s4,32(sp)
    80001534:	6ae2                	ld	s5,24(sp)
    80001536:	6b42                	ld	s6,16(sp)
    80001538:	6ba2                	ld	s7,8(sp)
    8000153a:	6161                	addi	sp,sp,80
    8000153c:	8082                	ret
  return 0;
    8000153e:	4501                	li	a0,0
    80001540:	b7e5                	j	80001528 <mappages+0x74>

0000000080001542 <kvmmap>:
{
    80001542:	1141                	addi	sp,sp,-16
    80001544:	e406                	sd	ra,8(sp)
    80001546:	e022                	sd	s0,0(sp)
    80001548:	0800                	addi	s0,sp,16
    8000154a:	8736                	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    8000154c:	86ae                	mv	a3,a1
    8000154e:	85aa                	mv	a1,a0
    80001550:	00008517          	auipc	a0,0x8
    80001554:	ac053503          	ld	a0,-1344(a0) # 80009010 <kernel_pagetable>
    80001558:	00000097          	auipc	ra,0x0
    8000155c:	f5c080e7          	jalr	-164(ra) # 800014b4 <mappages>
    80001560:	e509                	bnez	a0,8000156a <kvmmap+0x28>
}
    80001562:	60a2                	ld	ra,8(sp)
    80001564:	6402                	ld	s0,0(sp)
    80001566:	0141                	addi	sp,sp,16
    80001568:	8082                	ret
    panic("kvmmap");
    8000156a:	00007517          	auipc	a0,0x7
    8000156e:	c0e50513          	addi	a0,a0,-1010 # 80008178 <digits+0x138>
    80001572:	fffff097          	auipc	ra,0xfffff
    80001576:	fde080e7          	jalr	-34(ra) # 80000550 <panic>

000000008000157a <kvminit>:
{
    8000157a:	1101                	addi	sp,sp,-32
    8000157c:	ec06                	sd	ra,24(sp)
    8000157e:	e822                	sd	s0,16(sp)
    80001580:	e426                	sd	s1,8(sp)
    80001582:	1000                	addi	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    80001584:	fffff097          	auipc	ra,0xfffff
    80001588:	5f4080e7          	jalr	1524(ra) # 80000b78 <kalloc>
    8000158c:	00008797          	auipc	a5,0x8
    80001590:	a8a7b223          	sd	a0,-1404(a5) # 80009010 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    80001594:	6605                	lui	a2,0x1
    80001596:	4581                	li	a1,0
    80001598:	00000097          	auipc	ra,0x0
    8000159c:	b40080e7          	jalr	-1216(ra) # 800010d8 <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800015a0:	4699                	li	a3,6
    800015a2:	6605                	lui	a2,0x1
    800015a4:	100005b7          	lui	a1,0x10000
    800015a8:	10000537          	lui	a0,0x10000
    800015ac:	00000097          	auipc	ra,0x0
    800015b0:	f96080e7          	jalr	-106(ra) # 80001542 <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800015b4:	4699                	li	a3,6
    800015b6:	6605                	lui	a2,0x1
    800015b8:	100015b7          	lui	a1,0x10001
    800015bc:	10001537          	lui	a0,0x10001
    800015c0:	00000097          	auipc	ra,0x0
    800015c4:	f82080e7          	jalr	-126(ra) # 80001542 <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800015c8:	4699                	li	a3,6
    800015ca:	00400637          	lui	a2,0x400
    800015ce:	0c0005b7          	lui	a1,0xc000
    800015d2:	0c000537          	lui	a0,0xc000
    800015d6:	00000097          	auipc	ra,0x0
    800015da:	f6c080e7          	jalr	-148(ra) # 80001542 <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800015de:	00007497          	auipc	s1,0x7
    800015e2:	a2248493          	addi	s1,s1,-1502 # 80008000 <etext>
    800015e6:	46a9                	li	a3,10
    800015e8:	80007617          	auipc	a2,0x80007
    800015ec:	a1860613          	addi	a2,a2,-1512 # 8000 <_entry-0x7fff8000>
    800015f0:	4585                	li	a1,1
    800015f2:	05fe                	slli	a1,a1,0x1f
    800015f4:	852e                	mv	a0,a1
    800015f6:	00000097          	auipc	ra,0x0
    800015fa:	f4c080e7          	jalr	-180(ra) # 80001542 <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800015fe:	4699                	li	a3,6
    80001600:	4645                	li	a2,17
    80001602:	066e                	slli	a2,a2,0x1b
    80001604:	8e05                	sub	a2,a2,s1
    80001606:	85a6                	mv	a1,s1
    80001608:	8526                	mv	a0,s1
    8000160a:	00000097          	auipc	ra,0x0
    8000160e:	f38080e7          	jalr	-200(ra) # 80001542 <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001612:	46a9                	li	a3,10
    80001614:	6605                	lui	a2,0x1
    80001616:	00006597          	auipc	a1,0x6
    8000161a:	9ea58593          	addi	a1,a1,-1558 # 80007000 <_trampoline>
    8000161e:	04000537          	lui	a0,0x4000
    80001622:	157d                	addi	a0,a0,-1
    80001624:	0532                	slli	a0,a0,0xc
    80001626:	00000097          	auipc	ra,0x0
    8000162a:	f1c080e7          	jalr	-228(ra) # 80001542 <kvmmap>
}
    8000162e:	60e2                	ld	ra,24(sp)
    80001630:	6442                	ld	s0,16(sp)
    80001632:	64a2                	ld	s1,8(sp)
    80001634:	6105                	addi	sp,sp,32
    80001636:	8082                	ret

0000000080001638 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001638:	715d                	addi	sp,sp,-80
    8000163a:	e486                	sd	ra,72(sp)
    8000163c:	e0a2                	sd	s0,64(sp)
    8000163e:	fc26                	sd	s1,56(sp)
    80001640:	f84a                	sd	s2,48(sp)
    80001642:	f44e                	sd	s3,40(sp)
    80001644:	f052                	sd	s4,32(sp)
    80001646:	ec56                	sd	s5,24(sp)
    80001648:	e85a                	sd	s6,16(sp)
    8000164a:	e45e                	sd	s7,8(sp)
    8000164c:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000164e:	03459793          	slli	a5,a1,0x34
    80001652:	e795                	bnez	a5,8000167e <uvmunmap+0x46>
    80001654:	8a2a                	mv	s4,a0
    80001656:	892e                	mv	s2,a1
    80001658:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000165a:	0632                	slli	a2,a2,0xc
    8000165c:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001660:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001662:	6b05                	lui	s6,0x1
    80001664:	0735e863          	bltu	a1,s3,800016d4 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001668:	60a6                	ld	ra,72(sp)
    8000166a:	6406                	ld	s0,64(sp)
    8000166c:	74e2                	ld	s1,56(sp)
    8000166e:	7942                	ld	s2,48(sp)
    80001670:	79a2                	ld	s3,40(sp)
    80001672:	7a02                	ld	s4,32(sp)
    80001674:	6ae2                	ld	s5,24(sp)
    80001676:	6b42                	ld	s6,16(sp)
    80001678:	6ba2                	ld	s7,8(sp)
    8000167a:	6161                	addi	sp,sp,80
    8000167c:	8082                	ret
    panic("uvmunmap: not aligned");
    8000167e:	00007517          	auipc	a0,0x7
    80001682:	b0250513          	addi	a0,a0,-1278 # 80008180 <digits+0x140>
    80001686:	fffff097          	auipc	ra,0xfffff
    8000168a:	eca080e7          	jalr	-310(ra) # 80000550 <panic>
      panic("uvmunmap: walk");
    8000168e:	00007517          	auipc	a0,0x7
    80001692:	b0a50513          	addi	a0,a0,-1270 # 80008198 <digits+0x158>
    80001696:	fffff097          	auipc	ra,0xfffff
    8000169a:	eba080e7          	jalr	-326(ra) # 80000550 <panic>
      panic("uvmunmap: not mapped");
    8000169e:	00007517          	auipc	a0,0x7
    800016a2:	b0a50513          	addi	a0,a0,-1270 # 800081a8 <digits+0x168>
    800016a6:	fffff097          	auipc	ra,0xfffff
    800016aa:	eaa080e7          	jalr	-342(ra) # 80000550 <panic>
      panic("uvmunmap: not a leaf");
    800016ae:	00007517          	auipc	a0,0x7
    800016b2:	b1250513          	addi	a0,a0,-1262 # 800081c0 <digits+0x180>
    800016b6:	fffff097          	auipc	ra,0xfffff
    800016ba:	e9a080e7          	jalr	-358(ra) # 80000550 <panic>
      uint64 pa = PTE2PA(*pte);
    800016be:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800016c0:	0532                	slli	a0,a0,0xc
    800016c2:	fffff097          	auipc	ra,0xfffff
    800016c6:	36a080e7          	jalr	874(ra) # 80000a2c <kfree>
    *pte = 0;
    800016ca:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800016ce:	995a                	add	s2,s2,s6
    800016d0:	f9397ce3          	bgeu	s2,s3,80001668 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800016d4:	4601                	li	a2,0
    800016d6:	85ca                	mv	a1,s2
    800016d8:	8552                	mv	a0,s4
    800016da:	00000097          	auipc	ra,0x0
    800016de:	cce080e7          	jalr	-818(ra) # 800013a8 <walk>
    800016e2:	84aa                	mv	s1,a0
    800016e4:	d54d                	beqz	a0,8000168e <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800016e6:	6108                	ld	a0,0(a0)
    800016e8:	00157793          	andi	a5,a0,1
    800016ec:	dbcd                	beqz	a5,8000169e <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    800016ee:	3ff57793          	andi	a5,a0,1023
    800016f2:	fb778ee3          	beq	a5,s7,800016ae <uvmunmap+0x76>
    if(do_free){
    800016f6:	fc0a8ae3          	beqz	s5,800016ca <uvmunmap+0x92>
    800016fa:	b7d1                	j	800016be <uvmunmap+0x86>

00000000800016fc <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800016fc:	1101                	addi	sp,sp,-32
    800016fe:	ec06                	sd	ra,24(sp)
    80001700:	e822                	sd	s0,16(sp)
    80001702:	e426                	sd	s1,8(sp)
    80001704:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001706:	fffff097          	auipc	ra,0xfffff
    8000170a:	472080e7          	jalr	1138(ra) # 80000b78 <kalloc>
    8000170e:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001710:	c519                	beqz	a0,8000171e <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001712:	6605                	lui	a2,0x1
    80001714:	4581                	li	a1,0
    80001716:	00000097          	auipc	ra,0x0
    8000171a:	9c2080e7          	jalr	-1598(ra) # 800010d8 <memset>
  return pagetable;
}
    8000171e:	8526                	mv	a0,s1
    80001720:	60e2                	ld	ra,24(sp)
    80001722:	6442                	ld	s0,16(sp)
    80001724:	64a2                	ld	s1,8(sp)
    80001726:	6105                	addi	sp,sp,32
    80001728:	8082                	ret

000000008000172a <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    8000172a:	7179                	addi	sp,sp,-48
    8000172c:	f406                	sd	ra,40(sp)
    8000172e:	f022                	sd	s0,32(sp)
    80001730:	ec26                	sd	s1,24(sp)
    80001732:	e84a                	sd	s2,16(sp)
    80001734:	e44e                	sd	s3,8(sp)
    80001736:	e052                	sd	s4,0(sp)
    80001738:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    8000173a:	6785                	lui	a5,0x1
    8000173c:	04f67863          	bgeu	a2,a5,8000178c <uvminit+0x62>
    80001740:	8a2a                	mv	s4,a0
    80001742:	89ae                	mv	s3,a1
    80001744:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001746:	fffff097          	auipc	ra,0xfffff
    8000174a:	432080e7          	jalr	1074(ra) # 80000b78 <kalloc>
    8000174e:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001750:	6605                	lui	a2,0x1
    80001752:	4581                	li	a1,0
    80001754:	00000097          	auipc	ra,0x0
    80001758:	984080e7          	jalr	-1660(ra) # 800010d8 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000175c:	4779                	li	a4,30
    8000175e:	86ca                	mv	a3,s2
    80001760:	6605                	lui	a2,0x1
    80001762:	4581                	li	a1,0
    80001764:	8552                	mv	a0,s4
    80001766:	00000097          	auipc	ra,0x0
    8000176a:	d4e080e7          	jalr	-690(ra) # 800014b4 <mappages>
  memmove(mem, src, sz);
    8000176e:	8626                	mv	a2,s1
    80001770:	85ce                	mv	a1,s3
    80001772:	854a                	mv	a0,s2
    80001774:	00000097          	auipc	ra,0x0
    80001778:	9c4080e7          	jalr	-1596(ra) # 80001138 <memmove>
}
    8000177c:	70a2                	ld	ra,40(sp)
    8000177e:	7402                	ld	s0,32(sp)
    80001780:	64e2                	ld	s1,24(sp)
    80001782:	6942                	ld	s2,16(sp)
    80001784:	69a2                	ld	s3,8(sp)
    80001786:	6a02                	ld	s4,0(sp)
    80001788:	6145                	addi	sp,sp,48
    8000178a:	8082                	ret
    panic("inituvm: more than a page");
    8000178c:	00007517          	auipc	a0,0x7
    80001790:	a4c50513          	addi	a0,a0,-1460 # 800081d8 <digits+0x198>
    80001794:	fffff097          	auipc	ra,0xfffff
    80001798:	dbc080e7          	jalr	-580(ra) # 80000550 <panic>

000000008000179c <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    8000179c:	1101                	addi	sp,sp,-32
    8000179e:	ec06                	sd	ra,24(sp)
    800017a0:	e822                	sd	s0,16(sp)
    800017a2:	e426                	sd	s1,8(sp)
    800017a4:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800017a6:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800017a8:	00b67d63          	bgeu	a2,a1,800017c2 <uvmdealloc+0x26>
    800017ac:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800017ae:	6785                	lui	a5,0x1
    800017b0:	17fd                	addi	a5,a5,-1
    800017b2:	00f60733          	add	a4,a2,a5
    800017b6:	767d                	lui	a2,0xfffff
    800017b8:	8f71                	and	a4,a4,a2
    800017ba:	97ae                	add	a5,a5,a1
    800017bc:	8ff1                	and	a5,a5,a2
    800017be:	00f76863          	bltu	a4,a5,800017ce <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800017c2:	8526                	mv	a0,s1
    800017c4:	60e2                	ld	ra,24(sp)
    800017c6:	6442                	ld	s0,16(sp)
    800017c8:	64a2                	ld	s1,8(sp)
    800017ca:	6105                	addi	sp,sp,32
    800017cc:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800017ce:	8f99                	sub	a5,a5,a4
    800017d0:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800017d2:	4685                	li	a3,1
    800017d4:	0007861b          	sext.w	a2,a5
    800017d8:	85ba                	mv	a1,a4
    800017da:	00000097          	auipc	ra,0x0
    800017de:	e5e080e7          	jalr	-418(ra) # 80001638 <uvmunmap>
    800017e2:	b7c5                	j	800017c2 <uvmdealloc+0x26>

00000000800017e4 <uvmalloc>:
  if(newsz < oldsz)
    800017e4:	0ab66163          	bltu	a2,a1,80001886 <uvmalloc+0xa2>
{
    800017e8:	7139                	addi	sp,sp,-64
    800017ea:	fc06                	sd	ra,56(sp)
    800017ec:	f822                	sd	s0,48(sp)
    800017ee:	f426                	sd	s1,40(sp)
    800017f0:	f04a                	sd	s2,32(sp)
    800017f2:	ec4e                	sd	s3,24(sp)
    800017f4:	e852                	sd	s4,16(sp)
    800017f6:	e456                	sd	s5,8(sp)
    800017f8:	0080                	addi	s0,sp,64
    800017fa:	8aaa                	mv	s5,a0
    800017fc:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    800017fe:	6985                	lui	s3,0x1
    80001800:	19fd                	addi	s3,s3,-1
    80001802:	95ce                	add	a1,a1,s3
    80001804:	79fd                	lui	s3,0xfffff
    80001806:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000180a:	08c9f063          	bgeu	s3,a2,8000188a <uvmalloc+0xa6>
    8000180e:	894e                	mv	s2,s3
    mem = kalloc();
    80001810:	fffff097          	auipc	ra,0xfffff
    80001814:	368080e7          	jalr	872(ra) # 80000b78 <kalloc>
    80001818:	84aa                	mv	s1,a0
    if(mem == 0){
    8000181a:	c51d                	beqz	a0,80001848 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000181c:	6605                	lui	a2,0x1
    8000181e:	4581                	li	a1,0
    80001820:	00000097          	auipc	ra,0x0
    80001824:	8b8080e7          	jalr	-1864(ra) # 800010d8 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001828:	4779                	li	a4,30
    8000182a:	86a6                	mv	a3,s1
    8000182c:	6605                	lui	a2,0x1
    8000182e:	85ca                	mv	a1,s2
    80001830:	8556                	mv	a0,s5
    80001832:	00000097          	auipc	ra,0x0
    80001836:	c82080e7          	jalr	-894(ra) # 800014b4 <mappages>
    8000183a:	e905                	bnez	a0,8000186a <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000183c:	6785                	lui	a5,0x1
    8000183e:	993e                	add	s2,s2,a5
    80001840:	fd4968e3          	bltu	s2,s4,80001810 <uvmalloc+0x2c>
  return newsz;
    80001844:	8552                	mv	a0,s4
    80001846:	a809                	j	80001858 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001848:	864e                	mv	a2,s3
    8000184a:	85ca                	mv	a1,s2
    8000184c:	8556                	mv	a0,s5
    8000184e:	00000097          	auipc	ra,0x0
    80001852:	f4e080e7          	jalr	-178(ra) # 8000179c <uvmdealloc>
      return 0;
    80001856:	4501                	li	a0,0
}
    80001858:	70e2                	ld	ra,56(sp)
    8000185a:	7442                	ld	s0,48(sp)
    8000185c:	74a2                	ld	s1,40(sp)
    8000185e:	7902                	ld	s2,32(sp)
    80001860:	69e2                	ld	s3,24(sp)
    80001862:	6a42                	ld	s4,16(sp)
    80001864:	6aa2                	ld	s5,8(sp)
    80001866:	6121                	addi	sp,sp,64
    80001868:	8082                	ret
      kfree(mem);
    8000186a:	8526                	mv	a0,s1
    8000186c:	fffff097          	auipc	ra,0xfffff
    80001870:	1c0080e7          	jalr	448(ra) # 80000a2c <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001874:	864e                	mv	a2,s3
    80001876:	85ca                	mv	a1,s2
    80001878:	8556                	mv	a0,s5
    8000187a:	00000097          	auipc	ra,0x0
    8000187e:	f22080e7          	jalr	-222(ra) # 8000179c <uvmdealloc>
      return 0;
    80001882:	4501                	li	a0,0
    80001884:	bfd1                	j	80001858 <uvmalloc+0x74>
    return oldsz;
    80001886:	852e                	mv	a0,a1
}
    80001888:	8082                	ret
  return newsz;
    8000188a:	8532                	mv	a0,a2
    8000188c:	b7f1                	j	80001858 <uvmalloc+0x74>

000000008000188e <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    8000188e:	7179                	addi	sp,sp,-48
    80001890:	f406                	sd	ra,40(sp)
    80001892:	f022                	sd	s0,32(sp)
    80001894:	ec26                	sd	s1,24(sp)
    80001896:	e84a                	sd	s2,16(sp)
    80001898:	e44e                	sd	s3,8(sp)
    8000189a:	e052                	sd	s4,0(sp)
    8000189c:	1800                	addi	s0,sp,48
    8000189e:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800018a0:	84aa                	mv	s1,a0
    800018a2:	6905                	lui	s2,0x1
    800018a4:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800018a6:	4985                	li	s3,1
    800018a8:	a821                	j	800018c0 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800018aa:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800018ac:	0532                	slli	a0,a0,0xc
    800018ae:	00000097          	auipc	ra,0x0
    800018b2:	fe0080e7          	jalr	-32(ra) # 8000188e <freewalk>
      pagetable[i] = 0;
    800018b6:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800018ba:	04a1                	addi	s1,s1,8
    800018bc:	03248163          	beq	s1,s2,800018de <freewalk+0x50>
    pte_t pte = pagetable[i];
    800018c0:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800018c2:	00f57793          	andi	a5,a0,15
    800018c6:	ff3782e3          	beq	a5,s3,800018aa <freewalk+0x1c>
    } else if(pte & PTE_V){
    800018ca:	8905                	andi	a0,a0,1
    800018cc:	d57d                	beqz	a0,800018ba <freewalk+0x2c>
      panic("freewalk: leaf");
    800018ce:	00007517          	auipc	a0,0x7
    800018d2:	92a50513          	addi	a0,a0,-1750 # 800081f8 <digits+0x1b8>
    800018d6:	fffff097          	auipc	ra,0xfffff
    800018da:	c7a080e7          	jalr	-902(ra) # 80000550 <panic>
    }
  }
  kfree((void*)pagetable);
    800018de:	8552                	mv	a0,s4
    800018e0:	fffff097          	auipc	ra,0xfffff
    800018e4:	14c080e7          	jalr	332(ra) # 80000a2c <kfree>
}
    800018e8:	70a2                	ld	ra,40(sp)
    800018ea:	7402                	ld	s0,32(sp)
    800018ec:	64e2                	ld	s1,24(sp)
    800018ee:	6942                	ld	s2,16(sp)
    800018f0:	69a2                	ld	s3,8(sp)
    800018f2:	6a02                	ld	s4,0(sp)
    800018f4:	6145                	addi	sp,sp,48
    800018f6:	8082                	ret

00000000800018f8 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800018f8:	1101                	addi	sp,sp,-32
    800018fa:	ec06                	sd	ra,24(sp)
    800018fc:	e822                	sd	s0,16(sp)
    800018fe:	e426                	sd	s1,8(sp)
    80001900:	1000                	addi	s0,sp,32
    80001902:	84aa                	mv	s1,a0
  if(sz > 0)
    80001904:	e999                	bnez	a1,8000191a <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001906:	8526                	mv	a0,s1
    80001908:	00000097          	auipc	ra,0x0
    8000190c:	f86080e7          	jalr	-122(ra) # 8000188e <freewalk>
}
    80001910:	60e2                	ld	ra,24(sp)
    80001912:	6442                	ld	s0,16(sp)
    80001914:	64a2                	ld	s1,8(sp)
    80001916:	6105                	addi	sp,sp,32
    80001918:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000191a:	6605                	lui	a2,0x1
    8000191c:	167d                	addi	a2,a2,-1
    8000191e:	962e                	add	a2,a2,a1
    80001920:	4685                	li	a3,1
    80001922:	8231                	srli	a2,a2,0xc
    80001924:	4581                	li	a1,0
    80001926:	00000097          	auipc	ra,0x0
    8000192a:	d12080e7          	jalr	-750(ra) # 80001638 <uvmunmap>
    8000192e:	bfe1                	j	80001906 <uvmfree+0xe>

0000000080001930 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001930:	c679                	beqz	a2,800019fe <uvmcopy+0xce>
{
    80001932:	715d                	addi	sp,sp,-80
    80001934:	e486                	sd	ra,72(sp)
    80001936:	e0a2                	sd	s0,64(sp)
    80001938:	fc26                	sd	s1,56(sp)
    8000193a:	f84a                	sd	s2,48(sp)
    8000193c:	f44e                	sd	s3,40(sp)
    8000193e:	f052                	sd	s4,32(sp)
    80001940:	ec56                	sd	s5,24(sp)
    80001942:	e85a                	sd	s6,16(sp)
    80001944:	e45e                	sd	s7,8(sp)
    80001946:	0880                	addi	s0,sp,80
    80001948:	8b2a                	mv	s6,a0
    8000194a:	8aae                	mv	s5,a1
    8000194c:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000194e:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001950:	4601                	li	a2,0
    80001952:	85ce                	mv	a1,s3
    80001954:	855a                	mv	a0,s6
    80001956:	00000097          	auipc	ra,0x0
    8000195a:	a52080e7          	jalr	-1454(ra) # 800013a8 <walk>
    8000195e:	c531                	beqz	a0,800019aa <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001960:	6118                	ld	a4,0(a0)
    80001962:	00177793          	andi	a5,a4,1
    80001966:	cbb1                	beqz	a5,800019ba <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001968:	00a75593          	srli	a1,a4,0xa
    8000196c:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001970:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    80001974:	fffff097          	auipc	ra,0xfffff
    80001978:	204080e7          	jalr	516(ra) # 80000b78 <kalloc>
    8000197c:	892a                	mv	s2,a0
    8000197e:	c939                	beqz	a0,800019d4 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    80001980:	6605                	lui	a2,0x1
    80001982:	85de                	mv	a1,s7
    80001984:	fffff097          	auipc	ra,0xfffff
    80001988:	7b4080e7          	jalr	1972(ra) # 80001138 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    8000198c:	8726                	mv	a4,s1
    8000198e:	86ca                	mv	a3,s2
    80001990:	6605                	lui	a2,0x1
    80001992:	85ce                	mv	a1,s3
    80001994:	8556                	mv	a0,s5
    80001996:	00000097          	auipc	ra,0x0
    8000199a:	b1e080e7          	jalr	-1250(ra) # 800014b4 <mappages>
    8000199e:	e515                	bnez	a0,800019ca <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800019a0:	6785                	lui	a5,0x1
    800019a2:	99be                	add	s3,s3,a5
    800019a4:	fb49e6e3          	bltu	s3,s4,80001950 <uvmcopy+0x20>
    800019a8:	a081                	j	800019e8 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800019aa:	00007517          	auipc	a0,0x7
    800019ae:	85e50513          	addi	a0,a0,-1954 # 80008208 <digits+0x1c8>
    800019b2:	fffff097          	auipc	ra,0xfffff
    800019b6:	b9e080e7          	jalr	-1122(ra) # 80000550 <panic>
      panic("uvmcopy: page not present");
    800019ba:	00007517          	auipc	a0,0x7
    800019be:	86e50513          	addi	a0,a0,-1938 # 80008228 <digits+0x1e8>
    800019c2:	fffff097          	auipc	ra,0xfffff
    800019c6:	b8e080e7          	jalr	-1138(ra) # 80000550 <panic>
      kfree(mem);
    800019ca:	854a                	mv	a0,s2
    800019cc:	fffff097          	auipc	ra,0xfffff
    800019d0:	060080e7          	jalr	96(ra) # 80000a2c <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800019d4:	4685                	li	a3,1
    800019d6:	00c9d613          	srli	a2,s3,0xc
    800019da:	4581                	li	a1,0
    800019dc:	8556                	mv	a0,s5
    800019de:	00000097          	auipc	ra,0x0
    800019e2:	c5a080e7          	jalr	-934(ra) # 80001638 <uvmunmap>
  return -1;
    800019e6:	557d                	li	a0,-1
}
    800019e8:	60a6                	ld	ra,72(sp)
    800019ea:	6406                	ld	s0,64(sp)
    800019ec:	74e2                	ld	s1,56(sp)
    800019ee:	7942                	ld	s2,48(sp)
    800019f0:	79a2                	ld	s3,40(sp)
    800019f2:	7a02                	ld	s4,32(sp)
    800019f4:	6ae2                	ld	s5,24(sp)
    800019f6:	6b42                	ld	s6,16(sp)
    800019f8:	6ba2                	ld	s7,8(sp)
    800019fa:	6161                	addi	sp,sp,80
    800019fc:	8082                	ret
  return 0;
    800019fe:	4501                	li	a0,0
}
    80001a00:	8082                	ret

0000000080001a02 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001a02:	1141                	addi	sp,sp,-16
    80001a04:	e406                	sd	ra,8(sp)
    80001a06:	e022                	sd	s0,0(sp)
    80001a08:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001a0a:	4601                	li	a2,0
    80001a0c:	00000097          	auipc	ra,0x0
    80001a10:	99c080e7          	jalr	-1636(ra) # 800013a8 <walk>
  if(pte == 0)
    80001a14:	c901                	beqz	a0,80001a24 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001a16:	611c                	ld	a5,0(a0)
    80001a18:	9bbd                	andi	a5,a5,-17
    80001a1a:	e11c                	sd	a5,0(a0)
}
    80001a1c:	60a2                	ld	ra,8(sp)
    80001a1e:	6402                	ld	s0,0(sp)
    80001a20:	0141                	addi	sp,sp,16
    80001a22:	8082                	ret
    panic("uvmclear");
    80001a24:	00007517          	auipc	a0,0x7
    80001a28:	82450513          	addi	a0,a0,-2012 # 80008248 <digits+0x208>
    80001a2c:	fffff097          	auipc	ra,0xfffff
    80001a30:	b24080e7          	jalr	-1244(ra) # 80000550 <panic>

0000000080001a34 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001a34:	c6bd                	beqz	a3,80001aa2 <copyout+0x6e>
{
    80001a36:	715d                	addi	sp,sp,-80
    80001a38:	e486                	sd	ra,72(sp)
    80001a3a:	e0a2                	sd	s0,64(sp)
    80001a3c:	fc26                	sd	s1,56(sp)
    80001a3e:	f84a                	sd	s2,48(sp)
    80001a40:	f44e                	sd	s3,40(sp)
    80001a42:	f052                	sd	s4,32(sp)
    80001a44:	ec56                	sd	s5,24(sp)
    80001a46:	e85a                	sd	s6,16(sp)
    80001a48:	e45e                	sd	s7,8(sp)
    80001a4a:	e062                	sd	s8,0(sp)
    80001a4c:	0880                	addi	s0,sp,80
    80001a4e:	8b2a                	mv	s6,a0
    80001a50:	8c2e                	mv	s8,a1
    80001a52:	8a32                	mv	s4,a2
    80001a54:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001a56:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001a58:	6a85                	lui	s5,0x1
    80001a5a:	a015                	j	80001a7e <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001a5c:	9562                	add	a0,a0,s8
    80001a5e:	0004861b          	sext.w	a2,s1
    80001a62:	85d2                	mv	a1,s4
    80001a64:	41250533          	sub	a0,a0,s2
    80001a68:	fffff097          	auipc	ra,0xfffff
    80001a6c:	6d0080e7          	jalr	1744(ra) # 80001138 <memmove>

    len -= n;
    80001a70:	409989b3          	sub	s3,s3,s1
    src += n;
    80001a74:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001a76:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001a7a:	02098263          	beqz	s3,80001a9e <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    80001a7e:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001a82:	85ca                	mv	a1,s2
    80001a84:	855a                	mv	a0,s6
    80001a86:	00000097          	auipc	ra,0x0
    80001a8a:	9ec080e7          	jalr	-1556(ra) # 80001472 <walkaddr>
    if(pa0 == 0)
    80001a8e:	cd01                	beqz	a0,80001aa6 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001a90:	418904b3          	sub	s1,s2,s8
    80001a94:	94d6                	add	s1,s1,s5
    if(n > len)
    80001a96:	fc99f3e3          	bgeu	s3,s1,80001a5c <copyout+0x28>
    80001a9a:	84ce                	mv	s1,s3
    80001a9c:	b7c1                	j	80001a5c <copyout+0x28>
  }
  return 0;
    80001a9e:	4501                	li	a0,0
    80001aa0:	a021                	j	80001aa8 <copyout+0x74>
    80001aa2:	4501                	li	a0,0
}
    80001aa4:	8082                	ret
      return -1;
    80001aa6:	557d                	li	a0,-1
}
    80001aa8:	60a6                	ld	ra,72(sp)
    80001aaa:	6406                	ld	s0,64(sp)
    80001aac:	74e2                	ld	s1,56(sp)
    80001aae:	7942                	ld	s2,48(sp)
    80001ab0:	79a2                	ld	s3,40(sp)
    80001ab2:	7a02                	ld	s4,32(sp)
    80001ab4:	6ae2                	ld	s5,24(sp)
    80001ab6:	6b42                	ld	s6,16(sp)
    80001ab8:	6ba2                	ld	s7,8(sp)
    80001aba:	6c02                	ld	s8,0(sp)
    80001abc:	6161                	addi	sp,sp,80
    80001abe:	8082                	ret

0000000080001ac0 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001ac0:	c6bd                	beqz	a3,80001b2e <copyin+0x6e>
{
    80001ac2:	715d                	addi	sp,sp,-80
    80001ac4:	e486                	sd	ra,72(sp)
    80001ac6:	e0a2                	sd	s0,64(sp)
    80001ac8:	fc26                	sd	s1,56(sp)
    80001aca:	f84a                	sd	s2,48(sp)
    80001acc:	f44e                	sd	s3,40(sp)
    80001ace:	f052                	sd	s4,32(sp)
    80001ad0:	ec56                	sd	s5,24(sp)
    80001ad2:	e85a                	sd	s6,16(sp)
    80001ad4:	e45e                	sd	s7,8(sp)
    80001ad6:	e062                	sd	s8,0(sp)
    80001ad8:	0880                	addi	s0,sp,80
    80001ada:	8b2a                	mv	s6,a0
    80001adc:	8a2e                	mv	s4,a1
    80001ade:	8c32                	mv	s8,a2
    80001ae0:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001ae2:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001ae4:	6a85                	lui	s5,0x1
    80001ae6:	a015                	j	80001b0a <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001ae8:	9562                	add	a0,a0,s8
    80001aea:	0004861b          	sext.w	a2,s1
    80001aee:	412505b3          	sub	a1,a0,s2
    80001af2:	8552                	mv	a0,s4
    80001af4:	fffff097          	auipc	ra,0xfffff
    80001af8:	644080e7          	jalr	1604(ra) # 80001138 <memmove>

    len -= n;
    80001afc:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001b00:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001b02:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001b06:	02098263          	beqz	s3,80001b2a <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    80001b0a:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001b0e:	85ca                	mv	a1,s2
    80001b10:	855a                	mv	a0,s6
    80001b12:	00000097          	auipc	ra,0x0
    80001b16:	960080e7          	jalr	-1696(ra) # 80001472 <walkaddr>
    if(pa0 == 0)
    80001b1a:	cd01                	beqz	a0,80001b32 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    80001b1c:	418904b3          	sub	s1,s2,s8
    80001b20:	94d6                	add	s1,s1,s5
    if(n > len)
    80001b22:	fc99f3e3          	bgeu	s3,s1,80001ae8 <copyin+0x28>
    80001b26:	84ce                	mv	s1,s3
    80001b28:	b7c1                	j	80001ae8 <copyin+0x28>
  }
  return 0;
    80001b2a:	4501                	li	a0,0
    80001b2c:	a021                	j	80001b34 <copyin+0x74>
    80001b2e:	4501                	li	a0,0
}
    80001b30:	8082                	ret
      return -1;
    80001b32:	557d                	li	a0,-1
}
    80001b34:	60a6                	ld	ra,72(sp)
    80001b36:	6406                	ld	s0,64(sp)
    80001b38:	74e2                	ld	s1,56(sp)
    80001b3a:	7942                	ld	s2,48(sp)
    80001b3c:	79a2                	ld	s3,40(sp)
    80001b3e:	7a02                	ld	s4,32(sp)
    80001b40:	6ae2                	ld	s5,24(sp)
    80001b42:	6b42                	ld	s6,16(sp)
    80001b44:	6ba2                	ld	s7,8(sp)
    80001b46:	6c02                	ld	s8,0(sp)
    80001b48:	6161                	addi	sp,sp,80
    80001b4a:	8082                	ret

0000000080001b4c <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001b4c:	c6c5                	beqz	a3,80001bf4 <copyinstr+0xa8>
{
    80001b4e:	715d                	addi	sp,sp,-80
    80001b50:	e486                	sd	ra,72(sp)
    80001b52:	e0a2                	sd	s0,64(sp)
    80001b54:	fc26                	sd	s1,56(sp)
    80001b56:	f84a                	sd	s2,48(sp)
    80001b58:	f44e                	sd	s3,40(sp)
    80001b5a:	f052                	sd	s4,32(sp)
    80001b5c:	ec56                	sd	s5,24(sp)
    80001b5e:	e85a                	sd	s6,16(sp)
    80001b60:	e45e                	sd	s7,8(sp)
    80001b62:	0880                	addi	s0,sp,80
    80001b64:	8a2a                	mv	s4,a0
    80001b66:	8b2e                	mv	s6,a1
    80001b68:	8bb2                	mv	s7,a2
    80001b6a:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001b6c:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001b6e:	6985                	lui	s3,0x1
    80001b70:	a035                	j	80001b9c <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001b72:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001b76:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001b78:	0017b793          	seqz	a5,a5
    80001b7c:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001b80:	60a6                	ld	ra,72(sp)
    80001b82:	6406                	ld	s0,64(sp)
    80001b84:	74e2                	ld	s1,56(sp)
    80001b86:	7942                	ld	s2,48(sp)
    80001b88:	79a2                	ld	s3,40(sp)
    80001b8a:	7a02                	ld	s4,32(sp)
    80001b8c:	6ae2                	ld	s5,24(sp)
    80001b8e:	6b42                	ld	s6,16(sp)
    80001b90:	6ba2                	ld	s7,8(sp)
    80001b92:	6161                	addi	sp,sp,80
    80001b94:	8082                	ret
    srcva = va0 + PGSIZE;
    80001b96:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001b9a:	c8a9                	beqz	s1,80001bec <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    80001b9c:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001ba0:	85ca                	mv	a1,s2
    80001ba2:	8552                	mv	a0,s4
    80001ba4:	00000097          	auipc	ra,0x0
    80001ba8:	8ce080e7          	jalr	-1842(ra) # 80001472 <walkaddr>
    if(pa0 == 0)
    80001bac:	c131                	beqz	a0,80001bf0 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    80001bae:	41790833          	sub	a6,s2,s7
    80001bb2:	984e                	add	a6,a6,s3
    if(n > max)
    80001bb4:	0104f363          	bgeu	s1,a6,80001bba <copyinstr+0x6e>
    80001bb8:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001bba:	955e                	add	a0,a0,s7
    80001bbc:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001bc0:	fc080be3          	beqz	a6,80001b96 <copyinstr+0x4a>
    80001bc4:	985a                	add	a6,a6,s6
    80001bc6:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001bc8:	41650633          	sub	a2,a0,s6
    80001bcc:	14fd                	addi	s1,s1,-1
    80001bce:	9b26                	add	s6,s6,s1
    80001bd0:	00f60733          	add	a4,a2,a5
    80001bd4:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd6fd8>
    80001bd8:	df49                	beqz	a4,80001b72 <copyinstr+0x26>
        *dst = *p;
    80001bda:	00e78023          	sb	a4,0(a5)
      --max;
    80001bde:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001be2:	0785                	addi	a5,a5,1
    while(n > 0){
    80001be4:	ff0796e3          	bne	a5,a6,80001bd0 <copyinstr+0x84>
      dst++;
    80001be8:	8b42                	mv	s6,a6
    80001bea:	b775                	j	80001b96 <copyinstr+0x4a>
    80001bec:	4781                	li	a5,0
    80001bee:	b769                	j	80001b78 <copyinstr+0x2c>
      return -1;
    80001bf0:	557d                	li	a0,-1
    80001bf2:	b779                	j	80001b80 <copyinstr+0x34>
  int got_null = 0;
    80001bf4:	4781                	li	a5,0
  if(got_null){
    80001bf6:	0017b793          	seqz	a5,a5
    80001bfa:	40f00533          	neg	a0,a5
}
    80001bfe:	8082                	ret

0000000080001c00 <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    80001c00:	1101                	addi	sp,sp,-32
    80001c02:	ec06                	sd	ra,24(sp)
    80001c04:	e822                	sd	s0,16(sp)
    80001c06:	e426                	sd	s1,8(sp)
    80001c08:	1000                	addi	s0,sp,32
    80001c0a:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001c0c:	fffff097          	auipc	ra,0xfffff
    80001c10:	072080e7          	jalr	114(ra) # 80000c7e <holding>
    80001c14:	c909                	beqz	a0,80001c26 <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    80001c16:	789c                	ld	a5,48(s1)
    80001c18:	00978f63          	beq	a5,s1,80001c36 <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    80001c1c:	60e2                	ld	ra,24(sp)
    80001c1e:	6442                	ld	s0,16(sp)
    80001c20:	64a2                	ld	s1,8(sp)
    80001c22:	6105                	addi	sp,sp,32
    80001c24:	8082                	ret
    panic("wakeup1");
    80001c26:	00006517          	auipc	a0,0x6
    80001c2a:	63250513          	addi	a0,a0,1586 # 80008258 <digits+0x218>
    80001c2e:	fffff097          	auipc	ra,0xfffff
    80001c32:	922080e7          	jalr	-1758(ra) # 80000550 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    80001c36:	5098                	lw	a4,32(s1)
    80001c38:	4785                	li	a5,1
    80001c3a:	fef711e3          	bne	a4,a5,80001c1c <wakeup1+0x1c>
    p->state = RUNNABLE;
    80001c3e:	4789                	li	a5,2
    80001c40:	d09c                	sw	a5,32(s1)
}
    80001c42:	bfe9                	j	80001c1c <wakeup1+0x1c>

0000000080001c44 <procinit>:
{
    80001c44:	715d                	addi	sp,sp,-80
    80001c46:	e486                	sd	ra,72(sp)
    80001c48:	e0a2                	sd	s0,64(sp)
    80001c4a:	fc26                	sd	s1,56(sp)
    80001c4c:	f84a                	sd	s2,48(sp)
    80001c4e:	f44e                	sd	s3,40(sp)
    80001c50:	f052                	sd	s4,32(sp)
    80001c52:	ec56                	sd	s5,24(sp)
    80001c54:	e85a                	sd	s6,16(sp)
    80001c56:	e45e                	sd	s7,8(sp)
    80001c58:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    80001c5a:	00006597          	auipc	a1,0x6
    80001c5e:	60658593          	addi	a1,a1,1542 # 80008260 <digits+0x220>
    80001c62:	00010517          	auipc	a0,0x10
    80001c66:	72650513          	addi	a0,a0,1830 # 80012388 <pid_lock>
    80001c6a:	fffff097          	auipc	ra,0xfffff
    80001c6e:	20a080e7          	jalr	522(ra) # 80000e74 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c72:	00011917          	auipc	s2,0x11
    80001c76:	b3690913          	addi	s2,s2,-1226 # 800127a8 <proc>
      initlock(&p->lock, "proc");
    80001c7a:	00006b97          	auipc	s7,0x6
    80001c7e:	5eeb8b93          	addi	s7,s7,1518 # 80008268 <digits+0x228>
      uint64 va = KSTACK((int) (p - proc));
    80001c82:	8b4a                	mv	s6,s2
    80001c84:	00006a97          	auipc	s5,0x6
    80001c88:	37ca8a93          	addi	s5,s5,892 # 80008000 <etext>
    80001c8c:	040009b7          	lui	s3,0x4000
    80001c90:	19fd                	addi	s3,s3,-1
    80001c92:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c94:	00016a17          	auipc	s4,0x16
    80001c98:	714a0a13          	addi	s4,s4,1812 # 800183a8 <tickslock>
      initlock(&p->lock, "proc");
    80001c9c:	85de                	mv	a1,s7
    80001c9e:	854a                	mv	a0,s2
    80001ca0:	fffff097          	auipc	ra,0xfffff
    80001ca4:	1d4080e7          	jalr	468(ra) # 80000e74 <initlock>
      char *pa = kalloc();
    80001ca8:	fffff097          	auipc	ra,0xfffff
    80001cac:	ed0080e7          	jalr	-304(ra) # 80000b78 <kalloc>
    80001cb0:	85aa                	mv	a1,a0
      if(pa == 0)
    80001cb2:	c929                	beqz	a0,80001d04 <procinit+0xc0>
      uint64 va = KSTACK((int) (p - proc));
    80001cb4:	416904b3          	sub	s1,s2,s6
    80001cb8:	8491                	srai	s1,s1,0x4
    80001cba:	000ab783          	ld	a5,0(s5)
    80001cbe:	02f484b3          	mul	s1,s1,a5
    80001cc2:	2485                	addiw	s1,s1,1
    80001cc4:	00d4949b          	slliw	s1,s1,0xd
    80001cc8:	409984b3          	sub	s1,s3,s1
      kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001ccc:	4699                	li	a3,6
    80001cce:	6605                	lui	a2,0x1
    80001cd0:	8526                	mv	a0,s1
    80001cd2:	00000097          	auipc	ra,0x0
    80001cd6:	870080e7          	jalr	-1936(ra) # 80001542 <kvmmap>
      p->kstack = va;
    80001cda:	04993423          	sd	s1,72(s2)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001cde:	17090913          	addi	s2,s2,368
    80001ce2:	fb491de3          	bne	s2,s4,80001c9c <procinit+0x58>
  kvminithart();
    80001ce6:	fffff097          	auipc	ra,0xfffff
    80001cea:	768080e7          	jalr	1896(ra) # 8000144e <kvminithart>
}
    80001cee:	60a6                	ld	ra,72(sp)
    80001cf0:	6406                	ld	s0,64(sp)
    80001cf2:	74e2                	ld	s1,56(sp)
    80001cf4:	7942                	ld	s2,48(sp)
    80001cf6:	79a2                	ld	s3,40(sp)
    80001cf8:	7a02                	ld	s4,32(sp)
    80001cfa:	6ae2                	ld	s5,24(sp)
    80001cfc:	6b42                	ld	s6,16(sp)
    80001cfe:	6ba2                	ld	s7,8(sp)
    80001d00:	6161                	addi	sp,sp,80
    80001d02:	8082                	ret
        panic("kalloc");
    80001d04:	00006517          	auipc	a0,0x6
    80001d08:	56c50513          	addi	a0,a0,1388 # 80008270 <digits+0x230>
    80001d0c:	fffff097          	auipc	ra,0xfffff
    80001d10:	844080e7          	jalr	-1980(ra) # 80000550 <panic>

0000000080001d14 <cpuid>:
{
    80001d14:	1141                	addi	sp,sp,-16
    80001d16:	e422                	sd	s0,8(sp)
    80001d18:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001d1a:	8512                	mv	a0,tp
}
    80001d1c:	2501                	sext.w	a0,a0
    80001d1e:	6422                	ld	s0,8(sp)
    80001d20:	0141                	addi	sp,sp,16
    80001d22:	8082                	ret

0000000080001d24 <mycpu>:
mycpu(void) {
    80001d24:	1141                	addi	sp,sp,-16
    80001d26:	e422                	sd	s0,8(sp)
    80001d28:	0800                	addi	s0,sp,16
    80001d2a:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001d2c:	2781                	sext.w	a5,a5
    80001d2e:	079e                	slli	a5,a5,0x7
}
    80001d30:	00010517          	auipc	a0,0x10
    80001d34:	67850513          	addi	a0,a0,1656 # 800123a8 <cpus>
    80001d38:	953e                	add	a0,a0,a5
    80001d3a:	6422                	ld	s0,8(sp)
    80001d3c:	0141                	addi	sp,sp,16
    80001d3e:	8082                	ret

0000000080001d40 <myproc>:
myproc(void) {
    80001d40:	1101                	addi	sp,sp,-32
    80001d42:	ec06                	sd	ra,24(sp)
    80001d44:	e822                	sd	s0,16(sp)
    80001d46:	e426                	sd	s1,8(sp)
    80001d48:	1000                	addi	s0,sp,32
  push_off();
    80001d4a:	fffff097          	auipc	ra,0xfffff
    80001d4e:	f62080e7          	jalr	-158(ra) # 80000cac <push_off>
    80001d52:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001d54:	2781                	sext.w	a5,a5
    80001d56:	079e                	slli	a5,a5,0x7
    80001d58:	00010717          	auipc	a4,0x10
    80001d5c:	63070713          	addi	a4,a4,1584 # 80012388 <pid_lock>
    80001d60:	97ba                	add	a5,a5,a4
    80001d62:	7384                	ld	s1,32(a5)
  pop_off();
    80001d64:	fffff097          	auipc	ra,0xfffff
    80001d68:	004080e7          	jalr	4(ra) # 80000d68 <pop_off>
}
    80001d6c:	8526                	mv	a0,s1
    80001d6e:	60e2                	ld	ra,24(sp)
    80001d70:	6442                	ld	s0,16(sp)
    80001d72:	64a2                	ld	s1,8(sp)
    80001d74:	6105                	addi	sp,sp,32
    80001d76:	8082                	ret

0000000080001d78 <forkret>:
{
    80001d78:	1141                	addi	sp,sp,-16
    80001d7a:	e406                	sd	ra,8(sp)
    80001d7c:	e022                	sd	s0,0(sp)
    80001d7e:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001d80:	00000097          	auipc	ra,0x0
    80001d84:	fc0080e7          	jalr	-64(ra) # 80001d40 <myproc>
    80001d88:	fffff097          	auipc	ra,0xfffff
    80001d8c:	040080e7          	jalr	64(ra) # 80000dc8 <release>
  if (first) {
    80001d90:	00007797          	auipc	a5,0x7
    80001d94:	b207a783          	lw	a5,-1248(a5) # 800088b0 <first.1672>
    80001d98:	eb89                	bnez	a5,80001daa <forkret+0x32>
  usertrapret();
    80001d9a:	00001097          	auipc	ra,0x1
    80001d9e:	c1c080e7          	jalr	-996(ra) # 800029b6 <usertrapret>
}
    80001da2:	60a2                	ld	ra,8(sp)
    80001da4:	6402                	ld	s0,0(sp)
    80001da6:	0141                	addi	sp,sp,16
    80001da8:	8082                	ret
    first = 0;
    80001daa:	00007797          	auipc	a5,0x7
    80001dae:	b007a323          	sw	zero,-1274(a5) # 800088b0 <first.1672>
    fsinit(ROOTDEV);
    80001db2:	4505                	li	a0,1
    80001db4:	00002097          	auipc	ra,0x2
    80001db8:	944080e7          	jalr	-1724(ra) # 800036f8 <fsinit>
    80001dbc:	bff9                	j	80001d9a <forkret+0x22>

0000000080001dbe <allocpid>:
allocpid() {
    80001dbe:	1101                	addi	sp,sp,-32
    80001dc0:	ec06                	sd	ra,24(sp)
    80001dc2:	e822                	sd	s0,16(sp)
    80001dc4:	e426                	sd	s1,8(sp)
    80001dc6:	e04a                	sd	s2,0(sp)
    80001dc8:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001dca:	00010917          	auipc	s2,0x10
    80001dce:	5be90913          	addi	s2,s2,1470 # 80012388 <pid_lock>
    80001dd2:	854a                	mv	a0,s2
    80001dd4:	fffff097          	auipc	ra,0xfffff
    80001dd8:	f24080e7          	jalr	-220(ra) # 80000cf8 <acquire>
  pid = nextpid;
    80001ddc:	00007797          	auipc	a5,0x7
    80001de0:	ad878793          	addi	a5,a5,-1320 # 800088b4 <nextpid>
    80001de4:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001de6:	0014871b          	addiw	a4,s1,1
    80001dea:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001dec:	854a                	mv	a0,s2
    80001dee:	fffff097          	auipc	ra,0xfffff
    80001df2:	fda080e7          	jalr	-38(ra) # 80000dc8 <release>
}
    80001df6:	8526                	mv	a0,s1
    80001df8:	60e2                	ld	ra,24(sp)
    80001dfa:	6442                	ld	s0,16(sp)
    80001dfc:	64a2                	ld	s1,8(sp)
    80001dfe:	6902                	ld	s2,0(sp)
    80001e00:	6105                	addi	sp,sp,32
    80001e02:	8082                	ret

0000000080001e04 <proc_pagetable>:
{
    80001e04:	1101                	addi	sp,sp,-32
    80001e06:	ec06                	sd	ra,24(sp)
    80001e08:	e822                	sd	s0,16(sp)
    80001e0a:	e426                	sd	s1,8(sp)
    80001e0c:	e04a                	sd	s2,0(sp)
    80001e0e:	1000                	addi	s0,sp,32
    80001e10:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001e12:	00000097          	auipc	ra,0x0
    80001e16:	8ea080e7          	jalr	-1814(ra) # 800016fc <uvmcreate>
    80001e1a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001e1c:	c121                	beqz	a0,80001e5c <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001e1e:	4729                	li	a4,10
    80001e20:	00005697          	auipc	a3,0x5
    80001e24:	1e068693          	addi	a3,a3,480 # 80007000 <_trampoline>
    80001e28:	6605                	lui	a2,0x1
    80001e2a:	040005b7          	lui	a1,0x4000
    80001e2e:	15fd                	addi	a1,a1,-1
    80001e30:	05b2                	slli	a1,a1,0xc
    80001e32:	fffff097          	auipc	ra,0xfffff
    80001e36:	682080e7          	jalr	1666(ra) # 800014b4 <mappages>
    80001e3a:	02054863          	bltz	a0,80001e6a <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001e3e:	4719                	li	a4,6
    80001e40:	06093683          	ld	a3,96(s2)
    80001e44:	6605                	lui	a2,0x1
    80001e46:	020005b7          	lui	a1,0x2000
    80001e4a:	15fd                	addi	a1,a1,-1
    80001e4c:	05b6                	slli	a1,a1,0xd
    80001e4e:	8526                	mv	a0,s1
    80001e50:	fffff097          	auipc	ra,0xfffff
    80001e54:	664080e7          	jalr	1636(ra) # 800014b4 <mappages>
    80001e58:	02054163          	bltz	a0,80001e7a <proc_pagetable+0x76>
}
    80001e5c:	8526                	mv	a0,s1
    80001e5e:	60e2                	ld	ra,24(sp)
    80001e60:	6442                	ld	s0,16(sp)
    80001e62:	64a2                	ld	s1,8(sp)
    80001e64:	6902                	ld	s2,0(sp)
    80001e66:	6105                	addi	sp,sp,32
    80001e68:	8082                	ret
    uvmfree(pagetable, 0);
    80001e6a:	4581                	li	a1,0
    80001e6c:	8526                	mv	a0,s1
    80001e6e:	00000097          	auipc	ra,0x0
    80001e72:	a8a080e7          	jalr	-1398(ra) # 800018f8 <uvmfree>
    return 0;
    80001e76:	4481                	li	s1,0
    80001e78:	b7d5                	j	80001e5c <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001e7a:	4681                	li	a3,0
    80001e7c:	4605                	li	a2,1
    80001e7e:	040005b7          	lui	a1,0x4000
    80001e82:	15fd                	addi	a1,a1,-1
    80001e84:	05b2                	slli	a1,a1,0xc
    80001e86:	8526                	mv	a0,s1
    80001e88:	fffff097          	auipc	ra,0xfffff
    80001e8c:	7b0080e7          	jalr	1968(ra) # 80001638 <uvmunmap>
    uvmfree(pagetable, 0);
    80001e90:	4581                	li	a1,0
    80001e92:	8526                	mv	a0,s1
    80001e94:	00000097          	auipc	ra,0x0
    80001e98:	a64080e7          	jalr	-1436(ra) # 800018f8 <uvmfree>
    return 0;
    80001e9c:	4481                	li	s1,0
    80001e9e:	bf7d                	j	80001e5c <proc_pagetable+0x58>

0000000080001ea0 <proc_freepagetable>:
{
    80001ea0:	1101                	addi	sp,sp,-32
    80001ea2:	ec06                	sd	ra,24(sp)
    80001ea4:	e822                	sd	s0,16(sp)
    80001ea6:	e426                	sd	s1,8(sp)
    80001ea8:	e04a                	sd	s2,0(sp)
    80001eaa:	1000                	addi	s0,sp,32
    80001eac:	84aa                	mv	s1,a0
    80001eae:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001eb0:	4681                	li	a3,0
    80001eb2:	4605                	li	a2,1
    80001eb4:	040005b7          	lui	a1,0x4000
    80001eb8:	15fd                	addi	a1,a1,-1
    80001eba:	05b2                	slli	a1,a1,0xc
    80001ebc:	fffff097          	auipc	ra,0xfffff
    80001ec0:	77c080e7          	jalr	1916(ra) # 80001638 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001ec4:	4681                	li	a3,0
    80001ec6:	4605                	li	a2,1
    80001ec8:	020005b7          	lui	a1,0x2000
    80001ecc:	15fd                	addi	a1,a1,-1
    80001ece:	05b6                	slli	a1,a1,0xd
    80001ed0:	8526                	mv	a0,s1
    80001ed2:	fffff097          	auipc	ra,0xfffff
    80001ed6:	766080e7          	jalr	1894(ra) # 80001638 <uvmunmap>
  uvmfree(pagetable, sz);
    80001eda:	85ca                	mv	a1,s2
    80001edc:	8526                	mv	a0,s1
    80001ede:	00000097          	auipc	ra,0x0
    80001ee2:	a1a080e7          	jalr	-1510(ra) # 800018f8 <uvmfree>
}
    80001ee6:	60e2                	ld	ra,24(sp)
    80001ee8:	6442                	ld	s0,16(sp)
    80001eea:	64a2                	ld	s1,8(sp)
    80001eec:	6902                	ld	s2,0(sp)
    80001eee:	6105                	addi	sp,sp,32
    80001ef0:	8082                	ret

0000000080001ef2 <freeproc>:
{
    80001ef2:	1101                	addi	sp,sp,-32
    80001ef4:	ec06                	sd	ra,24(sp)
    80001ef6:	e822                	sd	s0,16(sp)
    80001ef8:	e426                	sd	s1,8(sp)
    80001efa:	1000                	addi	s0,sp,32
    80001efc:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001efe:	7128                	ld	a0,96(a0)
    80001f00:	c509                	beqz	a0,80001f0a <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001f02:	fffff097          	auipc	ra,0xfffff
    80001f06:	b2a080e7          	jalr	-1238(ra) # 80000a2c <kfree>
  p->trapframe = 0;
    80001f0a:	0604b023          	sd	zero,96(s1)
  if(p->pagetable)
    80001f0e:	6ca8                	ld	a0,88(s1)
    80001f10:	c511                	beqz	a0,80001f1c <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001f12:	68ac                	ld	a1,80(s1)
    80001f14:	00000097          	auipc	ra,0x0
    80001f18:	f8c080e7          	jalr	-116(ra) # 80001ea0 <proc_freepagetable>
  p->pagetable = 0;
    80001f1c:	0404bc23          	sd	zero,88(s1)
  p->sz = 0;
    80001f20:	0404b823          	sd	zero,80(s1)
  p->pid = 0;
    80001f24:	0404a023          	sw	zero,64(s1)
  p->parent = 0;
    80001f28:	0204b423          	sd	zero,40(s1)
  p->name[0] = 0;
    80001f2c:	16048023          	sb	zero,352(s1)
  p->chan = 0;
    80001f30:	0204b823          	sd	zero,48(s1)
  p->killed = 0;
    80001f34:	0204ac23          	sw	zero,56(s1)
  p->xstate = 0;
    80001f38:	0204ae23          	sw	zero,60(s1)
  p->state = UNUSED;
    80001f3c:	0204a023          	sw	zero,32(s1)
}
    80001f40:	60e2                	ld	ra,24(sp)
    80001f42:	6442                	ld	s0,16(sp)
    80001f44:	64a2                	ld	s1,8(sp)
    80001f46:	6105                	addi	sp,sp,32
    80001f48:	8082                	ret

0000000080001f4a <allocproc>:
{
    80001f4a:	1101                	addi	sp,sp,-32
    80001f4c:	ec06                	sd	ra,24(sp)
    80001f4e:	e822                	sd	s0,16(sp)
    80001f50:	e426                	sd	s1,8(sp)
    80001f52:	e04a                	sd	s2,0(sp)
    80001f54:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001f56:	00011497          	auipc	s1,0x11
    80001f5a:	85248493          	addi	s1,s1,-1966 # 800127a8 <proc>
    80001f5e:	00016917          	auipc	s2,0x16
    80001f62:	44a90913          	addi	s2,s2,1098 # 800183a8 <tickslock>
    acquire(&p->lock);
    80001f66:	8526                	mv	a0,s1
    80001f68:	fffff097          	auipc	ra,0xfffff
    80001f6c:	d90080e7          	jalr	-624(ra) # 80000cf8 <acquire>
    if(p->state == UNUSED) {
    80001f70:	509c                	lw	a5,32(s1)
    80001f72:	cf81                	beqz	a5,80001f8a <allocproc+0x40>
      release(&p->lock);
    80001f74:	8526                	mv	a0,s1
    80001f76:	fffff097          	auipc	ra,0xfffff
    80001f7a:	e52080e7          	jalr	-430(ra) # 80000dc8 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001f7e:	17048493          	addi	s1,s1,368
    80001f82:	ff2492e3          	bne	s1,s2,80001f66 <allocproc+0x1c>
  return 0;
    80001f86:	4481                	li	s1,0
    80001f88:	a0b9                	j	80001fd6 <allocproc+0x8c>
  p->pid = allocpid();
    80001f8a:	00000097          	auipc	ra,0x0
    80001f8e:	e34080e7          	jalr	-460(ra) # 80001dbe <allocpid>
    80001f92:	c0a8                	sw	a0,64(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001f94:	fffff097          	auipc	ra,0xfffff
    80001f98:	be4080e7          	jalr	-1052(ra) # 80000b78 <kalloc>
    80001f9c:	892a                	mv	s2,a0
    80001f9e:	f0a8                	sd	a0,96(s1)
    80001fa0:	c131                	beqz	a0,80001fe4 <allocproc+0x9a>
  p->pagetable = proc_pagetable(p);
    80001fa2:	8526                	mv	a0,s1
    80001fa4:	00000097          	auipc	ra,0x0
    80001fa8:	e60080e7          	jalr	-416(ra) # 80001e04 <proc_pagetable>
    80001fac:	892a                	mv	s2,a0
    80001fae:	eca8                	sd	a0,88(s1)
  if(p->pagetable == 0){
    80001fb0:	c129                	beqz	a0,80001ff2 <allocproc+0xa8>
  memset(&p->context, 0, sizeof(p->context));
    80001fb2:	07000613          	li	a2,112
    80001fb6:	4581                	li	a1,0
    80001fb8:	06848513          	addi	a0,s1,104
    80001fbc:	fffff097          	auipc	ra,0xfffff
    80001fc0:	11c080e7          	jalr	284(ra) # 800010d8 <memset>
  p->context.ra = (uint64)forkret;
    80001fc4:	00000797          	auipc	a5,0x0
    80001fc8:	db478793          	addi	a5,a5,-588 # 80001d78 <forkret>
    80001fcc:	f4bc                	sd	a5,104(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001fce:	64bc                	ld	a5,72(s1)
    80001fd0:	6705                	lui	a4,0x1
    80001fd2:	97ba                	add	a5,a5,a4
    80001fd4:	f8bc                	sd	a5,112(s1)
}
    80001fd6:	8526                	mv	a0,s1
    80001fd8:	60e2                	ld	ra,24(sp)
    80001fda:	6442                	ld	s0,16(sp)
    80001fdc:	64a2                	ld	s1,8(sp)
    80001fde:	6902                	ld	s2,0(sp)
    80001fe0:	6105                	addi	sp,sp,32
    80001fe2:	8082                	ret
    release(&p->lock);
    80001fe4:	8526                	mv	a0,s1
    80001fe6:	fffff097          	auipc	ra,0xfffff
    80001fea:	de2080e7          	jalr	-542(ra) # 80000dc8 <release>
    return 0;
    80001fee:	84ca                	mv	s1,s2
    80001ff0:	b7dd                	j	80001fd6 <allocproc+0x8c>
    freeproc(p);
    80001ff2:	8526                	mv	a0,s1
    80001ff4:	00000097          	auipc	ra,0x0
    80001ff8:	efe080e7          	jalr	-258(ra) # 80001ef2 <freeproc>
    release(&p->lock);
    80001ffc:	8526                	mv	a0,s1
    80001ffe:	fffff097          	auipc	ra,0xfffff
    80002002:	dca080e7          	jalr	-566(ra) # 80000dc8 <release>
    return 0;
    80002006:	84ca                	mv	s1,s2
    80002008:	b7f9                	j	80001fd6 <allocproc+0x8c>

000000008000200a <userinit>:
{
    8000200a:	1101                	addi	sp,sp,-32
    8000200c:	ec06                	sd	ra,24(sp)
    8000200e:	e822                	sd	s0,16(sp)
    80002010:	e426                	sd	s1,8(sp)
    80002012:	1000                	addi	s0,sp,32
  p = allocproc();
    80002014:	00000097          	auipc	ra,0x0
    80002018:	f36080e7          	jalr	-202(ra) # 80001f4a <allocproc>
    8000201c:	84aa                	mv	s1,a0
  initproc = p;
    8000201e:	00007797          	auipc	a5,0x7
    80002022:	fea7bd23          	sd	a0,-6(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80002026:	03400613          	li	a2,52
    8000202a:	00007597          	auipc	a1,0x7
    8000202e:	89658593          	addi	a1,a1,-1898 # 800088c0 <initcode>
    80002032:	6d28                	ld	a0,88(a0)
    80002034:	fffff097          	auipc	ra,0xfffff
    80002038:	6f6080e7          	jalr	1782(ra) # 8000172a <uvminit>
  p->sz = PGSIZE;
    8000203c:	6785                	lui	a5,0x1
    8000203e:	e8bc                	sd	a5,80(s1)
  p->trapframe->epc = 0;      // user program counter
    80002040:	70b8                	ld	a4,96(s1)
    80002042:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80002046:	70b8                	ld	a4,96(s1)
    80002048:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    8000204a:	4641                	li	a2,16
    8000204c:	00006597          	auipc	a1,0x6
    80002050:	22c58593          	addi	a1,a1,556 # 80008278 <digits+0x238>
    80002054:	16048513          	addi	a0,s1,352
    80002058:	fffff097          	auipc	ra,0xfffff
    8000205c:	1d6080e7          	jalr	470(ra) # 8000122e <safestrcpy>
  p->cwd = namei("/");
    80002060:	00006517          	auipc	a0,0x6
    80002064:	22850513          	addi	a0,a0,552 # 80008288 <digits+0x248>
    80002068:	00002097          	auipc	ra,0x2
    8000206c:	0bc080e7          	jalr	188(ra) # 80004124 <namei>
    80002070:	14a4bc23          	sd	a0,344(s1)
  p->state = RUNNABLE;
    80002074:	4789                	li	a5,2
    80002076:	d09c                	sw	a5,32(s1)
  release(&p->lock);
    80002078:	8526                	mv	a0,s1
    8000207a:	fffff097          	auipc	ra,0xfffff
    8000207e:	d4e080e7          	jalr	-690(ra) # 80000dc8 <release>
}
    80002082:	60e2                	ld	ra,24(sp)
    80002084:	6442                	ld	s0,16(sp)
    80002086:	64a2                	ld	s1,8(sp)
    80002088:	6105                	addi	sp,sp,32
    8000208a:	8082                	ret

000000008000208c <growproc>:
{
    8000208c:	1101                	addi	sp,sp,-32
    8000208e:	ec06                	sd	ra,24(sp)
    80002090:	e822                	sd	s0,16(sp)
    80002092:	e426                	sd	s1,8(sp)
    80002094:	e04a                	sd	s2,0(sp)
    80002096:	1000                	addi	s0,sp,32
    80002098:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    8000209a:	00000097          	auipc	ra,0x0
    8000209e:	ca6080e7          	jalr	-858(ra) # 80001d40 <myproc>
    800020a2:	892a                	mv	s2,a0
  sz = p->sz;
    800020a4:	692c                	ld	a1,80(a0)
    800020a6:	0005861b          	sext.w	a2,a1
  if(n > 0){
    800020aa:	00904f63          	bgtz	s1,800020c8 <growproc+0x3c>
  } else if(n < 0){
    800020ae:	0204cc63          	bltz	s1,800020e6 <growproc+0x5a>
  p->sz = sz;
    800020b2:	1602                	slli	a2,a2,0x20
    800020b4:	9201                	srli	a2,a2,0x20
    800020b6:	04c93823          	sd	a2,80(s2)
  return 0;
    800020ba:	4501                	li	a0,0
}
    800020bc:	60e2                	ld	ra,24(sp)
    800020be:	6442                	ld	s0,16(sp)
    800020c0:	64a2                	ld	s1,8(sp)
    800020c2:	6902                	ld	s2,0(sp)
    800020c4:	6105                	addi	sp,sp,32
    800020c6:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    800020c8:	9e25                	addw	a2,a2,s1
    800020ca:	1602                	slli	a2,a2,0x20
    800020cc:	9201                	srli	a2,a2,0x20
    800020ce:	1582                	slli	a1,a1,0x20
    800020d0:	9181                	srli	a1,a1,0x20
    800020d2:	6d28                	ld	a0,88(a0)
    800020d4:	fffff097          	auipc	ra,0xfffff
    800020d8:	710080e7          	jalr	1808(ra) # 800017e4 <uvmalloc>
    800020dc:	0005061b          	sext.w	a2,a0
    800020e0:	fa69                	bnez	a2,800020b2 <growproc+0x26>
      return -1;
    800020e2:	557d                	li	a0,-1
    800020e4:	bfe1                	j	800020bc <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    800020e6:	9e25                	addw	a2,a2,s1
    800020e8:	1602                	slli	a2,a2,0x20
    800020ea:	9201                	srli	a2,a2,0x20
    800020ec:	1582                	slli	a1,a1,0x20
    800020ee:	9181                	srli	a1,a1,0x20
    800020f0:	6d28                	ld	a0,88(a0)
    800020f2:	fffff097          	auipc	ra,0xfffff
    800020f6:	6aa080e7          	jalr	1706(ra) # 8000179c <uvmdealloc>
    800020fa:	0005061b          	sext.w	a2,a0
    800020fe:	bf55                	j	800020b2 <growproc+0x26>

0000000080002100 <fork>:
{
    80002100:	7179                	addi	sp,sp,-48
    80002102:	f406                	sd	ra,40(sp)
    80002104:	f022                	sd	s0,32(sp)
    80002106:	ec26                	sd	s1,24(sp)
    80002108:	e84a                	sd	s2,16(sp)
    8000210a:	e44e                	sd	s3,8(sp)
    8000210c:	e052                	sd	s4,0(sp)
    8000210e:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002110:	00000097          	auipc	ra,0x0
    80002114:	c30080e7          	jalr	-976(ra) # 80001d40 <myproc>
    80002118:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    8000211a:	00000097          	auipc	ra,0x0
    8000211e:	e30080e7          	jalr	-464(ra) # 80001f4a <allocproc>
    80002122:	c175                	beqz	a0,80002206 <fork+0x106>
    80002124:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80002126:	05093603          	ld	a2,80(s2)
    8000212a:	6d2c                	ld	a1,88(a0)
    8000212c:	05893503          	ld	a0,88(s2)
    80002130:	00000097          	auipc	ra,0x0
    80002134:	800080e7          	jalr	-2048(ra) # 80001930 <uvmcopy>
    80002138:	04054863          	bltz	a0,80002188 <fork+0x88>
  np->sz = p->sz;
    8000213c:	05093783          	ld	a5,80(s2)
    80002140:	04f9b823          	sd	a5,80(s3) # 4000050 <_entry-0x7bffffb0>
  np->parent = p;
    80002144:	0329b423          	sd	s2,40(s3)
  *(np->trapframe) = *(p->trapframe);
    80002148:	06093683          	ld	a3,96(s2)
    8000214c:	87b6                	mv	a5,a3
    8000214e:	0609b703          	ld	a4,96(s3)
    80002152:	12068693          	addi	a3,a3,288
    80002156:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    8000215a:	6788                	ld	a0,8(a5)
    8000215c:	6b8c                	ld	a1,16(a5)
    8000215e:	6f90                	ld	a2,24(a5)
    80002160:	01073023          	sd	a6,0(a4)
    80002164:	e708                	sd	a0,8(a4)
    80002166:	eb0c                	sd	a1,16(a4)
    80002168:	ef10                	sd	a2,24(a4)
    8000216a:	02078793          	addi	a5,a5,32
    8000216e:	02070713          	addi	a4,a4,32
    80002172:	fed792e3          	bne	a5,a3,80002156 <fork+0x56>
  np->trapframe->a0 = 0;
    80002176:	0609b783          	ld	a5,96(s3)
    8000217a:	0607b823          	sd	zero,112(a5)
    8000217e:	0d800493          	li	s1,216
  for(i = 0; i < NOFILE; i++)
    80002182:	15800a13          	li	s4,344
    80002186:	a03d                	j	800021b4 <fork+0xb4>
    freeproc(np);
    80002188:	854e                	mv	a0,s3
    8000218a:	00000097          	auipc	ra,0x0
    8000218e:	d68080e7          	jalr	-664(ra) # 80001ef2 <freeproc>
    release(&np->lock);
    80002192:	854e                	mv	a0,s3
    80002194:	fffff097          	auipc	ra,0xfffff
    80002198:	c34080e7          	jalr	-972(ra) # 80000dc8 <release>
    return -1;
    8000219c:	54fd                	li	s1,-1
    8000219e:	a899                	j	800021f4 <fork+0xf4>
      np->ofile[i] = filedup(p->ofile[i]);
    800021a0:	00002097          	auipc	ra,0x2
    800021a4:	622080e7          	jalr	1570(ra) # 800047c2 <filedup>
    800021a8:	009987b3          	add	a5,s3,s1
    800021ac:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    800021ae:	04a1                	addi	s1,s1,8
    800021b0:	01448763          	beq	s1,s4,800021be <fork+0xbe>
    if(p->ofile[i])
    800021b4:	009907b3          	add	a5,s2,s1
    800021b8:	6388                	ld	a0,0(a5)
    800021ba:	f17d                	bnez	a0,800021a0 <fork+0xa0>
    800021bc:	bfcd                	j	800021ae <fork+0xae>
  np->cwd = idup(p->cwd);
    800021be:	15893503          	ld	a0,344(s2)
    800021c2:	00001097          	auipc	ra,0x1
    800021c6:	770080e7          	jalr	1904(ra) # 80003932 <idup>
    800021ca:	14a9bc23          	sd	a0,344(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    800021ce:	4641                	li	a2,16
    800021d0:	16090593          	addi	a1,s2,352
    800021d4:	16098513          	addi	a0,s3,352
    800021d8:	fffff097          	auipc	ra,0xfffff
    800021dc:	056080e7          	jalr	86(ra) # 8000122e <safestrcpy>
  pid = np->pid;
    800021e0:	0409a483          	lw	s1,64(s3)
  np->state = RUNNABLE;
    800021e4:	4789                	li	a5,2
    800021e6:	02f9a023          	sw	a5,32(s3)
  release(&np->lock);
    800021ea:	854e                	mv	a0,s3
    800021ec:	fffff097          	auipc	ra,0xfffff
    800021f0:	bdc080e7          	jalr	-1060(ra) # 80000dc8 <release>
}
    800021f4:	8526                	mv	a0,s1
    800021f6:	70a2                	ld	ra,40(sp)
    800021f8:	7402                	ld	s0,32(sp)
    800021fa:	64e2                	ld	s1,24(sp)
    800021fc:	6942                	ld	s2,16(sp)
    800021fe:	69a2                	ld	s3,8(sp)
    80002200:	6a02                	ld	s4,0(sp)
    80002202:	6145                	addi	sp,sp,48
    80002204:	8082                	ret
    return -1;
    80002206:	54fd                	li	s1,-1
    80002208:	b7f5                	j	800021f4 <fork+0xf4>

000000008000220a <reparent>:
{
    8000220a:	7179                	addi	sp,sp,-48
    8000220c:	f406                	sd	ra,40(sp)
    8000220e:	f022                	sd	s0,32(sp)
    80002210:	ec26                	sd	s1,24(sp)
    80002212:	e84a                	sd	s2,16(sp)
    80002214:	e44e                	sd	s3,8(sp)
    80002216:	e052                	sd	s4,0(sp)
    80002218:	1800                	addi	s0,sp,48
    8000221a:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000221c:	00010497          	auipc	s1,0x10
    80002220:	58c48493          	addi	s1,s1,1420 # 800127a8 <proc>
      pp->parent = initproc;
    80002224:	00007a17          	auipc	s4,0x7
    80002228:	df4a0a13          	addi	s4,s4,-524 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000222c:	00016997          	auipc	s3,0x16
    80002230:	17c98993          	addi	s3,s3,380 # 800183a8 <tickslock>
    80002234:	a029                	j	8000223e <reparent+0x34>
    80002236:	17048493          	addi	s1,s1,368
    8000223a:	03348363          	beq	s1,s3,80002260 <reparent+0x56>
    if(pp->parent == p){
    8000223e:	749c                	ld	a5,40(s1)
    80002240:	ff279be3          	bne	a5,s2,80002236 <reparent+0x2c>
      acquire(&pp->lock);
    80002244:	8526                	mv	a0,s1
    80002246:	fffff097          	auipc	ra,0xfffff
    8000224a:	ab2080e7          	jalr	-1358(ra) # 80000cf8 <acquire>
      pp->parent = initproc;
    8000224e:	000a3783          	ld	a5,0(s4)
    80002252:	f49c                	sd	a5,40(s1)
      release(&pp->lock);
    80002254:	8526                	mv	a0,s1
    80002256:	fffff097          	auipc	ra,0xfffff
    8000225a:	b72080e7          	jalr	-1166(ra) # 80000dc8 <release>
    8000225e:	bfe1                	j	80002236 <reparent+0x2c>
}
    80002260:	70a2                	ld	ra,40(sp)
    80002262:	7402                	ld	s0,32(sp)
    80002264:	64e2                	ld	s1,24(sp)
    80002266:	6942                	ld	s2,16(sp)
    80002268:	69a2                	ld	s3,8(sp)
    8000226a:	6a02                	ld	s4,0(sp)
    8000226c:	6145                	addi	sp,sp,48
    8000226e:	8082                	ret

0000000080002270 <scheduler>:
{
    80002270:	711d                	addi	sp,sp,-96
    80002272:	ec86                	sd	ra,88(sp)
    80002274:	e8a2                	sd	s0,80(sp)
    80002276:	e4a6                	sd	s1,72(sp)
    80002278:	e0ca                	sd	s2,64(sp)
    8000227a:	fc4e                	sd	s3,56(sp)
    8000227c:	f852                	sd	s4,48(sp)
    8000227e:	f456                	sd	s5,40(sp)
    80002280:	f05a                	sd	s6,32(sp)
    80002282:	ec5e                	sd	s7,24(sp)
    80002284:	e862                	sd	s8,16(sp)
    80002286:	e466                	sd	s9,8(sp)
    80002288:	1080                	addi	s0,sp,96
    8000228a:	8792                	mv	a5,tp
  int id = r_tp();
    8000228c:	2781                	sext.w	a5,a5
  c->proc = 0;
    8000228e:	00779c13          	slli	s8,a5,0x7
    80002292:	00010717          	auipc	a4,0x10
    80002296:	0f670713          	addi	a4,a4,246 # 80012388 <pid_lock>
    8000229a:	9762                	add	a4,a4,s8
    8000229c:	02073023          	sd	zero,32(a4)
        swtch(&c->context, &p->context);
    800022a0:	00010717          	auipc	a4,0x10
    800022a4:	11070713          	addi	a4,a4,272 # 800123b0 <cpus+0x8>
    800022a8:	9c3a                	add	s8,s8,a4
      if(p->state == RUNNABLE) {
    800022aa:	4a89                	li	s5,2
        c->proc = p;
    800022ac:	079e                	slli	a5,a5,0x7
    800022ae:	00010b17          	auipc	s6,0x10
    800022b2:	0dab0b13          	addi	s6,s6,218 # 80012388 <pid_lock>
    800022b6:	9b3e                	add	s6,s6,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    800022b8:	00016a17          	auipc	s4,0x16
    800022bc:	0f0a0a13          	addi	s4,s4,240 # 800183a8 <tickslock>
    int nproc = 0;
    800022c0:	4c81                	li	s9,0
    800022c2:	a8a1                	j	8000231a <scheduler+0xaa>
        p->state = RUNNING;
    800022c4:	0374a023          	sw	s7,32(s1)
        c->proc = p;
    800022c8:	029b3023          	sd	s1,32(s6)
        swtch(&c->context, &p->context);
    800022cc:	06848593          	addi	a1,s1,104
    800022d0:	8562                	mv	a0,s8
    800022d2:	00000097          	auipc	ra,0x0
    800022d6:	63a080e7          	jalr	1594(ra) # 8000290c <swtch>
        c->proc = 0;
    800022da:	020b3023          	sd	zero,32(s6)
      release(&p->lock);
    800022de:	8526                	mv	a0,s1
    800022e0:	fffff097          	auipc	ra,0xfffff
    800022e4:	ae8080e7          	jalr	-1304(ra) # 80000dc8 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    800022e8:	17048493          	addi	s1,s1,368
    800022ec:	01448d63          	beq	s1,s4,80002306 <scheduler+0x96>
      acquire(&p->lock);
    800022f0:	8526                	mv	a0,s1
    800022f2:	fffff097          	auipc	ra,0xfffff
    800022f6:	a06080e7          	jalr	-1530(ra) # 80000cf8 <acquire>
      if(p->state != UNUSED) {
    800022fa:	509c                	lw	a5,32(s1)
    800022fc:	d3ed                	beqz	a5,800022de <scheduler+0x6e>
        nproc++;
    800022fe:	2985                	addiw	s3,s3,1
      if(p->state == RUNNABLE) {
    80002300:	fd579fe3          	bne	a5,s5,800022de <scheduler+0x6e>
    80002304:	b7c1                	j	800022c4 <scheduler+0x54>
    if(nproc <= 2) {   // only init and sh exist
    80002306:	013aca63          	blt	s5,s3,8000231a <scheduler+0xaa>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000230a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000230e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002312:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    80002316:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000231a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000231e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002322:	10079073          	csrw	sstatus,a5
    int nproc = 0;
    80002326:	89e6                	mv	s3,s9
    for(p = proc; p < &proc[NPROC]; p++) {
    80002328:	00010497          	auipc	s1,0x10
    8000232c:	48048493          	addi	s1,s1,1152 # 800127a8 <proc>
        p->state = RUNNING;
    80002330:	4b8d                	li	s7,3
    80002332:	bf7d                	j	800022f0 <scheduler+0x80>

0000000080002334 <sched>:
{
    80002334:	7179                	addi	sp,sp,-48
    80002336:	f406                	sd	ra,40(sp)
    80002338:	f022                	sd	s0,32(sp)
    8000233a:	ec26                	sd	s1,24(sp)
    8000233c:	e84a                	sd	s2,16(sp)
    8000233e:	e44e                	sd	s3,8(sp)
    80002340:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002342:	00000097          	auipc	ra,0x0
    80002346:	9fe080e7          	jalr	-1538(ra) # 80001d40 <myproc>
    8000234a:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000234c:	fffff097          	auipc	ra,0xfffff
    80002350:	932080e7          	jalr	-1742(ra) # 80000c7e <holding>
    80002354:	c93d                	beqz	a0,800023ca <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002356:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002358:	2781                	sext.w	a5,a5
    8000235a:	079e                	slli	a5,a5,0x7
    8000235c:	00010717          	auipc	a4,0x10
    80002360:	02c70713          	addi	a4,a4,44 # 80012388 <pid_lock>
    80002364:	97ba                	add	a5,a5,a4
    80002366:	0987a703          	lw	a4,152(a5)
    8000236a:	4785                	li	a5,1
    8000236c:	06f71763          	bne	a4,a5,800023da <sched+0xa6>
  if(p->state == RUNNING)
    80002370:	5098                	lw	a4,32(s1)
    80002372:	478d                	li	a5,3
    80002374:	06f70b63          	beq	a4,a5,800023ea <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002378:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000237c:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000237e:	efb5                	bnez	a5,800023fa <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002380:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002382:	00010917          	auipc	s2,0x10
    80002386:	00690913          	addi	s2,s2,6 # 80012388 <pid_lock>
    8000238a:	2781                	sext.w	a5,a5
    8000238c:	079e                	slli	a5,a5,0x7
    8000238e:	97ca                	add	a5,a5,s2
    80002390:	09c7a983          	lw	s3,156(a5)
    80002394:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002396:	2781                	sext.w	a5,a5
    80002398:	079e                	slli	a5,a5,0x7
    8000239a:	00010597          	auipc	a1,0x10
    8000239e:	01658593          	addi	a1,a1,22 # 800123b0 <cpus+0x8>
    800023a2:	95be                	add	a1,a1,a5
    800023a4:	06848513          	addi	a0,s1,104
    800023a8:	00000097          	auipc	ra,0x0
    800023ac:	564080e7          	jalr	1380(ra) # 8000290c <swtch>
    800023b0:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800023b2:	2781                	sext.w	a5,a5
    800023b4:	079e                	slli	a5,a5,0x7
    800023b6:	97ca                	add	a5,a5,s2
    800023b8:	0937ae23          	sw	s3,156(a5)
}
    800023bc:	70a2                	ld	ra,40(sp)
    800023be:	7402                	ld	s0,32(sp)
    800023c0:	64e2                	ld	s1,24(sp)
    800023c2:	6942                	ld	s2,16(sp)
    800023c4:	69a2                	ld	s3,8(sp)
    800023c6:	6145                	addi	sp,sp,48
    800023c8:	8082                	ret
    panic("sched p->lock");
    800023ca:	00006517          	auipc	a0,0x6
    800023ce:	ec650513          	addi	a0,a0,-314 # 80008290 <digits+0x250>
    800023d2:	ffffe097          	auipc	ra,0xffffe
    800023d6:	17e080e7          	jalr	382(ra) # 80000550 <panic>
    panic("sched locks");
    800023da:	00006517          	auipc	a0,0x6
    800023de:	ec650513          	addi	a0,a0,-314 # 800082a0 <digits+0x260>
    800023e2:	ffffe097          	auipc	ra,0xffffe
    800023e6:	16e080e7          	jalr	366(ra) # 80000550 <panic>
    panic("sched running");
    800023ea:	00006517          	auipc	a0,0x6
    800023ee:	ec650513          	addi	a0,a0,-314 # 800082b0 <digits+0x270>
    800023f2:	ffffe097          	auipc	ra,0xffffe
    800023f6:	15e080e7          	jalr	350(ra) # 80000550 <panic>
    panic("sched interruptible");
    800023fa:	00006517          	auipc	a0,0x6
    800023fe:	ec650513          	addi	a0,a0,-314 # 800082c0 <digits+0x280>
    80002402:	ffffe097          	auipc	ra,0xffffe
    80002406:	14e080e7          	jalr	334(ra) # 80000550 <panic>

000000008000240a <exit>:
{
    8000240a:	7179                	addi	sp,sp,-48
    8000240c:	f406                	sd	ra,40(sp)
    8000240e:	f022                	sd	s0,32(sp)
    80002410:	ec26                	sd	s1,24(sp)
    80002412:	e84a                	sd	s2,16(sp)
    80002414:	e44e                	sd	s3,8(sp)
    80002416:	e052                	sd	s4,0(sp)
    80002418:	1800                	addi	s0,sp,48
    8000241a:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000241c:	00000097          	auipc	ra,0x0
    80002420:	924080e7          	jalr	-1756(ra) # 80001d40 <myproc>
    80002424:	89aa                	mv	s3,a0
  if(p == initproc)
    80002426:	00007797          	auipc	a5,0x7
    8000242a:	bf27b783          	ld	a5,-1038(a5) # 80009018 <initproc>
    8000242e:	0d850493          	addi	s1,a0,216
    80002432:	15850913          	addi	s2,a0,344
    80002436:	02a79363          	bne	a5,a0,8000245c <exit+0x52>
    panic("init exiting");
    8000243a:	00006517          	auipc	a0,0x6
    8000243e:	e9e50513          	addi	a0,a0,-354 # 800082d8 <digits+0x298>
    80002442:	ffffe097          	auipc	ra,0xffffe
    80002446:	10e080e7          	jalr	270(ra) # 80000550 <panic>
      fileclose(f);
    8000244a:	00002097          	auipc	ra,0x2
    8000244e:	3ca080e7          	jalr	970(ra) # 80004814 <fileclose>
      p->ofile[fd] = 0;
    80002452:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002456:	04a1                	addi	s1,s1,8
    80002458:	01248563          	beq	s1,s2,80002462 <exit+0x58>
    if(p->ofile[fd]){
    8000245c:	6088                	ld	a0,0(s1)
    8000245e:	f575                	bnez	a0,8000244a <exit+0x40>
    80002460:	bfdd                	j	80002456 <exit+0x4c>
  begin_op();
    80002462:	00002097          	auipc	ra,0x2
    80002466:	ede080e7          	jalr	-290(ra) # 80004340 <begin_op>
  iput(p->cwd);
    8000246a:	1589b503          	ld	a0,344(s3)
    8000246e:	00001097          	auipc	ra,0x1
    80002472:	6bc080e7          	jalr	1724(ra) # 80003b2a <iput>
  end_op();
    80002476:	00002097          	auipc	ra,0x2
    8000247a:	f4a080e7          	jalr	-182(ra) # 800043c0 <end_op>
  p->cwd = 0;
    8000247e:	1409bc23          	sd	zero,344(s3)
  acquire(&initproc->lock);
    80002482:	00007497          	auipc	s1,0x7
    80002486:	b9648493          	addi	s1,s1,-1130 # 80009018 <initproc>
    8000248a:	6088                	ld	a0,0(s1)
    8000248c:	fffff097          	auipc	ra,0xfffff
    80002490:	86c080e7          	jalr	-1940(ra) # 80000cf8 <acquire>
  wakeup1(initproc);
    80002494:	6088                	ld	a0,0(s1)
    80002496:	fffff097          	auipc	ra,0xfffff
    8000249a:	76a080e7          	jalr	1898(ra) # 80001c00 <wakeup1>
  release(&initproc->lock);
    8000249e:	6088                	ld	a0,0(s1)
    800024a0:	fffff097          	auipc	ra,0xfffff
    800024a4:	928080e7          	jalr	-1752(ra) # 80000dc8 <release>
  acquire(&p->lock);
    800024a8:	854e                	mv	a0,s3
    800024aa:	fffff097          	auipc	ra,0xfffff
    800024ae:	84e080e7          	jalr	-1970(ra) # 80000cf8 <acquire>
  struct proc *original_parent = p->parent;
    800024b2:	0289b483          	ld	s1,40(s3)
  release(&p->lock);
    800024b6:	854e                	mv	a0,s3
    800024b8:	fffff097          	auipc	ra,0xfffff
    800024bc:	910080e7          	jalr	-1776(ra) # 80000dc8 <release>
  acquire(&original_parent->lock);
    800024c0:	8526                	mv	a0,s1
    800024c2:	fffff097          	auipc	ra,0xfffff
    800024c6:	836080e7          	jalr	-1994(ra) # 80000cf8 <acquire>
  acquire(&p->lock);
    800024ca:	854e                	mv	a0,s3
    800024cc:	fffff097          	auipc	ra,0xfffff
    800024d0:	82c080e7          	jalr	-2004(ra) # 80000cf8 <acquire>
  reparent(p);
    800024d4:	854e                	mv	a0,s3
    800024d6:	00000097          	auipc	ra,0x0
    800024da:	d34080e7          	jalr	-716(ra) # 8000220a <reparent>
  wakeup1(original_parent);
    800024de:	8526                	mv	a0,s1
    800024e0:	fffff097          	auipc	ra,0xfffff
    800024e4:	720080e7          	jalr	1824(ra) # 80001c00 <wakeup1>
  p->xstate = status;
    800024e8:	0349ae23          	sw	s4,60(s3)
  p->state = ZOMBIE;
    800024ec:	4791                	li	a5,4
    800024ee:	02f9a023          	sw	a5,32(s3)
  release(&original_parent->lock);
    800024f2:	8526                	mv	a0,s1
    800024f4:	fffff097          	auipc	ra,0xfffff
    800024f8:	8d4080e7          	jalr	-1836(ra) # 80000dc8 <release>
  sched();
    800024fc:	00000097          	auipc	ra,0x0
    80002500:	e38080e7          	jalr	-456(ra) # 80002334 <sched>
  panic("zombie exit");
    80002504:	00006517          	auipc	a0,0x6
    80002508:	de450513          	addi	a0,a0,-540 # 800082e8 <digits+0x2a8>
    8000250c:	ffffe097          	auipc	ra,0xffffe
    80002510:	044080e7          	jalr	68(ra) # 80000550 <panic>

0000000080002514 <yield>:
{
    80002514:	1101                	addi	sp,sp,-32
    80002516:	ec06                	sd	ra,24(sp)
    80002518:	e822                	sd	s0,16(sp)
    8000251a:	e426                	sd	s1,8(sp)
    8000251c:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000251e:	00000097          	auipc	ra,0x0
    80002522:	822080e7          	jalr	-2014(ra) # 80001d40 <myproc>
    80002526:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002528:	ffffe097          	auipc	ra,0xffffe
    8000252c:	7d0080e7          	jalr	2000(ra) # 80000cf8 <acquire>
  p->state = RUNNABLE;
    80002530:	4789                	li	a5,2
    80002532:	d09c                	sw	a5,32(s1)
  sched();
    80002534:	00000097          	auipc	ra,0x0
    80002538:	e00080e7          	jalr	-512(ra) # 80002334 <sched>
  release(&p->lock);
    8000253c:	8526                	mv	a0,s1
    8000253e:	fffff097          	auipc	ra,0xfffff
    80002542:	88a080e7          	jalr	-1910(ra) # 80000dc8 <release>
}
    80002546:	60e2                	ld	ra,24(sp)
    80002548:	6442                	ld	s0,16(sp)
    8000254a:	64a2                	ld	s1,8(sp)
    8000254c:	6105                	addi	sp,sp,32
    8000254e:	8082                	ret

0000000080002550 <sleep>:
{
    80002550:	7179                	addi	sp,sp,-48
    80002552:	f406                	sd	ra,40(sp)
    80002554:	f022                	sd	s0,32(sp)
    80002556:	ec26                	sd	s1,24(sp)
    80002558:	e84a                	sd	s2,16(sp)
    8000255a:	e44e                	sd	s3,8(sp)
    8000255c:	1800                	addi	s0,sp,48
    8000255e:	89aa                	mv	s3,a0
    80002560:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002562:	fffff097          	auipc	ra,0xfffff
    80002566:	7de080e7          	jalr	2014(ra) # 80001d40 <myproc>
    8000256a:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    8000256c:	05250663          	beq	a0,s2,800025b8 <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    80002570:	ffffe097          	auipc	ra,0xffffe
    80002574:	788080e7          	jalr	1928(ra) # 80000cf8 <acquire>
    release(lk);
    80002578:	854a                	mv	a0,s2
    8000257a:	fffff097          	auipc	ra,0xfffff
    8000257e:	84e080e7          	jalr	-1970(ra) # 80000dc8 <release>
  p->chan = chan;
    80002582:	0334b823          	sd	s3,48(s1)
  p->state = SLEEPING;
    80002586:	4785                	li	a5,1
    80002588:	d09c                	sw	a5,32(s1)
  sched();
    8000258a:	00000097          	auipc	ra,0x0
    8000258e:	daa080e7          	jalr	-598(ra) # 80002334 <sched>
  p->chan = 0;
    80002592:	0204b823          	sd	zero,48(s1)
    release(&p->lock);
    80002596:	8526                	mv	a0,s1
    80002598:	fffff097          	auipc	ra,0xfffff
    8000259c:	830080e7          	jalr	-2000(ra) # 80000dc8 <release>
    acquire(lk);
    800025a0:	854a                	mv	a0,s2
    800025a2:	ffffe097          	auipc	ra,0xffffe
    800025a6:	756080e7          	jalr	1878(ra) # 80000cf8 <acquire>
}
    800025aa:	70a2                	ld	ra,40(sp)
    800025ac:	7402                	ld	s0,32(sp)
    800025ae:	64e2                	ld	s1,24(sp)
    800025b0:	6942                	ld	s2,16(sp)
    800025b2:	69a2                	ld	s3,8(sp)
    800025b4:	6145                	addi	sp,sp,48
    800025b6:	8082                	ret
  p->chan = chan;
    800025b8:	03353823          	sd	s3,48(a0)
  p->state = SLEEPING;
    800025bc:	4785                	li	a5,1
    800025be:	d11c                	sw	a5,32(a0)
  sched();
    800025c0:	00000097          	auipc	ra,0x0
    800025c4:	d74080e7          	jalr	-652(ra) # 80002334 <sched>
  p->chan = 0;
    800025c8:	0204b823          	sd	zero,48(s1)
  if(lk != &p->lock){
    800025cc:	bff9                	j	800025aa <sleep+0x5a>

00000000800025ce <wait>:
{
    800025ce:	715d                	addi	sp,sp,-80
    800025d0:	e486                	sd	ra,72(sp)
    800025d2:	e0a2                	sd	s0,64(sp)
    800025d4:	fc26                	sd	s1,56(sp)
    800025d6:	f84a                	sd	s2,48(sp)
    800025d8:	f44e                	sd	s3,40(sp)
    800025da:	f052                	sd	s4,32(sp)
    800025dc:	ec56                	sd	s5,24(sp)
    800025de:	e85a                	sd	s6,16(sp)
    800025e0:	e45e                	sd	s7,8(sp)
    800025e2:	e062                	sd	s8,0(sp)
    800025e4:	0880                	addi	s0,sp,80
    800025e6:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800025e8:	fffff097          	auipc	ra,0xfffff
    800025ec:	758080e7          	jalr	1880(ra) # 80001d40 <myproc>
    800025f0:	892a                	mv	s2,a0
  acquire(&p->lock);
    800025f2:	8c2a                	mv	s8,a0
    800025f4:	ffffe097          	auipc	ra,0xffffe
    800025f8:	704080e7          	jalr	1796(ra) # 80000cf8 <acquire>
    havekids = 0;
    800025fc:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800025fe:	4a11                	li	s4,4
    for(np = proc; np < &proc[NPROC]; np++){
    80002600:	00016997          	auipc	s3,0x16
    80002604:	da898993          	addi	s3,s3,-600 # 800183a8 <tickslock>
        havekids = 1;
    80002608:	4a85                	li	s5,1
    havekids = 0;
    8000260a:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    8000260c:	00010497          	auipc	s1,0x10
    80002610:	19c48493          	addi	s1,s1,412 # 800127a8 <proc>
    80002614:	a08d                	j	80002676 <wait+0xa8>
          pid = np->pid;
    80002616:	0404a983          	lw	s3,64(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000261a:	000b0e63          	beqz	s6,80002636 <wait+0x68>
    8000261e:	4691                	li	a3,4
    80002620:	03c48613          	addi	a2,s1,60
    80002624:	85da                	mv	a1,s6
    80002626:	05893503          	ld	a0,88(s2)
    8000262a:	fffff097          	auipc	ra,0xfffff
    8000262e:	40a080e7          	jalr	1034(ra) # 80001a34 <copyout>
    80002632:	02054263          	bltz	a0,80002656 <wait+0x88>
          freeproc(np);
    80002636:	8526                	mv	a0,s1
    80002638:	00000097          	auipc	ra,0x0
    8000263c:	8ba080e7          	jalr	-1862(ra) # 80001ef2 <freeproc>
          release(&np->lock);
    80002640:	8526                	mv	a0,s1
    80002642:	ffffe097          	auipc	ra,0xffffe
    80002646:	786080e7          	jalr	1926(ra) # 80000dc8 <release>
          release(&p->lock);
    8000264a:	854a                	mv	a0,s2
    8000264c:	ffffe097          	auipc	ra,0xffffe
    80002650:	77c080e7          	jalr	1916(ra) # 80000dc8 <release>
          return pid;
    80002654:	a8a9                	j	800026ae <wait+0xe0>
            release(&np->lock);
    80002656:	8526                	mv	a0,s1
    80002658:	ffffe097          	auipc	ra,0xffffe
    8000265c:	770080e7          	jalr	1904(ra) # 80000dc8 <release>
            release(&p->lock);
    80002660:	854a                	mv	a0,s2
    80002662:	ffffe097          	auipc	ra,0xffffe
    80002666:	766080e7          	jalr	1894(ra) # 80000dc8 <release>
            return -1;
    8000266a:	59fd                	li	s3,-1
    8000266c:	a089                	j	800026ae <wait+0xe0>
    for(np = proc; np < &proc[NPROC]; np++){
    8000266e:	17048493          	addi	s1,s1,368
    80002672:	03348463          	beq	s1,s3,8000269a <wait+0xcc>
      if(np->parent == p){
    80002676:	749c                	ld	a5,40(s1)
    80002678:	ff279be3          	bne	a5,s2,8000266e <wait+0xa0>
        acquire(&np->lock);
    8000267c:	8526                	mv	a0,s1
    8000267e:	ffffe097          	auipc	ra,0xffffe
    80002682:	67a080e7          	jalr	1658(ra) # 80000cf8 <acquire>
        if(np->state == ZOMBIE){
    80002686:	509c                	lw	a5,32(s1)
    80002688:	f94787e3          	beq	a5,s4,80002616 <wait+0x48>
        release(&np->lock);
    8000268c:	8526                	mv	a0,s1
    8000268e:	ffffe097          	auipc	ra,0xffffe
    80002692:	73a080e7          	jalr	1850(ra) # 80000dc8 <release>
        havekids = 1;
    80002696:	8756                	mv	a4,s5
    80002698:	bfd9                	j	8000266e <wait+0xa0>
    if(!havekids || p->killed){
    8000269a:	c701                	beqz	a4,800026a2 <wait+0xd4>
    8000269c:	03892783          	lw	a5,56(s2)
    800026a0:	c785                	beqz	a5,800026c8 <wait+0xfa>
      release(&p->lock);
    800026a2:	854a                	mv	a0,s2
    800026a4:	ffffe097          	auipc	ra,0xffffe
    800026a8:	724080e7          	jalr	1828(ra) # 80000dc8 <release>
      return -1;
    800026ac:	59fd                	li	s3,-1
}
    800026ae:	854e                	mv	a0,s3
    800026b0:	60a6                	ld	ra,72(sp)
    800026b2:	6406                	ld	s0,64(sp)
    800026b4:	74e2                	ld	s1,56(sp)
    800026b6:	7942                	ld	s2,48(sp)
    800026b8:	79a2                	ld	s3,40(sp)
    800026ba:	7a02                	ld	s4,32(sp)
    800026bc:	6ae2                	ld	s5,24(sp)
    800026be:	6b42                	ld	s6,16(sp)
    800026c0:	6ba2                	ld	s7,8(sp)
    800026c2:	6c02                	ld	s8,0(sp)
    800026c4:	6161                	addi	sp,sp,80
    800026c6:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    800026c8:	85e2                	mv	a1,s8
    800026ca:	854a                	mv	a0,s2
    800026cc:	00000097          	auipc	ra,0x0
    800026d0:	e84080e7          	jalr	-380(ra) # 80002550 <sleep>
    havekids = 0;
    800026d4:	bf1d                	j	8000260a <wait+0x3c>

00000000800026d6 <wakeup>:
{
    800026d6:	7139                	addi	sp,sp,-64
    800026d8:	fc06                	sd	ra,56(sp)
    800026da:	f822                	sd	s0,48(sp)
    800026dc:	f426                	sd	s1,40(sp)
    800026de:	f04a                	sd	s2,32(sp)
    800026e0:	ec4e                	sd	s3,24(sp)
    800026e2:	e852                	sd	s4,16(sp)
    800026e4:	e456                	sd	s5,8(sp)
    800026e6:	0080                	addi	s0,sp,64
    800026e8:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    800026ea:	00010497          	auipc	s1,0x10
    800026ee:	0be48493          	addi	s1,s1,190 # 800127a8 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    800026f2:	4985                	li	s3,1
      p->state = RUNNABLE;
    800026f4:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    800026f6:	00016917          	auipc	s2,0x16
    800026fa:	cb290913          	addi	s2,s2,-846 # 800183a8 <tickslock>
    800026fe:	a821                	j	80002716 <wakeup+0x40>
      p->state = RUNNABLE;
    80002700:	0354a023          	sw	s5,32(s1)
    release(&p->lock);
    80002704:	8526                	mv	a0,s1
    80002706:	ffffe097          	auipc	ra,0xffffe
    8000270a:	6c2080e7          	jalr	1730(ra) # 80000dc8 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000270e:	17048493          	addi	s1,s1,368
    80002712:	01248e63          	beq	s1,s2,8000272e <wakeup+0x58>
    acquire(&p->lock);
    80002716:	8526                	mv	a0,s1
    80002718:	ffffe097          	auipc	ra,0xffffe
    8000271c:	5e0080e7          	jalr	1504(ra) # 80000cf8 <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    80002720:	509c                	lw	a5,32(s1)
    80002722:	ff3791e3          	bne	a5,s3,80002704 <wakeup+0x2e>
    80002726:	789c                	ld	a5,48(s1)
    80002728:	fd479ee3          	bne	a5,s4,80002704 <wakeup+0x2e>
    8000272c:	bfd1                	j	80002700 <wakeup+0x2a>
}
    8000272e:	70e2                	ld	ra,56(sp)
    80002730:	7442                	ld	s0,48(sp)
    80002732:	74a2                	ld	s1,40(sp)
    80002734:	7902                	ld	s2,32(sp)
    80002736:	69e2                	ld	s3,24(sp)
    80002738:	6a42                	ld	s4,16(sp)
    8000273a:	6aa2                	ld	s5,8(sp)
    8000273c:	6121                	addi	sp,sp,64
    8000273e:	8082                	ret

0000000080002740 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002740:	7179                	addi	sp,sp,-48
    80002742:	f406                	sd	ra,40(sp)
    80002744:	f022                	sd	s0,32(sp)
    80002746:	ec26                	sd	s1,24(sp)
    80002748:	e84a                	sd	s2,16(sp)
    8000274a:	e44e                	sd	s3,8(sp)
    8000274c:	1800                	addi	s0,sp,48
    8000274e:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002750:	00010497          	auipc	s1,0x10
    80002754:	05848493          	addi	s1,s1,88 # 800127a8 <proc>
    80002758:	00016997          	auipc	s3,0x16
    8000275c:	c5098993          	addi	s3,s3,-944 # 800183a8 <tickslock>
    acquire(&p->lock);
    80002760:	8526                	mv	a0,s1
    80002762:	ffffe097          	auipc	ra,0xffffe
    80002766:	596080e7          	jalr	1430(ra) # 80000cf8 <acquire>
    if(p->pid == pid){
    8000276a:	40bc                	lw	a5,64(s1)
    8000276c:	01278d63          	beq	a5,s2,80002786 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002770:	8526                	mv	a0,s1
    80002772:	ffffe097          	auipc	ra,0xffffe
    80002776:	656080e7          	jalr	1622(ra) # 80000dc8 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000277a:	17048493          	addi	s1,s1,368
    8000277e:	ff3491e3          	bne	s1,s3,80002760 <kill+0x20>
  }
  return -1;
    80002782:	557d                	li	a0,-1
    80002784:	a829                	j	8000279e <kill+0x5e>
      p->killed = 1;
    80002786:	4785                	li	a5,1
    80002788:	dc9c                	sw	a5,56(s1)
      if(p->state == SLEEPING){
    8000278a:	5098                	lw	a4,32(s1)
    8000278c:	4785                	li	a5,1
    8000278e:	00f70f63          	beq	a4,a5,800027ac <kill+0x6c>
      release(&p->lock);
    80002792:	8526                	mv	a0,s1
    80002794:	ffffe097          	auipc	ra,0xffffe
    80002798:	634080e7          	jalr	1588(ra) # 80000dc8 <release>
      return 0;
    8000279c:	4501                	li	a0,0
}
    8000279e:	70a2                	ld	ra,40(sp)
    800027a0:	7402                	ld	s0,32(sp)
    800027a2:	64e2                	ld	s1,24(sp)
    800027a4:	6942                	ld	s2,16(sp)
    800027a6:	69a2                	ld	s3,8(sp)
    800027a8:	6145                	addi	sp,sp,48
    800027aa:	8082                	ret
        p->state = RUNNABLE;
    800027ac:	4789                	li	a5,2
    800027ae:	d09c                	sw	a5,32(s1)
    800027b0:	b7cd                	j	80002792 <kill+0x52>

00000000800027b2 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800027b2:	7179                	addi	sp,sp,-48
    800027b4:	f406                	sd	ra,40(sp)
    800027b6:	f022                	sd	s0,32(sp)
    800027b8:	ec26                	sd	s1,24(sp)
    800027ba:	e84a                	sd	s2,16(sp)
    800027bc:	e44e                	sd	s3,8(sp)
    800027be:	e052                	sd	s4,0(sp)
    800027c0:	1800                	addi	s0,sp,48
    800027c2:	84aa                	mv	s1,a0
    800027c4:	892e                	mv	s2,a1
    800027c6:	89b2                	mv	s3,a2
    800027c8:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800027ca:	fffff097          	auipc	ra,0xfffff
    800027ce:	576080e7          	jalr	1398(ra) # 80001d40 <myproc>
  if(user_dst){
    800027d2:	c08d                	beqz	s1,800027f4 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800027d4:	86d2                	mv	a3,s4
    800027d6:	864e                	mv	a2,s3
    800027d8:	85ca                	mv	a1,s2
    800027da:	6d28                	ld	a0,88(a0)
    800027dc:	fffff097          	auipc	ra,0xfffff
    800027e0:	258080e7          	jalr	600(ra) # 80001a34 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800027e4:	70a2                	ld	ra,40(sp)
    800027e6:	7402                	ld	s0,32(sp)
    800027e8:	64e2                	ld	s1,24(sp)
    800027ea:	6942                	ld	s2,16(sp)
    800027ec:	69a2                	ld	s3,8(sp)
    800027ee:	6a02                	ld	s4,0(sp)
    800027f0:	6145                	addi	sp,sp,48
    800027f2:	8082                	ret
    memmove((char *)dst, src, len);
    800027f4:	000a061b          	sext.w	a2,s4
    800027f8:	85ce                	mv	a1,s3
    800027fa:	854a                	mv	a0,s2
    800027fc:	fffff097          	auipc	ra,0xfffff
    80002800:	93c080e7          	jalr	-1732(ra) # 80001138 <memmove>
    return 0;
    80002804:	8526                	mv	a0,s1
    80002806:	bff9                	j	800027e4 <either_copyout+0x32>

0000000080002808 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002808:	7179                	addi	sp,sp,-48
    8000280a:	f406                	sd	ra,40(sp)
    8000280c:	f022                	sd	s0,32(sp)
    8000280e:	ec26                	sd	s1,24(sp)
    80002810:	e84a                	sd	s2,16(sp)
    80002812:	e44e                	sd	s3,8(sp)
    80002814:	e052                	sd	s4,0(sp)
    80002816:	1800                	addi	s0,sp,48
    80002818:	892a                	mv	s2,a0
    8000281a:	84ae                	mv	s1,a1
    8000281c:	89b2                	mv	s3,a2
    8000281e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002820:	fffff097          	auipc	ra,0xfffff
    80002824:	520080e7          	jalr	1312(ra) # 80001d40 <myproc>
  if(user_src){
    80002828:	c08d                	beqz	s1,8000284a <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    8000282a:	86d2                	mv	a3,s4
    8000282c:	864e                	mv	a2,s3
    8000282e:	85ca                	mv	a1,s2
    80002830:	6d28                	ld	a0,88(a0)
    80002832:	fffff097          	auipc	ra,0xfffff
    80002836:	28e080e7          	jalr	654(ra) # 80001ac0 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    8000283a:	70a2                	ld	ra,40(sp)
    8000283c:	7402                	ld	s0,32(sp)
    8000283e:	64e2                	ld	s1,24(sp)
    80002840:	6942                	ld	s2,16(sp)
    80002842:	69a2                	ld	s3,8(sp)
    80002844:	6a02                	ld	s4,0(sp)
    80002846:	6145                	addi	sp,sp,48
    80002848:	8082                	ret
    memmove(dst, (char*)src, len);
    8000284a:	000a061b          	sext.w	a2,s4
    8000284e:	85ce                	mv	a1,s3
    80002850:	854a                	mv	a0,s2
    80002852:	fffff097          	auipc	ra,0xfffff
    80002856:	8e6080e7          	jalr	-1818(ra) # 80001138 <memmove>
    return 0;
    8000285a:	8526                	mv	a0,s1
    8000285c:	bff9                	j	8000283a <either_copyin+0x32>

000000008000285e <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    8000285e:	715d                	addi	sp,sp,-80
    80002860:	e486                	sd	ra,72(sp)
    80002862:	e0a2                	sd	s0,64(sp)
    80002864:	fc26                	sd	s1,56(sp)
    80002866:	f84a                	sd	s2,48(sp)
    80002868:	f44e                	sd	s3,40(sp)
    8000286a:	f052                	sd	s4,32(sp)
    8000286c:	ec56                	sd	s5,24(sp)
    8000286e:	e85a                	sd	s6,16(sp)
    80002870:	e45e                	sd	s7,8(sp)
    80002872:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002874:	00006517          	auipc	a0,0x6
    80002878:	8ec50513          	addi	a0,a0,-1812 # 80008160 <digits+0x120>
    8000287c:	ffffe097          	auipc	ra,0xffffe
    80002880:	d1e080e7          	jalr	-738(ra) # 8000059a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002884:	00010497          	auipc	s1,0x10
    80002888:	08448493          	addi	s1,s1,132 # 80012908 <proc+0x160>
    8000288c:	00016917          	auipc	s2,0x16
    80002890:	c7c90913          	addi	s2,s2,-900 # 80018508 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002894:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    80002896:	00006997          	auipc	s3,0x6
    8000289a:	a6298993          	addi	s3,s3,-1438 # 800082f8 <digits+0x2b8>
    printf("%d %s %s", p->pid, state, p->name);
    8000289e:	00006a97          	auipc	s5,0x6
    800028a2:	a62a8a93          	addi	s5,s5,-1438 # 80008300 <digits+0x2c0>
    printf("\n");
    800028a6:	00006a17          	auipc	s4,0x6
    800028aa:	8baa0a13          	addi	s4,s4,-1862 # 80008160 <digits+0x120>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028ae:	00006b97          	auipc	s7,0x6
    800028b2:	a8ab8b93          	addi	s7,s7,-1398 # 80008338 <states.1712>
    800028b6:	a00d                	j	800028d8 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800028b8:	ee06a583          	lw	a1,-288(a3)
    800028bc:	8556                	mv	a0,s5
    800028be:	ffffe097          	auipc	ra,0xffffe
    800028c2:	cdc080e7          	jalr	-804(ra) # 8000059a <printf>
    printf("\n");
    800028c6:	8552                	mv	a0,s4
    800028c8:	ffffe097          	auipc	ra,0xffffe
    800028cc:	cd2080e7          	jalr	-814(ra) # 8000059a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800028d0:	17048493          	addi	s1,s1,368
    800028d4:	03248163          	beq	s1,s2,800028f6 <procdump+0x98>
    if(p->state == UNUSED)
    800028d8:	86a6                	mv	a3,s1
    800028da:	ec04a783          	lw	a5,-320(s1)
    800028de:	dbed                	beqz	a5,800028d0 <procdump+0x72>
      state = "???";
    800028e0:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028e2:	fcfb6be3          	bltu	s6,a5,800028b8 <procdump+0x5a>
    800028e6:	1782                	slli	a5,a5,0x20
    800028e8:	9381                	srli	a5,a5,0x20
    800028ea:	078e                	slli	a5,a5,0x3
    800028ec:	97de                	add	a5,a5,s7
    800028ee:	6390                	ld	a2,0(a5)
    800028f0:	f661                	bnez	a2,800028b8 <procdump+0x5a>
      state = "???";
    800028f2:	864e                	mv	a2,s3
    800028f4:	b7d1                	j	800028b8 <procdump+0x5a>
  }
}
    800028f6:	60a6                	ld	ra,72(sp)
    800028f8:	6406                	ld	s0,64(sp)
    800028fa:	74e2                	ld	s1,56(sp)
    800028fc:	7942                	ld	s2,48(sp)
    800028fe:	79a2                	ld	s3,40(sp)
    80002900:	7a02                	ld	s4,32(sp)
    80002902:	6ae2                	ld	s5,24(sp)
    80002904:	6b42                	ld	s6,16(sp)
    80002906:	6ba2                	ld	s7,8(sp)
    80002908:	6161                	addi	sp,sp,80
    8000290a:	8082                	ret

000000008000290c <swtch>:
    8000290c:	00153023          	sd	ra,0(a0)
    80002910:	00253423          	sd	sp,8(a0)
    80002914:	e900                	sd	s0,16(a0)
    80002916:	ed04                	sd	s1,24(a0)
    80002918:	03253023          	sd	s2,32(a0)
    8000291c:	03353423          	sd	s3,40(a0)
    80002920:	03453823          	sd	s4,48(a0)
    80002924:	03553c23          	sd	s5,56(a0)
    80002928:	05653023          	sd	s6,64(a0)
    8000292c:	05753423          	sd	s7,72(a0)
    80002930:	05853823          	sd	s8,80(a0)
    80002934:	05953c23          	sd	s9,88(a0)
    80002938:	07a53023          	sd	s10,96(a0)
    8000293c:	07b53423          	sd	s11,104(a0)
    80002940:	0005b083          	ld	ra,0(a1)
    80002944:	0085b103          	ld	sp,8(a1)
    80002948:	6980                	ld	s0,16(a1)
    8000294a:	6d84                	ld	s1,24(a1)
    8000294c:	0205b903          	ld	s2,32(a1)
    80002950:	0285b983          	ld	s3,40(a1)
    80002954:	0305ba03          	ld	s4,48(a1)
    80002958:	0385ba83          	ld	s5,56(a1)
    8000295c:	0405bb03          	ld	s6,64(a1)
    80002960:	0485bb83          	ld	s7,72(a1)
    80002964:	0505bc03          	ld	s8,80(a1)
    80002968:	0585bc83          	ld	s9,88(a1)
    8000296c:	0605bd03          	ld	s10,96(a1)
    80002970:	0685bd83          	ld	s11,104(a1)
    80002974:	8082                	ret

0000000080002976 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002976:	1141                	addi	sp,sp,-16
    80002978:	e406                	sd	ra,8(sp)
    8000297a:	e022                	sd	s0,0(sp)
    8000297c:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000297e:	00006597          	auipc	a1,0x6
    80002982:	9e258593          	addi	a1,a1,-1566 # 80008360 <states.1712+0x28>
    80002986:	00016517          	auipc	a0,0x16
    8000298a:	a2250513          	addi	a0,a0,-1502 # 800183a8 <tickslock>
    8000298e:	ffffe097          	auipc	ra,0xffffe
    80002992:	4e6080e7          	jalr	1254(ra) # 80000e74 <initlock>
}
    80002996:	60a2                	ld	ra,8(sp)
    80002998:	6402                	ld	s0,0(sp)
    8000299a:	0141                	addi	sp,sp,16
    8000299c:	8082                	ret

000000008000299e <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000299e:	1141                	addi	sp,sp,-16
    800029a0:	e422                	sd	s0,8(sp)
    800029a2:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029a4:	00003797          	auipc	a5,0x3
    800029a8:	4ec78793          	addi	a5,a5,1260 # 80005e90 <kernelvec>
    800029ac:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800029b0:	6422                	ld	s0,8(sp)
    800029b2:	0141                	addi	sp,sp,16
    800029b4:	8082                	ret

00000000800029b6 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800029b6:	1141                	addi	sp,sp,-16
    800029b8:	e406                	sd	ra,8(sp)
    800029ba:	e022                	sd	s0,0(sp)
    800029bc:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800029be:	fffff097          	auipc	ra,0xfffff
    800029c2:	382080e7          	jalr	898(ra) # 80001d40 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029c6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800029ca:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029cc:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800029d0:	00004617          	auipc	a2,0x4
    800029d4:	63060613          	addi	a2,a2,1584 # 80007000 <_trampoline>
    800029d8:	00004697          	auipc	a3,0x4
    800029dc:	62868693          	addi	a3,a3,1576 # 80007000 <_trampoline>
    800029e0:	8e91                	sub	a3,a3,a2
    800029e2:	040007b7          	lui	a5,0x4000
    800029e6:	17fd                	addi	a5,a5,-1
    800029e8:	07b2                	slli	a5,a5,0xc
    800029ea:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029ec:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800029f0:	7138                	ld	a4,96(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800029f2:	180026f3          	csrr	a3,satp
    800029f6:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800029f8:	7138                	ld	a4,96(a0)
    800029fa:	6534                	ld	a3,72(a0)
    800029fc:	6585                	lui	a1,0x1
    800029fe:	96ae                	add	a3,a3,a1
    80002a00:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002a02:	7138                	ld	a4,96(a0)
    80002a04:	00000697          	auipc	a3,0x0
    80002a08:	13868693          	addi	a3,a3,312 # 80002b3c <usertrap>
    80002a0c:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002a0e:	7138                	ld	a4,96(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002a10:	8692                	mv	a3,tp
    80002a12:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a14:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002a18:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002a1c:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a20:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002a24:	7138                	ld	a4,96(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a26:	6f18                	ld	a4,24(a4)
    80002a28:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002a2c:	6d2c                	ld	a1,88(a0)
    80002a2e:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002a30:	00004717          	auipc	a4,0x4
    80002a34:	66070713          	addi	a4,a4,1632 # 80007090 <userret>
    80002a38:	8f11                	sub	a4,a4,a2
    80002a3a:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002a3c:	577d                	li	a4,-1
    80002a3e:	177e                	slli	a4,a4,0x3f
    80002a40:	8dd9                	or	a1,a1,a4
    80002a42:	02000537          	lui	a0,0x2000
    80002a46:	157d                	addi	a0,a0,-1
    80002a48:	0536                	slli	a0,a0,0xd
    80002a4a:	9782                	jalr	a5
}
    80002a4c:	60a2                	ld	ra,8(sp)
    80002a4e:	6402                	ld	s0,0(sp)
    80002a50:	0141                	addi	sp,sp,16
    80002a52:	8082                	ret

0000000080002a54 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002a54:	1101                	addi	sp,sp,-32
    80002a56:	ec06                	sd	ra,24(sp)
    80002a58:	e822                	sd	s0,16(sp)
    80002a5a:	e426                	sd	s1,8(sp)
    80002a5c:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002a5e:	00016497          	auipc	s1,0x16
    80002a62:	94a48493          	addi	s1,s1,-1718 # 800183a8 <tickslock>
    80002a66:	8526                	mv	a0,s1
    80002a68:	ffffe097          	auipc	ra,0xffffe
    80002a6c:	290080e7          	jalr	656(ra) # 80000cf8 <acquire>
  ticks++;
    80002a70:	00006517          	auipc	a0,0x6
    80002a74:	5b050513          	addi	a0,a0,1456 # 80009020 <ticks>
    80002a78:	411c                	lw	a5,0(a0)
    80002a7a:	2785                	addiw	a5,a5,1
    80002a7c:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002a7e:	00000097          	auipc	ra,0x0
    80002a82:	c58080e7          	jalr	-936(ra) # 800026d6 <wakeup>
  release(&tickslock);
    80002a86:	8526                	mv	a0,s1
    80002a88:	ffffe097          	auipc	ra,0xffffe
    80002a8c:	340080e7          	jalr	832(ra) # 80000dc8 <release>
}
    80002a90:	60e2                	ld	ra,24(sp)
    80002a92:	6442                	ld	s0,16(sp)
    80002a94:	64a2                	ld	s1,8(sp)
    80002a96:	6105                	addi	sp,sp,32
    80002a98:	8082                	ret

0000000080002a9a <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002a9a:	1101                	addi	sp,sp,-32
    80002a9c:	ec06                	sd	ra,24(sp)
    80002a9e:	e822                	sd	s0,16(sp)
    80002aa0:	e426                	sd	s1,8(sp)
    80002aa2:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002aa4:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002aa8:	00074d63          	bltz	a4,80002ac2 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002aac:	57fd                	li	a5,-1
    80002aae:	17fe                	slli	a5,a5,0x3f
    80002ab0:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002ab2:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002ab4:	06f70363          	beq	a4,a5,80002b1a <devintr+0x80>
  }
}
    80002ab8:	60e2                	ld	ra,24(sp)
    80002aba:	6442                	ld	s0,16(sp)
    80002abc:	64a2                	ld	s1,8(sp)
    80002abe:	6105                	addi	sp,sp,32
    80002ac0:	8082                	ret
     (scause & 0xff) == 9){
    80002ac2:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002ac6:	46a5                	li	a3,9
    80002ac8:	fed792e3          	bne	a5,a3,80002aac <devintr+0x12>
    int irq = plic_claim();
    80002acc:	00003097          	auipc	ra,0x3
    80002ad0:	4cc080e7          	jalr	1228(ra) # 80005f98 <plic_claim>
    80002ad4:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002ad6:	47a9                	li	a5,10
    80002ad8:	02f50763          	beq	a0,a5,80002b06 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002adc:	4785                	li	a5,1
    80002ade:	02f50963          	beq	a0,a5,80002b10 <devintr+0x76>
    return 1;
    80002ae2:	4505                	li	a0,1
    } else if(irq){
    80002ae4:	d8f1                	beqz	s1,80002ab8 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002ae6:	85a6                	mv	a1,s1
    80002ae8:	00006517          	auipc	a0,0x6
    80002aec:	88050513          	addi	a0,a0,-1920 # 80008368 <states.1712+0x30>
    80002af0:	ffffe097          	auipc	ra,0xffffe
    80002af4:	aaa080e7          	jalr	-1366(ra) # 8000059a <printf>
      plic_complete(irq);
    80002af8:	8526                	mv	a0,s1
    80002afa:	00003097          	auipc	ra,0x3
    80002afe:	4c2080e7          	jalr	1218(ra) # 80005fbc <plic_complete>
    return 1;
    80002b02:	4505                	li	a0,1
    80002b04:	bf55                	j	80002ab8 <devintr+0x1e>
      uartintr();
    80002b06:	ffffe097          	auipc	ra,0xffffe
    80002b0a:	ed6080e7          	jalr	-298(ra) # 800009dc <uartintr>
    80002b0e:	b7ed                	j	80002af8 <devintr+0x5e>
      virtio_disk_intr();
    80002b10:	00004097          	auipc	ra,0x4
    80002b14:	98c080e7          	jalr	-1652(ra) # 8000649c <virtio_disk_intr>
    80002b18:	b7c5                	j	80002af8 <devintr+0x5e>
    if(cpuid() == 0){
    80002b1a:	fffff097          	auipc	ra,0xfffff
    80002b1e:	1fa080e7          	jalr	506(ra) # 80001d14 <cpuid>
    80002b22:	c901                	beqz	a0,80002b32 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002b24:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002b28:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002b2a:	14479073          	csrw	sip,a5
    return 2;
    80002b2e:	4509                	li	a0,2
    80002b30:	b761                	j	80002ab8 <devintr+0x1e>
      clockintr();
    80002b32:	00000097          	auipc	ra,0x0
    80002b36:	f22080e7          	jalr	-222(ra) # 80002a54 <clockintr>
    80002b3a:	b7ed                	j	80002b24 <devintr+0x8a>

0000000080002b3c <usertrap>:
{
    80002b3c:	1101                	addi	sp,sp,-32
    80002b3e:	ec06                	sd	ra,24(sp)
    80002b40:	e822                	sd	s0,16(sp)
    80002b42:	e426                	sd	s1,8(sp)
    80002b44:	e04a                	sd	s2,0(sp)
    80002b46:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b48:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002b4c:	1007f793          	andi	a5,a5,256
    80002b50:	e3ad                	bnez	a5,80002bb2 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b52:	00003797          	auipc	a5,0x3
    80002b56:	33e78793          	addi	a5,a5,830 # 80005e90 <kernelvec>
    80002b5a:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002b5e:	fffff097          	auipc	ra,0xfffff
    80002b62:	1e2080e7          	jalr	482(ra) # 80001d40 <myproc>
    80002b66:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002b68:	713c                	ld	a5,96(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b6a:	14102773          	csrr	a4,sepc
    80002b6e:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b70:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002b74:	47a1                	li	a5,8
    80002b76:	04f71c63          	bne	a4,a5,80002bce <usertrap+0x92>
    if(p->killed)
    80002b7a:	5d1c                	lw	a5,56(a0)
    80002b7c:	e3b9                	bnez	a5,80002bc2 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002b7e:	70b8                	ld	a4,96(s1)
    80002b80:	6f1c                	ld	a5,24(a4)
    80002b82:	0791                	addi	a5,a5,4
    80002b84:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b86:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002b8a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b8e:	10079073          	csrw	sstatus,a5
    syscall();
    80002b92:	00000097          	auipc	ra,0x0
    80002b96:	2e0080e7          	jalr	736(ra) # 80002e72 <syscall>
  if(p->killed)
    80002b9a:	5c9c                	lw	a5,56(s1)
    80002b9c:	ebc1                	bnez	a5,80002c2c <usertrap+0xf0>
  usertrapret();
    80002b9e:	00000097          	auipc	ra,0x0
    80002ba2:	e18080e7          	jalr	-488(ra) # 800029b6 <usertrapret>
}
    80002ba6:	60e2                	ld	ra,24(sp)
    80002ba8:	6442                	ld	s0,16(sp)
    80002baa:	64a2                	ld	s1,8(sp)
    80002bac:	6902                	ld	s2,0(sp)
    80002bae:	6105                	addi	sp,sp,32
    80002bb0:	8082                	ret
    panic("usertrap: not from user mode");
    80002bb2:	00005517          	auipc	a0,0x5
    80002bb6:	7d650513          	addi	a0,a0,2006 # 80008388 <states.1712+0x50>
    80002bba:	ffffe097          	auipc	ra,0xffffe
    80002bbe:	996080e7          	jalr	-1642(ra) # 80000550 <panic>
      exit(-1);
    80002bc2:	557d                	li	a0,-1
    80002bc4:	00000097          	auipc	ra,0x0
    80002bc8:	846080e7          	jalr	-1978(ra) # 8000240a <exit>
    80002bcc:	bf4d                	j	80002b7e <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002bce:	00000097          	auipc	ra,0x0
    80002bd2:	ecc080e7          	jalr	-308(ra) # 80002a9a <devintr>
    80002bd6:	892a                	mv	s2,a0
    80002bd8:	c501                	beqz	a0,80002be0 <usertrap+0xa4>
  if(p->killed)
    80002bda:	5c9c                	lw	a5,56(s1)
    80002bdc:	c3a1                	beqz	a5,80002c1c <usertrap+0xe0>
    80002bde:	a815                	j	80002c12 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002be0:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002be4:	40b0                	lw	a2,64(s1)
    80002be6:	00005517          	auipc	a0,0x5
    80002bea:	7c250513          	addi	a0,a0,1986 # 800083a8 <states.1712+0x70>
    80002bee:	ffffe097          	auipc	ra,0xffffe
    80002bf2:	9ac080e7          	jalr	-1620(ra) # 8000059a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bf6:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002bfa:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002bfe:	00005517          	auipc	a0,0x5
    80002c02:	7da50513          	addi	a0,a0,2010 # 800083d8 <states.1712+0xa0>
    80002c06:	ffffe097          	auipc	ra,0xffffe
    80002c0a:	994080e7          	jalr	-1644(ra) # 8000059a <printf>
    p->killed = 1;
    80002c0e:	4785                	li	a5,1
    80002c10:	dc9c                	sw	a5,56(s1)
    exit(-1);
    80002c12:	557d                	li	a0,-1
    80002c14:	fffff097          	auipc	ra,0xfffff
    80002c18:	7f6080e7          	jalr	2038(ra) # 8000240a <exit>
  if(which_dev == 2)
    80002c1c:	4789                	li	a5,2
    80002c1e:	f8f910e3          	bne	s2,a5,80002b9e <usertrap+0x62>
    yield();
    80002c22:	00000097          	auipc	ra,0x0
    80002c26:	8f2080e7          	jalr	-1806(ra) # 80002514 <yield>
    80002c2a:	bf95                	j	80002b9e <usertrap+0x62>
  int which_dev = 0;
    80002c2c:	4901                	li	s2,0
    80002c2e:	b7d5                	j	80002c12 <usertrap+0xd6>

0000000080002c30 <kerneltrap>:
{
    80002c30:	7179                	addi	sp,sp,-48
    80002c32:	f406                	sd	ra,40(sp)
    80002c34:	f022                	sd	s0,32(sp)
    80002c36:	ec26                	sd	s1,24(sp)
    80002c38:	e84a                	sd	s2,16(sp)
    80002c3a:	e44e                	sd	s3,8(sp)
    80002c3c:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c3e:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c42:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c46:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002c4a:	1004f793          	andi	a5,s1,256
    80002c4e:	cb85                	beqz	a5,80002c7e <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c50:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002c54:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002c56:	ef85                	bnez	a5,80002c8e <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002c58:	00000097          	auipc	ra,0x0
    80002c5c:	e42080e7          	jalr	-446(ra) # 80002a9a <devintr>
    80002c60:	cd1d                	beqz	a0,80002c9e <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002c62:	4789                	li	a5,2
    80002c64:	06f50a63          	beq	a0,a5,80002cd8 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c68:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c6c:	10049073          	csrw	sstatus,s1
}
    80002c70:	70a2                	ld	ra,40(sp)
    80002c72:	7402                	ld	s0,32(sp)
    80002c74:	64e2                	ld	s1,24(sp)
    80002c76:	6942                	ld	s2,16(sp)
    80002c78:	69a2                	ld	s3,8(sp)
    80002c7a:	6145                	addi	sp,sp,48
    80002c7c:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002c7e:	00005517          	auipc	a0,0x5
    80002c82:	77a50513          	addi	a0,a0,1914 # 800083f8 <states.1712+0xc0>
    80002c86:	ffffe097          	auipc	ra,0xffffe
    80002c8a:	8ca080e7          	jalr	-1846(ra) # 80000550 <panic>
    panic("kerneltrap: interrupts enabled");
    80002c8e:	00005517          	auipc	a0,0x5
    80002c92:	79250513          	addi	a0,a0,1938 # 80008420 <states.1712+0xe8>
    80002c96:	ffffe097          	auipc	ra,0xffffe
    80002c9a:	8ba080e7          	jalr	-1862(ra) # 80000550 <panic>
    printf("scause %p\n", scause);
    80002c9e:	85ce                	mv	a1,s3
    80002ca0:	00005517          	auipc	a0,0x5
    80002ca4:	7a050513          	addi	a0,a0,1952 # 80008440 <states.1712+0x108>
    80002ca8:	ffffe097          	auipc	ra,0xffffe
    80002cac:	8f2080e7          	jalr	-1806(ra) # 8000059a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002cb0:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002cb4:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002cb8:	00005517          	auipc	a0,0x5
    80002cbc:	79850513          	addi	a0,a0,1944 # 80008450 <states.1712+0x118>
    80002cc0:	ffffe097          	auipc	ra,0xffffe
    80002cc4:	8da080e7          	jalr	-1830(ra) # 8000059a <printf>
    panic("kerneltrap");
    80002cc8:	00005517          	auipc	a0,0x5
    80002ccc:	7a050513          	addi	a0,a0,1952 # 80008468 <states.1712+0x130>
    80002cd0:	ffffe097          	auipc	ra,0xffffe
    80002cd4:	880080e7          	jalr	-1920(ra) # 80000550 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002cd8:	fffff097          	auipc	ra,0xfffff
    80002cdc:	068080e7          	jalr	104(ra) # 80001d40 <myproc>
    80002ce0:	d541                	beqz	a0,80002c68 <kerneltrap+0x38>
    80002ce2:	fffff097          	auipc	ra,0xfffff
    80002ce6:	05e080e7          	jalr	94(ra) # 80001d40 <myproc>
    80002cea:	5118                	lw	a4,32(a0)
    80002cec:	478d                	li	a5,3
    80002cee:	f6f71de3          	bne	a4,a5,80002c68 <kerneltrap+0x38>
    yield();
    80002cf2:	00000097          	auipc	ra,0x0
    80002cf6:	822080e7          	jalr	-2014(ra) # 80002514 <yield>
    80002cfa:	b7bd                	j	80002c68 <kerneltrap+0x38>

0000000080002cfc <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002cfc:	1101                	addi	sp,sp,-32
    80002cfe:	ec06                	sd	ra,24(sp)
    80002d00:	e822                	sd	s0,16(sp)
    80002d02:	e426                	sd	s1,8(sp)
    80002d04:	1000                	addi	s0,sp,32
    80002d06:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002d08:	fffff097          	auipc	ra,0xfffff
    80002d0c:	038080e7          	jalr	56(ra) # 80001d40 <myproc>
  switch (n) {
    80002d10:	4795                	li	a5,5
    80002d12:	0497e163          	bltu	a5,s1,80002d54 <argraw+0x58>
    80002d16:	048a                	slli	s1,s1,0x2
    80002d18:	00005717          	auipc	a4,0x5
    80002d1c:	78870713          	addi	a4,a4,1928 # 800084a0 <states.1712+0x168>
    80002d20:	94ba                	add	s1,s1,a4
    80002d22:	409c                	lw	a5,0(s1)
    80002d24:	97ba                	add	a5,a5,a4
    80002d26:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002d28:	713c                	ld	a5,96(a0)
    80002d2a:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002d2c:	60e2                	ld	ra,24(sp)
    80002d2e:	6442                	ld	s0,16(sp)
    80002d30:	64a2                	ld	s1,8(sp)
    80002d32:	6105                	addi	sp,sp,32
    80002d34:	8082                	ret
    return p->trapframe->a1;
    80002d36:	713c                	ld	a5,96(a0)
    80002d38:	7fa8                	ld	a0,120(a5)
    80002d3a:	bfcd                	j	80002d2c <argraw+0x30>
    return p->trapframe->a2;
    80002d3c:	713c                	ld	a5,96(a0)
    80002d3e:	63c8                	ld	a0,128(a5)
    80002d40:	b7f5                	j	80002d2c <argraw+0x30>
    return p->trapframe->a3;
    80002d42:	713c                	ld	a5,96(a0)
    80002d44:	67c8                	ld	a0,136(a5)
    80002d46:	b7dd                	j	80002d2c <argraw+0x30>
    return p->trapframe->a4;
    80002d48:	713c                	ld	a5,96(a0)
    80002d4a:	6bc8                	ld	a0,144(a5)
    80002d4c:	b7c5                	j	80002d2c <argraw+0x30>
    return p->trapframe->a5;
    80002d4e:	713c                	ld	a5,96(a0)
    80002d50:	6fc8                	ld	a0,152(a5)
    80002d52:	bfe9                	j	80002d2c <argraw+0x30>
  panic("argraw");
    80002d54:	00005517          	auipc	a0,0x5
    80002d58:	72450513          	addi	a0,a0,1828 # 80008478 <states.1712+0x140>
    80002d5c:	ffffd097          	auipc	ra,0xffffd
    80002d60:	7f4080e7          	jalr	2036(ra) # 80000550 <panic>

0000000080002d64 <fetchaddr>:
{
    80002d64:	1101                	addi	sp,sp,-32
    80002d66:	ec06                	sd	ra,24(sp)
    80002d68:	e822                	sd	s0,16(sp)
    80002d6a:	e426                	sd	s1,8(sp)
    80002d6c:	e04a                	sd	s2,0(sp)
    80002d6e:	1000                	addi	s0,sp,32
    80002d70:	84aa                	mv	s1,a0
    80002d72:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002d74:	fffff097          	auipc	ra,0xfffff
    80002d78:	fcc080e7          	jalr	-52(ra) # 80001d40 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002d7c:	693c                	ld	a5,80(a0)
    80002d7e:	02f4f863          	bgeu	s1,a5,80002dae <fetchaddr+0x4a>
    80002d82:	00848713          	addi	a4,s1,8
    80002d86:	02e7e663          	bltu	a5,a4,80002db2 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002d8a:	46a1                	li	a3,8
    80002d8c:	8626                	mv	a2,s1
    80002d8e:	85ca                	mv	a1,s2
    80002d90:	6d28                	ld	a0,88(a0)
    80002d92:	fffff097          	auipc	ra,0xfffff
    80002d96:	d2e080e7          	jalr	-722(ra) # 80001ac0 <copyin>
    80002d9a:	00a03533          	snez	a0,a0
    80002d9e:	40a00533          	neg	a0,a0
}
    80002da2:	60e2                	ld	ra,24(sp)
    80002da4:	6442                	ld	s0,16(sp)
    80002da6:	64a2                	ld	s1,8(sp)
    80002da8:	6902                	ld	s2,0(sp)
    80002daa:	6105                	addi	sp,sp,32
    80002dac:	8082                	ret
    return -1;
    80002dae:	557d                	li	a0,-1
    80002db0:	bfcd                	j	80002da2 <fetchaddr+0x3e>
    80002db2:	557d                	li	a0,-1
    80002db4:	b7fd                	j	80002da2 <fetchaddr+0x3e>

0000000080002db6 <fetchstr>:
{
    80002db6:	7179                	addi	sp,sp,-48
    80002db8:	f406                	sd	ra,40(sp)
    80002dba:	f022                	sd	s0,32(sp)
    80002dbc:	ec26                	sd	s1,24(sp)
    80002dbe:	e84a                	sd	s2,16(sp)
    80002dc0:	e44e                	sd	s3,8(sp)
    80002dc2:	1800                	addi	s0,sp,48
    80002dc4:	892a                	mv	s2,a0
    80002dc6:	84ae                	mv	s1,a1
    80002dc8:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002dca:	fffff097          	auipc	ra,0xfffff
    80002dce:	f76080e7          	jalr	-138(ra) # 80001d40 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002dd2:	86ce                	mv	a3,s3
    80002dd4:	864a                	mv	a2,s2
    80002dd6:	85a6                	mv	a1,s1
    80002dd8:	6d28                	ld	a0,88(a0)
    80002dda:	fffff097          	auipc	ra,0xfffff
    80002dde:	d72080e7          	jalr	-654(ra) # 80001b4c <copyinstr>
  if(err < 0)
    80002de2:	00054763          	bltz	a0,80002df0 <fetchstr+0x3a>
  return strlen(buf);
    80002de6:	8526                	mv	a0,s1
    80002de8:	ffffe097          	auipc	ra,0xffffe
    80002dec:	478080e7          	jalr	1144(ra) # 80001260 <strlen>
}
    80002df0:	70a2                	ld	ra,40(sp)
    80002df2:	7402                	ld	s0,32(sp)
    80002df4:	64e2                	ld	s1,24(sp)
    80002df6:	6942                	ld	s2,16(sp)
    80002df8:	69a2                	ld	s3,8(sp)
    80002dfa:	6145                	addi	sp,sp,48
    80002dfc:	8082                	ret

0000000080002dfe <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002dfe:	1101                	addi	sp,sp,-32
    80002e00:	ec06                	sd	ra,24(sp)
    80002e02:	e822                	sd	s0,16(sp)
    80002e04:	e426                	sd	s1,8(sp)
    80002e06:	1000                	addi	s0,sp,32
    80002e08:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002e0a:	00000097          	auipc	ra,0x0
    80002e0e:	ef2080e7          	jalr	-270(ra) # 80002cfc <argraw>
    80002e12:	c088                	sw	a0,0(s1)
  return 0;
}
    80002e14:	4501                	li	a0,0
    80002e16:	60e2                	ld	ra,24(sp)
    80002e18:	6442                	ld	s0,16(sp)
    80002e1a:	64a2                	ld	s1,8(sp)
    80002e1c:	6105                	addi	sp,sp,32
    80002e1e:	8082                	ret

0000000080002e20 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002e20:	1101                	addi	sp,sp,-32
    80002e22:	ec06                	sd	ra,24(sp)
    80002e24:	e822                	sd	s0,16(sp)
    80002e26:	e426                	sd	s1,8(sp)
    80002e28:	1000                	addi	s0,sp,32
    80002e2a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002e2c:	00000097          	auipc	ra,0x0
    80002e30:	ed0080e7          	jalr	-304(ra) # 80002cfc <argraw>
    80002e34:	e088                	sd	a0,0(s1)
  return 0;
}
    80002e36:	4501                	li	a0,0
    80002e38:	60e2                	ld	ra,24(sp)
    80002e3a:	6442                	ld	s0,16(sp)
    80002e3c:	64a2                	ld	s1,8(sp)
    80002e3e:	6105                	addi	sp,sp,32
    80002e40:	8082                	ret

0000000080002e42 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002e42:	1101                	addi	sp,sp,-32
    80002e44:	ec06                	sd	ra,24(sp)
    80002e46:	e822                	sd	s0,16(sp)
    80002e48:	e426                	sd	s1,8(sp)
    80002e4a:	e04a                	sd	s2,0(sp)
    80002e4c:	1000                	addi	s0,sp,32
    80002e4e:	84ae                	mv	s1,a1
    80002e50:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002e52:	00000097          	auipc	ra,0x0
    80002e56:	eaa080e7          	jalr	-342(ra) # 80002cfc <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002e5a:	864a                	mv	a2,s2
    80002e5c:	85a6                	mv	a1,s1
    80002e5e:	00000097          	auipc	ra,0x0
    80002e62:	f58080e7          	jalr	-168(ra) # 80002db6 <fetchstr>
}
    80002e66:	60e2                	ld	ra,24(sp)
    80002e68:	6442                	ld	s0,16(sp)
    80002e6a:	64a2                	ld	s1,8(sp)
    80002e6c:	6902                	ld	s2,0(sp)
    80002e6e:	6105                	addi	sp,sp,32
    80002e70:	8082                	ret

0000000080002e72 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002e72:	1101                	addi	sp,sp,-32
    80002e74:	ec06                	sd	ra,24(sp)
    80002e76:	e822                	sd	s0,16(sp)
    80002e78:	e426                	sd	s1,8(sp)
    80002e7a:	e04a                	sd	s2,0(sp)
    80002e7c:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002e7e:	fffff097          	auipc	ra,0xfffff
    80002e82:	ec2080e7          	jalr	-318(ra) # 80001d40 <myproc>
    80002e86:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002e88:	06053903          	ld	s2,96(a0)
    80002e8c:	0a893783          	ld	a5,168(s2)
    80002e90:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002e94:	37fd                	addiw	a5,a5,-1
    80002e96:	4751                	li	a4,20
    80002e98:	00f76f63          	bltu	a4,a5,80002eb6 <syscall+0x44>
    80002e9c:	00369713          	slli	a4,a3,0x3
    80002ea0:	00005797          	auipc	a5,0x5
    80002ea4:	61878793          	addi	a5,a5,1560 # 800084b8 <syscalls>
    80002ea8:	97ba                	add	a5,a5,a4
    80002eaa:	639c                	ld	a5,0(a5)
    80002eac:	c789                	beqz	a5,80002eb6 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002eae:	9782                	jalr	a5
    80002eb0:	06a93823          	sd	a0,112(s2)
    80002eb4:	a839                	j	80002ed2 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002eb6:	16048613          	addi	a2,s1,352
    80002eba:	40ac                	lw	a1,64(s1)
    80002ebc:	00005517          	auipc	a0,0x5
    80002ec0:	5c450513          	addi	a0,a0,1476 # 80008480 <states.1712+0x148>
    80002ec4:	ffffd097          	auipc	ra,0xffffd
    80002ec8:	6d6080e7          	jalr	1750(ra) # 8000059a <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002ecc:	70bc                	ld	a5,96(s1)
    80002ece:	577d                	li	a4,-1
    80002ed0:	fbb8                	sd	a4,112(a5)
  }
}
    80002ed2:	60e2                	ld	ra,24(sp)
    80002ed4:	6442                	ld	s0,16(sp)
    80002ed6:	64a2                	ld	s1,8(sp)
    80002ed8:	6902                	ld	s2,0(sp)
    80002eda:	6105                	addi	sp,sp,32
    80002edc:	8082                	ret

0000000080002ede <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002ede:	1101                	addi	sp,sp,-32
    80002ee0:	ec06                	sd	ra,24(sp)
    80002ee2:	e822                	sd	s0,16(sp)
    80002ee4:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002ee6:	fec40593          	addi	a1,s0,-20
    80002eea:	4501                	li	a0,0
    80002eec:	00000097          	auipc	ra,0x0
    80002ef0:	f12080e7          	jalr	-238(ra) # 80002dfe <argint>
    return -1;
    80002ef4:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002ef6:	00054963          	bltz	a0,80002f08 <sys_exit+0x2a>
  exit(n);
    80002efa:	fec42503          	lw	a0,-20(s0)
    80002efe:	fffff097          	auipc	ra,0xfffff
    80002f02:	50c080e7          	jalr	1292(ra) # 8000240a <exit>
  return 0;  // not reached
    80002f06:	4781                	li	a5,0
}
    80002f08:	853e                	mv	a0,a5
    80002f0a:	60e2                	ld	ra,24(sp)
    80002f0c:	6442                	ld	s0,16(sp)
    80002f0e:	6105                	addi	sp,sp,32
    80002f10:	8082                	ret

0000000080002f12 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002f12:	1141                	addi	sp,sp,-16
    80002f14:	e406                	sd	ra,8(sp)
    80002f16:	e022                	sd	s0,0(sp)
    80002f18:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002f1a:	fffff097          	auipc	ra,0xfffff
    80002f1e:	e26080e7          	jalr	-474(ra) # 80001d40 <myproc>
}
    80002f22:	4128                	lw	a0,64(a0)
    80002f24:	60a2                	ld	ra,8(sp)
    80002f26:	6402                	ld	s0,0(sp)
    80002f28:	0141                	addi	sp,sp,16
    80002f2a:	8082                	ret

0000000080002f2c <sys_fork>:

uint64
sys_fork(void)
{
    80002f2c:	1141                	addi	sp,sp,-16
    80002f2e:	e406                	sd	ra,8(sp)
    80002f30:	e022                	sd	s0,0(sp)
    80002f32:	0800                	addi	s0,sp,16
  return fork();
    80002f34:	fffff097          	auipc	ra,0xfffff
    80002f38:	1cc080e7          	jalr	460(ra) # 80002100 <fork>
}
    80002f3c:	60a2                	ld	ra,8(sp)
    80002f3e:	6402                	ld	s0,0(sp)
    80002f40:	0141                	addi	sp,sp,16
    80002f42:	8082                	ret

0000000080002f44 <sys_wait>:

uint64
sys_wait(void)
{
    80002f44:	1101                	addi	sp,sp,-32
    80002f46:	ec06                	sd	ra,24(sp)
    80002f48:	e822                	sd	s0,16(sp)
    80002f4a:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002f4c:	fe840593          	addi	a1,s0,-24
    80002f50:	4501                	li	a0,0
    80002f52:	00000097          	auipc	ra,0x0
    80002f56:	ece080e7          	jalr	-306(ra) # 80002e20 <argaddr>
    80002f5a:	87aa                	mv	a5,a0
    return -1;
    80002f5c:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002f5e:	0007c863          	bltz	a5,80002f6e <sys_wait+0x2a>
  return wait(p);
    80002f62:	fe843503          	ld	a0,-24(s0)
    80002f66:	fffff097          	auipc	ra,0xfffff
    80002f6a:	668080e7          	jalr	1640(ra) # 800025ce <wait>
}
    80002f6e:	60e2                	ld	ra,24(sp)
    80002f70:	6442                	ld	s0,16(sp)
    80002f72:	6105                	addi	sp,sp,32
    80002f74:	8082                	ret

0000000080002f76 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002f76:	7179                	addi	sp,sp,-48
    80002f78:	f406                	sd	ra,40(sp)
    80002f7a:	f022                	sd	s0,32(sp)
    80002f7c:	ec26                	sd	s1,24(sp)
    80002f7e:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002f80:	fdc40593          	addi	a1,s0,-36
    80002f84:	4501                	li	a0,0
    80002f86:	00000097          	auipc	ra,0x0
    80002f8a:	e78080e7          	jalr	-392(ra) # 80002dfe <argint>
    80002f8e:	87aa                	mv	a5,a0
    return -1;
    80002f90:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002f92:	0207c063          	bltz	a5,80002fb2 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002f96:	fffff097          	auipc	ra,0xfffff
    80002f9a:	daa080e7          	jalr	-598(ra) # 80001d40 <myproc>
    80002f9e:	4924                	lw	s1,80(a0)
  if(growproc(n) < 0)
    80002fa0:	fdc42503          	lw	a0,-36(s0)
    80002fa4:	fffff097          	auipc	ra,0xfffff
    80002fa8:	0e8080e7          	jalr	232(ra) # 8000208c <growproc>
    80002fac:	00054863          	bltz	a0,80002fbc <sys_sbrk+0x46>
    return -1;
  return addr;
    80002fb0:	8526                	mv	a0,s1
}
    80002fb2:	70a2                	ld	ra,40(sp)
    80002fb4:	7402                	ld	s0,32(sp)
    80002fb6:	64e2                	ld	s1,24(sp)
    80002fb8:	6145                	addi	sp,sp,48
    80002fba:	8082                	ret
    return -1;
    80002fbc:	557d                	li	a0,-1
    80002fbe:	bfd5                	j	80002fb2 <sys_sbrk+0x3c>

0000000080002fc0 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002fc0:	7139                	addi	sp,sp,-64
    80002fc2:	fc06                	sd	ra,56(sp)
    80002fc4:	f822                	sd	s0,48(sp)
    80002fc6:	f426                	sd	s1,40(sp)
    80002fc8:	f04a                	sd	s2,32(sp)
    80002fca:	ec4e                	sd	s3,24(sp)
    80002fcc:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002fce:	fcc40593          	addi	a1,s0,-52
    80002fd2:	4501                	li	a0,0
    80002fd4:	00000097          	auipc	ra,0x0
    80002fd8:	e2a080e7          	jalr	-470(ra) # 80002dfe <argint>
    return -1;
    80002fdc:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002fde:	06054563          	bltz	a0,80003048 <sys_sleep+0x88>
  acquire(&tickslock);
    80002fe2:	00015517          	auipc	a0,0x15
    80002fe6:	3c650513          	addi	a0,a0,966 # 800183a8 <tickslock>
    80002fea:	ffffe097          	auipc	ra,0xffffe
    80002fee:	d0e080e7          	jalr	-754(ra) # 80000cf8 <acquire>
  ticks0 = ticks;
    80002ff2:	00006917          	auipc	s2,0x6
    80002ff6:	02e92903          	lw	s2,46(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    80002ffa:	fcc42783          	lw	a5,-52(s0)
    80002ffe:	cf85                	beqz	a5,80003036 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003000:	00015997          	auipc	s3,0x15
    80003004:	3a898993          	addi	s3,s3,936 # 800183a8 <tickslock>
    80003008:	00006497          	auipc	s1,0x6
    8000300c:	01848493          	addi	s1,s1,24 # 80009020 <ticks>
    if(myproc()->killed){
    80003010:	fffff097          	auipc	ra,0xfffff
    80003014:	d30080e7          	jalr	-720(ra) # 80001d40 <myproc>
    80003018:	5d1c                	lw	a5,56(a0)
    8000301a:	ef9d                	bnez	a5,80003058 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    8000301c:	85ce                	mv	a1,s3
    8000301e:	8526                	mv	a0,s1
    80003020:	fffff097          	auipc	ra,0xfffff
    80003024:	530080e7          	jalr	1328(ra) # 80002550 <sleep>
  while(ticks - ticks0 < n){
    80003028:	409c                	lw	a5,0(s1)
    8000302a:	412787bb          	subw	a5,a5,s2
    8000302e:	fcc42703          	lw	a4,-52(s0)
    80003032:	fce7efe3          	bltu	a5,a4,80003010 <sys_sleep+0x50>
  }
  release(&tickslock);
    80003036:	00015517          	auipc	a0,0x15
    8000303a:	37250513          	addi	a0,a0,882 # 800183a8 <tickslock>
    8000303e:	ffffe097          	auipc	ra,0xffffe
    80003042:	d8a080e7          	jalr	-630(ra) # 80000dc8 <release>
  return 0;
    80003046:	4781                	li	a5,0
}
    80003048:	853e                	mv	a0,a5
    8000304a:	70e2                	ld	ra,56(sp)
    8000304c:	7442                	ld	s0,48(sp)
    8000304e:	74a2                	ld	s1,40(sp)
    80003050:	7902                	ld	s2,32(sp)
    80003052:	69e2                	ld	s3,24(sp)
    80003054:	6121                	addi	sp,sp,64
    80003056:	8082                	ret
      release(&tickslock);
    80003058:	00015517          	auipc	a0,0x15
    8000305c:	35050513          	addi	a0,a0,848 # 800183a8 <tickslock>
    80003060:	ffffe097          	auipc	ra,0xffffe
    80003064:	d68080e7          	jalr	-664(ra) # 80000dc8 <release>
      return -1;
    80003068:	57fd                	li	a5,-1
    8000306a:	bff9                	j	80003048 <sys_sleep+0x88>

000000008000306c <sys_kill>:

uint64
sys_kill(void)
{
    8000306c:	1101                	addi	sp,sp,-32
    8000306e:	ec06                	sd	ra,24(sp)
    80003070:	e822                	sd	s0,16(sp)
    80003072:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80003074:	fec40593          	addi	a1,s0,-20
    80003078:	4501                	li	a0,0
    8000307a:	00000097          	auipc	ra,0x0
    8000307e:	d84080e7          	jalr	-636(ra) # 80002dfe <argint>
    80003082:	87aa                	mv	a5,a0
    return -1;
    80003084:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80003086:	0007c863          	bltz	a5,80003096 <sys_kill+0x2a>
  return kill(pid);
    8000308a:	fec42503          	lw	a0,-20(s0)
    8000308e:	fffff097          	auipc	ra,0xfffff
    80003092:	6b2080e7          	jalr	1714(ra) # 80002740 <kill>
}
    80003096:	60e2                	ld	ra,24(sp)
    80003098:	6442                	ld	s0,16(sp)
    8000309a:	6105                	addi	sp,sp,32
    8000309c:	8082                	ret

000000008000309e <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    8000309e:	1101                	addi	sp,sp,-32
    800030a0:	ec06                	sd	ra,24(sp)
    800030a2:	e822                	sd	s0,16(sp)
    800030a4:	e426                	sd	s1,8(sp)
    800030a6:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800030a8:	00015517          	auipc	a0,0x15
    800030ac:	30050513          	addi	a0,a0,768 # 800183a8 <tickslock>
    800030b0:	ffffe097          	auipc	ra,0xffffe
    800030b4:	c48080e7          	jalr	-952(ra) # 80000cf8 <acquire>
  xticks = ticks;
    800030b8:	00006497          	auipc	s1,0x6
    800030bc:	f684a483          	lw	s1,-152(s1) # 80009020 <ticks>
  release(&tickslock);
    800030c0:	00015517          	auipc	a0,0x15
    800030c4:	2e850513          	addi	a0,a0,744 # 800183a8 <tickslock>
    800030c8:	ffffe097          	auipc	ra,0xffffe
    800030cc:	d00080e7          	jalr	-768(ra) # 80000dc8 <release>
  return xticks;
}
    800030d0:	02049513          	slli	a0,s1,0x20
    800030d4:	9101                	srli	a0,a0,0x20
    800030d6:	60e2                	ld	ra,24(sp)
    800030d8:	6442                	ld	s0,16(sp)
    800030da:	64a2                	ld	s1,8(sp)
    800030dc:	6105                	addi	sp,sp,32
    800030de:	8082                	ret

00000000800030e0 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800030e0:	7179                	addi	sp,sp,-48
    800030e2:	f406                	sd	ra,40(sp)
    800030e4:	f022                	sd	s0,32(sp)
    800030e6:	ec26                	sd	s1,24(sp)
    800030e8:	e84a                	sd	s2,16(sp)
    800030ea:	e44e                	sd	s3,8(sp)
    800030ec:	e052                	sd	s4,0(sp)
    800030ee:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800030f0:	00005597          	auipc	a1,0x5
    800030f4:	01058593          	addi	a1,a1,16 # 80008100 <digits+0xc0>
    800030f8:	00015517          	auipc	a0,0x15
    800030fc:	2d050513          	addi	a0,a0,720 # 800183c8 <bcache>
    80003100:	ffffe097          	auipc	ra,0xffffe
    80003104:	d74080e7          	jalr	-652(ra) # 80000e74 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003108:	0001d797          	auipc	a5,0x1d
    8000310c:	2c078793          	addi	a5,a5,704 # 800203c8 <bcache+0x8000>
    80003110:	0001d717          	auipc	a4,0x1d
    80003114:	61870713          	addi	a4,a4,1560 # 80020728 <bcache+0x8360>
    80003118:	3ae7b823          	sd	a4,944(a5)
  bcache.head.next = &bcache.head;
    8000311c:	3ae7bc23          	sd	a4,952(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003120:	00015497          	auipc	s1,0x15
    80003124:	2c848493          	addi	s1,s1,712 # 800183e8 <bcache+0x20>
    b->next = bcache.head.next;
    80003128:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000312a:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000312c:	00005a17          	auipc	s4,0x5
    80003130:	43ca0a13          	addi	s4,s4,1084 # 80008568 <syscalls+0xb0>
    b->next = bcache.head.next;
    80003134:	3b893783          	ld	a5,952(s2)
    80003138:	ecbc                	sd	a5,88(s1)
    b->prev = &bcache.head;
    8000313a:	0534b823          	sd	s3,80(s1)
    initsleeplock(&b->lock, "buffer");
    8000313e:	85d2                	mv	a1,s4
    80003140:	01048513          	addi	a0,s1,16
    80003144:	00001097          	auipc	ra,0x1
    80003148:	4c2080e7          	jalr	1218(ra) # 80004606 <initsleeplock>
    bcache.head.next->prev = b;
    8000314c:	3b893783          	ld	a5,952(s2)
    80003150:	eba4                	sd	s1,80(a5)
    bcache.head.next = b;
    80003152:	3a993c23          	sd	s1,952(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003156:	46048493          	addi	s1,s1,1120
    8000315a:	fd349de3          	bne	s1,s3,80003134 <binit+0x54>
  }
}
    8000315e:	70a2                	ld	ra,40(sp)
    80003160:	7402                	ld	s0,32(sp)
    80003162:	64e2                	ld	s1,24(sp)
    80003164:	6942                	ld	s2,16(sp)
    80003166:	69a2                	ld	s3,8(sp)
    80003168:	6a02                	ld	s4,0(sp)
    8000316a:	6145                	addi	sp,sp,48
    8000316c:	8082                	ret

000000008000316e <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000316e:	7179                	addi	sp,sp,-48
    80003170:	f406                	sd	ra,40(sp)
    80003172:	f022                	sd	s0,32(sp)
    80003174:	ec26                	sd	s1,24(sp)
    80003176:	e84a                	sd	s2,16(sp)
    80003178:	e44e                	sd	s3,8(sp)
    8000317a:	1800                	addi	s0,sp,48
    8000317c:	89aa                	mv	s3,a0
    8000317e:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003180:	00015517          	auipc	a0,0x15
    80003184:	24850513          	addi	a0,a0,584 # 800183c8 <bcache>
    80003188:	ffffe097          	auipc	ra,0xffffe
    8000318c:	b70080e7          	jalr	-1168(ra) # 80000cf8 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003190:	0001d497          	auipc	s1,0x1d
    80003194:	5f04b483          	ld	s1,1520(s1) # 80020780 <bcache+0x83b8>
    80003198:	0001d797          	auipc	a5,0x1d
    8000319c:	59078793          	addi	a5,a5,1424 # 80020728 <bcache+0x8360>
    800031a0:	02f48f63          	beq	s1,a5,800031de <bread+0x70>
    800031a4:	873e                	mv	a4,a5
    800031a6:	a021                	j	800031ae <bread+0x40>
    800031a8:	6ca4                	ld	s1,88(s1)
    800031aa:	02e48a63          	beq	s1,a4,800031de <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800031ae:	449c                	lw	a5,8(s1)
    800031b0:	ff379ce3          	bne	a5,s3,800031a8 <bread+0x3a>
    800031b4:	44dc                	lw	a5,12(s1)
    800031b6:	ff2799e3          	bne	a5,s2,800031a8 <bread+0x3a>
      b->refcnt++;
    800031ba:	44bc                	lw	a5,72(s1)
    800031bc:	2785                	addiw	a5,a5,1
    800031be:	c4bc                	sw	a5,72(s1)
      release(&bcache.lock);
    800031c0:	00015517          	auipc	a0,0x15
    800031c4:	20850513          	addi	a0,a0,520 # 800183c8 <bcache>
    800031c8:	ffffe097          	auipc	ra,0xffffe
    800031cc:	c00080e7          	jalr	-1024(ra) # 80000dc8 <release>
      acquiresleep(&b->lock);
    800031d0:	01048513          	addi	a0,s1,16
    800031d4:	00001097          	auipc	ra,0x1
    800031d8:	46c080e7          	jalr	1132(ra) # 80004640 <acquiresleep>
      return b;
    800031dc:	a8b9                	j	8000323a <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800031de:	0001d497          	auipc	s1,0x1d
    800031e2:	59a4b483          	ld	s1,1434(s1) # 80020778 <bcache+0x83b0>
    800031e6:	0001d797          	auipc	a5,0x1d
    800031ea:	54278793          	addi	a5,a5,1346 # 80020728 <bcache+0x8360>
    800031ee:	00f48863          	beq	s1,a5,800031fe <bread+0x90>
    800031f2:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800031f4:	44bc                	lw	a5,72(s1)
    800031f6:	cf81                	beqz	a5,8000320e <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800031f8:	68a4                	ld	s1,80(s1)
    800031fa:	fee49de3          	bne	s1,a4,800031f4 <bread+0x86>
  panic("bget: no buffers");
    800031fe:	00005517          	auipc	a0,0x5
    80003202:	37250513          	addi	a0,a0,882 # 80008570 <syscalls+0xb8>
    80003206:	ffffd097          	auipc	ra,0xffffd
    8000320a:	34a080e7          	jalr	842(ra) # 80000550 <panic>
      b->dev = dev;
    8000320e:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003212:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003216:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000321a:	4785                	li	a5,1
    8000321c:	c4bc                	sw	a5,72(s1)
      release(&bcache.lock);
    8000321e:	00015517          	auipc	a0,0x15
    80003222:	1aa50513          	addi	a0,a0,426 # 800183c8 <bcache>
    80003226:	ffffe097          	auipc	ra,0xffffe
    8000322a:	ba2080e7          	jalr	-1118(ra) # 80000dc8 <release>
      acquiresleep(&b->lock);
    8000322e:	01048513          	addi	a0,s1,16
    80003232:	00001097          	auipc	ra,0x1
    80003236:	40e080e7          	jalr	1038(ra) # 80004640 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000323a:	409c                	lw	a5,0(s1)
    8000323c:	cb89                	beqz	a5,8000324e <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000323e:	8526                	mv	a0,s1
    80003240:	70a2                	ld	ra,40(sp)
    80003242:	7402                	ld	s0,32(sp)
    80003244:	64e2                	ld	s1,24(sp)
    80003246:	6942                	ld	s2,16(sp)
    80003248:	69a2                	ld	s3,8(sp)
    8000324a:	6145                	addi	sp,sp,48
    8000324c:	8082                	ret
    virtio_disk_rw(b, 0);
    8000324e:	4581                	li	a1,0
    80003250:	8526                	mv	a0,s1
    80003252:	00003097          	auipc	ra,0x3
    80003256:	f74080e7          	jalr	-140(ra) # 800061c6 <virtio_disk_rw>
    b->valid = 1;
    8000325a:	4785                	li	a5,1
    8000325c:	c09c                	sw	a5,0(s1)
  return b;
    8000325e:	b7c5                	j	8000323e <bread+0xd0>

0000000080003260 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003260:	1101                	addi	sp,sp,-32
    80003262:	ec06                	sd	ra,24(sp)
    80003264:	e822                	sd	s0,16(sp)
    80003266:	e426                	sd	s1,8(sp)
    80003268:	1000                	addi	s0,sp,32
    8000326a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000326c:	0541                	addi	a0,a0,16
    8000326e:	00001097          	auipc	ra,0x1
    80003272:	46c080e7          	jalr	1132(ra) # 800046da <holdingsleep>
    80003276:	cd01                	beqz	a0,8000328e <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003278:	4585                	li	a1,1
    8000327a:	8526                	mv	a0,s1
    8000327c:	00003097          	auipc	ra,0x3
    80003280:	f4a080e7          	jalr	-182(ra) # 800061c6 <virtio_disk_rw>
}
    80003284:	60e2                	ld	ra,24(sp)
    80003286:	6442                	ld	s0,16(sp)
    80003288:	64a2                	ld	s1,8(sp)
    8000328a:	6105                	addi	sp,sp,32
    8000328c:	8082                	ret
    panic("bwrite");
    8000328e:	00005517          	auipc	a0,0x5
    80003292:	2fa50513          	addi	a0,a0,762 # 80008588 <syscalls+0xd0>
    80003296:	ffffd097          	auipc	ra,0xffffd
    8000329a:	2ba080e7          	jalr	698(ra) # 80000550 <panic>

000000008000329e <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000329e:	1101                	addi	sp,sp,-32
    800032a0:	ec06                	sd	ra,24(sp)
    800032a2:	e822                	sd	s0,16(sp)
    800032a4:	e426                	sd	s1,8(sp)
    800032a6:	e04a                	sd	s2,0(sp)
    800032a8:	1000                	addi	s0,sp,32
    800032aa:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800032ac:	01050913          	addi	s2,a0,16
    800032b0:	854a                	mv	a0,s2
    800032b2:	00001097          	auipc	ra,0x1
    800032b6:	428080e7          	jalr	1064(ra) # 800046da <holdingsleep>
    800032ba:	c92d                	beqz	a0,8000332c <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800032bc:	854a                	mv	a0,s2
    800032be:	00001097          	auipc	ra,0x1
    800032c2:	3d8080e7          	jalr	984(ra) # 80004696 <releasesleep>

  acquire(&bcache.lock);
    800032c6:	00015517          	auipc	a0,0x15
    800032ca:	10250513          	addi	a0,a0,258 # 800183c8 <bcache>
    800032ce:	ffffe097          	auipc	ra,0xffffe
    800032d2:	a2a080e7          	jalr	-1494(ra) # 80000cf8 <acquire>
  b->refcnt--;
    800032d6:	44bc                	lw	a5,72(s1)
    800032d8:	37fd                	addiw	a5,a5,-1
    800032da:	0007871b          	sext.w	a4,a5
    800032de:	c4bc                	sw	a5,72(s1)
  if (b->refcnt == 0) {
    800032e0:	eb05                	bnez	a4,80003310 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800032e2:	6cbc                	ld	a5,88(s1)
    800032e4:	68b8                	ld	a4,80(s1)
    800032e6:	ebb8                	sd	a4,80(a5)
    b->prev->next = b->next;
    800032e8:	68bc                	ld	a5,80(s1)
    800032ea:	6cb8                	ld	a4,88(s1)
    800032ec:	efb8                	sd	a4,88(a5)
    b->next = bcache.head.next;
    800032ee:	0001d797          	auipc	a5,0x1d
    800032f2:	0da78793          	addi	a5,a5,218 # 800203c8 <bcache+0x8000>
    800032f6:	3b87b703          	ld	a4,952(a5)
    800032fa:	ecb8                	sd	a4,88(s1)
    b->prev = &bcache.head;
    800032fc:	0001d717          	auipc	a4,0x1d
    80003300:	42c70713          	addi	a4,a4,1068 # 80020728 <bcache+0x8360>
    80003304:	e8b8                	sd	a4,80(s1)
    bcache.head.next->prev = b;
    80003306:	3b87b703          	ld	a4,952(a5)
    8000330a:	eb24                	sd	s1,80(a4)
    bcache.head.next = b;
    8000330c:	3a97bc23          	sd	s1,952(a5)
  }
  
  release(&bcache.lock);
    80003310:	00015517          	auipc	a0,0x15
    80003314:	0b850513          	addi	a0,a0,184 # 800183c8 <bcache>
    80003318:	ffffe097          	auipc	ra,0xffffe
    8000331c:	ab0080e7          	jalr	-1360(ra) # 80000dc8 <release>
}
    80003320:	60e2                	ld	ra,24(sp)
    80003322:	6442                	ld	s0,16(sp)
    80003324:	64a2                	ld	s1,8(sp)
    80003326:	6902                	ld	s2,0(sp)
    80003328:	6105                	addi	sp,sp,32
    8000332a:	8082                	ret
    panic("brelse");
    8000332c:	00005517          	auipc	a0,0x5
    80003330:	26450513          	addi	a0,a0,612 # 80008590 <syscalls+0xd8>
    80003334:	ffffd097          	auipc	ra,0xffffd
    80003338:	21c080e7          	jalr	540(ra) # 80000550 <panic>

000000008000333c <bpin>:

void
bpin(struct buf *b) {
    8000333c:	1101                	addi	sp,sp,-32
    8000333e:	ec06                	sd	ra,24(sp)
    80003340:	e822                	sd	s0,16(sp)
    80003342:	e426                	sd	s1,8(sp)
    80003344:	1000                	addi	s0,sp,32
    80003346:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003348:	00015517          	auipc	a0,0x15
    8000334c:	08050513          	addi	a0,a0,128 # 800183c8 <bcache>
    80003350:	ffffe097          	auipc	ra,0xffffe
    80003354:	9a8080e7          	jalr	-1624(ra) # 80000cf8 <acquire>
  b->refcnt++;
    80003358:	44bc                	lw	a5,72(s1)
    8000335a:	2785                	addiw	a5,a5,1
    8000335c:	c4bc                	sw	a5,72(s1)
  release(&bcache.lock);
    8000335e:	00015517          	auipc	a0,0x15
    80003362:	06a50513          	addi	a0,a0,106 # 800183c8 <bcache>
    80003366:	ffffe097          	auipc	ra,0xffffe
    8000336a:	a62080e7          	jalr	-1438(ra) # 80000dc8 <release>
}
    8000336e:	60e2                	ld	ra,24(sp)
    80003370:	6442                	ld	s0,16(sp)
    80003372:	64a2                	ld	s1,8(sp)
    80003374:	6105                	addi	sp,sp,32
    80003376:	8082                	ret

0000000080003378 <bunpin>:

void
bunpin(struct buf *b) {
    80003378:	1101                	addi	sp,sp,-32
    8000337a:	ec06                	sd	ra,24(sp)
    8000337c:	e822                	sd	s0,16(sp)
    8000337e:	e426                	sd	s1,8(sp)
    80003380:	1000                	addi	s0,sp,32
    80003382:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003384:	00015517          	auipc	a0,0x15
    80003388:	04450513          	addi	a0,a0,68 # 800183c8 <bcache>
    8000338c:	ffffe097          	auipc	ra,0xffffe
    80003390:	96c080e7          	jalr	-1684(ra) # 80000cf8 <acquire>
  b->refcnt--;
    80003394:	44bc                	lw	a5,72(s1)
    80003396:	37fd                	addiw	a5,a5,-1
    80003398:	c4bc                	sw	a5,72(s1)
  release(&bcache.lock);
    8000339a:	00015517          	auipc	a0,0x15
    8000339e:	02e50513          	addi	a0,a0,46 # 800183c8 <bcache>
    800033a2:	ffffe097          	auipc	ra,0xffffe
    800033a6:	a26080e7          	jalr	-1498(ra) # 80000dc8 <release>
}
    800033aa:	60e2                	ld	ra,24(sp)
    800033ac:	6442                	ld	s0,16(sp)
    800033ae:	64a2                	ld	s1,8(sp)
    800033b0:	6105                	addi	sp,sp,32
    800033b2:	8082                	ret

00000000800033b4 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800033b4:	1101                	addi	sp,sp,-32
    800033b6:	ec06                	sd	ra,24(sp)
    800033b8:	e822                	sd	s0,16(sp)
    800033ba:	e426                	sd	s1,8(sp)
    800033bc:	e04a                	sd	s2,0(sp)
    800033be:	1000                	addi	s0,sp,32
    800033c0:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800033c2:	00d5d59b          	srliw	a1,a1,0xd
    800033c6:	0001d797          	auipc	a5,0x1d
    800033ca:	7de7a783          	lw	a5,2014(a5) # 80020ba4 <sb+0x1c>
    800033ce:	9dbd                	addw	a1,a1,a5
    800033d0:	00000097          	auipc	ra,0x0
    800033d4:	d9e080e7          	jalr	-610(ra) # 8000316e <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800033d8:	0074f713          	andi	a4,s1,7
    800033dc:	4785                	li	a5,1
    800033de:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800033e2:	14ce                	slli	s1,s1,0x33
    800033e4:	90d9                	srli	s1,s1,0x36
    800033e6:	00950733          	add	a4,a0,s1
    800033ea:	06074703          	lbu	a4,96(a4)
    800033ee:	00e7f6b3          	and	a3,a5,a4
    800033f2:	c69d                	beqz	a3,80003420 <bfree+0x6c>
    800033f4:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800033f6:	94aa                	add	s1,s1,a0
    800033f8:	fff7c793          	not	a5,a5
    800033fc:	8ff9                	and	a5,a5,a4
    800033fe:	06f48023          	sb	a5,96(s1)
  log_write(bp);
    80003402:	00001097          	auipc	ra,0x1
    80003406:	116080e7          	jalr	278(ra) # 80004518 <log_write>
  brelse(bp);
    8000340a:	854a                	mv	a0,s2
    8000340c:	00000097          	auipc	ra,0x0
    80003410:	e92080e7          	jalr	-366(ra) # 8000329e <brelse>
}
    80003414:	60e2                	ld	ra,24(sp)
    80003416:	6442                	ld	s0,16(sp)
    80003418:	64a2                	ld	s1,8(sp)
    8000341a:	6902                	ld	s2,0(sp)
    8000341c:	6105                	addi	sp,sp,32
    8000341e:	8082                	ret
    panic("freeing free block");
    80003420:	00005517          	auipc	a0,0x5
    80003424:	17850513          	addi	a0,a0,376 # 80008598 <syscalls+0xe0>
    80003428:	ffffd097          	auipc	ra,0xffffd
    8000342c:	128080e7          	jalr	296(ra) # 80000550 <panic>

0000000080003430 <balloc>:
{
    80003430:	711d                	addi	sp,sp,-96
    80003432:	ec86                	sd	ra,88(sp)
    80003434:	e8a2                	sd	s0,80(sp)
    80003436:	e4a6                	sd	s1,72(sp)
    80003438:	e0ca                	sd	s2,64(sp)
    8000343a:	fc4e                	sd	s3,56(sp)
    8000343c:	f852                	sd	s4,48(sp)
    8000343e:	f456                	sd	s5,40(sp)
    80003440:	f05a                	sd	s6,32(sp)
    80003442:	ec5e                	sd	s7,24(sp)
    80003444:	e862                	sd	s8,16(sp)
    80003446:	e466                	sd	s9,8(sp)
    80003448:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000344a:	0001d797          	auipc	a5,0x1d
    8000344e:	7427a783          	lw	a5,1858(a5) # 80020b8c <sb+0x4>
    80003452:	cbd1                	beqz	a5,800034e6 <balloc+0xb6>
    80003454:	8baa                	mv	s7,a0
    80003456:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003458:	0001db17          	auipc	s6,0x1d
    8000345c:	730b0b13          	addi	s6,s6,1840 # 80020b88 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003460:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003462:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003464:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003466:	6c89                	lui	s9,0x2
    80003468:	a831                	j	80003484 <balloc+0x54>
    brelse(bp);
    8000346a:	854a                	mv	a0,s2
    8000346c:	00000097          	auipc	ra,0x0
    80003470:	e32080e7          	jalr	-462(ra) # 8000329e <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003474:	015c87bb          	addw	a5,s9,s5
    80003478:	00078a9b          	sext.w	s5,a5
    8000347c:	004b2703          	lw	a4,4(s6)
    80003480:	06eaf363          	bgeu	s5,a4,800034e6 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003484:	41fad79b          	sraiw	a5,s5,0x1f
    80003488:	0137d79b          	srliw	a5,a5,0x13
    8000348c:	015787bb          	addw	a5,a5,s5
    80003490:	40d7d79b          	sraiw	a5,a5,0xd
    80003494:	01cb2583          	lw	a1,28(s6)
    80003498:	9dbd                	addw	a1,a1,a5
    8000349a:	855e                	mv	a0,s7
    8000349c:	00000097          	auipc	ra,0x0
    800034a0:	cd2080e7          	jalr	-814(ra) # 8000316e <bread>
    800034a4:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034a6:	004b2503          	lw	a0,4(s6)
    800034aa:	000a849b          	sext.w	s1,s5
    800034ae:	8662                	mv	a2,s8
    800034b0:	faa4fde3          	bgeu	s1,a0,8000346a <balloc+0x3a>
      m = 1 << (bi % 8);
    800034b4:	41f6579b          	sraiw	a5,a2,0x1f
    800034b8:	01d7d69b          	srliw	a3,a5,0x1d
    800034bc:	00c6873b          	addw	a4,a3,a2
    800034c0:	00777793          	andi	a5,a4,7
    800034c4:	9f95                	subw	a5,a5,a3
    800034c6:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800034ca:	4037571b          	sraiw	a4,a4,0x3
    800034ce:	00e906b3          	add	a3,s2,a4
    800034d2:	0606c683          	lbu	a3,96(a3)
    800034d6:	00d7f5b3          	and	a1,a5,a3
    800034da:	cd91                	beqz	a1,800034f6 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034dc:	2605                	addiw	a2,a2,1
    800034de:	2485                	addiw	s1,s1,1
    800034e0:	fd4618e3          	bne	a2,s4,800034b0 <balloc+0x80>
    800034e4:	b759                	j	8000346a <balloc+0x3a>
  panic("balloc: out of blocks");
    800034e6:	00005517          	auipc	a0,0x5
    800034ea:	0ca50513          	addi	a0,a0,202 # 800085b0 <syscalls+0xf8>
    800034ee:	ffffd097          	auipc	ra,0xffffd
    800034f2:	062080e7          	jalr	98(ra) # 80000550 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800034f6:	974a                	add	a4,a4,s2
    800034f8:	8fd5                	or	a5,a5,a3
    800034fa:	06f70023          	sb	a5,96(a4)
        log_write(bp);
    800034fe:	854a                	mv	a0,s2
    80003500:	00001097          	auipc	ra,0x1
    80003504:	018080e7          	jalr	24(ra) # 80004518 <log_write>
        brelse(bp);
    80003508:	854a                	mv	a0,s2
    8000350a:	00000097          	auipc	ra,0x0
    8000350e:	d94080e7          	jalr	-620(ra) # 8000329e <brelse>
  bp = bread(dev, bno);
    80003512:	85a6                	mv	a1,s1
    80003514:	855e                	mv	a0,s7
    80003516:	00000097          	auipc	ra,0x0
    8000351a:	c58080e7          	jalr	-936(ra) # 8000316e <bread>
    8000351e:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003520:	40000613          	li	a2,1024
    80003524:	4581                	li	a1,0
    80003526:	06050513          	addi	a0,a0,96
    8000352a:	ffffe097          	auipc	ra,0xffffe
    8000352e:	bae080e7          	jalr	-1106(ra) # 800010d8 <memset>
  log_write(bp);
    80003532:	854a                	mv	a0,s2
    80003534:	00001097          	auipc	ra,0x1
    80003538:	fe4080e7          	jalr	-28(ra) # 80004518 <log_write>
  brelse(bp);
    8000353c:	854a                	mv	a0,s2
    8000353e:	00000097          	auipc	ra,0x0
    80003542:	d60080e7          	jalr	-672(ra) # 8000329e <brelse>
}
    80003546:	8526                	mv	a0,s1
    80003548:	60e6                	ld	ra,88(sp)
    8000354a:	6446                	ld	s0,80(sp)
    8000354c:	64a6                	ld	s1,72(sp)
    8000354e:	6906                	ld	s2,64(sp)
    80003550:	79e2                	ld	s3,56(sp)
    80003552:	7a42                	ld	s4,48(sp)
    80003554:	7aa2                	ld	s5,40(sp)
    80003556:	7b02                	ld	s6,32(sp)
    80003558:	6be2                	ld	s7,24(sp)
    8000355a:	6c42                	ld	s8,16(sp)
    8000355c:	6ca2                	ld	s9,8(sp)
    8000355e:	6125                	addi	sp,sp,96
    80003560:	8082                	ret

0000000080003562 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003562:	7179                	addi	sp,sp,-48
    80003564:	f406                	sd	ra,40(sp)
    80003566:	f022                	sd	s0,32(sp)
    80003568:	ec26                	sd	s1,24(sp)
    8000356a:	e84a                	sd	s2,16(sp)
    8000356c:	e44e                	sd	s3,8(sp)
    8000356e:	e052                	sd	s4,0(sp)
    80003570:	1800                	addi	s0,sp,48
    80003572:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003574:	47ad                	li	a5,11
    80003576:	04b7fe63          	bgeu	a5,a1,800035d2 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    8000357a:	ff45849b          	addiw	s1,a1,-12
    8000357e:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003582:	0ff00793          	li	a5,255
    80003586:	0ae7e363          	bltu	a5,a4,8000362c <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    8000358a:	08852583          	lw	a1,136(a0)
    8000358e:	c5ad                	beqz	a1,800035f8 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003590:	00092503          	lw	a0,0(s2)
    80003594:	00000097          	auipc	ra,0x0
    80003598:	bda080e7          	jalr	-1062(ra) # 8000316e <bread>
    8000359c:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000359e:	06050793          	addi	a5,a0,96
    if((addr = a[bn]) == 0){
    800035a2:	02049593          	slli	a1,s1,0x20
    800035a6:	9181                	srli	a1,a1,0x20
    800035a8:	058a                	slli	a1,a1,0x2
    800035aa:	00b784b3          	add	s1,a5,a1
    800035ae:	0004a983          	lw	s3,0(s1)
    800035b2:	04098d63          	beqz	s3,8000360c <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800035b6:	8552                	mv	a0,s4
    800035b8:	00000097          	auipc	ra,0x0
    800035bc:	ce6080e7          	jalr	-794(ra) # 8000329e <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800035c0:	854e                	mv	a0,s3
    800035c2:	70a2                	ld	ra,40(sp)
    800035c4:	7402                	ld	s0,32(sp)
    800035c6:	64e2                	ld	s1,24(sp)
    800035c8:	6942                	ld	s2,16(sp)
    800035ca:	69a2                	ld	s3,8(sp)
    800035cc:	6a02                	ld	s4,0(sp)
    800035ce:	6145                	addi	sp,sp,48
    800035d0:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800035d2:	02059493          	slli	s1,a1,0x20
    800035d6:	9081                	srli	s1,s1,0x20
    800035d8:	048a                	slli	s1,s1,0x2
    800035da:	94aa                	add	s1,s1,a0
    800035dc:	0584a983          	lw	s3,88(s1)
    800035e0:	fe0990e3          	bnez	s3,800035c0 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800035e4:	4108                	lw	a0,0(a0)
    800035e6:	00000097          	auipc	ra,0x0
    800035ea:	e4a080e7          	jalr	-438(ra) # 80003430 <balloc>
    800035ee:	0005099b          	sext.w	s3,a0
    800035f2:	0534ac23          	sw	s3,88(s1)
    800035f6:	b7e9                	j	800035c0 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800035f8:	4108                	lw	a0,0(a0)
    800035fa:	00000097          	auipc	ra,0x0
    800035fe:	e36080e7          	jalr	-458(ra) # 80003430 <balloc>
    80003602:	0005059b          	sext.w	a1,a0
    80003606:	08b92423          	sw	a1,136(s2)
    8000360a:	b759                	j	80003590 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    8000360c:	00092503          	lw	a0,0(s2)
    80003610:	00000097          	auipc	ra,0x0
    80003614:	e20080e7          	jalr	-480(ra) # 80003430 <balloc>
    80003618:	0005099b          	sext.w	s3,a0
    8000361c:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003620:	8552                	mv	a0,s4
    80003622:	00001097          	auipc	ra,0x1
    80003626:	ef6080e7          	jalr	-266(ra) # 80004518 <log_write>
    8000362a:	b771                	j	800035b6 <bmap+0x54>
  panic("bmap: out of range");
    8000362c:	00005517          	auipc	a0,0x5
    80003630:	f9c50513          	addi	a0,a0,-100 # 800085c8 <syscalls+0x110>
    80003634:	ffffd097          	auipc	ra,0xffffd
    80003638:	f1c080e7          	jalr	-228(ra) # 80000550 <panic>

000000008000363c <iget>:
{
    8000363c:	7179                	addi	sp,sp,-48
    8000363e:	f406                	sd	ra,40(sp)
    80003640:	f022                	sd	s0,32(sp)
    80003642:	ec26                	sd	s1,24(sp)
    80003644:	e84a                	sd	s2,16(sp)
    80003646:	e44e                	sd	s3,8(sp)
    80003648:	e052                	sd	s4,0(sp)
    8000364a:	1800                	addi	s0,sp,48
    8000364c:	89aa                	mv	s3,a0
    8000364e:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    80003650:	0001d517          	auipc	a0,0x1d
    80003654:	55850513          	addi	a0,a0,1368 # 80020ba8 <icache>
    80003658:	ffffd097          	auipc	ra,0xffffd
    8000365c:	6a0080e7          	jalr	1696(ra) # 80000cf8 <acquire>
  empty = 0;
    80003660:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003662:	0001d497          	auipc	s1,0x1d
    80003666:	56648493          	addi	s1,s1,1382 # 80020bc8 <icache+0x20>
    8000366a:	0001f697          	auipc	a3,0x1f
    8000366e:	17e68693          	addi	a3,a3,382 # 800227e8 <log>
    80003672:	a039                	j	80003680 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003674:	02090b63          	beqz	s2,800036aa <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003678:	09048493          	addi	s1,s1,144
    8000367c:	02d48a63          	beq	s1,a3,800036b0 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003680:	449c                	lw	a5,8(s1)
    80003682:	fef059e3          	blez	a5,80003674 <iget+0x38>
    80003686:	4098                	lw	a4,0(s1)
    80003688:	ff3716e3          	bne	a4,s3,80003674 <iget+0x38>
    8000368c:	40d8                	lw	a4,4(s1)
    8000368e:	ff4713e3          	bne	a4,s4,80003674 <iget+0x38>
      ip->ref++;
    80003692:	2785                	addiw	a5,a5,1
    80003694:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    80003696:	0001d517          	auipc	a0,0x1d
    8000369a:	51250513          	addi	a0,a0,1298 # 80020ba8 <icache>
    8000369e:	ffffd097          	auipc	ra,0xffffd
    800036a2:	72a080e7          	jalr	1834(ra) # 80000dc8 <release>
      return ip;
    800036a6:	8926                	mv	s2,s1
    800036a8:	a03d                	j	800036d6 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800036aa:	f7f9                	bnez	a5,80003678 <iget+0x3c>
    800036ac:	8926                	mv	s2,s1
    800036ae:	b7e9                	j	80003678 <iget+0x3c>
  if(empty == 0)
    800036b0:	02090c63          	beqz	s2,800036e8 <iget+0xac>
  ip->dev = dev;
    800036b4:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800036b8:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800036bc:	4785                	li	a5,1
    800036be:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800036c2:	04092423          	sw	zero,72(s2)
  release(&icache.lock);
    800036c6:	0001d517          	auipc	a0,0x1d
    800036ca:	4e250513          	addi	a0,a0,1250 # 80020ba8 <icache>
    800036ce:	ffffd097          	auipc	ra,0xffffd
    800036d2:	6fa080e7          	jalr	1786(ra) # 80000dc8 <release>
}
    800036d6:	854a                	mv	a0,s2
    800036d8:	70a2                	ld	ra,40(sp)
    800036da:	7402                	ld	s0,32(sp)
    800036dc:	64e2                	ld	s1,24(sp)
    800036de:	6942                	ld	s2,16(sp)
    800036e0:	69a2                	ld	s3,8(sp)
    800036e2:	6a02                	ld	s4,0(sp)
    800036e4:	6145                	addi	sp,sp,48
    800036e6:	8082                	ret
    panic("iget: no inodes");
    800036e8:	00005517          	auipc	a0,0x5
    800036ec:	ef850513          	addi	a0,a0,-264 # 800085e0 <syscalls+0x128>
    800036f0:	ffffd097          	auipc	ra,0xffffd
    800036f4:	e60080e7          	jalr	-416(ra) # 80000550 <panic>

00000000800036f8 <fsinit>:
fsinit(int dev) {
    800036f8:	7179                	addi	sp,sp,-48
    800036fa:	f406                	sd	ra,40(sp)
    800036fc:	f022                	sd	s0,32(sp)
    800036fe:	ec26                	sd	s1,24(sp)
    80003700:	e84a                	sd	s2,16(sp)
    80003702:	e44e                	sd	s3,8(sp)
    80003704:	1800                	addi	s0,sp,48
    80003706:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003708:	4585                	li	a1,1
    8000370a:	00000097          	auipc	ra,0x0
    8000370e:	a64080e7          	jalr	-1436(ra) # 8000316e <bread>
    80003712:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003714:	0001d997          	auipc	s3,0x1d
    80003718:	47498993          	addi	s3,s3,1140 # 80020b88 <sb>
    8000371c:	02000613          	li	a2,32
    80003720:	06050593          	addi	a1,a0,96
    80003724:	854e                	mv	a0,s3
    80003726:	ffffe097          	auipc	ra,0xffffe
    8000372a:	a12080e7          	jalr	-1518(ra) # 80001138 <memmove>
  brelse(bp);
    8000372e:	8526                	mv	a0,s1
    80003730:	00000097          	auipc	ra,0x0
    80003734:	b6e080e7          	jalr	-1170(ra) # 8000329e <brelse>
  if(sb.magic != FSMAGIC)
    80003738:	0009a703          	lw	a4,0(s3)
    8000373c:	102037b7          	lui	a5,0x10203
    80003740:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003744:	02f71263          	bne	a4,a5,80003768 <fsinit+0x70>
  initlog(dev, &sb);
    80003748:	0001d597          	auipc	a1,0x1d
    8000374c:	44058593          	addi	a1,a1,1088 # 80020b88 <sb>
    80003750:	854a                	mv	a0,s2
    80003752:	00001097          	auipc	ra,0x1
    80003756:	b4a080e7          	jalr	-1206(ra) # 8000429c <initlog>
}
    8000375a:	70a2                	ld	ra,40(sp)
    8000375c:	7402                	ld	s0,32(sp)
    8000375e:	64e2                	ld	s1,24(sp)
    80003760:	6942                	ld	s2,16(sp)
    80003762:	69a2                	ld	s3,8(sp)
    80003764:	6145                	addi	sp,sp,48
    80003766:	8082                	ret
    panic("invalid file system");
    80003768:	00005517          	auipc	a0,0x5
    8000376c:	e8850513          	addi	a0,a0,-376 # 800085f0 <syscalls+0x138>
    80003770:	ffffd097          	auipc	ra,0xffffd
    80003774:	de0080e7          	jalr	-544(ra) # 80000550 <panic>

0000000080003778 <iinit>:
{
    80003778:	7179                	addi	sp,sp,-48
    8000377a:	f406                	sd	ra,40(sp)
    8000377c:	f022                	sd	s0,32(sp)
    8000377e:	ec26                	sd	s1,24(sp)
    80003780:	e84a                	sd	s2,16(sp)
    80003782:	e44e                	sd	s3,8(sp)
    80003784:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    80003786:	00005597          	auipc	a1,0x5
    8000378a:	e8258593          	addi	a1,a1,-382 # 80008608 <syscalls+0x150>
    8000378e:	0001d517          	auipc	a0,0x1d
    80003792:	41a50513          	addi	a0,a0,1050 # 80020ba8 <icache>
    80003796:	ffffd097          	auipc	ra,0xffffd
    8000379a:	6de080e7          	jalr	1758(ra) # 80000e74 <initlock>
  for(i = 0; i < NINODE; i++) {
    8000379e:	0001d497          	auipc	s1,0x1d
    800037a2:	43a48493          	addi	s1,s1,1082 # 80020bd8 <icache+0x30>
    800037a6:	0001f997          	auipc	s3,0x1f
    800037aa:	05298993          	addi	s3,s3,82 # 800227f8 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    800037ae:	00005917          	auipc	s2,0x5
    800037b2:	e6290913          	addi	s2,s2,-414 # 80008610 <syscalls+0x158>
    800037b6:	85ca                	mv	a1,s2
    800037b8:	8526                	mv	a0,s1
    800037ba:	00001097          	auipc	ra,0x1
    800037be:	e4c080e7          	jalr	-436(ra) # 80004606 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800037c2:	09048493          	addi	s1,s1,144
    800037c6:	ff3498e3          	bne	s1,s3,800037b6 <iinit+0x3e>
}
    800037ca:	70a2                	ld	ra,40(sp)
    800037cc:	7402                	ld	s0,32(sp)
    800037ce:	64e2                	ld	s1,24(sp)
    800037d0:	6942                	ld	s2,16(sp)
    800037d2:	69a2                	ld	s3,8(sp)
    800037d4:	6145                	addi	sp,sp,48
    800037d6:	8082                	ret

00000000800037d8 <ialloc>:
{
    800037d8:	715d                	addi	sp,sp,-80
    800037da:	e486                	sd	ra,72(sp)
    800037dc:	e0a2                	sd	s0,64(sp)
    800037de:	fc26                	sd	s1,56(sp)
    800037e0:	f84a                	sd	s2,48(sp)
    800037e2:	f44e                	sd	s3,40(sp)
    800037e4:	f052                	sd	s4,32(sp)
    800037e6:	ec56                	sd	s5,24(sp)
    800037e8:	e85a                	sd	s6,16(sp)
    800037ea:	e45e                	sd	s7,8(sp)
    800037ec:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800037ee:	0001d717          	auipc	a4,0x1d
    800037f2:	3a672703          	lw	a4,934(a4) # 80020b94 <sb+0xc>
    800037f6:	4785                	li	a5,1
    800037f8:	04e7fa63          	bgeu	a5,a4,8000384c <ialloc+0x74>
    800037fc:	8aaa                	mv	s5,a0
    800037fe:	8bae                	mv	s7,a1
    80003800:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003802:	0001da17          	auipc	s4,0x1d
    80003806:	386a0a13          	addi	s4,s4,902 # 80020b88 <sb>
    8000380a:	00048b1b          	sext.w	s6,s1
    8000380e:	0044d593          	srli	a1,s1,0x4
    80003812:	018a2783          	lw	a5,24(s4)
    80003816:	9dbd                	addw	a1,a1,a5
    80003818:	8556                	mv	a0,s5
    8000381a:	00000097          	auipc	ra,0x0
    8000381e:	954080e7          	jalr	-1708(ra) # 8000316e <bread>
    80003822:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003824:	06050993          	addi	s3,a0,96
    80003828:	00f4f793          	andi	a5,s1,15
    8000382c:	079a                	slli	a5,a5,0x6
    8000382e:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003830:	00099783          	lh	a5,0(s3)
    80003834:	c785                	beqz	a5,8000385c <ialloc+0x84>
    brelse(bp);
    80003836:	00000097          	auipc	ra,0x0
    8000383a:	a68080e7          	jalr	-1432(ra) # 8000329e <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000383e:	0485                	addi	s1,s1,1
    80003840:	00ca2703          	lw	a4,12(s4)
    80003844:	0004879b          	sext.w	a5,s1
    80003848:	fce7e1e3          	bltu	a5,a4,8000380a <ialloc+0x32>
  panic("ialloc: no inodes");
    8000384c:	00005517          	auipc	a0,0x5
    80003850:	dcc50513          	addi	a0,a0,-564 # 80008618 <syscalls+0x160>
    80003854:	ffffd097          	auipc	ra,0xffffd
    80003858:	cfc080e7          	jalr	-772(ra) # 80000550 <panic>
      memset(dip, 0, sizeof(*dip));
    8000385c:	04000613          	li	a2,64
    80003860:	4581                	li	a1,0
    80003862:	854e                	mv	a0,s3
    80003864:	ffffe097          	auipc	ra,0xffffe
    80003868:	874080e7          	jalr	-1932(ra) # 800010d8 <memset>
      dip->type = type;
    8000386c:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003870:	854a                	mv	a0,s2
    80003872:	00001097          	auipc	ra,0x1
    80003876:	ca6080e7          	jalr	-858(ra) # 80004518 <log_write>
      brelse(bp);
    8000387a:	854a                	mv	a0,s2
    8000387c:	00000097          	auipc	ra,0x0
    80003880:	a22080e7          	jalr	-1502(ra) # 8000329e <brelse>
      return iget(dev, inum);
    80003884:	85da                	mv	a1,s6
    80003886:	8556                	mv	a0,s5
    80003888:	00000097          	auipc	ra,0x0
    8000388c:	db4080e7          	jalr	-588(ra) # 8000363c <iget>
}
    80003890:	60a6                	ld	ra,72(sp)
    80003892:	6406                	ld	s0,64(sp)
    80003894:	74e2                	ld	s1,56(sp)
    80003896:	7942                	ld	s2,48(sp)
    80003898:	79a2                	ld	s3,40(sp)
    8000389a:	7a02                	ld	s4,32(sp)
    8000389c:	6ae2                	ld	s5,24(sp)
    8000389e:	6b42                	ld	s6,16(sp)
    800038a0:	6ba2                	ld	s7,8(sp)
    800038a2:	6161                	addi	sp,sp,80
    800038a4:	8082                	ret

00000000800038a6 <iupdate>:
{
    800038a6:	1101                	addi	sp,sp,-32
    800038a8:	ec06                	sd	ra,24(sp)
    800038aa:	e822                	sd	s0,16(sp)
    800038ac:	e426                	sd	s1,8(sp)
    800038ae:	e04a                	sd	s2,0(sp)
    800038b0:	1000                	addi	s0,sp,32
    800038b2:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800038b4:	415c                	lw	a5,4(a0)
    800038b6:	0047d79b          	srliw	a5,a5,0x4
    800038ba:	0001d597          	auipc	a1,0x1d
    800038be:	2e65a583          	lw	a1,742(a1) # 80020ba0 <sb+0x18>
    800038c2:	9dbd                	addw	a1,a1,a5
    800038c4:	4108                	lw	a0,0(a0)
    800038c6:	00000097          	auipc	ra,0x0
    800038ca:	8a8080e7          	jalr	-1880(ra) # 8000316e <bread>
    800038ce:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800038d0:	06050793          	addi	a5,a0,96
    800038d4:	40c8                	lw	a0,4(s1)
    800038d6:	893d                	andi	a0,a0,15
    800038d8:	051a                	slli	a0,a0,0x6
    800038da:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800038dc:	04c49703          	lh	a4,76(s1)
    800038e0:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800038e4:	04e49703          	lh	a4,78(s1)
    800038e8:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800038ec:	05049703          	lh	a4,80(s1)
    800038f0:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800038f4:	05249703          	lh	a4,82(s1)
    800038f8:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800038fc:	48f8                	lw	a4,84(s1)
    800038fe:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003900:	03400613          	li	a2,52
    80003904:	05848593          	addi	a1,s1,88
    80003908:	0531                	addi	a0,a0,12
    8000390a:	ffffe097          	auipc	ra,0xffffe
    8000390e:	82e080e7          	jalr	-2002(ra) # 80001138 <memmove>
  log_write(bp);
    80003912:	854a                	mv	a0,s2
    80003914:	00001097          	auipc	ra,0x1
    80003918:	c04080e7          	jalr	-1020(ra) # 80004518 <log_write>
  brelse(bp);
    8000391c:	854a                	mv	a0,s2
    8000391e:	00000097          	auipc	ra,0x0
    80003922:	980080e7          	jalr	-1664(ra) # 8000329e <brelse>
}
    80003926:	60e2                	ld	ra,24(sp)
    80003928:	6442                	ld	s0,16(sp)
    8000392a:	64a2                	ld	s1,8(sp)
    8000392c:	6902                	ld	s2,0(sp)
    8000392e:	6105                	addi	sp,sp,32
    80003930:	8082                	ret

0000000080003932 <idup>:
{
    80003932:	1101                	addi	sp,sp,-32
    80003934:	ec06                	sd	ra,24(sp)
    80003936:	e822                	sd	s0,16(sp)
    80003938:	e426                	sd	s1,8(sp)
    8000393a:	1000                	addi	s0,sp,32
    8000393c:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    8000393e:	0001d517          	auipc	a0,0x1d
    80003942:	26a50513          	addi	a0,a0,618 # 80020ba8 <icache>
    80003946:	ffffd097          	auipc	ra,0xffffd
    8000394a:	3b2080e7          	jalr	946(ra) # 80000cf8 <acquire>
  ip->ref++;
    8000394e:	449c                	lw	a5,8(s1)
    80003950:	2785                	addiw	a5,a5,1
    80003952:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003954:	0001d517          	auipc	a0,0x1d
    80003958:	25450513          	addi	a0,a0,596 # 80020ba8 <icache>
    8000395c:	ffffd097          	auipc	ra,0xffffd
    80003960:	46c080e7          	jalr	1132(ra) # 80000dc8 <release>
}
    80003964:	8526                	mv	a0,s1
    80003966:	60e2                	ld	ra,24(sp)
    80003968:	6442                	ld	s0,16(sp)
    8000396a:	64a2                	ld	s1,8(sp)
    8000396c:	6105                	addi	sp,sp,32
    8000396e:	8082                	ret

0000000080003970 <ilock>:
{
    80003970:	1101                	addi	sp,sp,-32
    80003972:	ec06                	sd	ra,24(sp)
    80003974:	e822                	sd	s0,16(sp)
    80003976:	e426                	sd	s1,8(sp)
    80003978:	e04a                	sd	s2,0(sp)
    8000397a:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    8000397c:	c115                	beqz	a0,800039a0 <ilock+0x30>
    8000397e:	84aa                	mv	s1,a0
    80003980:	451c                	lw	a5,8(a0)
    80003982:	00f05f63          	blez	a5,800039a0 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003986:	0541                	addi	a0,a0,16
    80003988:	00001097          	auipc	ra,0x1
    8000398c:	cb8080e7          	jalr	-840(ra) # 80004640 <acquiresleep>
  if(ip->valid == 0){
    80003990:	44bc                	lw	a5,72(s1)
    80003992:	cf99                	beqz	a5,800039b0 <ilock+0x40>
}
    80003994:	60e2                	ld	ra,24(sp)
    80003996:	6442                	ld	s0,16(sp)
    80003998:	64a2                	ld	s1,8(sp)
    8000399a:	6902                	ld	s2,0(sp)
    8000399c:	6105                	addi	sp,sp,32
    8000399e:	8082                	ret
    panic("ilock");
    800039a0:	00005517          	auipc	a0,0x5
    800039a4:	c9050513          	addi	a0,a0,-880 # 80008630 <syscalls+0x178>
    800039a8:	ffffd097          	auipc	ra,0xffffd
    800039ac:	ba8080e7          	jalr	-1112(ra) # 80000550 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800039b0:	40dc                	lw	a5,4(s1)
    800039b2:	0047d79b          	srliw	a5,a5,0x4
    800039b6:	0001d597          	auipc	a1,0x1d
    800039ba:	1ea5a583          	lw	a1,490(a1) # 80020ba0 <sb+0x18>
    800039be:	9dbd                	addw	a1,a1,a5
    800039c0:	4088                	lw	a0,0(s1)
    800039c2:	fffff097          	auipc	ra,0xfffff
    800039c6:	7ac080e7          	jalr	1964(ra) # 8000316e <bread>
    800039ca:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800039cc:	06050593          	addi	a1,a0,96
    800039d0:	40dc                	lw	a5,4(s1)
    800039d2:	8bbd                	andi	a5,a5,15
    800039d4:	079a                	slli	a5,a5,0x6
    800039d6:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800039d8:	00059783          	lh	a5,0(a1)
    800039dc:	04f49623          	sh	a5,76(s1)
    ip->major = dip->major;
    800039e0:	00259783          	lh	a5,2(a1)
    800039e4:	04f49723          	sh	a5,78(s1)
    ip->minor = dip->minor;
    800039e8:	00459783          	lh	a5,4(a1)
    800039ec:	04f49823          	sh	a5,80(s1)
    ip->nlink = dip->nlink;
    800039f0:	00659783          	lh	a5,6(a1)
    800039f4:	04f49923          	sh	a5,82(s1)
    ip->size = dip->size;
    800039f8:	459c                	lw	a5,8(a1)
    800039fa:	c8fc                	sw	a5,84(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800039fc:	03400613          	li	a2,52
    80003a00:	05b1                	addi	a1,a1,12
    80003a02:	05848513          	addi	a0,s1,88
    80003a06:	ffffd097          	auipc	ra,0xffffd
    80003a0a:	732080e7          	jalr	1842(ra) # 80001138 <memmove>
    brelse(bp);
    80003a0e:	854a                	mv	a0,s2
    80003a10:	00000097          	auipc	ra,0x0
    80003a14:	88e080e7          	jalr	-1906(ra) # 8000329e <brelse>
    ip->valid = 1;
    80003a18:	4785                	li	a5,1
    80003a1a:	c4bc                	sw	a5,72(s1)
    if(ip->type == 0)
    80003a1c:	04c49783          	lh	a5,76(s1)
    80003a20:	fbb5                	bnez	a5,80003994 <ilock+0x24>
      panic("ilock: no type");
    80003a22:	00005517          	auipc	a0,0x5
    80003a26:	c1650513          	addi	a0,a0,-1002 # 80008638 <syscalls+0x180>
    80003a2a:	ffffd097          	auipc	ra,0xffffd
    80003a2e:	b26080e7          	jalr	-1242(ra) # 80000550 <panic>

0000000080003a32 <iunlock>:
{
    80003a32:	1101                	addi	sp,sp,-32
    80003a34:	ec06                	sd	ra,24(sp)
    80003a36:	e822                	sd	s0,16(sp)
    80003a38:	e426                	sd	s1,8(sp)
    80003a3a:	e04a                	sd	s2,0(sp)
    80003a3c:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003a3e:	c905                	beqz	a0,80003a6e <iunlock+0x3c>
    80003a40:	84aa                	mv	s1,a0
    80003a42:	01050913          	addi	s2,a0,16
    80003a46:	854a                	mv	a0,s2
    80003a48:	00001097          	auipc	ra,0x1
    80003a4c:	c92080e7          	jalr	-878(ra) # 800046da <holdingsleep>
    80003a50:	cd19                	beqz	a0,80003a6e <iunlock+0x3c>
    80003a52:	449c                	lw	a5,8(s1)
    80003a54:	00f05d63          	blez	a5,80003a6e <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003a58:	854a                	mv	a0,s2
    80003a5a:	00001097          	auipc	ra,0x1
    80003a5e:	c3c080e7          	jalr	-964(ra) # 80004696 <releasesleep>
}
    80003a62:	60e2                	ld	ra,24(sp)
    80003a64:	6442                	ld	s0,16(sp)
    80003a66:	64a2                	ld	s1,8(sp)
    80003a68:	6902                	ld	s2,0(sp)
    80003a6a:	6105                	addi	sp,sp,32
    80003a6c:	8082                	ret
    panic("iunlock");
    80003a6e:	00005517          	auipc	a0,0x5
    80003a72:	bda50513          	addi	a0,a0,-1062 # 80008648 <syscalls+0x190>
    80003a76:	ffffd097          	auipc	ra,0xffffd
    80003a7a:	ada080e7          	jalr	-1318(ra) # 80000550 <panic>

0000000080003a7e <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003a7e:	7179                	addi	sp,sp,-48
    80003a80:	f406                	sd	ra,40(sp)
    80003a82:	f022                	sd	s0,32(sp)
    80003a84:	ec26                	sd	s1,24(sp)
    80003a86:	e84a                	sd	s2,16(sp)
    80003a88:	e44e                	sd	s3,8(sp)
    80003a8a:	e052                	sd	s4,0(sp)
    80003a8c:	1800                	addi	s0,sp,48
    80003a8e:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003a90:	05850493          	addi	s1,a0,88
    80003a94:	08850913          	addi	s2,a0,136
    80003a98:	a021                	j	80003aa0 <itrunc+0x22>
    80003a9a:	0491                	addi	s1,s1,4
    80003a9c:	01248d63          	beq	s1,s2,80003ab6 <itrunc+0x38>
    if(ip->addrs[i]){
    80003aa0:	408c                	lw	a1,0(s1)
    80003aa2:	dde5                	beqz	a1,80003a9a <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003aa4:	0009a503          	lw	a0,0(s3)
    80003aa8:	00000097          	auipc	ra,0x0
    80003aac:	90c080e7          	jalr	-1780(ra) # 800033b4 <bfree>
      ip->addrs[i] = 0;
    80003ab0:	0004a023          	sw	zero,0(s1)
    80003ab4:	b7dd                	j	80003a9a <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003ab6:	0889a583          	lw	a1,136(s3)
    80003aba:	e185                	bnez	a1,80003ada <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003abc:	0409aa23          	sw	zero,84(s3)
  iupdate(ip);
    80003ac0:	854e                	mv	a0,s3
    80003ac2:	00000097          	auipc	ra,0x0
    80003ac6:	de4080e7          	jalr	-540(ra) # 800038a6 <iupdate>
}
    80003aca:	70a2                	ld	ra,40(sp)
    80003acc:	7402                	ld	s0,32(sp)
    80003ace:	64e2                	ld	s1,24(sp)
    80003ad0:	6942                	ld	s2,16(sp)
    80003ad2:	69a2                	ld	s3,8(sp)
    80003ad4:	6a02                	ld	s4,0(sp)
    80003ad6:	6145                	addi	sp,sp,48
    80003ad8:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003ada:	0009a503          	lw	a0,0(s3)
    80003ade:	fffff097          	auipc	ra,0xfffff
    80003ae2:	690080e7          	jalr	1680(ra) # 8000316e <bread>
    80003ae6:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003ae8:	06050493          	addi	s1,a0,96
    80003aec:	46050913          	addi	s2,a0,1120
    80003af0:	a811                	j	80003b04 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003af2:	0009a503          	lw	a0,0(s3)
    80003af6:	00000097          	auipc	ra,0x0
    80003afa:	8be080e7          	jalr	-1858(ra) # 800033b4 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003afe:	0491                	addi	s1,s1,4
    80003b00:	01248563          	beq	s1,s2,80003b0a <itrunc+0x8c>
      if(a[j])
    80003b04:	408c                	lw	a1,0(s1)
    80003b06:	dde5                	beqz	a1,80003afe <itrunc+0x80>
    80003b08:	b7ed                	j	80003af2 <itrunc+0x74>
    brelse(bp);
    80003b0a:	8552                	mv	a0,s4
    80003b0c:	fffff097          	auipc	ra,0xfffff
    80003b10:	792080e7          	jalr	1938(ra) # 8000329e <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003b14:	0889a583          	lw	a1,136(s3)
    80003b18:	0009a503          	lw	a0,0(s3)
    80003b1c:	00000097          	auipc	ra,0x0
    80003b20:	898080e7          	jalr	-1896(ra) # 800033b4 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003b24:	0809a423          	sw	zero,136(s3)
    80003b28:	bf51                	j	80003abc <itrunc+0x3e>

0000000080003b2a <iput>:
{
    80003b2a:	1101                	addi	sp,sp,-32
    80003b2c:	ec06                	sd	ra,24(sp)
    80003b2e:	e822                	sd	s0,16(sp)
    80003b30:	e426                	sd	s1,8(sp)
    80003b32:	e04a                	sd	s2,0(sp)
    80003b34:	1000                	addi	s0,sp,32
    80003b36:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003b38:	0001d517          	auipc	a0,0x1d
    80003b3c:	07050513          	addi	a0,a0,112 # 80020ba8 <icache>
    80003b40:	ffffd097          	auipc	ra,0xffffd
    80003b44:	1b8080e7          	jalr	440(ra) # 80000cf8 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b48:	4498                	lw	a4,8(s1)
    80003b4a:	4785                	li	a5,1
    80003b4c:	02f70363          	beq	a4,a5,80003b72 <iput+0x48>
  ip->ref--;
    80003b50:	449c                	lw	a5,8(s1)
    80003b52:	37fd                	addiw	a5,a5,-1
    80003b54:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003b56:	0001d517          	auipc	a0,0x1d
    80003b5a:	05250513          	addi	a0,a0,82 # 80020ba8 <icache>
    80003b5e:	ffffd097          	auipc	ra,0xffffd
    80003b62:	26a080e7          	jalr	618(ra) # 80000dc8 <release>
}
    80003b66:	60e2                	ld	ra,24(sp)
    80003b68:	6442                	ld	s0,16(sp)
    80003b6a:	64a2                	ld	s1,8(sp)
    80003b6c:	6902                	ld	s2,0(sp)
    80003b6e:	6105                	addi	sp,sp,32
    80003b70:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b72:	44bc                	lw	a5,72(s1)
    80003b74:	dff1                	beqz	a5,80003b50 <iput+0x26>
    80003b76:	05249783          	lh	a5,82(s1)
    80003b7a:	fbf9                	bnez	a5,80003b50 <iput+0x26>
    acquiresleep(&ip->lock);
    80003b7c:	01048913          	addi	s2,s1,16
    80003b80:	854a                	mv	a0,s2
    80003b82:	00001097          	auipc	ra,0x1
    80003b86:	abe080e7          	jalr	-1346(ra) # 80004640 <acquiresleep>
    release(&icache.lock);
    80003b8a:	0001d517          	auipc	a0,0x1d
    80003b8e:	01e50513          	addi	a0,a0,30 # 80020ba8 <icache>
    80003b92:	ffffd097          	auipc	ra,0xffffd
    80003b96:	236080e7          	jalr	566(ra) # 80000dc8 <release>
    itrunc(ip);
    80003b9a:	8526                	mv	a0,s1
    80003b9c:	00000097          	auipc	ra,0x0
    80003ba0:	ee2080e7          	jalr	-286(ra) # 80003a7e <itrunc>
    ip->type = 0;
    80003ba4:	04049623          	sh	zero,76(s1)
    iupdate(ip);
    80003ba8:	8526                	mv	a0,s1
    80003baa:	00000097          	auipc	ra,0x0
    80003bae:	cfc080e7          	jalr	-772(ra) # 800038a6 <iupdate>
    ip->valid = 0;
    80003bb2:	0404a423          	sw	zero,72(s1)
    releasesleep(&ip->lock);
    80003bb6:	854a                	mv	a0,s2
    80003bb8:	00001097          	auipc	ra,0x1
    80003bbc:	ade080e7          	jalr	-1314(ra) # 80004696 <releasesleep>
    acquire(&icache.lock);
    80003bc0:	0001d517          	auipc	a0,0x1d
    80003bc4:	fe850513          	addi	a0,a0,-24 # 80020ba8 <icache>
    80003bc8:	ffffd097          	auipc	ra,0xffffd
    80003bcc:	130080e7          	jalr	304(ra) # 80000cf8 <acquire>
    80003bd0:	b741                	j	80003b50 <iput+0x26>

0000000080003bd2 <iunlockput>:
{
    80003bd2:	1101                	addi	sp,sp,-32
    80003bd4:	ec06                	sd	ra,24(sp)
    80003bd6:	e822                	sd	s0,16(sp)
    80003bd8:	e426                	sd	s1,8(sp)
    80003bda:	1000                	addi	s0,sp,32
    80003bdc:	84aa                	mv	s1,a0
  iunlock(ip);
    80003bde:	00000097          	auipc	ra,0x0
    80003be2:	e54080e7          	jalr	-428(ra) # 80003a32 <iunlock>
  iput(ip);
    80003be6:	8526                	mv	a0,s1
    80003be8:	00000097          	auipc	ra,0x0
    80003bec:	f42080e7          	jalr	-190(ra) # 80003b2a <iput>
}
    80003bf0:	60e2                	ld	ra,24(sp)
    80003bf2:	6442                	ld	s0,16(sp)
    80003bf4:	64a2                	ld	s1,8(sp)
    80003bf6:	6105                	addi	sp,sp,32
    80003bf8:	8082                	ret

0000000080003bfa <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003bfa:	1141                	addi	sp,sp,-16
    80003bfc:	e422                	sd	s0,8(sp)
    80003bfe:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003c00:	411c                	lw	a5,0(a0)
    80003c02:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003c04:	415c                	lw	a5,4(a0)
    80003c06:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003c08:	04c51783          	lh	a5,76(a0)
    80003c0c:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003c10:	05251783          	lh	a5,82(a0)
    80003c14:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003c18:	05456783          	lwu	a5,84(a0)
    80003c1c:	e99c                	sd	a5,16(a1)
}
    80003c1e:	6422                	ld	s0,8(sp)
    80003c20:	0141                	addi	sp,sp,16
    80003c22:	8082                	ret

0000000080003c24 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c24:	497c                	lw	a5,84(a0)
    80003c26:	0ed7e963          	bltu	a5,a3,80003d18 <readi+0xf4>
{
    80003c2a:	7159                	addi	sp,sp,-112
    80003c2c:	f486                	sd	ra,104(sp)
    80003c2e:	f0a2                	sd	s0,96(sp)
    80003c30:	eca6                	sd	s1,88(sp)
    80003c32:	e8ca                	sd	s2,80(sp)
    80003c34:	e4ce                	sd	s3,72(sp)
    80003c36:	e0d2                	sd	s4,64(sp)
    80003c38:	fc56                	sd	s5,56(sp)
    80003c3a:	f85a                	sd	s6,48(sp)
    80003c3c:	f45e                	sd	s7,40(sp)
    80003c3e:	f062                	sd	s8,32(sp)
    80003c40:	ec66                	sd	s9,24(sp)
    80003c42:	e86a                	sd	s10,16(sp)
    80003c44:	e46e                	sd	s11,8(sp)
    80003c46:	1880                	addi	s0,sp,112
    80003c48:	8baa                	mv	s7,a0
    80003c4a:	8c2e                	mv	s8,a1
    80003c4c:	8ab2                	mv	s5,a2
    80003c4e:	84b6                	mv	s1,a3
    80003c50:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003c52:	9f35                	addw	a4,a4,a3
    return 0;
    80003c54:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003c56:	0ad76063          	bltu	a4,a3,80003cf6 <readi+0xd2>
  if(off + n > ip->size)
    80003c5a:	00e7f463          	bgeu	a5,a4,80003c62 <readi+0x3e>
    n = ip->size - off;
    80003c5e:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c62:	0a0b0963          	beqz	s6,80003d14 <readi+0xf0>
    80003c66:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c68:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003c6c:	5cfd                	li	s9,-1
    80003c6e:	a82d                	j	80003ca8 <readi+0x84>
    80003c70:	020a1d93          	slli	s11,s4,0x20
    80003c74:	020ddd93          	srli	s11,s11,0x20
    80003c78:	06090613          	addi	a2,s2,96
    80003c7c:	86ee                	mv	a3,s11
    80003c7e:	963a                	add	a2,a2,a4
    80003c80:	85d6                	mv	a1,s5
    80003c82:	8562                	mv	a0,s8
    80003c84:	fffff097          	auipc	ra,0xfffff
    80003c88:	b2e080e7          	jalr	-1234(ra) # 800027b2 <either_copyout>
    80003c8c:	05950d63          	beq	a0,s9,80003ce6 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003c90:	854a                	mv	a0,s2
    80003c92:	fffff097          	auipc	ra,0xfffff
    80003c96:	60c080e7          	jalr	1548(ra) # 8000329e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c9a:	013a09bb          	addw	s3,s4,s3
    80003c9e:	009a04bb          	addw	s1,s4,s1
    80003ca2:	9aee                	add	s5,s5,s11
    80003ca4:	0569f763          	bgeu	s3,s6,80003cf2 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003ca8:	000ba903          	lw	s2,0(s7)
    80003cac:	00a4d59b          	srliw	a1,s1,0xa
    80003cb0:	855e                	mv	a0,s7
    80003cb2:	00000097          	auipc	ra,0x0
    80003cb6:	8b0080e7          	jalr	-1872(ra) # 80003562 <bmap>
    80003cba:	0005059b          	sext.w	a1,a0
    80003cbe:	854a                	mv	a0,s2
    80003cc0:	fffff097          	auipc	ra,0xfffff
    80003cc4:	4ae080e7          	jalr	1198(ra) # 8000316e <bread>
    80003cc8:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003cca:	3ff4f713          	andi	a4,s1,1023
    80003cce:	40ed07bb          	subw	a5,s10,a4
    80003cd2:	413b06bb          	subw	a3,s6,s3
    80003cd6:	8a3e                	mv	s4,a5
    80003cd8:	2781                	sext.w	a5,a5
    80003cda:	0006861b          	sext.w	a2,a3
    80003cde:	f8f679e3          	bgeu	a2,a5,80003c70 <readi+0x4c>
    80003ce2:	8a36                	mv	s4,a3
    80003ce4:	b771                	j	80003c70 <readi+0x4c>
      brelse(bp);
    80003ce6:	854a                	mv	a0,s2
    80003ce8:	fffff097          	auipc	ra,0xfffff
    80003cec:	5b6080e7          	jalr	1462(ra) # 8000329e <brelse>
      tot = -1;
    80003cf0:	59fd                	li	s3,-1
  }
  return tot;
    80003cf2:	0009851b          	sext.w	a0,s3
}
    80003cf6:	70a6                	ld	ra,104(sp)
    80003cf8:	7406                	ld	s0,96(sp)
    80003cfa:	64e6                	ld	s1,88(sp)
    80003cfc:	6946                	ld	s2,80(sp)
    80003cfe:	69a6                	ld	s3,72(sp)
    80003d00:	6a06                	ld	s4,64(sp)
    80003d02:	7ae2                	ld	s5,56(sp)
    80003d04:	7b42                	ld	s6,48(sp)
    80003d06:	7ba2                	ld	s7,40(sp)
    80003d08:	7c02                	ld	s8,32(sp)
    80003d0a:	6ce2                	ld	s9,24(sp)
    80003d0c:	6d42                	ld	s10,16(sp)
    80003d0e:	6da2                	ld	s11,8(sp)
    80003d10:	6165                	addi	sp,sp,112
    80003d12:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d14:	89da                	mv	s3,s6
    80003d16:	bff1                	j	80003cf2 <readi+0xce>
    return 0;
    80003d18:	4501                	li	a0,0
}
    80003d1a:	8082                	ret

0000000080003d1c <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003d1c:	497c                	lw	a5,84(a0)
    80003d1e:	10d7e763          	bltu	a5,a3,80003e2c <writei+0x110>
{
    80003d22:	7159                	addi	sp,sp,-112
    80003d24:	f486                	sd	ra,104(sp)
    80003d26:	f0a2                	sd	s0,96(sp)
    80003d28:	eca6                	sd	s1,88(sp)
    80003d2a:	e8ca                	sd	s2,80(sp)
    80003d2c:	e4ce                	sd	s3,72(sp)
    80003d2e:	e0d2                	sd	s4,64(sp)
    80003d30:	fc56                	sd	s5,56(sp)
    80003d32:	f85a                	sd	s6,48(sp)
    80003d34:	f45e                	sd	s7,40(sp)
    80003d36:	f062                	sd	s8,32(sp)
    80003d38:	ec66                	sd	s9,24(sp)
    80003d3a:	e86a                	sd	s10,16(sp)
    80003d3c:	e46e                	sd	s11,8(sp)
    80003d3e:	1880                	addi	s0,sp,112
    80003d40:	8baa                	mv	s7,a0
    80003d42:	8c2e                	mv	s8,a1
    80003d44:	8ab2                	mv	s5,a2
    80003d46:	8936                	mv	s2,a3
    80003d48:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003d4a:	00e687bb          	addw	a5,a3,a4
    80003d4e:	0ed7e163          	bltu	a5,a3,80003e30 <writei+0x114>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003d52:	00043737          	lui	a4,0x43
    80003d56:	0cf76f63          	bltu	a4,a5,80003e34 <writei+0x118>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d5a:	0a0b0863          	beqz	s6,80003e0a <writei+0xee>
    80003d5e:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d60:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003d64:	5cfd                	li	s9,-1
    80003d66:	a091                	j	80003daa <writei+0x8e>
    80003d68:	02099d93          	slli	s11,s3,0x20
    80003d6c:	020ddd93          	srli	s11,s11,0x20
    80003d70:	06048513          	addi	a0,s1,96
    80003d74:	86ee                	mv	a3,s11
    80003d76:	8656                	mv	a2,s5
    80003d78:	85e2                	mv	a1,s8
    80003d7a:	953a                	add	a0,a0,a4
    80003d7c:	fffff097          	auipc	ra,0xfffff
    80003d80:	a8c080e7          	jalr	-1396(ra) # 80002808 <either_copyin>
    80003d84:	07950263          	beq	a0,s9,80003de8 <writei+0xcc>
      brelse(bp);
      n = -1;
      break;
    }
    log_write(bp);
    80003d88:	8526                	mv	a0,s1
    80003d8a:	00000097          	auipc	ra,0x0
    80003d8e:	78e080e7          	jalr	1934(ra) # 80004518 <log_write>
    brelse(bp);
    80003d92:	8526                	mv	a0,s1
    80003d94:	fffff097          	auipc	ra,0xfffff
    80003d98:	50a080e7          	jalr	1290(ra) # 8000329e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d9c:	01498a3b          	addw	s4,s3,s4
    80003da0:	0129893b          	addw	s2,s3,s2
    80003da4:	9aee                	add	s5,s5,s11
    80003da6:	056a7763          	bgeu	s4,s6,80003df4 <writei+0xd8>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003daa:	000ba483          	lw	s1,0(s7)
    80003dae:	00a9559b          	srliw	a1,s2,0xa
    80003db2:	855e                	mv	a0,s7
    80003db4:	fffff097          	auipc	ra,0xfffff
    80003db8:	7ae080e7          	jalr	1966(ra) # 80003562 <bmap>
    80003dbc:	0005059b          	sext.w	a1,a0
    80003dc0:	8526                	mv	a0,s1
    80003dc2:	fffff097          	auipc	ra,0xfffff
    80003dc6:	3ac080e7          	jalr	940(ra) # 8000316e <bread>
    80003dca:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003dcc:	3ff97713          	andi	a4,s2,1023
    80003dd0:	40ed07bb          	subw	a5,s10,a4
    80003dd4:	414b06bb          	subw	a3,s6,s4
    80003dd8:	89be                	mv	s3,a5
    80003dda:	2781                	sext.w	a5,a5
    80003ddc:	0006861b          	sext.w	a2,a3
    80003de0:	f8f674e3          	bgeu	a2,a5,80003d68 <writei+0x4c>
    80003de4:	89b6                	mv	s3,a3
    80003de6:	b749                	j	80003d68 <writei+0x4c>
      brelse(bp);
    80003de8:	8526                	mv	a0,s1
    80003dea:	fffff097          	auipc	ra,0xfffff
    80003dee:	4b4080e7          	jalr	1204(ra) # 8000329e <brelse>
      n = -1;
    80003df2:	5b7d                	li	s6,-1
  }

  if(n > 0){
    if(off > ip->size)
    80003df4:	054ba783          	lw	a5,84(s7)
    80003df8:	0127f463          	bgeu	a5,s2,80003e00 <writei+0xe4>
      ip->size = off;
    80003dfc:	052baa23          	sw	s2,84(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003e00:	855e                	mv	a0,s7
    80003e02:	00000097          	auipc	ra,0x0
    80003e06:	aa4080e7          	jalr	-1372(ra) # 800038a6 <iupdate>
  }

  return n;
    80003e0a:	000b051b          	sext.w	a0,s6
}
    80003e0e:	70a6                	ld	ra,104(sp)
    80003e10:	7406                	ld	s0,96(sp)
    80003e12:	64e6                	ld	s1,88(sp)
    80003e14:	6946                	ld	s2,80(sp)
    80003e16:	69a6                	ld	s3,72(sp)
    80003e18:	6a06                	ld	s4,64(sp)
    80003e1a:	7ae2                	ld	s5,56(sp)
    80003e1c:	7b42                	ld	s6,48(sp)
    80003e1e:	7ba2                	ld	s7,40(sp)
    80003e20:	7c02                	ld	s8,32(sp)
    80003e22:	6ce2                	ld	s9,24(sp)
    80003e24:	6d42                	ld	s10,16(sp)
    80003e26:	6da2                	ld	s11,8(sp)
    80003e28:	6165                	addi	sp,sp,112
    80003e2a:	8082                	ret
    return -1;
    80003e2c:	557d                	li	a0,-1
}
    80003e2e:	8082                	ret
    return -1;
    80003e30:	557d                	li	a0,-1
    80003e32:	bff1                	j	80003e0e <writei+0xf2>
    return -1;
    80003e34:	557d                	li	a0,-1
    80003e36:	bfe1                	j	80003e0e <writei+0xf2>

0000000080003e38 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003e38:	1141                	addi	sp,sp,-16
    80003e3a:	e406                	sd	ra,8(sp)
    80003e3c:	e022                	sd	s0,0(sp)
    80003e3e:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003e40:	4639                	li	a2,14
    80003e42:	ffffd097          	auipc	ra,0xffffd
    80003e46:	372080e7          	jalr	882(ra) # 800011b4 <strncmp>
}
    80003e4a:	60a2                	ld	ra,8(sp)
    80003e4c:	6402                	ld	s0,0(sp)
    80003e4e:	0141                	addi	sp,sp,16
    80003e50:	8082                	ret

0000000080003e52 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003e52:	7139                	addi	sp,sp,-64
    80003e54:	fc06                	sd	ra,56(sp)
    80003e56:	f822                	sd	s0,48(sp)
    80003e58:	f426                	sd	s1,40(sp)
    80003e5a:	f04a                	sd	s2,32(sp)
    80003e5c:	ec4e                	sd	s3,24(sp)
    80003e5e:	e852                	sd	s4,16(sp)
    80003e60:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003e62:	04c51703          	lh	a4,76(a0)
    80003e66:	4785                	li	a5,1
    80003e68:	00f71a63          	bne	a4,a5,80003e7c <dirlookup+0x2a>
    80003e6c:	892a                	mv	s2,a0
    80003e6e:	89ae                	mv	s3,a1
    80003e70:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e72:	497c                	lw	a5,84(a0)
    80003e74:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003e76:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e78:	e79d                	bnez	a5,80003ea6 <dirlookup+0x54>
    80003e7a:	a8a5                	j	80003ef2 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003e7c:	00004517          	auipc	a0,0x4
    80003e80:	7d450513          	addi	a0,a0,2004 # 80008650 <syscalls+0x198>
    80003e84:	ffffc097          	auipc	ra,0xffffc
    80003e88:	6cc080e7          	jalr	1740(ra) # 80000550 <panic>
      panic("dirlookup read");
    80003e8c:	00004517          	auipc	a0,0x4
    80003e90:	7dc50513          	addi	a0,a0,2012 # 80008668 <syscalls+0x1b0>
    80003e94:	ffffc097          	auipc	ra,0xffffc
    80003e98:	6bc080e7          	jalr	1724(ra) # 80000550 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e9c:	24c1                	addiw	s1,s1,16
    80003e9e:	05492783          	lw	a5,84(s2)
    80003ea2:	04f4f763          	bgeu	s1,a5,80003ef0 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ea6:	4741                	li	a4,16
    80003ea8:	86a6                	mv	a3,s1
    80003eaa:	fc040613          	addi	a2,s0,-64
    80003eae:	4581                	li	a1,0
    80003eb0:	854a                	mv	a0,s2
    80003eb2:	00000097          	auipc	ra,0x0
    80003eb6:	d72080e7          	jalr	-654(ra) # 80003c24 <readi>
    80003eba:	47c1                	li	a5,16
    80003ebc:	fcf518e3          	bne	a0,a5,80003e8c <dirlookup+0x3a>
    if(de.inum == 0)
    80003ec0:	fc045783          	lhu	a5,-64(s0)
    80003ec4:	dfe1                	beqz	a5,80003e9c <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003ec6:	fc240593          	addi	a1,s0,-62
    80003eca:	854e                	mv	a0,s3
    80003ecc:	00000097          	auipc	ra,0x0
    80003ed0:	f6c080e7          	jalr	-148(ra) # 80003e38 <namecmp>
    80003ed4:	f561                	bnez	a0,80003e9c <dirlookup+0x4a>
      if(poff)
    80003ed6:	000a0463          	beqz	s4,80003ede <dirlookup+0x8c>
        *poff = off;
    80003eda:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003ede:	fc045583          	lhu	a1,-64(s0)
    80003ee2:	00092503          	lw	a0,0(s2)
    80003ee6:	fffff097          	auipc	ra,0xfffff
    80003eea:	756080e7          	jalr	1878(ra) # 8000363c <iget>
    80003eee:	a011                	j	80003ef2 <dirlookup+0xa0>
  return 0;
    80003ef0:	4501                	li	a0,0
}
    80003ef2:	70e2                	ld	ra,56(sp)
    80003ef4:	7442                	ld	s0,48(sp)
    80003ef6:	74a2                	ld	s1,40(sp)
    80003ef8:	7902                	ld	s2,32(sp)
    80003efa:	69e2                	ld	s3,24(sp)
    80003efc:	6a42                	ld	s4,16(sp)
    80003efe:	6121                	addi	sp,sp,64
    80003f00:	8082                	ret

0000000080003f02 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003f02:	711d                	addi	sp,sp,-96
    80003f04:	ec86                	sd	ra,88(sp)
    80003f06:	e8a2                	sd	s0,80(sp)
    80003f08:	e4a6                	sd	s1,72(sp)
    80003f0a:	e0ca                	sd	s2,64(sp)
    80003f0c:	fc4e                	sd	s3,56(sp)
    80003f0e:	f852                	sd	s4,48(sp)
    80003f10:	f456                	sd	s5,40(sp)
    80003f12:	f05a                	sd	s6,32(sp)
    80003f14:	ec5e                	sd	s7,24(sp)
    80003f16:	e862                	sd	s8,16(sp)
    80003f18:	e466                	sd	s9,8(sp)
    80003f1a:	1080                	addi	s0,sp,96
    80003f1c:	84aa                	mv	s1,a0
    80003f1e:	8b2e                	mv	s6,a1
    80003f20:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003f22:	00054703          	lbu	a4,0(a0)
    80003f26:	02f00793          	li	a5,47
    80003f2a:	02f70363          	beq	a4,a5,80003f50 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003f2e:	ffffe097          	auipc	ra,0xffffe
    80003f32:	e12080e7          	jalr	-494(ra) # 80001d40 <myproc>
    80003f36:	15853503          	ld	a0,344(a0)
    80003f3a:	00000097          	auipc	ra,0x0
    80003f3e:	9f8080e7          	jalr	-1544(ra) # 80003932 <idup>
    80003f42:	89aa                	mv	s3,a0
  while(*path == '/')
    80003f44:	02f00913          	li	s2,47
  len = path - s;
    80003f48:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003f4a:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003f4c:	4c05                	li	s8,1
    80003f4e:	a865                	j	80004006 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003f50:	4585                	li	a1,1
    80003f52:	4505                	li	a0,1
    80003f54:	fffff097          	auipc	ra,0xfffff
    80003f58:	6e8080e7          	jalr	1768(ra) # 8000363c <iget>
    80003f5c:	89aa                	mv	s3,a0
    80003f5e:	b7dd                	j	80003f44 <namex+0x42>
      iunlockput(ip);
    80003f60:	854e                	mv	a0,s3
    80003f62:	00000097          	auipc	ra,0x0
    80003f66:	c70080e7          	jalr	-912(ra) # 80003bd2 <iunlockput>
      return 0;
    80003f6a:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003f6c:	854e                	mv	a0,s3
    80003f6e:	60e6                	ld	ra,88(sp)
    80003f70:	6446                	ld	s0,80(sp)
    80003f72:	64a6                	ld	s1,72(sp)
    80003f74:	6906                	ld	s2,64(sp)
    80003f76:	79e2                	ld	s3,56(sp)
    80003f78:	7a42                	ld	s4,48(sp)
    80003f7a:	7aa2                	ld	s5,40(sp)
    80003f7c:	7b02                	ld	s6,32(sp)
    80003f7e:	6be2                	ld	s7,24(sp)
    80003f80:	6c42                	ld	s8,16(sp)
    80003f82:	6ca2                	ld	s9,8(sp)
    80003f84:	6125                	addi	sp,sp,96
    80003f86:	8082                	ret
      iunlock(ip);
    80003f88:	854e                	mv	a0,s3
    80003f8a:	00000097          	auipc	ra,0x0
    80003f8e:	aa8080e7          	jalr	-1368(ra) # 80003a32 <iunlock>
      return ip;
    80003f92:	bfe9                	j	80003f6c <namex+0x6a>
      iunlockput(ip);
    80003f94:	854e                	mv	a0,s3
    80003f96:	00000097          	auipc	ra,0x0
    80003f9a:	c3c080e7          	jalr	-964(ra) # 80003bd2 <iunlockput>
      return 0;
    80003f9e:	89d2                	mv	s3,s4
    80003fa0:	b7f1                	j	80003f6c <namex+0x6a>
  len = path - s;
    80003fa2:	40b48633          	sub	a2,s1,a1
    80003fa6:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003faa:	094cd463          	bge	s9,s4,80004032 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003fae:	4639                	li	a2,14
    80003fb0:	8556                	mv	a0,s5
    80003fb2:	ffffd097          	auipc	ra,0xffffd
    80003fb6:	186080e7          	jalr	390(ra) # 80001138 <memmove>
  while(*path == '/')
    80003fba:	0004c783          	lbu	a5,0(s1)
    80003fbe:	01279763          	bne	a5,s2,80003fcc <namex+0xca>
    path++;
    80003fc2:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003fc4:	0004c783          	lbu	a5,0(s1)
    80003fc8:	ff278de3          	beq	a5,s2,80003fc2 <namex+0xc0>
    ilock(ip);
    80003fcc:	854e                	mv	a0,s3
    80003fce:	00000097          	auipc	ra,0x0
    80003fd2:	9a2080e7          	jalr	-1630(ra) # 80003970 <ilock>
    if(ip->type != T_DIR){
    80003fd6:	04c99783          	lh	a5,76(s3)
    80003fda:	f98793e3          	bne	a5,s8,80003f60 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003fde:	000b0563          	beqz	s6,80003fe8 <namex+0xe6>
    80003fe2:	0004c783          	lbu	a5,0(s1)
    80003fe6:	d3cd                	beqz	a5,80003f88 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003fe8:	865e                	mv	a2,s7
    80003fea:	85d6                	mv	a1,s5
    80003fec:	854e                	mv	a0,s3
    80003fee:	00000097          	auipc	ra,0x0
    80003ff2:	e64080e7          	jalr	-412(ra) # 80003e52 <dirlookup>
    80003ff6:	8a2a                	mv	s4,a0
    80003ff8:	dd51                	beqz	a0,80003f94 <namex+0x92>
    iunlockput(ip);
    80003ffa:	854e                	mv	a0,s3
    80003ffc:	00000097          	auipc	ra,0x0
    80004000:	bd6080e7          	jalr	-1066(ra) # 80003bd2 <iunlockput>
    ip = next;
    80004004:	89d2                	mv	s3,s4
  while(*path == '/')
    80004006:	0004c783          	lbu	a5,0(s1)
    8000400a:	05279763          	bne	a5,s2,80004058 <namex+0x156>
    path++;
    8000400e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004010:	0004c783          	lbu	a5,0(s1)
    80004014:	ff278de3          	beq	a5,s2,8000400e <namex+0x10c>
  if(*path == 0)
    80004018:	c79d                	beqz	a5,80004046 <namex+0x144>
    path++;
    8000401a:	85a6                	mv	a1,s1
  len = path - s;
    8000401c:	8a5e                	mv	s4,s7
    8000401e:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004020:	01278963          	beq	a5,s2,80004032 <namex+0x130>
    80004024:	dfbd                	beqz	a5,80003fa2 <namex+0xa0>
    path++;
    80004026:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004028:	0004c783          	lbu	a5,0(s1)
    8000402c:	ff279ce3          	bne	a5,s2,80004024 <namex+0x122>
    80004030:	bf8d                	j	80003fa2 <namex+0xa0>
    memmove(name, s, len);
    80004032:	2601                	sext.w	a2,a2
    80004034:	8556                	mv	a0,s5
    80004036:	ffffd097          	auipc	ra,0xffffd
    8000403a:	102080e7          	jalr	258(ra) # 80001138 <memmove>
    name[len] = 0;
    8000403e:	9a56                	add	s4,s4,s5
    80004040:	000a0023          	sb	zero,0(s4)
    80004044:	bf9d                	j	80003fba <namex+0xb8>
  if(nameiparent){
    80004046:	f20b03e3          	beqz	s6,80003f6c <namex+0x6a>
    iput(ip);
    8000404a:	854e                	mv	a0,s3
    8000404c:	00000097          	auipc	ra,0x0
    80004050:	ade080e7          	jalr	-1314(ra) # 80003b2a <iput>
    return 0;
    80004054:	4981                	li	s3,0
    80004056:	bf19                	j	80003f6c <namex+0x6a>
  if(*path == 0)
    80004058:	d7fd                	beqz	a5,80004046 <namex+0x144>
  while(*path != '/' && *path != 0)
    8000405a:	0004c783          	lbu	a5,0(s1)
    8000405e:	85a6                	mv	a1,s1
    80004060:	b7d1                	j	80004024 <namex+0x122>

0000000080004062 <dirlink>:
{
    80004062:	7139                	addi	sp,sp,-64
    80004064:	fc06                	sd	ra,56(sp)
    80004066:	f822                	sd	s0,48(sp)
    80004068:	f426                	sd	s1,40(sp)
    8000406a:	f04a                	sd	s2,32(sp)
    8000406c:	ec4e                	sd	s3,24(sp)
    8000406e:	e852                	sd	s4,16(sp)
    80004070:	0080                	addi	s0,sp,64
    80004072:	892a                	mv	s2,a0
    80004074:	8a2e                	mv	s4,a1
    80004076:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004078:	4601                	li	a2,0
    8000407a:	00000097          	auipc	ra,0x0
    8000407e:	dd8080e7          	jalr	-552(ra) # 80003e52 <dirlookup>
    80004082:	e93d                	bnez	a0,800040f8 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004084:	05492483          	lw	s1,84(s2)
    80004088:	c49d                	beqz	s1,800040b6 <dirlink+0x54>
    8000408a:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000408c:	4741                	li	a4,16
    8000408e:	86a6                	mv	a3,s1
    80004090:	fc040613          	addi	a2,s0,-64
    80004094:	4581                	li	a1,0
    80004096:	854a                	mv	a0,s2
    80004098:	00000097          	auipc	ra,0x0
    8000409c:	b8c080e7          	jalr	-1140(ra) # 80003c24 <readi>
    800040a0:	47c1                	li	a5,16
    800040a2:	06f51163          	bne	a0,a5,80004104 <dirlink+0xa2>
    if(de.inum == 0)
    800040a6:	fc045783          	lhu	a5,-64(s0)
    800040aa:	c791                	beqz	a5,800040b6 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040ac:	24c1                	addiw	s1,s1,16
    800040ae:	05492783          	lw	a5,84(s2)
    800040b2:	fcf4ede3          	bltu	s1,a5,8000408c <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800040b6:	4639                	li	a2,14
    800040b8:	85d2                	mv	a1,s4
    800040ba:	fc240513          	addi	a0,s0,-62
    800040be:	ffffd097          	auipc	ra,0xffffd
    800040c2:	132080e7          	jalr	306(ra) # 800011f0 <strncpy>
  de.inum = inum;
    800040c6:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040ca:	4741                	li	a4,16
    800040cc:	86a6                	mv	a3,s1
    800040ce:	fc040613          	addi	a2,s0,-64
    800040d2:	4581                	li	a1,0
    800040d4:	854a                	mv	a0,s2
    800040d6:	00000097          	auipc	ra,0x0
    800040da:	c46080e7          	jalr	-954(ra) # 80003d1c <writei>
    800040de:	872a                	mv	a4,a0
    800040e0:	47c1                	li	a5,16
  return 0;
    800040e2:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040e4:	02f71863          	bne	a4,a5,80004114 <dirlink+0xb2>
}
    800040e8:	70e2                	ld	ra,56(sp)
    800040ea:	7442                	ld	s0,48(sp)
    800040ec:	74a2                	ld	s1,40(sp)
    800040ee:	7902                	ld	s2,32(sp)
    800040f0:	69e2                	ld	s3,24(sp)
    800040f2:	6a42                	ld	s4,16(sp)
    800040f4:	6121                	addi	sp,sp,64
    800040f6:	8082                	ret
    iput(ip);
    800040f8:	00000097          	auipc	ra,0x0
    800040fc:	a32080e7          	jalr	-1486(ra) # 80003b2a <iput>
    return -1;
    80004100:	557d                	li	a0,-1
    80004102:	b7dd                	j	800040e8 <dirlink+0x86>
      panic("dirlink read");
    80004104:	00004517          	auipc	a0,0x4
    80004108:	57450513          	addi	a0,a0,1396 # 80008678 <syscalls+0x1c0>
    8000410c:	ffffc097          	auipc	ra,0xffffc
    80004110:	444080e7          	jalr	1092(ra) # 80000550 <panic>
    panic("dirlink");
    80004114:	00004517          	auipc	a0,0x4
    80004118:	68450513          	addi	a0,a0,1668 # 80008798 <syscalls+0x2e0>
    8000411c:	ffffc097          	auipc	ra,0xffffc
    80004120:	434080e7          	jalr	1076(ra) # 80000550 <panic>

0000000080004124 <namei>:

struct inode*
namei(char *path)
{
    80004124:	1101                	addi	sp,sp,-32
    80004126:	ec06                	sd	ra,24(sp)
    80004128:	e822                	sd	s0,16(sp)
    8000412a:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000412c:	fe040613          	addi	a2,s0,-32
    80004130:	4581                	li	a1,0
    80004132:	00000097          	auipc	ra,0x0
    80004136:	dd0080e7          	jalr	-560(ra) # 80003f02 <namex>
}
    8000413a:	60e2                	ld	ra,24(sp)
    8000413c:	6442                	ld	s0,16(sp)
    8000413e:	6105                	addi	sp,sp,32
    80004140:	8082                	ret

0000000080004142 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004142:	1141                	addi	sp,sp,-16
    80004144:	e406                	sd	ra,8(sp)
    80004146:	e022                	sd	s0,0(sp)
    80004148:	0800                	addi	s0,sp,16
    8000414a:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000414c:	4585                	li	a1,1
    8000414e:	00000097          	auipc	ra,0x0
    80004152:	db4080e7          	jalr	-588(ra) # 80003f02 <namex>
}
    80004156:	60a2                	ld	ra,8(sp)
    80004158:	6402                	ld	s0,0(sp)
    8000415a:	0141                	addi	sp,sp,16
    8000415c:	8082                	ret

000000008000415e <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    8000415e:	1101                	addi	sp,sp,-32
    80004160:	ec06                	sd	ra,24(sp)
    80004162:	e822                	sd	s0,16(sp)
    80004164:	e426                	sd	s1,8(sp)
    80004166:	e04a                	sd	s2,0(sp)
    80004168:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000416a:	0001e917          	auipc	s2,0x1e
    8000416e:	67e90913          	addi	s2,s2,1662 # 800227e8 <log>
    80004172:	02092583          	lw	a1,32(s2)
    80004176:	03092503          	lw	a0,48(s2)
    8000417a:	fffff097          	auipc	ra,0xfffff
    8000417e:	ff4080e7          	jalr	-12(ra) # 8000316e <bread>
    80004182:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004184:	03492683          	lw	a3,52(s2)
    80004188:	d134                	sw	a3,96(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000418a:	02d05763          	blez	a3,800041b8 <write_head+0x5a>
    8000418e:	0001e797          	auipc	a5,0x1e
    80004192:	69278793          	addi	a5,a5,1682 # 80022820 <log+0x38>
    80004196:	06450713          	addi	a4,a0,100
    8000419a:	36fd                	addiw	a3,a3,-1
    8000419c:	1682                	slli	a3,a3,0x20
    8000419e:	9281                	srli	a3,a3,0x20
    800041a0:	068a                	slli	a3,a3,0x2
    800041a2:	0001e617          	auipc	a2,0x1e
    800041a6:	68260613          	addi	a2,a2,1666 # 80022824 <log+0x3c>
    800041aa:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800041ac:	4390                	lw	a2,0(a5)
    800041ae:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800041b0:	0791                	addi	a5,a5,4
    800041b2:	0711                	addi	a4,a4,4
    800041b4:	fed79ce3          	bne	a5,a3,800041ac <write_head+0x4e>
  }
  bwrite(buf);
    800041b8:	8526                	mv	a0,s1
    800041ba:	fffff097          	auipc	ra,0xfffff
    800041be:	0a6080e7          	jalr	166(ra) # 80003260 <bwrite>
  brelse(buf);
    800041c2:	8526                	mv	a0,s1
    800041c4:	fffff097          	auipc	ra,0xfffff
    800041c8:	0da080e7          	jalr	218(ra) # 8000329e <brelse>
}
    800041cc:	60e2                	ld	ra,24(sp)
    800041ce:	6442                	ld	s0,16(sp)
    800041d0:	64a2                	ld	s1,8(sp)
    800041d2:	6902                	ld	s2,0(sp)
    800041d4:	6105                	addi	sp,sp,32
    800041d6:	8082                	ret

00000000800041d8 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800041d8:	0001e797          	auipc	a5,0x1e
    800041dc:	6447a783          	lw	a5,1604(a5) # 8002281c <log+0x34>
    800041e0:	0af05d63          	blez	a5,8000429a <install_trans+0xc2>
{
    800041e4:	7139                	addi	sp,sp,-64
    800041e6:	fc06                	sd	ra,56(sp)
    800041e8:	f822                	sd	s0,48(sp)
    800041ea:	f426                	sd	s1,40(sp)
    800041ec:	f04a                	sd	s2,32(sp)
    800041ee:	ec4e                	sd	s3,24(sp)
    800041f0:	e852                	sd	s4,16(sp)
    800041f2:	e456                	sd	s5,8(sp)
    800041f4:	e05a                	sd	s6,0(sp)
    800041f6:	0080                	addi	s0,sp,64
    800041f8:	8b2a                	mv	s6,a0
    800041fa:	0001ea97          	auipc	s5,0x1e
    800041fe:	626a8a93          	addi	s5,s5,1574 # 80022820 <log+0x38>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004202:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004204:	0001e997          	auipc	s3,0x1e
    80004208:	5e498993          	addi	s3,s3,1508 # 800227e8 <log>
    8000420c:	a035                	j	80004238 <install_trans+0x60>
      bunpin(dbuf);
    8000420e:	8526                	mv	a0,s1
    80004210:	fffff097          	auipc	ra,0xfffff
    80004214:	168080e7          	jalr	360(ra) # 80003378 <bunpin>
    brelse(lbuf);
    80004218:	854a                	mv	a0,s2
    8000421a:	fffff097          	auipc	ra,0xfffff
    8000421e:	084080e7          	jalr	132(ra) # 8000329e <brelse>
    brelse(dbuf);
    80004222:	8526                	mv	a0,s1
    80004224:	fffff097          	auipc	ra,0xfffff
    80004228:	07a080e7          	jalr	122(ra) # 8000329e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000422c:	2a05                	addiw	s4,s4,1
    8000422e:	0a91                	addi	s5,s5,4
    80004230:	0349a783          	lw	a5,52(s3)
    80004234:	04fa5963          	bge	s4,a5,80004286 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004238:	0209a583          	lw	a1,32(s3)
    8000423c:	014585bb          	addw	a1,a1,s4
    80004240:	2585                	addiw	a1,a1,1
    80004242:	0309a503          	lw	a0,48(s3)
    80004246:	fffff097          	auipc	ra,0xfffff
    8000424a:	f28080e7          	jalr	-216(ra) # 8000316e <bread>
    8000424e:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004250:	000aa583          	lw	a1,0(s5)
    80004254:	0309a503          	lw	a0,48(s3)
    80004258:	fffff097          	auipc	ra,0xfffff
    8000425c:	f16080e7          	jalr	-234(ra) # 8000316e <bread>
    80004260:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004262:	40000613          	li	a2,1024
    80004266:	06090593          	addi	a1,s2,96
    8000426a:	06050513          	addi	a0,a0,96
    8000426e:	ffffd097          	auipc	ra,0xffffd
    80004272:	eca080e7          	jalr	-310(ra) # 80001138 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004276:	8526                	mv	a0,s1
    80004278:	fffff097          	auipc	ra,0xfffff
    8000427c:	fe8080e7          	jalr	-24(ra) # 80003260 <bwrite>
    if(recovering == 0)
    80004280:	f80b1ce3          	bnez	s6,80004218 <install_trans+0x40>
    80004284:	b769                	j	8000420e <install_trans+0x36>
}
    80004286:	70e2                	ld	ra,56(sp)
    80004288:	7442                	ld	s0,48(sp)
    8000428a:	74a2                	ld	s1,40(sp)
    8000428c:	7902                	ld	s2,32(sp)
    8000428e:	69e2                	ld	s3,24(sp)
    80004290:	6a42                	ld	s4,16(sp)
    80004292:	6aa2                	ld	s5,8(sp)
    80004294:	6b02                	ld	s6,0(sp)
    80004296:	6121                	addi	sp,sp,64
    80004298:	8082                	ret
    8000429a:	8082                	ret

000000008000429c <initlog>:
{
    8000429c:	7179                	addi	sp,sp,-48
    8000429e:	f406                	sd	ra,40(sp)
    800042a0:	f022                	sd	s0,32(sp)
    800042a2:	ec26                	sd	s1,24(sp)
    800042a4:	e84a                	sd	s2,16(sp)
    800042a6:	e44e                	sd	s3,8(sp)
    800042a8:	1800                	addi	s0,sp,48
    800042aa:	892a                	mv	s2,a0
    800042ac:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800042ae:	0001e497          	auipc	s1,0x1e
    800042b2:	53a48493          	addi	s1,s1,1338 # 800227e8 <log>
    800042b6:	00004597          	auipc	a1,0x4
    800042ba:	3d258593          	addi	a1,a1,978 # 80008688 <syscalls+0x1d0>
    800042be:	8526                	mv	a0,s1
    800042c0:	ffffd097          	auipc	ra,0xffffd
    800042c4:	bb4080e7          	jalr	-1100(ra) # 80000e74 <initlock>
  log.start = sb->logstart;
    800042c8:	0149a583          	lw	a1,20(s3)
    800042cc:	d08c                	sw	a1,32(s1)
  log.size = sb->nlog;
    800042ce:	0109a783          	lw	a5,16(s3)
    800042d2:	d0dc                	sw	a5,36(s1)
  log.dev = dev;
    800042d4:	0324a823          	sw	s2,48(s1)
  struct buf *buf = bread(log.dev, log.start);
    800042d8:	854a                	mv	a0,s2
    800042da:	fffff097          	auipc	ra,0xfffff
    800042de:	e94080e7          	jalr	-364(ra) # 8000316e <bread>
  log.lh.n = lh->n;
    800042e2:	513c                	lw	a5,96(a0)
    800042e4:	d8dc                	sw	a5,52(s1)
  for (i = 0; i < log.lh.n; i++) {
    800042e6:	02f05563          	blez	a5,80004310 <initlog+0x74>
    800042ea:	06450713          	addi	a4,a0,100
    800042ee:	0001e697          	auipc	a3,0x1e
    800042f2:	53268693          	addi	a3,a3,1330 # 80022820 <log+0x38>
    800042f6:	37fd                	addiw	a5,a5,-1
    800042f8:	1782                	slli	a5,a5,0x20
    800042fa:	9381                	srli	a5,a5,0x20
    800042fc:	078a                	slli	a5,a5,0x2
    800042fe:	06850613          	addi	a2,a0,104
    80004302:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004304:	4310                	lw	a2,0(a4)
    80004306:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004308:	0711                	addi	a4,a4,4
    8000430a:	0691                	addi	a3,a3,4
    8000430c:	fef71ce3          	bne	a4,a5,80004304 <initlog+0x68>
  brelse(buf);
    80004310:	fffff097          	auipc	ra,0xfffff
    80004314:	f8e080e7          	jalr	-114(ra) # 8000329e <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004318:	4505                	li	a0,1
    8000431a:	00000097          	auipc	ra,0x0
    8000431e:	ebe080e7          	jalr	-322(ra) # 800041d8 <install_trans>
  log.lh.n = 0;
    80004322:	0001e797          	auipc	a5,0x1e
    80004326:	4e07ad23          	sw	zero,1274(a5) # 8002281c <log+0x34>
  write_head(); // clear the log
    8000432a:	00000097          	auipc	ra,0x0
    8000432e:	e34080e7          	jalr	-460(ra) # 8000415e <write_head>
}
    80004332:	70a2                	ld	ra,40(sp)
    80004334:	7402                	ld	s0,32(sp)
    80004336:	64e2                	ld	s1,24(sp)
    80004338:	6942                	ld	s2,16(sp)
    8000433a:	69a2                	ld	s3,8(sp)
    8000433c:	6145                	addi	sp,sp,48
    8000433e:	8082                	ret

0000000080004340 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004340:	1101                	addi	sp,sp,-32
    80004342:	ec06                	sd	ra,24(sp)
    80004344:	e822                	sd	s0,16(sp)
    80004346:	e426                	sd	s1,8(sp)
    80004348:	e04a                	sd	s2,0(sp)
    8000434a:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000434c:	0001e517          	auipc	a0,0x1e
    80004350:	49c50513          	addi	a0,a0,1180 # 800227e8 <log>
    80004354:	ffffd097          	auipc	ra,0xffffd
    80004358:	9a4080e7          	jalr	-1628(ra) # 80000cf8 <acquire>
  while(1){
    if(log.committing){
    8000435c:	0001e497          	auipc	s1,0x1e
    80004360:	48c48493          	addi	s1,s1,1164 # 800227e8 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004364:	4979                	li	s2,30
    80004366:	a039                	j	80004374 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004368:	85a6                	mv	a1,s1
    8000436a:	8526                	mv	a0,s1
    8000436c:	ffffe097          	auipc	ra,0xffffe
    80004370:	1e4080e7          	jalr	484(ra) # 80002550 <sleep>
    if(log.committing){
    80004374:	54dc                	lw	a5,44(s1)
    80004376:	fbed                	bnez	a5,80004368 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004378:	549c                	lw	a5,40(s1)
    8000437a:	0017871b          	addiw	a4,a5,1
    8000437e:	0007069b          	sext.w	a3,a4
    80004382:	0027179b          	slliw	a5,a4,0x2
    80004386:	9fb9                	addw	a5,a5,a4
    80004388:	0017979b          	slliw	a5,a5,0x1
    8000438c:	58d8                	lw	a4,52(s1)
    8000438e:	9fb9                	addw	a5,a5,a4
    80004390:	00f95963          	bge	s2,a5,800043a2 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004394:	85a6                	mv	a1,s1
    80004396:	8526                	mv	a0,s1
    80004398:	ffffe097          	auipc	ra,0xffffe
    8000439c:	1b8080e7          	jalr	440(ra) # 80002550 <sleep>
    800043a0:	bfd1                	j	80004374 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800043a2:	0001e517          	auipc	a0,0x1e
    800043a6:	44650513          	addi	a0,a0,1094 # 800227e8 <log>
    800043aa:	d514                	sw	a3,40(a0)
      release(&log.lock);
    800043ac:	ffffd097          	auipc	ra,0xffffd
    800043b0:	a1c080e7          	jalr	-1508(ra) # 80000dc8 <release>
      break;
    }
  }
}
    800043b4:	60e2                	ld	ra,24(sp)
    800043b6:	6442                	ld	s0,16(sp)
    800043b8:	64a2                	ld	s1,8(sp)
    800043ba:	6902                	ld	s2,0(sp)
    800043bc:	6105                	addi	sp,sp,32
    800043be:	8082                	ret

00000000800043c0 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800043c0:	7139                	addi	sp,sp,-64
    800043c2:	fc06                	sd	ra,56(sp)
    800043c4:	f822                	sd	s0,48(sp)
    800043c6:	f426                	sd	s1,40(sp)
    800043c8:	f04a                	sd	s2,32(sp)
    800043ca:	ec4e                	sd	s3,24(sp)
    800043cc:	e852                	sd	s4,16(sp)
    800043ce:	e456                	sd	s5,8(sp)
    800043d0:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800043d2:	0001e497          	auipc	s1,0x1e
    800043d6:	41648493          	addi	s1,s1,1046 # 800227e8 <log>
    800043da:	8526                	mv	a0,s1
    800043dc:	ffffd097          	auipc	ra,0xffffd
    800043e0:	91c080e7          	jalr	-1764(ra) # 80000cf8 <acquire>
  log.outstanding -= 1;
    800043e4:	549c                	lw	a5,40(s1)
    800043e6:	37fd                	addiw	a5,a5,-1
    800043e8:	0007891b          	sext.w	s2,a5
    800043ec:	d49c                	sw	a5,40(s1)
  if(log.committing)
    800043ee:	54dc                	lw	a5,44(s1)
    800043f0:	efb9                	bnez	a5,8000444e <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800043f2:	06091663          	bnez	s2,8000445e <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800043f6:	0001e497          	auipc	s1,0x1e
    800043fa:	3f248493          	addi	s1,s1,1010 # 800227e8 <log>
    800043fe:	4785                	li	a5,1
    80004400:	d4dc                	sw	a5,44(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004402:	8526                	mv	a0,s1
    80004404:	ffffd097          	auipc	ra,0xffffd
    80004408:	9c4080e7          	jalr	-1596(ra) # 80000dc8 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000440c:	58dc                	lw	a5,52(s1)
    8000440e:	06f04763          	bgtz	a5,8000447c <end_op+0xbc>
    acquire(&log.lock);
    80004412:	0001e497          	auipc	s1,0x1e
    80004416:	3d648493          	addi	s1,s1,982 # 800227e8 <log>
    8000441a:	8526                	mv	a0,s1
    8000441c:	ffffd097          	auipc	ra,0xffffd
    80004420:	8dc080e7          	jalr	-1828(ra) # 80000cf8 <acquire>
    log.committing = 0;
    80004424:	0204a623          	sw	zero,44(s1)
    wakeup(&log);
    80004428:	8526                	mv	a0,s1
    8000442a:	ffffe097          	auipc	ra,0xffffe
    8000442e:	2ac080e7          	jalr	684(ra) # 800026d6 <wakeup>
    release(&log.lock);
    80004432:	8526                	mv	a0,s1
    80004434:	ffffd097          	auipc	ra,0xffffd
    80004438:	994080e7          	jalr	-1644(ra) # 80000dc8 <release>
}
    8000443c:	70e2                	ld	ra,56(sp)
    8000443e:	7442                	ld	s0,48(sp)
    80004440:	74a2                	ld	s1,40(sp)
    80004442:	7902                	ld	s2,32(sp)
    80004444:	69e2                	ld	s3,24(sp)
    80004446:	6a42                	ld	s4,16(sp)
    80004448:	6aa2                	ld	s5,8(sp)
    8000444a:	6121                	addi	sp,sp,64
    8000444c:	8082                	ret
    panic("log.committing");
    8000444e:	00004517          	auipc	a0,0x4
    80004452:	24250513          	addi	a0,a0,578 # 80008690 <syscalls+0x1d8>
    80004456:	ffffc097          	auipc	ra,0xffffc
    8000445a:	0fa080e7          	jalr	250(ra) # 80000550 <panic>
    wakeup(&log);
    8000445e:	0001e497          	auipc	s1,0x1e
    80004462:	38a48493          	addi	s1,s1,906 # 800227e8 <log>
    80004466:	8526                	mv	a0,s1
    80004468:	ffffe097          	auipc	ra,0xffffe
    8000446c:	26e080e7          	jalr	622(ra) # 800026d6 <wakeup>
  release(&log.lock);
    80004470:	8526                	mv	a0,s1
    80004472:	ffffd097          	auipc	ra,0xffffd
    80004476:	956080e7          	jalr	-1706(ra) # 80000dc8 <release>
  if(do_commit){
    8000447a:	b7c9                	j	8000443c <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000447c:	0001ea97          	auipc	s5,0x1e
    80004480:	3a4a8a93          	addi	s5,s5,932 # 80022820 <log+0x38>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004484:	0001ea17          	auipc	s4,0x1e
    80004488:	364a0a13          	addi	s4,s4,868 # 800227e8 <log>
    8000448c:	020a2583          	lw	a1,32(s4)
    80004490:	012585bb          	addw	a1,a1,s2
    80004494:	2585                	addiw	a1,a1,1
    80004496:	030a2503          	lw	a0,48(s4)
    8000449a:	fffff097          	auipc	ra,0xfffff
    8000449e:	cd4080e7          	jalr	-812(ra) # 8000316e <bread>
    800044a2:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800044a4:	000aa583          	lw	a1,0(s5)
    800044a8:	030a2503          	lw	a0,48(s4)
    800044ac:	fffff097          	auipc	ra,0xfffff
    800044b0:	cc2080e7          	jalr	-830(ra) # 8000316e <bread>
    800044b4:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800044b6:	40000613          	li	a2,1024
    800044ba:	06050593          	addi	a1,a0,96
    800044be:	06048513          	addi	a0,s1,96
    800044c2:	ffffd097          	auipc	ra,0xffffd
    800044c6:	c76080e7          	jalr	-906(ra) # 80001138 <memmove>
    bwrite(to);  // write the log
    800044ca:	8526                	mv	a0,s1
    800044cc:	fffff097          	auipc	ra,0xfffff
    800044d0:	d94080e7          	jalr	-620(ra) # 80003260 <bwrite>
    brelse(from);
    800044d4:	854e                	mv	a0,s3
    800044d6:	fffff097          	auipc	ra,0xfffff
    800044da:	dc8080e7          	jalr	-568(ra) # 8000329e <brelse>
    brelse(to);
    800044de:	8526                	mv	a0,s1
    800044e0:	fffff097          	auipc	ra,0xfffff
    800044e4:	dbe080e7          	jalr	-578(ra) # 8000329e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800044e8:	2905                	addiw	s2,s2,1
    800044ea:	0a91                	addi	s5,s5,4
    800044ec:	034a2783          	lw	a5,52(s4)
    800044f0:	f8f94ee3          	blt	s2,a5,8000448c <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800044f4:	00000097          	auipc	ra,0x0
    800044f8:	c6a080e7          	jalr	-918(ra) # 8000415e <write_head>
    install_trans(0); // Now install writes to home locations
    800044fc:	4501                	li	a0,0
    800044fe:	00000097          	auipc	ra,0x0
    80004502:	cda080e7          	jalr	-806(ra) # 800041d8 <install_trans>
    log.lh.n = 0;
    80004506:	0001e797          	auipc	a5,0x1e
    8000450a:	3007ab23          	sw	zero,790(a5) # 8002281c <log+0x34>
    write_head();    // Erase the transaction from the log
    8000450e:	00000097          	auipc	ra,0x0
    80004512:	c50080e7          	jalr	-944(ra) # 8000415e <write_head>
    80004516:	bdf5                	j	80004412 <end_op+0x52>

0000000080004518 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004518:	1101                	addi	sp,sp,-32
    8000451a:	ec06                	sd	ra,24(sp)
    8000451c:	e822                	sd	s0,16(sp)
    8000451e:	e426                	sd	s1,8(sp)
    80004520:	e04a                	sd	s2,0(sp)
    80004522:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004524:	0001e717          	auipc	a4,0x1e
    80004528:	2f872703          	lw	a4,760(a4) # 8002281c <log+0x34>
    8000452c:	47f5                	li	a5,29
    8000452e:	08e7c063          	blt	a5,a4,800045ae <log_write+0x96>
    80004532:	84aa                	mv	s1,a0
    80004534:	0001e797          	auipc	a5,0x1e
    80004538:	2d87a783          	lw	a5,728(a5) # 8002280c <log+0x24>
    8000453c:	37fd                	addiw	a5,a5,-1
    8000453e:	06f75863          	bge	a4,a5,800045ae <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004542:	0001e797          	auipc	a5,0x1e
    80004546:	2ce7a783          	lw	a5,718(a5) # 80022810 <log+0x28>
    8000454a:	06f05a63          	blez	a5,800045be <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    8000454e:	0001e917          	auipc	s2,0x1e
    80004552:	29a90913          	addi	s2,s2,666 # 800227e8 <log>
    80004556:	854a                	mv	a0,s2
    80004558:	ffffc097          	auipc	ra,0xffffc
    8000455c:	7a0080e7          	jalr	1952(ra) # 80000cf8 <acquire>
  for (i = 0; i < log.lh.n; i++) {
    80004560:	03492603          	lw	a2,52(s2)
    80004564:	06c05563          	blez	a2,800045ce <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004568:	44cc                	lw	a1,12(s1)
    8000456a:	0001e717          	auipc	a4,0x1e
    8000456e:	2b670713          	addi	a4,a4,694 # 80022820 <log+0x38>
  for (i = 0; i < log.lh.n; i++) {
    80004572:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004574:	4314                	lw	a3,0(a4)
    80004576:	04b68d63          	beq	a3,a1,800045d0 <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    8000457a:	2785                	addiw	a5,a5,1
    8000457c:	0711                	addi	a4,a4,4
    8000457e:	fec79be3          	bne	a5,a2,80004574 <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004582:	0631                	addi	a2,a2,12
    80004584:	060a                	slli	a2,a2,0x2
    80004586:	0001e797          	auipc	a5,0x1e
    8000458a:	26278793          	addi	a5,a5,610 # 800227e8 <log>
    8000458e:	963e                	add	a2,a2,a5
    80004590:	44dc                	lw	a5,12(s1)
    80004592:	c61c                	sw	a5,8(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004594:	8526                	mv	a0,s1
    80004596:	fffff097          	auipc	ra,0xfffff
    8000459a:	da6080e7          	jalr	-602(ra) # 8000333c <bpin>
    log.lh.n++;
    8000459e:	0001e717          	auipc	a4,0x1e
    800045a2:	24a70713          	addi	a4,a4,586 # 800227e8 <log>
    800045a6:	5b5c                	lw	a5,52(a4)
    800045a8:	2785                	addiw	a5,a5,1
    800045aa:	db5c                	sw	a5,52(a4)
    800045ac:	a83d                	j	800045ea <log_write+0xd2>
    panic("too big a transaction");
    800045ae:	00004517          	auipc	a0,0x4
    800045b2:	0f250513          	addi	a0,a0,242 # 800086a0 <syscalls+0x1e8>
    800045b6:	ffffc097          	auipc	ra,0xffffc
    800045ba:	f9a080e7          	jalr	-102(ra) # 80000550 <panic>
    panic("log_write outside of trans");
    800045be:	00004517          	auipc	a0,0x4
    800045c2:	0fa50513          	addi	a0,a0,250 # 800086b8 <syscalls+0x200>
    800045c6:	ffffc097          	auipc	ra,0xffffc
    800045ca:	f8a080e7          	jalr	-118(ra) # 80000550 <panic>
  for (i = 0; i < log.lh.n; i++) {
    800045ce:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    800045d0:	00c78713          	addi	a4,a5,12
    800045d4:	00271693          	slli	a3,a4,0x2
    800045d8:	0001e717          	auipc	a4,0x1e
    800045dc:	21070713          	addi	a4,a4,528 # 800227e8 <log>
    800045e0:	9736                	add	a4,a4,a3
    800045e2:	44d4                	lw	a3,12(s1)
    800045e4:	c714                	sw	a3,8(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800045e6:	faf607e3          	beq	a2,a5,80004594 <log_write+0x7c>
  }
  release(&log.lock);
    800045ea:	0001e517          	auipc	a0,0x1e
    800045ee:	1fe50513          	addi	a0,a0,510 # 800227e8 <log>
    800045f2:	ffffc097          	auipc	ra,0xffffc
    800045f6:	7d6080e7          	jalr	2006(ra) # 80000dc8 <release>
}
    800045fa:	60e2                	ld	ra,24(sp)
    800045fc:	6442                	ld	s0,16(sp)
    800045fe:	64a2                	ld	s1,8(sp)
    80004600:	6902                	ld	s2,0(sp)
    80004602:	6105                	addi	sp,sp,32
    80004604:	8082                	ret

0000000080004606 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004606:	1101                	addi	sp,sp,-32
    80004608:	ec06                	sd	ra,24(sp)
    8000460a:	e822                	sd	s0,16(sp)
    8000460c:	e426                	sd	s1,8(sp)
    8000460e:	e04a                	sd	s2,0(sp)
    80004610:	1000                	addi	s0,sp,32
    80004612:	84aa                	mv	s1,a0
    80004614:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004616:	00004597          	auipc	a1,0x4
    8000461a:	0c258593          	addi	a1,a1,194 # 800086d8 <syscalls+0x220>
    8000461e:	0521                	addi	a0,a0,8
    80004620:	ffffd097          	auipc	ra,0xffffd
    80004624:	854080e7          	jalr	-1964(ra) # 80000e74 <initlock>
  lk->name = name;
    80004628:	0324b423          	sd	s2,40(s1)
  lk->locked = 0;
    8000462c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004630:	0204a823          	sw	zero,48(s1)
}
    80004634:	60e2                	ld	ra,24(sp)
    80004636:	6442                	ld	s0,16(sp)
    80004638:	64a2                	ld	s1,8(sp)
    8000463a:	6902                	ld	s2,0(sp)
    8000463c:	6105                	addi	sp,sp,32
    8000463e:	8082                	ret

0000000080004640 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004640:	1101                	addi	sp,sp,-32
    80004642:	ec06                	sd	ra,24(sp)
    80004644:	e822                	sd	s0,16(sp)
    80004646:	e426                	sd	s1,8(sp)
    80004648:	e04a                	sd	s2,0(sp)
    8000464a:	1000                	addi	s0,sp,32
    8000464c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000464e:	00850913          	addi	s2,a0,8
    80004652:	854a                	mv	a0,s2
    80004654:	ffffc097          	auipc	ra,0xffffc
    80004658:	6a4080e7          	jalr	1700(ra) # 80000cf8 <acquire>
  while (lk->locked) {
    8000465c:	409c                	lw	a5,0(s1)
    8000465e:	cb89                	beqz	a5,80004670 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004660:	85ca                	mv	a1,s2
    80004662:	8526                	mv	a0,s1
    80004664:	ffffe097          	auipc	ra,0xffffe
    80004668:	eec080e7          	jalr	-276(ra) # 80002550 <sleep>
  while (lk->locked) {
    8000466c:	409c                	lw	a5,0(s1)
    8000466e:	fbed                	bnez	a5,80004660 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004670:	4785                	li	a5,1
    80004672:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004674:	ffffd097          	auipc	ra,0xffffd
    80004678:	6cc080e7          	jalr	1740(ra) # 80001d40 <myproc>
    8000467c:	413c                	lw	a5,64(a0)
    8000467e:	d89c                	sw	a5,48(s1)
  release(&lk->lk);
    80004680:	854a                	mv	a0,s2
    80004682:	ffffc097          	auipc	ra,0xffffc
    80004686:	746080e7          	jalr	1862(ra) # 80000dc8 <release>
}
    8000468a:	60e2                	ld	ra,24(sp)
    8000468c:	6442                	ld	s0,16(sp)
    8000468e:	64a2                	ld	s1,8(sp)
    80004690:	6902                	ld	s2,0(sp)
    80004692:	6105                	addi	sp,sp,32
    80004694:	8082                	ret

0000000080004696 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004696:	1101                	addi	sp,sp,-32
    80004698:	ec06                	sd	ra,24(sp)
    8000469a:	e822                	sd	s0,16(sp)
    8000469c:	e426                	sd	s1,8(sp)
    8000469e:	e04a                	sd	s2,0(sp)
    800046a0:	1000                	addi	s0,sp,32
    800046a2:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800046a4:	00850913          	addi	s2,a0,8
    800046a8:	854a                	mv	a0,s2
    800046aa:	ffffc097          	auipc	ra,0xffffc
    800046ae:	64e080e7          	jalr	1614(ra) # 80000cf8 <acquire>
  lk->locked = 0;
    800046b2:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800046b6:	0204a823          	sw	zero,48(s1)
  wakeup(lk);
    800046ba:	8526                	mv	a0,s1
    800046bc:	ffffe097          	auipc	ra,0xffffe
    800046c0:	01a080e7          	jalr	26(ra) # 800026d6 <wakeup>
  release(&lk->lk);
    800046c4:	854a                	mv	a0,s2
    800046c6:	ffffc097          	auipc	ra,0xffffc
    800046ca:	702080e7          	jalr	1794(ra) # 80000dc8 <release>
}
    800046ce:	60e2                	ld	ra,24(sp)
    800046d0:	6442                	ld	s0,16(sp)
    800046d2:	64a2                	ld	s1,8(sp)
    800046d4:	6902                	ld	s2,0(sp)
    800046d6:	6105                	addi	sp,sp,32
    800046d8:	8082                	ret

00000000800046da <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800046da:	7179                	addi	sp,sp,-48
    800046dc:	f406                	sd	ra,40(sp)
    800046de:	f022                	sd	s0,32(sp)
    800046e0:	ec26                	sd	s1,24(sp)
    800046e2:	e84a                	sd	s2,16(sp)
    800046e4:	e44e                	sd	s3,8(sp)
    800046e6:	1800                	addi	s0,sp,48
    800046e8:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800046ea:	00850913          	addi	s2,a0,8
    800046ee:	854a                	mv	a0,s2
    800046f0:	ffffc097          	auipc	ra,0xffffc
    800046f4:	608080e7          	jalr	1544(ra) # 80000cf8 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800046f8:	409c                	lw	a5,0(s1)
    800046fa:	ef99                	bnez	a5,80004718 <holdingsleep+0x3e>
    800046fc:	4481                	li	s1,0
  release(&lk->lk);
    800046fe:	854a                	mv	a0,s2
    80004700:	ffffc097          	auipc	ra,0xffffc
    80004704:	6c8080e7          	jalr	1736(ra) # 80000dc8 <release>
  return r;
}
    80004708:	8526                	mv	a0,s1
    8000470a:	70a2                	ld	ra,40(sp)
    8000470c:	7402                	ld	s0,32(sp)
    8000470e:	64e2                	ld	s1,24(sp)
    80004710:	6942                	ld	s2,16(sp)
    80004712:	69a2                	ld	s3,8(sp)
    80004714:	6145                	addi	sp,sp,48
    80004716:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004718:	0304a983          	lw	s3,48(s1)
    8000471c:	ffffd097          	auipc	ra,0xffffd
    80004720:	624080e7          	jalr	1572(ra) # 80001d40 <myproc>
    80004724:	4124                	lw	s1,64(a0)
    80004726:	413484b3          	sub	s1,s1,s3
    8000472a:	0014b493          	seqz	s1,s1
    8000472e:	bfc1                	j	800046fe <holdingsleep+0x24>

0000000080004730 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004730:	1141                	addi	sp,sp,-16
    80004732:	e406                	sd	ra,8(sp)
    80004734:	e022                	sd	s0,0(sp)
    80004736:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004738:	00004597          	auipc	a1,0x4
    8000473c:	fb058593          	addi	a1,a1,-80 # 800086e8 <syscalls+0x230>
    80004740:	0001e517          	auipc	a0,0x1e
    80004744:	1f850513          	addi	a0,a0,504 # 80022938 <ftable>
    80004748:	ffffc097          	auipc	ra,0xffffc
    8000474c:	72c080e7          	jalr	1836(ra) # 80000e74 <initlock>
}
    80004750:	60a2                	ld	ra,8(sp)
    80004752:	6402                	ld	s0,0(sp)
    80004754:	0141                	addi	sp,sp,16
    80004756:	8082                	ret

0000000080004758 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004758:	1101                	addi	sp,sp,-32
    8000475a:	ec06                	sd	ra,24(sp)
    8000475c:	e822                	sd	s0,16(sp)
    8000475e:	e426                	sd	s1,8(sp)
    80004760:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004762:	0001e517          	auipc	a0,0x1e
    80004766:	1d650513          	addi	a0,a0,470 # 80022938 <ftable>
    8000476a:	ffffc097          	auipc	ra,0xffffc
    8000476e:	58e080e7          	jalr	1422(ra) # 80000cf8 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004772:	0001e497          	auipc	s1,0x1e
    80004776:	1e648493          	addi	s1,s1,486 # 80022958 <ftable+0x20>
    8000477a:	0001f717          	auipc	a4,0x1f
    8000477e:	17e70713          	addi	a4,a4,382 # 800238f8 <ftable+0xfc0>
    if(f->ref == 0){
    80004782:	40dc                	lw	a5,4(s1)
    80004784:	cf99                	beqz	a5,800047a2 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004786:	02848493          	addi	s1,s1,40
    8000478a:	fee49ce3          	bne	s1,a4,80004782 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000478e:	0001e517          	auipc	a0,0x1e
    80004792:	1aa50513          	addi	a0,a0,426 # 80022938 <ftable>
    80004796:	ffffc097          	auipc	ra,0xffffc
    8000479a:	632080e7          	jalr	1586(ra) # 80000dc8 <release>
  return 0;
    8000479e:	4481                	li	s1,0
    800047a0:	a819                	j	800047b6 <filealloc+0x5e>
      f->ref = 1;
    800047a2:	4785                	li	a5,1
    800047a4:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800047a6:	0001e517          	auipc	a0,0x1e
    800047aa:	19250513          	addi	a0,a0,402 # 80022938 <ftable>
    800047ae:	ffffc097          	auipc	ra,0xffffc
    800047b2:	61a080e7          	jalr	1562(ra) # 80000dc8 <release>
}
    800047b6:	8526                	mv	a0,s1
    800047b8:	60e2                	ld	ra,24(sp)
    800047ba:	6442                	ld	s0,16(sp)
    800047bc:	64a2                	ld	s1,8(sp)
    800047be:	6105                	addi	sp,sp,32
    800047c0:	8082                	ret

00000000800047c2 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800047c2:	1101                	addi	sp,sp,-32
    800047c4:	ec06                	sd	ra,24(sp)
    800047c6:	e822                	sd	s0,16(sp)
    800047c8:	e426                	sd	s1,8(sp)
    800047ca:	1000                	addi	s0,sp,32
    800047cc:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800047ce:	0001e517          	auipc	a0,0x1e
    800047d2:	16a50513          	addi	a0,a0,362 # 80022938 <ftable>
    800047d6:	ffffc097          	auipc	ra,0xffffc
    800047da:	522080e7          	jalr	1314(ra) # 80000cf8 <acquire>
  if(f->ref < 1)
    800047de:	40dc                	lw	a5,4(s1)
    800047e0:	02f05263          	blez	a5,80004804 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800047e4:	2785                	addiw	a5,a5,1
    800047e6:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800047e8:	0001e517          	auipc	a0,0x1e
    800047ec:	15050513          	addi	a0,a0,336 # 80022938 <ftable>
    800047f0:	ffffc097          	auipc	ra,0xffffc
    800047f4:	5d8080e7          	jalr	1496(ra) # 80000dc8 <release>
  return f;
}
    800047f8:	8526                	mv	a0,s1
    800047fa:	60e2                	ld	ra,24(sp)
    800047fc:	6442                	ld	s0,16(sp)
    800047fe:	64a2                	ld	s1,8(sp)
    80004800:	6105                	addi	sp,sp,32
    80004802:	8082                	ret
    panic("filedup");
    80004804:	00004517          	auipc	a0,0x4
    80004808:	eec50513          	addi	a0,a0,-276 # 800086f0 <syscalls+0x238>
    8000480c:	ffffc097          	auipc	ra,0xffffc
    80004810:	d44080e7          	jalr	-700(ra) # 80000550 <panic>

0000000080004814 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004814:	7139                	addi	sp,sp,-64
    80004816:	fc06                	sd	ra,56(sp)
    80004818:	f822                	sd	s0,48(sp)
    8000481a:	f426                	sd	s1,40(sp)
    8000481c:	f04a                	sd	s2,32(sp)
    8000481e:	ec4e                	sd	s3,24(sp)
    80004820:	e852                	sd	s4,16(sp)
    80004822:	e456                	sd	s5,8(sp)
    80004824:	0080                	addi	s0,sp,64
    80004826:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004828:	0001e517          	auipc	a0,0x1e
    8000482c:	11050513          	addi	a0,a0,272 # 80022938 <ftable>
    80004830:	ffffc097          	auipc	ra,0xffffc
    80004834:	4c8080e7          	jalr	1224(ra) # 80000cf8 <acquire>
  if(f->ref < 1)
    80004838:	40dc                	lw	a5,4(s1)
    8000483a:	06f05163          	blez	a5,8000489c <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000483e:	37fd                	addiw	a5,a5,-1
    80004840:	0007871b          	sext.w	a4,a5
    80004844:	c0dc                	sw	a5,4(s1)
    80004846:	06e04363          	bgtz	a4,800048ac <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000484a:	0004a903          	lw	s2,0(s1)
    8000484e:	0094ca83          	lbu	s5,9(s1)
    80004852:	0104ba03          	ld	s4,16(s1)
    80004856:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000485a:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000485e:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004862:	0001e517          	auipc	a0,0x1e
    80004866:	0d650513          	addi	a0,a0,214 # 80022938 <ftable>
    8000486a:	ffffc097          	auipc	ra,0xffffc
    8000486e:	55e080e7          	jalr	1374(ra) # 80000dc8 <release>

  if(ff.type == FD_PIPE){
    80004872:	4785                	li	a5,1
    80004874:	04f90d63          	beq	s2,a5,800048ce <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004878:	3979                	addiw	s2,s2,-2
    8000487a:	4785                	li	a5,1
    8000487c:	0527e063          	bltu	a5,s2,800048bc <fileclose+0xa8>
    begin_op();
    80004880:	00000097          	auipc	ra,0x0
    80004884:	ac0080e7          	jalr	-1344(ra) # 80004340 <begin_op>
    iput(ff.ip);
    80004888:	854e                	mv	a0,s3
    8000488a:	fffff097          	auipc	ra,0xfffff
    8000488e:	2a0080e7          	jalr	672(ra) # 80003b2a <iput>
    end_op();
    80004892:	00000097          	auipc	ra,0x0
    80004896:	b2e080e7          	jalr	-1234(ra) # 800043c0 <end_op>
    8000489a:	a00d                	j	800048bc <fileclose+0xa8>
    panic("fileclose");
    8000489c:	00004517          	auipc	a0,0x4
    800048a0:	e5c50513          	addi	a0,a0,-420 # 800086f8 <syscalls+0x240>
    800048a4:	ffffc097          	auipc	ra,0xffffc
    800048a8:	cac080e7          	jalr	-852(ra) # 80000550 <panic>
    release(&ftable.lock);
    800048ac:	0001e517          	auipc	a0,0x1e
    800048b0:	08c50513          	addi	a0,a0,140 # 80022938 <ftable>
    800048b4:	ffffc097          	auipc	ra,0xffffc
    800048b8:	514080e7          	jalr	1300(ra) # 80000dc8 <release>
  }
}
    800048bc:	70e2                	ld	ra,56(sp)
    800048be:	7442                	ld	s0,48(sp)
    800048c0:	74a2                	ld	s1,40(sp)
    800048c2:	7902                	ld	s2,32(sp)
    800048c4:	69e2                	ld	s3,24(sp)
    800048c6:	6a42                	ld	s4,16(sp)
    800048c8:	6aa2                	ld	s5,8(sp)
    800048ca:	6121                	addi	sp,sp,64
    800048cc:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800048ce:	85d6                	mv	a1,s5
    800048d0:	8552                	mv	a0,s4
    800048d2:	00000097          	auipc	ra,0x0
    800048d6:	372080e7          	jalr	882(ra) # 80004c44 <pipeclose>
    800048da:	b7cd                	j	800048bc <fileclose+0xa8>

00000000800048dc <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800048dc:	715d                	addi	sp,sp,-80
    800048de:	e486                	sd	ra,72(sp)
    800048e0:	e0a2                	sd	s0,64(sp)
    800048e2:	fc26                	sd	s1,56(sp)
    800048e4:	f84a                	sd	s2,48(sp)
    800048e6:	f44e                	sd	s3,40(sp)
    800048e8:	0880                	addi	s0,sp,80
    800048ea:	84aa                	mv	s1,a0
    800048ec:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800048ee:	ffffd097          	auipc	ra,0xffffd
    800048f2:	452080e7          	jalr	1106(ra) # 80001d40 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800048f6:	409c                	lw	a5,0(s1)
    800048f8:	37f9                	addiw	a5,a5,-2
    800048fa:	4705                	li	a4,1
    800048fc:	04f76763          	bltu	a4,a5,8000494a <filestat+0x6e>
    80004900:	892a                	mv	s2,a0
    ilock(f->ip);
    80004902:	6c88                	ld	a0,24(s1)
    80004904:	fffff097          	auipc	ra,0xfffff
    80004908:	06c080e7          	jalr	108(ra) # 80003970 <ilock>
    stati(f->ip, &st);
    8000490c:	fb840593          	addi	a1,s0,-72
    80004910:	6c88                	ld	a0,24(s1)
    80004912:	fffff097          	auipc	ra,0xfffff
    80004916:	2e8080e7          	jalr	744(ra) # 80003bfa <stati>
    iunlock(f->ip);
    8000491a:	6c88                	ld	a0,24(s1)
    8000491c:	fffff097          	auipc	ra,0xfffff
    80004920:	116080e7          	jalr	278(ra) # 80003a32 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004924:	46e1                	li	a3,24
    80004926:	fb840613          	addi	a2,s0,-72
    8000492a:	85ce                	mv	a1,s3
    8000492c:	05893503          	ld	a0,88(s2)
    80004930:	ffffd097          	auipc	ra,0xffffd
    80004934:	104080e7          	jalr	260(ra) # 80001a34 <copyout>
    80004938:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000493c:	60a6                	ld	ra,72(sp)
    8000493e:	6406                	ld	s0,64(sp)
    80004940:	74e2                	ld	s1,56(sp)
    80004942:	7942                	ld	s2,48(sp)
    80004944:	79a2                	ld	s3,40(sp)
    80004946:	6161                	addi	sp,sp,80
    80004948:	8082                	ret
  return -1;
    8000494a:	557d                	li	a0,-1
    8000494c:	bfc5                	j	8000493c <filestat+0x60>

000000008000494e <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000494e:	7179                	addi	sp,sp,-48
    80004950:	f406                	sd	ra,40(sp)
    80004952:	f022                	sd	s0,32(sp)
    80004954:	ec26                	sd	s1,24(sp)
    80004956:	e84a                	sd	s2,16(sp)
    80004958:	e44e                	sd	s3,8(sp)
    8000495a:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000495c:	00854783          	lbu	a5,8(a0)
    80004960:	c3d5                	beqz	a5,80004a04 <fileread+0xb6>
    80004962:	84aa                	mv	s1,a0
    80004964:	89ae                	mv	s3,a1
    80004966:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004968:	411c                	lw	a5,0(a0)
    8000496a:	4705                	li	a4,1
    8000496c:	04e78963          	beq	a5,a4,800049be <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004970:	470d                	li	a4,3
    80004972:	04e78d63          	beq	a5,a4,800049cc <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004976:	4709                	li	a4,2
    80004978:	06e79e63          	bne	a5,a4,800049f4 <fileread+0xa6>
    ilock(f->ip);
    8000497c:	6d08                	ld	a0,24(a0)
    8000497e:	fffff097          	auipc	ra,0xfffff
    80004982:	ff2080e7          	jalr	-14(ra) # 80003970 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004986:	874a                	mv	a4,s2
    80004988:	5094                	lw	a3,32(s1)
    8000498a:	864e                	mv	a2,s3
    8000498c:	4585                	li	a1,1
    8000498e:	6c88                	ld	a0,24(s1)
    80004990:	fffff097          	auipc	ra,0xfffff
    80004994:	294080e7          	jalr	660(ra) # 80003c24 <readi>
    80004998:	892a                	mv	s2,a0
    8000499a:	00a05563          	blez	a0,800049a4 <fileread+0x56>
      f->off += r;
    8000499e:	509c                	lw	a5,32(s1)
    800049a0:	9fa9                	addw	a5,a5,a0
    800049a2:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800049a4:	6c88                	ld	a0,24(s1)
    800049a6:	fffff097          	auipc	ra,0xfffff
    800049aa:	08c080e7          	jalr	140(ra) # 80003a32 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800049ae:	854a                	mv	a0,s2
    800049b0:	70a2                	ld	ra,40(sp)
    800049b2:	7402                	ld	s0,32(sp)
    800049b4:	64e2                	ld	s1,24(sp)
    800049b6:	6942                	ld	s2,16(sp)
    800049b8:	69a2                	ld	s3,8(sp)
    800049ba:	6145                	addi	sp,sp,48
    800049bc:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800049be:	6908                	ld	a0,16(a0)
    800049c0:	00000097          	auipc	ra,0x0
    800049c4:	422080e7          	jalr	1058(ra) # 80004de2 <piperead>
    800049c8:	892a                	mv	s2,a0
    800049ca:	b7d5                	j	800049ae <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800049cc:	02451783          	lh	a5,36(a0)
    800049d0:	03079693          	slli	a3,a5,0x30
    800049d4:	92c1                	srli	a3,a3,0x30
    800049d6:	4725                	li	a4,9
    800049d8:	02d76863          	bltu	a4,a3,80004a08 <fileread+0xba>
    800049dc:	0792                	slli	a5,a5,0x4
    800049de:	0001e717          	auipc	a4,0x1e
    800049e2:	eba70713          	addi	a4,a4,-326 # 80022898 <devsw>
    800049e6:	97ba                	add	a5,a5,a4
    800049e8:	639c                	ld	a5,0(a5)
    800049ea:	c38d                	beqz	a5,80004a0c <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800049ec:	4505                	li	a0,1
    800049ee:	9782                	jalr	a5
    800049f0:	892a                	mv	s2,a0
    800049f2:	bf75                	j	800049ae <fileread+0x60>
    panic("fileread");
    800049f4:	00004517          	auipc	a0,0x4
    800049f8:	d1450513          	addi	a0,a0,-748 # 80008708 <syscalls+0x250>
    800049fc:	ffffc097          	auipc	ra,0xffffc
    80004a00:	b54080e7          	jalr	-1196(ra) # 80000550 <panic>
    return -1;
    80004a04:	597d                	li	s2,-1
    80004a06:	b765                	j	800049ae <fileread+0x60>
      return -1;
    80004a08:	597d                	li	s2,-1
    80004a0a:	b755                	j	800049ae <fileread+0x60>
    80004a0c:	597d                	li	s2,-1
    80004a0e:	b745                	j	800049ae <fileread+0x60>

0000000080004a10 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004a10:	00954783          	lbu	a5,9(a0)
    80004a14:	14078563          	beqz	a5,80004b5e <filewrite+0x14e>
{
    80004a18:	715d                	addi	sp,sp,-80
    80004a1a:	e486                	sd	ra,72(sp)
    80004a1c:	e0a2                	sd	s0,64(sp)
    80004a1e:	fc26                	sd	s1,56(sp)
    80004a20:	f84a                	sd	s2,48(sp)
    80004a22:	f44e                	sd	s3,40(sp)
    80004a24:	f052                	sd	s4,32(sp)
    80004a26:	ec56                	sd	s5,24(sp)
    80004a28:	e85a                	sd	s6,16(sp)
    80004a2a:	e45e                	sd	s7,8(sp)
    80004a2c:	e062                	sd	s8,0(sp)
    80004a2e:	0880                	addi	s0,sp,80
    80004a30:	892a                	mv	s2,a0
    80004a32:	8aae                	mv	s5,a1
    80004a34:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004a36:	411c                	lw	a5,0(a0)
    80004a38:	4705                	li	a4,1
    80004a3a:	02e78263          	beq	a5,a4,80004a5e <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004a3e:	470d                	li	a4,3
    80004a40:	02e78563          	beq	a5,a4,80004a6a <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004a44:	4709                	li	a4,2
    80004a46:	10e79463          	bne	a5,a4,80004b4e <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004a4a:	0ec05e63          	blez	a2,80004b46 <filewrite+0x136>
    int i = 0;
    80004a4e:	4981                	li	s3,0
    80004a50:	6b05                	lui	s6,0x1
    80004a52:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004a56:	6b85                	lui	s7,0x1
    80004a58:	c00b8b9b          	addiw	s7,s7,-1024
    80004a5c:	a851                	j	80004af0 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004a5e:	6908                	ld	a0,16(a0)
    80004a60:	00000097          	auipc	ra,0x0
    80004a64:	25e080e7          	jalr	606(ra) # 80004cbe <pipewrite>
    80004a68:	a85d                	j	80004b1e <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004a6a:	02451783          	lh	a5,36(a0)
    80004a6e:	03079693          	slli	a3,a5,0x30
    80004a72:	92c1                	srli	a3,a3,0x30
    80004a74:	4725                	li	a4,9
    80004a76:	0ed76663          	bltu	a4,a3,80004b62 <filewrite+0x152>
    80004a7a:	0792                	slli	a5,a5,0x4
    80004a7c:	0001e717          	auipc	a4,0x1e
    80004a80:	e1c70713          	addi	a4,a4,-484 # 80022898 <devsw>
    80004a84:	97ba                	add	a5,a5,a4
    80004a86:	679c                	ld	a5,8(a5)
    80004a88:	cff9                	beqz	a5,80004b66 <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    80004a8a:	4505                	li	a0,1
    80004a8c:	9782                	jalr	a5
    80004a8e:	a841                	j	80004b1e <filewrite+0x10e>
    80004a90:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004a94:	00000097          	auipc	ra,0x0
    80004a98:	8ac080e7          	jalr	-1876(ra) # 80004340 <begin_op>
      ilock(f->ip);
    80004a9c:	01893503          	ld	a0,24(s2)
    80004aa0:	fffff097          	auipc	ra,0xfffff
    80004aa4:	ed0080e7          	jalr	-304(ra) # 80003970 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004aa8:	8762                	mv	a4,s8
    80004aaa:	02092683          	lw	a3,32(s2)
    80004aae:	01598633          	add	a2,s3,s5
    80004ab2:	4585                	li	a1,1
    80004ab4:	01893503          	ld	a0,24(s2)
    80004ab8:	fffff097          	auipc	ra,0xfffff
    80004abc:	264080e7          	jalr	612(ra) # 80003d1c <writei>
    80004ac0:	84aa                	mv	s1,a0
    80004ac2:	02a05f63          	blez	a0,80004b00 <filewrite+0xf0>
        f->off += r;
    80004ac6:	02092783          	lw	a5,32(s2)
    80004aca:	9fa9                	addw	a5,a5,a0
    80004acc:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004ad0:	01893503          	ld	a0,24(s2)
    80004ad4:	fffff097          	auipc	ra,0xfffff
    80004ad8:	f5e080e7          	jalr	-162(ra) # 80003a32 <iunlock>
      end_op();
    80004adc:	00000097          	auipc	ra,0x0
    80004ae0:	8e4080e7          	jalr	-1820(ra) # 800043c0 <end_op>

      if(r < 0)
        break;
      if(r != n1)
    80004ae4:	049c1963          	bne	s8,s1,80004b36 <filewrite+0x126>
        panic("short filewrite");
      i += r;
    80004ae8:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004aec:	0349d663          	bge	s3,s4,80004b18 <filewrite+0x108>
      int n1 = n - i;
    80004af0:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004af4:	84be                	mv	s1,a5
    80004af6:	2781                	sext.w	a5,a5
    80004af8:	f8fb5ce3          	bge	s6,a5,80004a90 <filewrite+0x80>
    80004afc:	84de                	mv	s1,s7
    80004afe:	bf49                	j	80004a90 <filewrite+0x80>
      iunlock(f->ip);
    80004b00:	01893503          	ld	a0,24(s2)
    80004b04:	fffff097          	auipc	ra,0xfffff
    80004b08:	f2e080e7          	jalr	-210(ra) # 80003a32 <iunlock>
      end_op();
    80004b0c:	00000097          	auipc	ra,0x0
    80004b10:	8b4080e7          	jalr	-1868(ra) # 800043c0 <end_op>
      if(r < 0)
    80004b14:	fc04d8e3          	bgez	s1,80004ae4 <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    80004b18:	8552                	mv	a0,s4
    80004b1a:	033a1863          	bne	s4,s3,80004b4a <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004b1e:	60a6                	ld	ra,72(sp)
    80004b20:	6406                	ld	s0,64(sp)
    80004b22:	74e2                	ld	s1,56(sp)
    80004b24:	7942                	ld	s2,48(sp)
    80004b26:	79a2                	ld	s3,40(sp)
    80004b28:	7a02                	ld	s4,32(sp)
    80004b2a:	6ae2                	ld	s5,24(sp)
    80004b2c:	6b42                	ld	s6,16(sp)
    80004b2e:	6ba2                	ld	s7,8(sp)
    80004b30:	6c02                	ld	s8,0(sp)
    80004b32:	6161                	addi	sp,sp,80
    80004b34:	8082                	ret
        panic("short filewrite");
    80004b36:	00004517          	auipc	a0,0x4
    80004b3a:	be250513          	addi	a0,a0,-1054 # 80008718 <syscalls+0x260>
    80004b3e:	ffffc097          	auipc	ra,0xffffc
    80004b42:	a12080e7          	jalr	-1518(ra) # 80000550 <panic>
    int i = 0;
    80004b46:	4981                	li	s3,0
    80004b48:	bfc1                	j	80004b18 <filewrite+0x108>
    ret = (i == n ? n : -1);
    80004b4a:	557d                	li	a0,-1
    80004b4c:	bfc9                	j	80004b1e <filewrite+0x10e>
    panic("filewrite");
    80004b4e:	00004517          	auipc	a0,0x4
    80004b52:	bda50513          	addi	a0,a0,-1062 # 80008728 <syscalls+0x270>
    80004b56:	ffffc097          	auipc	ra,0xffffc
    80004b5a:	9fa080e7          	jalr	-1542(ra) # 80000550 <panic>
    return -1;
    80004b5e:	557d                	li	a0,-1
}
    80004b60:	8082                	ret
      return -1;
    80004b62:	557d                	li	a0,-1
    80004b64:	bf6d                	j	80004b1e <filewrite+0x10e>
    80004b66:	557d                	li	a0,-1
    80004b68:	bf5d                	j	80004b1e <filewrite+0x10e>

0000000080004b6a <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004b6a:	7179                	addi	sp,sp,-48
    80004b6c:	f406                	sd	ra,40(sp)
    80004b6e:	f022                	sd	s0,32(sp)
    80004b70:	ec26                	sd	s1,24(sp)
    80004b72:	e84a                	sd	s2,16(sp)
    80004b74:	e44e                	sd	s3,8(sp)
    80004b76:	e052                	sd	s4,0(sp)
    80004b78:	1800                	addi	s0,sp,48
    80004b7a:	84aa                	mv	s1,a0
    80004b7c:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004b7e:	0005b023          	sd	zero,0(a1)
    80004b82:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004b86:	00000097          	auipc	ra,0x0
    80004b8a:	bd2080e7          	jalr	-1070(ra) # 80004758 <filealloc>
    80004b8e:	e088                	sd	a0,0(s1)
    80004b90:	c551                	beqz	a0,80004c1c <pipealloc+0xb2>
    80004b92:	00000097          	auipc	ra,0x0
    80004b96:	bc6080e7          	jalr	-1082(ra) # 80004758 <filealloc>
    80004b9a:	00aa3023          	sd	a0,0(s4)
    80004b9e:	c92d                	beqz	a0,80004c10 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004ba0:	ffffc097          	auipc	ra,0xffffc
    80004ba4:	fd8080e7          	jalr	-40(ra) # 80000b78 <kalloc>
    80004ba8:	892a                	mv	s2,a0
    80004baa:	c125                	beqz	a0,80004c0a <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004bac:	4985                	li	s3,1
    80004bae:	23352423          	sw	s3,552(a0)
  pi->writeopen = 1;
    80004bb2:	23352623          	sw	s3,556(a0)
  pi->nwrite = 0;
    80004bb6:	22052223          	sw	zero,548(a0)
  pi->nread = 0;
    80004bba:	22052023          	sw	zero,544(a0)
  initlock(&pi->lock, "pipe");
    80004bbe:	00004597          	auipc	a1,0x4
    80004bc2:	b7a58593          	addi	a1,a1,-1158 # 80008738 <syscalls+0x280>
    80004bc6:	ffffc097          	auipc	ra,0xffffc
    80004bca:	2ae080e7          	jalr	686(ra) # 80000e74 <initlock>
  (*f0)->type = FD_PIPE;
    80004bce:	609c                	ld	a5,0(s1)
    80004bd0:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004bd4:	609c                	ld	a5,0(s1)
    80004bd6:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004bda:	609c                	ld	a5,0(s1)
    80004bdc:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004be0:	609c                	ld	a5,0(s1)
    80004be2:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004be6:	000a3783          	ld	a5,0(s4)
    80004bea:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004bee:	000a3783          	ld	a5,0(s4)
    80004bf2:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004bf6:	000a3783          	ld	a5,0(s4)
    80004bfa:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004bfe:	000a3783          	ld	a5,0(s4)
    80004c02:	0127b823          	sd	s2,16(a5)
  return 0;
    80004c06:	4501                	li	a0,0
    80004c08:	a025                	j	80004c30 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004c0a:	6088                	ld	a0,0(s1)
    80004c0c:	e501                	bnez	a0,80004c14 <pipealloc+0xaa>
    80004c0e:	a039                	j	80004c1c <pipealloc+0xb2>
    80004c10:	6088                	ld	a0,0(s1)
    80004c12:	c51d                	beqz	a0,80004c40 <pipealloc+0xd6>
    fileclose(*f0);
    80004c14:	00000097          	auipc	ra,0x0
    80004c18:	c00080e7          	jalr	-1024(ra) # 80004814 <fileclose>
  if(*f1)
    80004c1c:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004c20:	557d                	li	a0,-1
  if(*f1)
    80004c22:	c799                	beqz	a5,80004c30 <pipealloc+0xc6>
    fileclose(*f1);
    80004c24:	853e                	mv	a0,a5
    80004c26:	00000097          	auipc	ra,0x0
    80004c2a:	bee080e7          	jalr	-1042(ra) # 80004814 <fileclose>
  return -1;
    80004c2e:	557d                	li	a0,-1
}
    80004c30:	70a2                	ld	ra,40(sp)
    80004c32:	7402                	ld	s0,32(sp)
    80004c34:	64e2                	ld	s1,24(sp)
    80004c36:	6942                	ld	s2,16(sp)
    80004c38:	69a2                	ld	s3,8(sp)
    80004c3a:	6a02                	ld	s4,0(sp)
    80004c3c:	6145                	addi	sp,sp,48
    80004c3e:	8082                	ret
  return -1;
    80004c40:	557d                	li	a0,-1
    80004c42:	b7fd                	j	80004c30 <pipealloc+0xc6>

0000000080004c44 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004c44:	1101                	addi	sp,sp,-32
    80004c46:	ec06                	sd	ra,24(sp)
    80004c48:	e822                	sd	s0,16(sp)
    80004c4a:	e426                	sd	s1,8(sp)
    80004c4c:	e04a                	sd	s2,0(sp)
    80004c4e:	1000                	addi	s0,sp,32
    80004c50:	84aa                	mv	s1,a0
    80004c52:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004c54:	ffffc097          	auipc	ra,0xffffc
    80004c58:	0a4080e7          	jalr	164(ra) # 80000cf8 <acquire>
  if(writable){
    80004c5c:	04090263          	beqz	s2,80004ca0 <pipeclose+0x5c>
    pi->writeopen = 0;
    80004c60:	2204a623          	sw	zero,556(s1)
    wakeup(&pi->nread);
    80004c64:	22048513          	addi	a0,s1,544
    80004c68:	ffffe097          	auipc	ra,0xffffe
    80004c6c:	a6e080e7          	jalr	-1426(ra) # 800026d6 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004c70:	2284b783          	ld	a5,552(s1)
    80004c74:	ef9d                	bnez	a5,80004cb2 <pipeclose+0x6e>
    release(&pi->lock);
    80004c76:	8526                	mv	a0,s1
    80004c78:	ffffc097          	auipc	ra,0xffffc
    80004c7c:	150080e7          	jalr	336(ra) # 80000dc8 <release>
#ifdef LAB_LOCK
    freelock(&pi->lock);
    80004c80:	8526                	mv	a0,s1
    80004c82:	ffffc097          	auipc	ra,0xffffc
    80004c86:	18e080e7          	jalr	398(ra) # 80000e10 <freelock>
#endif    
    kfree((char*)pi);
    80004c8a:	8526                	mv	a0,s1
    80004c8c:	ffffc097          	auipc	ra,0xffffc
    80004c90:	da0080e7          	jalr	-608(ra) # 80000a2c <kfree>
  } else
    release(&pi->lock);
}
    80004c94:	60e2                	ld	ra,24(sp)
    80004c96:	6442                	ld	s0,16(sp)
    80004c98:	64a2                	ld	s1,8(sp)
    80004c9a:	6902                	ld	s2,0(sp)
    80004c9c:	6105                	addi	sp,sp,32
    80004c9e:	8082                	ret
    pi->readopen = 0;
    80004ca0:	2204a423          	sw	zero,552(s1)
    wakeup(&pi->nwrite);
    80004ca4:	22448513          	addi	a0,s1,548
    80004ca8:	ffffe097          	auipc	ra,0xffffe
    80004cac:	a2e080e7          	jalr	-1490(ra) # 800026d6 <wakeup>
    80004cb0:	b7c1                	j	80004c70 <pipeclose+0x2c>
    release(&pi->lock);
    80004cb2:	8526                	mv	a0,s1
    80004cb4:	ffffc097          	auipc	ra,0xffffc
    80004cb8:	114080e7          	jalr	276(ra) # 80000dc8 <release>
}
    80004cbc:	bfe1                	j	80004c94 <pipeclose+0x50>

0000000080004cbe <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004cbe:	7119                	addi	sp,sp,-128
    80004cc0:	fc86                	sd	ra,120(sp)
    80004cc2:	f8a2                	sd	s0,112(sp)
    80004cc4:	f4a6                	sd	s1,104(sp)
    80004cc6:	f0ca                	sd	s2,96(sp)
    80004cc8:	ecce                	sd	s3,88(sp)
    80004cca:	e8d2                	sd	s4,80(sp)
    80004ccc:	e4d6                	sd	s5,72(sp)
    80004cce:	e0da                	sd	s6,64(sp)
    80004cd0:	fc5e                	sd	s7,56(sp)
    80004cd2:	f862                	sd	s8,48(sp)
    80004cd4:	f466                	sd	s9,40(sp)
    80004cd6:	f06a                	sd	s10,32(sp)
    80004cd8:	ec6e                	sd	s11,24(sp)
    80004cda:	0100                	addi	s0,sp,128
    80004cdc:	84aa                	mv	s1,a0
    80004cde:	8cae                	mv	s9,a1
    80004ce0:	8b32                	mv	s6,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004ce2:	ffffd097          	auipc	ra,0xffffd
    80004ce6:	05e080e7          	jalr	94(ra) # 80001d40 <myproc>
    80004cea:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004cec:	8526                	mv	a0,s1
    80004cee:	ffffc097          	auipc	ra,0xffffc
    80004cf2:	00a080e7          	jalr	10(ra) # 80000cf8 <acquire>
  for(i = 0; i < n; i++){
    80004cf6:	0d605963          	blez	s6,80004dc8 <pipewrite+0x10a>
    80004cfa:	89a6                	mv	s3,s1
    80004cfc:	3b7d                	addiw	s6,s6,-1
    80004cfe:	1b02                	slli	s6,s6,0x20
    80004d00:	020b5b13          	srli	s6,s6,0x20
    80004d04:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004d06:	22048a93          	addi	s5,s1,544
      sleep(&pi->nwrite, &pi->lock);
    80004d0a:	22448a13          	addi	s4,s1,548
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004d0e:	5dfd                	li	s11,-1
    80004d10:	000b8d1b          	sext.w	s10,s7
    80004d14:	8c6a                	mv	s8,s10
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004d16:	2204a783          	lw	a5,544(s1)
    80004d1a:	2244a703          	lw	a4,548(s1)
    80004d1e:	2007879b          	addiw	a5,a5,512
    80004d22:	02f71b63          	bne	a4,a5,80004d58 <pipewrite+0x9a>
      if(pi->readopen == 0 || pr->killed){
    80004d26:	2284a783          	lw	a5,552(s1)
    80004d2a:	cbad                	beqz	a5,80004d9c <pipewrite+0xde>
    80004d2c:	03892783          	lw	a5,56(s2)
    80004d30:	e7b5                	bnez	a5,80004d9c <pipewrite+0xde>
      wakeup(&pi->nread);
    80004d32:	8556                	mv	a0,s5
    80004d34:	ffffe097          	auipc	ra,0xffffe
    80004d38:	9a2080e7          	jalr	-1630(ra) # 800026d6 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004d3c:	85ce                	mv	a1,s3
    80004d3e:	8552                	mv	a0,s4
    80004d40:	ffffe097          	auipc	ra,0xffffe
    80004d44:	810080e7          	jalr	-2032(ra) # 80002550 <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004d48:	2204a783          	lw	a5,544(s1)
    80004d4c:	2244a703          	lw	a4,548(s1)
    80004d50:	2007879b          	addiw	a5,a5,512
    80004d54:	fcf709e3          	beq	a4,a5,80004d26 <pipewrite+0x68>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004d58:	4685                	li	a3,1
    80004d5a:	019b8633          	add	a2,s7,s9
    80004d5e:	f8f40593          	addi	a1,s0,-113
    80004d62:	05893503          	ld	a0,88(s2)
    80004d66:	ffffd097          	auipc	ra,0xffffd
    80004d6a:	d5a080e7          	jalr	-678(ra) # 80001ac0 <copyin>
    80004d6e:	05b50e63          	beq	a0,s11,80004dca <pipewrite+0x10c>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004d72:	2244a783          	lw	a5,548(s1)
    80004d76:	0017871b          	addiw	a4,a5,1
    80004d7a:	22e4a223          	sw	a4,548(s1)
    80004d7e:	1ff7f793          	andi	a5,a5,511
    80004d82:	97a6                	add	a5,a5,s1
    80004d84:	f8f44703          	lbu	a4,-113(s0)
    80004d88:	02e78023          	sb	a4,32(a5)
  for(i = 0; i < n; i++){
    80004d8c:	001d0c1b          	addiw	s8,s10,1
    80004d90:	001b8793          	addi	a5,s7,1 # 1001 <_entry-0x7fffefff>
    80004d94:	036b8b63          	beq	s7,s6,80004dca <pipewrite+0x10c>
    80004d98:	8bbe                	mv	s7,a5
    80004d9a:	bf9d                	j	80004d10 <pipewrite+0x52>
        release(&pi->lock);
    80004d9c:	8526                	mv	a0,s1
    80004d9e:	ffffc097          	auipc	ra,0xffffc
    80004da2:	02a080e7          	jalr	42(ra) # 80000dc8 <release>
        return -1;
    80004da6:	5c7d                	li	s8,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);
  return i;
}
    80004da8:	8562                	mv	a0,s8
    80004daa:	70e6                	ld	ra,120(sp)
    80004dac:	7446                	ld	s0,112(sp)
    80004dae:	74a6                	ld	s1,104(sp)
    80004db0:	7906                	ld	s2,96(sp)
    80004db2:	69e6                	ld	s3,88(sp)
    80004db4:	6a46                	ld	s4,80(sp)
    80004db6:	6aa6                	ld	s5,72(sp)
    80004db8:	6b06                	ld	s6,64(sp)
    80004dba:	7be2                	ld	s7,56(sp)
    80004dbc:	7c42                	ld	s8,48(sp)
    80004dbe:	7ca2                	ld	s9,40(sp)
    80004dc0:	7d02                	ld	s10,32(sp)
    80004dc2:	6de2                	ld	s11,24(sp)
    80004dc4:	6109                	addi	sp,sp,128
    80004dc6:	8082                	ret
  for(i = 0; i < n; i++){
    80004dc8:	4c01                	li	s8,0
  wakeup(&pi->nread);
    80004dca:	22048513          	addi	a0,s1,544
    80004dce:	ffffe097          	auipc	ra,0xffffe
    80004dd2:	908080e7          	jalr	-1784(ra) # 800026d6 <wakeup>
  release(&pi->lock);
    80004dd6:	8526                	mv	a0,s1
    80004dd8:	ffffc097          	auipc	ra,0xffffc
    80004ddc:	ff0080e7          	jalr	-16(ra) # 80000dc8 <release>
  return i;
    80004de0:	b7e1                	j	80004da8 <pipewrite+0xea>

0000000080004de2 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004de2:	715d                	addi	sp,sp,-80
    80004de4:	e486                	sd	ra,72(sp)
    80004de6:	e0a2                	sd	s0,64(sp)
    80004de8:	fc26                	sd	s1,56(sp)
    80004dea:	f84a                	sd	s2,48(sp)
    80004dec:	f44e                	sd	s3,40(sp)
    80004dee:	f052                	sd	s4,32(sp)
    80004df0:	ec56                	sd	s5,24(sp)
    80004df2:	e85a                	sd	s6,16(sp)
    80004df4:	0880                	addi	s0,sp,80
    80004df6:	84aa                	mv	s1,a0
    80004df8:	892e                	mv	s2,a1
    80004dfa:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004dfc:	ffffd097          	auipc	ra,0xffffd
    80004e00:	f44080e7          	jalr	-188(ra) # 80001d40 <myproc>
    80004e04:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004e06:	8b26                	mv	s6,s1
    80004e08:	8526                	mv	a0,s1
    80004e0a:	ffffc097          	auipc	ra,0xffffc
    80004e0e:	eee080e7          	jalr	-274(ra) # 80000cf8 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e12:	2204a703          	lw	a4,544(s1)
    80004e16:	2244a783          	lw	a5,548(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004e1a:	22048993          	addi	s3,s1,544
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e1e:	02f71463          	bne	a4,a5,80004e46 <piperead+0x64>
    80004e22:	22c4a783          	lw	a5,556(s1)
    80004e26:	c385                	beqz	a5,80004e46 <piperead+0x64>
    if(pr->killed){
    80004e28:	038a2783          	lw	a5,56(s4)
    80004e2c:	ebc1                	bnez	a5,80004ebc <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004e2e:	85da                	mv	a1,s6
    80004e30:	854e                	mv	a0,s3
    80004e32:	ffffd097          	auipc	ra,0xffffd
    80004e36:	71e080e7          	jalr	1822(ra) # 80002550 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e3a:	2204a703          	lw	a4,544(s1)
    80004e3e:	2244a783          	lw	a5,548(s1)
    80004e42:	fef700e3          	beq	a4,a5,80004e22 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e46:	09505263          	blez	s5,80004eca <piperead+0xe8>
    80004e4a:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e4c:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004e4e:	2204a783          	lw	a5,544(s1)
    80004e52:	2244a703          	lw	a4,548(s1)
    80004e56:	02f70d63          	beq	a4,a5,80004e90 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004e5a:	0017871b          	addiw	a4,a5,1
    80004e5e:	22e4a023          	sw	a4,544(s1)
    80004e62:	1ff7f793          	andi	a5,a5,511
    80004e66:	97a6                	add	a5,a5,s1
    80004e68:	0207c783          	lbu	a5,32(a5)
    80004e6c:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e70:	4685                	li	a3,1
    80004e72:	fbf40613          	addi	a2,s0,-65
    80004e76:	85ca                	mv	a1,s2
    80004e78:	058a3503          	ld	a0,88(s4)
    80004e7c:	ffffd097          	auipc	ra,0xffffd
    80004e80:	bb8080e7          	jalr	-1096(ra) # 80001a34 <copyout>
    80004e84:	01650663          	beq	a0,s6,80004e90 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e88:	2985                	addiw	s3,s3,1
    80004e8a:	0905                	addi	s2,s2,1
    80004e8c:	fd3a91e3          	bne	s5,s3,80004e4e <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004e90:	22448513          	addi	a0,s1,548
    80004e94:	ffffe097          	auipc	ra,0xffffe
    80004e98:	842080e7          	jalr	-1982(ra) # 800026d6 <wakeup>
  release(&pi->lock);
    80004e9c:	8526                	mv	a0,s1
    80004e9e:	ffffc097          	auipc	ra,0xffffc
    80004ea2:	f2a080e7          	jalr	-214(ra) # 80000dc8 <release>
  return i;
}
    80004ea6:	854e                	mv	a0,s3
    80004ea8:	60a6                	ld	ra,72(sp)
    80004eaa:	6406                	ld	s0,64(sp)
    80004eac:	74e2                	ld	s1,56(sp)
    80004eae:	7942                	ld	s2,48(sp)
    80004eb0:	79a2                	ld	s3,40(sp)
    80004eb2:	7a02                	ld	s4,32(sp)
    80004eb4:	6ae2                	ld	s5,24(sp)
    80004eb6:	6b42                	ld	s6,16(sp)
    80004eb8:	6161                	addi	sp,sp,80
    80004eba:	8082                	ret
      release(&pi->lock);
    80004ebc:	8526                	mv	a0,s1
    80004ebe:	ffffc097          	auipc	ra,0xffffc
    80004ec2:	f0a080e7          	jalr	-246(ra) # 80000dc8 <release>
      return -1;
    80004ec6:	59fd                	li	s3,-1
    80004ec8:	bff9                	j	80004ea6 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004eca:	4981                	li	s3,0
    80004ecc:	b7d1                	j	80004e90 <piperead+0xae>

0000000080004ece <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004ece:	df010113          	addi	sp,sp,-528
    80004ed2:	20113423          	sd	ra,520(sp)
    80004ed6:	20813023          	sd	s0,512(sp)
    80004eda:	ffa6                	sd	s1,504(sp)
    80004edc:	fbca                	sd	s2,496(sp)
    80004ede:	f7ce                	sd	s3,488(sp)
    80004ee0:	f3d2                	sd	s4,480(sp)
    80004ee2:	efd6                	sd	s5,472(sp)
    80004ee4:	ebda                	sd	s6,464(sp)
    80004ee6:	e7de                	sd	s7,456(sp)
    80004ee8:	e3e2                	sd	s8,448(sp)
    80004eea:	ff66                	sd	s9,440(sp)
    80004eec:	fb6a                	sd	s10,432(sp)
    80004eee:	f76e                	sd	s11,424(sp)
    80004ef0:	0c00                	addi	s0,sp,528
    80004ef2:	84aa                	mv	s1,a0
    80004ef4:	dea43c23          	sd	a0,-520(s0)
    80004ef8:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004efc:	ffffd097          	auipc	ra,0xffffd
    80004f00:	e44080e7          	jalr	-444(ra) # 80001d40 <myproc>
    80004f04:	892a                	mv	s2,a0

  begin_op();
    80004f06:	fffff097          	auipc	ra,0xfffff
    80004f0a:	43a080e7          	jalr	1082(ra) # 80004340 <begin_op>

  if((ip = namei(path)) == 0){
    80004f0e:	8526                	mv	a0,s1
    80004f10:	fffff097          	auipc	ra,0xfffff
    80004f14:	214080e7          	jalr	532(ra) # 80004124 <namei>
    80004f18:	c92d                	beqz	a0,80004f8a <exec+0xbc>
    80004f1a:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004f1c:	fffff097          	auipc	ra,0xfffff
    80004f20:	a54080e7          	jalr	-1452(ra) # 80003970 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004f24:	04000713          	li	a4,64
    80004f28:	4681                	li	a3,0
    80004f2a:	e4840613          	addi	a2,s0,-440
    80004f2e:	4581                	li	a1,0
    80004f30:	8526                	mv	a0,s1
    80004f32:	fffff097          	auipc	ra,0xfffff
    80004f36:	cf2080e7          	jalr	-782(ra) # 80003c24 <readi>
    80004f3a:	04000793          	li	a5,64
    80004f3e:	00f51a63          	bne	a0,a5,80004f52 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004f42:	e4842703          	lw	a4,-440(s0)
    80004f46:	464c47b7          	lui	a5,0x464c4
    80004f4a:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004f4e:	04f70463          	beq	a4,a5,80004f96 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004f52:	8526                	mv	a0,s1
    80004f54:	fffff097          	auipc	ra,0xfffff
    80004f58:	c7e080e7          	jalr	-898(ra) # 80003bd2 <iunlockput>
    end_op();
    80004f5c:	fffff097          	auipc	ra,0xfffff
    80004f60:	464080e7          	jalr	1124(ra) # 800043c0 <end_op>
  }
  return -1;
    80004f64:	557d                	li	a0,-1
}
    80004f66:	20813083          	ld	ra,520(sp)
    80004f6a:	20013403          	ld	s0,512(sp)
    80004f6e:	74fe                	ld	s1,504(sp)
    80004f70:	795e                	ld	s2,496(sp)
    80004f72:	79be                	ld	s3,488(sp)
    80004f74:	7a1e                	ld	s4,480(sp)
    80004f76:	6afe                	ld	s5,472(sp)
    80004f78:	6b5e                	ld	s6,464(sp)
    80004f7a:	6bbe                	ld	s7,456(sp)
    80004f7c:	6c1e                	ld	s8,448(sp)
    80004f7e:	7cfa                	ld	s9,440(sp)
    80004f80:	7d5a                	ld	s10,432(sp)
    80004f82:	7dba                	ld	s11,424(sp)
    80004f84:	21010113          	addi	sp,sp,528
    80004f88:	8082                	ret
    end_op();
    80004f8a:	fffff097          	auipc	ra,0xfffff
    80004f8e:	436080e7          	jalr	1078(ra) # 800043c0 <end_op>
    return -1;
    80004f92:	557d                	li	a0,-1
    80004f94:	bfc9                	j	80004f66 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004f96:	854a                	mv	a0,s2
    80004f98:	ffffd097          	auipc	ra,0xffffd
    80004f9c:	e6c080e7          	jalr	-404(ra) # 80001e04 <proc_pagetable>
    80004fa0:	8baa                	mv	s7,a0
    80004fa2:	d945                	beqz	a0,80004f52 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004fa4:	e6842983          	lw	s3,-408(s0)
    80004fa8:	e8045783          	lhu	a5,-384(s0)
    80004fac:	c7ad                	beqz	a5,80005016 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004fae:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004fb0:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004fb2:	6c85                	lui	s9,0x1
    80004fb4:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004fb8:	def43823          	sd	a5,-528(s0)
    80004fbc:	a42d                	j	800051e6 <exec+0x318>
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004fbe:	00003517          	auipc	a0,0x3
    80004fc2:	78250513          	addi	a0,a0,1922 # 80008740 <syscalls+0x288>
    80004fc6:	ffffb097          	auipc	ra,0xffffb
    80004fca:	58a080e7          	jalr	1418(ra) # 80000550 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004fce:	8756                	mv	a4,s5
    80004fd0:	012d86bb          	addw	a3,s11,s2
    80004fd4:	4581                	li	a1,0
    80004fd6:	8526                	mv	a0,s1
    80004fd8:	fffff097          	auipc	ra,0xfffff
    80004fdc:	c4c080e7          	jalr	-948(ra) # 80003c24 <readi>
    80004fe0:	2501                	sext.w	a0,a0
    80004fe2:	1aaa9963          	bne	s5,a0,80005194 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004fe6:	6785                	lui	a5,0x1
    80004fe8:	0127893b          	addw	s2,a5,s2
    80004fec:	77fd                	lui	a5,0xfffff
    80004fee:	01478a3b          	addw	s4,a5,s4
    80004ff2:	1f897163          	bgeu	s2,s8,800051d4 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004ff6:	02091593          	slli	a1,s2,0x20
    80004ffa:	9181                	srli	a1,a1,0x20
    80004ffc:	95ea                	add	a1,a1,s10
    80004ffe:	855e                	mv	a0,s7
    80005000:	ffffc097          	auipc	ra,0xffffc
    80005004:	472080e7          	jalr	1138(ra) # 80001472 <walkaddr>
    80005008:	862a                	mv	a2,a0
    if(pa == 0)
    8000500a:	d955                	beqz	a0,80004fbe <exec+0xf0>
      n = PGSIZE;
    8000500c:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    8000500e:	fd9a70e3          	bgeu	s4,s9,80004fce <exec+0x100>
      n = sz - i;
    80005012:	8ad2                	mv	s5,s4
    80005014:	bf6d                	j	80004fce <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80005016:	4901                	li	s2,0
  iunlockput(ip);
    80005018:	8526                	mv	a0,s1
    8000501a:	fffff097          	auipc	ra,0xfffff
    8000501e:	bb8080e7          	jalr	-1096(ra) # 80003bd2 <iunlockput>
  end_op();
    80005022:	fffff097          	auipc	ra,0xfffff
    80005026:	39e080e7          	jalr	926(ra) # 800043c0 <end_op>
  p = myproc();
    8000502a:	ffffd097          	auipc	ra,0xffffd
    8000502e:	d16080e7          	jalr	-746(ra) # 80001d40 <myproc>
    80005032:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80005034:	05053d03          	ld	s10,80(a0)
  sz = PGROUNDUP(sz);
    80005038:	6785                	lui	a5,0x1
    8000503a:	17fd                	addi	a5,a5,-1
    8000503c:	993e                	add	s2,s2,a5
    8000503e:	757d                	lui	a0,0xfffff
    80005040:	00a977b3          	and	a5,s2,a0
    80005044:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005048:	6609                	lui	a2,0x2
    8000504a:	963e                	add	a2,a2,a5
    8000504c:	85be                	mv	a1,a5
    8000504e:	855e                	mv	a0,s7
    80005050:	ffffc097          	auipc	ra,0xffffc
    80005054:	794080e7          	jalr	1940(ra) # 800017e4 <uvmalloc>
    80005058:	8b2a                	mv	s6,a0
  ip = 0;
    8000505a:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    8000505c:	12050c63          	beqz	a0,80005194 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005060:	75f9                	lui	a1,0xffffe
    80005062:	95aa                	add	a1,a1,a0
    80005064:	855e                	mv	a0,s7
    80005066:	ffffd097          	auipc	ra,0xffffd
    8000506a:	99c080e7          	jalr	-1636(ra) # 80001a02 <uvmclear>
  stackbase = sp - PGSIZE;
    8000506e:	7c7d                	lui	s8,0xfffff
    80005070:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80005072:	e0043783          	ld	a5,-512(s0)
    80005076:	6388                	ld	a0,0(a5)
    80005078:	c535                	beqz	a0,800050e4 <exec+0x216>
    8000507a:	e8840993          	addi	s3,s0,-376
    8000507e:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80005082:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80005084:	ffffc097          	auipc	ra,0xffffc
    80005088:	1dc080e7          	jalr	476(ra) # 80001260 <strlen>
    8000508c:	2505                	addiw	a0,a0,1
    8000508e:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005092:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005096:	13896363          	bltu	s2,s8,800051bc <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8000509a:	e0043d83          	ld	s11,-512(s0)
    8000509e:	000dba03          	ld	s4,0(s11)
    800050a2:	8552                	mv	a0,s4
    800050a4:	ffffc097          	auipc	ra,0xffffc
    800050a8:	1bc080e7          	jalr	444(ra) # 80001260 <strlen>
    800050ac:	0015069b          	addiw	a3,a0,1
    800050b0:	8652                	mv	a2,s4
    800050b2:	85ca                	mv	a1,s2
    800050b4:	855e                	mv	a0,s7
    800050b6:	ffffd097          	auipc	ra,0xffffd
    800050ba:	97e080e7          	jalr	-1666(ra) # 80001a34 <copyout>
    800050be:	10054363          	bltz	a0,800051c4 <exec+0x2f6>
    ustack[argc] = sp;
    800050c2:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800050c6:	0485                	addi	s1,s1,1
    800050c8:	008d8793          	addi	a5,s11,8
    800050cc:	e0f43023          	sd	a5,-512(s0)
    800050d0:	008db503          	ld	a0,8(s11)
    800050d4:	c911                	beqz	a0,800050e8 <exec+0x21a>
    if(argc >= MAXARG)
    800050d6:	09a1                	addi	s3,s3,8
    800050d8:	fb3c96e3          	bne	s9,s3,80005084 <exec+0x1b6>
  sz = sz1;
    800050dc:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800050e0:	4481                	li	s1,0
    800050e2:	a84d                	j	80005194 <exec+0x2c6>
  sp = sz;
    800050e4:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    800050e6:	4481                	li	s1,0
  ustack[argc] = 0;
    800050e8:	00349793          	slli	a5,s1,0x3
    800050ec:	f9040713          	addi	a4,s0,-112
    800050f0:	97ba                	add	a5,a5,a4
    800050f2:	ee07bc23          	sd	zero,-264(a5) # ef8 <_entry-0x7ffff108>
  sp -= (argc+1) * sizeof(uint64);
    800050f6:	00148693          	addi	a3,s1,1
    800050fa:	068e                	slli	a3,a3,0x3
    800050fc:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005100:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005104:	01897663          	bgeu	s2,s8,80005110 <exec+0x242>
  sz = sz1;
    80005108:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000510c:	4481                	li	s1,0
    8000510e:	a059                	j	80005194 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005110:	e8840613          	addi	a2,s0,-376
    80005114:	85ca                	mv	a1,s2
    80005116:	855e                	mv	a0,s7
    80005118:	ffffd097          	auipc	ra,0xffffd
    8000511c:	91c080e7          	jalr	-1764(ra) # 80001a34 <copyout>
    80005120:	0a054663          	bltz	a0,800051cc <exec+0x2fe>
  p->trapframe->a1 = sp;
    80005124:	060ab783          	ld	a5,96(s5)
    80005128:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000512c:	df843783          	ld	a5,-520(s0)
    80005130:	0007c703          	lbu	a4,0(a5)
    80005134:	cf11                	beqz	a4,80005150 <exec+0x282>
    80005136:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005138:	02f00693          	li	a3,47
    8000513c:	a029                	j	80005146 <exec+0x278>
  for(last=s=path; *s; s++)
    8000513e:	0785                	addi	a5,a5,1
    80005140:	fff7c703          	lbu	a4,-1(a5)
    80005144:	c711                	beqz	a4,80005150 <exec+0x282>
    if(*s == '/')
    80005146:	fed71ce3          	bne	a4,a3,8000513e <exec+0x270>
      last = s+1;
    8000514a:	def43c23          	sd	a5,-520(s0)
    8000514e:	bfc5                	j	8000513e <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80005150:	4641                	li	a2,16
    80005152:	df843583          	ld	a1,-520(s0)
    80005156:	160a8513          	addi	a0,s5,352
    8000515a:	ffffc097          	auipc	ra,0xffffc
    8000515e:	0d4080e7          	jalr	212(ra) # 8000122e <safestrcpy>
  oldpagetable = p->pagetable;
    80005162:	058ab503          	ld	a0,88(s5)
  p->pagetable = pagetable;
    80005166:	057abc23          	sd	s7,88(s5)
  p->sz = sz;
    8000516a:	056ab823          	sd	s6,80(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000516e:	060ab783          	ld	a5,96(s5)
    80005172:	e6043703          	ld	a4,-416(s0)
    80005176:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005178:	060ab783          	ld	a5,96(s5)
    8000517c:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005180:	85ea                	mv	a1,s10
    80005182:	ffffd097          	auipc	ra,0xffffd
    80005186:	d1e080e7          	jalr	-738(ra) # 80001ea0 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000518a:	0004851b          	sext.w	a0,s1
    8000518e:	bbe1                	j	80004f66 <exec+0x98>
    80005190:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005194:	e0843583          	ld	a1,-504(s0)
    80005198:	855e                	mv	a0,s7
    8000519a:	ffffd097          	auipc	ra,0xffffd
    8000519e:	d06080e7          	jalr	-762(ra) # 80001ea0 <proc_freepagetable>
  if(ip){
    800051a2:	da0498e3          	bnez	s1,80004f52 <exec+0x84>
  return -1;
    800051a6:	557d                	li	a0,-1
    800051a8:	bb7d                	j	80004f66 <exec+0x98>
    800051aa:	e1243423          	sd	s2,-504(s0)
    800051ae:	b7dd                	j	80005194 <exec+0x2c6>
    800051b0:	e1243423          	sd	s2,-504(s0)
    800051b4:	b7c5                	j	80005194 <exec+0x2c6>
    800051b6:	e1243423          	sd	s2,-504(s0)
    800051ba:	bfe9                	j	80005194 <exec+0x2c6>
  sz = sz1;
    800051bc:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800051c0:	4481                	li	s1,0
    800051c2:	bfc9                	j	80005194 <exec+0x2c6>
  sz = sz1;
    800051c4:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800051c8:	4481                	li	s1,0
    800051ca:	b7e9                	j	80005194 <exec+0x2c6>
  sz = sz1;
    800051cc:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800051d0:	4481                	li	s1,0
    800051d2:	b7c9                	j	80005194 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800051d4:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800051d8:	2b05                	addiw	s6,s6,1
    800051da:	0389899b          	addiw	s3,s3,56
    800051de:	e8045783          	lhu	a5,-384(s0)
    800051e2:	e2fb5be3          	bge	s6,a5,80005018 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800051e6:	2981                	sext.w	s3,s3
    800051e8:	03800713          	li	a4,56
    800051ec:	86ce                	mv	a3,s3
    800051ee:	e1040613          	addi	a2,s0,-496
    800051f2:	4581                	li	a1,0
    800051f4:	8526                	mv	a0,s1
    800051f6:	fffff097          	auipc	ra,0xfffff
    800051fa:	a2e080e7          	jalr	-1490(ra) # 80003c24 <readi>
    800051fe:	03800793          	li	a5,56
    80005202:	f8f517e3          	bne	a0,a5,80005190 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80005206:	e1042783          	lw	a5,-496(s0)
    8000520a:	4705                	li	a4,1
    8000520c:	fce796e3          	bne	a5,a4,800051d8 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80005210:	e3843603          	ld	a2,-456(s0)
    80005214:	e3043783          	ld	a5,-464(s0)
    80005218:	f8f669e3          	bltu	a2,a5,800051aa <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000521c:	e2043783          	ld	a5,-480(s0)
    80005220:	963e                	add	a2,a2,a5
    80005222:	f8f667e3          	bltu	a2,a5,800051b0 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005226:	85ca                	mv	a1,s2
    80005228:	855e                	mv	a0,s7
    8000522a:	ffffc097          	auipc	ra,0xffffc
    8000522e:	5ba080e7          	jalr	1466(ra) # 800017e4 <uvmalloc>
    80005232:	e0a43423          	sd	a0,-504(s0)
    80005236:	d141                	beqz	a0,800051b6 <exec+0x2e8>
    if(ph.vaddr % PGSIZE != 0)
    80005238:	e2043d03          	ld	s10,-480(s0)
    8000523c:	df043783          	ld	a5,-528(s0)
    80005240:	00fd77b3          	and	a5,s10,a5
    80005244:	fba1                	bnez	a5,80005194 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005246:	e1842d83          	lw	s11,-488(s0)
    8000524a:	e3042c03          	lw	s8,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000524e:	f80c03e3          	beqz	s8,800051d4 <exec+0x306>
    80005252:	8a62                	mv	s4,s8
    80005254:	4901                	li	s2,0
    80005256:	b345                	j	80004ff6 <exec+0x128>

0000000080005258 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005258:	7179                	addi	sp,sp,-48
    8000525a:	f406                	sd	ra,40(sp)
    8000525c:	f022                	sd	s0,32(sp)
    8000525e:	ec26                	sd	s1,24(sp)
    80005260:	e84a                	sd	s2,16(sp)
    80005262:	1800                	addi	s0,sp,48
    80005264:	892e                	mv	s2,a1
    80005266:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005268:	fdc40593          	addi	a1,s0,-36
    8000526c:	ffffe097          	auipc	ra,0xffffe
    80005270:	b92080e7          	jalr	-1134(ra) # 80002dfe <argint>
    80005274:	04054063          	bltz	a0,800052b4 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005278:	fdc42703          	lw	a4,-36(s0)
    8000527c:	47bd                	li	a5,15
    8000527e:	02e7ed63          	bltu	a5,a4,800052b8 <argfd+0x60>
    80005282:	ffffd097          	auipc	ra,0xffffd
    80005286:	abe080e7          	jalr	-1346(ra) # 80001d40 <myproc>
    8000528a:	fdc42703          	lw	a4,-36(s0)
    8000528e:	01a70793          	addi	a5,a4,26
    80005292:	078e                	slli	a5,a5,0x3
    80005294:	953e                	add	a0,a0,a5
    80005296:	651c                	ld	a5,8(a0)
    80005298:	c395                	beqz	a5,800052bc <argfd+0x64>
    return -1;
  if(pfd)
    8000529a:	00090463          	beqz	s2,800052a2 <argfd+0x4a>
    *pfd = fd;
    8000529e:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800052a2:	4501                	li	a0,0
  if(pf)
    800052a4:	c091                	beqz	s1,800052a8 <argfd+0x50>
    *pf = f;
    800052a6:	e09c                	sd	a5,0(s1)
}
    800052a8:	70a2                	ld	ra,40(sp)
    800052aa:	7402                	ld	s0,32(sp)
    800052ac:	64e2                	ld	s1,24(sp)
    800052ae:	6942                	ld	s2,16(sp)
    800052b0:	6145                	addi	sp,sp,48
    800052b2:	8082                	ret
    return -1;
    800052b4:	557d                	li	a0,-1
    800052b6:	bfcd                	j	800052a8 <argfd+0x50>
    return -1;
    800052b8:	557d                	li	a0,-1
    800052ba:	b7fd                	j	800052a8 <argfd+0x50>
    800052bc:	557d                	li	a0,-1
    800052be:	b7ed                	j	800052a8 <argfd+0x50>

00000000800052c0 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800052c0:	1101                	addi	sp,sp,-32
    800052c2:	ec06                	sd	ra,24(sp)
    800052c4:	e822                	sd	s0,16(sp)
    800052c6:	e426                	sd	s1,8(sp)
    800052c8:	1000                	addi	s0,sp,32
    800052ca:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800052cc:	ffffd097          	auipc	ra,0xffffd
    800052d0:	a74080e7          	jalr	-1420(ra) # 80001d40 <myproc>
    800052d4:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800052d6:	0d850793          	addi	a5,a0,216 # fffffffffffff0d8 <end+0xffffffff7ffd70b0>
    800052da:	4501                	li	a0,0
    800052dc:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800052de:	6398                	ld	a4,0(a5)
    800052e0:	cb19                	beqz	a4,800052f6 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800052e2:	2505                	addiw	a0,a0,1
    800052e4:	07a1                	addi	a5,a5,8
    800052e6:	fed51ce3          	bne	a0,a3,800052de <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800052ea:	557d                	li	a0,-1
}
    800052ec:	60e2                	ld	ra,24(sp)
    800052ee:	6442                	ld	s0,16(sp)
    800052f0:	64a2                	ld	s1,8(sp)
    800052f2:	6105                	addi	sp,sp,32
    800052f4:	8082                	ret
      p->ofile[fd] = f;
    800052f6:	01a50793          	addi	a5,a0,26
    800052fa:	078e                	slli	a5,a5,0x3
    800052fc:	963e                	add	a2,a2,a5
    800052fe:	e604                	sd	s1,8(a2)
      return fd;
    80005300:	b7f5                	j	800052ec <fdalloc+0x2c>

0000000080005302 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005302:	715d                	addi	sp,sp,-80
    80005304:	e486                	sd	ra,72(sp)
    80005306:	e0a2                	sd	s0,64(sp)
    80005308:	fc26                	sd	s1,56(sp)
    8000530a:	f84a                	sd	s2,48(sp)
    8000530c:	f44e                	sd	s3,40(sp)
    8000530e:	f052                	sd	s4,32(sp)
    80005310:	ec56                	sd	s5,24(sp)
    80005312:	0880                	addi	s0,sp,80
    80005314:	89ae                	mv	s3,a1
    80005316:	8ab2                	mv	s5,a2
    80005318:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000531a:	fb040593          	addi	a1,s0,-80
    8000531e:	fffff097          	auipc	ra,0xfffff
    80005322:	e24080e7          	jalr	-476(ra) # 80004142 <nameiparent>
    80005326:	892a                	mv	s2,a0
    80005328:	12050f63          	beqz	a0,80005466 <create+0x164>
    return 0;

  ilock(dp);
    8000532c:	ffffe097          	auipc	ra,0xffffe
    80005330:	644080e7          	jalr	1604(ra) # 80003970 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005334:	4601                	li	a2,0
    80005336:	fb040593          	addi	a1,s0,-80
    8000533a:	854a                	mv	a0,s2
    8000533c:	fffff097          	auipc	ra,0xfffff
    80005340:	b16080e7          	jalr	-1258(ra) # 80003e52 <dirlookup>
    80005344:	84aa                	mv	s1,a0
    80005346:	c921                	beqz	a0,80005396 <create+0x94>
    iunlockput(dp);
    80005348:	854a                	mv	a0,s2
    8000534a:	fffff097          	auipc	ra,0xfffff
    8000534e:	888080e7          	jalr	-1912(ra) # 80003bd2 <iunlockput>
    ilock(ip);
    80005352:	8526                	mv	a0,s1
    80005354:	ffffe097          	auipc	ra,0xffffe
    80005358:	61c080e7          	jalr	1564(ra) # 80003970 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000535c:	2981                	sext.w	s3,s3
    8000535e:	4789                	li	a5,2
    80005360:	02f99463          	bne	s3,a5,80005388 <create+0x86>
    80005364:	04c4d783          	lhu	a5,76(s1)
    80005368:	37f9                	addiw	a5,a5,-2
    8000536a:	17c2                	slli	a5,a5,0x30
    8000536c:	93c1                	srli	a5,a5,0x30
    8000536e:	4705                	li	a4,1
    80005370:	00f76c63          	bltu	a4,a5,80005388 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005374:	8526                	mv	a0,s1
    80005376:	60a6                	ld	ra,72(sp)
    80005378:	6406                	ld	s0,64(sp)
    8000537a:	74e2                	ld	s1,56(sp)
    8000537c:	7942                	ld	s2,48(sp)
    8000537e:	79a2                	ld	s3,40(sp)
    80005380:	7a02                	ld	s4,32(sp)
    80005382:	6ae2                	ld	s5,24(sp)
    80005384:	6161                	addi	sp,sp,80
    80005386:	8082                	ret
    iunlockput(ip);
    80005388:	8526                	mv	a0,s1
    8000538a:	fffff097          	auipc	ra,0xfffff
    8000538e:	848080e7          	jalr	-1976(ra) # 80003bd2 <iunlockput>
    return 0;
    80005392:	4481                	li	s1,0
    80005394:	b7c5                	j	80005374 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005396:	85ce                	mv	a1,s3
    80005398:	00092503          	lw	a0,0(s2)
    8000539c:	ffffe097          	auipc	ra,0xffffe
    800053a0:	43c080e7          	jalr	1084(ra) # 800037d8 <ialloc>
    800053a4:	84aa                	mv	s1,a0
    800053a6:	c529                	beqz	a0,800053f0 <create+0xee>
  ilock(ip);
    800053a8:	ffffe097          	auipc	ra,0xffffe
    800053ac:	5c8080e7          	jalr	1480(ra) # 80003970 <ilock>
  ip->major = major;
    800053b0:	05549723          	sh	s5,78(s1)
  ip->minor = minor;
    800053b4:	05449823          	sh	s4,80(s1)
  ip->nlink = 1;
    800053b8:	4785                	li	a5,1
    800053ba:	04f49923          	sh	a5,82(s1)
  iupdate(ip);
    800053be:	8526                	mv	a0,s1
    800053c0:	ffffe097          	auipc	ra,0xffffe
    800053c4:	4e6080e7          	jalr	1254(ra) # 800038a6 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800053c8:	2981                	sext.w	s3,s3
    800053ca:	4785                	li	a5,1
    800053cc:	02f98a63          	beq	s3,a5,80005400 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800053d0:	40d0                	lw	a2,4(s1)
    800053d2:	fb040593          	addi	a1,s0,-80
    800053d6:	854a                	mv	a0,s2
    800053d8:	fffff097          	auipc	ra,0xfffff
    800053dc:	c8a080e7          	jalr	-886(ra) # 80004062 <dirlink>
    800053e0:	06054b63          	bltz	a0,80005456 <create+0x154>
  iunlockput(dp);
    800053e4:	854a                	mv	a0,s2
    800053e6:	ffffe097          	auipc	ra,0xffffe
    800053ea:	7ec080e7          	jalr	2028(ra) # 80003bd2 <iunlockput>
  return ip;
    800053ee:	b759                	j	80005374 <create+0x72>
    panic("create: ialloc");
    800053f0:	00003517          	auipc	a0,0x3
    800053f4:	37050513          	addi	a0,a0,880 # 80008760 <syscalls+0x2a8>
    800053f8:	ffffb097          	auipc	ra,0xffffb
    800053fc:	158080e7          	jalr	344(ra) # 80000550 <panic>
    dp->nlink++;  // for ".."
    80005400:	05295783          	lhu	a5,82(s2)
    80005404:	2785                	addiw	a5,a5,1
    80005406:	04f91923          	sh	a5,82(s2)
    iupdate(dp);
    8000540a:	854a                	mv	a0,s2
    8000540c:	ffffe097          	auipc	ra,0xffffe
    80005410:	49a080e7          	jalr	1178(ra) # 800038a6 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005414:	40d0                	lw	a2,4(s1)
    80005416:	00003597          	auipc	a1,0x3
    8000541a:	35a58593          	addi	a1,a1,858 # 80008770 <syscalls+0x2b8>
    8000541e:	8526                	mv	a0,s1
    80005420:	fffff097          	auipc	ra,0xfffff
    80005424:	c42080e7          	jalr	-958(ra) # 80004062 <dirlink>
    80005428:	00054f63          	bltz	a0,80005446 <create+0x144>
    8000542c:	00492603          	lw	a2,4(s2)
    80005430:	00003597          	auipc	a1,0x3
    80005434:	34858593          	addi	a1,a1,840 # 80008778 <syscalls+0x2c0>
    80005438:	8526                	mv	a0,s1
    8000543a:	fffff097          	auipc	ra,0xfffff
    8000543e:	c28080e7          	jalr	-984(ra) # 80004062 <dirlink>
    80005442:	f80557e3          	bgez	a0,800053d0 <create+0xce>
      panic("create dots");
    80005446:	00003517          	auipc	a0,0x3
    8000544a:	33a50513          	addi	a0,a0,826 # 80008780 <syscalls+0x2c8>
    8000544e:	ffffb097          	auipc	ra,0xffffb
    80005452:	102080e7          	jalr	258(ra) # 80000550 <panic>
    panic("create: dirlink");
    80005456:	00003517          	auipc	a0,0x3
    8000545a:	33a50513          	addi	a0,a0,826 # 80008790 <syscalls+0x2d8>
    8000545e:	ffffb097          	auipc	ra,0xffffb
    80005462:	0f2080e7          	jalr	242(ra) # 80000550 <panic>
    return 0;
    80005466:	84aa                	mv	s1,a0
    80005468:	b731                	j	80005374 <create+0x72>

000000008000546a <sys_dup>:
{
    8000546a:	7179                	addi	sp,sp,-48
    8000546c:	f406                	sd	ra,40(sp)
    8000546e:	f022                	sd	s0,32(sp)
    80005470:	ec26                	sd	s1,24(sp)
    80005472:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005474:	fd840613          	addi	a2,s0,-40
    80005478:	4581                	li	a1,0
    8000547a:	4501                	li	a0,0
    8000547c:	00000097          	auipc	ra,0x0
    80005480:	ddc080e7          	jalr	-548(ra) # 80005258 <argfd>
    return -1;
    80005484:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005486:	02054363          	bltz	a0,800054ac <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000548a:	fd843503          	ld	a0,-40(s0)
    8000548e:	00000097          	auipc	ra,0x0
    80005492:	e32080e7          	jalr	-462(ra) # 800052c0 <fdalloc>
    80005496:	84aa                	mv	s1,a0
    return -1;
    80005498:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000549a:	00054963          	bltz	a0,800054ac <sys_dup+0x42>
  filedup(f);
    8000549e:	fd843503          	ld	a0,-40(s0)
    800054a2:	fffff097          	auipc	ra,0xfffff
    800054a6:	320080e7          	jalr	800(ra) # 800047c2 <filedup>
  return fd;
    800054aa:	87a6                	mv	a5,s1
}
    800054ac:	853e                	mv	a0,a5
    800054ae:	70a2                	ld	ra,40(sp)
    800054b0:	7402                	ld	s0,32(sp)
    800054b2:	64e2                	ld	s1,24(sp)
    800054b4:	6145                	addi	sp,sp,48
    800054b6:	8082                	ret

00000000800054b8 <sys_read>:
{
    800054b8:	7179                	addi	sp,sp,-48
    800054ba:	f406                	sd	ra,40(sp)
    800054bc:	f022                	sd	s0,32(sp)
    800054be:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054c0:	fe840613          	addi	a2,s0,-24
    800054c4:	4581                	li	a1,0
    800054c6:	4501                	li	a0,0
    800054c8:	00000097          	auipc	ra,0x0
    800054cc:	d90080e7          	jalr	-624(ra) # 80005258 <argfd>
    return -1;
    800054d0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054d2:	04054163          	bltz	a0,80005514 <sys_read+0x5c>
    800054d6:	fe440593          	addi	a1,s0,-28
    800054da:	4509                	li	a0,2
    800054dc:	ffffe097          	auipc	ra,0xffffe
    800054e0:	922080e7          	jalr	-1758(ra) # 80002dfe <argint>
    return -1;
    800054e4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054e6:	02054763          	bltz	a0,80005514 <sys_read+0x5c>
    800054ea:	fd840593          	addi	a1,s0,-40
    800054ee:	4505                	li	a0,1
    800054f0:	ffffe097          	auipc	ra,0xffffe
    800054f4:	930080e7          	jalr	-1744(ra) # 80002e20 <argaddr>
    return -1;
    800054f8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054fa:	00054d63          	bltz	a0,80005514 <sys_read+0x5c>
  return fileread(f, p, n);
    800054fe:	fe442603          	lw	a2,-28(s0)
    80005502:	fd843583          	ld	a1,-40(s0)
    80005506:	fe843503          	ld	a0,-24(s0)
    8000550a:	fffff097          	auipc	ra,0xfffff
    8000550e:	444080e7          	jalr	1092(ra) # 8000494e <fileread>
    80005512:	87aa                	mv	a5,a0
}
    80005514:	853e                	mv	a0,a5
    80005516:	70a2                	ld	ra,40(sp)
    80005518:	7402                	ld	s0,32(sp)
    8000551a:	6145                	addi	sp,sp,48
    8000551c:	8082                	ret

000000008000551e <sys_write>:
{
    8000551e:	7179                	addi	sp,sp,-48
    80005520:	f406                	sd	ra,40(sp)
    80005522:	f022                	sd	s0,32(sp)
    80005524:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005526:	fe840613          	addi	a2,s0,-24
    8000552a:	4581                	li	a1,0
    8000552c:	4501                	li	a0,0
    8000552e:	00000097          	auipc	ra,0x0
    80005532:	d2a080e7          	jalr	-726(ra) # 80005258 <argfd>
    return -1;
    80005536:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005538:	04054163          	bltz	a0,8000557a <sys_write+0x5c>
    8000553c:	fe440593          	addi	a1,s0,-28
    80005540:	4509                	li	a0,2
    80005542:	ffffe097          	auipc	ra,0xffffe
    80005546:	8bc080e7          	jalr	-1860(ra) # 80002dfe <argint>
    return -1;
    8000554a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000554c:	02054763          	bltz	a0,8000557a <sys_write+0x5c>
    80005550:	fd840593          	addi	a1,s0,-40
    80005554:	4505                	li	a0,1
    80005556:	ffffe097          	auipc	ra,0xffffe
    8000555a:	8ca080e7          	jalr	-1846(ra) # 80002e20 <argaddr>
    return -1;
    8000555e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005560:	00054d63          	bltz	a0,8000557a <sys_write+0x5c>
  return filewrite(f, p, n);
    80005564:	fe442603          	lw	a2,-28(s0)
    80005568:	fd843583          	ld	a1,-40(s0)
    8000556c:	fe843503          	ld	a0,-24(s0)
    80005570:	fffff097          	auipc	ra,0xfffff
    80005574:	4a0080e7          	jalr	1184(ra) # 80004a10 <filewrite>
    80005578:	87aa                	mv	a5,a0
}
    8000557a:	853e                	mv	a0,a5
    8000557c:	70a2                	ld	ra,40(sp)
    8000557e:	7402                	ld	s0,32(sp)
    80005580:	6145                	addi	sp,sp,48
    80005582:	8082                	ret

0000000080005584 <sys_close>:
{
    80005584:	1101                	addi	sp,sp,-32
    80005586:	ec06                	sd	ra,24(sp)
    80005588:	e822                	sd	s0,16(sp)
    8000558a:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000558c:	fe040613          	addi	a2,s0,-32
    80005590:	fec40593          	addi	a1,s0,-20
    80005594:	4501                	li	a0,0
    80005596:	00000097          	auipc	ra,0x0
    8000559a:	cc2080e7          	jalr	-830(ra) # 80005258 <argfd>
    return -1;
    8000559e:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800055a0:	02054463          	bltz	a0,800055c8 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800055a4:	ffffc097          	auipc	ra,0xffffc
    800055a8:	79c080e7          	jalr	1948(ra) # 80001d40 <myproc>
    800055ac:	fec42783          	lw	a5,-20(s0)
    800055b0:	07e9                	addi	a5,a5,26
    800055b2:	078e                	slli	a5,a5,0x3
    800055b4:	97aa                	add	a5,a5,a0
    800055b6:	0007b423          	sd	zero,8(a5)
  fileclose(f);
    800055ba:	fe043503          	ld	a0,-32(s0)
    800055be:	fffff097          	auipc	ra,0xfffff
    800055c2:	256080e7          	jalr	598(ra) # 80004814 <fileclose>
  return 0;
    800055c6:	4781                	li	a5,0
}
    800055c8:	853e                	mv	a0,a5
    800055ca:	60e2                	ld	ra,24(sp)
    800055cc:	6442                	ld	s0,16(sp)
    800055ce:	6105                	addi	sp,sp,32
    800055d0:	8082                	ret

00000000800055d2 <sys_fstat>:
{
    800055d2:	1101                	addi	sp,sp,-32
    800055d4:	ec06                	sd	ra,24(sp)
    800055d6:	e822                	sd	s0,16(sp)
    800055d8:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800055da:	fe840613          	addi	a2,s0,-24
    800055de:	4581                	li	a1,0
    800055e0:	4501                	li	a0,0
    800055e2:	00000097          	auipc	ra,0x0
    800055e6:	c76080e7          	jalr	-906(ra) # 80005258 <argfd>
    return -1;
    800055ea:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800055ec:	02054563          	bltz	a0,80005616 <sys_fstat+0x44>
    800055f0:	fe040593          	addi	a1,s0,-32
    800055f4:	4505                	li	a0,1
    800055f6:	ffffe097          	auipc	ra,0xffffe
    800055fa:	82a080e7          	jalr	-2006(ra) # 80002e20 <argaddr>
    return -1;
    800055fe:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005600:	00054b63          	bltz	a0,80005616 <sys_fstat+0x44>
  return filestat(f, st);
    80005604:	fe043583          	ld	a1,-32(s0)
    80005608:	fe843503          	ld	a0,-24(s0)
    8000560c:	fffff097          	auipc	ra,0xfffff
    80005610:	2d0080e7          	jalr	720(ra) # 800048dc <filestat>
    80005614:	87aa                	mv	a5,a0
}
    80005616:	853e                	mv	a0,a5
    80005618:	60e2                	ld	ra,24(sp)
    8000561a:	6442                	ld	s0,16(sp)
    8000561c:	6105                	addi	sp,sp,32
    8000561e:	8082                	ret

0000000080005620 <sys_link>:
{
    80005620:	7169                	addi	sp,sp,-304
    80005622:	f606                	sd	ra,296(sp)
    80005624:	f222                	sd	s0,288(sp)
    80005626:	ee26                	sd	s1,280(sp)
    80005628:	ea4a                	sd	s2,272(sp)
    8000562a:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000562c:	08000613          	li	a2,128
    80005630:	ed040593          	addi	a1,s0,-304
    80005634:	4501                	li	a0,0
    80005636:	ffffe097          	auipc	ra,0xffffe
    8000563a:	80c080e7          	jalr	-2036(ra) # 80002e42 <argstr>
    return -1;
    8000563e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005640:	10054e63          	bltz	a0,8000575c <sys_link+0x13c>
    80005644:	08000613          	li	a2,128
    80005648:	f5040593          	addi	a1,s0,-176
    8000564c:	4505                	li	a0,1
    8000564e:	ffffd097          	auipc	ra,0xffffd
    80005652:	7f4080e7          	jalr	2036(ra) # 80002e42 <argstr>
    return -1;
    80005656:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005658:	10054263          	bltz	a0,8000575c <sys_link+0x13c>
  begin_op();
    8000565c:	fffff097          	auipc	ra,0xfffff
    80005660:	ce4080e7          	jalr	-796(ra) # 80004340 <begin_op>
  if((ip = namei(old)) == 0){
    80005664:	ed040513          	addi	a0,s0,-304
    80005668:	fffff097          	auipc	ra,0xfffff
    8000566c:	abc080e7          	jalr	-1348(ra) # 80004124 <namei>
    80005670:	84aa                	mv	s1,a0
    80005672:	c551                	beqz	a0,800056fe <sys_link+0xde>
  ilock(ip);
    80005674:	ffffe097          	auipc	ra,0xffffe
    80005678:	2fc080e7          	jalr	764(ra) # 80003970 <ilock>
  if(ip->type == T_DIR){
    8000567c:	04c49703          	lh	a4,76(s1)
    80005680:	4785                	li	a5,1
    80005682:	08f70463          	beq	a4,a5,8000570a <sys_link+0xea>
  ip->nlink++;
    80005686:	0524d783          	lhu	a5,82(s1)
    8000568a:	2785                	addiw	a5,a5,1
    8000568c:	04f49923          	sh	a5,82(s1)
  iupdate(ip);
    80005690:	8526                	mv	a0,s1
    80005692:	ffffe097          	auipc	ra,0xffffe
    80005696:	214080e7          	jalr	532(ra) # 800038a6 <iupdate>
  iunlock(ip);
    8000569a:	8526                	mv	a0,s1
    8000569c:	ffffe097          	auipc	ra,0xffffe
    800056a0:	396080e7          	jalr	918(ra) # 80003a32 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800056a4:	fd040593          	addi	a1,s0,-48
    800056a8:	f5040513          	addi	a0,s0,-176
    800056ac:	fffff097          	auipc	ra,0xfffff
    800056b0:	a96080e7          	jalr	-1386(ra) # 80004142 <nameiparent>
    800056b4:	892a                	mv	s2,a0
    800056b6:	c935                	beqz	a0,8000572a <sys_link+0x10a>
  ilock(dp);
    800056b8:	ffffe097          	auipc	ra,0xffffe
    800056bc:	2b8080e7          	jalr	696(ra) # 80003970 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800056c0:	00092703          	lw	a4,0(s2)
    800056c4:	409c                	lw	a5,0(s1)
    800056c6:	04f71d63          	bne	a4,a5,80005720 <sys_link+0x100>
    800056ca:	40d0                	lw	a2,4(s1)
    800056cc:	fd040593          	addi	a1,s0,-48
    800056d0:	854a                	mv	a0,s2
    800056d2:	fffff097          	auipc	ra,0xfffff
    800056d6:	990080e7          	jalr	-1648(ra) # 80004062 <dirlink>
    800056da:	04054363          	bltz	a0,80005720 <sys_link+0x100>
  iunlockput(dp);
    800056de:	854a                	mv	a0,s2
    800056e0:	ffffe097          	auipc	ra,0xffffe
    800056e4:	4f2080e7          	jalr	1266(ra) # 80003bd2 <iunlockput>
  iput(ip);
    800056e8:	8526                	mv	a0,s1
    800056ea:	ffffe097          	auipc	ra,0xffffe
    800056ee:	440080e7          	jalr	1088(ra) # 80003b2a <iput>
  end_op();
    800056f2:	fffff097          	auipc	ra,0xfffff
    800056f6:	cce080e7          	jalr	-818(ra) # 800043c0 <end_op>
  return 0;
    800056fa:	4781                	li	a5,0
    800056fc:	a085                	j	8000575c <sys_link+0x13c>
    end_op();
    800056fe:	fffff097          	auipc	ra,0xfffff
    80005702:	cc2080e7          	jalr	-830(ra) # 800043c0 <end_op>
    return -1;
    80005706:	57fd                	li	a5,-1
    80005708:	a891                	j	8000575c <sys_link+0x13c>
    iunlockput(ip);
    8000570a:	8526                	mv	a0,s1
    8000570c:	ffffe097          	auipc	ra,0xffffe
    80005710:	4c6080e7          	jalr	1222(ra) # 80003bd2 <iunlockput>
    end_op();
    80005714:	fffff097          	auipc	ra,0xfffff
    80005718:	cac080e7          	jalr	-852(ra) # 800043c0 <end_op>
    return -1;
    8000571c:	57fd                	li	a5,-1
    8000571e:	a83d                	j	8000575c <sys_link+0x13c>
    iunlockput(dp);
    80005720:	854a                	mv	a0,s2
    80005722:	ffffe097          	auipc	ra,0xffffe
    80005726:	4b0080e7          	jalr	1200(ra) # 80003bd2 <iunlockput>
  ilock(ip);
    8000572a:	8526                	mv	a0,s1
    8000572c:	ffffe097          	auipc	ra,0xffffe
    80005730:	244080e7          	jalr	580(ra) # 80003970 <ilock>
  ip->nlink--;
    80005734:	0524d783          	lhu	a5,82(s1)
    80005738:	37fd                	addiw	a5,a5,-1
    8000573a:	04f49923          	sh	a5,82(s1)
  iupdate(ip);
    8000573e:	8526                	mv	a0,s1
    80005740:	ffffe097          	auipc	ra,0xffffe
    80005744:	166080e7          	jalr	358(ra) # 800038a6 <iupdate>
  iunlockput(ip);
    80005748:	8526                	mv	a0,s1
    8000574a:	ffffe097          	auipc	ra,0xffffe
    8000574e:	488080e7          	jalr	1160(ra) # 80003bd2 <iunlockput>
  end_op();
    80005752:	fffff097          	auipc	ra,0xfffff
    80005756:	c6e080e7          	jalr	-914(ra) # 800043c0 <end_op>
  return -1;
    8000575a:	57fd                	li	a5,-1
}
    8000575c:	853e                	mv	a0,a5
    8000575e:	70b2                	ld	ra,296(sp)
    80005760:	7412                	ld	s0,288(sp)
    80005762:	64f2                	ld	s1,280(sp)
    80005764:	6952                	ld	s2,272(sp)
    80005766:	6155                	addi	sp,sp,304
    80005768:	8082                	ret

000000008000576a <sys_unlink>:
{
    8000576a:	7151                	addi	sp,sp,-240
    8000576c:	f586                	sd	ra,232(sp)
    8000576e:	f1a2                	sd	s0,224(sp)
    80005770:	eda6                	sd	s1,216(sp)
    80005772:	e9ca                	sd	s2,208(sp)
    80005774:	e5ce                	sd	s3,200(sp)
    80005776:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005778:	08000613          	li	a2,128
    8000577c:	f3040593          	addi	a1,s0,-208
    80005780:	4501                	li	a0,0
    80005782:	ffffd097          	auipc	ra,0xffffd
    80005786:	6c0080e7          	jalr	1728(ra) # 80002e42 <argstr>
    8000578a:	18054163          	bltz	a0,8000590c <sys_unlink+0x1a2>
  begin_op();
    8000578e:	fffff097          	auipc	ra,0xfffff
    80005792:	bb2080e7          	jalr	-1102(ra) # 80004340 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005796:	fb040593          	addi	a1,s0,-80
    8000579a:	f3040513          	addi	a0,s0,-208
    8000579e:	fffff097          	auipc	ra,0xfffff
    800057a2:	9a4080e7          	jalr	-1628(ra) # 80004142 <nameiparent>
    800057a6:	84aa                	mv	s1,a0
    800057a8:	c979                	beqz	a0,8000587e <sys_unlink+0x114>
  ilock(dp);
    800057aa:	ffffe097          	auipc	ra,0xffffe
    800057ae:	1c6080e7          	jalr	454(ra) # 80003970 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800057b2:	00003597          	auipc	a1,0x3
    800057b6:	fbe58593          	addi	a1,a1,-66 # 80008770 <syscalls+0x2b8>
    800057ba:	fb040513          	addi	a0,s0,-80
    800057be:	ffffe097          	auipc	ra,0xffffe
    800057c2:	67a080e7          	jalr	1658(ra) # 80003e38 <namecmp>
    800057c6:	14050a63          	beqz	a0,8000591a <sys_unlink+0x1b0>
    800057ca:	00003597          	auipc	a1,0x3
    800057ce:	fae58593          	addi	a1,a1,-82 # 80008778 <syscalls+0x2c0>
    800057d2:	fb040513          	addi	a0,s0,-80
    800057d6:	ffffe097          	auipc	ra,0xffffe
    800057da:	662080e7          	jalr	1634(ra) # 80003e38 <namecmp>
    800057de:	12050e63          	beqz	a0,8000591a <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800057e2:	f2c40613          	addi	a2,s0,-212
    800057e6:	fb040593          	addi	a1,s0,-80
    800057ea:	8526                	mv	a0,s1
    800057ec:	ffffe097          	auipc	ra,0xffffe
    800057f0:	666080e7          	jalr	1638(ra) # 80003e52 <dirlookup>
    800057f4:	892a                	mv	s2,a0
    800057f6:	12050263          	beqz	a0,8000591a <sys_unlink+0x1b0>
  ilock(ip);
    800057fa:	ffffe097          	auipc	ra,0xffffe
    800057fe:	176080e7          	jalr	374(ra) # 80003970 <ilock>
  if(ip->nlink < 1)
    80005802:	05291783          	lh	a5,82(s2)
    80005806:	08f05263          	blez	a5,8000588a <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000580a:	04c91703          	lh	a4,76(s2)
    8000580e:	4785                	li	a5,1
    80005810:	08f70563          	beq	a4,a5,8000589a <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005814:	4641                	li	a2,16
    80005816:	4581                	li	a1,0
    80005818:	fc040513          	addi	a0,s0,-64
    8000581c:	ffffc097          	auipc	ra,0xffffc
    80005820:	8bc080e7          	jalr	-1860(ra) # 800010d8 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005824:	4741                	li	a4,16
    80005826:	f2c42683          	lw	a3,-212(s0)
    8000582a:	fc040613          	addi	a2,s0,-64
    8000582e:	4581                	li	a1,0
    80005830:	8526                	mv	a0,s1
    80005832:	ffffe097          	auipc	ra,0xffffe
    80005836:	4ea080e7          	jalr	1258(ra) # 80003d1c <writei>
    8000583a:	47c1                	li	a5,16
    8000583c:	0af51563          	bne	a0,a5,800058e6 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005840:	04c91703          	lh	a4,76(s2)
    80005844:	4785                	li	a5,1
    80005846:	0af70863          	beq	a4,a5,800058f6 <sys_unlink+0x18c>
  iunlockput(dp);
    8000584a:	8526                	mv	a0,s1
    8000584c:	ffffe097          	auipc	ra,0xffffe
    80005850:	386080e7          	jalr	902(ra) # 80003bd2 <iunlockput>
  ip->nlink--;
    80005854:	05295783          	lhu	a5,82(s2)
    80005858:	37fd                	addiw	a5,a5,-1
    8000585a:	04f91923          	sh	a5,82(s2)
  iupdate(ip);
    8000585e:	854a                	mv	a0,s2
    80005860:	ffffe097          	auipc	ra,0xffffe
    80005864:	046080e7          	jalr	70(ra) # 800038a6 <iupdate>
  iunlockput(ip);
    80005868:	854a                	mv	a0,s2
    8000586a:	ffffe097          	auipc	ra,0xffffe
    8000586e:	368080e7          	jalr	872(ra) # 80003bd2 <iunlockput>
  end_op();
    80005872:	fffff097          	auipc	ra,0xfffff
    80005876:	b4e080e7          	jalr	-1202(ra) # 800043c0 <end_op>
  return 0;
    8000587a:	4501                	li	a0,0
    8000587c:	a84d                	j	8000592e <sys_unlink+0x1c4>
    end_op();
    8000587e:	fffff097          	auipc	ra,0xfffff
    80005882:	b42080e7          	jalr	-1214(ra) # 800043c0 <end_op>
    return -1;
    80005886:	557d                	li	a0,-1
    80005888:	a05d                	j	8000592e <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000588a:	00003517          	auipc	a0,0x3
    8000588e:	f1650513          	addi	a0,a0,-234 # 800087a0 <syscalls+0x2e8>
    80005892:	ffffb097          	auipc	ra,0xffffb
    80005896:	cbe080e7          	jalr	-834(ra) # 80000550 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000589a:	05492703          	lw	a4,84(s2)
    8000589e:	02000793          	li	a5,32
    800058a2:	f6e7f9e3          	bgeu	a5,a4,80005814 <sys_unlink+0xaa>
    800058a6:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800058aa:	4741                	li	a4,16
    800058ac:	86ce                	mv	a3,s3
    800058ae:	f1840613          	addi	a2,s0,-232
    800058b2:	4581                	li	a1,0
    800058b4:	854a                	mv	a0,s2
    800058b6:	ffffe097          	auipc	ra,0xffffe
    800058ba:	36e080e7          	jalr	878(ra) # 80003c24 <readi>
    800058be:	47c1                	li	a5,16
    800058c0:	00f51b63          	bne	a0,a5,800058d6 <sys_unlink+0x16c>
    if(de.inum != 0)
    800058c4:	f1845783          	lhu	a5,-232(s0)
    800058c8:	e7a1                	bnez	a5,80005910 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800058ca:	29c1                	addiw	s3,s3,16
    800058cc:	05492783          	lw	a5,84(s2)
    800058d0:	fcf9ede3          	bltu	s3,a5,800058aa <sys_unlink+0x140>
    800058d4:	b781                	j	80005814 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800058d6:	00003517          	auipc	a0,0x3
    800058da:	ee250513          	addi	a0,a0,-286 # 800087b8 <syscalls+0x300>
    800058de:	ffffb097          	auipc	ra,0xffffb
    800058e2:	c72080e7          	jalr	-910(ra) # 80000550 <panic>
    panic("unlink: writei");
    800058e6:	00003517          	auipc	a0,0x3
    800058ea:	eea50513          	addi	a0,a0,-278 # 800087d0 <syscalls+0x318>
    800058ee:	ffffb097          	auipc	ra,0xffffb
    800058f2:	c62080e7          	jalr	-926(ra) # 80000550 <panic>
    dp->nlink--;
    800058f6:	0524d783          	lhu	a5,82(s1)
    800058fa:	37fd                	addiw	a5,a5,-1
    800058fc:	04f49923          	sh	a5,82(s1)
    iupdate(dp);
    80005900:	8526                	mv	a0,s1
    80005902:	ffffe097          	auipc	ra,0xffffe
    80005906:	fa4080e7          	jalr	-92(ra) # 800038a6 <iupdate>
    8000590a:	b781                	j	8000584a <sys_unlink+0xe0>
    return -1;
    8000590c:	557d                	li	a0,-1
    8000590e:	a005                	j	8000592e <sys_unlink+0x1c4>
    iunlockput(ip);
    80005910:	854a                	mv	a0,s2
    80005912:	ffffe097          	auipc	ra,0xffffe
    80005916:	2c0080e7          	jalr	704(ra) # 80003bd2 <iunlockput>
  iunlockput(dp);
    8000591a:	8526                	mv	a0,s1
    8000591c:	ffffe097          	auipc	ra,0xffffe
    80005920:	2b6080e7          	jalr	694(ra) # 80003bd2 <iunlockput>
  end_op();
    80005924:	fffff097          	auipc	ra,0xfffff
    80005928:	a9c080e7          	jalr	-1380(ra) # 800043c0 <end_op>
  return -1;
    8000592c:	557d                	li	a0,-1
}
    8000592e:	70ae                	ld	ra,232(sp)
    80005930:	740e                	ld	s0,224(sp)
    80005932:	64ee                	ld	s1,216(sp)
    80005934:	694e                	ld	s2,208(sp)
    80005936:	69ae                	ld	s3,200(sp)
    80005938:	616d                	addi	sp,sp,240
    8000593a:	8082                	ret

000000008000593c <sys_open>:

uint64
sys_open(void)
{
    8000593c:	7131                	addi	sp,sp,-192
    8000593e:	fd06                	sd	ra,184(sp)
    80005940:	f922                	sd	s0,176(sp)
    80005942:	f526                	sd	s1,168(sp)
    80005944:	f14a                	sd	s2,160(sp)
    80005946:	ed4e                	sd	s3,152(sp)
    80005948:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000594a:	08000613          	li	a2,128
    8000594e:	f5040593          	addi	a1,s0,-176
    80005952:	4501                	li	a0,0
    80005954:	ffffd097          	auipc	ra,0xffffd
    80005958:	4ee080e7          	jalr	1262(ra) # 80002e42 <argstr>
    return -1;
    8000595c:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000595e:	0c054163          	bltz	a0,80005a20 <sys_open+0xe4>
    80005962:	f4c40593          	addi	a1,s0,-180
    80005966:	4505                	li	a0,1
    80005968:	ffffd097          	auipc	ra,0xffffd
    8000596c:	496080e7          	jalr	1174(ra) # 80002dfe <argint>
    80005970:	0a054863          	bltz	a0,80005a20 <sys_open+0xe4>

  begin_op();
    80005974:	fffff097          	auipc	ra,0xfffff
    80005978:	9cc080e7          	jalr	-1588(ra) # 80004340 <begin_op>

  if(omode & O_CREATE){
    8000597c:	f4c42783          	lw	a5,-180(s0)
    80005980:	2007f793          	andi	a5,a5,512
    80005984:	cbdd                	beqz	a5,80005a3a <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005986:	4681                	li	a3,0
    80005988:	4601                	li	a2,0
    8000598a:	4589                	li	a1,2
    8000598c:	f5040513          	addi	a0,s0,-176
    80005990:	00000097          	auipc	ra,0x0
    80005994:	972080e7          	jalr	-1678(ra) # 80005302 <create>
    80005998:	892a                	mv	s2,a0
    if(ip == 0){
    8000599a:	c959                	beqz	a0,80005a30 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000599c:	04c91703          	lh	a4,76(s2)
    800059a0:	478d                	li	a5,3
    800059a2:	00f71763          	bne	a4,a5,800059b0 <sys_open+0x74>
    800059a6:	04e95703          	lhu	a4,78(s2)
    800059aa:	47a5                	li	a5,9
    800059ac:	0ce7ec63          	bltu	a5,a4,80005a84 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800059b0:	fffff097          	auipc	ra,0xfffff
    800059b4:	da8080e7          	jalr	-600(ra) # 80004758 <filealloc>
    800059b8:	89aa                	mv	s3,a0
    800059ba:	10050263          	beqz	a0,80005abe <sys_open+0x182>
    800059be:	00000097          	auipc	ra,0x0
    800059c2:	902080e7          	jalr	-1790(ra) # 800052c0 <fdalloc>
    800059c6:	84aa                	mv	s1,a0
    800059c8:	0e054663          	bltz	a0,80005ab4 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800059cc:	04c91703          	lh	a4,76(s2)
    800059d0:	478d                	li	a5,3
    800059d2:	0cf70463          	beq	a4,a5,80005a9a <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800059d6:	4789                	li	a5,2
    800059d8:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800059dc:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800059e0:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800059e4:	f4c42783          	lw	a5,-180(s0)
    800059e8:	0017c713          	xori	a4,a5,1
    800059ec:	8b05                	andi	a4,a4,1
    800059ee:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800059f2:	0037f713          	andi	a4,a5,3
    800059f6:	00e03733          	snez	a4,a4
    800059fa:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800059fe:	4007f793          	andi	a5,a5,1024
    80005a02:	c791                	beqz	a5,80005a0e <sys_open+0xd2>
    80005a04:	04c91703          	lh	a4,76(s2)
    80005a08:	4789                	li	a5,2
    80005a0a:	08f70f63          	beq	a4,a5,80005aa8 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005a0e:	854a                	mv	a0,s2
    80005a10:	ffffe097          	auipc	ra,0xffffe
    80005a14:	022080e7          	jalr	34(ra) # 80003a32 <iunlock>
  end_op();
    80005a18:	fffff097          	auipc	ra,0xfffff
    80005a1c:	9a8080e7          	jalr	-1624(ra) # 800043c0 <end_op>

  return fd;
}
    80005a20:	8526                	mv	a0,s1
    80005a22:	70ea                	ld	ra,184(sp)
    80005a24:	744a                	ld	s0,176(sp)
    80005a26:	74aa                	ld	s1,168(sp)
    80005a28:	790a                	ld	s2,160(sp)
    80005a2a:	69ea                	ld	s3,152(sp)
    80005a2c:	6129                	addi	sp,sp,192
    80005a2e:	8082                	ret
      end_op();
    80005a30:	fffff097          	auipc	ra,0xfffff
    80005a34:	990080e7          	jalr	-1648(ra) # 800043c0 <end_op>
      return -1;
    80005a38:	b7e5                	j	80005a20 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005a3a:	f5040513          	addi	a0,s0,-176
    80005a3e:	ffffe097          	auipc	ra,0xffffe
    80005a42:	6e6080e7          	jalr	1766(ra) # 80004124 <namei>
    80005a46:	892a                	mv	s2,a0
    80005a48:	c905                	beqz	a0,80005a78 <sys_open+0x13c>
    ilock(ip);
    80005a4a:	ffffe097          	auipc	ra,0xffffe
    80005a4e:	f26080e7          	jalr	-218(ra) # 80003970 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005a52:	04c91703          	lh	a4,76(s2)
    80005a56:	4785                	li	a5,1
    80005a58:	f4f712e3          	bne	a4,a5,8000599c <sys_open+0x60>
    80005a5c:	f4c42783          	lw	a5,-180(s0)
    80005a60:	dba1                	beqz	a5,800059b0 <sys_open+0x74>
      iunlockput(ip);
    80005a62:	854a                	mv	a0,s2
    80005a64:	ffffe097          	auipc	ra,0xffffe
    80005a68:	16e080e7          	jalr	366(ra) # 80003bd2 <iunlockput>
      end_op();
    80005a6c:	fffff097          	auipc	ra,0xfffff
    80005a70:	954080e7          	jalr	-1708(ra) # 800043c0 <end_op>
      return -1;
    80005a74:	54fd                	li	s1,-1
    80005a76:	b76d                	j	80005a20 <sys_open+0xe4>
      end_op();
    80005a78:	fffff097          	auipc	ra,0xfffff
    80005a7c:	948080e7          	jalr	-1720(ra) # 800043c0 <end_op>
      return -1;
    80005a80:	54fd                	li	s1,-1
    80005a82:	bf79                	j	80005a20 <sys_open+0xe4>
    iunlockput(ip);
    80005a84:	854a                	mv	a0,s2
    80005a86:	ffffe097          	auipc	ra,0xffffe
    80005a8a:	14c080e7          	jalr	332(ra) # 80003bd2 <iunlockput>
    end_op();
    80005a8e:	fffff097          	auipc	ra,0xfffff
    80005a92:	932080e7          	jalr	-1742(ra) # 800043c0 <end_op>
    return -1;
    80005a96:	54fd                	li	s1,-1
    80005a98:	b761                	j	80005a20 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005a9a:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005a9e:	04e91783          	lh	a5,78(s2)
    80005aa2:	02f99223          	sh	a5,36(s3)
    80005aa6:	bf2d                	j	800059e0 <sys_open+0xa4>
    itrunc(ip);
    80005aa8:	854a                	mv	a0,s2
    80005aaa:	ffffe097          	auipc	ra,0xffffe
    80005aae:	fd4080e7          	jalr	-44(ra) # 80003a7e <itrunc>
    80005ab2:	bfb1                	j	80005a0e <sys_open+0xd2>
      fileclose(f);
    80005ab4:	854e                	mv	a0,s3
    80005ab6:	fffff097          	auipc	ra,0xfffff
    80005aba:	d5e080e7          	jalr	-674(ra) # 80004814 <fileclose>
    iunlockput(ip);
    80005abe:	854a                	mv	a0,s2
    80005ac0:	ffffe097          	auipc	ra,0xffffe
    80005ac4:	112080e7          	jalr	274(ra) # 80003bd2 <iunlockput>
    end_op();
    80005ac8:	fffff097          	auipc	ra,0xfffff
    80005acc:	8f8080e7          	jalr	-1800(ra) # 800043c0 <end_op>
    return -1;
    80005ad0:	54fd                	li	s1,-1
    80005ad2:	b7b9                	j	80005a20 <sys_open+0xe4>

0000000080005ad4 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005ad4:	7175                	addi	sp,sp,-144
    80005ad6:	e506                	sd	ra,136(sp)
    80005ad8:	e122                	sd	s0,128(sp)
    80005ada:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005adc:	fffff097          	auipc	ra,0xfffff
    80005ae0:	864080e7          	jalr	-1948(ra) # 80004340 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005ae4:	08000613          	li	a2,128
    80005ae8:	f7040593          	addi	a1,s0,-144
    80005aec:	4501                	li	a0,0
    80005aee:	ffffd097          	auipc	ra,0xffffd
    80005af2:	354080e7          	jalr	852(ra) # 80002e42 <argstr>
    80005af6:	02054963          	bltz	a0,80005b28 <sys_mkdir+0x54>
    80005afa:	4681                	li	a3,0
    80005afc:	4601                	li	a2,0
    80005afe:	4585                	li	a1,1
    80005b00:	f7040513          	addi	a0,s0,-144
    80005b04:	fffff097          	auipc	ra,0xfffff
    80005b08:	7fe080e7          	jalr	2046(ra) # 80005302 <create>
    80005b0c:	cd11                	beqz	a0,80005b28 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005b0e:	ffffe097          	auipc	ra,0xffffe
    80005b12:	0c4080e7          	jalr	196(ra) # 80003bd2 <iunlockput>
  end_op();
    80005b16:	fffff097          	auipc	ra,0xfffff
    80005b1a:	8aa080e7          	jalr	-1878(ra) # 800043c0 <end_op>
  return 0;
    80005b1e:	4501                	li	a0,0
}
    80005b20:	60aa                	ld	ra,136(sp)
    80005b22:	640a                	ld	s0,128(sp)
    80005b24:	6149                	addi	sp,sp,144
    80005b26:	8082                	ret
    end_op();
    80005b28:	fffff097          	auipc	ra,0xfffff
    80005b2c:	898080e7          	jalr	-1896(ra) # 800043c0 <end_op>
    return -1;
    80005b30:	557d                	li	a0,-1
    80005b32:	b7fd                	j	80005b20 <sys_mkdir+0x4c>

0000000080005b34 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005b34:	7135                	addi	sp,sp,-160
    80005b36:	ed06                	sd	ra,152(sp)
    80005b38:	e922                	sd	s0,144(sp)
    80005b3a:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005b3c:	fffff097          	auipc	ra,0xfffff
    80005b40:	804080e7          	jalr	-2044(ra) # 80004340 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005b44:	08000613          	li	a2,128
    80005b48:	f7040593          	addi	a1,s0,-144
    80005b4c:	4501                	li	a0,0
    80005b4e:	ffffd097          	auipc	ra,0xffffd
    80005b52:	2f4080e7          	jalr	756(ra) # 80002e42 <argstr>
    80005b56:	04054a63          	bltz	a0,80005baa <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005b5a:	f6c40593          	addi	a1,s0,-148
    80005b5e:	4505                	li	a0,1
    80005b60:	ffffd097          	auipc	ra,0xffffd
    80005b64:	29e080e7          	jalr	670(ra) # 80002dfe <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005b68:	04054163          	bltz	a0,80005baa <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005b6c:	f6840593          	addi	a1,s0,-152
    80005b70:	4509                	li	a0,2
    80005b72:	ffffd097          	auipc	ra,0xffffd
    80005b76:	28c080e7          	jalr	652(ra) # 80002dfe <argint>
     argint(1, &major) < 0 ||
    80005b7a:	02054863          	bltz	a0,80005baa <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005b7e:	f6841683          	lh	a3,-152(s0)
    80005b82:	f6c41603          	lh	a2,-148(s0)
    80005b86:	458d                	li	a1,3
    80005b88:	f7040513          	addi	a0,s0,-144
    80005b8c:	fffff097          	auipc	ra,0xfffff
    80005b90:	776080e7          	jalr	1910(ra) # 80005302 <create>
     argint(2, &minor) < 0 ||
    80005b94:	c919                	beqz	a0,80005baa <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005b96:	ffffe097          	auipc	ra,0xffffe
    80005b9a:	03c080e7          	jalr	60(ra) # 80003bd2 <iunlockput>
  end_op();
    80005b9e:	fffff097          	auipc	ra,0xfffff
    80005ba2:	822080e7          	jalr	-2014(ra) # 800043c0 <end_op>
  return 0;
    80005ba6:	4501                	li	a0,0
    80005ba8:	a031                	j	80005bb4 <sys_mknod+0x80>
    end_op();
    80005baa:	fffff097          	auipc	ra,0xfffff
    80005bae:	816080e7          	jalr	-2026(ra) # 800043c0 <end_op>
    return -1;
    80005bb2:	557d                	li	a0,-1
}
    80005bb4:	60ea                	ld	ra,152(sp)
    80005bb6:	644a                	ld	s0,144(sp)
    80005bb8:	610d                	addi	sp,sp,160
    80005bba:	8082                	ret

0000000080005bbc <sys_chdir>:

uint64
sys_chdir(void)
{
    80005bbc:	7135                	addi	sp,sp,-160
    80005bbe:	ed06                	sd	ra,152(sp)
    80005bc0:	e922                	sd	s0,144(sp)
    80005bc2:	e526                	sd	s1,136(sp)
    80005bc4:	e14a                	sd	s2,128(sp)
    80005bc6:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005bc8:	ffffc097          	auipc	ra,0xffffc
    80005bcc:	178080e7          	jalr	376(ra) # 80001d40 <myproc>
    80005bd0:	892a                	mv	s2,a0
  
  begin_op();
    80005bd2:	ffffe097          	auipc	ra,0xffffe
    80005bd6:	76e080e7          	jalr	1902(ra) # 80004340 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005bda:	08000613          	li	a2,128
    80005bde:	f6040593          	addi	a1,s0,-160
    80005be2:	4501                	li	a0,0
    80005be4:	ffffd097          	auipc	ra,0xffffd
    80005be8:	25e080e7          	jalr	606(ra) # 80002e42 <argstr>
    80005bec:	04054b63          	bltz	a0,80005c42 <sys_chdir+0x86>
    80005bf0:	f6040513          	addi	a0,s0,-160
    80005bf4:	ffffe097          	auipc	ra,0xffffe
    80005bf8:	530080e7          	jalr	1328(ra) # 80004124 <namei>
    80005bfc:	84aa                	mv	s1,a0
    80005bfe:	c131                	beqz	a0,80005c42 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005c00:	ffffe097          	auipc	ra,0xffffe
    80005c04:	d70080e7          	jalr	-656(ra) # 80003970 <ilock>
  if(ip->type != T_DIR){
    80005c08:	04c49703          	lh	a4,76(s1)
    80005c0c:	4785                	li	a5,1
    80005c0e:	04f71063          	bne	a4,a5,80005c4e <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005c12:	8526                	mv	a0,s1
    80005c14:	ffffe097          	auipc	ra,0xffffe
    80005c18:	e1e080e7          	jalr	-482(ra) # 80003a32 <iunlock>
  iput(p->cwd);
    80005c1c:	15893503          	ld	a0,344(s2)
    80005c20:	ffffe097          	auipc	ra,0xffffe
    80005c24:	f0a080e7          	jalr	-246(ra) # 80003b2a <iput>
  end_op();
    80005c28:	ffffe097          	auipc	ra,0xffffe
    80005c2c:	798080e7          	jalr	1944(ra) # 800043c0 <end_op>
  p->cwd = ip;
    80005c30:	14993c23          	sd	s1,344(s2)
  return 0;
    80005c34:	4501                	li	a0,0
}
    80005c36:	60ea                	ld	ra,152(sp)
    80005c38:	644a                	ld	s0,144(sp)
    80005c3a:	64aa                	ld	s1,136(sp)
    80005c3c:	690a                	ld	s2,128(sp)
    80005c3e:	610d                	addi	sp,sp,160
    80005c40:	8082                	ret
    end_op();
    80005c42:	ffffe097          	auipc	ra,0xffffe
    80005c46:	77e080e7          	jalr	1918(ra) # 800043c0 <end_op>
    return -1;
    80005c4a:	557d                	li	a0,-1
    80005c4c:	b7ed                	j	80005c36 <sys_chdir+0x7a>
    iunlockput(ip);
    80005c4e:	8526                	mv	a0,s1
    80005c50:	ffffe097          	auipc	ra,0xffffe
    80005c54:	f82080e7          	jalr	-126(ra) # 80003bd2 <iunlockput>
    end_op();
    80005c58:	ffffe097          	auipc	ra,0xffffe
    80005c5c:	768080e7          	jalr	1896(ra) # 800043c0 <end_op>
    return -1;
    80005c60:	557d                	li	a0,-1
    80005c62:	bfd1                	j	80005c36 <sys_chdir+0x7a>

0000000080005c64 <sys_exec>:

uint64
sys_exec(void)
{
    80005c64:	7145                	addi	sp,sp,-464
    80005c66:	e786                	sd	ra,456(sp)
    80005c68:	e3a2                	sd	s0,448(sp)
    80005c6a:	ff26                	sd	s1,440(sp)
    80005c6c:	fb4a                	sd	s2,432(sp)
    80005c6e:	f74e                	sd	s3,424(sp)
    80005c70:	f352                	sd	s4,416(sp)
    80005c72:	ef56                	sd	s5,408(sp)
    80005c74:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005c76:	08000613          	li	a2,128
    80005c7a:	f4040593          	addi	a1,s0,-192
    80005c7e:	4501                	li	a0,0
    80005c80:	ffffd097          	auipc	ra,0xffffd
    80005c84:	1c2080e7          	jalr	450(ra) # 80002e42 <argstr>
    return -1;
    80005c88:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005c8a:	0c054a63          	bltz	a0,80005d5e <sys_exec+0xfa>
    80005c8e:	e3840593          	addi	a1,s0,-456
    80005c92:	4505                	li	a0,1
    80005c94:	ffffd097          	auipc	ra,0xffffd
    80005c98:	18c080e7          	jalr	396(ra) # 80002e20 <argaddr>
    80005c9c:	0c054163          	bltz	a0,80005d5e <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005ca0:	10000613          	li	a2,256
    80005ca4:	4581                	li	a1,0
    80005ca6:	e4040513          	addi	a0,s0,-448
    80005caa:	ffffb097          	auipc	ra,0xffffb
    80005cae:	42e080e7          	jalr	1070(ra) # 800010d8 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005cb2:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005cb6:	89a6                	mv	s3,s1
    80005cb8:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005cba:	02000a13          	li	s4,32
    80005cbe:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005cc2:	00391513          	slli	a0,s2,0x3
    80005cc6:	e3040593          	addi	a1,s0,-464
    80005cca:	e3843783          	ld	a5,-456(s0)
    80005cce:	953e                	add	a0,a0,a5
    80005cd0:	ffffd097          	auipc	ra,0xffffd
    80005cd4:	094080e7          	jalr	148(ra) # 80002d64 <fetchaddr>
    80005cd8:	02054a63          	bltz	a0,80005d0c <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005cdc:	e3043783          	ld	a5,-464(s0)
    80005ce0:	c3b9                	beqz	a5,80005d26 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005ce2:	ffffb097          	auipc	ra,0xffffb
    80005ce6:	e96080e7          	jalr	-362(ra) # 80000b78 <kalloc>
    80005cea:	85aa                	mv	a1,a0
    80005cec:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005cf0:	cd11                	beqz	a0,80005d0c <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005cf2:	6605                	lui	a2,0x1
    80005cf4:	e3043503          	ld	a0,-464(s0)
    80005cf8:	ffffd097          	auipc	ra,0xffffd
    80005cfc:	0be080e7          	jalr	190(ra) # 80002db6 <fetchstr>
    80005d00:	00054663          	bltz	a0,80005d0c <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005d04:	0905                	addi	s2,s2,1
    80005d06:	09a1                	addi	s3,s3,8
    80005d08:	fb491be3          	bne	s2,s4,80005cbe <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d0c:	10048913          	addi	s2,s1,256
    80005d10:	6088                	ld	a0,0(s1)
    80005d12:	c529                	beqz	a0,80005d5c <sys_exec+0xf8>
    kfree(argv[i]);
    80005d14:	ffffb097          	auipc	ra,0xffffb
    80005d18:	d18080e7          	jalr	-744(ra) # 80000a2c <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d1c:	04a1                	addi	s1,s1,8
    80005d1e:	ff2499e3          	bne	s1,s2,80005d10 <sys_exec+0xac>
  return -1;
    80005d22:	597d                	li	s2,-1
    80005d24:	a82d                	j	80005d5e <sys_exec+0xfa>
      argv[i] = 0;
    80005d26:	0a8e                	slli	s5,s5,0x3
    80005d28:	fc040793          	addi	a5,s0,-64
    80005d2c:	9abe                	add	s5,s5,a5
    80005d2e:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005d32:	e4040593          	addi	a1,s0,-448
    80005d36:	f4040513          	addi	a0,s0,-192
    80005d3a:	fffff097          	auipc	ra,0xfffff
    80005d3e:	194080e7          	jalr	404(ra) # 80004ece <exec>
    80005d42:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d44:	10048993          	addi	s3,s1,256
    80005d48:	6088                	ld	a0,0(s1)
    80005d4a:	c911                	beqz	a0,80005d5e <sys_exec+0xfa>
    kfree(argv[i]);
    80005d4c:	ffffb097          	auipc	ra,0xffffb
    80005d50:	ce0080e7          	jalr	-800(ra) # 80000a2c <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d54:	04a1                	addi	s1,s1,8
    80005d56:	ff3499e3          	bne	s1,s3,80005d48 <sys_exec+0xe4>
    80005d5a:	a011                	j	80005d5e <sys_exec+0xfa>
  return -1;
    80005d5c:	597d                	li	s2,-1
}
    80005d5e:	854a                	mv	a0,s2
    80005d60:	60be                	ld	ra,456(sp)
    80005d62:	641e                	ld	s0,448(sp)
    80005d64:	74fa                	ld	s1,440(sp)
    80005d66:	795a                	ld	s2,432(sp)
    80005d68:	79ba                	ld	s3,424(sp)
    80005d6a:	7a1a                	ld	s4,416(sp)
    80005d6c:	6afa                	ld	s5,408(sp)
    80005d6e:	6179                	addi	sp,sp,464
    80005d70:	8082                	ret

0000000080005d72 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005d72:	7139                	addi	sp,sp,-64
    80005d74:	fc06                	sd	ra,56(sp)
    80005d76:	f822                	sd	s0,48(sp)
    80005d78:	f426                	sd	s1,40(sp)
    80005d7a:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005d7c:	ffffc097          	auipc	ra,0xffffc
    80005d80:	fc4080e7          	jalr	-60(ra) # 80001d40 <myproc>
    80005d84:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005d86:	fd840593          	addi	a1,s0,-40
    80005d8a:	4501                	li	a0,0
    80005d8c:	ffffd097          	auipc	ra,0xffffd
    80005d90:	094080e7          	jalr	148(ra) # 80002e20 <argaddr>
    return -1;
    80005d94:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005d96:	0e054063          	bltz	a0,80005e76 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005d9a:	fc840593          	addi	a1,s0,-56
    80005d9e:	fd040513          	addi	a0,s0,-48
    80005da2:	fffff097          	auipc	ra,0xfffff
    80005da6:	dc8080e7          	jalr	-568(ra) # 80004b6a <pipealloc>
    return -1;
    80005daa:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005dac:	0c054563          	bltz	a0,80005e76 <sys_pipe+0x104>
  fd0 = -1;
    80005db0:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005db4:	fd043503          	ld	a0,-48(s0)
    80005db8:	fffff097          	auipc	ra,0xfffff
    80005dbc:	508080e7          	jalr	1288(ra) # 800052c0 <fdalloc>
    80005dc0:	fca42223          	sw	a0,-60(s0)
    80005dc4:	08054c63          	bltz	a0,80005e5c <sys_pipe+0xea>
    80005dc8:	fc843503          	ld	a0,-56(s0)
    80005dcc:	fffff097          	auipc	ra,0xfffff
    80005dd0:	4f4080e7          	jalr	1268(ra) # 800052c0 <fdalloc>
    80005dd4:	fca42023          	sw	a0,-64(s0)
    80005dd8:	06054863          	bltz	a0,80005e48 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005ddc:	4691                	li	a3,4
    80005dde:	fc440613          	addi	a2,s0,-60
    80005de2:	fd843583          	ld	a1,-40(s0)
    80005de6:	6ca8                	ld	a0,88(s1)
    80005de8:	ffffc097          	auipc	ra,0xffffc
    80005dec:	c4c080e7          	jalr	-948(ra) # 80001a34 <copyout>
    80005df0:	02054063          	bltz	a0,80005e10 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005df4:	4691                	li	a3,4
    80005df6:	fc040613          	addi	a2,s0,-64
    80005dfa:	fd843583          	ld	a1,-40(s0)
    80005dfe:	0591                	addi	a1,a1,4
    80005e00:	6ca8                	ld	a0,88(s1)
    80005e02:	ffffc097          	auipc	ra,0xffffc
    80005e06:	c32080e7          	jalr	-974(ra) # 80001a34 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005e0a:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005e0c:	06055563          	bgez	a0,80005e76 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005e10:	fc442783          	lw	a5,-60(s0)
    80005e14:	07e9                	addi	a5,a5,26
    80005e16:	078e                	slli	a5,a5,0x3
    80005e18:	97a6                	add	a5,a5,s1
    80005e1a:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    80005e1e:	fc042503          	lw	a0,-64(s0)
    80005e22:	0569                	addi	a0,a0,26
    80005e24:	050e                	slli	a0,a0,0x3
    80005e26:	9526                	add	a0,a0,s1
    80005e28:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80005e2c:	fd043503          	ld	a0,-48(s0)
    80005e30:	fffff097          	auipc	ra,0xfffff
    80005e34:	9e4080e7          	jalr	-1564(ra) # 80004814 <fileclose>
    fileclose(wf);
    80005e38:	fc843503          	ld	a0,-56(s0)
    80005e3c:	fffff097          	auipc	ra,0xfffff
    80005e40:	9d8080e7          	jalr	-1576(ra) # 80004814 <fileclose>
    return -1;
    80005e44:	57fd                	li	a5,-1
    80005e46:	a805                	j	80005e76 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005e48:	fc442783          	lw	a5,-60(s0)
    80005e4c:	0007c863          	bltz	a5,80005e5c <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005e50:	01a78513          	addi	a0,a5,26
    80005e54:	050e                	slli	a0,a0,0x3
    80005e56:	9526                	add	a0,a0,s1
    80005e58:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80005e5c:	fd043503          	ld	a0,-48(s0)
    80005e60:	fffff097          	auipc	ra,0xfffff
    80005e64:	9b4080e7          	jalr	-1612(ra) # 80004814 <fileclose>
    fileclose(wf);
    80005e68:	fc843503          	ld	a0,-56(s0)
    80005e6c:	fffff097          	auipc	ra,0xfffff
    80005e70:	9a8080e7          	jalr	-1624(ra) # 80004814 <fileclose>
    return -1;
    80005e74:	57fd                	li	a5,-1
}
    80005e76:	853e                	mv	a0,a5
    80005e78:	70e2                	ld	ra,56(sp)
    80005e7a:	7442                	ld	s0,48(sp)
    80005e7c:	74a2                	ld	s1,40(sp)
    80005e7e:	6121                	addi	sp,sp,64
    80005e80:	8082                	ret
	...

0000000080005e90 <kernelvec>:
    80005e90:	7111                	addi	sp,sp,-256
    80005e92:	e006                	sd	ra,0(sp)
    80005e94:	e40a                	sd	sp,8(sp)
    80005e96:	e80e                	sd	gp,16(sp)
    80005e98:	ec12                	sd	tp,24(sp)
    80005e9a:	f016                	sd	t0,32(sp)
    80005e9c:	f41a                	sd	t1,40(sp)
    80005e9e:	f81e                	sd	t2,48(sp)
    80005ea0:	fc22                	sd	s0,56(sp)
    80005ea2:	e0a6                	sd	s1,64(sp)
    80005ea4:	e4aa                	sd	a0,72(sp)
    80005ea6:	e8ae                	sd	a1,80(sp)
    80005ea8:	ecb2                	sd	a2,88(sp)
    80005eaa:	f0b6                	sd	a3,96(sp)
    80005eac:	f4ba                	sd	a4,104(sp)
    80005eae:	f8be                	sd	a5,112(sp)
    80005eb0:	fcc2                	sd	a6,120(sp)
    80005eb2:	e146                	sd	a7,128(sp)
    80005eb4:	e54a                	sd	s2,136(sp)
    80005eb6:	e94e                	sd	s3,144(sp)
    80005eb8:	ed52                	sd	s4,152(sp)
    80005eba:	f156                	sd	s5,160(sp)
    80005ebc:	f55a                	sd	s6,168(sp)
    80005ebe:	f95e                	sd	s7,176(sp)
    80005ec0:	fd62                	sd	s8,184(sp)
    80005ec2:	e1e6                	sd	s9,192(sp)
    80005ec4:	e5ea                	sd	s10,200(sp)
    80005ec6:	e9ee                	sd	s11,208(sp)
    80005ec8:	edf2                	sd	t3,216(sp)
    80005eca:	f1f6                	sd	t4,224(sp)
    80005ecc:	f5fa                	sd	t5,232(sp)
    80005ece:	f9fe                	sd	t6,240(sp)
    80005ed0:	d61fc0ef          	jal	ra,80002c30 <kerneltrap>
    80005ed4:	6082                	ld	ra,0(sp)
    80005ed6:	6122                	ld	sp,8(sp)
    80005ed8:	61c2                	ld	gp,16(sp)
    80005eda:	7282                	ld	t0,32(sp)
    80005edc:	7322                	ld	t1,40(sp)
    80005ede:	73c2                	ld	t2,48(sp)
    80005ee0:	7462                	ld	s0,56(sp)
    80005ee2:	6486                	ld	s1,64(sp)
    80005ee4:	6526                	ld	a0,72(sp)
    80005ee6:	65c6                	ld	a1,80(sp)
    80005ee8:	6666                	ld	a2,88(sp)
    80005eea:	7686                	ld	a3,96(sp)
    80005eec:	7726                	ld	a4,104(sp)
    80005eee:	77c6                	ld	a5,112(sp)
    80005ef0:	7866                	ld	a6,120(sp)
    80005ef2:	688a                	ld	a7,128(sp)
    80005ef4:	692a                	ld	s2,136(sp)
    80005ef6:	69ca                	ld	s3,144(sp)
    80005ef8:	6a6a                	ld	s4,152(sp)
    80005efa:	7a8a                	ld	s5,160(sp)
    80005efc:	7b2a                	ld	s6,168(sp)
    80005efe:	7bca                	ld	s7,176(sp)
    80005f00:	7c6a                	ld	s8,184(sp)
    80005f02:	6c8e                	ld	s9,192(sp)
    80005f04:	6d2e                	ld	s10,200(sp)
    80005f06:	6dce                	ld	s11,208(sp)
    80005f08:	6e6e                	ld	t3,216(sp)
    80005f0a:	7e8e                	ld	t4,224(sp)
    80005f0c:	7f2e                	ld	t5,232(sp)
    80005f0e:	7fce                	ld	t6,240(sp)
    80005f10:	6111                	addi	sp,sp,256
    80005f12:	10200073          	sret
    80005f16:	00000013          	nop
    80005f1a:	00000013          	nop
    80005f1e:	0001                	nop

0000000080005f20 <timervec>:
    80005f20:	34051573          	csrrw	a0,mscratch,a0
    80005f24:	e10c                	sd	a1,0(a0)
    80005f26:	e510                	sd	a2,8(a0)
    80005f28:	e914                	sd	a3,16(a0)
    80005f2a:	6d0c                	ld	a1,24(a0)
    80005f2c:	7110                	ld	a2,32(a0)
    80005f2e:	6194                	ld	a3,0(a1)
    80005f30:	96b2                	add	a3,a3,a2
    80005f32:	e194                	sd	a3,0(a1)
    80005f34:	4589                	li	a1,2
    80005f36:	14459073          	csrw	sip,a1
    80005f3a:	6914                	ld	a3,16(a0)
    80005f3c:	6510                	ld	a2,8(a0)
    80005f3e:	610c                	ld	a1,0(a0)
    80005f40:	34051573          	csrrw	a0,mscratch,a0
    80005f44:	30200073          	mret
	...

0000000080005f4a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005f4a:	1141                	addi	sp,sp,-16
    80005f4c:	e422                	sd	s0,8(sp)
    80005f4e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005f50:	0c0007b7          	lui	a5,0xc000
    80005f54:	4705                	li	a4,1
    80005f56:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005f58:	c3d8                	sw	a4,4(a5)
}
    80005f5a:	6422                	ld	s0,8(sp)
    80005f5c:	0141                	addi	sp,sp,16
    80005f5e:	8082                	ret

0000000080005f60 <plicinithart>:

void
plicinithart(void)
{
    80005f60:	1141                	addi	sp,sp,-16
    80005f62:	e406                	sd	ra,8(sp)
    80005f64:	e022                	sd	s0,0(sp)
    80005f66:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005f68:	ffffc097          	auipc	ra,0xffffc
    80005f6c:	dac080e7          	jalr	-596(ra) # 80001d14 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005f70:	0085171b          	slliw	a4,a0,0x8
    80005f74:	0c0027b7          	lui	a5,0xc002
    80005f78:	97ba                	add	a5,a5,a4
    80005f7a:	40200713          	li	a4,1026
    80005f7e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005f82:	00d5151b          	slliw	a0,a0,0xd
    80005f86:	0c2017b7          	lui	a5,0xc201
    80005f8a:	953e                	add	a0,a0,a5
    80005f8c:	00052023          	sw	zero,0(a0)
}
    80005f90:	60a2                	ld	ra,8(sp)
    80005f92:	6402                	ld	s0,0(sp)
    80005f94:	0141                	addi	sp,sp,16
    80005f96:	8082                	ret

0000000080005f98 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005f98:	1141                	addi	sp,sp,-16
    80005f9a:	e406                	sd	ra,8(sp)
    80005f9c:	e022                	sd	s0,0(sp)
    80005f9e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005fa0:	ffffc097          	auipc	ra,0xffffc
    80005fa4:	d74080e7          	jalr	-652(ra) # 80001d14 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005fa8:	00d5179b          	slliw	a5,a0,0xd
    80005fac:	0c201537          	lui	a0,0xc201
    80005fb0:	953e                	add	a0,a0,a5
  return irq;
}
    80005fb2:	4148                	lw	a0,4(a0)
    80005fb4:	60a2                	ld	ra,8(sp)
    80005fb6:	6402                	ld	s0,0(sp)
    80005fb8:	0141                	addi	sp,sp,16
    80005fba:	8082                	ret

0000000080005fbc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005fbc:	1101                	addi	sp,sp,-32
    80005fbe:	ec06                	sd	ra,24(sp)
    80005fc0:	e822                	sd	s0,16(sp)
    80005fc2:	e426                	sd	s1,8(sp)
    80005fc4:	1000                	addi	s0,sp,32
    80005fc6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005fc8:	ffffc097          	auipc	ra,0xffffc
    80005fcc:	d4c080e7          	jalr	-692(ra) # 80001d14 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005fd0:	00d5151b          	slliw	a0,a0,0xd
    80005fd4:	0c2017b7          	lui	a5,0xc201
    80005fd8:	97aa                	add	a5,a5,a0
    80005fda:	c3c4                	sw	s1,4(a5)
}
    80005fdc:	60e2                	ld	ra,24(sp)
    80005fde:	6442                	ld	s0,16(sp)
    80005fe0:	64a2                	ld	s1,8(sp)
    80005fe2:	6105                	addi	sp,sp,32
    80005fe4:	8082                	ret

0000000080005fe6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005fe6:	1141                	addi	sp,sp,-16
    80005fe8:	e406                	sd	ra,8(sp)
    80005fea:	e022                	sd	s0,0(sp)
    80005fec:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005fee:	479d                	li	a5,7
    80005ff0:	06a7c963          	blt	a5,a0,80006062 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005ff4:	0001e797          	auipc	a5,0x1e
    80005ff8:	00c78793          	addi	a5,a5,12 # 80024000 <disk>
    80005ffc:	00a78733          	add	a4,a5,a0
    80006000:	6789                	lui	a5,0x2
    80006002:	97ba                	add	a5,a5,a4
    80006004:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006008:	e7ad                	bnez	a5,80006072 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000600a:	00451793          	slli	a5,a0,0x4
    8000600e:	00020717          	auipc	a4,0x20
    80006012:	ff270713          	addi	a4,a4,-14 # 80026000 <disk+0x2000>
    80006016:	6314                	ld	a3,0(a4)
    80006018:	96be                	add	a3,a3,a5
    8000601a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000601e:	6314                	ld	a3,0(a4)
    80006020:	96be                	add	a3,a3,a5
    80006022:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006026:	6314                	ld	a3,0(a4)
    80006028:	96be                	add	a3,a3,a5
    8000602a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000602e:	6318                	ld	a4,0(a4)
    80006030:	97ba                	add	a5,a5,a4
    80006032:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006036:	0001e797          	auipc	a5,0x1e
    8000603a:	fca78793          	addi	a5,a5,-54 # 80024000 <disk>
    8000603e:	97aa                	add	a5,a5,a0
    80006040:	6509                	lui	a0,0x2
    80006042:	953e                	add	a0,a0,a5
    80006044:	4785                	li	a5,1
    80006046:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000604a:	00020517          	auipc	a0,0x20
    8000604e:	fce50513          	addi	a0,a0,-50 # 80026018 <disk+0x2018>
    80006052:	ffffc097          	auipc	ra,0xffffc
    80006056:	684080e7          	jalr	1668(ra) # 800026d6 <wakeup>
}
    8000605a:	60a2                	ld	ra,8(sp)
    8000605c:	6402                	ld	s0,0(sp)
    8000605e:	0141                	addi	sp,sp,16
    80006060:	8082                	ret
    panic("free_desc 1");
    80006062:	00002517          	auipc	a0,0x2
    80006066:	77e50513          	addi	a0,a0,1918 # 800087e0 <syscalls+0x328>
    8000606a:	ffffa097          	auipc	ra,0xffffa
    8000606e:	4e6080e7          	jalr	1254(ra) # 80000550 <panic>
    panic("free_desc 2");
    80006072:	00002517          	auipc	a0,0x2
    80006076:	77e50513          	addi	a0,a0,1918 # 800087f0 <syscalls+0x338>
    8000607a:	ffffa097          	auipc	ra,0xffffa
    8000607e:	4d6080e7          	jalr	1238(ra) # 80000550 <panic>

0000000080006082 <virtio_disk_init>:
{
    80006082:	1101                	addi	sp,sp,-32
    80006084:	ec06                	sd	ra,24(sp)
    80006086:	e822                	sd	s0,16(sp)
    80006088:	e426                	sd	s1,8(sp)
    8000608a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000608c:	00002597          	auipc	a1,0x2
    80006090:	77458593          	addi	a1,a1,1908 # 80008800 <syscalls+0x348>
    80006094:	00020517          	auipc	a0,0x20
    80006098:	09450513          	addi	a0,a0,148 # 80026128 <disk+0x2128>
    8000609c:	ffffb097          	auipc	ra,0xffffb
    800060a0:	dd8080e7          	jalr	-552(ra) # 80000e74 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800060a4:	100017b7          	lui	a5,0x10001
    800060a8:	4398                	lw	a4,0(a5)
    800060aa:	2701                	sext.w	a4,a4
    800060ac:	747277b7          	lui	a5,0x74727
    800060b0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800060b4:	0ef71163          	bne	a4,a5,80006196 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800060b8:	100017b7          	lui	a5,0x10001
    800060bc:	43dc                	lw	a5,4(a5)
    800060be:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800060c0:	4705                	li	a4,1
    800060c2:	0ce79a63          	bne	a5,a4,80006196 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800060c6:	100017b7          	lui	a5,0x10001
    800060ca:	479c                	lw	a5,8(a5)
    800060cc:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800060ce:	4709                	li	a4,2
    800060d0:	0ce79363          	bne	a5,a4,80006196 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800060d4:	100017b7          	lui	a5,0x10001
    800060d8:	47d8                	lw	a4,12(a5)
    800060da:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800060dc:	554d47b7          	lui	a5,0x554d4
    800060e0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800060e4:	0af71963          	bne	a4,a5,80006196 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    800060e8:	100017b7          	lui	a5,0x10001
    800060ec:	4705                	li	a4,1
    800060ee:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800060f0:	470d                	li	a4,3
    800060f2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800060f4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800060f6:	c7ffe737          	lui	a4,0xc7ffe
    800060fa:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd6737>
    800060fe:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006100:	2701                	sext.w	a4,a4
    80006102:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006104:	472d                	li	a4,11
    80006106:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006108:	473d                	li	a4,15
    8000610a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000610c:	6705                	lui	a4,0x1
    8000610e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006110:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006114:	5bdc                	lw	a5,52(a5)
    80006116:	2781                	sext.w	a5,a5
  if(max == 0)
    80006118:	c7d9                	beqz	a5,800061a6 <virtio_disk_init+0x124>
  if(max < NUM)
    8000611a:	471d                	li	a4,7
    8000611c:	08f77d63          	bgeu	a4,a5,800061b6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006120:	100014b7          	lui	s1,0x10001
    80006124:	47a1                	li	a5,8
    80006126:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006128:	6609                	lui	a2,0x2
    8000612a:	4581                	li	a1,0
    8000612c:	0001e517          	auipc	a0,0x1e
    80006130:	ed450513          	addi	a0,a0,-300 # 80024000 <disk>
    80006134:	ffffb097          	auipc	ra,0xffffb
    80006138:	fa4080e7          	jalr	-92(ra) # 800010d8 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000613c:	0001e717          	auipc	a4,0x1e
    80006140:	ec470713          	addi	a4,a4,-316 # 80024000 <disk>
    80006144:	00c75793          	srli	a5,a4,0xc
    80006148:	2781                	sext.w	a5,a5
    8000614a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000614c:	00020797          	auipc	a5,0x20
    80006150:	eb478793          	addi	a5,a5,-332 # 80026000 <disk+0x2000>
    80006154:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006156:	0001e717          	auipc	a4,0x1e
    8000615a:	f2a70713          	addi	a4,a4,-214 # 80024080 <disk+0x80>
    8000615e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006160:	0001f717          	auipc	a4,0x1f
    80006164:	ea070713          	addi	a4,a4,-352 # 80025000 <disk+0x1000>
    80006168:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000616a:	4705                	li	a4,1
    8000616c:	00e78c23          	sb	a4,24(a5)
    80006170:	00e78ca3          	sb	a4,25(a5)
    80006174:	00e78d23          	sb	a4,26(a5)
    80006178:	00e78da3          	sb	a4,27(a5)
    8000617c:	00e78e23          	sb	a4,28(a5)
    80006180:	00e78ea3          	sb	a4,29(a5)
    80006184:	00e78f23          	sb	a4,30(a5)
    80006188:	00e78fa3          	sb	a4,31(a5)
}
    8000618c:	60e2                	ld	ra,24(sp)
    8000618e:	6442                	ld	s0,16(sp)
    80006190:	64a2                	ld	s1,8(sp)
    80006192:	6105                	addi	sp,sp,32
    80006194:	8082                	ret
    panic("could not find virtio disk");
    80006196:	00002517          	auipc	a0,0x2
    8000619a:	67a50513          	addi	a0,a0,1658 # 80008810 <syscalls+0x358>
    8000619e:	ffffa097          	auipc	ra,0xffffa
    800061a2:	3b2080e7          	jalr	946(ra) # 80000550 <panic>
    panic("virtio disk has no queue 0");
    800061a6:	00002517          	auipc	a0,0x2
    800061aa:	68a50513          	addi	a0,a0,1674 # 80008830 <syscalls+0x378>
    800061ae:	ffffa097          	auipc	ra,0xffffa
    800061b2:	3a2080e7          	jalr	930(ra) # 80000550 <panic>
    panic("virtio disk max queue too short");
    800061b6:	00002517          	auipc	a0,0x2
    800061ba:	69a50513          	addi	a0,a0,1690 # 80008850 <syscalls+0x398>
    800061be:	ffffa097          	auipc	ra,0xffffa
    800061c2:	392080e7          	jalr	914(ra) # 80000550 <panic>

00000000800061c6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800061c6:	7159                	addi	sp,sp,-112
    800061c8:	f486                	sd	ra,104(sp)
    800061ca:	f0a2                	sd	s0,96(sp)
    800061cc:	eca6                	sd	s1,88(sp)
    800061ce:	e8ca                	sd	s2,80(sp)
    800061d0:	e4ce                	sd	s3,72(sp)
    800061d2:	e0d2                	sd	s4,64(sp)
    800061d4:	fc56                	sd	s5,56(sp)
    800061d6:	f85a                	sd	s6,48(sp)
    800061d8:	f45e                	sd	s7,40(sp)
    800061da:	f062                	sd	s8,32(sp)
    800061dc:	ec66                	sd	s9,24(sp)
    800061de:	e86a                	sd	s10,16(sp)
    800061e0:	1880                	addi	s0,sp,112
    800061e2:	892a                	mv	s2,a0
    800061e4:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800061e6:	00c52c83          	lw	s9,12(a0)
    800061ea:	001c9c9b          	slliw	s9,s9,0x1
    800061ee:	1c82                	slli	s9,s9,0x20
    800061f0:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800061f4:	00020517          	auipc	a0,0x20
    800061f8:	f3450513          	addi	a0,a0,-204 # 80026128 <disk+0x2128>
    800061fc:	ffffb097          	auipc	ra,0xffffb
    80006200:	afc080e7          	jalr	-1284(ra) # 80000cf8 <acquire>
  for(int i = 0; i < 3; i++){
    80006204:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006206:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006208:	0001eb97          	auipc	s7,0x1e
    8000620c:	df8b8b93          	addi	s7,s7,-520 # 80024000 <disk>
    80006210:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006212:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006214:	8a4e                	mv	s4,s3
    80006216:	a051                	j	8000629a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006218:	00fb86b3          	add	a3,s7,a5
    8000621c:	96da                	add	a3,a3,s6
    8000621e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006222:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006224:	0207c563          	bltz	a5,8000624e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006228:	2485                	addiw	s1,s1,1
    8000622a:	0711                	addi	a4,a4,4
    8000622c:	25548063          	beq	s1,s5,8000646c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006230:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006232:	00020697          	auipc	a3,0x20
    80006236:	de668693          	addi	a3,a3,-538 # 80026018 <disk+0x2018>
    8000623a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000623c:	0006c583          	lbu	a1,0(a3)
    80006240:	fde1                	bnez	a1,80006218 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006242:	2785                	addiw	a5,a5,1
    80006244:	0685                	addi	a3,a3,1
    80006246:	ff879be3          	bne	a5,s8,8000623c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000624a:	57fd                	li	a5,-1
    8000624c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000624e:	02905a63          	blez	s1,80006282 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006252:	f9042503          	lw	a0,-112(s0)
    80006256:	00000097          	auipc	ra,0x0
    8000625a:	d90080e7          	jalr	-624(ra) # 80005fe6 <free_desc>
      for(int j = 0; j < i; j++)
    8000625e:	4785                	li	a5,1
    80006260:	0297d163          	bge	a5,s1,80006282 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006264:	f9442503          	lw	a0,-108(s0)
    80006268:	00000097          	auipc	ra,0x0
    8000626c:	d7e080e7          	jalr	-642(ra) # 80005fe6 <free_desc>
      for(int j = 0; j < i; j++)
    80006270:	4789                	li	a5,2
    80006272:	0097d863          	bge	a5,s1,80006282 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006276:	f9842503          	lw	a0,-104(s0)
    8000627a:	00000097          	auipc	ra,0x0
    8000627e:	d6c080e7          	jalr	-660(ra) # 80005fe6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006282:	00020597          	auipc	a1,0x20
    80006286:	ea658593          	addi	a1,a1,-346 # 80026128 <disk+0x2128>
    8000628a:	00020517          	auipc	a0,0x20
    8000628e:	d8e50513          	addi	a0,a0,-626 # 80026018 <disk+0x2018>
    80006292:	ffffc097          	auipc	ra,0xffffc
    80006296:	2be080e7          	jalr	702(ra) # 80002550 <sleep>
  for(int i = 0; i < 3; i++){
    8000629a:	f9040713          	addi	a4,s0,-112
    8000629e:	84ce                	mv	s1,s3
    800062a0:	bf41                	j	80006230 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    800062a2:	20058713          	addi	a4,a1,512
    800062a6:	00471693          	slli	a3,a4,0x4
    800062aa:	0001e717          	auipc	a4,0x1e
    800062ae:	d5670713          	addi	a4,a4,-682 # 80024000 <disk>
    800062b2:	9736                	add	a4,a4,a3
    800062b4:	4685                	li	a3,1
    800062b6:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800062ba:	20058713          	addi	a4,a1,512
    800062be:	00471693          	slli	a3,a4,0x4
    800062c2:	0001e717          	auipc	a4,0x1e
    800062c6:	d3e70713          	addi	a4,a4,-706 # 80024000 <disk>
    800062ca:	9736                	add	a4,a4,a3
    800062cc:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800062d0:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800062d4:	7679                	lui	a2,0xffffe
    800062d6:	963e                	add	a2,a2,a5
    800062d8:	00020697          	auipc	a3,0x20
    800062dc:	d2868693          	addi	a3,a3,-728 # 80026000 <disk+0x2000>
    800062e0:	6298                	ld	a4,0(a3)
    800062e2:	9732                	add	a4,a4,a2
    800062e4:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800062e6:	6298                	ld	a4,0(a3)
    800062e8:	9732                	add	a4,a4,a2
    800062ea:	4541                	li	a0,16
    800062ec:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800062ee:	6298                	ld	a4,0(a3)
    800062f0:	9732                	add	a4,a4,a2
    800062f2:	4505                	li	a0,1
    800062f4:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    800062f8:	f9442703          	lw	a4,-108(s0)
    800062fc:	6288                	ld	a0,0(a3)
    800062fe:	962a                	add	a2,a2,a0
    80006300:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd5fe6>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006304:	0712                	slli	a4,a4,0x4
    80006306:	6290                	ld	a2,0(a3)
    80006308:	963a                	add	a2,a2,a4
    8000630a:	06090513          	addi	a0,s2,96
    8000630e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006310:	6294                	ld	a3,0(a3)
    80006312:	96ba                	add	a3,a3,a4
    80006314:	40000613          	li	a2,1024
    80006318:	c690                	sw	a2,8(a3)
  if(write)
    8000631a:	140d0063          	beqz	s10,8000645a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000631e:	00020697          	auipc	a3,0x20
    80006322:	ce26b683          	ld	a3,-798(a3) # 80026000 <disk+0x2000>
    80006326:	96ba                	add	a3,a3,a4
    80006328:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000632c:	0001e817          	auipc	a6,0x1e
    80006330:	cd480813          	addi	a6,a6,-812 # 80024000 <disk>
    80006334:	00020517          	auipc	a0,0x20
    80006338:	ccc50513          	addi	a0,a0,-820 # 80026000 <disk+0x2000>
    8000633c:	6114                	ld	a3,0(a0)
    8000633e:	96ba                	add	a3,a3,a4
    80006340:	00c6d603          	lhu	a2,12(a3)
    80006344:	00166613          	ori	a2,a2,1
    80006348:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000634c:	f9842683          	lw	a3,-104(s0)
    80006350:	6110                	ld	a2,0(a0)
    80006352:	9732                	add	a4,a4,a2
    80006354:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006358:	20058613          	addi	a2,a1,512
    8000635c:	0612                	slli	a2,a2,0x4
    8000635e:	9642                	add	a2,a2,a6
    80006360:	577d                	li	a4,-1
    80006362:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006366:	00469713          	slli	a4,a3,0x4
    8000636a:	6114                	ld	a3,0(a0)
    8000636c:	96ba                	add	a3,a3,a4
    8000636e:	03078793          	addi	a5,a5,48
    80006372:	97c2                	add	a5,a5,a6
    80006374:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006376:	611c                	ld	a5,0(a0)
    80006378:	97ba                	add	a5,a5,a4
    8000637a:	4685                	li	a3,1
    8000637c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000637e:	611c                	ld	a5,0(a0)
    80006380:	97ba                	add	a5,a5,a4
    80006382:	4809                	li	a6,2
    80006384:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006388:	611c                	ld	a5,0(a0)
    8000638a:	973e                	add	a4,a4,a5
    8000638c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006390:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006394:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006398:	6518                	ld	a4,8(a0)
    8000639a:	00275783          	lhu	a5,2(a4)
    8000639e:	8b9d                	andi	a5,a5,7
    800063a0:	0786                	slli	a5,a5,0x1
    800063a2:	97ba                	add	a5,a5,a4
    800063a4:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    800063a8:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800063ac:	6518                	ld	a4,8(a0)
    800063ae:	00275783          	lhu	a5,2(a4)
    800063b2:	2785                	addiw	a5,a5,1
    800063b4:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800063b8:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800063bc:	100017b7          	lui	a5,0x10001
    800063c0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800063c4:	00492703          	lw	a4,4(s2)
    800063c8:	4785                	li	a5,1
    800063ca:	02f71163          	bne	a4,a5,800063ec <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    800063ce:	00020997          	auipc	s3,0x20
    800063d2:	d5a98993          	addi	s3,s3,-678 # 80026128 <disk+0x2128>
  while(b->disk == 1) {
    800063d6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800063d8:	85ce                	mv	a1,s3
    800063da:	854a                	mv	a0,s2
    800063dc:	ffffc097          	auipc	ra,0xffffc
    800063e0:	174080e7          	jalr	372(ra) # 80002550 <sleep>
  while(b->disk == 1) {
    800063e4:	00492783          	lw	a5,4(s2)
    800063e8:	fe9788e3          	beq	a5,s1,800063d8 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    800063ec:	f9042903          	lw	s2,-112(s0)
    800063f0:	20090793          	addi	a5,s2,512
    800063f4:	00479713          	slli	a4,a5,0x4
    800063f8:	0001e797          	auipc	a5,0x1e
    800063fc:	c0878793          	addi	a5,a5,-1016 # 80024000 <disk>
    80006400:	97ba                	add	a5,a5,a4
    80006402:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006406:	00020997          	auipc	s3,0x20
    8000640a:	bfa98993          	addi	s3,s3,-1030 # 80026000 <disk+0x2000>
    8000640e:	00491713          	slli	a4,s2,0x4
    80006412:	0009b783          	ld	a5,0(s3)
    80006416:	97ba                	add	a5,a5,a4
    80006418:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000641c:	854a                	mv	a0,s2
    8000641e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006422:	00000097          	auipc	ra,0x0
    80006426:	bc4080e7          	jalr	-1084(ra) # 80005fe6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000642a:	8885                	andi	s1,s1,1
    8000642c:	f0ed                	bnez	s1,8000640e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000642e:	00020517          	auipc	a0,0x20
    80006432:	cfa50513          	addi	a0,a0,-774 # 80026128 <disk+0x2128>
    80006436:	ffffb097          	auipc	ra,0xffffb
    8000643a:	992080e7          	jalr	-1646(ra) # 80000dc8 <release>
}
    8000643e:	70a6                	ld	ra,104(sp)
    80006440:	7406                	ld	s0,96(sp)
    80006442:	64e6                	ld	s1,88(sp)
    80006444:	6946                	ld	s2,80(sp)
    80006446:	69a6                	ld	s3,72(sp)
    80006448:	6a06                	ld	s4,64(sp)
    8000644a:	7ae2                	ld	s5,56(sp)
    8000644c:	7b42                	ld	s6,48(sp)
    8000644e:	7ba2                	ld	s7,40(sp)
    80006450:	7c02                	ld	s8,32(sp)
    80006452:	6ce2                	ld	s9,24(sp)
    80006454:	6d42                	ld	s10,16(sp)
    80006456:	6165                	addi	sp,sp,112
    80006458:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000645a:	00020697          	auipc	a3,0x20
    8000645e:	ba66b683          	ld	a3,-1114(a3) # 80026000 <disk+0x2000>
    80006462:	96ba                	add	a3,a3,a4
    80006464:	4609                	li	a2,2
    80006466:	00c69623          	sh	a2,12(a3)
    8000646a:	b5c9                	j	8000632c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000646c:	f9042583          	lw	a1,-112(s0)
    80006470:	20058793          	addi	a5,a1,512
    80006474:	0792                	slli	a5,a5,0x4
    80006476:	0001e517          	auipc	a0,0x1e
    8000647a:	c3250513          	addi	a0,a0,-974 # 800240a8 <disk+0xa8>
    8000647e:	953e                	add	a0,a0,a5
  if(write)
    80006480:	e20d11e3          	bnez	s10,800062a2 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006484:	20058713          	addi	a4,a1,512
    80006488:	00471693          	slli	a3,a4,0x4
    8000648c:	0001e717          	auipc	a4,0x1e
    80006490:	b7470713          	addi	a4,a4,-1164 # 80024000 <disk>
    80006494:	9736                	add	a4,a4,a3
    80006496:	0a072423          	sw	zero,168(a4)
    8000649a:	b505                	j	800062ba <virtio_disk_rw+0xf4>

000000008000649c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000649c:	1101                	addi	sp,sp,-32
    8000649e:	ec06                	sd	ra,24(sp)
    800064a0:	e822                	sd	s0,16(sp)
    800064a2:	e426                	sd	s1,8(sp)
    800064a4:	e04a                	sd	s2,0(sp)
    800064a6:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800064a8:	00020517          	auipc	a0,0x20
    800064ac:	c8050513          	addi	a0,a0,-896 # 80026128 <disk+0x2128>
    800064b0:	ffffb097          	auipc	ra,0xffffb
    800064b4:	848080e7          	jalr	-1976(ra) # 80000cf8 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800064b8:	10001737          	lui	a4,0x10001
    800064bc:	533c                	lw	a5,96(a4)
    800064be:	8b8d                	andi	a5,a5,3
    800064c0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800064c2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800064c6:	00020797          	auipc	a5,0x20
    800064ca:	b3a78793          	addi	a5,a5,-1222 # 80026000 <disk+0x2000>
    800064ce:	6b94                	ld	a3,16(a5)
    800064d0:	0207d703          	lhu	a4,32(a5)
    800064d4:	0026d783          	lhu	a5,2(a3)
    800064d8:	06f70163          	beq	a4,a5,8000653a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800064dc:	0001e917          	auipc	s2,0x1e
    800064e0:	b2490913          	addi	s2,s2,-1244 # 80024000 <disk>
    800064e4:	00020497          	auipc	s1,0x20
    800064e8:	b1c48493          	addi	s1,s1,-1252 # 80026000 <disk+0x2000>
    __sync_synchronize();
    800064ec:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800064f0:	6898                	ld	a4,16(s1)
    800064f2:	0204d783          	lhu	a5,32(s1)
    800064f6:	8b9d                	andi	a5,a5,7
    800064f8:	078e                	slli	a5,a5,0x3
    800064fa:	97ba                	add	a5,a5,a4
    800064fc:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800064fe:	20078713          	addi	a4,a5,512
    80006502:	0712                	slli	a4,a4,0x4
    80006504:	974a                	add	a4,a4,s2
    80006506:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000650a:	e731                	bnez	a4,80006556 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000650c:	20078793          	addi	a5,a5,512
    80006510:	0792                	slli	a5,a5,0x4
    80006512:	97ca                	add	a5,a5,s2
    80006514:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006516:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000651a:	ffffc097          	auipc	ra,0xffffc
    8000651e:	1bc080e7          	jalr	444(ra) # 800026d6 <wakeup>

    disk.used_idx += 1;
    80006522:	0204d783          	lhu	a5,32(s1)
    80006526:	2785                	addiw	a5,a5,1
    80006528:	17c2                	slli	a5,a5,0x30
    8000652a:	93c1                	srli	a5,a5,0x30
    8000652c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006530:	6898                	ld	a4,16(s1)
    80006532:	00275703          	lhu	a4,2(a4)
    80006536:	faf71be3          	bne	a4,a5,800064ec <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000653a:	00020517          	auipc	a0,0x20
    8000653e:	bee50513          	addi	a0,a0,-1042 # 80026128 <disk+0x2128>
    80006542:	ffffb097          	auipc	ra,0xffffb
    80006546:	886080e7          	jalr	-1914(ra) # 80000dc8 <release>
}
    8000654a:	60e2                	ld	ra,24(sp)
    8000654c:	6442                	ld	s0,16(sp)
    8000654e:	64a2                	ld	s1,8(sp)
    80006550:	6902                	ld	s2,0(sp)
    80006552:	6105                	addi	sp,sp,32
    80006554:	8082                	ret
      panic("virtio_disk_intr status");
    80006556:	00002517          	auipc	a0,0x2
    8000655a:	31a50513          	addi	a0,a0,794 # 80008870 <syscalls+0x3b8>
    8000655e:	ffffa097          	auipc	ra,0xffffa
    80006562:	ff2080e7          	jalr	-14(ra) # 80000550 <panic>

0000000080006566 <statswrite>:
int statscopyin(char*, int);
int statslock(char*, int);
  
int
statswrite(int user_src, uint64 src, int n)
{
    80006566:	1141                	addi	sp,sp,-16
    80006568:	e422                	sd	s0,8(sp)
    8000656a:	0800                	addi	s0,sp,16
  return -1;
}
    8000656c:	557d                	li	a0,-1
    8000656e:	6422                	ld	s0,8(sp)
    80006570:	0141                	addi	sp,sp,16
    80006572:	8082                	ret

0000000080006574 <statsread>:

int
statsread(int user_dst, uint64 dst, int n)
{
    80006574:	7179                	addi	sp,sp,-48
    80006576:	f406                	sd	ra,40(sp)
    80006578:	f022                	sd	s0,32(sp)
    8000657a:	ec26                	sd	s1,24(sp)
    8000657c:	e84a                	sd	s2,16(sp)
    8000657e:	e44e                	sd	s3,8(sp)
    80006580:	e052                	sd	s4,0(sp)
    80006582:	1800                	addi	s0,sp,48
    80006584:	892a                	mv	s2,a0
    80006586:	89ae                	mv	s3,a1
    80006588:	84b2                	mv	s1,a2
  int m;

  acquire(&stats.lock);
    8000658a:	00021517          	auipc	a0,0x21
    8000658e:	a7650513          	addi	a0,a0,-1418 # 80027000 <stats>
    80006592:	ffffa097          	auipc	ra,0xffffa
    80006596:	766080e7          	jalr	1894(ra) # 80000cf8 <acquire>

  if(stats.sz == 0) {
    8000659a:	00022797          	auipc	a5,0x22
    8000659e:	a867a783          	lw	a5,-1402(a5) # 80028020 <stats+0x1020>
    800065a2:	cbb5                	beqz	a5,80006616 <statsread+0xa2>
#endif
#ifdef LAB_LOCK
    stats.sz = statslock(stats.buf, BUFSZ);
#endif
  }
  m = stats.sz - stats.off;
    800065a4:	00022797          	auipc	a5,0x22
    800065a8:	a5c78793          	addi	a5,a5,-1444 # 80028000 <stats+0x1000>
    800065ac:	53d8                	lw	a4,36(a5)
    800065ae:	539c                	lw	a5,32(a5)
    800065b0:	9f99                	subw	a5,a5,a4
    800065b2:	0007869b          	sext.w	a3,a5

  if (m > 0) {
    800065b6:	06d05e63          	blez	a3,80006632 <statsread+0xbe>
    if(m > n)
    800065ba:	8a3e                	mv	s4,a5
    800065bc:	00d4d363          	bge	s1,a3,800065c2 <statsread+0x4e>
    800065c0:	8a26                	mv	s4,s1
    800065c2:	000a049b          	sext.w	s1,s4
      m  = n;
    if(either_copyout(user_dst, dst, stats.buf+stats.off, m) != -1) {
    800065c6:	86a6                	mv	a3,s1
    800065c8:	00021617          	auipc	a2,0x21
    800065cc:	a5860613          	addi	a2,a2,-1448 # 80027020 <stats+0x20>
    800065d0:	963a                	add	a2,a2,a4
    800065d2:	85ce                	mv	a1,s3
    800065d4:	854a                	mv	a0,s2
    800065d6:	ffffc097          	auipc	ra,0xffffc
    800065da:	1dc080e7          	jalr	476(ra) # 800027b2 <either_copyout>
    800065de:	57fd                	li	a5,-1
    800065e0:	00f50a63          	beq	a0,a5,800065f4 <statsread+0x80>
      stats.off += m;
    800065e4:	00022717          	auipc	a4,0x22
    800065e8:	a1c70713          	addi	a4,a4,-1508 # 80028000 <stats+0x1000>
    800065ec:	535c                	lw	a5,36(a4)
    800065ee:	014787bb          	addw	a5,a5,s4
    800065f2:	d35c                	sw	a5,36(a4)
  } else {
    m = -1;
    stats.sz = 0;
    stats.off = 0;
  }
  release(&stats.lock);
    800065f4:	00021517          	auipc	a0,0x21
    800065f8:	a0c50513          	addi	a0,a0,-1524 # 80027000 <stats>
    800065fc:	ffffa097          	auipc	ra,0xffffa
    80006600:	7cc080e7          	jalr	1996(ra) # 80000dc8 <release>
  return m;
}
    80006604:	8526                	mv	a0,s1
    80006606:	70a2                	ld	ra,40(sp)
    80006608:	7402                	ld	s0,32(sp)
    8000660a:	64e2                	ld	s1,24(sp)
    8000660c:	6942                	ld	s2,16(sp)
    8000660e:	69a2                	ld	s3,8(sp)
    80006610:	6a02                	ld	s4,0(sp)
    80006612:	6145                	addi	sp,sp,48
    80006614:	8082                	ret
    stats.sz = statslock(stats.buf, BUFSZ);
    80006616:	6585                	lui	a1,0x1
    80006618:	00021517          	auipc	a0,0x21
    8000661c:	a0850513          	addi	a0,a0,-1528 # 80027020 <stats+0x20>
    80006620:	ffffb097          	auipc	ra,0xffffb
    80006624:	902080e7          	jalr	-1790(ra) # 80000f22 <statslock>
    80006628:	00022797          	auipc	a5,0x22
    8000662c:	9ea7ac23          	sw	a0,-1544(a5) # 80028020 <stats+0x1020>
    80006630:	bf95                	j	800065a4 <statsread+0x30>
    stats.sz = 0;
    80006632:	00022797          	auipc	a5,0x22
    80006636:	9ce78793          	addi	a5,a5,-1586 # 80028000 <stats+0x1000>
    8000663a:	0207a023          	sw	zero,32(a5)
    stats.off = 0;
    8000663e:	0207a223          	sw	zero,36(a5)
    m = -1;
    80006642:	54fd                	li	s1,-1
    80006644:	bf45                	j	800065f4 <statsread+0x80>

0000000080006646 <statsinit>:

void
statsinit(void)
{
    80006646:	1141                	addi	sp,sp,-16
    80006648:	e406                	sd	ra,8(sp)
    8000664a:	e022                	sd	s0,0(sp)
    8000664c:	0800                	addi	s0,sp,16
  initlock(&stats.lock, "stats");
    8000664e:	00002597          	auipc	a1,0x2
    80006652:	23a58593          	addi	a1,a1,570 # 80008888 <syscalls+0x3d0>
    80006656:	00021517          	auipc	a0,0x21
    8000665a:	9aa50513          	addi	a0,a0,-1622 # 80027000 <stats>
    8000665e:	ffffb097          	auipc	ra,0xffffb
    80006662:	816080e7          	jalr	-2026(ra) # 80000e74 <initlock>

  devsw[STATS].read = statsread;
    80006666:	0001c797          	auipc	a5,0x1c
    8000666a:	23278793          	addi	a5,a5,562 # 80022898 <devsw>
    8000666e:	00000717          	auipc	a4,0x0
    80006672:	f0670713          	addi	a4,a4,-250 # 80006574 <statsread>
    80006676:	f398                	sd	a4,32(a5)
  devsw[STATS].write = statswrite;
    80006678:	00000717          	auipc	a4,0x0
    8000667c:	eee70713          	addi	a4,a4,-274 # 80006566 <statswrite>
    80006680:	f798                	sd	a4,40(a5)
}
    80006682:	60a2                	ld	ra,8(sp)
    80006684:	6402                	ld	s0,0(sp)
    80006686:	0141                	addi	sp,sp,16
    80006688:	8082                	ret

000000008000668a <sprintint>:
  return 1;
}

static int
sprintint(char *s, int xx, int base, int sign)
{
    8000668a:	1101                	addi	sp,sp,-32
    8000668c:	ec22                	sd	s0,24(sp)
    8000668e:	1000                	addi	s0,sp,32
    80006690:	882a                	mv	a6,a0
  char buf[16];
  int i, n;
  uint x;

  if(sign && (sign = xx < 0))
    80006692:	c299                	beqz	a3,80006698 <sprintint+0xe>
    80006694:	0805c163          	bltz	a1,80006716 <sprintint+0x8c>
    x = -xx;
  else
    x = xx;
    80006698:	2581                	sext.w	a1,a1
    8000669a:	4301                	li	t1,0

  i = 0;
    8000669c:	fe040713          	addi	a4,s0,-32
    800066a0:	4501                	li	a0,0
  do {
    buf[i++] = digits[x % base];
    800066a2:	2601                	sext.w	a2,a2
    800066a4:	00002697          	auipc	a3,0x2
    800066a8:	1ec68693          	addi	a3,a3,492 # 80008890 <digits>
    800066ac:	88aa                	mv	a7,a0
    800066ae:	2505                	addiw	a0,a0,1
    800066b0:	02c5f7bb          	remuw	a5,a1,a2
    800066b4:	1782                	slli	a5,a5,0x20
    800066b6:	9381                	srli	a5,a5,0x20
    800066b8:	97b6                	add	a5,a5,a3
    800066ba:	0007c783          	lbu	a5,0(a5)
    800066be:	00f70023          	sb	a5,0(a4)
  } while((x /= base) != 0);
    800066c2:	0005879b          	sext.w	a5,a1
    800066c6:	02c5d5bb          	divuw	a1,a1,a2
    800066ca:	0705                	addi	a4,a4,1
    800066cc:	fec7f0e3          	bgeu	a5,a2,800066ac <sprintint+0x22>

  if(sign)
    800066d0:	00030b63          	beqz	t1,800066e6 <sprintint+0x5c>
    buf[i++] = '-';
    800066d4:	ff040793          	addi	a5,s0,-16
    800066d8:	97aa                	add	a5,a5,a0
    800066da:	02d00713          	li	a4,45
    800066de:	fee78823          	sb	a4,-16(a5)
    800066e2:	0028851b          	addiw	a0,a7,2

  n = 0;
  while(--i >= 0)
    800066e6:	02a05c63          	blez	a0,8000671e <sprintint+0x94>
    800066ea:	fe040793          	addi	a5,s0,-32
    800066ee:	00a78733          	add	a4,a5,a0
    800066f2:	87c2                	mv	a5,a6
    800066f4:	0805                	addi	a6,a6,1
    800066f6:	fff5061b          	addiw	a2,a0,-1
    800066fa:	1602                	slli	a2,a2,0x20
    800066fc:	9201                	srli	a2,a2,0x20
    800066fe:	9642                	add	a2,a2,a6
  *s = c;
    80006700:	fff74683          	lbu	a3,-1(a4)
    80006704:	00d78023          	sb	a3,0(a5)
  while(--i >= 0)
    80006708:	177d                	addi	a4,a4,-1
    8000670a:	0785                	addi	a5,a5,1
    8000670c:	fec79ae3          	bne	a5,a2,80006700 <sprintint+0x76>
    n += sputc(s+n, buf[i]);
  return n;
}
    80006710:	6462                	ld	s0,24(sp)
    80006712:	6105                	addi	sp,sp,32
    80006714:	8082                	ret
    x = -xx;
    80006716:	40b005bb          	negw	a1,a1
  if(sign && (sign = xx < 0))
    8000671a:	4305                	li	t1,1
    x = -xx;
    8000671c:	b741                	j	8000669c <sprintint+0x12>
  while(--i >= 0)
    8000671e:	4501                	li	a0,0
    80006720:	bfc5                	j	80006710 <sprintint+0x86>

0000000080006722 <snprintf>:

int
snprintf(char *buf, int sz, char *fmt, ...)
{
    80006722:	7171                	addi	sp,sp,-176
    80006724:	fc86                	sd	ra,120(sp)
    80006726:	f8a2                	sd	s0,112(sp)
    80006728:	f4a6                	sd	s1,104(sp)
    8000672a:	f0ca                	sd	s2,96(sp)
    8000672c:	ecce                	sd	s3,88(sp)
    8000672e:	e8d2                	sd	s4,80(sp)
    80006730:	e4d6                	sd	s5,72(sp)
    80006732:	e0da                	sd	s6,64(sp)
    80006734:	fc5e                	sd	s7,56(sp)
    80006736:	f862                	sd	s8,48(sp)
    80006738:	f466                	sd	s9,40(sp)
    8000673a:	f06a                	sd	s10,32(sp)
    8000673c:	ec6e                	sd	s11,24(sp)
    8000673e:	0100                	addi	s0,sp,128
    80006740:	e414                	sd	a3,8(s0)
    80006742:	e818                	sd	a4,16(s0)
    80006744:	ec1c                	sd	a5,24(s0)
    80006746:	03043023          	sd	a6,32(s0)
    8000674a:	03143423          	sd	a7,40(s0)
  va_list ap;
  int i, c;
  int off = 0;
  char *s;

  if (fmt == 0)
    8000674e:	ca0d                	beqz	a2,80006780 <snprintf+0x5e>
    80006750:	8baa                	mv	s7,a0
    80006752:	89ae                	mv	s3,a1
    80006754:	8a32                	mv	s4,a2
    panic("null fmt");

  va_start(ap, fmt);
    80006756:	00840793          	addi	a5,s0,8
    8000675a:	f8f43423          	sd	a5,-120(s0)
  int off = 0;
    8000675e:	4481                	li	s1,0
  for(i = 0; off < sz && (c = fmt[i] & 0xff) != 0; i++){
    80006760:	4901                	li	s2,0
    80006762:	02b05763          	blez	a1,80006790 <snprintf+0x6e>
    if(c != '%'){
    80006766:	02500a93          	li	s5,37
      continue;
    }
    c = fmt[++i] & 0xff;
    if(c == 0)
      break;
    switch(c){
    8000676a:	07300b13          	li	s6,115
      off += sprintint(buf+off, va_arg(ap, int), 16, 1);
      break;
    case 's':
      if((s = va_arg(ap, char*)) == 0)
        s = "(null)";
      for(; *s && off < sz; s++)
    8000676e:	02800d93          	li	s11,40
  *s = c;
    80006772:	02500d13          	li	s10,37
    switch(c){
    80006776:	07800c93          	li	s9,120
    8000677a:	06400c13          	li	s8,100
    8000677e:	a01d                	j	800067a4 <snprintf+0x82>
    panic("null fmt");
    80006780:	00002517          	auipc	a0,0x2
    80006784:	8a850513          	addi	a0,a0,-1880 # 80008028 <etext+0x28>
    80006788:	ffffa097          	auipc	ra,0xffffa
    8000678c:	dc8080e7          	jalr	-568(ra) # 80000550 <panic>
  int off = 0;
    80006790:	4481                	li	s1,0
    80006792:	a86d                	j	8000684c <snprintf+0x12a>
  *s = c;
    80006794:	009b8733          	add	a4,s7,s1
    80006798:	00f70023          	sb	a5,0(a4)
      off += sputc(buf+off, c);
    8000679c:	2485                	addiw	s1,s1,1
  for(i = 0; off < sz && (c = fmt[i] & 0xff) != 0; i++){
    8000679e:	2905                	addiw	s2,s2,1
    800067a0:	0b34d663          	bge	s1,s3,8000684c <snprintf+0x12a>
    800067a4:	012a07b3          	add	a5,s4,s2
    800067a8:	0007c783          	lbu	a5,0(a5)
    800067ac:	0007871b          	sext.w	a4,a5
    800067b0:	cfd1                	beqz	a5,8000684c <snprintf+0x12a>
    if(c != '%'){
    800067b2:	ff5711e3          	bne	a4,s5,80006794 <snprintf+0x72>
    c = fmt[++i] & 0xff;
    800067b6:	2905                	addiw	s2,s2,1
    800067b8:	012a07b3          	add	a5,s4,s2
    800067bc:	0007c783          	lbu	a5,0(a5)
    if(c == 0)
    800067c0:	c7d1                	beqz	a5,8000684c <snprintf+0x12a>
    switch(c){
    800067c2:	05678c63          	beq	a5,s6,8000681a <snprintf+0xf8>
    800067c6:	02fb6763          	bltu	s6,a5,800067f4 <snprintf+0xd2>
    800067ca:	0b578763          	beq	a5,s5,80006878 <snprintf+0x156>
    800067ce:	0b879b63          	bne	a5,s8,80006884 <snprintf+0x162>
      off += sprintint(buf+off, va_arg(ap, int), 10, 1);
    800067d2:	f8843783          	ld	a5,-120(s0)
    800067d6:	00878713          	addi	a4,a5,8
    800067da:	f8e43423          	sd	a4,-120(s0)
    800067de:	4685                	li	a3,1
    800067e0:	4629                	li	a2,10
    800067e2:	438c                	lw	a1,0(a5)
    800067e4:	009b8533          	add	a0,s7,s1
    800067e8:	00000097          	auipc	ra,0x0
    800067ec:	ea2080e7          	jalr	-350(ra) # 8000668a <sprintint>
    800067f0:	9ca9                	addw	s1,s1,a0
      break;
    800067f2:	b775                	j	8000679e <snprintf+0x7c>
    switch(c){
    800067f4:	09979863          	bne	a5,s9,80006884 <snprintf+0x162>
      off += sprintint(buf+off, va_arg(ap, int), 16, 1);
    800067f8:	f8843783          	ld	a5,-120(s0)
    800067fc:	00878713          	addi	a4,a5,8
    80006800:	f8e43423          	sd	a4,-120(s0)
    80006804:	4685                	li	a3,1
    80006806:	4641                	li	a2,16
    80006808:	438c                	lw	a1,0(a5)
    8000680a:	009b8533          	add	a0,s7,s1
    8000680e:	00000097          	auipc	ra,0x0
    80006812:	e7c080e7          	jalr	-388(ra) # 8000668a <sprintint>
    80006816:	9ca9                	addw	s1,s1,a0
      break;
    80006818:	b759                	j	8000679e <snprintf+0x7c>
      if((s = va_arg(ap, char*)) == 0)
    8000681a:	f8843783          	ld	a5,-120(s0)
    8000681e:	00878713          	addi	a4,a5,8
    80006822:	f8e43423          	sd	a4,-120(s0)
    80006826:	639c                	ld	a5,0(a5)
    80006828:	c3b1                	beqz	a5,8000686c <snprintf+0x14a>
      for(; *s && off < sz; s++)
    8000682a:	0007c703          	lbu	a4,0(a5)
    8000682e:	db25                	beqz	a4,8000679e <snprintf+0x7c>
    80006830:	0134de63          	bge	s1,s3,8000684c <snprintf+0x12a>
    80006834:	009b86b3          	add	a3,s7,s1
  *s = c;
    80006838:	00e68023          	sb	a4,0(a3)
        off += sputc(buf+off, *s);
    8000683c:	2485                	addiw	s1,s1,1
      for(; *s && off < sz; s++)
    8000683e:	0785                	addi	a5,a5,1
    80006840:	0007c703          	lbu	a4,0(a5)
    80006844:	df29                	beqz	a4,8000679e <snprintf+0x7c>
    80006846:	0685                	addi	a3,a3,1
    80006848:	fe9998e3          	bne	s3,s1,80006838 <snprintf+0x116>
      off += sputc(buf+off, c);
      break;
    }
  }
  return off;
}
    8000684c:	8526                	mv	a0,s1
    8000684e:	70e6                	ld	ra,120(sp)
    80006850:	7446                	ld	s0,112(sp)
    80006852:	74a6                	ld	s1,104(sp)
    80006854:	7906                	ld	s2,96(sp)
    80006856:	69e6                	ld	s3,88(sp)
    80006858:	6a46                	ld	s4,80(sp)
    8000685a:	6aa6                	ld	s5,72(sp)
    8000685c:	6b06                	ld	s6,64(sp)
    8000685e:	7be2                	ld	s7,56(sp)
    80006860:	7c42                	ld	s8,48(sp)
    80006862:	7ca2                	ld	s9,40(sp)
    80006864:	7d02                	ld	s10,32(sp)
    80006866:	6de2                	ld	s11,24(sp)
    80006868:	614d                	addi	sp,sp,176
    8000686a:	8082                	ret
        s = "(null)";
    8000686c:	00001797          	auipc	a5,0x1
    80006870:	7b478793          	addi	a5,a5,1972 # 80008020 <etext+0x20>
      for(; *s && off < sz; s++)
    80006874:	876e                	mv	a4,s11
    80006876:	bf6d                	j	80006830 <snprintf+0x10e>
  *s = c;
    80006878:	009b87b3          	add	a5,s7,s1
    8000687c:	01a78023          	sb	s10,0(a5)
      off += sputc(buf+off, '%');
    80006880:	2485                	addiw	s1,s1,1
      break;
    80006882:	bf31                	j	8000679e <snprintf+0x7c>
  *s = c;
    80006884:	009b8733          	add	a4,s7,s1
    80006888:	01a70023          	sb	s10,0(a4)
      off += sputc(buf+off, c);
    8000688c:	0014871b          	addiw	a4,s1,1
  *s = c;
    80006890:	975e                	add	a4,a4,s7
    80006892:	00f70023          	sb	a5,0(a4)
      off += sputc(buf+off, c);
    80006896:	2489                	addiw	s1,s1,2
      break;
    80006898:	b719                	j	8000679e <snprintf+0x7c>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...

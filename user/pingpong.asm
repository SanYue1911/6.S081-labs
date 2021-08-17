
user/_pingpong：     文件格式 elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:
#include <kernel/types.h>
#include <user/user.h>

int main(){
   0:	7179                	addi	sp,sp,-48
   2:	f406                	sd	ra,40(sp)
   4:	f022                	sd	s0,32(sp)
   6:	1800                	addi	s0,sp,48

    int p1[2];
    int p2[2];
    char buffer[] = {'X'};
   8:	05800793          	li	a5,88
   c:	fcf40c23          	sb	a5,-40(s0)
    long length = sizeof(buffer);
    pipe(p1);
  10:	fe840513          	addi	a0,s0,-24
  14:	00000097          	auipc	ra,0x0
  18:	3ee080e7          	jalr	1006(ra) # 402 <pipe>
    pipe(p2);
  1c:	fe040513          	addi	a0,s0,-32
  20:	00000097          	auipc	ra,0x0
  24:	3e2080e7          	jalr	994(ra) # 402 <pipe>
    if(fork() == 0){
  28:	00000097          	auipc	ra,0x0
  2c:	3c2080e7          	jalr	962(ra) # 3ea <fork>
  30:	e14d                	bnez	a0,d2 <main+0xd2>
        close(p1[1]);
  32:	fec42503          	lw	a0,-20(s0)
  36:	00000097          	auipc	ra,0x0
  3a:	3e4080e7          	jalr	996(ra) # 41a <close>
        close(p2[0]);
  3e:	fe042503          	lw	a0,-32(s0)
  42:	00000097          	auipc	ra,0x0
  46:	3d8080e7          	jalr	984(ra) # 41a <close>
	if(read(p1[0], buffer, length) != length){
  4a:	4605                	li	a2,1
  4c:	fd840593          	addi	a1,s0,-40
  50:	fe842503          	lw	a0,-24(s0)
  54:	00000097          	auipc	ra,0x0
  58:	3b6080e7          	jalr	950(ra) # 40a <read>
  5c:	4785                	li	a5,1
  5e:	00f50f63          	beq	a0,a5,7c <main+0x7c>
	    printf("a--->b read error!");
  62:	00001517          	auipc	a0,0x1
  66:	8ae50513          	addi	a0,a0,-1874 # 910 <malloc+0xe8>
  6a:	00000097          	auipc	ra,0x0
  6e:	700080e7          	jalr	1792(ra) # 76a <printf>
	    exit(1);
  72:	4505                	li	a0,1
  74:	00000097          	auipc	ra,0x0
  78:	37e080e7          	jalr	894(ra) # 3f2 <exit>
	}
	printf("%d: received ping\n", getpid());
  7c:	00000097          	auipc	ra,0x0
  80:	3f6080e7          	jalr	1014(ra) # 472 <getpid>
  84:	85aa                	mv	a1,a0
  86:	00001517          	auipc	a0,0x1
  8a:	8a250513          	addi	a0,a0,-1886 # 928 <malloc+0x100>
  8e:	00000097          	auipc	ra,0x0
  92:	6dc080e7          	jalr	1756(ra) # 76a <printf>
	if(write(p2[1], buffer, length) != length){
  96:	4605                	li	a2,1
  98:	fd840593          	addi	a1,s0,-40
  9c:	fe442503          	lw	a0,-28(s0)
  a0:	00000097          	auipc	ra,0x0
  a4:	372080e7          	jalr	882(ra) # 412 <write>
  a8:	4785                	li	a5,1
  aa:	00f50f63          	beq	a0,a5,c8 <main+0xc8>
	    printf("a<---b write error!");
  ae:	00001517          	auipc	a0,0x1
  b2:	89250513          	addi	a0,a0,-1902 # 940 <malloc+0x118>
  b6:	00000097          	auipc	ra,0x0
  ba:	6b4080e7          	jalr	1716(ra) # 76a <printf>
	    exit(1);
  be:	4505                	li	a0,1
  c0:	00000097          	auipc	ra,0x0
  c4:	332080e7          	jalr	818(ra) # 3f2 <exit>
	}
        exit(0);
  c8:	4501                	li	a0,0
  ca:	00000097          	auipc	ra,0x0
  ce:	328080e7          	jalr	808(ra) # 3f2 <exit>
    }
    
    close(p1[0]);
  d2:	fe842503          	lw	a0,-24(s0)
  d6:	00000097          	auipc	ra,0x0
  da:	344080e7          	jalr	836(ra) # 41a <close>
    close(p2[1]);
  de:	fe442503          	lw	a0,-28(s0)
  e2:	00000097          	auipc	ra,0x0
  e6:	338080e7          	jalr	824(ra) # 41a <close>
    if(write(p1[1], buffer, length) != length){
  ea:	4605                	li	a2,1
  ec:	fd840593          	addi	a1,s0,-40
  f0:	fec42503          	lw	a0,-20(s0)
  f4:	00000097          	auipc	ra,0x0
  f8:	31e080e7          	jalr	798(ra) # 412 <write>
  fc:	4785                	li	a5,1
  fe:	00f50f63          	beq	a0,a5,11c <main+0x11c>
        printf("a--->b write error!");
 102:	00001517          	auipc	a0,0x1
 106:	85650513          	addi	a0,a0,-1962 # 958 <malloc+0x130>
 10a:	00000097          	auipc	ra,0x0
 10e:	660080e7          	jalr	1632(ra) # 76a <printf>
        exit(1);
 112:	4505                	li	a0,1
 114:	00000097          	auipc	ra,0x0
 118:	2de080e7          	jalr	734(ra) # 3f2 <exit>
    }
    if(read(p2[0], buffer, length) != length){
 11c:	4605                	li	a2,1
 11e:	fd840593          	addi	a1,s0,-40
 122:	fe042503          	lw	a0,-32(s0)
 126:	00000097          	auipc	ra,0x0
 12a:	2e4080e7          	jalr	740(ra) # 40a <read>
 12e:	4785                	li	a5,1
 130:	00f50f63          	beq	a0,a5,14e <main+0x14e>
	printf("a<---b read error!");
 134:	00001517          	auipc	a0,0x1
 138:	83c50513          	addi	a0,a0,-1988 # 970 <malloc+0x148>
 13c:	00000097          	auipc	ra,0x0
 140:	62e080e7          	jalr	1582(ra) # 76a <printf>
	exit(1);
 144:	4505                	li	a0,1
 146:	00000097          	auipc	ra,0x0
 14a:	2ac080e7          	jalr	684(ra) # 3f2 <exit>
    }
    printf("%d: received pong\n", getpid());
 14e:	00000097          	auipc	ra,0x0
 152:	324080e7          	jalr	804(ra) # 472 <getpid>
 156:	85aa                	mv	a1,a0
 158:	00001517          	auipc	a0,0x1
 15c:	83050513          	addi	a0,a0,-2000 # 988 <malloc+0x160>
 160:	00000097          	auipc	ra,0x0
 164:	60a080e7          	jalr	1546(ra) # 76a <printf>
    wait(0);
 168:	4501                	li	a0,0
 16a:	00000097          	auipc	ra,0x0
 16e:	290080e7          	jalr	656(ra) # 3fa <wait>
    exit(0);
 172:	4501                	li	a0,0
 174:	00000097          	auipc	ra,0x0
 178:	27e080e7          	jalr	638(ra) # 3f2 <exit>

000000000000017c <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
 17c:	1141                	addi	sp,sp,-16
 17e:	e422                	sd	s0,8(sp)
 180:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 182:	87aa                	mv	a5,a0
 184:	0585                	addi	a1,a1,1
 186:	0785                	addi	a5,a5,1
 188:	fff5c703          	lbu	a4,-1(a1)
 18c:	fee78fa3          	sb	a4,-1(a5)
 190:	fb75                	bnez	a4,184 <strcpy+0x8>
    ;
  return os;
}
 192:	6422                	ld	s0,8(sp)
 194:	0141                	addi	sp,sp,16
 196:	8082                	ret

0000000000000198 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 198:	1141                	addi	sp,sp,-16
 19a:	e422                	sd	s0,8(sp)
 19c:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 19e:	00054783          	lbu	a5,0(a0)
 1a2:	cb91                	beqz	a5,1b6 <strcmp+0x1e>
 1a4:	0005c703          	lbu	a4,0(a1)
 1a8:	00f71763          	bne	a4,a5,1b6 <strcmp+0x1e>
    p++, q++;
 1ac:	0505                	addi	a0,a0,1
 1ae:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 1b0:	00054783          	lbu	a5,0(a0)
 1b4:	fbe5                	bnez	a5,1a4 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 1b6:	0005c503          	lbu	a0,0(a1)
}
 1ba:	40a7853b          	subw	a0,a5,a0
 1be:	6422                	ld	s0,8(sp)
 1c0:	0141                	addi	sp,sp,16
 1c2:	8082                	ret

00000000000001c4 <strlen>:

uint
strlen(const char *s)
{
 1c4:	1141                	addi	sp,sp,-16
 1c6:	e422                	sd	s0,8(sp)
 1c8:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 1ca:	00054783          	lbu	a5,0(a0)
 1ce:	cf91                	beqz	a5,1ea <strlen+0x26>
 1d0:	0505                	addi	a0,a0,1
 1d2:	87aa                	mv	a5,a0
 1d4:	4685                	li	a3,1
 1d6:	9e89                	subw	a3,a3,a0
 1d8:	00f6853b          	addw	a0,a3,a5
 1dc:	0785                	addi	a5,a5,1
 1de:	fff7c703          	lbu	a4,-1(a5)
 1e2:	fb7d                	bnez	a4,1d8 <strlen+0x14>
    ;
  return n;
}
 1e4:	6422                	ld	s0,8(sp)
 1e6:	0141                	addi	sp,sp,16
 1e8:	8082                	ret
  for(n = 0; s[n]; n++)
 1ea:	4501                	li	a0,0
 1ec:	bfe5                	j	1e4 <strlen+0x20>

00000000000001ee <memset>:

void*
memset(void *dst, int c, uint n)
{
 1ee:	1141                	addi	sp,sp,-16
 1f0:	e422                	sd	s0,8(sp)
 1f2:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 1f4:	ce09                	beqz	a2,20e <memset+0x20>
 1f6:	87aa                	mv	a5,a0
 1f8:	fff6071b          	addiw	a4,a2,-1
 1fc:	1702                	slli	a4,a4,0x20
 1fe:	9301                	srli	a4,a4,0x20
 200:	0705                	addi	a4,a4,1
 202:	972a                	add	a4,a4,a0
    cdst[i] = c;
 204:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 208:	0785                	addi	a5,a5,1
 20a:	fee79de3          	bne	a5,a4,204 <memset+0x16>
  }
  return dst;
}
 20e:	6422                	ld	s0,8(sp)
 210:	0141                	addi	sp,sp,16
 212:	8082                	ret

0000000000000214 <strchr>:

char*
strchr(const char *s, char c)
{
 214:	1141                	addi	sp,sp,-16
 216:	e422                	sd	s0,8(sp)
 218:	0800                	addi	s0,sp,16
  for(; *s; s++)
 21a:	00054783          	lbu	a5,0(a0)
 21e:	cb99                	beqz	a5,234 <strchr+0x20>
    if(*s == c)
 220:	00f58763          	beq	a1,a5,22e <strchr+0x1a>
  for(; *s; s++)
 224:	0505                	addi	a0,a0,1
 226:	00054783          	lbu	a5,0(a0)
 22a:	fbfd                	bnez	a5,220 <strchr+0xc>
      return (char*)s;
  return 0;
 22c:	4501                	li	a0,0
}
 22e:	6422                	ld	s0,8(sp)
 230:	0141                	addi	sp,sp,16
 232:	8082                	ret
  return 0;
 234:	4501                	li	a0,0
 236:	bfe5                	j	22e <strchr+0x1a>

0000000000000238 <gets>:

char*
gets(char *buf, int max)
{
 238:	711d                	addi	sp,sp,-96
 23a:	ec86                	sd	ra,88(sp)
 23c:	e8a2                	sd	s0,80(sp)
 23e:	e4a6                	sd	s1,72(sp)
 240:	e0ca                	sd	s2,64(sp)
 242:	fc4e                	sd	s3,56(sp)
 244:	f852                	sd	s4,48(sp)
 246:	f456                	sd	s5,40(sp)
 248:	f05a                	sd	s6,32(sp)
 24a:	ec5e                	sd	s7,24(sp)
 24c:	1080                	addi	s0,sp,96
 24e:	8baa                	mv	s7,a0
 250:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 252:	892a                	mv	s2,a0
 254:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 256:	4aa9                	li	s5,10
 258:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 25a:	89a6                	mv	s3,s1
 25c:	2485                	addiw	s1,s1,1
 25e:	0344d863          	bge	s1,s4,28e <gets+0x56>
    cc = read(0, &c, 1);
 262:	4605                	li	a2,1
 264:	faf40593          	addi	a1,s0,-81
 268:	4501                	li	a0,0
 26a:	00000097          	auipc	ra,0x0
 26e:	1a0080e7          	jalr	416(ra) # 40a <read>
    if(cc < 1)
 272:	00a05e63          	blez	a0,28e <gets+0x56>
    buf[i++] = c;
 276:	faf44783          	lbu	a5,-81(s0)
 27a:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 27e:	01578763          	beq	a5,s5,28c <gets+0x54>
 282:	0905                	addi	s2,s2,1
 284:	fd679be3          	bne	a5,s6,25a <gets+0x22>
  for(i=0; i+1 < max; ){
 288:	89a6                	mv	s3,s1
 28a:	a011                	j	28e <gets+0x56>
 28c:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 28e:	99de                	add	s3,s3,s7
 290:	00098023          	sb	zero,0(s3)
  return buf;
}
 294:	855e                	mv	a0,s7
 296:	60e6                	ld	ra,88(sp)
 298:	6446                	ld	s0,80(sp)
 29a:	64a6                	ld	s1,72(sp)
 29c:	6906                	ld	s2,64(sp)
 29e:	79e2                	ld	s3,56(sp)
 2a0:	7a42                	ld	s4,48(sp)
 2a2:	7aa2                	ld	s5,40(sp)
 2a4:	7b02                	ld	s6,32(sp)
 2a6:	6be2                	ld	s7,24(sp)
 2a8:	6125                	addi	sp,sp,96
 2aa:	8082                	ret

00000000000002ac <stat>:

int
stat(const char *n, struct stat *st)
{
 2ac:	1101                	addi	sp,sp,-32
 2ae:	ec06                	sd	ra,24(sp)
 2b0:	e822                	sd	s0,16(sp)
 2b2:	e426                	sd	s1,8(sp)
 2b4:	e04a                	sd	s2,0(sp)
 2b6:	1000                	addi	s0,sp,32
 2b8:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 2ba:	4581                	li	a1,0
 2bc:	00000097          	auipc	ra,0x0
 2c0:	176080e7          	jalr	374(ra) # 432 <open>
  if(fd < 0)
 2c4:	02054563          	bltz	a0,2ee <stat+0x42>
 2c8:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 2ca:	85ca                	mv	a1,s2
 2cc:	00000097          	auipc	ra,0x0
 2d0:	17e080e7          	jalr	382(ra) # 44a <fstat>
 2d4:	892a                	mv	s2,a0
  close(fd);
 2d6:	8526                	mv	a0,s1
 2d8:	00000097          	auipc	ra,0x0
 2dc:	142080e7          	jalr	322(ra) # 41a <close>
  return r;
}
 2e0:	854a                	mv	a0,s2
 2e2:	60e2                	ld	ra,24(sp)
 2e4:	6442                	ld	s0,16(sp)
 2e6:	64a2                	ld	s1,8(sp)
 2e8:	6902                	ld	s2,0(sp)
 2ea:	6105                	addi	sp,sp,32
 2ec:	8082                	ret
    return -1;
 2ee:	597d                	li	s2,-1
 2f0:	bfc5                	j	2e0 <stat+0x34>

00000000000002f2 <atoi>:

int
atoi(const char *s)
{
 2f2:	1141                	addi	sp,sp,-16
 2f4:	e422                	sd	s0,8(sp)
 2f6:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 2f8:	00054603          	lbu	a2,0(a0)
 2fc:	fd06079b          	addiw	a5,a2,-48
 300:	0ff7f793          	andi	a5,a5,255
 304:	4725                	li	a4,9
 306:	02f76963          	bltu	a4,a5,338 <atoi+0x46>
 30a:	86aa                	mv	a3,a0
  n = 0;
 30c:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 30e:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 310:	0685                	addi	a3,a3,1
 312:	0025179b          	slliw	a5,a0,0x2
 316:	9fa9                	addw	a5,a5,a0
 318:	0017979b          	slliw	a5,a5,0x1
 31c:	9fb1                	addw	a5,a5,a2
 31e:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 322:	0006c603          	lbu	a2,0(a3)
 326:	fd06071b          	addiw	a4,a2,-48
 32a:	0ff77713          	andi	a4,a4,255
 32e:	fee5f1e3          	bgeu	a1,a4,310 <atoi+0x1e>
  return n;
}
 332:	6422                	ld	s0,8(sp)
 334:	0141                	addi	sp,sp,16
 336:	8082                	ret
  n = 0;
 338:	4501                	li	a0,0
 33a:	bfe5                	j	332 <atoi+0x40>

000000000000033c <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 33c:	1141                	addi	sp,sp,-16
 33e:	e422                	sd	s0,8(sp)
 340:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 342:	02b57663          	bgeu	a0,a1,36e <memmove+0x32>
    while(n-- > 0)
 346:	02c05163          	blez	a2,368 <memmove+0x2c>
 34a:	fff6079b          	addiw	a5,a2,-1
 34e:	1782                	slli	a5,a5,0x20
 350:	9381                	srli	a5,a5,0x20
 352:	0785                	addi	a5,a5,1
 354:	97aa                	add	a5,a5,a0
  dst = vdst;
 356:	872a                	mv	a4,a0
      *dst++ = *src++;
 358:	0585                	addi	a1,a1,1
 35a:	0705                	addi	a4,a4,1
 35c:	fff5c683          	lbu	a3,-1(a1)
 360:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 364:	fee79ae3          	bne	a5,a4,358 <memmove+0x1c>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 368:	6422                	ld	s0,8(sp)
 36a:	0141                	addi	sp,sp,16
 36c:	8082                	ret
    dst += n;
 36e:	00c50733          	add	a4,a0,a2
    src += n;
 372:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 374:	fec05ae3          	blez	a2,368 <memmove+0x2c>
 378:	fff6079b          	addiw	a5,a2,-1
 37c:	1782                	slli	a5,a5,0x20
 37e:	9381                	srli	a5,a5,0x20
 380:	fff7c793          	not	a5,a5
 384:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 386:	15fd                	addi	a1,a1,-1
 388:	177d                	addi	a4,a4,-1
 38a:	0005c683          	lbu	a3,0(a1)
 38e:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 392:	fee79ae3          	bne	a5,a4,386 <memmove+0x4a>
 396:	bfc9                	j	368 <memmove+0x2c>

0000000000000398 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 398:	1141                	addi	sp,sp,-16
 39a:	e422                	sd	s0,8(sp)
 39c:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 39e:	ca05                	beqz	a2,3ce <memcmp+0x36>
 3a0:	fff6069b          	addiw	a3,a2,-1
 3a4:	1682                	slli	a3,a3,0x20
 3a6:	9281                	srli	a3,a3,0x20
 3a8:	0685                	addi	a3,a3,1
 3aa:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 3ac:	00054783          	lbu	a5,0(a0)
 3b0:	0005c703          	lbu	a4,0(a1)
 3b4:	00e79863          	bne	a5,a4,3c4 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 3b8:	0505                	addi	a0,a0,1
    p2++;
 3ba:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 3bc:	fed518e3          	bne	a0,a3,3ac <memcmp+0x14>
  }
  return 0;
 3c0:	4501                	li	a0,0
 3c2:	a019                	j	3c8 <memcmp+0x30>
      return *p1 - *p2;
 3c4:	40e7853b          	subw	a0,a5,a4
}
 3c8:	6422                	ld	s0,8(sp)
 3ca:	0141                	addi	sp,sp,16
 3cc:	8082                	ret
  return 0;
 3ce:	4501                	li	a0,0
 3d0:	bfe5                	j	3c8 <memcmp+0x30>

00000000000003d2 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 3d2:	1141                	addi	sp,sp,-16
 3d4:	e406                	sd	ra,8(sp)
 3d6:	e022                	sd	s0,0(sp)
 3d8:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 3da:	00000097          	auipc	ra,0x0
 3de:	f62080e7          	jalr	-158(ra) # 33c <memmove>
}
 3e2:	60a2                	ld	ra,8(sp)
 3e4:	6402                	ld	s0,0(sp)
 3e6:	0141                	addi	sp,sp,16
 3e8:	8082                	ret

00000000000003ea <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 3ea:	4885                	li	a7,1
 ecall
 3ec:	00000073          	ecall
 ret
 3f0:	8082                	ret

00000000000003f2 <exit>:
.global exit
exit:
 li a7, SYS_exit
 3f2:	4889                	li	a7,2
 ecall
 3f4:	00000073          	ecall
 ret
 3f8:	8082                	ret

00000000000003fa <wait>:
.global wait
wait:
 li a7, SYS_wait
 3fa:	488d                	li	a7,3
 ecall
 3fc:	00000073          	ecall
 ret
 400:	8082                	ret

0000000000000402 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 402:	4891                	li	a7,4
 ecall
 404:	00000073          	ecall
 ret
 408:	8082                	ret

000000000000040a <read>:
.global read
read:
 li a7, SYS_read
 40a:	4895                	li	a7,5
 ecall
 40c:	00000073          	ecall
 ret
 410:	8082                	ret

0000000000000412 <write>:
.global write
write:
 li a7, SYS_write
 412:	48c1                	li	a7,16
 ecall
 414:	00000073          	ecall
 ret
 418:	8082                	ret

000000000000041a <close>:
.global close
close:
 li a7, SYS_close
 41a:	48d5                	li	a7,21
 ecall
 41c:	00000073          	ecall
 ret
 420:	8082                	ret

0000000000000422 <kill>:
.global kill
kill:
 li a7, SYS_kill
 422:	4899                	li	a7,6
 ecall
 424:	00000073          	ecall
 ret
 428:	8082                	ret

000000000000042a <exec>:
.global exec
exec:
 li a7, SYS_exec
 42a:	489d                	li	a7,7
 ecall
 42c:	00000073          	ecall
 ret
 430:	8082                	ret

0000000000000432 <open>:
.global open
open:
 li a7, SYS_open
 432:	48bd                	li	a7,15
 ecall
 434:	00000073          	ecall
 ret
 438:	8082                	ret

000000000000043a <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 43a:	48c5                	li	a7,17
 ecall
 43c:	00000073          	ecall
 ret
 440:	8082                	ret

0000000000000442 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 442:	48c9                	li	a7,18
 ecall
 444:	00000073          	ecall
 ret
 448:	8082                	ret

000000000000044a <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 44a:	48a1                	li	a7,8
 ecall
 44c:	00000073          	ecall
 ret
 450:	8082                	ret

0000000000000452 <link>:
.global link
link:
 li a7, SYS_link
 452:	48cd                	li	a7,19
 ecall
 454:	00000073          	ecall
 ret
 458:	8082                	ret

000000000000045a <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 45a:	48d1                	li	a7,20
 ecall
 45c:	00000073          	ecall
 ret
 460:	8082                	ret

0000000000000462 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 462:	48a5                	li	a7,9
 ecall
 464:	00000073          	ecall
 ret
 468:	8082                	ret

000000000000046a <dup>:
.global dup
dup:
 li a7, SYS_dup
 46a:	48a9                	li	a7,10
 ecall
 46c:	00000073          	ecall
 ret
 470:	8082                	ret

0000000000000472 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 472:	48ad                	li	a7,11
 ecall
 474:	00000073          	ecall
 ret
 478:	8082                	ret

000000000000047a <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 47a:	48b1                	li	a7,12
 ecall
 47c:	00000073          	ecall
 ret
 480:	8082                	ret

0000000000000482 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 482:	48b5                	li	a7,13
 ecall
 484:	00000073          	ecall
 ret
 488:	8082                	ret

000000000000048a <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 48a:	48b9                	li	a7,14
 ecall
 48c:	00000073          	ecall
 ret
 490:	8082                	ret

0000000000000492 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 492:	1101                	addi	sp,sp,-32
 494:	ec06                	sd	ra,24(sp)
 496:	e822                	sd	s0,16(sp)
 498:	1000                	addi	s0,sp,32
 49a:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 49e:	4605                	li	a2,1
 4a0:	fef40593          	addi	a1,s0,-17
 4a4:	00000097          	auipc	ra,0x0
 4a8:	f6e080e7          	jalr	-146(ra) # 412 <write>
}
 4ac:	60e2                	ld	ra,24(sp)
 4ae:	6442                	ld	s0,16(sp)
 4b0:	6105                	addi	sp,sp,32
 4b2:	8082                	ret

00000000000004b4 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 4b4:	7139                	addi	sp,sp,-64
 4b6:	fc06                	sd	ra,56(sp)
 4b8:	f822                	sd	s0,48(sp)
 4ba:	f426                	sd	s1,40(sp)
 4bc:	f04a                	sd	s2,32(sp)
 4be:	ec4e                	sd	s3,24(sp)
 4c0:	0080                	addi	s0,sp,64
 4c2:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 4c4:	c299                	beqz	a3,4ca <printint+0x16>
 4c6:	0805c863          	bltz	a1,556 <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 4ca:	2581                	sext.w	a1,a1
  neg = 0;
 4cc:	4881                	li	a7,0
 4ce:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 4d2:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 4d4:	2601                	sext.w	a2,a2
 4d6:	00000517          	auipc	a0,0x0
 4da:	4d250513          	addi	a0,a0,1234 # 9a8 <digits>
 4de:	883a                	mv	a6,a4
 4e0:	2705                	addiw	a4,a4,1
 4e2:	02c5f7bb          	remuw	a5,a1,a2
 4e6:	1782                	slli	a5,a5,0x20
 4e8:	9381                	srli	a5,a5,0x20
 4ea:	97aa                	add	a5,a5,a0
 4ec:	0007c783          	lbu	a5,0(a5)
 4f0:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 4f4:	0005879b          	sext.w	a5,a1
 4f8:	02c5d5bb          	divuw	a1,a1,a2
 4fc:	0685                	addi	a3,a3,1
 4fe:	fec7f0e3          	bgeu	a5,a2,4de <printint+0x2a>
  if(neg)
 502:	00088b63          	beqz	a7,518 <printint+0x64>
    buf[i++] = '-';
 506:	fd040793          	addi	a5,s0,-48
 50a:	973e                	add	a4,a4,a5
 50c:	02d00793          	li	a5,45
 510:	fef70823          	sb	a5,-16(a4)
 514:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 518:	02e05863          	blez	a4,548 <printint+0x94>
 51c:	fc040793          	addi	a5,s0,-64
 520:	00e78933          	add	s2,a5,a4
 524:	fff78993          	addi	s3,a5,-1
 528:	99ba                	add	s3,s3,a4
 52a:	377d                	addiw	a4,a4,-1
 52c:	1702                	slli	a4,a4,0x20
 52e:	9301                	srli	a4,a4,0x20
 530:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 534:	fff94583          	lbu	a1,-1(s2)
 538:	8526                	mv	a0,s1
 53a:	00000097          	auipc	ra,0x0
 53e:	f58080e7          	jalr	-168(ra) # 492 <putc>
  while(--i >= 0)
 542:	197d                	addi	s2,s2,-1
 544:	ff3918e3          	bne	s2,s3,534 <printint+0x80>
}
 548:	70e2                	ld	ra,56(sp)
 54a:	7442                	ld	s0,48(sp)
 54c:	74a2                	ld	s1,40(sp)
 54e:	7902                	ld	s2,32(sp)
 550:	69e2                	ld	s3,24(sp)
 552:	6121                	addi	sp,sp,64
 554:	8082                	ret
    x = -xx;
 556:	40b005bb          	negw	a1,a1
    neg = 1;
 55a:	4885                	li	a7,1
    x = -xx;
 55c:	bf8d                	j	4ce <printint+0x1a>

000000000000055e <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 55e:	7119                	addi	sp,sp,-128
 560:	fc86                	sd	ra,120(sp)
 562:	f8a2                	sd	s0,112(sp)
 564:	f4a6                	sd	s1,104(sp)
 566:	f0ca                	sd	s2,96(sp)
 568:	ecce                	sd	s3,88(sp)
 56a:	e8d2                	sd	s4,80(sp)
 56c:	e4d6                	sd	s5,72(sp)
 56e:	e0da                	sd	s6,64(sp)
 570:	fc5e                	sd	s7,56(sp)
 572:	f862                	sd	s8,48(sp)
 574:	f466                	sd	s9,40(sp)
 576:	f06a                	sd	s10,32(sp)
 578:	ec6e                	sd	s11,24(sp)
 57a:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 57c:	0005c903          	lbu	s2,0(a1)
 580:	18090f63          	beqz	s2,71e <vprintf+0x1c0>
 584:	8aaa                	mv	s5,a0
 586:	8b32                	mv	s6,a2
 588:	00158493          	addi	s1,a1,1
  state = 0;
 58c:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 58e:	02500a13          	li	s4,37
      if(c == 'd'){
 592:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 596:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 59a:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 59e:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 5a2:	00000b97          	auipc	s7,0x0
 5a6:	406b8b93          	addi	s7,s7,1030 # 9a8 <digits>
 5aa:	a839                	j	5c8 <vprintf+0x6a>
        putc(fd, c);
 5ac:	85ca                	mv	a1,s2
 5ae:	8556                	mv	a0,s5
 5b0:	00000097          	auipc	ra,0x0
 5b4:	ee2080e7          	jalr	-286(ra) # 492 <putc>
 5b8:	a019                	j	5be <vprintf+0x60>
    } else if(state == '%'){
 5ba:	01498f63          	beq	s3,s4,5d8 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 5be:	0485                	addi	s1,s1,1
 5c0:	fff4c903          	lbu	s2,-1(s1)
 5c4:	14090d63          	beqz	s2,71e <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 5c8:	0009079b          	sext.w	a5,s2
    if(state == 0){
 5cc:	fe0997e3          	bnez	s3,5ba <vprintf+0x5c>
      if(c == '%'){
 5d0:	fd479ee3          	bne	a5,s4,5ac <vprintf+0x4e>
        state = '%';
 5d4:	89be                	mv	s3,a5
 5d6:	b7e5                	j	5be <vprintf+0x60>
      if(c == 'd'){
 5d8:	05878063          	beq	a5,s8,618 <vprintf+0xba>
      } else if(c == 'l') {
 5dc:	05978c63          	beq	a5,s9,634 <vprintf+0xd6>
      } else if(c == 'x') {
 5e0:	07a78863          	beq	a5,s10,650 <vprintf+0xf2>
      } else if(c == 'p') {
 5e4:	09b78463          	beq	a5,s11,66c <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 5e8:	07300713          	li	a4,115
 5ec:	0ce78663          	beq	a5,a4,6b8 <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 5f0:	06300713          	li	a4,99
 5f4:	0ee78e63          	beq	a5,a4,6f0 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 5f8:	11478863          	beq	a5,s4,708 <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 5fc:	85d2                	mv	a1,s4
 5fe:	8556                	mv	a0,s5
 600:	00000097          	auipc	ra,0x0
 604:	e92080e7          	jalr	-366(ra) # 492 <putc>
        putc(fd, c);
 608:	85ca                	mv	a1,s2
 60a:	8556                	mv	a0,s5
 60c:	00000097          	auipc	ra,0x0
 610:	e86080e7          	jalr	-378(ra) # 492 <putc>
      }
      state = 0;
 614:	4981                	li	s3,0
 616:	b765                	j	5be <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 618:	008b0913          	addi	s2,s6,8
 61c:	4685                	li	a3,1
 61e:	4629                	li	a2,10
 620:	000b2583          	lw	a1,0(s6)
 624:	8556                	mv	a0,s5
 626:	00000097          	auipc	ra,0x0
 62a:	e8e080e7          	jalr	-370(ra) # 4b4 <printint>
 62e:	8b4a                	mv	s6,s2
      state = 0;
 630:	4981                	li	s3,0
 632:	b771                	j	5be <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 634:	008b0913          	addi	s2,s6,8
 638:	4681                	li	a3,0
 63a:	4629                	li	a2,10
 63c:	000b2583          	lw	a1,0(s6)
 640:	8556                	mv	a0,s5
 642:	00000097          	auipc	ra,0x0
 646:	e72080e7          	jalr	-398(ra) # 4b4 <printint>
 64a:	8b4a                	mv	s6,s2
      state = 0;
 64c:	4981                	li	s3,0
 64e:	bf85                	j	5be <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 650:	008b0913          	addi	s2,s6,8
 654:	4681                	li	a3,0
 656:	4641                	li	a2,16
 658:	000b2583          	lw	a1,0(s6)
 65c:	8556                	mv	a0,s5
 65e:	00000097          	auipc	ra,0x0
 662:	e56080e7          	jalr	-426(ra) # 4b4 <printint>
 666:	8b4a                	mv	s6,s2
      state = 0;
 668:	4981                	li	s3,0
 66a:	bf91                	j	5be <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 66c:	008b0793          	addi	a5,s6,8
 670:	f8f43423          	sd	a5,-120(s0)
 674:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 678:	03000593          	li	a1,48
 67c:	8556                	mv	a0,s5
 67e:	00000097          	auipc	ra,0x0
 682:	e14080e7          	jalr	-492(ra) # 492 <putc>
  putc(fd, 'x');
 686:	85ea                	mv	a1,s10
 688:	8556                	mv	a0,s5
 68a:	00000097          	auipc	ra,0x0
 68e:	e08080e7          	jalr	-504(ra) # 492 <putc>
 692:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 694:	03c9d793          	srli	a5,s3,0x3c
 698:	97de                	add	a5,a5,s7
 69a:	0007c583          	lbu	a1,0(a5)
 69e:	8556                	mv	a0,s5
 6a0:	00000097          	auipc	ra,0x0
 6a4:	df2080e7          	jalr	-526(ra) # 492 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 6a8:	0992                	slli	s3,s3,0x4
 6aa:	397d                	addiw	s2,s2,-1
 6ac:	fe0914e3          	bnez	s2,694 <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 6b0:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 6b4:	4981                	li	s3,0
 6b6:	b721                	j	5be <vprintf+0x60>
        s = va_arg(ap, char*);
 6b8:	008b0993          	addi	s3,s6,8
 6bc:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 6c0:	02090163          	beqz	s2,6e2 <vprintf+0x184>
        while(*s != 0){
 6c4:	00094583          	lbu	a1,0(s2)
 6c8:	c9a1                	beqz	a1,718 <vprintf+0x1ba>
          putc(fd, *s);
 6ca:	8556                	mv	a0,s5
 6cc:	00000097          	auipc	ra,0x0
 6d0:	dc6080e7          	jalr	-570(ra) # 492 <putc>
          s++;
 6d4:	0905                	addi	s2,s2,1
        while(*s != 0){
 6d6:	00094583          	lbu	a1,0(s2)
 6da:	f9e5                	bnez	a1,6ca <vprintf+0x16c>
        s = va_arg(ap, char*);
 6dc:	8b4e                	mv	s6,s3
      state = 0;
 6de:	4981                	li	s3,0
 6e0:	bdf9                	j	5be <vprintf+0x60>
          s = "(null)";
 6e2:	00000917          	auipc	s2,0x0
 6e6:	2be90913          	addi	s2,s2,702 # 9a0 <malloc+0x178>
        while(*s != 0){
 6ea:	02800593          	li	a1,40
 6ee:	bff1                	j	6ca <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 6f0:	008b0913          	addi	s2,s6,8
 6f4:	000b4583          	lbu	a1,0(s6)
 6f8:	8556                	mv	a0,s5
 6fa:	00000097          	auipc	ra,0x0
 6fe:	d98080e7          	jalr	-616(ra) # 492 <putc>
 702:	8b4a                	mv	s6,s2
      state = 0;
 704:	4981                	li	s3,0
 706:	bd65                	j	5be <vprintf+0x60>
        putc(fd, c);
 708:	85d2                	mv	a1,s4
 70a:	8556                	mv	a0,s5
 70c:	00000097          	auipc	ra,0x0
 710:	d86080e7          	jalr	-634(ra) # 492 <putc>
      state = 0;
 714:	4981                	li	s3,0
 716:	b565                	j	5be <vprintf+0x60>
        s = va_arg(ap, char*);
 718:	8b4e                	mv	s6,s3
      state = 0;
 71a:	4981                	li	s3,0
 71c:	b54d                	j	5be <vprintf+0x60>
    }
  }
}
 71e:	70e6                	ld	ra,120(sp)
 720:	7446                	ld	s0,112(sp)
 722:	74a6                	ld	s1,104(sp)
 724:	7906                	ld	s2,96(sp)
 726:	69e6                	ld	s3,88(sp)
 728:	6a46                	ld	s4,80(sp)
 72a:	6aa6                	ld	s5,72(sp)
 72c:	6b06                	ld	s6,64(sp)
 72e:	7be2                	ld	s7,56(sp)
 730:	7c42                	ld	s8,48(sp)
 732:	7ca2                	ld	s9,40(sp)
 734:	7d02                	ld	s10,32(sp)
 736:	6de2                	ld	s11,24(sp)
 738:	6109                	addi	sp,sp,128
 73a:	8082                	ret

000000000000073c <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 73c:	715d                	addi	sp,sp,-80
 73e:	ec06                	sd	ra,24(sp)
 740:	e822                	sd	s0,16(sp)
 742:	1000                	addi	s0,sp,32
 744:	e010                	sd	a2,0(s0)
 746:	e414                	sd	a3,8(s0)
 748:	e818                	sd	a4,16(s0)
 74a:	ec1c                	sd	a5,24(s0)
 74c:	03043023          	sd	a6,32(s0)
 750:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 754:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 758:	8622                	mv	a2,s0
 75a:	00000097          	auipc	ra,0x0
 75e:	e04080e7          	jalr	-508(ra) # 55e <vprintf>
}
 762:	60e2                	ld	ra,24(sp)
 764:	6442                	ld	s0,16(sp)
 766:	6161                	addi	sp,sp,80
 768:	8082                	ret

000000000000076a <printf>:

void
printf(const char *fmt, ...)
{
 76a:	711d                	addi	sp,sp,-96
 76c:	ec06                	sd	ra,24(sp)
 76e:	e822                	sd	s0,16(sp)
 770:	1000                	addi	s0,sp,32
 772:	e40c                	sd	a1,8(s0)
 774:	e810                	sd	a2,16(s0)
 776:	ec14                	sd	a3,24(s0)
 778:	f018                	sd	a4,32(s0)
 77a:	f41c                	sd	a5,40(s0)
 77c:	03043823          	sd	a6,48(s0)
 780:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 784:	00840613          	addi	a2,s0,8
 788:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 78c:	85aa                	mv	a1,a0
 78e:	4505                	li	a0,1
 790:	00000097          	auipc	ra,0x0
 794:	dce080e7          	jalr	-562(ra) # 55e <vprintf>
}
 798:	60e2                	ld	ra,24(sp)
 79a:	6442                	ld	s0,16(sp)
 79c:	6125                	addi	sp,sp,96
 79e:	8082                	ret

00000000000007a0 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 7a0:	1141                	addi	sp,sp,-16
 7a2:	e422                	sd	s0,8(sp)
 7a4:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 7a6:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 7aa:	00000797          	auipc	a5,0x0
 7ae:	2167b783          	ld	a5,534(a5) # 9c0 <freep>
 7b2:	a805                	j	7e2 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 7b4:	4618                	lw	a4,8(a2)
 7b6:	9db9                	addw	a1,a1,a4
 7b8:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 7bc:	6398                	ld	a4,0(a5)
 7be:	6318                	ld	a4,0(a4)
 7c0:	fee53823          	sd	a4,-16(a0)
 7c4:	a091                	j	808 <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 7c6:	ff852703          	lw	a4,-8(a0)
 7ca:	9e39                	addw	a2,a2,a4
 7cc:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 7ce:	ff053703          	ld	a4,-16(a0)
 7d2:	e398                	sd	a4,0(a5)
 7d4:	a099                	j	81a <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 7d6:	6398                	ld	a4,0(a5)
 7d8:	00e7e463          	bltu	a5,a4,7e0 <free+0x40>
 7dc:	00e6ea63          	bltu	a3,a4,7f0 <free+0x50>
{
 7e0:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 7e2:	fed7fae3          	bgeu	a5,a3,7d6 <free+0x36>
 7e6:	6398                	ld	a4,0(a5)
 7e8:	00e6e463          	bltu	a3,a4,7f0 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 7ec:	fee7eae3          	bltu	a5,a4,7e0 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 7f0:	ff852583          	lw	a1,-8(a0)
 7f4:	6390                	ld	a2,0(a5)
 7f6:	02059713          	slli	a4,a1,0x20
 7fa:	9301                	srli	a4,a4,0x20
 7fc:	0712                	slli	a4,a4,0x4
 7fe:	9736                	add	a4,a4,a3
 800:	fae60ae3          	beq	a2,a4,7b4 <free+0x14>
    bp->s.ptr = p->s.ptr;
 804:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 808:	4790                	lw	a2,8(a5)
 80a:	02061713          	slli	a4,a2,0x20
 80e:	9301                	srli	a4,a4,0x20
 810:	0712                	slli	a4,a4,0x4
 812:	973e                	add	a4,a4,a5
 814:	fae689e3          	beq	a3,a4,7c6 <free+0x26>
  } else
    p->s.ptr = bp;
 818:	e394                	sd	a3,0(a5)
  freep = p;
 81a:	00000717          	auipc	a4,0x0
 81e:	1af73323          	sd	a5,422(a4) # 9c0 <freep>
}
 822:	6422                	ld	s0,8(sp)
 824:	0141                	addi	sp,sp,16
 826:	8082                	ret

0000000000000828 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 828:	7139                	addi	sp,sp,-64
 82a:	fc06                	sd	ra,56(sp)
 82c:	f822                	sd	s0,48(sp)
 82e:	f426                	sd	s1,40(sp)
 830:	f04a                	sd	s2,32(sp)
 832:	ec4e                	sd	s3,24(sp)
 834:	e852                	sd	s4,16(sp)
 836:	e456                	sd	s5,8(sp)
 838:	e05a                	sd	s6,0(sp)
 83a:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 83c:	02051493          	slli	s1,a0,0x20
 840:	9081                	srli	s1,s1,0x20
 842:	04bd                	addi	s1,s1,15
 844:	8091                	srli	s1,s1,0x4
 846:	0014899b          	addiw	s3,s1,1
 84a:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 84c:	00000517          	auipc	a0,0x0
 850:	17453503          	ld	a0,372(a0) # 9c0 <freep>
 854:	c515                	beqz	a0,880 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 856:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 858:	4798                	lw	a4,8(a5)
 85a:	02977f63          	bgeu	a4,s1,898 <malloc+0x70>
 85e:	8a4e                	mv	s4,s3
 860:	0009871b          	sext.w	a4,s3
 864:	6685                	lui	a3,0x1
 866:	00d77363          	bgeu	a4,a3,86c <malloc+0x44>
 86a:	6a05                	lui	s4,0x1
 86c:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 870:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 874:	00000917          	auipc	s2,0x0
 878:	14c90913          	addi	s2,s2,332 # 9c0 <freep>
  if(p == (char*)-1)
 87c:	5afd                	li	s5,-1
 87e:	a88d                	j	8f0 <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 880:	00000797          	auipc	a5,0x0
 884:	14878793          	addi	a5,a5,328 # 9c8 <base>
 888:	00000717          	auipc	a4,0x0
 88c:	12f73c23          	sd	a5,312(a4) # 9c0 <freep>
 890:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 892:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 896:	b7e1                	j	85e <malloc+0x36>
      if(p->s.size == nunits)
 898:	02e48b63          	beq	s1,a4,8ce <malloc+0xa6>
        p->s.size -= nunits;
 89c:	4137073b          	subw	a4,a4,s3
 8a0:	c798                	sw	a4,8(a5)
        p += p->s.size;
 8a2:	1702                	slli	a4,a4,0x20
 8a4:	9301                	srli	a4,a4,0x20
 8a6:	0712                	slli	a4,a4,0x4
 8a8:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 8aa:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 8ae:	00000717          	auipc	a4,0x0
 8b2:	10a73923          	sd	a0,274(a4) # 9c0 <freep>
      return (void*)(p + 1);
 8b6:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 8ba:	70e2                	ld	ra,56(sp)
 8bc:	7442                	ld	s0,48(sp)
 8be:	74a2                	ld	s1,40(sp)
 8c0:	7902                	ld	s2,32(sp)
 8c2:	69e2                	ld	s3,24(sp)
 8c4:	6a42                	ld	s4,16(sp)
 8c6:	6aa2                	ld	s5,8(sp)
 8c8:	6b02                	ld	s6,0(sp)
 8ca:	6121                	addi	sp,sp,64
 8cc:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 8ce:	6398                	ld	a4,0(a5)
 8d0:	e118                	sd	a4,0(a0)
 8d2:	bff1                	j	8ae <malloc+0x86>
  hp->s.size = nu;
 8d4:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 8d8:	0541                	addi	a0,a0,16
 8da:	00000097          	auipc	ra,0x0
 8de:	ec6080e7          	jalr	-314(ra) # 7a0 <free>
  return freep;
 8e2:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 8e6:	d971                	beqz	a0,8ba <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 8e8:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 8ea:	4798                	lw	a4,8(a5)
 8ec:	fa9776e3          	bgeu	a4,s1,898 <malloc+0x70>
    if(p == freep)
 8f0:	00093703          	ld	a4,0(s2)
 8f4:	853e                	mv	a0,a5
 8f6:	fef719e3          	bne	a4,a5,8e8 <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 8fa:	8552                	mv	a0,s4
 8fc:	00000097          	auipc	ra,0x0
 900:	b7e080e7          	jalr	-1154(ra) # 47a <sbrk>
  if(p == (char*)-1)
 904:	fd5518e3          	bne	a0,s5,8d4 <malloc+0xac>
        return 0;
 908:	4501                	li	a0,0
 90a:	bf45                	j	8ba <malloc+0x92>

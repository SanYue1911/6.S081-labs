// Buffer cache.
//
// The buffer cache is a linked list of buf structures holding
// cached copies of disk block contents.  Caching disk blocks
// in memory reduces the number of disk reads and also provides
// a synchronization point for disk blocks used by multiple processes.
//
// Interface:
// * To get a buffer for a particular disk block, call bread.
// * After changing buffer data, call bwrite to write it to disk.
// * When done with the buffer, call brelse.
// * Do not use the buffer after calling brelse.
// * Only one process at a time can use a buffer,
//     so do not keep them longer than necessary.


#include "types.h"
#include "param.h"
#include "spinlock.h"
#include "sleeplock.h"
#include "riscv.h"
#include "defs.h"
#include "fs.h"
#include "buf.h"
#define NBUC 13

struct {
  struct spinlock lock;
  struct buf buf[NBUF];

  // Linked list of all buffers, through prev/next.
  // Sorted by how recently the buffer was used.
  // head.next is most recent, head.prev is least.
  //struct buf head;
} bcache;

struct bmem{
  struct spinlock lock;
  struct buf head;
};

static struct bmem hashtable[NBUC];

void
binit(void)
{
  struct buf *b;

  initlock(&bcache.lock, "bcache");
/*
  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
  bcache.head.next = &bcache.head;
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    b->next = bcache.head.next;
    b->prev = &bcache.head;
    initsleeplock(&b->lock, "buffer");
    bcache.head.next->prev = b;
    bcache.head.next = b;
  }
*/
  for(int i = 0; i < NBUC; i++){
    initlock(&(hashtable[i].lock),"bcache.bucket");
  }
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    initsleeplock(&b->lock,"buffer");
  }
}

void replacebuffer(struct buf *lrubuf, uint dev, uint blockno, uint ticks){
  lrubuf->dev = dev;
  lrubuf->blockno = blockno; 
  lrubuf->valid = 0;
  lrubuf->refcnt = 1;
  lrubuf->tick = ticks;
}

// Look through buffer cache for block on device dev.
// If not found, allocate a buffer.
// In either case, return locked buffer.
/*static struct buf*
bget(uint dev, uint blockno)
{
  struct buf *b;

  acquire(&bcache.lock);

  // Is the block already cached?
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    if(b->dev == dev && b->blockno == blockno){
      b->refcnt++;
      release(&bcache.lock);
      acquiresleep(&b->lock);
      return b;
    }
  }

  // Not cached.
  // Recycle the least recently used (LRU) unused buffer.
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    if(b->refcnt == 0) {
      b->dev = dev;
      b->blockno = blockno;
      b->valid = 0;
      b->refcnt = 1;
      release(&bcache.lock);
      acquiresleep(&b->lock);
      return b;
    }
  }
  panic("bget: no buffers");
}*/

static struct buf*
bget(uint dev, uint blockno)
{
  struct buf *b;
  struct buf *lastBuf;

  // Is the block already cached?
  uint64 num = blockno%NBUC;
  acquire(&(hashtable[num].lock));
  for(b = hashtable[num].head.next, lastBuf = &(hashtable[num].head); b; b = b->next){
	if (!(b->next)){
      lastBuf = b;
	}
	if(b->dev == dev && b->blockno == blockno){
	  b->refcnt++;
	  release(&(hashtable[num].lock));
	  acquiresleep(&b->lock);
	  return b;
	}
  }

  struct buf *lruBuf = 0;
  acquire(&bcache.lock);
  for(b = bcache.buf; b < bcache.buf + NBUF; b++){
    if(b->refcnt == 0) {
      if (lruBuf == 0){
        lruBuf = b;
	    continue;
	  }
	  if (b->tick < lruBuf->tick){
	    lruBuf = b;
	  }
	}
  }

  if (lruBuf){
    uint64 oldTick = lruBuf->tick;
    uint64 oldNum = (lruBuf->blockno)%NBUC;
	if(oldTick == 0){
	  replacebuffer(lruBuf, dev, blockno, ticks);
	  lastBuf->next = lruBuf;
	  lruBuf->prev = lastBuf;
	}else {
	  if (oldNum != num){
	    acquire(&(hashtable[oldNum].lock));
	    replacebuffer(lruBuf, dev, blockno, ticks);
	    lruBuf->prev->next = lruBuf->next;
	    if (lruBuf->next){
		  lruBuf->next->prev = lruBuf->prev;
		}
		release(&(hashtable[oldNum].lock));
		lastBuf->next = lruBuf;
		lruBuf->prev = lastBuf;
		lruBuf->next = 0;
		}else {
		  replacebuffer(lruBuf, dev, blockno, ticks);
		}
	}
	release(&bcache.lock);
	release(&(hashtable[num].lock));
	acquiresleep(&lruBuf->lock);
	return lruBuf;
  }
  panic("bget: no buffers");
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
  if(!holdingsleep(&b->lock))
    panic("bwrite");
  virtio_disk_rw(b, 1);
}

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
  if(!holdingsleep(&b->lock))
    panic("brelse");

  releasesleep(&b->lock);

  /*acquire(&bcache.lock);
  b->refcnt--;
  if (b->refcnt == 0) {
    // no one is waiting for it.
    b->next->prev = b->prev;
    b->prev->next = b->next;
    b->next = bcache.head.next;
    b->prev = &bcache.head;
    bcache.head.next->prev = b;
    bcache.head.next = b;
  }*/
  uint64 num = b->blockno % NBUC;
  acquire(&(hashtable[num].lock));
  b->refcnt--;
  release(&(hashtable[num].lock));
}

void
bpin(struct buf *b) {
  uint64 num = b->blockno % NBUC;
  acquire(&(hashtable[num].lock));
  b->refcnt++;
  release(&(hashtable[num].lock));
}

void
bunpin(struct buf *b) {
  uint64 num = b->blockno % NBUC;
  acquire(&(hashtable[num].lock));
  b->refcnt--;
  release(&(hashtable[num].lock));

}



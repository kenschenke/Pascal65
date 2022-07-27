#ifndef __MEGA65_MEMORY_H
#define __MEGA65_MEMORY_H

struct dmagic_dmalist
{
  // Enhanced DMA options
  unsigned char option_0b;
  unsigned char option_80;
  unsigned char source_mb;
  unsigned char option_81;
  unsigned char dest_mb;
  unsigned char option_85;
  unsigned char dest_skip;
  unsigned char end_of_options;

  // F018B format DMA request
  unsigned char command;
  unsigned int count;
  unsigned int source_addr;
  unsigned char source_bank;
  unsigned int dest_addr;
  unsigned char dest_bank;
  unsigned char sub_cmd; // F018B subcmd
  unsigned int modulo;
};

extern struct dmagic_dmalist dmalist;
extern unsigned char dma_byte;

void mega65_io_enable(void);
unsigned char lpeek(long address);
unsigned char lpeek_debounced(long address);
void lpoke(long address, unsigned char value);
void lcopy(long source_address, long destination_address,
           unsigned int count);
void lfill(long destination_address, unsigned char value,
           unsigned int count);
void lfill_skip(long destination_address, unsigned char value,
                unsigned int count, unsigned char skip);
#ifdef __CC65__
#define POKE(X, Y) (*(unsigned char *)(X)) = Y
#define PEEK(X) (*(unsigned char *)(X))
#else
#define POKE(X, Y)
#define PEEK(X)
#endif

#endif

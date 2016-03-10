// $Id: BlinkToRadio.h,v 1.4 2006-12-12 18:22:52 vlahan Exp $

#ifndef BLINKTORADIO_H
#define BLINKTORADIO_H

enum {
	AM_BLINKTORADIO = 6,
	TIMER_PERIOD_MILLI = 1000
};

typedef nx_struct RssiMsg{
  nx_int16_t rssi;
  uint_16 ID_esclavo;
} RssiMsg;

#endif

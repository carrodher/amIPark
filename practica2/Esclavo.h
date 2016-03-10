// $Id: BlinkToRadio.h,v 1.4 2006-12-12 18:22:52 vlahan Exp $

#ifndef ESCLAVO_H
#define ESCLAVO_H

enum {
	AM_BLINKTORADIO = 6,

};

typedef nx_struct RssiMsg{
  nx_int16_t rssi;
  uint_16 id_esclavo;
} RssiMsg;

#endif

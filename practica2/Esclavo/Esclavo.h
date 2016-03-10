#ifndef ESCLAVO_H
#define ESCLAVO_H

enum {
	AM_ESCLAVO = 13,
	MAESTRO_ID = 131,
  	ESCLAVO_ID = 132
};

typedef nx_struct MaestroMsg {
	nx_uint16_t ID_maestro;
} MaestroMsg;

typedef nx_struct EsclavoMsg {
	nx_uint16_t ID_esclavo;
	nx_uint16_t medidaRssi;
} EsclavoMsg;

#endif
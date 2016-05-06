#ifndef MOVIL_H
#define MOVIL_H

enum {
	TIMER_PERIOD_MILLI 	= 5000,
	AM_MOVIL 			= 13,
	MOVIL_ID 			= 130,
	FIJO1_ID    		= 131,
	FIJO2_ID    		= 132,
	FIJO3_ID    		= 133,
	SLOTS				= 5
};

typedef nx_struct MovilMsg {
	nx_uint16_t ID_movil;		// ID maestro = ID origen
	nx_uint16_t Tslot;			// Tiempo de slot
	nx_uint16_t first;			// 1º slot para este esclavo
	nx_uint16_t second;			// 2º slot para este esclavo
	nx_uint16_t third;			// 3º slot para este esclavo
	nx_uint16_t fourth;			// 4º slot para este esclavo
} MovilMsg;

typedef nx_struct FijoMsg {
	nx_uint16_t ID_fijo;		// ID fijo = ID origen
	nx_int16_t medidaRssi;		// Valor de la medida RSSI
	nx_uint16_t x;				// Valor de la coordenada X del fijo
	nx_uint16_t y;				// Valor de la coordenada Y del fijo
} FijoMsg;

typedef nx_struct LocationMsg {
	nx_uint16_t ID_movil;		// ID movil = ID origen
	nx_uint16_t coorX;			// Valor de la coordenada X del movil calculada
	nx_uint16_t coorY;			// Valor de la coordenada Y del movil calculada
  nx_uint16_t distance1;
  nx_uint16_t distance2;
  nx_uint16_t distance3;
} LocationMsg;

#endif

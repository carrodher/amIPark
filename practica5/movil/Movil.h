#ifndef MOVIL_H
#define MOVIL_H

enum {
	TIMER_PERIOD_MILLI 	= 5000,
	AM_MOVIL 			= 13,
	MOVIL_ID 			= 130,
	FIJO1_ID   			= 131,
	FIJO2_ID  			= 132,
	FIJO3_ID   			= 133,
	SLOTS				= 5,
	COOR1_X				= 0,
	COOR1_Y				= 0,
	COOR2_X				= 2,
	COOR2_Y				= 0,
	COOR3_X				= 1,
	COOR3_Y				= 1
};

typedef nx_struct MovilMsg {
	nx_uint16_t ID_movil;		// ID movil = ID origen
	nx_uint16_t Tslot;			// Tiempo de slot
	nx_uint16_t first;			// 1º slot para este fijo
	nx_uint16_t second;			// 2º slot para este fijo
	nx_uint16_t third;			// 3º slot para este fijo
	nx_uint16_t fourth;			// 4º slot para el móvil
} MovilMsg;

typedef nx_struct FijoMsg {
	nx_uint16_t ID_fijo;		// ID fijo = ID origen
	nx_int16_t medidaRssi;		// Valor de la medida RSSI
	nx_uint16_t x;				// Coordenada X
	nx_uint16_t y;				// Coordenada Y
} FijoMsg;

typedef nx_struct LocationMsg {
	nx_uint16_t ID_movil;		// ID movil = ID origen
	nx_int16_t coorX;			// Coordenada X
	nx_int16_t coorY;			// Coordenada Y
} LocationMsg;

#endif

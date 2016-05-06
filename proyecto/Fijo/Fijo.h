#ifndef FIJO1_H
#define FIJO1_H

enum {
	TIMER_PERIOD_MILLI = 5000,
	SLOTS     = 5,

	AM_FIJO   = 13,

	MOVIL_ID  = 130,
	FIJO1_ID  = 131,
	FIJO2_ID  = 132,
	FIJO3_ID  = 133,

	FIJO1_X   = 0,    //   [Y]
	FIJO1_Y   = 0,    //    |
	FIJO2_X   = 2,    //    |     (3)
	FIJO2_Y   = 0,    //    |
	FIJO3_X   = 1,    //    |
	FIJO3_Y   = 1     //   (1)-----------(2)----------[X]
};

typedef nx_struct MovilMsg {
	nx_uint16_t ID_movil;		  // ID movil = ID origen
	nx_uint16_t Tslot;			  // Tiempo de slot
	nx_uint16_t first;			  // 1º slot para este fijo
	nx_uint16_t second;			  // 2º slot para este fijo
	nx_uint16_t third;			  // 3º slot para este fijo
	nx_uint16_t fourth;			  // 4º slot para el móvil
} MovilMsg;

typedef nx_struct FijoMsg {
	nx_uint16_t ID_fijo;		  // ID fijo = ID origen
	nx_int16_t  medidaRssi;		// Valor de la medida RSSI
	nx_uint16_t x;				    // Coordenada X
	nx_uint16_t y;				    // Coordenada Y
} FijoMsg;

#endif

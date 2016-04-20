#ifndef FIJO_H
#define FIJO_H

enum {
	TIMER_PERIOD_MILLI 	= 5000,
	AM_FIJO 			= 13,
	MOVIL_ID 			= 130,
	FIJO1_ID   			= 131,
	FIJO2_ID  			= 132,
	FIJO3_ID   			= 133,
	SLOTS				= 5
};

typedef nx_struct MovilMsg {
	nx_uint16_t ID_movil;		// ID movil = ID origen
	nx_uint16_t Tslot;			// Tiempo de slot
	nx_uint16_t first;			// 1º slot para este fijo
	nx_uint16_t second;			// 2º slot para este fijo
	nx_uint16_t third;			// 3º slot para este fijo
	nx_uint16_t fourth;			// 3º slot para el móvil
} MovilMsg;

typedef nx_struct FijoMsg {
	nx_uint16_t ID_fijo;		// ID fijo = ID origen
	nx_int16_t medidaRssi;		// Valor de la medida RSSI
} FijoMsg;

#endif

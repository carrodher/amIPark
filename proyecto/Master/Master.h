#ifndef MASTER_H
#define MASTER_H

enum {
	TIMER_PERIOD_MILLI 		= 5000,
	TIEMPO_ROJO_ENCENDIDO 	= 5000, 	//timer para led rojo encendido si no encuentra aparcamiento libre
	AM_MASTER				= 13,
	MOVIL_ID 				= 130,
	FIJO1_ID  		  		= 131,
	FIJO2_ID    			= 132,
	FIJO3_ID    			= 133,
	MASTER_ID				= 134,
	APARC1_ID				= 1,
	APARC2_ID				= 2,
	APARC3_ID				= 3,
	SLOTS					= 6,
	ORDEN_INICIAL 			= 0,
	FIJOM_X					= 0,
	FIJOM_Y					= 0,
	FIJO1_X					= 0,
	FIJO1_Y					= 400,
	FIJO2_X					= 600,
	FIJO2_Y					= 400,
	FIJO3_X					= 600,
	FIJO3_Y					= 0,
	COORD_APARC_X1			= 100,
	COORD_APARC_Y1			= 300,
	COORD_APARC_X2			= 300,
	COORD_APARC_Y2			= 300,
	COORD_APARC_X3			= 500,
	COORD_APARC_Y3			= 300,
	NO_MOVIL_ASOCIADO		= 0,
	LIBRE 					= 0,
	RESERVADO 				= 1,
	OCUPADO 				= 2
};

typedef nx_struct MovilMsg {
	nx_uint16_t ID_movil;		// ID maestro = ID origen
	nx_uint16_t Tslot;			// Tiempo de slot
	nx_uint16_t master;			// 1º slot para master
	nx_uint16_t first;			// 2º slot para fijo1
	nx_uint16_t second;			// 3º slot para fijo2
	nx_uint16_t third;			// 4º slot para fijo3
	nx_uint16_t fourth;			// 5º slot para movil
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
	nx_uint16_t distancem;
    nx_uint16_t distance1;
    nx_uint16_t distance2;
    nx_uint16_t distance3;
    nx_bool location;
} LocationMsg;

typedef nx_struct LlegadaMsg {
	nx_uint16_t ID_movil;		//ID movil
	nx_uint16_t orden;			//orden para saber que hacer (llegada, salida....)
} LlegadaMsg;

typedef nx_struct SitiosLibresMsg {
	nx_uint16_t ID_plaza;
	nx_uint16_t coorX;
	nx_uint16_t coorY;
	nx_uint16_t movilAsociado;	//ID del movil que esta aparcado o quiere aparcarse
	nx_uint16_t estado;			//estado de la plaza de aparcamiento (libre 0, reservado 1, ocupado 2)
}SitiosLibresMsg;



#endif

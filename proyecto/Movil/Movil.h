#ifndef MOVIL_H
#define MOVIL_H

enum {
	TIMER_PERIOD_MILLI 	= 5000,
	AM_MOVIL 			= 13,
	MOVIL_ID 			= 130,
	FIJO1_ID    		= 131,
	FIJO2_ID    		= 132,
	FIJO3_ID    		= 133,
	SLOTS				= 5,
	ORDEN_INICIAL 		= 0,
	LIBRE 				= 0,
	RESERVADO 			= 1,
	OCUPADO 			=2
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

typedef nx_struct LlegadaMsg {
	nx_uint16_t ID_movil;		//ID movil 
	nx_uint16_t orden;			//orden para saber que hacer (llegada, salida....)
} LlegadaMsg;

typedef nx_struct BaseDatos {
	nx_uint16_t ID_plaza1;
	nx_uint16_t coorX1;
	nx_uint16_t coorY1;
	nx_uint16_t movilAsociado1;	//ID del movil que esta aparcado o quiere aparcarse
	nx_uint16_t estado1;			//estado de la plaza de aparcamiento (libre 0, reservado 1, ocupado 2)
	nx_uint16_t ID_plaza2;
	nx_uint16_t coorX2;
	nx_uint16_t coorY2;
	nx_uint16_t movilAsociado2;	//ID del movil que esta aparcado o quiere aparcarse
	nx_uint16_t estado2;			//estado de la plaza de aparcamiento (libre 0, reservado 1, ocupado 2)
	nx_uint16_t ID_plaza3;
	nx_uint16_t coorX3;
	nx_uint16_t coorY3;
	nx_uint16_t movilAsociado3;	//ID del movil que esta aparcado o quiere aparcarse
	nx_uint16_t estado3;			//estado de la plaza de aparcamiento (libre 0, reservado 1, ocupado 2)
}BaseDatos;

typedef nx_struct SitiosLibresMsg {
	nx_struct BaseDatos;
}SitiosLibresMsg;





#endif

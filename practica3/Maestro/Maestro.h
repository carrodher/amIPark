#ifndef MAESTRO_H
#define MAESTRO_H

enum {
	TIMER_PERIOD_MILLI = 5000,
 	AM_MAESTRO  	   = 13,
 	MAESTRO_ID  	   = 131,
 	ESCLAVO_ID 		   = 132
};

typedef nx_struct MaestroMsg {
	nx_uint16_t ID_maestro;		// ID maestro = ID origen
	nx_uint16_t ID_esclavo;		// ID esclavo = ID destino
	nx_uint16_t tipo;			// Tipo de medida que solicita
} MaestroMsg;

typedef nx_struct EsclavoMsg {
	nx_uint16_t ID_esclavo;		// ID esclavo = ID origne
	nx_uint16_t medidaRssi;		// Valor de la medida RSSI
	nx_uint16_t tipo;			// Tipo de medida solicitada
	nx_uint16_t medida;			// Valor de la medida solicitada
} EsclavoMsg;

#endif
#ifndef ESCLAVO_H
#define ESCLAVO_H

enum {
	TIMER_PERIOD_MILLI 	= 4000,
	AM_ESCLAVO 			= 13,
	MAESTRO_ID 			= 130,
	ESCLAVO_TEMP_ID    	= 131,
	ESCLAVO_HUM_ID    	= 132,
	ESCLAVO_LUM_ID    	= 133,
	TEMPERATURA			= 1,
	HUMEDAD				= 2,
	LUMINOSIDAD			= 3,
	SLOTS				= 4
};

typedef nx_struct MaestroMsg {
	nx_uint16_t ID_maestro;		// ID maestro = ID origen
	nx_uint16_t first;			// 1º slot para este esclavo
	nx_uint16_t second;			// 2º slot para este esclavo
	nx_uint16_t third;			// 3º slot para este esclavo
} MaestroMsg;

typedef nx_struct EsclavoMsg {
	nx_uint16_t ID_esclavo;		// ID esclavo = ID origen
	nx_uint16_t medidaRssi;		// Valor de la medida RSSI
	nx_uint16_t medida;			// Valor de la medida solicitada
} EsclavoMsg;

#endif

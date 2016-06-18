#ifndef RSSIBOT_H
#define RSSIBOT_H

enum {
	AM = 13,
	SEND_FREQUENCY = 50,
	SAMPLES = 100,

	D1 = 10,
	D2 = 20,

	MSG_TYPE_RSSI = 1,
	RSSI_REQUEST = 10,
	RSSI_MEASURE = 20,

	RED   = 0,
	GREEN = 1,
	BLUE  = 2
};


typedef nx_struct RssiMsg {
	nx_uint8_t nodeID;              // ID del nodo origen del mensaje
	nx_uint8_t order;               // Orden a realizar
	nx_int16_t rssiValue;           // Medida RSSI
} RssiMsg;

#endif

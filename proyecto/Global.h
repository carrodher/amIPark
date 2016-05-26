#ifndef GLOBAL_H
#define GLOBAL_H

enum {
	AM = 13,

	TDMA_MASTER_BEACON_SLOT_TIME = 500,
	TDMA_RSSI_REQUEST_SLOT_TIME  = 100,

	MSG_TYPE_RSSI = 1,
	RSSI_REQUEST  = 10,
	RSSI_MEASURE  = 11,

	MSG_TYPE_VEHICLE     = 2,
	COMM_SLOT_REQUEST    = 20,
	PARKING_INFO_REQUEST = 21,
	SPOT_TAKEN_UP        = 22,
	SPOT_RELEASED        = 23,

	MSG_TYPE_PARKING_INFO = 3,
	PARKING_SPOT = 30,
	ANCHOR_POSITION = 31,
	NO_SPOTS_AVAILABLE = 32,

	TIMER_OFFSET  = 1,

	RED   = 0,
	GREEN = 1,
	BLUE  = 2,

	LED_BLINK_TIME = 10,

	NUMBER_OF_ANCHORS = 4,

	MASTER_ID = 130,
	FIJO_1_ID = 131,
	FIJO_2_ID = 132,
	FIJO_3_ID = 133,

	MASTER_X  = 0,
	MASTER_Y  = 0,

	FIJO_1_X  = 0,
	FIJO_1_Y  = 150,

	FIJO_2_X  = 150,
	FIJO_2_Y  = 150,

	FIJO_3_X  = 150,
	FIJO_3_Y  = 0,

	MAX_LINKED_VEHICLES = 5,
	PARKING_SIZE = 4,

	ERROR      = 20,

	SPOT_01_ID = 1,
	SPOT_02_ID = 2,
	SPOT_03_ID = 3,
	SPOT_04_ID = 4,

	SPOT_01_X  = 30,
	SPOT_02_X  = 118,
	SPOT_03_X  = 118,
	SPOT_04_X  = 30,

	SPOT_01_Y  = 115,
	SPOT_02_Y  = 115,
	SPOT_03_Y  = 30,
	SPOT_04_Y  = 30
};

// Estructura con la información estática de una plaza de parking
typedef struct ParkingSpot {
	uint8_t   id;     // ID de la plaza de parking
	uint16_t  x;      // Coordenada X
	uint16_t  y;      // Coordenada Y
} ParkingSpot;

/* TIPOS DE MENSAJE EXISTENTES */

typedef nx_struct RssiMsg {
	nx_uint8_t  nodeID;               // ID del nodo origen del mensaje
	nx_uint8_t  order;                // Orden a realizar
	nx_int16_t  rssiValue;            // Medida RSSI
} RssiMsg;

typedef nx_struct TdmaBeaconFrame {
	nx_uint8_t  nodeID;               // ID del nodo origen del mensaje
	// TODO Constantes "a" y "b"
	nx_uint8_t  slots;                // Número de slots de TDMA
	nx_uint16_t tSlot;                // Tiempo dedicado a cada slot
	nx_uint8_t  slotsOwners[MAX_LINKED_VEHICLES];        // IDs de los dueños de los slots (nodeIDs)
} TdmaBeaconFrame;

typedef nx_struct TdmaRssiRequestFrame {
	nx_uint8_t  nodeID;                             // ID del nodo origen del mensaje
	nx_uint8_t  slots;                              // Número de slots de TDMA
	nx_uint16_t tSlot;                              // Tiempo dedicado a cada slot
	nx_uint8_t  slotsOwners[ NUMBER_OF_ANCHORS];    // IDs de los dueños de los slots (nodeIDs) == [[Número de anchors]]
	nx_uint16_t  x;
	nx_uint16_t  y;
} TdmaRssiRequestFrame;

typedef nx_struct VehicleOrder {
	nx_uint8_t  nodeID;               // ID del nodo origen del mensaje
	nx_uint8_t  order;                // Orden a realizar
	nx_uint8_t  extraData;            // Datos extra: ID de la plaza reservada / ocupada (una vez aparcado)
} VehicleOrder;

typedef nx_struct ParkingInfo {
	nx_uint8_t  nodeID;               // ID del nodo origen del mensaje
	nx_uint8_t  order;                // Orden a realizar
	nx_uint8_t  id;                   // ID del parking / nodo fijo
	nx_uint16_t x;                    // Coordenada X
	nx_uint16_t y;                    // Coordenada Y
} ParkingInfo;

typedef nx_struct UpdateConstants {
	nx_float    a;                    // Parámetro a
	nx_float    b;                    // Parámetro b
} UpdateConstants;

#endif

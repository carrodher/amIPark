#include "Master.h"

module MasterC {
	uses interface Boot;
	uses interface Leds;
	uses interface CC2420Packet;
	uses interface Packet;
	uses interface AMPacket;
	uses interface AMSend;
	uses interface Receive;
	uses interface SplitControl as AMControl;
	uses interface Timer<TMilli> as Timer0;
}


implementation {
  
    uint8_t   nodeID;       // Almacena el identificador de este nodo
	message_t pkt;			   	// Espacio para el pkt a tx
	bool busy = FALSE;		  // Flag para comprobar el estado de la radio
	int16_t rssi2; 				  // Valor RSSI a enviar ( devuelto por getRssi() )

	//VARIABLES BASE DATOS
	nx_uint16_t ID_plaza1 = APARC1_ID;
	nx_uint16_t coorX1 = COORD_APARC_X1;
	nx_uint16_t coorY1 = COORD_APARC_Y1;
	nx_uint16_t movilAsociado1 = NO_MOVIL_ASOCIADO;		//ID del movil que esta aparcado o quiere aparcarse
	nx_uint16_t estado1 = LIBRE;			//estado de la plaza de aparcamiento (libre 0, reservado 1, ocupado 2)
	nx_uint16_t ID_plaza2 = APARC2_ID;
	nx_uint16_t coorX2 = COORD_APARC_X2;
	nx_uint16_t coorY2 = COORD_APARC_Y2;
	nx_uint16_t movilAsociado2 = NO_MOVIL_ASOCIADO;				//ID del movil que esta aparcado o quiere aparcarse
	nx_uint16_t estado2 = LIBRE;			//estado de la plaza de aparcamiento (libre 0, reservado 1, ocupado 2)
	nx_uint16_t ID_plaza3 = APARC3_ID;
	nx_uint16_t coorX3 = COORD_APARC_X3;
	nx_uint16_t coorY3 = COORD_APARC_Y3;
	nx_uint16_t movilAsociado3 = NO_MOVIL_ASOCIADO		//ID del movil que esta aparcado o quiere aparcarse
	nx_uint16_t estado3  = LIBRE;			//estado de la plaza de aparcamiento (libre 0, reservado 1, ocupado 2)

	// Obtiene el valor RSSI del paquete recibido
	int16_t getRssi(message_t *msg){
    	// Valores usados internamente en la función
    	uint8_t rssi_t;    // Se extrae en 8 bits sin signo
    	int16_t rssi2_t;   // Se calcula en 16 bits con signo: la potencia recibida estará entre -10 y -90 dBm
		rssi_t = call CC2420Packet.getRssi(msg);

		if(rssi_t >= 128) {
			rssi2_t = rssi_t-45-256;
		}
		else {
			rssi2_t = rssi_t-45;
		}
		return rssi2_t;
	}


	// Se ejecuta al alimentar t-mote. Arranca la radio
	event void Boot.booted() {
		call AMControl.start();
    // Obtenemos el ID de este nodo
    nodeID = TOS_NODE_ID;
	}


	// Arranca la radio si la primera vez hubo algún error
	event void AMControl.startDone(error_t err) {
		if (err != SUCCESS) {
			call AMControl.start();
		}
	}


	event void AMControl.stopDone(error_t err) {
	}


	// Cuando salta el temporizador se envia el mensaje
	event void Timer0.fired() {
		// Comprueba la rx de un pkt
	}


	// Comprueba la tx del pkt y marca como libre si ha terminado
	event void AMSend.sendDone(message_t* msg, error_t err) {
		if (&pkt == msg) {
			busy = FALSE;	// Libre
		}
	}


	event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
		// Si el paquete tiene la longitud de un paquete que pide el RSSI y es del nodo móvil
		if (len == sizeof(MovilMsg)) {
			MovilMsg* pktmovil_rx = (MovilMsg*)payload;		// Extrae el payload
			call Leds.led0On();    // Led 0 ON cuando me llega el paquete del móvil
			call Leds.led1Off();   // Led 1 OFF
			rssi2 = getRssi(msg);		// Obtiene el RSSI
			// Comprueba el slot que se le ha asignado
			// 1º slot => Transmitir
			if (pktmovil_rx->first == nodeID) {
				// No espera "nada"
				call Timer0.startOneShot(1);
			}
			// 2º slot => Esperar 1 slot y Transmitir
			else if (pktmovil_rx->second == nodeID) {
				// Espera 1 slot = Periodo/nº slots
				call Timer0.startOneShot(pktmovil_rx->Tslot);
			}
			// 3º slot => Esperar 2 slots y Transmitir
			else if (pktmovil_rx->third == nodeID) {
				// Espera 2 slots = 2*Periodo/nº slots
				call Timer0.startOneShot(2*pktmovil_rx->Tslot);
			}
		}else if (len == sizeof(LlegadaMsg)) {
			LlegadaMsg* pktllegada_rx = (LlegadaMsg*)payload;	//Extrae el payload
			/* si hubiese que comprobarse algo del mensaje de hola que tal se haria aqui */ 

			SitiosLibresMsg* pktsitioslibres_tx = (SitiosLibresMsg*)(call Packet.getPayload(&pkt, sizeof(SitiosLibresMsg)));
			// Reserva errónea
			if (pktsitioslibres_tx == NULL) {
				return;
			}
			//Forma el paquete
			// Campos plaza 1
			pktsitioslibres_tx->BaseDatos.ID_plaza1 = ID_plaza1;
			pktsitioslibres_tx->BaseDatos.coorX1 = coorX1;
			pktsitioslibres_tx->BaseDatos.coorY1 = coorY1;
			pktsitioslibres_tx->BaseDatos.movilAsociado1 = movilAsociado1;
			pktsitioslibres_tx->BaseDatos.estado1 = estado1;
			// Campos plaza 2
			pktsitioslibres_tx->BaseDatos.ID_plaza2 = ID_plaza2;
			pktsitioslibres_tx->BaseDatos.coorX2 = coorX2;
			pktsitioslibres_tx->BaseDatos.coorY2 = coorY2;
			pktsitioslibres_tx->BaseDatos.movilAsociado2 = movilAsociado2;
			pktsitioslibres_tx->BaseDatos.estado2 = estado2;
			// Campos plaza 3
			pktsitioslibres_tx->BaseDatos.ID_plaza3 = ID_plaza3;
			pktsitioslibres_tx->BaseDatos.coorX3 = coorX3;
			pktsitioslibres_tx->BaseDatos.coorY3 = coorY3;
			pktsitioslibres_tx->BaseDatos.movilAsociado3 = movilAsociado3;
			pktsitioslibres_tx->BaseDatos.estado3 = estado3;
			
			// Envía
			if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(SitiosLibresMsg)) == SUCCESS) {
				busy = TRUE;
				// Enciende los 3 leds cuando envía el paquete largo primero
				call Leds.led0On();
				call Leds.led1On();
				call Leds.led2On();
			}
		}else if (len == sizeof (SitiosLibresMsg)) {
			SitiosLibresMsg* pktsitioslibres_rx = (SitiosLibresMsg*)payload;	//Extrae el payload
			if (pktsitioslibres_rx->BaseDatos.movilAsociado1 != NO_MOVIL_ASOCIADO) {
				if(pktsitioslibres_rx->BaseDatos.estado1 == RESERVADO){
					movilAsociado1 = pktsitioslibres_rx->BaseDatos.movilAsociado1;
					estado1 = pktsitioslibres_rx->BaseDatos.estado1;
				}else if(pktsitioslibres_rx->BaseDatos.estado1 == OCUPADO){
					movilAsociado1 = pktsitioslibres_rx->BaseDatos.movilAsociado1;
					estado1 = pktsitioslibres_rx->BaseDatos.estado1;
				}
			}else if (pktsitioslibres_rx->BaseDatos.movilAsociado2 != NO_MOVIL_ASOCIADO) {
				if(pktsitioslibres_rx->BaseDatos.estado2 == RESERVADO){
					movilAsociado2 = pktsitioslibres_rx->BaseDatos.movilAsociado2;
					estado2 = pktsitioslibres_rx->BaseDatos.estado2;
				}else if(pktsitioslibres_rx->BaseDatos.estado2 == OCUPADO){
					movilAsociado2 = pktsitioslibres_rx->BaseDatos.movilAsociado2;
					estado2 = pktsitioslibres_rx->BaseDatos.estado2;
				}
			}else if (pktsitioslibres_rx->BaseDatos.movilAsociado3 != NO_MOVIL_ASOCIADO) {
				if(pktsitioslibres_rx->BaseDatos.estado3 == RESERVADO){
					movilAsociado3 = pktsitioslibres_rx->BaseDatos.movilAsociado3;
					estado3 = pktsitioslibres_rx->BaseDatos.estado3;
				}else if(pktsitioslibres_rx->BaseDatos.estado3 == OCUPADO){
					movilAsociado3 = pktsitioslibres_rx->BaseDatos.movilAsociado3;
					estado3 = pktsitioslibres_rx->BaseDatos.estado3;
				}
			}
		}
		return msg;
	}
	// En cualquiera de los casos cuando expira el temporizador dirige a "event void Timer0.fired()
	
		// Si no está ocupado forma y envía el mensaje
		/*if (!busy) {
			// Reserva memoria para el paquete
			FijoMsg* pktfijo_tx = (FijoMsg*)(call Packet.getPayload(&pkt, sizeof(FijoMsg)));

			// Reserva errónea
			if (pktfijo_tx == NULL) {
				return;
			}

			// Forma el paquete a tx
			pktfijo_tx->ID_fijo    = nodeID;    // Campo 1: ID del nodo fijo
			pktfijo_tx->medidaRssi = rssi2;     // Campo 2: Medida RSSI

      		// Determinar las coordenadas de este nodo fijo
      		switch (nodeID) {
        		case FIJO1_ID:
          		pktfijo_tx->x = FIJO1_X;   // Campo 3: Coordenada X
				pktfijo_tx->y = FIJO1_Y;   // Campo 4: Coordenada Y
          		break;

        		case FIJO2_ID:
          		pktfijo_tx->x = FIJO2_X;   // Campo 3: Coordenada X
				pktfijo_tx->y = FIJO2_Y;   // Campo 4: Coordenada Y
          		break;

        		case FIJO3_ID:
          		pktfijo_tx->x = FIJO3_X;   // Campo 3: Coordenada X
				pktfijo_tx->y = FIJO3_Y;   // Campo 4: Coordenada Y
          		break;
      		}

			// Envía
			if (call AMSend.send(MOVIL_ID, &pkt, sizeof(FijoMsg)) == SUCCESS) {
				//					|-> Destino = Móvil
				busy = TRUE;	// Ocupado
				call Leds.led0Off();   // Led 0 Off
				call Leds.led1On();    // Led 1 ON cuando envío mi paquete
			}
		}*/
	
}

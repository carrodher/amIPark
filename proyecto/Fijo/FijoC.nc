#include "Fijo.h"

module FijoC {
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
		// Si no está ocupado forma y envía el mensaje
		if (!busy) {
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
      			case MASTER_ID:
          			pktfijo_tx->x = FIJOM_X;   // Campo 3: Coordenada X
			    	pktfijo_tx->y = FIJOM_Y;   // Campo 4: Coordenada Y
          		break;
          		
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
		}
	}


	// Comprueba la tx del pkt y marca como libre si ha terminado
	event void AMSend.sendDone(message_t* msg, error_t err) {
		if (&pkt == msg) {
			busy = FALSE;	// Libre
		}
	}


	// Comprueba la rx de un pkt
	event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
		MovilMsg* pktmovil_rx = (MovilMsg*)payload;		// Extrae el payload

		// Si el paquete tiene la longitud correcta y es del nodo móvil
		if (len == sizeof(MovilMsg) && pktmovil_rx->ID_movil == MOVIL_ID) {
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
			}else if (pktmovil_rx->master == nodeID) {
				// Espera 2 slots = 2*Periodo/nº slots
				call Timer0.startOneShot(3*pktmovil_rx->Tslot);
			}
			// En cualquiera de los casos cuando expira el temporizador dirige a "event void Timer0.fired()
		}

		return msg;
	}
}

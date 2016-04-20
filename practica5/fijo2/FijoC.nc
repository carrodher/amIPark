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
	message_t pkt;			   	// Espacio para el pkt a tx
	bool busy = FALSE;		 	// Flag para comprobar el estado de la radio
	uint8_t rssi;			 	// Se extrae en 8 bits sin signo
	int16_t rssi2; 				// Se calcula en 16 bits con signo: la potencia recibida estará entre -10 y -90 dBm

	// Obtiene el valor RSSI del paquete recibido
	uint16_t getRssi(message_t *msg){

		rssi=call CC2420Packet.getRssi(msg);
		if(rssi >= 128){
			rssi2 = rssi-45-256;
		}
		else{
			rssi2 = rssi-45;
		}
		return (uint16_t) rssi2;
	}

	// Se ejecuta al alimentar t-mote. Arranca la radio
	event void Boot.booted() {
		call AMControl.start();
	}

	// Arranca la radio si la primera vez hubo algún error
	event void AMControl.startDone(error_t err) {
		if (err != SUCCESS) {
			call AMControl.start();
		}
	}

	event void AMControl.stopDone(error_t err) {
	}

	// Después de esperar, toca enviar. Cuando acaba el temporizador...
	event void Timer0.fired() {
		// Si no está ocupado forma y envía el mensaje
		if (!busy) {
			// Reserva memoria para el paquete
			FijoMsg* pktfijo_tx = (FijoMsg*)(call Packet.getPayload(&pkt, sizeof(FijoMsg)));

			// Reserva errónea
			if (pktfijo_tx == NULL) {
				return 0;
			}

			// Forma el paquete a tx
			pktfijo_tx->ID_fijo = FIJO2_ID;		// Campo 1: ID fijo 1
			pktfijo_tx->medidaRssi = rssi;      // Campo 2: Medida RSSI
			pktfijo_tx->x = COOR2_X;  			// Campo 3: Coordenada X
			pktfijo_tx->y = COOR2_Y;			// Campo 4: Coordenada Y

			// Envía
			if (call AMSend.send(MOVIL_ID, &pkt, sizeof(FijoMsg)) == SUCCESS) {
				//						|-> Destino = Móvil
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

			rssi = getRssi(msg);		// Calcula el RSSI

			// Comprueba el slot que se le ha asignado
			// 1º slot => Transmitir
			if (pktmovil_rx->first == FIJO2_ID) {
				// No espera nada
				call Timer0.startOneShot(1);
			}
			// 2º slot => Esperar 1 slot y Transmitir
			else if (pktmovil_rx->second == FIJO2_ID) {
				// Espera 1 slot = Periodo/nº slots
				call Timer0.startOneShot(pktmovil_rx->Tslot);
			}
			// 3º slot => Esperar 2 slots y Transmitir
			else if (pktmovil_rx->third == FIJO2_ID) {
				// Espera 2 slots = 2*Periodo/nº slots
				call Timer0.startOneShot(2*pktmovil_rx->Tslot);
			}
			// En cualquiera de los casos cuando expira el temporizador dirige a "event void Timer0.fired()
		}

		return msg;
	}
}

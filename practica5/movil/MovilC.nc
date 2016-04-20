#include "Movil.h"
#include <math.h>

module MovilC {
	uses interface Boot;
	uses interface Leds;
	uses interface Timer<TMilli> as Timer0;
	uses interface Packet;
	uses interface AMPacket;
	uses interface AMSend;
	uses interface Receive;
	uses interface SplitControl as AMControl;
}
implementation {
	uint16_t first = FIJO1_ID;		// 1º slot (Nodo fijo 1)
	uint16_t second = FIJO2_ID;		// 2º slot (Nodo fijo 2)
	uint16_t third = FIJO3_ID;		// 3º slot (Nodo fijo 3)
	uint16_t fourth = MOVIL_ID;		// 4º slot (Nodo móvil)
	message_t pkt;        			// Espacio para el pkt a tx
	bool busy = FALSE;    			// Flag para comprobar el estado de la radio

	//variables nodos fijos
	int16_t distance_n1;
	int16_t distance_n2;
	int16_t distance_n3;

	int16_t w_n1;
	int16_t w_n2;
	int16_t w_n3;


	float a = -10.302;
	float b = -1.678;

	int16_t p = 1;


	// Se ejecuta al alimentar t-mote. Arranca la radio
	event void Boot.booted() {
		call AMControl.start();
	}

	/* Si la radio está encendida arranca el temporizador.
	Arranca la radio si la primera vez hubo algún error */
	event void AMControl.startDone(error_t err) {
		if (err == SUCCESS) {
			call Timer0.startPeriodic(TIMER_PERIOD_MILLI);
		}
		else {
			call AMControl.start();
		}
	}

	event void AMControl.stopDone(error_t err) {
	}

	// Maneja el temporizador
	event void Timer0.fired() {
		// Si no está ocupado forma y envía el mensaje
		if (!busy) {
			// Reserva memoria para el paquete
			MovilMsg* pktmovil_tx = (MovilMsg*)(call Packet.getPayload(&pkt, sizeof(MovilMsg)));

			// Reserva errónea
			if (pktmovil_tx == NULL) {
				return;
			}

			/*** FORMA EL PAQUETE ***/
			// Campo 1: ID_movil
			pktmovil_tx->ID_movil = MOVIL_ID;
			// Campo 2: Tslot
			pktmovil_tx->Tslot = TIMER_PERIOD_MILLI/SLOTS;
			// Campos 3, 4 y 5: Orden de los slots
			pktmovil_tx->first = first;
			pktmovil_tx->second = second;
			pktmovil_tx->third = third;
			// Campo 6: Último slot siempre para el móvil
			pktmovil_tx->fourth = fourth;

			// Envía
			if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(MovilMsg)) == SUCCESS) {
				//						|-> Destino = Difusión
				busy = TRUE;	// Ocupado
				// Enciende los 3 leds cuando envía el paquete que organiza los slots
				call Leds.led0On();
				call Leds.led1On();
				call Leds.led2On();
			}
		}
	}

	// Comprueba la tx del pkt y marca como libre si ha terminado
	event void AMSend.sendDone(message_t* msg, error_t err) {
		if (&pkt == msg) {
			busy = FALSE;	// Libre
		}
	}

	uint8_t getDistance(int16_t rssiX){

		return exp((rssiX-b)/a);
	}

	event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
		if (len == sizeof(FijoMsg)) {
			FijoMsg* pktfijo_rx = (FijoMsg*)payload;   // Extrae el payload

			// Determina el emisor del mensaje recibido
			if (pktfijo_rx->ID_fijo == FIJO1_ID) {
				//Nos ha llegado un paquete del nodo fijo 1

				distance_n1=getDistance(pktfijo_rx->medidaRssi);
				w_n1=1/(pow(distance_n1,p));

				call Leds.led0On();   	// Led 0 On para fijo 1
				call Leds.led1Off();	// Led 0 Off
				call Leds.led2Off();  	// Led 0 Off
			}
			else if (pktfijo_rx->ID_fijo == FIJO2_ID) {
				//Nos ha llegado un paquete del nodo fijo 1

				distance_n2=getDistance(pktfijo_rx->medidaRssi);
				w_n2=1/(pow(distance_n2,p));


				call Leds.led0Off();   	// Led 0 Off
				call Leds.led1On();    	// Led 1 On para fijo 2
				call Leds.led2Off();	// Led 2 Off
			}
			else if (pktfijo_rx->ID_fijo == FIJO3_ID) {
				//Nos ha llegado un paquete del nodo fijo 1

				distance_n3=getDistance(pktfijo_rx->medidaRssi);
				w_n3=1/(pow(distance_n3,p));


				call Leds.led0Off();   	// Led 0 Off
				call Leds.led1Off();   	// Led 1 Off
				call Leds.led2On();    	// Led 2 On para fijo 2
			}
		}
		return msg;
	}
}

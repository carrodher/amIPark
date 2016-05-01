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

	// Distancia a nodos fijos Dij
	float distance_n1;
	float distance_n2;
	float distance_n3;

	// Pesos wij
	float w_n1;
	float w_n2;
	float w_n3;

	// Localización del nodo móvil
	float movilX;
	float movilY;

	// RSSI en función de la distancia: RSSI(D) = a·log(D)+b
	float a = -10.302;
	float b = -1.678;

	/* Exponente que modifica la influencia de la distancia en los pesos.
	Valores más altos de p dan más importancia a los nodos fijos más cercanos */
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

	// Fórmula para obtener la distancia a partir del RSSI
	float getDistance(float rssiX){
		return powf(10,((rssiX-b)/a));
	}

	// Fórmula para obtener el peso
	float getWeigth(float distance, float pvalue) {
		return 1/(powf(distance,pvalue));
	}

	// Fórmula para calcular la localización
	float calculateLocation(float w1, float w2, float w3, int16_t c1, int16_t c2, int16_t c3) {
		return (w1*c1+w2*c2+w3*c3)/(w1+w2+w3);
	}

	// Recibe un mensaje de cualquiera de los nodos fijos
	event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
		if (len == sizeof(FijoMsg)) {
			FijoMsg* pktfijo_rx = (FijoMsg*)payload;		// Extrae el payload

			// Determina el emisor del mensaje recibido
			if (pktfijo_rx->ID_fijo == FIJO1_ID) { 			//Nos ha llegado un paquete del nodo fijo 1
				// Enciende los leds para notificar la llegada de un paquete
				call Leds.led0On();   	// Led 0 On para fijo 1
				call Leds.led1Off();	// Led 0 Off
				call Leds.led2Off();  	// Led 0 Off

				// Calcula la distancia al nodo 1 en base al RSSI
				distance_n1 = getDistance(pktfijo_rx->medidaRssi);
				// Calcula el peso del nodo 1
				w_n1 = getWeigth(distance_n1,p);
			}
			else if (pktfijo_rx->ID_fijo == FIJO2_ID) {		//Nos ha llegado un paquete del nodo fijo 2
				// Enciende los leds para notificar la llegada de un paquete
				call Leds.led0Off();   	// Led 0 Off
				call Leds.led1On();    	// Led 1 On para fijo 2
				call Leds.led2Off();	// Led 2 Off

				// Calcula la distancia al nodo 2 en base al RSSI
				distance_n2 = getDistance(pktfijo_rx->medidaRssi);
				// Calcula el peso del nodo 2
				w_n2 = getWeigth(distance_n2,p);
			}
			else if (pktfijo_rx->ID_fijo == FIJO3_ID) {		//Nos ha llegado un paquete del nodo fijo 3
				// Enciende los leds para notificar la llegada de un paquete
				call Leds.led0Off();   	// Led 0 Off
				call Leds.led1Off();   	// Led 1 Off
				call Leds.led2On();    	// Led 2 On para fijo 3

				// Calcula la distancia al nodo 2 en base al RSSI
				distance_n3 = getDistance(pktfijo_rx->medidaRssi);
				// Calcula el peso del nodo 3
				w_n3 = getWeigth(distance_n3,p);

				/* Llegados a este punto ya tenemos TODOS los datos de los nodos fijos,
				así que podemos calcular la localizacón del nodo móvil */
				movilX = calculateLocation(w_n1,w_n2,w_n3,COOR1_X,COOR2_X,COOR3_X);
				movilY = calculateLocation(w_n1,w_n2,w_n3,COOR1_Y,COOR2_Y,COOR3_Y);

				// Mandamos las coordenadas calculadas a difusión para que pueda verlo la Base Station
				if (!busy) {
					// Reserva memoria para el paquete
					LocationMsg* pktmovil_loc = (LocationMsg*)(call Packet.getPayload(&pkt, sizeof(LocationMsg)));

					// Reserva errónea
					if (pktmovil_loc == NULL) {
						return 0;
					}

					/*** FORMA EL PAQUETE ***/
					// Campo 1: ID_movil
					pktmovil_loc->ID_movil = MOVIL_ID;
					// Campo 2: Coordenada X
					pktmovil_loc->coorX = movilX*100;
					// Campo 3: Coordenada Y
					pktmovil_loc->coorY = movilY*100;


					/* ¡¡ __TEST__ !!
						Para comprobar los pasos intermedios: comentar arriba,
						descomentar lo siguiente y ver en la Base Station: */
					// 	1.- Distancia
					//pktmovil_loc->ID_movil = distance_n1*100;
					//pktmovil_loc->coorX = distance_n2*100;
					//pktmovil_loc->coorY = distance_n3*100;
					// 	2.- Pesos
					//pktmovil_loc->ID_movil = w_n1;
					//pktmovil_loc->coorX = w_n2;
					//pktmovil_loc->coorY = w_n3;

					// Envía
					if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(LocationMsg)) == SUCCESS) {
						//						|-> Destino = Difusión
						busy = TRUE;	// Ocupado
					}
				}
			}
		}
		return msg;
	}
}

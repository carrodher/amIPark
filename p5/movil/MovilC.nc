#include "Movil.h"
#include <Timer.h>
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
	int16_t rssi = 0;					// Rssi recibido
	uint16_t first = FIJO1_ID;			// 1º slot (id fijo1)
	uint16_t second = FIJO2_ID;			// 2º slot (id fijo2)
	uint16_t third = FIJO3_ID;			// 3º slot (id fijo3)
	uint16_t fourth = MOVIL_ID; 		// 4º slot (id movil)
	message_t pkt;        				// Espacio para el pkt a tx
	bool busy = FALSE;    				// Flag para comprobar el estado de la radio

	// Coordenadas de los nodos fijos
	int16_t coor1_x = 0;
	int16_t coor1_y = 0;
	int16_t coor2_x = 2;
	int16_t coor2_y = 0;
	int16_t coor3_x = 1;
	int16_t coor3_y = 1;

	// Distancia a nodos fijos Dij
	float distance_n1 = 0;
	float distance_n2 = 0;
	float distance_n3 = 0;

	// Pesos wij
	float w_n1 = 0;
	float w_n2 = 0;
	float w_n3 = 0;

	// Localización del nodo móvil
	int16_t movilX = 0;
	int16_t movilY = 0;

    // RSSI en función de la distancia: RSSI(D) = a·log(D)+b
	
	/* Exponente que modifica la influencia de la distancia en los pesos.
	Valores más altos de p dan más importancia a los nodos fijos más cercanos */
	int p = 1;

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
			// Campo 6: Último slot siempre para el movil
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

	// Enciende los leds según el nodo emisor
	void turnOnLeds(int16_t nodo) {
		// Determina el emisor del mensaje recibido
		if (nodo == FIJO1_ID) { 			//Nos ha llegado un paquete del nodo fijo 1
			// Enciende los leds para notificar la llegada de un paquete
			call Leds.led0On();   	// Led 0 On para fijo 1
			call Leds.led1Off();	// Led 0 Off
			call Leds.led2Off();  	// Led 0 Off
		}
		else if (nodo == FIJO2_ID) {		//Nos ha llegado un paquete del nodo fijo 2
			// Enciende los leds para notificar la llegada de un paquete
			call Leds.led0Off();   	// Led 0 Off
			call Leds.led1On();    	// Led 1 On para fijo 2
			call Leds.led2Off();	// Led 2 Off
		}
		else if (nodo == FIJO3_ID) {
			// Enciende los leds para notificar la llegada de un paquete
			call Leds.led0Off();   	// Led 0 Off
			call Leds.led1Off();   	// Led 1 Off
			call Leds.led2On();    	// Led 2 On para fijo 3
		}
	}

		// Fórmula para obtener la distancia a partir del RSSI, se llama una vez por cada nodo fijo
	float getDistance(int16_t rssiX){
		/* Fórmula:
			RSSI(D) = a·log(D) + b
			D = 10^((RSSI-b)/a) */
		return 100*powf(10,((rssiX+1.678)/(-10.302)));
	}


	// Fórmula para obtener el peso, se llama una vez por cada nodo fijo
	float getWeigth(float distance, int pvalue) {
		/* Fórmula:
			w = 1/(D^p) */
		return 1/(powf(distance,pvalue)*100);
	}

	int16_t calculateLocation(float w1, float w2, float w3, uint16_t c1, uint16_t c2, uint16_t c3) {
		/* Fórmula:
			X = (w1·x1 + w2·x2 + w3·x3)/(w1 + w2 + w3)
			Y = (w1·y1 + w2·y2 + w3·y3)/(w1 + w2 + w3) */
		return (w1*c1+w2*c2+w3*c3)/(w1+w2+w3);
	}


// Recibe un mensaje de cualquiera de los nodos fijos
	event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){

			call Leds.led0Off();   	// Led 0 Off
			call Leds.led1Off();   	// Led 1 Off
			call Leds.led2Off();    // Led 2 Off

		if (len == sizeof(FijoMsg)) {
			FijoMsg* pktfijo_rx = (FijoMsg*)payload;		// Extrae el payload

			// Determina el emisor del mensaje recibido
			if (pktfijo_rx->ID_fijo == FIJO1_ID) { 			//Nos ha llegado un paquete del nodo fijo 1
				// Enciende los leds para notificar la llegada de un paquete
				turnOnLeds(pktfijo_rx->ID_fijo);

				rssi = pktfijo_rx->medidaRssi;
				// Calcula la distancia al nodo 1 en base al RSSI
				distance_n1 = getDistance(rssi);
				// Calcula el peso del nodo 1
				w_n1 = getWeigth(distance_n1,p);
			}
			else if (pktfijo_rx->ID_fijo == FIJO2_ID) {		//Nos ha llegado un paquete del nodo fijo 2
				// Enciende los leds para notificar la llegada de un paquete
				turnOnLeds(pktfijo_rx->ID_fijo);

				rssi = pktfijo_rx->medidaRssi;
				// Calcula la distancia al nodo 2 en base al RSSI
				distance_n2 = getDistance(rssi);
				// Calcula el peso del nodo 2
				w_n2 = getWeigth(distance_n2,p);
			}
			else if (pktfijo_rx->ID_fijo == FIJO3_ID) {		//Nos ha llegado un paquete del nodo fijo 3
				// Enciende los leds para notificar la llegada de un paquete
				turnOnLeds(pktfijo_rx->ID_fijo);

				rssi = pktfijo_rx->medidaRssi;
				// Calcula la distancia al nodo 3 en base al RSSI
				distance_n3 = getDistance(rssi);
				// Calcula el peso del nodo 3
				w_n3 = getWeigth(distance_n3,p);

				/* Llegados a este punto ya tenemos TODOS los datos de los nodos fijos,
				así que podemos calcular la localizacón del nodo móvil y enviar el resultado*/
				// Calculamos la coordenada X del nodo móvil
				movilX = calculateLocation(w_n1,w_n2,w_n3,coor1_x,coor2_x,coor3_x);
				// Calculamos la coordenada Y del nodo móvil
				movilY = calculateLocation(w_n1,w_n2,w_n3,coor1_y,coor2_y,coor3_y);

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
					//pktmovil_loc->coorX = movilX;
					// Campo 3: Coordenada Y
					//pktmovil_loc->coorY = movilY;


					/* ¡¡ __TEST__ !!
						Para comprobar los pasos intermedios: comentar arriba,
						descomentar lo siguiente y ver en la Base Station: */
					// 	1.- Distancia
					//pktmovil_loc->ID_movil = distance_n1*100;
					pktmovil_loc->coorX = distance_n2*100;
					//pktmovil_loc->coorY = distance_n3*100;
					// 	2.- Pesos
					//pktmovil_loc->ID_movil = w_n1;
					pktmovil_loc->coorY = w_n2;
					//pktmovil_loc->coorY = w_n3;

					// Envía
					if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(LocationMsg)) == SUCCESS) {
						//						|-> Destino = Difusión
						busy = TRUE;	// Ocupado
					}
				}
				// Si está ocupado mandamos un mensaje reconocido para saberlo
				else {
					// Reserva memoria para el paquete
					LocationMsg* pktmovil_loc = (LocationMsg*)(call Packet.getPayload(&pkt, sizeof(LocationMsg)));

					// Reserva errónea
					if (pktmovil_loc == NULL) {
						return 0;
					}

					/*** FORMA EL PAQUETE ***/
					pktmovil_loc->ID_movil = 0;
					pktmovil_loc->coorX = 0;
					pktmovil_loc->coorY = 0;
				}
			}
		}
		return msg;
	}
}

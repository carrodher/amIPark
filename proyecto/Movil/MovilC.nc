	#include "Movil.h"
	#include <math.h>
	#include "printf.h"
	#include <UserButton.h>


module MovilC {
	uses interface Boot;
	uses interface Leds;
		//uses interface Timer<TMilli> as Timer0;
	uses interface Timer<TMilli> as TimerLedRojo;
	uses interface Packet;
	uses interface AMPacket;
	uses interface AMSend;
	uses interface Receive;
	uses interface SplitControl as AMControl;
	uses interface Notify<button_state_t>;
}
implementation {
		int16_t rssi = 0;					// Rssi recibido
		uint16_t master = MASTER_ID;		// 1º slot: id master
		uint16_t first = FIJO1_ID;			// 2º slot: id fijo 1
		uint16_t second = FIJO2_ID;			// 3º slot: id fijo 2
		uint16_t third = FIJO3_ID;			// 4º slot: id fijo 3
		uint16_t fourth = MOVIL_ID; 		// 5º slot: id movil
		message_t pkt;        				// Espacio para el pkt a tx
		bool busy = FALSE;    				// Flag para comprobar el estado de la radio
		uint16_t contador_3_mensajes= 0;
		uint16_t localizacion = 0;

		// Coordenadas de los nodos fijos
		uint16_t coorm_x = FIJOM_X;
		uint16_t coorm_y = FIJOM_Y;

		uint16_t coor1_x = FIJO1_X;
		uint16_t coor1_y = FIJO1_Y;

		uint16_t coor2_x = FIJO2_X;
		uint16_t coor2_y = FIJO2_Y;

		uint16_t coor3_x = FIJO3_X;
		uint16_t coor3_y = FIJO3_Y;

		// Distancia a nodos fijos Dij
		float distance_nm = 0;
		float distance_n1 = 0;
		float distance_n2 = 0;
		float distance_n3 = 0;

		// Pesos wij
		float w_nm = 0;
		float w_n1 = 0;
		float w_n2 = 0;
		float w_n3 = 0;

		// Localización del nodo móvil
		uint16_t movilX = 0;
		uint16_t movilY = 0;

	   // Constantes para calculo de la distancia
		float a = -21.593;
		float b = -50.093;

		bool reserved = FALSE;

		uint16_t reserva_rssi = 0;

		uint16_t z = 0;

		uint8_t nodeID;

	  /* RSSI en función de la distancia: RSSI(D) = a·log(D)+b */

		/* Exponente que modifica la influencia de la distancia en los pesos.
		Valores más altos de p dan más importancia a los nodos fijos más cercanos */
		int p = 1;

		event void Notify.notify(button_state_t state) {
			// Botón pulsado
			if (state == BUTTON_PRESSED) {
				// Si no está ocupado forma y envía el mensaje
				if (!busy) {
					// Reserva memoria para el paquete
					LlegadaMsg * pktllegada_tx = (LlegadaMsg*)(call Packet.getPayload(&pkt, sizeof(LlegadaMsg)));
					//Reserva erronea
					if(pktllegada_tx == NULL){
						return;
					}

					/*** MENSAJE TRAS PULSAR EL BOTON ***/

					//Forma el paquete
					pktllegada_tx->ID_movil = nodeID;
					pktllegada_tx->orden = ORDEN_INICIAL;

					//Envía
					if(call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(LlegadaMsg)) == SUCCESS){
						//						|-> Destino = Difusión
						busy = TRUE;	// Ocupado
						// Enciende los 3 leds cuando envía el paquete que organiza los slots
						printf("He llegado al parking, solicito informacion sobre las plazas\n");
						printfflush();
						call Leds.led0On();
						call Leds.led1On();
						call Leds.led2On();
					}
				}
			}
			// Botón no pulsado
			else if (state == BUTTON_RELEASED) {
				call Leds.led0Off();
				call Leds.led1Off();
				call Leds.led2Off();
			}
		}



		// Se ejecuta al alimentar t-mote. Arranca la radio
		event void Boot.booted() {
			call AMControl.start();
			call Notify.enable();		// Botón
			nodeID = TOS_NODE_ID;
			printf("Este es mi ID %d\n", nodeID);
			printfflush();
		}

		/* Si la radio está encendida arranca el temporizador.
		Arranca la radio si la primera vez hubo algún error */
		event void AMControl.startDone(error_t err) {
			if (err == SUCCESS) {
			}
			else {
				call AMControl.start();
			}
		}

		event void AMControl.stopDone(error_t err) {
		}


		void sendMsgRSSI(){
			//ENVIA MENSAJE PARA RECIBIR RSSI
			if(!busy){
				MovilMsg* pktmovil_tx = (MovilMsg*)(call Packet.getPayload(&pkt, sizeof(MovilMsg)));

				// Reserva errónea
				if (pktmovil_tx == NULL) {
					return;
				}
				//Forma el paquete
				// Campo 1: nodeID
				pktmovil_tx->ID_movil = nodeID;
				// Campo 2: Tslot
				pktmovil_tx->Tslot = TIMER_PERIOD_MILLI/SLOTS;
				// Campos 3, 4, 5 y 6: Orden de los slots
				pktmovil_tx->master = master;
				pktmovil_tx->first = first;
				pktmovil_tx->second = second;
				pktmovil_tx->third = third;
				// Campo 6: Último slot siempre para el movil
				pktmovil_tx->fourth = fourth;

				reserva_rssi = 0;

				// Envía
				if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(MovilMsg)) == SUCCESS) {
					//						|-> Destino = Difusión
					localizacion = 1;
					busy = TRUE;
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
			if(reserva_rssi == 1){
				sendMsgRSSI();
				reserva_rssi=0;
			}
			if(localizacion == 1){
				localizacion=0;
			}

		}

		//Funcion que enciende y apaga luz durante un tiempo determinado
		event void TimerLedRojo.fired(){
			if (call Leds.get() & LEDS_LED1){
				call Leds.led1Off();
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
			else if (nodo == MASTER_ID){
				// Enciende los leds para notificar la llegada de un paquete
				call Leds.led0On();   	// Led 0 On
				call Leds.led1On();   	// Led 1 On
				call Leds.led2On();    	// Led 2 On para master
			}
		}

		// Fórmula para obtener la distancia a partir del RSSI, se llama una vez por cada nodo fijo
		float getDistance(int16_t rssiX){
	        // Convertir RSSI a float
			float rssi_float = (float) rssiX;
			/* Fórmula: RSSI(D) = a·log(D) + b; D = 10^((RSSI-b)/a) */
			return 100 * powf(10, (rssi_float-b)/a );
		}


		// Fórmula para obtener el peso, se llama una vez por cada nodo fijo
		float getWeigth(float distance, int pvalue) {
			/* Fórmula:
				w = 1/(D^p) */
			return 1/(powf(distance,pvalue));
		}

		int16_t calculateLocation(float wm, float w1, float w2, float w3, uint16_t cm, uint16_t c1, uint16_t c2, uint16_t c3) {
			/* Fórmula:
				X = (wm·xm + w1·x1 + w2·x2 + w3·x3)/(wm + w1 + w2 + w3)
				Y = (wm·ym + w1·y1 + w2·y2 + w3·y3)/(wm + w1 + w2 + w3) */
				return (wm*cm + w1*c1 + w2*c2 + w3*c3)/(wm + w1 + w2 + w3);
			}

			void sendParkedState(int i){

				printf("He aparcado en la plaza %d \n",i);
				printfflush();

				if(i == 1){

					if(!busy){

					// Reserva memoria para el paquete
						SitiosLibresMsg* pktsitioslibres_tx = (SitiosLibresMsg*)(call Packet.getPayload(&pkt, sizeof(SitiosLibresMsg)));
					// Reserva errónea
						if (pktsitioslibres_tx == NULL) {
							return;
						}
						pktsitioslibres_tx->movilAsociado = nodeID;
						pktsitioslibres_tx->estado = OCUPADO;
						pktsitioslibres_tx->ID_plaza = i;
						pktsitioslibres_tx->coorX = COORD_APARC_X1;
						pktsitioslibres_tx->coorY = COORD_APARC_Y1;
					//Envía
						if(call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(SitiosLibresMsg)) == SUCCESS){
						busy = TRUE;	// Ocupado
					}
				}

			}else if(i == 2){

				if(!busy){
					// Reserva memoria para el paquete
					SitiosLibresMsg* pktsitioslibres_tx = (SitiosLibresMsg*)(call Packet.getPayload(&pkt, sizeof(SitiosLibresMsg)));
					// Reserva errónea
					if (pktsitioslibres_tx == NULL) {
						return;
					}
					pktsitioslibres_tx->movilAsociado = nodeID;
					pktsitioslibres_tx->estado = OCUPADO;
					pktsitioslibres_tx->ID_plaza = i;
					pktsitioslibres_tx->coorX = COORD_APARC_X2;
					pktsitioslibres_tx->coorY = COORD_APARC_Y2;

					//Envía
					if(call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(SitiosLibresMsg)) == SUCCESS){
						busy = TRUE;	// Ocupado
					}
				}

			}else if(i == 3){

				if(!busy){
					// Reserva memoria para el paquete
					SitiosLibresMsg* pktsitioslibres_tx = (SitiosLibresMsg*)(call Packet.getPayload(&pkt, sizeof(SitiosLibresMsg)));
					// Reserva errónea
					if (pktsitioslibres_tx == NULL) {
						return;
					}
					pktsitioslibres_tx->movilAsociado = nodeID;
					pktsitioslibres_tx->estado = OCUPADO;
					pktsitioslibres_tx->ID_plaza = i;
					pktsitioslibres_tx->coorX = COORD_APARC_X3;
					pktsitioslibres_tx->coorY = COORD_APARC_Y3;

					//Envía
					if(call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(SitiosLibresMsg)) == SUCCESS){
						busy = TRUE;	// Ocupado
					}
				}
			}

		}

		bool am_i_parked(uint16_t movilXr, uint16_t movilYr){
			bool parked = FALSE;
			uint16_t j = 0;
			if(movilXr <= (COORD_APARC_X1+ERROR) && movilXr >= (COORD_APARC_X1-ERROR) && movilYr <= (COORD_APARC_Y1+ERROR) && movilYr >= (COORD_APARC_Y1-ERROR)){
				j = 1;
				sendParkedState(j);
				parked = TRUE;
			}else if(movilXr <= (COORD_APARC_X2+ERROR) && movilXr >= (COORD_APARC_X2-ERROR) && movilYr <= (COORD_APARC_Y2+ERROR) && movilYr >= (COORD_APARC_Y2-ERROR)){
				j = 2;
				sendParkedState(j);
				parked = TRUE;
			}else if(movilXr <= (COORD_APARC_X3+ERROR) && movilXr >= (COORD_APARC_X3-ERROR) && movilYr <= (COORD_APARC_Y3+ERROR) && movilYr >= (COORD_APARC_Y3-ERROR)){
				j = 3;
				sendParkedState(j);
				parked = TRUE;
			}
			return parked;
		}

		void sendReservedState (int i){

			//printf("He reservado la plaza %d con ID %d \n",i, APARC1_ID);
			//printfflush();

			if (i == 1){

				if(!busy){
					// Reserva memoria para el paquete
					SitiosLibresMsg* pktsitioslibres_tx = (SitiosLibresMsg*)(call Packet.getPayload(&pkt, sizeof(SitiosLibresMsg)));
					// Reserva errónea
					if (pktsitioslibres_tx == NULL) {
						return;
					}
					pktsitioslibres_tx->movilAsociado = nodeID;
					pktsitioslibres_tx->estado = RESERVADO;
					pktsitioslibres_tx->ID_plaza = APARC1_ID;
					pktsitioslibres_tx->coorX = COORD_APARC_X1;
					pktsitioslibres_tx->coorY = COORD_APARC_Y1;


					//Envía
					if(call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(SitiosLibresMsg)) == SUCCESS){
						busy = TRUE;	// Ocupado
						reserva_rssi = 1;
					}
				}

				//Si ha encontrado sitio libre, manda mensaje para recibir RSSI y calcular posicion
				//sendMsgRSSI();
			}else if(i == 2){

				if(!busy){
					// Reserva memoria para el paquete
					SitiosLibresMsg* pktsitioslibres_tx = (SitiosLibresMsg*)(call Packet.getPayload(&pkt, sizeof(SitiosLibresMsg)));
					// Reserva errónea
					if (pktsitioslibres_tx == NULL) {
						return;
					}
					pktsitioslibres_tx->movilAsociado = nodeID;
					pktsitioslibres_tx->estado = RESERVADO;
					pktsitioslibres_tx->ID_plaza = APARC2_ID;
					pktsitioslibres_tx->coorX = COORD_APARC_X2;
					pktsitioslibres_tx->coorY = COORD_APARC_Y2;
					//Envía
					if(call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(SitiosLibresMsg)) == SUCCESS){
						busy = TRUE;	// Ocupado
						reserva_rssi = 1;
					}
				}

				//Si ha encontrado sitio libre, manda mensaje para recibir RSSI y calcular posicion
				//sendMsgRSSI();

			}else if(i == 3){

				if(!busy){
				// Reserva memoria para el paquete
					SitiosLibresMsg* pktsitioslibres_tx = (SitiosLibresMsg*)(call Packet.getPayload(&pkt, sizeof(SitiosLibresMsg)));

				// Reserva errónea
					if (pktsitioslibres_tx == NULL) {
						return;
					}
					pktsitioslibres_tx->movilAsociado = nodeID;
					pktsitioslibres_tx->estado = RESERVADO;
					pktsitioslibres_tx->ID_plaza = APARC3_ID;
					pktsitioslibres_tx->coorX = COORD_APARC_X3;
					pktsitioslibres_tx->coorY = COORD_APARC_Y3;
				//Envía
					if(call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(SitiosLibresMsg)) == SUCCESS){
						busy = TRUE;	// Ocupado
						reserva_rssi = 1;
					}
				//Si ha encontrado sitio libre, manda mensaje para recibir RSSI y calcular posicion
				//sendMsgRSSI();
				}
			}
		}

	// Recibe un mensaje de cualquiera de los nodos fijos, el primer mensaje tiene que ser del master
		event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){

			bool parked2 = FALSE;

				call Leds.led0Off();   	// Led 0 Off
				call Leds.led1Off();   	// Led 1 Off
				call Leds.led2Off();    // Led 2 Off

				if (len == sizeof(FijoMsg)) {
				FijoMsg* pktfijo_rx = (FijoMsg*)payload;		// Extrae el payload
				printf("Me llega un mensaje fijo con id %d\n", pktfijo_rx->ID_fijo);
				printfflush();

				// Determina el emisor del mensaje recibido
				if (pktfijo_rx->ID_fijo == MASTER_ID) { 			//Nos ha llegado un paquete del nodo fijo 1
					// Enciende los leds para notificar la llegada de un paquete
					turnOnLeds(pktfijo_rx->ID_fijo);
					printf("He recibido rssi del nodo master\n");
					printfflush();
					rssi = pktfijo_rx->medidaRssi;
					// Calcula la distancia al nodo master en base al RSSI
					distance_nm = getDistance(rssi);
					// Calcula el peso del nodo 1
					w_nm = getWeigth(distance_nm,p);
				}
				else if (pktfijo_rx->ID_fijo == FIJO1_ID) { 			//Nos ha llegado un paquete del nodo fijo 1
					// Enciende los leds para notificar la llegada de un paquete
					turnOnLeds(pktfijo_rx->ID_fijo);
					printf("He recibido rssi del nodo 1\n");
					printfflush();
					rssi = pktfijo_rx->medidaRssi;
					// Calcula la distancia al nodo 1 en base al RSSI
					distance_n1 = getDistance(rssi);
					// Calcula el peso del nodo 1
					w_n1 = getWeigth(distance_n1,p);
				}
				else if (pktfijo_rx->ID_fijo == FIJO2_ID) {		//Nos ha llegado un paquete del nodo fijo 2
					// Enciende los leds para notificar la llegada de un paquete
					turnOnLeds(pktfijo_rx->ID_fijo);
					printf("He recibido rssi del nodo 2\n");
					printfflush();
					rssi = pktfijo_rx->medidaRssi;
					// Calcula la distancia al nodo 2 en base al RSSI
					distance_n2 = getDistance(rssi);
					// Calcula el peso del nodo 2
					w_n2 = getWeigth(distance_n2,p);
				}
				else if (pktfijo_rx->ID_fijo == FIJO3_ID) {		//Nos ha llegado un paquete del nodo fijo 3
					// Enciende los leds para notificar la llegada de un paquete
					turnOnLeds(pktfijo_rx->ID_fijo);
					printf("He recibido rssi del nodo 3\n");
					printfflush();
					rssi = pktfijo_rx->medidaRssi;
					// Calcula la distancia al nodo 3 en base al RSSI
					distance_n3 = getDistance(rssi);
					// Calcula el peso del nodo 3
					w_n3 = getWeigth(distance_n3,p);

					/* Llegados a este punto ya tenemos TODOS los datos de los nodos fijos,
					así que podemos calcular la localizacón del nodo móvil y enviar el resultado*/
					// Calculamos la coordenada X del nodo móvil
					movilX = calculateLocation(w_nm,w_n1,w_n2,w_n3,coorm_x,coor1_x,coor2_x,coor3_x);
					// Calculamos la coordenada Y del nodo móvil
					movilY = calculateLocation(w_nm,w_n1,w_n2,w_n3,coorm_y,coor1_y,coor2_y,coor3_y);

					printf("Ahora mismo estoy en: (%d, %d) \n",movilX, movilY);
					printfflush();

					parked2 = am_i_parked(movilX,movilY);
					if (parked2 == TRUE){
						call Leds.led0On();
						call Leds.led1Off();
						call Leds.led2Off();
						printf("APARCADO!\n");
						reserved = FALSE;
						printfflush();
					}else{
						// Borrar este else despues de depurar!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
						printf("NO APARCADO!\n");
						printfflush();
						sendMsgRSSI();
					}

					// Mandamos las coordenadas calculadas a difusión para que pueda verlo la Base Station
					if (!busy) {
						// Reserva memoria para el paquete
						LocationMsg* pktmovil_loc = (LocationMsg*)(call Packet.getPayload(&pkt, sizeof(LocationMsg)));

						// Reserva errónea
						if (pktmovil_loc == NULL) {
							return 0;
						}

						/*** FORMA EL PAQUETE ***/
						// Campo 1: nodeID
						pktmovil_loc->ID_movil = nodeID;
						// Campo 2: Coordenada X
						pktmovil_loc->coorX = movilX;
						// Campo 3: Coordenada Y
						pktmovil_loc->coorY = movilY;

						pktmovil_loc->distancem = (uint16_t) distance_nm;
						pktmovil_loc->distance1 = (uint16_t) distance_n1;
						pktmovil_loc->distance2 = (uint16_t) distance_n2;
						pktmovil_loc->distance3 = (uint16_t) distance_n3;
						pktmovil_loc->location= TRUE;

						// Envía
						if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(LocationMsg)) == SUCCESS) {
							//						|-> Destino = Difusión
							busy = TRUE;	// Ocupado
						}
					}
					// Si está ocupado mandamos un mensaje reconocido para saberlo
					else {

						printf("Busy no se puede mandar el mensaje de location\n");
						printfflush();
						/*if(!busy){
							// Reserva memoria para el paquete
							LocationMsg* pktmovil_loc = (LocationMsg*)(call Packet.getPayload(&pkt, sizeof(LocationMsg)));

							// Reserva errónea
							if (pktmovil_loc == NULL) {
								return 0;
							}

							pktmovil_loc->ID_movil = 0;
							pktmovil_loc->coorX = 0;
							pktmovil_loc->coorY = 0;

						}*/
						}
					}
				}else if (len == sizeof(SitiosLibresMsg)){
				SitiosLibresMsg* pktsitioslibres_rx = (SitiosLibresMsg*)payload;		// Extrae el payload
				printf("Recibo sitios libres %d\n", contador_3_mensajes);
				printfflush();
				contador_3_mensajes = contador_3_mensajes + 1;
				if(contador_3_mensajes == 3 && reserved == TRUE){
					contador_3_mensajes = 0;
					sendReservedState(z);
				}else{

					if(pktsitioslibres_rx->estado == LIBRE && pktsitioslibres_rx->ID_plaza == APARC1_ID && reserved == FALSE){
						// Enciende led verde para notificar hueco libre encontrado
						call Leds.led0On();   	// Led 0 On
						call Leds.led1Off();   	// Led 1 Off
						call Leds.led2Off();    // Led 2 Off
						printf("Entra en el 1\n");
						z = 1;
						reserved = TRUE;

					}else if (pktsitioslibres_rx->estado == LIBRE && pktsitioslibres_rx->ID_plaza == APARC2_ID && reserved == FALSE){
						call Leds.led0On();   	// Led 0 On
						call Leds.led1Off();   	// Led 1 Off
						call Leds.led2Off();    // Led 2 Off
						printf("Entra en el 2\n");
						z = 2;
						reserved = TRUE;


					}else if(pktsitioslibres_rx->estado == LIBRE && pktsitioslibres_rx->ID_plaza == APARC3_ID && reserved == FALSE){
						call Leds.led0On();   	// Led 0 On
						call Leds.led1Off();   	// Led 1 Off
						call Leds.led2Off();    // Led 2 Off
						printf("Entra en el 3\n");
						printfflush();
						z = 3;
						reserved = TRUE;
						sendReservedState(z);



					}else if(reserved == FALSE && contador_3_mensajes == 3){
						// Enciende led rojo para notificar no hueco libre encontrado
						call Leds.led0Off();   	// Led 0 Off
						call Leds.led1On();   	// Led 1 On
						call Leds.led2Off();    // Led 2 Off
						printf("No hay hueco libre \n");
						printfflush();
						call TimerLedRojo.startOneShot(TIEMPO_ROJO_ENCENDIDO);
					}else{
						printf("Aparcando...\n");
						printfflush();
					}
				}
			}
			return msg;
		}
	}

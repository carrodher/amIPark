#include "../Global.h"
#include "Movil.h"
#include "printf.h"
#include <UserButton.h>
#include <math.h>

module MovilC {
	uses interface Boot;
	uses interface Leds;
	uses interface Timer<TMilli> as VehicleOrderTimer;
	uses interface Timer<TMilli> as RssiRequestTimer;
	uses interface Timer<TMilli> as RedTimer;
	uses interface Timer<TMilli> as GreenTimer;
	uses interface Timer<TMilli> as BlueTimer;
	uses interface Packet;
	uses interface AMPacket;
	uses interface AMSend;
	uses interface Receive;
	uses interface SplitControl as AMControl;
	uses interface Notify<button_state_t>;
}

implementation {
	/* ======== [Variables de la aplicación] ======== */
	uint8_t     nodeID;                     // Almacena el identificador de este nodo
	message_t   pkt;			   	              // Espacio para el pkt a tx
	bool        busy = FALSE;               // Flag para comprobar el estado de la radio
	uint8_t     status = RESTING;           // Estado de ejecución del programa
	uint8_t     i;                          // Índice para recorrer bucles for
	/* ============================================== */


	/* =========== [Datos de los anchors] =========== */
	uint8_t   numberOfAnchors = 0;
	uint8_t   anchorId [NUMBER_OF_ANCHORS]; // = {MASTER_ID, FIJO_1_ID, FIJO_2_ID, FIJO_3_ID};
	uint16_t  anchorX  [NUMBER_OF_ANCHORS]; // = {MASTER_X,  FIJO_1_X,  FIJO_2_X,  FIJO_3_X };
	uint16_t  anchorY  [NUMBER_OF_ANCHORS]; // = {MASTER_Y,  FIJO_1_Y,  FIJO_2_Y,  FIJO_3_Y };
	/* ============================================== */


	/* ========= [Variables de información] ========= */
	uint8_t   destination;                // Destino del siguiente mensaje a enviar (nodeID/Difusión)
	uint8_t   orderToSend;                // Almacena la orden a enviar en el siguiente mensaje
	uint8_t   parkedAt;                   // Id de la plaza en que se aparca (extraData)
	bool      parked = FALSE;             // Indica si se está aparcado

	int16_t   rssiValueReceived;                // Medida RECIBIDA de RSSI
	int16_t   rssiOfAnchor[NUMBER_OF_ANCHORS];  // Medida asociada a cada anchor

	float     a = -21.593;      // Variables para localización
	float     b = -50.093;      //

	ParkingSpot spot[PARKING_SIZE];       // Vector con información de cada plaza libre recibida
	uint8_t     numberOfFreeSpots = 0;    // Número de plazas libres
	/* ============================================== */


	/* ======= [Variables para localización] ======== */
	float   distance[NUMBER_OF_ANCHORS];      // Distancia a nodos fijos Dij
	float   w[NUMBER_OF_ANCHORS];             // Pesos Wij

	uint16_t movilX = 0;                  // Localización del nodo móvil
	uint16_t movilY = 0;                  //

	int p = 1;                            /* Exponente que modifica la influencia de la distancia en los pesos.
	Valores más altos de p dan más importancia a los nodos fijos más cercanos */
	/* ============================================== */


	/* ========= [Declaración de funciones] ========= */
	float    getDistance(int16_t rssi);
	float    getWeight(float d);
	int16_t  computeLocation(float* w_t, uint16_t* c);
	void     getLocation(int16_t* rssi);
	void     printfFloat(float floatToBePrinted);
	void     turnOnLed  (uint8_t led, uint16_t time);
	void     turnOffLed (uint8_t led);
	bool     getAssignedSlot (uint8_t slots, nx_uint8_t* slotsOwners, uint8_t* assignedSlot);
	void     sendVehicleOrderMessage();
	void     sendBeaconMessage();
	void     newRssiMeasureReceived(uint8_t nodeId);
	void     am_i_parked(uint16_t movilXr, uint16_t movilYr);
	/* ============================================== */


	/**
	*   Evento de pulsación del botón
	*/
	event void Notify.notify(button_state_t state) {
		// Comprobar si está pulsado
		if (state == BUTTON_PRESSED) {
			printf("Pulsado\n");
			printfflush();

			// Cambiar a estado para solicitar un slot de comunicación con el master
			status = WAITING_FOR_COMM_SLOT;
		}
		else if (state == BUTTON_RELEASED) {
			// Nada que hacer
		}
	}


	/**
	*   Calcula la distancia a partir del RSSI
	*   Fórmula: RSSI(D) = a·log(D) + b; D = 10^((RSSI-b)/a)
	*/
	float getDistance(int16_t rssi) {
		float rssi_float = (float) rssi;      // Convertir RSSI a float
		return powf(10, (rssi_float-b)/a );
	}


	/**
	*   Calcula el peso: w = 1/(D^p)
	*/
	float getWeight(float d) {
		return 1/(powf(d,p));
	}


	/**
	*   Calcula una coordenada referente a la localización del nodo
	*   Parámetros: vector de pesos y coordenadas (x o y)
	*   Fórmula:
	*     X = (wm·xm + w1·x1 + w2·x2 + w3·x3)/(wm + w1 + w2 + w3)
	*     Y = (wm·ym + w1·y1 + w2·y2 + w3·y3)/(wm + w1 + w2 + w3)
	*/
	int16_t computeLocation(float* w_t, uint16_t* c) {
		// Variables temporales de cálculo
		float numerator   = 0;
		float denominator = 0;

		for (i=0 ; i<numberOfAnchors ; i++) {
			numerator   += w_t[i]*c[i];
			denominator += w_t[i];
		}

		return numerator/denominator;
	}



	/**
	*   Comprueba si esta aparcado en una de las plazas de aparcamiento
	*   Devuelve 0 si no esta aparcado
	*/
	void am_i_parked(uint16_t movilXr, uint16_t movilYr) {
		// Recorrer los datos de cada plaza libre disponible
		for (i=0 ; i<numberOfFreeSpots ; i++) {
			// Comparar la posición actual con la de la plaza
			if ( movilXr <= (spot[i].x + ERROR) && movilXr >= (spot[i].x - ERROR) && movilYr <= (spot[i].y + ERROR) && movilYr >= (spot[i].y - ERROR) ) {
				parkedAt = spot[i].id;    // Guardar ID de la plaza en que se ha aparcado
				parked   = TRUE;          // Se ha aparcado
				status   = PARKED;        // Pasar al estado "Aparcado"

				printf("He aparcado en la plaza %d\n", parkedAt);
				printfflush();
			}
		}
	}



	/**
	*   Obtiene la localización del nodo y la almacena en las variables globales movilX y movilY
	*   Devuelve verdadero si fue correcta la operación
	*/
	void getLocation(int16_t* rssi) {
		// Calcular las distancias y pesos de cada anchor
		for (i=0 ; i<numberOfAnchors ; i++) {
			distance[i] = getDistance(rssi[i]);       // Obtener distancia al nodo
			w[i]        = getWeight(distance[i]);     // Obtener peso relativo
		}

		// Calcular las coordenadas del movil y almacenarlas
		movilX = computeLocation(w,anchorX);
		movilY = computeLocation(w,anchorY);

		printf("[INFO] Nueva localizacion: x=%d, y=%d\n", movilX, movilY);
		printfflush();

		am_i_parked(movilX, movilY);
	}




	/**
	*   Usa printf() para imprimir un flotante
	*/
	void printfFloat(float floatToBePrinted) {
		uint32_t fi, f0, f1, f2, f3;
		char c;
		float f = floatToBePrinted;

		if (f<0){
			c = '-';    // Añade signo negativo
			f = -f;     // Invertir signo al flotante
		}
		else {
			c = ' ';    // Añade signo "Positivo"
		}

		// Obtener parte entera
		fi = (uint32_t) f;

		// Parte decimal (4 decimales)
		f  = f - ((float) fi);          // Restar parte entera
		f0 = f*10;    f0 %= 10;
		f1 = f*100;   f1 %= 10;
		f2 = f*1000;  f2 %= 10;
		f3 = f*10000; f3 %= 10;
		printf("%c%ld.%d%d%d%d", c, fi, (uint8_t) f0, (uint8_t) f1, (uint8_t) f2, (uint8_t) f3);
		printfflush();
	}



	/**
	*   Enciende el led indicado (y lo apaga pasado el tiempo especificado en ms)
	*   Si timeOn = 0 no se apagará el led
	*/
	void turnOnLed (uint8_t led, uint16_t timeOn) {
		switch (led) {
			case RED:
				call Leds.led0On();
				if (timeOn > 0)
					call RedTimer.startOneShot(timeOn);
				break;
			case GREEN:
				call Leds.led1On();
				if (timeOn > 0)
					call GreenTimer.startOneShot(timeOn);
				break;
			case BLUE:
				call Leds.led2On();
				if (timeOn > 0)
					call BlueTimer.startOneShot(timeOn);
				break;
		}
	}



	/**
	*   Apaga el led indicado
	*/
	void turnOffLed (uint8_t led) {
		switch (led) {
			case RED:
				call Leds.led0Off();
				break;
			case GREEN:
				call Leds.led1Off();
				break;
			case BLUE:
				call Leds.led2Off();
				break;
		}
	}



	/**
	*   Devuelve verdadero si se tiene un slot asignado a este nodo (a su ID) y su número por referencia
	*/
	bool getAssignedSlot (uint8_t slots, nx_uint8_t* slotsOwners, uint8_t* assignedSlot) {

		// Flag
		bool hasAssignedSlot = FALSE;

		// Índice para recorrer el vector slotsOwners
		uint8_t slotId;

		for (slotId = 0 ; slotId<slots ; slotId++) {
			if (slotsOwners[slotId] == nodeID) {
				// Afirmar que se tiene un slot
				hasAssignedSlot = TRUE;
				// Y guardar el slot asignado en la variable pasada por referencia
				*assignedSlot = slotId;
			}
		}

		return hasAssignedSlot;
	}



	/**
	*   Envia un mensaje de tipo VehicleOrder
	*   Usar variable "destination" para indicar el destino: AM_BROADCAST_ADDR para difussión, en cualquier otro caso el nodeID destino
	*/
	void sendVehicleOrderMessage() {

		uint16_t messageLength = 0;       // Almacenará el tamaño del mensaje a enviar
		VehicleOrder* msg_tx = NULL;      // Necesario crear el puntero previamente

		// Reserva memoria para el paquete
		messageLength = sizeof(VehicleOrder);
		msg_tx = (VehicleOrder*) call Packet.getPayload(&pkt, messageLength);

		// Comprobar que se realizó la reserva de memoria correctamente
		if (msg_tx == NULL) {
			printf("[ERROR] Reserva de memoria\n");
			printfflush();
		}
		else {
			// Añadir el id del nodo origen
			msg_tx->nodeID  = nodeID;

			// Añadir la orden
			msg_tx->order = orderToSend;

			// Adjuntar datos adicionales según la orden especificada
			switch (orderToSend) {
				case COMM_SLOT_REQUEST:
					// Nada que adjuntar
					break;
				case PARKING_INFO_REQUEST:
					// Nada que adjuntar
					break;
				case SPOT_TAKEN_UP:
					// Adjuntar el ID de la plaza ocupada
					msg_tx->extraData = parkedAt;
					break;
				case SPOT_RELEASED:
					// Adjuntar el ID de la plaza liberada
					msg_tx->extraData = parkedAt;
					break;
			}

			// Comprobar que no esté ocupado el transmisor
			if (!busy) {
				// Enviar y comprobar el resultado
				if(call AMSend.send(destination, &pkt, messageLength) == SUCCESS) {
					busy = TRUE;      // Ocupado
					printf("[DEBUG] Enviado mensaje VehicleOrder / Orden: %d\n", orderToSend);
					printfflush();
					// Notificación visual de envio de mensaje
					turnOnLed(RED, LED_BLINK_TIME);
				}
				else {
					printf("[ERROR] Mensaje no enviado\n");
					printfflush();
				}
			}
			else {
				printf("[ERROR] Bussy\n");
				printfflush();
			}
		}
	}



	/**
	*   Envia un mensaje de tipo TdmaRssiRequestFrame a difusión
	*   Se trata de la trama que indica a los anchors (fijos y master) cuando pueden enviar la medida RSSI de este mismo mensaje
	*/
	void sendTdmaRssiRequestMessage() {

		uint16_t messageLength = 0;               // Almacenará el tamaño del mensaje a enviar
		TdmaRssiRequestFrame* msg_tx = NULL;      // Necesario crear el puntero previamente

		// Reserva memoria para el paquete
		messageLength = sizeof(TdmaRssiRequestFrame);
		msg_tx = (TdmaRssiRequestFrame*) call Packet.getPayload(&pkt, messageLength);

		// Comprobar que se realizó la reserva de memoria correctamente
		if (msg_tx == NULL) {
			printf("[ERROR] Reserva de memoria\n");
			printfflush();
		}
		else {

			// Añadir el id del nodo origen
			msg_tx->nodeID  = nodeID;

			// Añadir el número de slots actualmente en uso y el tiempo reservado a cada cual
			msg_tx->slots = numberOfAnchors;
			msg_tx->tSlot = TDMA_RSSI_REQUEST_SLOT_TIME;
			msg_tx->x = movilX;
			msg_tx->y = movilY;

			// Asignar los slots a los IDs correspondientes
			for (i=0 ; i<numberOfAnchors ; i++) {
				msg_tx->slotsOwners[i] = anchorId[i];
			}

			// Comprobar que no esté ocupado el transmisor
			if (!busy) {
				// Enviar y comprobar el resultado
				if(call AMSend.send(AM_BROADCAST_ADDR, &pkt, messageLength) == SUCCESS) {
					busy = TRUE;      // Ocupado
					printf("[DEBUG] Enviado mensaje TdmaRssiRequestFrame\n");
					printfflush();
					// Notificación visual de envio de mensaje
					turnOnLed(RED, LED_BLINK_TIME);
				}
				else {
					printf("[ERROR] Mensaje no enviado\n");
					printfflush();
				}
			}
			else {
				printf("[ERROR] Bussy\n");
				printfflush();
			}
		}
	}



	/**
	*   Mensaje recibido
	*/
	event message_t* Receive.receive(message_t* msg, void* payload, uint8_t length) {
		// Vector de IDs asociados a cada slot ofrecido en una trama TDMA
		uint8_t assignedSlot;

		// Notificación visual de recepción de mensaje
		turnOnLed(GREEN, LED_BLINK_TIME);

		/* ---------------------------------------- *
		*  DETERMINAR EL TIPO DE MENSAJE RECIBIDO  *
		* ---------------------------------------- */

		// >>>> RssiMsg <<<<
		if (length == sizeof(RssiMsg)) {
			// Extraer el payload
			RssiMsg* msg_rx = (RssiMsg*)payload;

			printf("Recibido: RssiMsg / Orden: %d\n", msg_rx->order);
			printfflush();

			// Determinar la orden recibida
			switch (msg_rx->order) {
				case RSSI_MEASURE:
					// Almacenar la medida RSSI recivida
					rssiValueReceived = msg_rx->rssiValue;
					printf("Recibida medida RSSI del nodo %d con valor: %d\n", msg_rx->nodeID, rssiValueReceived);
					printfflush();
					// Tratar la nueva medida
					newRssiMeasureReceived(msg_rx->nodeID);
					break;
			}
		}
		// >>>> TdmaBeaconFrame <<<<
		else if (length == sizeof(TdmaBeaconFrame)) {
			// Extraer el payload
			TdmaBeaconFrame* msg_rx = (TdmaBeaconFrame*)payload;

			printf("Recibido: TdmaBeaconFrame | status=%d\n", status);
			printfflush();

			// Si se tiene un slot asociado...
			if (getAssignedSlot(msg_rx->slots, msg_rx->slotsOwners, &assignedSlot)) {
				printf("Se tiene el slot: %d\n", assignedSlot);
				printfflush();

				// Reaccionar en función del estado actual del programa
				switch (status) {
					case RESTING:
						// Nada que hacer
						break;
					case WAITING_FOR_COMM_SLOT:
						// Si se llega aquí es porque se ha conseguido un slot para transmitir
						// Comprobar si se está ocupando ya una plaza del parking
						if(!parked) {
							// Si no esta aparcado, el siguiente paso sería solicitar la informacion del parking
							status = REQUESTING_PARKING_INFO;
						}
						else {
							// Si esta aparcado, al darle al boton lo que quiere es liberar la plaza y salir del parking
							status = DRIVE_OFF;
						}
						break;
					case REQUESTING_PARKING_INFO:
						// Solicitar al master información del parking
						numberOfFreeSpots = 0;                    // Resetear variables que se han de deducir de los datos a recibir
						numberOfAnchors   = 0;                    //
						destination = msg_rx->nodeID;             // Destino el nodo master que envió el beacon
						orderToSend = PARKING_INFO_REQUEST;       // Orden de solicitud de información del parking
						// Enviar orden de solicitud de información del parking
						call VehicleOrderTimer.startOneShot( assignedSlot * (msg_rx->tSlot) + TIMER_OFFSET );
						break;
					case LOCATING:
						// Resetear acumulador de medidas RSSI
						for (i=0 ; i<numberOfAnchors ; i++) {
							rssiOfAnchor[i] = 0;
						}
						// Preparar el siguiente envio de la trama tdma de petición de medida RSSI
						call RssiRequestTimer.startOneShot( assignedSlot * (msg_rx->tSlot) + TIMER_OFFSET );
						break;
					case PARKED:
						destination = msg_rx->nodeID;       // Destino el nodo master que envió el beacon
						orderToSend = SPOT_TAKEN_UP;        // Orden de solicitud de slot de comunicación
						// Enviar orden de solicitud de ocupación de una plaza
						call VehicleOrderTimer.startOneShot( assignedSlot * (msg_rx->tSlot) + TIMER_OFFSET );
						break;
					case DRIVE_OFF:
						printf("Estoy abandonando la plaza %d\n", parkedAt);
						printfflush();
						destination = msg_rx->nodeID;       // Destino el nodo master que envió el beacon
						orderToSend = SPOT_RELEASED;        // Orden de solicitud de slot de comunicación
						parked = FALSE;                     // Ya no se tendría ninguna plaza de parking
						// Enviar orden de solicitud de liberación de una plaza
						call VehicleOrderTimer.startOneShot( assignedSlot * (msg_rx->tSlot) + TIMER_OFFSET );
						break;
				}
			}
			else {
				printf("No se tiene slot asociado\n");
				printfflush();

				// Reaccionar en función del estado actual del programa
				switch (status) {
					case RESTING:
						// Nada que hacer
						break;
					case WAITING_FOR_COMM_SLOT:
						// Enviar solicitud de reserva de slot para comunicación con el master
						destination = msg_rx->nodeID;       // Destino el nodo master que envió el beacon
						orderToSend = COMM_SLOT_REQUEST;    // Orden de solicitud de slot de comunicación
						// Enviar orden en el slot dedicado a nuevas asociaciones de vehículos, al final de los slots reservados
						call VehicleOrderTimer.startOneShot( (msg_rx->slots)*(msg_rx->tSlot) + nodeID/10 );
						break;
					case REQUESTING_PARKING_INFO:
						// Si se llega aquí sería por que se perdió por algún motivo el slot de comunicación, volver a pedirlo
						status = WAITING_FOR_COMM_SLOT;
						break;
					case LOCATING:
						// Si se llega aquí sería por que se perdió por algún motivo el slot de comunicación, volver a pedirlo
						status = WAITING_FOR_COMM_SLOT;
						break;
					case PARKED:
						// Nada que hacer
						break;
				}
			}
		}
		// >>>> UpdateConstants <<<<
		else if (length == sizeof(UpdateConstants)) {
			// Extraer el payload
			UpdateConstants* msg_rx = (UpdateConstants*)payload;

			printf("Recibido: UpdateConstants");
			printfflush();

			a = msg_rx->a;
			b = msg_rx->b;
			// Extraer los datos asociados "a" y "b"
			printf(" | a="); printfFloat(a); printf(" b="); printfFloat(b); printf("\n");
			printfflush();
		}
		// >>>> ParkingInfo <<<<
		else if (length == sizeof(ParkingInfo)) {
			// Extraer el payload
			ParkingInfo* msg_rx = (ParkingInfo*)payload;

			printf("Recibido: ParkingInfo / Orden: %d\n", msg_rx->order);
			printfflush();

			// Determinar la orden recibida
			switch (msg_rx->order) {
				case PARKING_SPOT:
					// Almacenar la nueva plaza de parking libre recibida
					spot[numberOfFreeSpots].id = msg_rx->id;
					spot[numberOfFreeSpots].x  = msg_rx->x;
					spot[numberOfFreeSpots].y  = msg_rx->y;
					numberOfFreeSpots++;      // Contabilizar una nueva plaza libre
					status = LOCATING;        // Como se tiene al menos una plaza, el siguiente estado será el de solicitar localización
					printf("Recibida plaza libre con id: %d [x=%d / y=%d]\n", msg_rx->id, msg_rx->x, msg_rx->y);
					printfflush();
					break;
				case ANCHOR_POSITION:
					// Almacenar el nuevo anchor recibido
					anchorId[numberOfAnchors] = msg_rx->id;
					anchorX[numberOfAnchors]  = msg_rx->x;
					anchorY[numberOfAnchors]  = msg_rx->y;
					numberOfAnchors++;        // Contabilizar un nuevo anchor
					printf("Recibida informacion del anchor con id: %d [x=%d / y=%d]\n", msg_rx->id, msg_rx->x, msg_rx->y);
					printfflush();
					break;
				case NO_SPOTS_AVAILABLE:
					// El parking no tiene plazas libres
					printf("Master informa de que no hay plazas libres\n");
					printfflush();
					// Volver al estado de reposo
					status = RESTING;
					turnOnLed(RED,2000);
					turnOnLed(GREEN,2000);
					break;
			}
		}
		else {
			printf("[ERROR] Recibido mensaje de tipo desconocido\n");
			printfflush();
		}
		return msg;
	}



	/**
	*   Se ejecuta cada vez que se recibe una medida RSSI de uno de los nodos fijos
	*/
	void newRssiMeasureReceived(uint8_t nodeId) {
		// Flags
		bool allMeasuresReceived = TRUE;    // Indica si se tienen todas las medidas
		bool error               = TRUE;    // Indica si hubo algún error

		// Por cada anchor tenido en cuenta...
		for (i=0 ; i<numberOfAnchors ; i++) {
			// Encontrado el nodo del cual se ha recibido una medida RSSI
			if (anchorId[i] == nodeId) {
				rssiOfAnchor[i] = rssiValueReceived;  // Asociar la medida al nodo
				error = FALSE;                        // La medida se ha asociado al nodo esperado, no hay fallos
			}
			// Comprobar además si se tiene la medida de cada nodo ya
			if (rssiOfAnchor[i] == 0) {
				allMeasuresReceived = FALSE;          // Al menos una de las medidas aun no se ha recibido
			}
		}

		// Si ya se tienen todas las medidas...
		if (allMeasuresReceived) {
			getLocation(rssiOfAnchor);              // Obtener la localización del nodo
		}

		if (error) {
			printf("[ERROR] Recibida medida RSSI que no se corresponde con ningún anchor\n");
			printfflush();
		}
	}



	/**
	*   Se ejecuta al alimentar t-mote. Arranca la radio
	*/
	event void Boot.booted() {
		call AMControl.start();
		call Notify.enable();

		// Obtenemos el ID de este nodo
		nodeID = TOS_NODE_ID;
		printf("nodeID=%d\n", nodeID);
		printfflush();

		// Inicializar variables
		for (i=0 ; i<NUMBER_OF_ANCHORS ; i++) {
			rssiOfAnchor[i] = 0;
		}

		// Inicializar el vector con la información de las plazas de aparcamiento
		/*    for (i=0 ; i<PARKING_SIZE ; i++) {
		parkingStatus.spot[i].id  = spotId[i];
		parkingStatus.spot[i].x   = spotX [i];
		parkingStatus.spot[i].y   = spotY [i];
		parkingStatus.free[i]     = TRUE;
		}*/

		// Notificar visualmente que el mote está encendido
		turnOnLed(BLUE,0);
	}



	/**
	*   Arranca la radio si la primera vez hubo algún error
	*/
	event void AMControl.startDone(error_t err) {
		if (err != SUCCESS) {
			call AMControl.start();
		}
	}



	/**
	*   Detención de la radio
	*/
	event void AMControl.stopDone(error_t err) {
		// Nada que hacer
	}



	/**
	*   Completada transmisión de mensaje
	*/
	event void AMSend.sendDone(message_t* msg, error_t err) {
		if (&pkt == msg) {
			busy = FALSE;     // Libre
		}
	}



	/**
	*   Activación del temporizador VehicleOrderTimer
	*/
	event void VehicleOrderTimer.fired() {
		sendVehicleOrderMessage();
	}



	/**
	*   Activación del temporizador RssiRequestTimer
	*/
	event void RssiRequestTimer.fired() {
		sendTdmaRssiRequestMessage();
	}



	/**
	*   Activación del temporizador RedTimer
	*/
	event void RedTimer.fired() {
		// Apagar el led rojo
		turnOffLed(RED);
	}



	/**
	*   Activación del temporizador GreenTimer
	*/
	event void GreenTimer.fired() {
		// Apagar el led verde
		turnOffLed(GREEN);
	}

	

	/**
	*   Activación del temporizador BlueTimer
	*/
	event void BlueTimer.fired() {
		// Apagar el led azul
		turnOffLed(BLUE);
	}
}

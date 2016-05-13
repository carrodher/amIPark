#include "Master.h"
#include "printf.h"


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
	uint16_t ID_plaza1 = APARC1_ID;
	uint16_t coorX1 = COORD_APARC_X1;
	uint16_t coorY1 = COORD_APARC_Y1;
	uint16_t movilAsociado1 = NO_MOVIL_ASOCIADO;		//ID del movil que esta aparcado o quiere aparcarse
	uint16_t estado1 = LIBRE;			//estado de la plaza de aparcamiento (libre 0, reservado 1, ocupado 2)
	uint16_t ID_plaza2 = APARC2_ID;
	uint16_t coorX2 = COORD_APARC_X2;
	uint16_t coorY2 = COORD_APARC_Y2;
	uint16_t movilAsociado2 = NO_MOVIL_ASOCIADO;				//ID del movil que esta aparcado o quiere aparcarse
	uint16_t estado2 = LIBRE;			//estado de la plaza de aparcamiento (libre 0, reservado 1, ocupado 2)
	uint16_t ID_plaza3 = APARC3_ID;
	uint16_t coorX3 = COORD_APARC_X3;
	uint16_t coorY3 = COORD_APARC_Y3;
	uint16_t movilAsociado3 = NO_MOVIL_ASOCIADO;	//ID del movil que esta aparcado o quiere aparcarse
	uint16_t estado3  = LIBRE;			//estado de la plaza de aparcamiento (libre 0, reservado 1, ocupado 2)

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

	void printParkPlacesState(uint16_t estado, uint16_t ID_plaza, uint16_t coorX, uint16_t coorY){

		switch (estado){
			case LIBRE:
				printf("El estado de la plaza %d con coordenadas (%d,%d) se encuentra libre", ID_plaza, coorX, coorY);
			break;
			case RESERVADO:
				printf("El estado de la plaza %d con coordenadas (%d,%d) se encuentra reservado", ID_plaza, coorX, coorY);
			break;
			case OCUPADO:
				printf("El estado de la plaza %d con coordenadas (%d,%d) se encuentra ocupado", ID_plaza, coorX, coorY);
			break;
		}

		printfflush();
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

	void sendParkPlaces(){
		SitiosLibresMsg* pktsitioslibres_tx = (SitiosLibresMsg*)(call Packet.getPayload(&pkt, sizeof(SitiosLibresMsg)));
			// Reserva errónea
			if (pktsitioslibres_tx == NULL) {
				return;
			}
			//Forma el paquete
			// Campos plaza 1
			pktsitioslibres_tx->ID_plaza1 = ID_plaza1;
			pktsitioslibres_tx->coorX1 = coorX1;
			pktsitioslibres_tx->coorY1 = coorY1;
			pktsitioslibres_tx->movilAsociado1 = movilAsociado1;
			pktsitioslibres_tx->estado1 = estado1;
			// Campos plaza 2
			pktsitioslibres_tx->ID_plaza2 = ID_plaza2;
			pktsitioslibres_tx->coorX2 = coorX2;
			pktsitioslibres_tx->coorY2 = coorY2;
			pktsitioslibres_tx->movilAsociado2 = movilAsociado2;
			pktsitioslibres_tx->estado2 = estado2;
			// Campos plaza 3
			pktsitioslibres_tx->ID_plaza3 = ID_plaza3;
			pktsitioslibres_tx->coorX3 = coorX3;
			pktsitioslibres_tx->coorY3 = coorY3;
			pktsitioslibres_tx->movilAsociado3 = movilAsociado3;
			pktsitioslibres_tx->estado3 = estado3;
			
			// Envía
			if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(SitiosLibresMsg)) == SUCCESS) {
				busy = TRUE;
				// Enciende los 3 leds cuando envía el paquete largo primero
				printParkPlacesState(estado1, ID_plaza1, coorX1, coorY1);
				printParkPlacesState(estado2, ID_plaza2, coorX2, coorY2);
				printParkPlacesState(estado3, ID_plaza3, coorX3, coorY3);
				call Leds.led0On();
				call Leds.led1On();
				call Leds.led2On();
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

			sendParkPlaces();

		}else if (len == sizeof (SitiosLibresMsg)) {
			SitiosLibresMsg* pktsitioslibres_rx = (SitiosLibresMsg*)payload;	//Extrae el payload
			if (pktsitioslibres_rx->movilAsociado1 != NO_MOVIL_ASOCIADO) {
				if(pktsitioslibres_rx->estado1 == RESERVADO){
					movilAsociado1 = pktsitioslibres_rx->movilAsociado1;
					estado1 = pktsitioslibres_rx->estado1;
				}else if(pktsitioslibres_rx->estado1 == OCUPADO){
					movilAsociado1 = pktsitioslibres_rx->movilAsociado1;
					estado1 = pktsitioslibres_rx->estado1;
				}
			}else if (pktsitioslibres_rx->movilAsociado2 != NO_MOVIL_ASOCIADO) {
				if(pktsitioslibres_rx->estado2 == RESERVADO){
					movilAsociado2 = pktsitioslibres_rx->movilAsociado2;
					estado2 = pktsitioslibres_rx->estado2;
				}else if(pktsitioslibres_rx->estado2 == OCUPADO){
					movilAsociado2 = pktsitioslibres_rx->movilAsociado2;
					estado2 = pktsitioslibres_rx->estado2;
				}
			}else if (pktsitioslibres_rx->movilAsociado3 != NO_MOVIL_ASOCIADO) {
				if(pktsitioslibres_rx->estado3 == RESERVADO){
					movilAsociado3 = pktsitioslibres_rx->movilAsociado3;
					estado3 = pktsitioslibres_rx->estado3;
				}else if(pktsitioslibres_rx->estado3 == OCUPADO){
					movilAsociado3 = pktsitioslibres_rx->movilAsociado3;
					estado3 = pktsitioslibres_rx->estado3;
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

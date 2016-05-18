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
	
	uint16_t manda3mensajes = 0;
	uint16_t adios = 0;

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
				printf("La plaza %d con coordenadas (%d,%d) se encuentra libre\n", ID_plaza, coorX, coorY);
				printfflush();
			break;
			case RESERVADO:
				printf("La plaza %d con coordenadas (%d,%d) se encuentra reservada\n", ID_plaza, coorX, coorY);
				printfflush();
			break;
			case OCUPADO:
				printf("La plaza %d con coordenadas (%d,%d) se encuentra ocupada\n", ID_plaza, coorX, coorY);
				printfflush();
			break;
		}
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
		printf("Estoy en Timer0\n");
		printfflush();
		if (!busy) {
			// Reserva memoria para el paquete
			FijoMsg* pktfijo_tx = (FijoMsg*)(call Packet.getPayload(&pkt, sizeof(FijoMsg)));

			// Reserva errónea
			if (pktfijo_tx == NULL) {
				printf("Reserva de FijoMsg erronea\n");
				printfflush();
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
				printf("FijoMsg mandado con SUCCESS a %d tamanio %d\n", MOVIL_ID, sizeof(FijoMsg));
				printfflush();
				printf("Busy: %d\n", busy);
				printfflush();
				adios = 1;
				busy = TRUE;	// Ocupado
				call Leds.led0Off();   // Led 0 Off
				call Leds.led1On();    // Led 1 ON cuando envío mi paquete
				call Leds.led2Off();
			}
		}else{
			printf("Canal busy para mandar FijoMsg\n");
			printfflush();
		}
	}


	void sendParkPlaces1(){
		if(!busy){
			SitiosLibresMsg* pktsitioslibres_tx = (SitiosLibresMsg*)(call Packet.getPayload(&pkt, sizeof(SitiosLibresMsg)));
			// Reserva errónea
			if (pktsitioslibres_tx == NULL) {
				return;
			}
			//Forma el paquete
			// Campos plaza 1 (mensaje1)
			pktsitioslibres_tx->ID_plaza = ID_plaza1;
			pktsitioslibres_tx->coorX = coorX1;
			pktsitioslibres_tx->coorY = coorY1;
			pktsitioslibres_tx->movilAsociado = movilAsociado1;
			pktsitioslibres_tx->estado = estado1;
			
			// Envía
			if (call AMSend.send(MOVIL_ID, &pkt, sizeof(SitiosLibresMsg)) == SUCCESS) {
				manda3mensajes = 1;
				busy = TRUE;
				printf("id= %d\n", nodeID);
    			printfflush();
				printf("Envio SitiosLibresMsg 1\n");
				printfflush();
				// Enciende los 3 leds cuando envía el paquete largo primero e imprime el estado de las plazas
				if(estado1==OCUPADO && estado2==OCUPADO && estado3==OCUPADO){
					printf("Todas las plazas están ocupadas\n");
					printfflush();
				}else{
					printParkPlacesState(estado1, 1, coorX1, coorY1);

				}
				call Leds.led0On();
				call Leds.led1On();
				call Leds.led2On();
				
			}
		}
	}
	void sendParkPlaces2(){
		if(!busy){
			SitiosLibresMsg* pktsitioslibres_tx = (SitiosLibresMsg*)(call Packet.getPayload(&pkt, sizeof(SitiosLibresMsg)));
			// Reserva errónea
		
			if (pktsitioslibres_tx == NULL) {
				return;
			}
			//Forma el paquete

			// Campos plaza 2 (mensaje2)
			pktsitioslibres_tx->ID_plaza = ID_plaza2;
			pktsitioslibres_tx->coorX = coorX2;
			pktsitioslibres_tx->coorY = coorY2;
			pktsitioslibres_tx->movilAsociado = movilAsociado2;
			pktsitioslibres_tx->estado = estado2;

			
			// Envía
			if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(SitiosLibresMsg)) == SUCCESS) {
				manda3mensajes = 2;
				busy = TRUE;
				printf("Envio SitiosLibresMsg 2\n");
				printfflush();
				// Enciende los 3 leds cuando envía el paquete largo primero e imprime el estado de las plazas
				if(estado1==OCUPADO && estado2==OCUPADO && estado3==OCUPADO){
					printf("\n");
					printfflush();
				}else{
					
					printParkPlacesState(estado2, 2, coorX2, coorY2);
				}
				call Leds.led0On();
				call Leds.led1On();
				call Leds.led2On();
			}
		}else{
			printf("HOLA JUAPI\n");
			printfflush();
		}	
	}
	void sendParkPlaces3(){
		if(!busy){
			SitiosLibresMsg* pktsitioslibres_tx = (SitiosLibresMsg*)(call Packet.getPayload(&pkt, sizeof(SitiosLibresMsg)));
			// Reserva errónea
			if (pktsitioslibres_tx == NULL) {
				return;
			}
	

			// Campos plaza 3 (mensaje3)
			pktsitioslibres_tx->ID_plaza = ID_plaza3;
			pktsitioslibres_tx->coorX = coorX3;
			pktsitioslibres_tx->coorY = coorY3;
			pktsitioslibres_tx->movilAsociado = movilAsociado3;
			pktsitioslibres_tx->estado = estado3;
			
			// Envía
			if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(SitiosLibresMsg)) == SUCCESS) {
				manda3mensajes = 3;
				busy = TRUE;
				printf("Envio SitiosLibresMsg 3\n");
				printfflush();
				// Enciende los 3 leds cuando envía el paquete largo primero e imprime el estado de las plazas
				if(estado1==OCUPADO && estado2==OCUPADO && estado3==OCUPADO){
					printf("\n");
					printfflush();
				}else{
					printParkPlacesState(estado3, 3, coorX3, coorY3);
				}
				call Leds.led0On();
				call Leds.led1On();
				call Leds.led2On();
			}
		}else{
			printf("HOLA JUAPI\n");
			printfflush();
		}	
	}

	// Comprueba la tx del pkt y marca como libre si ha terminado
	event void AMSend.sendDone(message_t* msg, error_t err) {
		if (&pkt == msg) {
			busy = FALSE;	// Libre
		}
		
		if(manda3mensajes == 1){
			sendParkPlaces2();
		}else if (manda3mensajes == 2){
			sendParkPlaces3();
		}else if (manda3mensajes == 3){
			manda3mensajes = 0;
			printf("Se han mandado las tres plazas\n");
			printfflush();
		}

		if(adios == 1){
			printf("Se ha mandado el fijo\n");
			printfflush();
			adios = 0;
		}

	}

	

	event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
		// Si el paquete tiene la longitud de un paquete que pide el RSSI y es del nodo móvil
		printf("Mensaje recibido de longitud %d\n", len);
		printfflush();
		if (len == sizeof(MovilMsg)) {
			MovilMsg* pktmovil_rx = (MovilMsg*)payload;		// Extrae el payload
			printf("El nodo %d me esta pidiendo el RSSI\n", pktmovil_rx->ID_movil);
			printfflush();
			call Leds.led0On();    // Led 0 ON cuando me llega el paquete del móvil
			call Leds.led1Off();   // Led 1 OFF
			call Leds.led2Off();
			rssi2 = getRssi(msg);		// Obtiene el RSSI
			// Comprueba el slot que se le ha asignado
			// 1º slot => Transmitir
			if (pktmovil_rx->master == nodeID) {
				// No espera "nada"
				call Timer0.startOneShot(1);
			}
			// 2º slot => Esperar 1 slot y Transmitir
			else if (pktmovil_rx->first == nodeID) {
				// Espera 1 slot = Periodo/nº slots
				printf("Me voy pal Timer0\n");
				printfflush();
				call Timer0.startOneShot(pktmovil_rx->Tslot);
			}
			// 3º slot => Esperar 2 slots y Transmitir
			else if (pktmovil_rx->second == nodeID) {
				// Espera 2 slots = 2*Periodo/nº slots
				printf("Me voy pal Timer0\n");
				printfflush();
				call Timer0.startOneShot(2*pktmovil_rx->Tslot);
			}else if (pktmovil_rx->third == nodeID) {
				// Espera 3 slots = 3*Periodo/nº slots
				printf("Me voy pal Timer0\n");
				printfflush();
				call Timer0.startOneShot(3*pktmovil_rx->Tslot);
			}
		}else if (len == sizeof(LlegadaMsg)) {
			LlegadaMsg* pktllegada_rx = (LlegadaMsg*)payload;	//Extrae el payload
			/* si hubiese que comprobarse algo del mensaje de hola que tal se haria aqui */ 
			printf("Me voy pal sendParkPlaces1\n");
			printfflush();
			sendParkPlaces1();
			
			//sendParkPlaces2();
			//sendParkPlaces3();

		}else if (len == sizeof (SitiosLibresMsg)) {
			SitiosLibresMsg* pktsitioslibres_rx = (SitiosLibresMsg*)payload;	//Extrae el payload
			//printf("LLEGAMOS AQUI CON ESTADO: %d MOVIL ASOCIADO %d ID_plaza %d \n", pktsitioslibres_rx->estado, pktsitioslibres_rx->movilAsociado, pktsitioslibres_rx->ID_plaza);
			//printfflush();
			if (pktsitioslibres_rx->movilAsociado != NO_MOVIL_ASOCIADO && pktsitioslibres_rx->ID_plaza == APARC1_ID) {
				if(pktsitioslibres_rx->estado == RESERVADO ){
					movilAsociado1 = pktsitioslibres_rx->movilAsociado;
					estado1 = pktsitioslibres_rx->estado;
					printf("El movil %d ha reservado la plaza %d\n", movilAsociado1, ID_plaza1);
					printfflush();
				}else if(pktsitioslibres_rx->estado == OCUPADO ){
					movilAsociado1 = pktsitioslibres_rx->movilAsociado;
					estado1 = pktsitioslibres_rx->estado;
					printf("El movil %d ha aparcado en la plaza %d\n", movilAsociado1, ID_plaza1);
					printfflush();					
				}
			}else if (pktsitioslibres_rx->movilAsociado != NO_MOVIL_ASOCIADO && pktsitioslibres_rx->ID_plaza == APARC2_ID) {
				if(pktsitioslibres_rx->estado == RESERVADO){
					movilAsociado2 = pktsitioslibres_rx->movilAsociado;
					estado2 = pktsitioslibres_rx->estado;
					printf("El movil %d ha reservado la plaza %d\n", movilAsociado2, ID_plaza2);
					printfflush();
				}else if(pktsitioslibres_rx->estado == OCUPADO){
					movilAsociado2 = pktsitioslibres_rx->movilAsociado;
					estado2 = pktsitioslibres_rx->estado;
					printf("El movil %d ha aparcado en la plaza %d\n", movilAsociado2, ID_plaza2);		
					printfflush();			
				}
			}else if (pktsitioslibres_rx->movilAsociado != NO_MOVIL_ASOCIADO && pktsitioslibres_rx->ID_plaza == APARC3_ID) {
				if(pktsitioslibres_rx->estado == RESERVADO){
					movilAsociado3 = pktsitioslibres_rx->movilAsociado;
					estado3 = pktsitioslibres_rx->estado;
					printf("El movil %d ha reservado la plaza %d\n", movilAsociado3, ID_plaza3);
					printfflush();
				}else if(pktsitioslibres_rx->estado == OCUPADO){
					movilAsociado3 = pktsitioslibres_rx->movilAsociado;
					estado3 = pktsitioslibres_rx->estado;
					printf("El movil %d ha aparcado en la plaza %d\n", movilAsociado3, ID_plaza3);
					printfflush();										
				}
			}
		}else if (len == sizeof(LocationMsg)){
			LocationMsg* locationmsg_rx = (LocationMsg*)payload;	//Extrae el payload
			printf("He recibido LocationMsg de %d\n", locationmsg_rx->ID_movil);
			printfflush();
			printf("Coordenada X: %d, Coordenada Y: %d, distanciam: %d, distancia1: %d, distancia2: %d, distancia3: %d", locationmsg_rx->coorX, locationmsg_rx->coorY, locationmsg_rx->distancem, locationmsg_rx->distance1, locationmsg_rx->distance2, locationmsg_rx->distance3);
			printfflush();
		}
		return msg;
	}
	
}

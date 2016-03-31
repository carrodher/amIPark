#include "Jefe.h"

module JefeC {
	uses interface Boot;
	uses interface Leds;
	uses interface Timer<TMilli> as Timer0;
	uses interface Packet;
	uses interface AMPacket;
	uses interface AMSend;
	uses interface Receive;
	uses interface SplitControl as AMControl;
	uses interface Random;
}
implementation {
	uint16_t number = 0;				// Número aleatorio
	uint16_t first = ESCLAVO_TEMP_ID;	// 1º slot (defecto: Temperatura)
	uint16_t second = ESCLAVO_HUM_ID;	// 2º slot (defecto: Humedad)
	uint16_t third = ESCLAVO_LUM_ID;	// 3º slot (defecto: Luminosidad)
	message_t pkt;        				// Espacio para el pkt a tx
	bool busy = FALSE;    				// Flag para comprobar el estado de la radio

	// Se ejecuta al alimentar t-mote. Arranca la radio
	event void Boot.booted() {
		call AMControl.start();
	}

	// Elige de manera pseudo-aleatoria el orden de los slots
	void randomSlot() {
		// Genera un valor aleatorio entre ESCLAVO_TEMP_ID , ESCLAVO_HUM_ID y ESCLAVO_LUM_ID y lo asigna al 1º slot
		first = call Random.rand16()%3+131;
		// El 2º y 3º slot se asignan en función del primero
		switch(first) {
			// Genera un número aleatorio entre 0 y 1 para definir el 2º y 3º slot
			number = call Random.rand16()%2;
			case(ESCLAVO_TEMP_ID): {
				if (number == 0){		// TEMP - LUM - HUM
					second = ESCLAVO_LUM_ID;
					third = ESCLAVO_HUM_ID;
				}
				else {					// TEMP - HUM - LUM
					second = ESCLAVO_HUM_ID;
					third = ESCLAVO_LUM_ID;
				}
				break;
			}
			case(ESCLAVO_HUM_ID): {
				if (number == 0){		// HUM - TEMP - LUM
					second = ESCLAVO_TEMP_ID;
					third = ESCLAVO_LUM_ID;
				}
				else {					// HUM - LUM - TEMP
					second = ESCLAVO_LUM_ID;
					third = ESCLAVO_TEMP_ID;
				}
				break;
			}
			case(ESCLAVO_LUM_ID): {
				if (number == 0) {		// LUM - TEMP - HUM
					second = ESCLAVO_TEMP_ID;
					third = ESCLAVO_HUM_ID;
				}
				else {					// LUM - HUM - TEMP
					second = ESCLAVO_HUM_ID;
					third = ESCLAVO_TEMP_ID ;
				}
				break;
			}
		}
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
			MaestroMsg* pktmaestro_tx = (MaestroMsg*)(call Packet.getPayload(&pkt, sizeof(MaestroMsg)));

			// Reserva errónea
			if (pktmaestro_tx == NULL) {
				return;
			}

			/*** FORMA EL PAQUETE ***/
			// Campo 1: ID_maestro
			pktmaestro_tx->ID_maestro = MAESTRO_ID;
			// Campos 2, 3 y 4: Orden de los slots
			randomSlot();
			pktmaestro_tx->first = first;
			pktmaestro_tx->second = second;
			pktmaestro_tx->third = third;

			// Envía
			if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(MaestroMsg)) == SUCCESS) {
				//						|-> Destino = Difusión
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

	event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
		if (len == sizeof(EsclavoMsg)) {
			EsclavoMsg* pktesclavo_rx = (EsclavoMsg*)payload;   // Extrae el payload

			//call Leds.led0On();   	// Led 0 ON cuando recibo un paquete
			//call Leds.led1Off();    // Led 1 OFF

			// Determina el tipo de medida
			if (pktesclavo_rx->ID_esclavo == ESCLAVO_TEMP_ID) {
				//Nos ha llegado una medida de temperatura
				call Leds.led0On();   // Led 0 On para temperatura
				call Leds.led1Off();	// Led 0 Off
				call Leds.led2Off();  // Led 0 Off
			}
			else if (pktesclavo_rx->ID_esclavo == ESCLAVO_HUM_ID) {
				//Nos ha llegado una medida de humedad
				call Leds.led0Off();   // Led 0 Off
				call Leds.led1On();    // Led 1 On para humedad
				call Leds.led2Off();	 // Led 2 Off
			}
			else if (pktesclavo_rx->ID_esclavo == ESCLAVO_LUM_ID) {
				//Nos ha llegado una medida de luminosidad
				call Leds.led0Off();   // Led 0 Off
				call Leds.led1Off();   // Led 1 Off
				call Leds.led2On();    //Led 2 On para luminosidad
			}
		}
		return msg;
	}
}

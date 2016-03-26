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
}
implementation {
	uint16_t tipo = 0;		// 1 = Temperatura    2 = Humedad    3 = Luminosidad
	message_t pkt;        	// Espacio para el pkt a tx
	bool busy = FALSE;    	// Flag para comprobar el estado de la radio

	// Se ejecuta al alimentar t-mote. Arranca la radio
	event void Boot.booted() {
		call AMControl.start();
	}

	// Enciende los leds según el tipo de medida a solicitar
	void enciendeLed(uint16_t tipoMed) {
		switch(tipoMed) {
			case(TEMPERATURA): {
				call Leds.led0On();    // Led 0 ON para temperatura
				call Leds.led1Off();   // Led 1 OFF para temperatura
				call Leds.led2Off();   // Led 2 OFF para temperatura
				break;
			}
			case(HUMEDAD): {
				call Leds.led0Off();    // Led 0 OFF para humedad
				call Leds.led1On();   	// Led 1 ON para humedad
				call Leds.led2Off();   	// Led 2 OFF para humedad
				break;
			}
			case(LUMINOSIDAD): {
				call Leds.led0Off();    // Led 0 OFF para luminosidad
				call Leds.led1Off();   	// Led 1 OFF para luminosidad
				call Leds.led2On();   	// Led 2 ON para luminosidad
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
		// Hace que el tipo de medida vaya rotando (1,2,3) cada vez que expira el timer0
		if (tipo == 3) {
			tipo = 1;
		}
		else {
			tipo++;
		}

		// Enciende los leds según el tipo de medida a solicitar
		enciendeLed(tipo);

		// Si no está ocupado forma y envía el mensaje
		if (!busy) {
			// Reserva memoria para el paquete
			MaestroMsg* pktmaestro_tx = (MaestroMsg*)(call Packet.getPayload(&pkt, sizeof(MaestroMsg)));

			// Reserva errónea
			if (pktmaestro_tx == NULL) {
				return;
			}

			// Forma el paquete a tx
			pktmaestro_tx->ID_maestro = MAESTRO_ID;   // Campo 1: ID maestro
			pktmaestro_tx->ID_esclavo = ESCLAVO_ID;   // Campo 2: ID esclavo
			pktmaestro_tx->tipo = tipo;   			  // Campo 3: tipo medida (1 = Temperatura    2 = Humedad    3 = Luminosidad)

			// Envía
			if (call AMSend.send(ESCLAVO_ID, &pkt, sizeof(MaestroMsg)) == SUCCESS) {
				//						|-> Destino = Esclavo
				busy = TRUE;	// Ocupado
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

			// Si el paquete recibido es de nuestro esclavo
			if (pktesclavo_rx->ID_esclavo == ESCLAVO_ID)
			{
				// No hay que tratar el paquete que llega, se ve en la base station
			}
		}
		return msg;
	}
}

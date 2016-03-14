#include "Esclavo.h"

module EsclavoC {
	uses interface Boot;
	uses interface Leds;
	uses interface CC2420Packet;
	uses interface Packet;
	uses interface AMPacket;
	uses interface AMSend;
	uses interface Receive;
	uses interface SplitControl as AMControl;
	uses interface Read<uint16_t> as ReadVisible;
	uses interface Read<uint16_t> as ReadNotVisible;
	uses interface Read<uint16_t> as Temperature;
	uses interface Read<uint16_t> as Humidity;
}
implementation {

	uint16_t rssi;			   	// Almacena la medida de RSSI
	uint16_t medida;			// Almacena la medida del tipo solicitado
	message_t pkt;			   	// Espacio para el pkt a tx
	bool busy = FALSE;		 	// Flag para comprobar el estado de la radio

	// Obtiene el valor RSSI del paquete recibido
	uint16_t getRssi(message_t *msg){
		return (uint16_t) call CC2420Packet.getRssi(msg);
	}

	// Mide y enciende los leds según el tipo de medida solicitada
	uint16_t medirTipo(uint16_t tipoMed) {
  		// Temperatura
  		if (tipoMed == 1) {
  			call Leds.led0On();    		// Led 0 ON para temperatura
  			call Leds.led1Off();   		// Led 1 OFF para temperatura
  			call Leds.led2Off();   		// Led 2 OFF para temperatura
  			call Temperature.read();	// Mide la temperatura
  		}
  		// Humedad
  		else if (tipoMed == 2) { 
	  		call Leds.led0Off();    // Led 0 OFF para humedad
  			call Leds.led1On();   	// Led 1 ON para humedad
  			call Leds.led2Off();   	// Led 2 OFF para humedad
  			call Humidity.read();	// Mide la temperatura
  		}
  		// Luminosidad
  		else if (tipoMed == 3) {
	  		call Leds.led0Off();    	// Led 0 OFF para luminosidad
  			call Leds.led1Off();   		// Led 1 OFF para luminosidad
  			call Leds.led2On();   		// Led 2 ON para luminosidad
  			// No se por qué hay dos, uno para luz visible y otro para luz no visible. Habrá que usar uno u otro
  			call ReadVisible.read();	// Mide la luz visible
  			call ReadNotVisible.read();	// Mide la luz no visible
  		}
 	}

 	// Mide la humedad. Almacena el valor en medida. Si hay error almacena 0xFFFF
 	event void Humidity.readDone(error_t result, uint16_t val) {
  		if(result == SUCCESS) {
   			medida = val;
  		}
  		else 
  			medida = 0xFFFF;
	}

	// Mide la temperatura. Almacena el valor en medida. Si hay error almacena 0xFFFF
	event void Temperature.readDone(error_t result, uint16_t val) {
  		if(result == SUCCESS) {
    		medida = val;
  		}
  		else 
  			medida = 0xFFFF;
	}

	// Mide la luz visible. Almacena el valor en medida. Si hay error almacena 0xFFFF
	event void ReadVisible.readDone(error_t result, uint16_t val) {
  		if(result == SUCCESS) {
    		medida = val;
  		}
  		else 
  			medida = 0xFFFF;
  	}  
  
  	// Mide la luz no visible. Almacena el valor en medida. Si hay error almacena 0xFFFF
  	event void ReadNotVisible.readDone(error_t result, uint16_t val) {
  		if(result == SUCCESS) {
    		medida = val;
  		}
  		else 
  			medida = 0xFFFF;
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

	// Comprueba la tx del pkt y marca como libre si ha terminado
	event void AMSend.sendDone(message_t* msg, error_t err) {
		if (&pkt == msg) {
			busy = FALSE;			// Libre
		}
	}

	// Comprueba la rx de un pkt
	event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
		MaestroMsg* pktmaestro_rx = (MaestroMsg*)payload;	// Extrae el payload
		
		// Si el paquete tiene la longitud correcta y es de mi maestro
		if (len == sizeof(MaestroMsg) && pktmaestro_rx->ID_maestro == MAESTRO_ID) {
			rssi = getRssi(msg);		// Calcula el RSSI
			
			// Mide y enciende los leds según el tipo de medida solicitada
			medida = medirTipo(pktmaestro_rx->tipo);

			// Si no está ocupado forma y envía el mensaje
			if (!busy) {
				// Reserva memoria para el paquete
		  		EsclavoMsg* pktesclavo_tx = (EsclavoMsg*)(call Packet.getPayload(&pkt, sizeof(EsclavoMsg)));
          		// Reserva OK
      			if (pktesclavo_tx == NULL) {
       				return;
       			}

        		// Forma el paquete a tx
		    	pktesclavo_tx->ID_esclavo = ESCLAVO_ID;  		// Campo 1: ID esclavo
        		pktesclavo_tx->medidaRssi = rssi;      			// Campo 2: Medida RSSI
        		pktesclavo_tx->tipo = pktmaestro_rx->tipo;      // Campo 3: Tipo de medida
        		pktesclavo_tx->medida = medida;     			// Campo 4: Valor de medida

        		// Envía
		    	if (call AMSend.send(pktmaestro_rx->ID_maestro, &pkt, sizeof(EsclavoMsg)) == SUCCESS) {
		    	//							|-> Destino = Origen pkt rx
	        		busy = TRUE;	// Ocupado
	        	}
			}
		}
		return msg;
	}
}
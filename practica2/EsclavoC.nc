// $Id: BlinkToRadioC.nc,v 1.6 2010-06-29 22:07:40 scipio Exp $
/**
 * Implementation of the BlinkToRadio application.  A counter is
 * incremented and a radio message is sent whenever a timer fires.
 * Whenever a radio message is received, the three least significant
 * bits of the counter in the message payload are displayed on the
 * LEDs.  Program two motes with this application.  As long as they
 * are both within range of each other, the LEDs on both will keep
 * changing.  If the LEDs on one (or both) of the nodes stops changing
 * and hold steady, then that node is no longer receiving any messages
 * from the other node.
 *
 * @author Prabal Dutta
 * @date   Feb 1, 2006
 */
 #include <Timer.h>
 #include "BlinkToRadio.h"

 module EsclavoC {
 	uses interface Boot;
 	uses interface Leds;
 	uses interface CC2420Packet;
 	uses interface Timer<TMilli> as Timer0;
 	uses interface Packet;
 	uses interface AMPacket;
 	uses interface AMSend;
 	uses interface Receive;
 	uses interface SplitControl as AMControl;
 }
 implementation {

 	message_t pkt;
 	bool busy = FALSE;

	uint16_t getRssi(message_t *msg){
		return (uint16_t) call CC2420Packet.getRssi(msg);
	}

 	// Se ejecuta al alimentar t-mote. Arranca la radio
 	event void Boot.booted() {
 		call AMControl.start();
 	}

 	// Arranca el contador con TIMER_PERIOD_MILLI ms
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

 	// Trata el temporizador, crea y envía el pkt
 	event void Timer0.fired() {
 		counter++;		// Cuando expira el temporizador incrementa el contador
 		// Reserva memoria para el pkt
 		if (!busy) {
 			RssiMsg* rssipkt = (RssiMsg*)(call Packet.getPayload(&pkt, sizeof(RssiMsg)));
 			if (rssipkt == NULL) {
 				return;
 			}
 			// Rellena los campos del pkt
 			rssipkt->rssi = getRssi(msg);	// ID del tx
 			rssipkt->id_esclavo = counter;
 			if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(RssiMsg)) == SUCCESS) {
 								// |-> Difusión o ID del t-mote rx
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

 	// Comprueba la rx de un pkt
 	event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
 		if (len == sizeof(RssiMsg)) {
 			RssiMsg* rssipkt = (RssiMsg*)payload;	// Extrae el payload
 			setLeds(rssipkt->counter);		// Llama a la función de los leds con ese valor
 		}
 		return msg;
 	}
 }

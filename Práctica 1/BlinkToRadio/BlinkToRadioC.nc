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

 module BlinkToRadioC {
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

 	uint16_t counter;
 	message_t pkt;
 	bool busy = FALSE;

 	// Enciende los leds en función del parámetro val que se le pasa
 	void setLeds(uint16_t val) {
 		// Comprueba último bit de val
 		if (val & 0x01){
 			call Leds.led0On();		// Led 0 ON
 		}
 		else 
 			call Leds.led0Off();	// Led 0 OFF
 			// Comprueba penúltimo bit de val
 		if (val & 0x02){		
 			call Leds.led1On();		// Led 1 ON
 		}
 		else
 			call Leds.led1Off();	// Led 1 OFF
 		// Comprueba antepenúltimo bit de val
 		if (val & 0x04){
 			call Leds.led2On();		// Led 2 ON
 		}
 		else
 			call Leds.led2Off();	// Led 2 OFF
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
 			BlinkToRadioMsg* btrpkt = (BlinkToRadioMsg*)(call Packet.getPayload(&pkt, sizeof(BlinkToRadioMsg)));
 			if (btrpkt == NULL) {
 				return;
 			}
 			// Rellena los campos del pkt
 			btrpkt->nodeid = TOS_NODE_ID;	// ID del tx
 			btrpkt->counter = counter;
 			if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(BlinkToRadioMsg)) == SUCCESS) {
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
 		if (len == sizeof(BlinkToRadioMsg)) {
 			BlinkToRadioMsg* btrpkt = (BlinkToRadioMsg*)payload;	// Extrae el payload
 			setLeds(btrpkt->counter);		// Llama a la función de los leds con ese valor
 		}
 		return msg;
 	}
 }

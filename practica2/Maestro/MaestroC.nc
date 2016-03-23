#include "Maestro.h"

module MaestroC {
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
    message_t pkt;        // Espacio para el pkt a tx
    bool busy = FALSE;    // Flag para comprobar el estado de la radio

    // Se ejecuta al alimentar t-mote. Arranca la radio
    event void Boot.booted() {
        call Leds.led0On();       // Enciende led 0 al inicio y no se apaga
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
            MaestroMsg* pktmaestro_tx = (MaestroMsg*)(call Packet.getPayload(&pkt, sizeof(MaestroMsg)));

            // Reserva OK
            if (pktmaestro_tx == NULL) {
                return;
            }

            // Forma el paquete a tx
            pktmaestro_tx->ID_maestro = MAESTRO_ID;   // Campo 1: ID maestro

            // Envía
            if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(MaestroMsg)) == SUCCESS) {
                busy = TRUE;              // Ocupado
                call Leds.led1Off();      // Led 1 off cuando envío
            }
        }
    }

    // Comprueba la tx del pkt y marca como libre si ha terminado
    event void AMSend.sendDone(message_t* msg, error_t err) {
        if (&pkt == msg) {
            busy = FALSE;   // Libre
        }
    }

    event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
        if (len == sizeof(EsclavoMsg)) {
            EsclavoMsg* pktesclavo_rx = (EsclavoMsg*)payload;   // Extrae el payload

            // Si el paquete recibido es de nuestro esclavo y tiene contenido enciende el led 1
            if (pktesclavo_rx->ID_esclavo == ESCLAVO_ID && pktesclavo_rx->medidaRssi != NULL) {
                call Leds.led1On();   // Led 1 on cuando recibo
            }
        }
        return msg;
    }
}

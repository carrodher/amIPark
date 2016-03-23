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
}
implementation {
    uint16_t rssi;			   // Almacena la medida de RSSI
    message_t pkt;			   // Espacio para el pkt a tx
    bool busy = FALSE;		 // Flag para comprobar el estado de la radio

    // Obtiene el valor RSSI del paquete recibido
    uint16_t getRssi(message_t *msg){
        return (uint16_t) call CC2420Packet.getRssi(msg);
    }

    // Se ejecuta al alimentar t-mote. Arranca la radio
    event void Boot.booted() {
        call Leds.led0On();        // Enciende led 0 al inicio y no se apaga
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
            call Leds.led1Off();	// Cuando tx OK led 1 off
        }
    }

    // Comprueba la rx de un pkt
    event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
        MaestroMsg* pktmaestro_rx = (MaestroMsg*)payload;	// Extrae el payload

        // Si el paquete tiene la longitud correcta y es de mi maestro
        if (len == sizeof(MaestroMsg) && pktmaestro_rx->ID_maestro == MAESTRO_ID) {
            call Leds.led1On();			// Cuando rx OK led 1 on
            rssi = getRssi(msg);		// Calcula el RSSI

            // Si no está ocupado forma y envía el mensaje
            if (!busy) {
                // Reserva memoria para el paquete
                EsclavoMsg* pktesclavo_tx = (EsclavoMsg*)(call Packet.getPayload(&pkt, sizeof(EsclavoMsg)));

                // Reserva OK
                if (pktesclavo_tx == NULL) {
                    return;
                }

                // Forma el paquete a tx
                pktesclavo_tx->ID_esclavo = ESCLAVO_ID;  // Campo 1: ID esclavo
                pktesclavo_tx->medidaRssi = rssi;      // Campo 2: Medida RSSI

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

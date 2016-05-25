#include "../Global.h"
#include "Fijo.h"
#include "printf.h"



module FijoC {
	uses interface Boot;
	uses interface Leds;
  uses interface CC2420Packet;
	uses interface Timer<TMilli> as RssiResponseTimer;
  uses interface Timer<TMilli> as RedTimer;
  uses interface Timer<TMilli> as GreenTimer;
  uses interface Timer<TMilli> as BlueTimer;
	uses interface Packet;
	uses interface AMPacket;
	uses interface AMSend;
	uses interface Receive;
	uses interface SplitControl as AMControl;
}



implementation {

  /* ======== [Variables de la aplicación] ======== */
  uint8_t     nodeID;                     // Almacena el identificador de este nodo
  message_t   pkt;			   	              // Espacio para el pkt a tx
  bool        busy = FALSE;               // Flag para comprobar el estado de la radio
  /* ============================================== */


  /* ========= [Variables de información] ========= */
  uint8_t     destination;                // Destino del siguiente mensaje a enviar (nodeID/Difusión)
  int16_t     rssiValueToSend;            // Medida REALIZADA de RSSI
  /* ============================================== */

  

  /* ========= [Declaración de funciones] ========= */
  void    printfFloat(float floatToBePrinted);
  void    turnOnLed  (uint8_t led, uint16_t time);
  void    turnOffLed (uint8_t led);
  bool    getAssignedSlot (uint8_t slots, nx_uint8_t* slotsOwners, uint8_t* assignedSlot);
  int16_t getRssi (message_t *msg);
  void    sendRssiMessage(uint8_t order);
  /* ============================================== */




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
    } else {
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
        if (timeOn > 0) call RedTimer.startOneShot(timeOn);
        break;
      case GREEN:
        call Leds.led1On();
        if (timeOn > 0) call GreenTimer.startOneShot(timeOn);
        break;
      case BLUE:
        call Leds.led2On();
        if (timeOn > 0) call BlueTimer.startOneShot(timeOn);
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
  *   Calcula el valor RSSI del paquete recibido
  */
  int16_t getRssi (message_t *msg) {
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
    
    printf("Realizada medida de RSSI: %d\n", rssi2_t);
    printfflush();

		return rssi2_t;
	}



  /**
  *   Envia un mensaje de tipo RssiMsg
  *   Usar variable "destination" para indicar el destino: AM_BROADCAST_ADDR para difussión, en cualquier otro caso el nodeID destino
  */    
  void sendRssiMessage(uint8_t order) {
    
    uint16_t messageLength = 0;   // Almacenará el tamaño del mensaje a enviar
    RssiMsg* msg_tx = NULL;       // Necesario crear el puntero previamente

    // Reserva memoria para el paquete
    messageLength = sizeof(RssiMsg);
    msg_tx = (RssiMsg*) call Packet.getPayload(&pkt, messageLength);
    
    // Comprobar que se realizó la reserva de memoria correctamente
    if (msg_tx == NULL) {
      printf("[ERROR] Reserva de memoria\n");
      printfflush();
    } else {

      // Añadir el id del nodo origen
      msg_tx->nodeID  = nodeID;

      // Añadir la orden
      msg_tx->order = order;

      // Adjuntar datos adicionales según la orden especificada
      switch (order) {
        
        case RSSI_REQUEST:
          // Nada que adjuntar
          break;
        
        case RSSI_MEASURE:
          // Valor RSSI medido
          msg_tx->rssiValue = rssiValueToSend;
          break;

      }

      // Comprobar que no esté ocupado el transmisor
      if (!busy) {
        // Enviar y comprobar el resultado
        if(call AMSend.send(destination, &pkt, messageLength) == SUCCESS) {
          busy = TRUE;      // Ocupado
          // Notificación visual de envio de mensaje
          turnOnLed(RED, LED_BLINK_TIME);
        } else {
          printf("[ERROR] Mensaje no enviado\n");
          printfflush();
        }
      } else {
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

        case RSSI_REQUEST:
          // Calcular RSSI y almacenarlo para su envio
          rssiValueToSend = getRssi(msg);
          // Almacenar el destinatario del mensaje
          destination = msg_rx->nodeID;
          // Enviar respuesta
          sendRssiMessage(RSSI_MEASURE);
          break;

      }


    // >>>> TdmaRssiRequestFrame <<<<
    } else if (length == sizeof(TdmaRssiRequestFrame)) {
      // Extraer el payload
      TdmaRssiRequestFrame* msg_rx = (TdmaRssiRequestFrame*)payload;

      printf("Recibido: TdmaRssiRequestFrame\n");
      printfflush();
      
      // Si se tiene un slot asociado...
      if (getAssignedSlot(msg_rx->slots, msg_rx->slotsOwners, &assignedSlot)) {

        // Calcular RSSI y almacenarlo para su envio
        rssiValueToSend = getRssi(msg);
        // Almacenar el destinatario del mensaje
        destination = msg_rx->nodeID;
        call RssiResponseTimer.startOneShot(assignedSlot * (msg_rx->tSlot) + TIMER_OFFSET);

      } else {
        printf("Recibida trama TDMA y no se tiene slot asociado\n");
        printfflush();
      }

    } else {
      printf("[ERROR] Recibido mensaje de tipo desconocido\n");
      printfflush();
    }

    
    return msg;
  }



	/**
  *   Se ejecuta al alimentar t-mote. Arranca la radio
  */
	event void Boot.booted() {
		call AMControl.start();
    
    // Obtenemos el ID de este nodo
    nodeID = TOS_NODE_ID;
    printf("nodeID=%d\n", nodeID);
    printfflush();
  
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
  *   Activación del temporizador RssiResponseTimer
  */
  event void RssiResponseTimer.fired() {
    // Al activarse el evento, enviar el mensaje con la medida RSSI
    sendRssiMessage(RSSI_MEASURE);
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

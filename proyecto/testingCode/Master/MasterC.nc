#include "../Global.h"
#include "Master.h"
#include "printf.h"
#include <UserButton.h>
#include <math.h>



module MasterC {
	uses interface Boot;
	uses interface Leds;
  uses interface CC2420Packet;
	uses interface Timer<TMilli> as SendBeaconTimer;
	uses interface Timer<TMilli> as RssiResponseTimer;
	uses interface Timer<TMilli> as RssiRequestTimer;
  uses interface Timer<TMilli> as RedTimer;
  uses interface Timer<TMilli> as GreenTimer;
  uses interface Timer<TMilli> as BlueTimer;
	uses interface Packet;
	uses interface AMPacket;
	uses interface AMSend;
	uses interface Receive;
	uses interface SplitControl as AMControl;
  uses interface Notify<button_state_t>;
}



implementation {

  /* ======== [Variables de la aplicación] ======== */
  uint8_t     nodeID;                     // Almacena el identificador de este nodo
  message_t   pkt;			   	              // Espacio para el pkt a tx
  bool        busy = FALSE;               // Flag para comprobar el estado de la radio
  bool        calibrationMode = FALSE;    // Activa el modo de calculo de constantes "a" y "b"
  uint8_t     i;                          // Índices para recorrer bucles for
  uint8_t     j;                          //
  /* ============================================== */


  /* ========= [Variables de información] ========= */
  uint8_t   spotId[PARKING_SIZE] = {SPOT_01_ID, SPOT_02_ID, SPOT_03_ID};
  uint16_t  spotX [PARKING_SIZE] = {SPOT_01_X , SPOT_02_X , SPOT_03_X };
  uint16_t  spotY [PARKING_SIZE] = {SPOT_01_Y , SPOT_02_Y , SPOT_03_Y };

  // Para el modo de calibración (Cálculo de "a" y "b")
  uint8_t   nodesToRequestRssi [2] = {FIJO_1_ID, FIJO_2_ID};    
  //float     distanceToNodes    [2] = {D1, D2};                

  uint8_t   destination;                // Destino del siguiente mensaje a enviar (nodeID/Difusión)
  int16_t   rssiValueToSend;            // Medida REALIZADA de RSSI

  int16_t   rssiValueReceived;          // Medida RECIBIDA de RSSI
  int16_t   rssiSampleValue[SAMPLES];   // Muestras de medidas RSSI recibidas
  float     rssiMeanValue[2];           // Media de las muestras recibidas
  uint8_t   sample = 0;                 // Contador de muestras tomadas
  uint8_t   meanValueIndex = 0;         // Índice para el vector rssiMeanValue[]

  float     a = 0;      // Variables para localización
  float     b = 0;      //

  // Vector con los IDs de los vehículos asociados a este parking que tienen slot para comunicarse
  uint8_t   linkedVehicles[MAX_LINKED_VEHICLES];
  uint8_t   numberOfLinkedVehicles = 0;
  /* ============================================== */


  /* ============ [Estado del parking] ============ */
  struct ParkingStatus {
    ParkingSpot   spot[PARKING_SIZE];       // Vector con información de cada plaza
    bool          free[PARKING_SIZE];       // TRUE si está libre, FALSE en otro caso
    uint8_t       vehicleID[PARKING_SIZE];  // ID del vehículo aparcado (de haberlo)
  } parkingStatus;
  /* ============================================== */


  /* ========= [Declaración de funciones] ========= */
  float   rssiMean();
  void    computeConstants (float rssi1, float rssi2, float d1, float d2);
  void    printfFloat(float floatToBePrinted);
  void    turnOnLed  (uint8_t led, uint16_t time);
  void    turnOffLed (uint8_t led);
  bool    linkVehicle (uint8_t vehicleId);
  bool    unlinkVehicle (uint8_t vehicleId);
  bool    getAssignedSlot (uint8_t slots, nx_uint8_t* slotsOwners, uint8_t* assignedSlot);
  int16_t getRssi (message_t *msg);
  void    sendRssiMessage(uint8_t order);
  void    sendBeaconMessage();
  void    newSampleReceived();
  /* ============================================== */





  /**
  *   Evento de pulsación del botón
  */
  event void Notify.notify(button_state_t state) {
    // Comprobar si está pulsado
	  if (state == BUTTON_PRESSED) {
      printf("Pulsado\n");
      printfflush();
      
      // Activar el modo de calibración o desactivarlo si ya estaba activo
      if (!calibrationMode) {
        calibrationMode = TRUE;   // Activarlo
      } else {
        calibrationMode = FALSE;  // Desactivarlo

        call RssiRequestTimer.stop();   // Detener el envio de mensajes de solicitud de medida RSSI

        sample = 0;           // Resetear variables utilizadas en el proceso
        meanValueIndex = 0;   //

        sendBeaconMessage();  // Iniciar envio de la trama beacon
      }
    }
    else if (state == BUTTON_RELEASED) {
      // Nada que hacer
    }
  }



  /**
  *   Calcula y guarda la media de las muestras de medida RSSI
  */
  float rssiMean() {
    float   mean;       // Almacenará la media una vez calculada
    int16_t tmp = 0;    // Para calculos intermedios
    
    // Sumar todas las muestras
    for ( i=0 ; i<SAMPLES ; i++ ) {
      tmp+=rssiSampleValue[i];
    }
    // Dividirlas entre el número de muestras
    mean = (float) tmp / SAMPLES;

    return mean;
  }



  /**
  *   Calcula el valor de las constantes
  */
  void computeConstants (float rssi1, float rssi2, float d1, float d2) {
    float tmp = logf(d1/d2)/2.303;
    a = (rssi1 - rssi2) / tmp;
    
    tmp = logf(d2)/2.303;
    b = rssi2 - (a * tmp);

    turnOnLed(GREEN,1000);

    printf("rssi1=%d | rssi2=%d | d1=%d | d2=%d\n", (int16_t) rssi1, (int16_t) rssi2, (int16_t) d1, (int16_t) d2);
    printf("a="); printfFloat(a); printf("\n");
    printf("b="); printfFloat(b); printf("\n");
    printfflush();
		return;
	}



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
  *   Devuelve verdadero si se ha asociado el vehículo y falso en caso contrario
  */
  bool linkVehicle (uint8_t vehicleId) {
    
    // Flag
    bool linked = FALSE;

    // Recorrer el vector en busca de un hueco libre
    for (i = 0 ; (i<MAX_LINKED_VEHICLES) && (linked == FALSE) ; i++) {
      if (linkedVehicles[i] == 0) {
        // Se ha encontrado un hueco
        linkedVehicles[i] = vehicleId;
        linked = TRUE;
        numberOfLinkedVehicles++;
        printf("Vehiculo con ID (%d) asociado. Total: %d\n", vehicleId, numberOfLinkedVehicles);
        printfflush();
      }
    }

    return linked;
  }



  /**
  *   Devuelve verdadero si se ha desasociado el vehículo y falso en caso contrario
  */
  bool unLinkVehicle (uint8_t vehicleId) {
    
    // Flag
    bool done = FALSE;

    // Recorrer el vector en busca de un hueco libre
    for (i = 0 ; (i<MAX_LINKED_VEHICLES) && (done == FALSE) ; i++) {
      if (linkedVehicles[i] == vehicleId) {
        // Se ha encontrado un hueco
        linkedVehicles[i] = 0;
        done = TRUE;
        numberOfLinkedVehicles--;
        printf("Vehiculo con ID (%d) desasociado. Total: %d\n", vehicleId, numberOfLinkedVehicles);
        printfflush();
      }
    }

    return done;
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
          printf("[DEBUG] Enviado mensaje RssiMsg\n");
          printfflush();
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
  *   Envia un mensaje de tipo TdmaBeaconFrame a difusión
  *   Se trata de la baliza que indica a los vehículos cuando pueden comunicarse con el master o solicitar localización
  */    
  void sendBeaconMessage() {
    
    uint16_t messageLength = 0;           // Almacenará el tamaño del mensaje a enviar
    TdmaBeaconFrame* msg_tx = NULL;       // Necesario crear el puntero previamente

    // Reserva memoria para el paquete
    messageLength = sizeof(TdmaBeaconFrame);
    msg_tx = (TdmaBeaconFrame*) call Packet.getPayload(&pkt, messageLength);
    
    // Comprobar que se realizó la reserva de memoria correctamente
    if (msg_tx == NULL) {
      printf("[ERROR] Reserva de memoria\n");
      printfflush();
    } else {

      // Añadir el id del nodo origen
      msg_tx->nodeID  = nodeID;
      
      // Añadir el número de slots actualmente en uso y el tiempo reservado a cada cual
      msg_tx->slots = numberOfLinkedVehicles;
      msg_tx->tSlot = TDMA_MASTER_BEACON_SLOT_TIME;


      // Enviar los IDs que tienen un slot asignado
      j=0;
      for (i=0 ; i<MAX_LINKED_VEHICLES ; i++) {
        if (linkedVehicles[i] != 0) {
          // Si se encuentra un ID se guarda
          msg_tx->slotsOwners[j++] = linkedVehicles[i];
        }
      }
      // Rellenar con 0 el resto del vector a enviar
      while (j<MAX_LINKED_VEHICLES) {
        msg_tx->slotsOwners[j++] = 0;
      }

/*    printf("slotsOwners: %d %d %d %d %d\n", msg_tx->slotsOwners[0],
                                              msg_tx->slotsOwners[1],
                                              msg_tx->slotsOwners[2],
                                              msg_tx->slotsOwners[3],
                                              msg_tx->slotsOwners[4] );
      printfflush();*/

      // Comprobar que no esté ocupado el transmisor
      if (!busy) {
        // Enviar y comprobar el resultado
        if(call AMSend.send(AM_BROADCAST_ADDR, &pkt, messageLength) == SUCCESS) {
          busy = TRUE;      // Ocupado
          printf("[DEBUG] Enviado mensaje TdmaBeaconFrame\n");
          printfflush();
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
      
      // Preparar el siguiente envio de la trama beacon respetando los slots anunciados: uno por vehículo más otro para nuevos usuarios
      call SendBeaconTimer.startOneShot( (numberOfLinkedVehicles + ADITIONAL_TDMA_SLOTS) * TDMA_MASTER_BEACON_SLOT_TIME );
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

        case RSSI_MEASURE:
          // Almacenar la medida RSSI recivida
          rssiValueReceived = msg_rx->rssiValue;
          printf("Recibida medida RSSI del nodo %d con valor: %d\n", msg_rx->nodeID, rssiValueReceived);
          printfflush();
          
          if (calibrationMode) {
            // Añadir al conjunto de muestras
            rssiSampleValue[sample++] = rssiValueReceived;
            newSampleReceived();
          }
          break;

      }


    // >>>> TdmaRssiRequestFrame <<<<
    } else if (length == sizeof(TdmaRssiRequestFrame)) {
      // Extraer el payload
      TdmaRssiRequestFrame* msg_rx = (TdmaRssiRequestFrame*)payload;

      printf("Recibido: TdmaRssiRequestFrame\n");
      printf("X = %d, Y = %d\n", msg_rx->X, msg_rx->Y);
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


    // >>>> VehicleOrder <<<<
    } else if (length == sizeof(VehicleOrder)) {
      // Extraer el payload
      VehicleOrder* msg_rx = (VehicleOrder*)payload;

      printf("Recibido: VehicleOrder  / Orden: %d\n", msg_rx->order);
      printfflush();

      // Determinar la orden recibida
      switch (msg_rx->order) {

        case COMM_SLOT_REQUEST:
          // Guardar ID del vehículo (nodo) en la lista de nodos asociados con este parking para darle un slot en la trama TDMA beacon del master
          linkVehicle(msg_rx->nodeID);
          break;
        
        case FREE_SPOTS_REQUEST:
          // Enviar mensaje(s) con el(los) sitio(s) libre(s) del parking
          // TODO ///////////////////////////////////////////////////////////////
          // TODO ///////////////////////////////////////////////////////////////
          // TODO ///////////////////////////////////////////////////////////////
          // TODO ///////////////////////////////////////////////////////////////
          break;

        case SPOT_TAKEN_UP:
          // Liberar el slot asociado a ese nodo en la trama TDMA beacon del master
          unLinkVehicle(msg_rx->nodeID);
          // Marcar la plaza indicada como ocupada
          parkingStatus.free[msg_rx->extraData] = FALSE;
          printf("Estacionamiento: El vehiculo con ID %d ha estacionado en la plaza %d\n", msg_rx->nodeID, msg_rx->extraData);
          printfflush();
          break;

      }
      
    } else {
      printf("[ERROR] Recibido mensaje de tipo desconocido\n");
      printfflush();
    }
    
    
    return msg;
  }



  /**
  *   Se ejecuta cada vez que se recibe una medida RSSI
  */
  void newSampleReceived() {
    // Si se tienen las muestras necesarias para hacer una media...
    if (sample == SAMPLES) {
      // Detener el envio de mensajes
      call RssiRequestTimer.stop();
      // Obtener media
      rssiMeanValue[meanValueIndex] = rssiMean();
      printf("Media RSSI: "); printfFloat(rssiMeanValue[meanValueIndex]); printf("\n");
      printfflush();
      
      sample = 0;         // Resetear el contador de muestras
      meanValueIndex++;   // Y contar que se tiene una media calculada
      
      // Si ya se tienen las dos medias RSSI (a dos distancias)
      if (meanValueIndex == 2) {
        // Calcular variables "a" y "b"
        computeConstants( rssiMeanValue[0], rssiMeanValue[1], FIJO_1_Y, sqrtf( powf(FIJO_2_X,2) + powf(FIJO_2_Y,2) ));

        meanValueIndex = 0;   // Resetear para futuros cálculos

        // Reiniciar el programa normal, enviando una trama beacon
        calibrationMode = FALSE;
        sendBeaconMessage();
      
      // Si aun queda una media por obtener, reiniciar el envio de peticiones de medida RSSI
      } else {
        destination = nodesToRequestRssi[1];    // Seleccionar el segundo nodo
        call RssiRequestTimer.startPeriodic(RSSI_REQUEST_SEND_FREQUENCY);
      }
    }

  }



	/**
  *   Se ejecuta al alimentar t-mote. Arranca la radio
  */
	event void Boot.booted() {
		call AMControl.start();
    call Notify.enable();
    
    // Obtenemos el ID de este nodo
    nodeID = TOS_NODE_ID;
    printf("nodeID=%d\n", nodeID);
    printfflush();

    // Inicializar variables
    for (i=0 ; i<MAX_LINKED_VEHICLES ; i++) {
      linkedVehicles[i] = 0;
    }

    // Inicializar el vector con la información de las plazas de aparcamiento
    for (i=0 ; i<PARKING_SIZE ; i++) {
      parkingStatus.spot[i].id  = spotId[i];
      parkingStatus.spot[i].x   = spotX [i];
      parkingStatus.spot[i].y   = spotY [i];
      parkingStatus.free[i]     = TRUE;
    }
    
    // Inicializar el envio de la trama beacon
    call SendBeaconTimer.startOneShot(INITIAL_BEACON_DELAY);
    
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
  *   Activación del temporizador SendBeaconTimer
  */
  event void SendBeaconTimer.fired() {
    
    if (!calibrationMode) {
      // Enviar el mensaje con la trama beacon a difusión
      sendBeaconMessage();
    } else {
      // Si se solicitó la calibración, se desactiva el envio de tramas beacon hasta finalizar
      call SendBeaconTimer.stop();
      // Iniciar la solicitud de medidas RSSI
      destination = nodesToRequestRssi[0];    // Seleccionar el primer nodo
      call RssiRequestTimer.startPeriodic(RSSI_REQUEST_SEND_FREQUENCY);
    }
	}



  /**
  *   Activación del temporizador RssiResponseTimer
  */
  event void RssiResponseTimer.fired() {
    sendRssiMessage(RSSI_MEASURE);
	}



  /**
  *   Activación del temporizador RssiRequestTimer
  */
  event void RssiRequestTimer.fired() {
    sendRssiMessage(RSSI_REQUEST);
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

	#include "RssiBot.h"
	#include <math.h>
	#include "printf.h"
	#include <UserButton.h>


module RssiBotC {
	uses interface Boot;
	uses interface Leds;
  uses interface CC2420Packet;
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
  uint8_t   nodeID;                     // Almacena el identificador de este nodo
  message_t pkt;			   	              // Espacio para el pkt a tx
  bool      busy = FALSE;               // Flag para comprobar el estado de la radio
  int16_t   rssiValueToSend;            // Medida REALIZADA de RSSI
  int16_t   rssiValueReceived;          // Medida RECIBIDA de RSSI
  int16_t   rssiSampleValue[SAMPLES];   // Muestras de medidas RSSI recibidas
  float     rssiMeanValue[2];           // Media de las muestras recibidas
  uint8_t   sample = 0;                 // Contador de muestras tomadas
  uint8_t   meanValueIndex = 0;         // Índice para el vector rssiMeanValue[]

  float     a = 0;      // Variables para localización
  float     b = 0;      //
  /* ============================================== */


  /* ========= [Declaración de funciones] ========= */
  float   rssiMean();
  void    printfFloat(float floatToBePrinted);
  void    turnOnLed (uint8_t led, uint16_t time);
  void    turnOffLed (uint8_t led);
  int16_t getRssi (message_t *msg);
  float   getDistance (float rssi);
  void    computeConstants (float rssi1, float rssi2, float d1, float d2);
  void    sendMessage(int type, int order);
  /* ============================================== */

  
  
  /**
  *   Calcula y guarda la media de las muestras de medida RSSI
  */
  float rssiMean() {
    float   mean;       // Almacenará la media una vez calculada
    int16_t tmp = 0;    // Para calculos intermedios
    uint8_t i;          // Índice para recorrer las muestras
    
    // Sumar todas las muestras
    for ( i=0 ; i<SAMPLES ; i++ ) {
      tmp+=rssiSampleValue[i];
    }
    // Dividirlas entre el número de muestras
    mean = (float) tmp / SAMPLES;

    return mean;
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

		return rssi2_t;
	}


  /**
  *   Calcula la distancia en función de una medida RSSI
  */
  float getDistance (float rssi) {
    /* Fórmula: RSSI(D) = a·log(D) + b; D = 10^((RSSI-b)/a) */
    return powf(10, (rssi-b)/a);
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
  *   Evento de pulsación del botón
  */
  event void Notify.notify(button_state_t state) {
    // Comprobar si está pulsado
	  if (state == BUTTON_PRESSED) {
      printf("Pulsado\n");
      printfflush();
      
      // Comprobar si se pueden realizar o no mediciones de distancia
      if ( a == 0 || b == 0 ) {
        // Enviar mensaje de solicitud de medida RSSI
        call RssiRequestTimer.startPeriodic(SEND_FREQUENCY);
      } else {
        // Enviar mensaje de solicitud de medida RSSI
        call RssiRequestTimer.startPeriodic(250);
      }
    }
    else if (state == BUTTON_RELEASED) {
      // Nada que hacer
    }
  }

    
  /**
  *   Envia un mensaje del tipo indicado con la orden especificada
  */    
  void sendMessage(int type, int order) {
    
    uint16_t messageLength = 0;   // Almacenará el tamaño del mensaje a enviar
    RssiMsg* msg_tx = NULL;

    // Determinar el tipo de mensaje a construir
    switch (type) {

      case MSG_TYPE_RSSI:
        // Reserva memoria para el paquete
        messageLength = sizeof(RssiMsg);
        msg_tx = (RssiMsg*) call Packet.getPayload(&pkt, messageLength);
        break;

    }
    
    // Comprobar que se realizó la reserva de memoria correctamente
    if (msg_tx == NULL){
      printf("[ERROR] Reserva de memoria\n");
      printfflush();
    } else {

      // Añadir el id del nodo origen
      msg_tx->nodeID  = nodeID;

      // Añadir la orden si la tiene
      if ( order != 0 ) {
        msg_tx->order = order;

        // Determinar el tipo orden a realizar
        switch (order) {
          
          case RSSI_REQUEST:
            break;
          
          case RSSI_MEASURE:
            msg_tx->rssiValue = rssiValueToSend;
            break;

        }
      }

      // Comprobar que no esté ocupado el transmisor
      if (!busy) {
        // Enviar y comprobar el resultado
        if(call AMSend.send(AM_BROADCAST_ADDR, &pkt, messageLength) == SUCCESS) {
          busy = TRUE;      // Ocupado
//          printf("Mensaje de tipo [%d] enviado\n",type);
//          printfflush();

          turnOnLed(RED,20);
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
    
    turnOnLed(GREEN,20);

    // Determinar el tipo de mensaje recibido
    if (length == sizeof(RssiMsg)) {
      // Extraer el payload
      RssiMsg* msg_rx = (RssiMsg*)payload;
    
      // Determinar la orden recibida
      switch (msg_rx->order) {

        case RSSI_REQUEST:
          // Calcular RSSI y enviarlo
          rssiValueToSend = getRssi(msg);
          printf("Realizada medida de RSSI | rssiValueToSend=%d\n", rssiValueToSend);
          printfflush();
          sendMessage(MSG_TYPE_RSSI, RSSI_MEASURE);
          break;
        
        case RSSI_MEASURE:
          // Almacenar la medida RSSI recivida
          rssiValueReceived = msg_rx->rssiValue;
          printf("Recibida medida RSSI | rssiValueReceived=%d\n", rssiValueReceived);
          printfflush();
          break;

      }
    }
    

    if ( a != 0 && b != 0 ) {
      // Calcular e imprimir distancia
      printf("Distancia: "); printfFloat(getDistance(rssiValueReceived)); printf(" cm\n");
      printfflush();
    } else {
      // Almacenar nueva muestra
      rssiSampleValue[sample++] = rssiValueReceived;

      // Si se tienen las muestras necesarias
      if (sample == SAMPLES) {
        // Detener el envio de mensajes
        call RssiRequestTimer.stop();
        // Obtener media
        rssiMeanValue[meanValueIndex] = rssiMean();
        printf("Media RSSI: "); printfFloat(rssiMeanValue[meanValueIndex]); printf("\n");
        printfflush();
        // Volver a iniciar el muestreo
        sample = 0;
        meanValueIndex++;
        
        // Si ya se tienen las dos medias RSSI (a dos distancias)
        if (meanValueIndex == 2) {
          // Calcular variables y volver a empezar
          computeConstants( rssiMeanValue[0], rssiMeanValue[1], D1, D2);
          meanValueIndex = 0;
        } else {
          // Volver a activar el envio de mensajes
          call RssiRequestTimer.stop(); //TODO
        }
      }
    }
    
    return msg;
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
  *   Activación del temporizador RssiRequestTimer
  */
  event void RssiRequestTimer.fired() {
    sendMessage(MSG_TYPE_RSSI, RSSI_REQUEST);
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

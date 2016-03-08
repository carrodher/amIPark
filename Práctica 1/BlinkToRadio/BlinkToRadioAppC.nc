// $Id: BlinkToRadioAppC.nc,v 1.5 2010-06-29 22:07:40 scipio Exp $

/**
 * Application file for the BlinkToRadio application.  A counter is
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

 configuration BlinkToRadioAppC {
 }
 implementation {
 	// Componentes
 	components MainC;
 	components LedsC;
 	components BlinkToRadioC as App;
 	components new TimerMilliC() as Timer0;
 	components ActiveMessageC;
 	components new AMSenderC(AM_BLINKTORADIO);
 	components new AMReceiverC(AM_BLINKTORADIO);

 	// Relaciona Interfaces con Componentes
 	App.Boot -> MainC;
 	App.Leds -> LedsC;
 	App.Timer0 -> Timer0;
 	App.Packet -> AMSenderC;
 	App.AMPacket -> AMSenderC;
 	App.AMControl -> ActiveMessageC;
 	App.AMSend -> AMSenderC;
 	App.Receive -> AMReceiverC;
 }

#include "Movil.h"

configuration MovilAppC {
}
implementation {
	// Componentes
	components MainC;
	components LedsC;
	components MovilC as App;
	components new TimerMilliC() as Timer0;
	components new TimerMilliC() as TimerLedRojo;
	components ActiveMessageC;
	components new AMSenderC(AM_MOVIL);
	components new AMReceiverC(AM_MOVIL);

	// Relaciona Interfaces con Componentes
	App.Boot -> MainC;
	App.Leds -> LedsC;
	App.Timer0 -> Timer0;
	App.TimerLedRojo -> TimerLedRojo;
	App.Packet -> AMSenderC;
	App.AMPacket -> AMSenderC;
	App.AMControl -> ActiveMessageC;
	App.AMSend -> AMSenderC;
	App.Receive -> AMReceiverC;
}

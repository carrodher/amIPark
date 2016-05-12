#include "Master.h"

configuration MasterAppC {
}
implementation {
	// Componentes
	components MainC;
	components LedsC;
	components MasterC as App;
	components ActiveMessageC;
	components new AMSenderC(AM_MASTER);
	components new AMReceiverC(AM_MASTER);
	components new TimerMilliC() as Timer0;
	components CC2420ActiveMessageC;

	// Relaciona Interfaces con Componentes
	App.Boot -> MainC;
	App.Leds -> LedsC;
	App.Packet -> AMSenderC;
	App.AMPacket -> AMSenderC;
	App.AMControl -> ActiveMessageC;
	App.AMSend -> AMSenderC;
	App.Receive -> AMReceiverC;
	App.Timer0 -> Timer0;
	App -> CC2420ActiveMessageC.CC2420Packet;
}

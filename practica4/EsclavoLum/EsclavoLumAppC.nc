#include "EsclavoLum.h"

configuration EsclavoLumAppC {
}
implementation {
	// Componentes
	components MainC;
	components LedsC;
	components EsclavoLumC as App;
	components ActiveMessageC;
	components new AMSenderC(AM_ESCLAVO);
	components new AMReceiverC(AM_ESCLAVO);
	components new TimerMilliC() as Timer0;
	components CC2420ActiveMessageC;
	components new HamamatsuS1087ParC() as TotalSolarC;

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
	App.Visible -> TotalSolarC;
}

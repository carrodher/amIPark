#include "RssiBot.h"

configuration RssiBotAppC {
}
implementation {
	// Componentes
	components MainC;
	components LedsC;
	components RssiBotC as App;
	components new TimerMilliC() as RssiRequestTimer;
	components new TimerMilliC() as RedTimer;
	components new TimerMilliC() as GreenTimer;
	components new TimerMilliC() as BlueTimer;
	components ActiveMessageC;
	components new AMSenderC(AM);
	components new AMReceiverC(AM);
	components UserButtonC;
	components CC2420ActiveMessageC;

	// Relaciona Interfaces con Componentes
	App.Boot -> MainC;
	App.Leds -> LedsC;
	App.RssiRequestTimer -> RssiRequestTimer;
	App.RedTimer -> RedTimer;
	App.GreenTimer -> GreenTimer;
	App.BlueTimer -> BlueTimer;
	App.Packet -> AMSenderC;
	App.AMPacket -> AMSenderC;
	App.AMControl -> ActiveMessageC;
	App.AMSend -> AMSenderC;
	App.Receive -> AMReceiverC;
	App.Notify -> UserButtonC;
	App -> CC2420ActiveMessageC.CC2420Packet;
}

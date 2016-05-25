#include "../Global.h"
#include "Fijo.h"

configuration FijoAppC {
}
implementation {
	// Componentes
	components MainC;
	components LedsC;
	components FijoC as App;
	components new TimerMilliC() as RssiResponseTimer;
  components new TimerMilliC() as RedTimer;
  components new TimerMilliC() as GreenTimer;
  components new TimerMilliC() as BlueTimer;
	components ActiveMessageC;
	components new AMSenderC(AM);
	components new AMReceiverC(AM);
  components CC2420ActiveMessageC;

	// Relaciona Interfaces con Componentes
	App.Boot -> MainC;
	App.Leds -> LedsC;
	App.RssiResponseTimer -> RssiResponseTimer;
  App.RedTimer -> RedTimer;
  App.GreenTimer -> GreenTimer;
  App.BlueTimer -> BlueTimer;
	App.Packet -> AMSenderC;
	App.AMPacket -> AMSenderC;
	App.AMControl -> ActiveMessageC;
	App.AMSend -> AMSenderC;
	App.Receive -> AMReceiverC;
  App -> CC2420ActiveMessageC.CC2420Packet;
}

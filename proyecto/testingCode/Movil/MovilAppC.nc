#include "Movil.h"

configuration MovilAppC {
}
implementation {
	// Componentes
	components MainC;
	components LedsC;
	components MovilC as App;
	components new TimerMilliC() as VehicleOrderTimer;
	components new TimerMilliC() as RssiRequestTimer;
  components new TimerMilliC() as RedTimer;
  components new TimerMilliC() as GreenTimer;
  components new TimerMilliC() as BlueTimer;
	components ActiveMessageC;
	components new AMSenderC(AM);
	components new AMReceiverC(AM);
	components UserButtonC;

	// Relaciona Interfaces con Componentes
	App.Boot -> MainC;
	App.Leds -> LedsC;
	App.VehicleOrderTimer -> VehicleOrderTimer;
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
}

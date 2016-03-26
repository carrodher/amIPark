#include "EsclavoTemp.h"

configuration EsclavoTempAppC {
}
implementation {
	// Componentes
	components MainC;
	components LedsC;
	components EsclavoTempC as App;
	components ActiveMessageC;
	components new AMSenderC(AM_ESCLAVO);
	components new AMReceiverC(AM_ESCLAVO);
	components CC2420ActiveMessageC;
	components new SensirionSht11C() as Sht11;

	// Relaciona Interfaces con Componentes
	App.Boot -> MainC;
	App.Leds -> LedsC;
	App.Packet -> AMSenderC;
	App.AMPacket -> AMSenderC;
	App.AMControl -> ActiveMessageC;
	App.AMSend -> AMSenderC;
	App.Receive -> AMReceiverC;
	App -> CC2420ActiveMessageC.CC2420Packet;
	App.Temperature -> Sht11.Temperature;
}

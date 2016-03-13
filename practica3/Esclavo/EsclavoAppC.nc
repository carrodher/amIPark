 #include "Esclavo.h"

 configuration EsclavoAppC {
 }
 implementation {
 	// Componentes
 	components MainC;
 	components LedsC;
 	components EsclavoC as App;
 	components ActiveMessageC;
 	components new AMSenderC(AM_ESCLAVO);
 	components new AMReceiverC(AM_ESCLAVO);
 	components CC2420ActiveMessageC;
 	components new SensirionSht11C() as Sht11;
	components new HamamatsuS10871TsrC() as PhotoActiveC;
	components new HamamatsuS1087ParC() as TotalSolarC;

 	// Relaciona Interfaces con Componentes
 	App.Boot -> MainC;
 	App.Leds -> LedsC;
 	App.Packet -> AMSenderC;
 	App.AMPacket -> AMSenderC;
 	App.AMControl -> ActiveMessageC;
 	App.AMSend -> AMSenderC;
 	App.Receive -> AMReceiverC;
 	App -> CC2420ActiveMessageC.CC2420Packet;
 	App.ReadNotVisible -> PhotoActiveC;
	App.ReadVisible -> TotalSolarC;
	App.Temperature -> Sht11.Temperature;
	App.Humidity -> Sht11.Humidity;
 }

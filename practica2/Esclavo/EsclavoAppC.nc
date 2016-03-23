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

    // Relaciona Interfaces con Componentes
    App.Boot -> MainC;
    App.Leds -> LedsC;
    App.Packet -> AMSenderC;
    App.AMPacket -> AMSenderC;
    App.AMControl -> ActiveMessageC;
    App.AMSend -> AMSenderC;
    App.Receive -> AMReceiverC;
    App -> CC2420ActiveMessageC.CC2420Packet;
}

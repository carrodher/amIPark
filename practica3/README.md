# Práctica 3

En esta práctica se pretende conseguir una comunicación Maestro-Esclavo en la que el maestro envíe periódicamente paquetes al Esclavo solicitando un tipo de medida (temperatura, humedad o luminosidad). El Esclavo, a partir de esos paquetes, debe calcular la RSSI y devolver en otro paquete el valor de RSSI junto con la medida pedida. Por tanto tenemos 3 elementos:
* Maestro
* Esclavo
* Base Station

### Maestro
El Maestro (ID 131) envía periódicamente paquetes al Esclavo (ID 132). Cuando recibe un paquete del Esclavo, comprueba que es su Esclavo el que lo manda y que contiene un valor de RSSI y de medida válido. Enciende los leds en función del tipo de medida solicitado.

### Esclavo
El Esclavo (ID 132) recibe los paquetes del Maestro y tras verificar que son de su Maestro y no de otro, calcula el RSSI relativo a este mensaje. Según el tipo solicitado, hace la medida necesaria y forma un paquete con este valor y lo envía de vuelta a su Maestro. Enciende los leds en función del tipo de medida solicitado.

### Base Station
Sirve para ver la comunicación entre ambos dispositivos.
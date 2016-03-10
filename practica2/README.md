# Práctica 2

En esta práctica se pretende conseguir una comunicación Maestro-Esclavo en la que el maestro envíe periódicamente paquetes al Esclavo. El esclavo, a partir de esos paquetes, debe calcular la RSSI con el Maestro y devolver en otro paquete este valor. Por tanto tenemos 3 elementos:
* Maestro
* Esclavo
* Base Station

### Maestro
El Maestro (ID 131) envía periódicamente paquetes al Esclavo (ID 132). Cuando recibe un paquete del Esclavo, comprueba que es su Esclavo el que lo manda y que contiene un valor de RSSI válido. Mantiene siempre encendido un led y cada vez que recibe un paquete se enciende otro.

### Esclavo
El Esclavo (ID 132) recibe los paquetes del Maestro y tras verificar que son de su Maestro y no de otro, calcula el RSSI relativo a este mensaje. Forma un paquete con este valor y lo envía de vuelta a su Maestro. Mantiene siempre encendido un led y cada vez que recibe un paquete se enciende otro.

### Base Station
Sirve para ver la comunicación entre ambos dispositivos.
# Práctica 4

En esta práctica se pretende conseguir una comunicación entre un Jefe y varios Esclavos, haciendo uso de algoritmos de control de acceso al medio, en este caso por división de tiempo (TDMA). Por tanto tenemos 3 elementos:
* Jefe
* Esclavos
* Base Station

```
/-------------------- T --------------------/-------------- T ---------------/      /-------------- T ---------------/
/----T/4------/---T/4---/---T/4---/---T/4---/-----T/4------/-T/4-/-T/4-/-T/4-/      /-----T/4------/-T/4-/-T/4-/-T/4-/
 ___________________________________________  ________________________________      ________________________________
|     T0      |   T01   |   T02   |   T03   ||     T1      | T11 | T12 | T13 |      |     TN      | TN1 | TN2 | TN3 |
|    orden    |         |         |         ||    orden    |     |     |     | ···  |    orden    |     |     |     |
| 132 131 133 |   132   |   131   |   133   || 133 131 132 | 133 | 131 | 132 |      | 132 133 131 | 132 | 133 | 131 |
```

### Jefe
El Jefe (ID 130) envía periódicamente paquetes a difusión en los que se indica el orden de acceso al canal para conseguir TDMA, este orden se determina de manera **aleatoria**. El paquete enviado por el Jefe contiene su ID y el ID del Esclavo que transimitirá en cada slot. Cuando recibe la respuesta de los esclavos comprueba que los parámetros son correctos.

### Esclavo Temperatura
Este Esclavo (ID 131) recibe los paquetes del Jefe y tras verificar que son de su Jefe y no de otro, calcula el RSSI relativo a este mensaje. Hace la medida de la **temperatura** y forma un paquete con este valor y, tras **calcular en qué slot le toca transmitir** y esperar el tiempo necesario, lo envía de vuelta a su Jefe.

### Esclavo Humedad
Este Esclavo (ID 132) recibe los paquetes del Jefe y tras verificar que son de su Jefe y no de otro, calcula el RSSI relativo a este mensaje. Hace la medida de la **humedad** y forma un paquete con este valor y, tras **calcular en qué slot le toca transmitir** y esperar el tiempo necesario, lo envía de vuelta a su Jefe.

### Esclavo Luminosidad
Este Esclavo (ID 133) recibe los paquetes del Jefe y tras verificar que son de su Jefe y no de otro, calcula el RSSI relativo a este mensaje. Hace la medida de la **luminosidad** y forma un paquete con este valor y, tras **calcular en qué slot le toca transmitir** y esperar el tiempo necesario, lo envía de vuelta a su Jefe.

### Base Station
Sirve para ver la comunicación y los datos entre ambos dispositivos.

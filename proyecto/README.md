# Proyecto párking
[![NesC](https://img.shields.io/badge/NesC-1.3.5-red.svg)](http://nescc.sourceforge.net/)
[![License](https://img.shields.io/badge/License-BY/NC-yellow.svg)](https://github.com/carrodher/tinyOS/blob/master/LICENSE.markdown)

## Introducción
En este proyecto se pretende realizar un sistema de aprcamiento inteligente, para ello contamos con 4 nodos fijos (uno en cada esquina del párking) y un nodo móvil en cada coche.

Mediante algoritmos de posicionamiento se determina cuándo el coche se aproxima al párking desde la calle y cuándo abandona el párking. Una vez dentro del párking se indica qué plazas hay libres para que aparque, y una vez aparcado se registra la plaza.

## Componentes
- Nodo móvil

    Este nodo se encuentra en los robots móviles que simulan los coches, es un nodo que va dormido hasta que detecta que está cerca del párking al recibir paquetes de los nodos de la puerta. En ese momento se despierta para poder obtener la información de las plazas disponibles.

    Una vez que el robot aparca en una de las plazas libres que se le ha indicado, el nodo se vuelve a dormir hasta que vuelve a ponerse en marcha el robot para salir. Cuando sale del párking se vuelve a dormir el nodo hasta que se aproxime nuevamente a la entrada.
- Nodos fijos
    - Base station
    - Nodos normales

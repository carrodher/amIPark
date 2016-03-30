# Proyecto párking
[![NesC](https://img.shields.io/badge/NesC-1.3.5-red.svg)](http://nescc.sourceforge.net/)
[![License](https://img.shields.io/badge/License-BY/NC-yellow.svg)](https://github.com/carrodher/tinyOS/blob/master/LICENSE.markdown)

## Introducción
En este proyecto se pretende realizar un sistema de control de un párking inteligente, para ello contamos con 4 nodos fijos (uno en cada esquina del párking) y un nodo móvil en cada coche.

Mediante algoritmos de posicionamiento, se determina cuándo el coche se aproxima al párking desde la calle y cuándo abandona el párking. Una vez dentro del párking se indica qué plazas hay libres para que aparque, y una vez aparcado se registra la plaza.

![alt tag](https://github.com/carrodher/tinyOS/blob/master/proyecto/diagramas/esquemaInicial.png "Esquema inicial")

## Componentes
1. **Nodo móvil**

    Este nodo se encuentra en los robots móviles que simulan los coches, es un nodo que va **dormido** hasta que detecta que está cerca del párking al recibir paquetes de los nodos de la puerta. En ese momento se **despierta** para poder obtener la información de las plazas libres.

    Una vez que el robot aparca en una de las plazas libres que se le ha indicado, el nodo se vuelve a dormir hasta que se pone de neuvo en marcha el robot para salir. Cuando sale del párking se vuelve a dormir el nodo hasta que se aproxime nuevamente a la entrada.

2. **Nodos fijos**
    1. **Nodos normales:**
    Todos los nodos actúan como nodos normales. Estos nodos se encargan de realizar las tareas relativa a las **puertas** y las tareas de **localización** en el interior del párking, para ello hace uso de los algoritmos vistos en clase.
    Funciones según la tarea:
        - _Puertas_:
            - Dormir/Despertar al nodo móvil
            - Registrar Entradas/Salidas
            - Encender semáforo led sincronizado con entradas y salidas de coches
        - _Localización_:
            - Determinar cuándo un coche se aproxima a cualquiera de las puertas
            - Llevar un registro de las plazas libres y ocupadas dentro del párking
            - Sugerir plazas libres cuando entra un coche.

     En un futuro se irán añadiendo nuevas mejoras y funcionalidades a los nodos fijos.

    2. **Base station**: 
    Tiene todas las características de un **nodo normal**, pero además actúa como **líder del cluster** de 4 nodos que forman el párking. Siendo éste el nodo que lleva el registro de las entradas y salidas detectadas por el resto de nodos, así como las plazas ocupadas y libres. Cuando sea necesario es el encargado de **distribuir** esta información al resto de nodos del clúster.

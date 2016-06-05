# Proyecto párking
[![Build Status](https://travis-ci.org/carrodher/tinyOS.svg?branch=master)](https://travis-ci.org/carrodher/tinyOS)
[![NesC](https://img.shields.io/badge/NesC-1.3.5-red.svg)](http://nescc.sourceforge.net/)
[![License](https://img.shields.io/badge/License-GNU-yellow.svg)](https://github.com/carrodher/tinyOS/blob/master/LICENSE.markdown)

## Introducción
En este proyecto se pretende realizar un sistema de control de un párking inteligente, para ello contamos con 4 nodos fijos (uno en cada esquina del párking) y un nodo móvil en el coche.

Mediante algoritmos de posicionamiento, se determina cuándo el coche se aproxima al párking desde la calle y cuándo abandona el párking. Una vez dentro del párking se indica qué plazas hay libres para que aparque, y una vez aparcado se registra la plaza.

![alt tag](https://github.com/carrodher/tinyOS/blob/master/proyecto/Diagramas/esquemaInicial.png "Esquema inicial")


## Componentes
1. **Nodo móvil**

    Este nodo se encuentra en los robots móviles que simulan los coches, y mediante la pulsación del botón indica su llegada al párking.

    Una vez dentro del párking el nodo móvil se localiza intercambiando mensajes con los 4 nodos fijos, para de esta manera saber cuándo ha aparcado y en qué plaza lo ha hecho, de igual manera se monitoriza la salida del párking del robot.

2. **Nodos fijos**
    1. **Nodos normales:**
    Todos los nodos actúan como nodos normales. Estos nodos se encargan de realizar las tareas de **localización** en el interior del párking, para ello hace uso de los algoritmos de posicionamiento vistos en clase.
    Funciones según la tarea:
        - _Localización_:
            - Determinar cuándo un coche aparca o abandona una plaza
            - Llevar un registro de las plazas libres y ocupadas dentro del párking
            - Sugerir plazas libres cuando entra un coche.

     En un futuro se irán añadiendo nuevas mejoras y funcionalidades a los nodos fijos.

    2. **Máster**:
    Tiene todas las características de un **nodo normal**, pero además actúa como **líder del cluster** de 4 nodos que forman el párking. Siendo éste el nodo que lleva el registro de las entradas y salidas detectadas por el resto de nodos, así como las plazas ocupadas y libres. Cuando sea necesario es el encargado de **distribuir** esta información al resto de nodos del clúster. Además, está conectado a un equipo de escritorio, desde el cual se muestra una interfaz gráfica con el estado del párking, actualizándose en tiempo real.

## GUI

![alt tag](https://github.com/carrodher/tinyOS/blob/master/proyecto/Diagramas/gui.png "GUI")

Para ejecutar la interfaz gráfica, en el equipo conectado al nodo máster hacer lo siguiente:
```shell
sudo apt-get install libgtk-3-0 libgtk-3-dev libgtk-3-common
cd ./proyecto/Interfaz
make all
./gui.out
print | tee park.data
```

## Componentes
Ana Lucero Fernández [@analucfer](https://github.com/analucfer "Ana")

Lourdes Liró Salinas [@loulirsal](https://github.com/loulirsal "Lourdes")

Gloria Martínez Muñoz [@gloriamm](https://github.com/gloriamm "Gloria")

Daniel Sojo España [@Dani57](https://github.com/Dani57 "Dani")

Carlos Rodríguez Hernández [@carrodher](https://github.com/carrodher "Carlos")

# tinyOS
[![NesC](https://img.shields.io/badge/NesC-1.3.5-red.svg)](http://nescc.sourceforge.net/)
[![Linkedin](https://img.shields.io/badge/LinkedIn-Carlos-blue.svg)](https://es.linkedin.com/in/carlosrodriguezhernandez)
[![Twitter](https://img.shields.io/badge/Twitter-carrodher-blue.svg)](https://twitter.com/carrodher)
[![License](https://img.shields.io/badge/License-BY/NC-yellow.svg)](https://github.com/carrodher/tinyOS/blob/master/LICENSE.markdown)

Proyectos y prácticas con tinyOS para TelosB como parte de la asignatura "Redes de Sensores y Sistemas Autónomos"

## Contenido
* [Instalación](#instalación)
* [Uso](#uso)

## Instalación
shhshshshs
Añadimos dos repositorios donde se encuentran los paquetes necesarios. Para ello creamos el fichero /etc/apt/sources.list.d/tinyprod-debian.list y lo abrimos con cualquier editor `sudo vim /etc/apt/sources.list.d/tinyprod-debian.list` añadiendo las siguientes líneas:

```
deb	http://tinyprod.net/repos/debian squeeze main
deb	http://tinyprod.net/repos/debian msp430-46 main
```

Instalamos la clave de seguridad del repositorio:

```
gpg --keyserver keyserver.ubuntu.com --recv-keys 34EC655A
gpg -a --export 34EC655A | sudo apt-key add -
```
Debe mostrar el mensaje 'OK' al finalizar. A veces es necesario cerrar y volver a abrir la terminal tras el paso anterior.

Actualizamos los repositorios e instalamos los paquetes necesarios:
```
sudo	apt-get	update
sudo	apt-get	install nesc tinyos-tools msp430-46 avr-tinyos
```

Descargamos TinyOS en el directorio que queramos, por ejemplo en /home/user/:
```
cd /home/user/
wget http://github.com/tinyos/tinyos-release/archive/tinyos-2_1_2.tar.gz
tar	xf	tinyos-2_1_2.tar.gz
mv	tinyos-release-tinyos-2_1_2	tinyos-main
rm -rf tinyos-2_1_2.tar.gz
```
De esta manera tenemos el directorio /home/user/tinyos-main con todo lo necesario.

Configuramos el entorno
```
export	TOSROOT="/home/user/tinyos-main"
export	TOSDIR="$TOSROOT/tos"
export  CLASSPATH=$CLASSPATH:$TOSROOT/support/sdk/java/tinyos.jar:.
export	MAKERULES="$TOSROOT/support/make/Makerules"
export	PYTHONPATH=$PYTHONPATH:$TOSROOT/support/sdk/python

echo "setting up TinyOS source path to $TOSROOT"
```

Para ello añadir lo anterior (modificando lo necesario) en el fichero .bashrc
```
locate .bashrc
vim /home/user/.bashrc
```

Conviene cerrar y volver a abrir la terminal en este punto.

Para obtener acceso al puerto serie: `sudo gpasswd -a <your user> dialout`. Tras esto hay que cerrar sesión de Ubuntu y volver a entrar para que haga efecto.

Para comprobar la instalación ejecutamos el siguiente comando: `tos-check-env`. Si todo ha ido bien deberán aparecer únicamente dos warnings, uno debido a la versión de Java y otro a la de graphviz, debido a que generalmente la versión instalada es superior a la requerida por TinyOS.

## Uso
Para hacer una prueba de funcionamiento nos situamos en el directorio /home/user/tinyos-main/apps/tutorials/BlinkFail, compilamos y cargamos este programa en un dispositivo TelosB previamente conectado.

Primero comprobamos que el dispositivo es reconocido correctamente: `motelist`

Por último, compilamos y cargamos el ejemplo BlinkFail en el dispositivo:
```
cd /home/user/tinyos-main/apps/tutorials/BlinkFail
make telosb install,ID
```

#include <stdio.h>
#include <stdlib.h>
#include <cairo.h>		// Pinta
#include <gtk/gtk.h>	// Interfaz
#include <math.h>		// Tamaño círculos
#include <regex.h>		// Expresiones regulares
#include <time.h>		// Fecha/Hora
#include <getopt.h>		// Entrada de parámetros

// Fichero con la GUI creado por glade
#define BUILDER_FILE "builder.glade"

// Estrcutura para getopt
static struct option long_options[] =
{
    {"timer",	required_argument,	0,  't'},
	{"help",	no_argument,		0,  'h'},
    {0, 0, 0, 0}
};

// Callback para dibujar los círculos
static gboolean onDrawEvent(GtkWidget *widget, cairo_t *cr, gpointer gui);
// Callback para el timer
static gboolean timer_cb(gpointer gui);

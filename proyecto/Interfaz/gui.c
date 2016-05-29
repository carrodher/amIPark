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

// Estructura para los datos de la interfaz
struct gui {
	// Objetos de la interfaz
	GtkBuilder *builder;
	GtkWidget *window;
	GtkWidget *darea1;
	GtkWidget *darea2;
	GtkWidget *darea3;
	GtkWidget *darea4;

	// Timer
	int timer;

	// FicheroS con los datos del mote y el log
	FILE *fileMote;
	FILE *fileLog;

	// Distingue las plazas
	int p1, p2, p3, p4, flag;

	// Expresiones regulares
	char str[512];		// Cadena leída
	regex_t regex;
	char c;				// Guarda el # (basura)

	// Fecha/Hora
	time_t rawtime;
};

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

int main(int argc, char **argv) {
	struct gui *g;
	// Getopt
	int option_index, c;
	int time = FALSE;

	// Struct para pasar todo los datos entre funciones
	g = (struct gui *)malloc(sizeof(struct gui));
	if (!g) {
		fprintf(stderr, "Error al reservar struct\n");
		return -1;
	}

	while ((c = getopt_long(argc, argv, "t:h", long_options, &option_index)) != -1) {
		switch (c) {
			case 't':
				g->timer = strtol(optarg, NULL, 0);
				time = TRUE;
				break;
			case 'h':
			case '?':
				printf("  Uso:\n\t./gui.out -t <miliSeg>\n");
				return -1;
				break;
		}
	}

	// Si no se ha introducido => Valor por defecto (1ms)
	if (time == FALSE) {
		g->timer = 1;
	}

	gtk_init(&argc, &argv);

	// Builder de glade
	g->builder = gtk_builder_new();
	if(!gtk_builder_add_from_file(g->builder,BUILDER_FILE,NULL)){
		fprintf(stderr, "No se puede abrir el fichero \"%s\"\n",BUILDER_FILE);
		return -1;
	}

	// Abre el fichero del mote y comprueba la apertura
	if (!(g->fileMote = fopen("park.data", "r"))) {
		fprintf(stderr, "No se puede abrir el fichero \"park.data\"\n");
		return -1;
	}

	// Abre el fichero de log y comprueba la apertura
	if (!(g->fileLog = fopen("park.log", "w"))) {
		fprintf(stderr, "No se puede abrir el fichero \"park.log\"\n");
		return -1;
	}

	// Compila regex
	if (regcomp(&(g->regex), "# [0-1] [0-1] [0-1] [0-1]", 0)) {
		fprintf(stderr, "Error al compilar regex\n");
		exit(1);
	}

	// Objetos
	g->window = GTK_WIDGET(gtk_builder_get_object(g->builder,"window"));
	g->darea1 = GTK_WIDGET(gtk_builder_get_object(g->builder,"darea1"));
	g->darea2 = GTK_WIDGET(gtk_builder_get_object(g->builder,"darea2"));
	g->darea3 = GTK_WIDGET(gtk_builder_get_object(g->builder,"darea3"));
	g->darea4 = GTK_WIDGET(gtk_builder_get_object(g->builder,"darea4"));

	// Al principio todas las plazas vacías
	g->p1 = 0;
	g->p2 = 0;
	g->p3 = 0;
	g->p4 = 0;
	g->flag = 0;

	// Señales
	g_signal_connect(g->window,"destroy",G_CALLBACK(gtk_main_quit),NULL);
	g_signal_connect(g->darea1, "draw", G_CALLBACK(onDrawEvent), g);
	g_signal_connect(g->darea2, "draw", G_CALLBACK(onDrawEvent), g);
	g_signal_connect(g->darea3, "draw", G_CALLBACK(onDrawEvent), g);
	g_signal_connect(g->darea4, "draw", G_CALLBACK(onDrawEvent), g);
	gtk_builder_connect_signals(g->builder,NULL);

	// Muestra la ventana
	gtk_widget_show_all(g->window);
	// Comienza el bucle con el primer evento de timer
	g_timeout_add(1, timer_cb, g);

	// Inicia la función que ejecuta la GUI
	gtk_main();

	regfree(&(g->regex));		// Libera reserva para regex
	fclose(g->fileMote);		// Cierra el fichero mote
	fclose(g->fileLog);		// Cierra el fichero mote

	return 0;
}

// Callback para el timer
static gboolean timer_cb(gpointer gui) {
	printf("\nTimer!\n");

	struct gui *g = (struct gui *)gui;

	// Lee una línea completa del fichero
	if(fgets(g->str, 512, g->fileMote) != NULL) {
		printf("Cadena leída: %s", g->str);
	}
	else
		perror("Error al leer cadena");

	// Ejecuta regex sobre la línea leída
	if (!regexec(&(g->regex), g->str, 0, NULL, 0)) {
		// Si hay match: Saca los valores de las plazas para pintarlos
		sscanf(g->str, "%c %d %d %d %d",&(g->c),&(g->p1),&(g->p2),&(g->p3),&(g->p4));
		printf("Match => %d %d %d %d [NUEVO] \n", g->p1, g->p2, g->p3, g->p4);

		// Vuelve a pintar los círculos con los nuevos valores
		gtk_widget_queue_draw(GTK_WIDGET(g->darea1));
		gtk_widget_queue_draw(GTK_WIDGET(g->darea2));
		gtk_widget_queue_draw(GTK_WIDGET(g->darea3));
		gtk_widget_queue_draw(GTK_WIDGET(g->darea4));

		// Reproduce el sonido cuando hay algún cambio
		system("mpg123 ./sound.mp3");

		// Guarda un log con los aparcamientos/salidas
		time(&(g->rawtime));

		fprintf(g->fileLog,"%s\tp1=%d p2=%d p3=%d p4=%d\n", asctime(localtime(&(g->rawtime))), g->p1, g->p2, g->p3, g->p4);
		fprintf(g->fileLog,"\t%d plazas ocupadas\n", g->p1+g->p2+g->p3+g->p4);
		fprintf(g->fileLog,"\t%d plazas libres\n", 4-(g->p1+g->p2+g->p3+g->p4));
	}
	else {
		// Si no hay match: No pinta los círculos de nuevo, deja los que hay
		printf("No Match => %d %d %d %d [ANTERIOR] \n", g->p1, g->p2, g->p3, g->p4);
	}

	// Tras 1ms vuelve a al inicio de esta función
	g_timeout_add(g->timer, timer_cb, g);

	return FALSE;
}

// Callback para pintar los círculos
static gboolean onDrawEvent(GtkWidget *widget, cairo_t *cr, gpointer gui) {
	struct gui *g = (struct gui *)gui;
	GtkWidget *win = gtk_widget_get_toplevel(widget);

	int width, height;
	gtk_window_get_size(GTK_WINDOW(win), &width, &height);

	/* Texto */
	// Fuente para las letras
	cairo_select_font_face(cr, "Purisa", CAIRO_FONT_SLANT_NORMAL,CAIRO_FONT_WEIGHT_BOLD);
	// Tamaño de las letras
	cairo_set_font_size(cr, 50);
	// Posición del texto
	cairo_move_to(cr, 50, 60);

	// En función del flag determina el área que toca pintar
	switch (g->flag) {
		case 0:
			/* Texto */
			cairo_show_text(cr, "Plaza 3 ");
			cairo_fill(cr);

			/* Círculo */
			cairo_translate(cr, width/4, height/4);
			cairo_arc(cr, 0, 0, 120, 0, 2*M_PI);
			cairo_stroke_preserve(cr);

			// Plaza 1 ocupada
			if (g->p3 == 1) {
				cairo_set_source_rgb(cr, 1, 0, 0);					// Rojo
			}
			// Plaza 1 libre
			else {
				cairo_set_source_rgb(cr, 0, 1, 0);					// Verde
			}
			break;
		case 1:
			/* Texto */
			cairo_show_text(cr, "Plaza 4 ");
			cairo_fill(cr);

			/* Círculo */
			// Posición del círculo
			cairo_translate(cr, width/4, height/4);
			cairo_arc(cr, 0, 0, 120, 0, 2*M_PI);
			cairo_stroke_preserve(cr);

			// Plaza 3 ocupada
			if (g->p4 == 1) {
				cairo_set_source_rgb(cr, 1, 0, 0);					// Rojo
			}
			// Plaza 3 libre
			else {
				cairo_set_source_rgb(cr, 0, 1, 0);					// Verde
			}
			break;
		case 2:
			/* Texto */
			cairo_show_text(cr, "Plaza 2 ");
			cairo_fill(cr);

			/* Círculo */
			cairo_translate(cr, width/4, height/4);
			cairo_arc(cr, 0, 0, 120, 0, 2*M_PI);
			cairo_stroke_preserve(cr);

			// Plaza 2 ocupada
			if (g->p2 == 1) {
				cairo_set_source_rgb(cr, 1, 0, 0);					// Rojo
			}
			// Plaza 2 libre
			else {
				cairo_set_source_rgb(cr, 0, 1, 0);					// Verde
			}
			break;
		case 3:
			/* Texto */
			cairo_show_text(cr, "Plaza 1 ");
			cairo_fill(cr);

			/* Círculo */
			cairo_translate(cr, width/4, height/4);
			cairo_arc(cr, 0, 0, 120, 0, 2*M_PI);
			cairo_stroke_preserve(cr);

			// Plaza 1 ocupada
			if (g->p1 == 1) {
				cairo_set_source_rgb(cr, 1, 0, 0);					// Rojo
			}
			// Plaza 1 libre
			else {
				cairo_set_source_rgb(cr, 0, 1, 0);					// Verde
			}
			break;
	}
	cairo_fill(cr);

	// Actualiza el flag del área para la siguiente entrada
	if (g->flag == 3)
		g->flag = 0;
	else
		g->flag++;

	return FALSE;
}

#include <stdio.h>
#include <stdlib.h>
#include <cairo.h>
#include <gtk/gtk.h>
#include <math.h>

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

	// Fichero con los datos del mote
	FILE *file;

	// Distingue las plazas
	int p1, p2, p3, p4, flag;
};

// Callback para dibujar los círculos
static gboolean onDrawEvent(GtkWidget *widget, cairo_t *cr, gpointer gui);
// Callback para el timer
static gboolean timer_cb(gpointer gui);

int main(int argc, char **argv) {
	struct gui *g;

	// Struct
	g = (struct gui *)malloc(sizeof(struct gui));
	if (!g) {
		fprintf(stderr, "Error al reservar struct\n");
		return -1;
	}
	gtk_init(&argc, &argv);

	// Builder de glade
	g->builder = gtk_builder_new();
	if(!gtk_builder_add_from_file(g->builder,BUILDER_FILE,NULL)){
		fprintf(stderr, "No se puede abrir el fichero \"%s\"\n",BUILDER_FILE);
		return -1;
	}

	// Abre el fichero y comprueba la apertura
	if (!(g->file = fopen("park.data", "r"))) {
		fprintf(stderr, "No se puede abrir el fichero \"park.data\"\n");
		return -1;
	}

	// Objects
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

	// Signals
	g_signal_connect(g->window,"destroy",G_CALLBACK(gtk_main_quit),NULL);
	g_signal_connect(g->darea1, "draw", G_CALLBACK(onDrawEvent), g);
	g_signal_connect(g->darea2, "draw", G_CALLBACK(onDrawEvent), g);
	g_signal_connect(g->darea3, "draw", G_CALLBACK(onDrawEvent), g);
	g_signal_connect(g->darea4, "draw", G_CALLBACK(onDrawEvent), g);
	gtk_builder_connect_signals(g->builder,NULL);

	// Muestra la ventana
	gtk_widget_show_all(g->window);
	g_timeout_add(1, timer_cb, g);

	// Inicia la función que ejecuta la GUI
	gtk_main();

	fclose(g->file);
	return 0;
}

// Callback para el timer
static gboolean timer_cb(gpointer gui) {
	printf("Timer!\n");
	struct gui *g = (struct gui *)gui;
	int width, height, p1, p2, p3, p4;

	int ret = fscanf(g->file, "%d %d %d %d",&(g->p1),&(g->p2),&(g->p3),&(g->p4));
	if (ferror(g->file) || (ret != 4)) {
		perror("Error al leer");
	}

	gtk_widget_queue_draw(GTK_WIDGET(g->darea1));
	gtk_widget_queue_draw(GTK_WIDGET(g->darea2));
	gtk_widget_queue_draw(GTK_WIDGET(g->darea3));
	gtk_widget_queue_draw(GTK_WIDGET(g->darea4));

	g_timeout_add(3000, timer_cb, g);
	return FALSE;
}

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

	if (g->flag == 3)
		g->flag = 0;
	else
		g->flag++;

	printf("%d %d %d %d\n", g->p1, g->p2, g->p3, g->p4);

	return FALSE;
}

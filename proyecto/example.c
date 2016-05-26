#include <stdio.h>
#include <stdlib.h>
#include <cairo.h>
#include <gtk/gtk.h>
#include <math.h>

// Fichero con la GUI creado por glade
#define BUILDER_FILE "builder.glade"

// Callback para dibujar los círculos
static gboolean onDrawEvent(GtkWidget *widget, cairo_t *cr, const char *str);

int main(int argc, char **argv) {
	GtkBuilder *builder;
	GtkWidget *window;
	GtkWidget *darea1;
	GtkWidget *darea2;
	GtkWidget *darea3;
	GtkWidget *darea4;

	gtk_init(&argc, &argv);

	/* builder */
	builder = gtk_builder_new();
	if(!gtk_builder_add_from_file(builder,BUILDER_FILE,NULL)){
		fprintf(stderr, "Can't open file \"%s\"\n",BUILDER_FILE);
		exit(EXIT_FAILURE);
	}

	/* Objects */
	window = GTK_WIDGET(gtk_builder_get_object(builder,"window"));
	darea1 = GTK_WIDGET(gtk_builder_get_object(builder,"darea1"));
	darea2 = GTK_WIDGET(gtk_builder_get_object(builder,"darea2"));
	darea3 = GTK_WIDGET(gtk_builder_get_object(builder,"darea3"));
	darea4 = GTK_WIDGET(gtk_builder_get_object(builder,"darea4"));

	/* Signals */
	g_signal_connect(window,"destroy",G_CALLBACK(gtk_main_quit),NULL);
	g_signal_connect(darea1, "draw", G_CALLBACK(onDrawEvent), "Plaza 1 ");
	g_signal_connect(darea2, "draw", G_CALLBACK(onDrawEvent), "Plaza 2 ");
	g_signal_connect(darea3, "draw", G_CALLBACK(onDrawEvent), "Plaza 3 ");
	g_signal_connect(darea4, "draw", G_CALLBACK(onDrawEvent), "Plaza 4 ");
	gtk_builder_connect_signals(builder,NULL);

	// Muestra la ventana
	gtk_widget_show_all(window);

	// Inicia la función que ejecuta la GUI
	gtk_main();

	return 0;
}

static gboolean onDrawEvent(GtkWidget *widget, cairo_t *cr, const char *str) {
	GtkWidget *win = gtk_widget_get_toplevel(widget);

	int width, height;
	gtk_window_get_size(GTK_WINDOW(win), &width, &height);

	// Fuente para las letras
	cairo_select_font_face(cr, "Purisa", CAIRO_FONT_SLANT_NORMAL,CAIRO_FONT_WEIGHT_BOLD);
	// Tamaño de las letras
	cairo_set_font_size(cr, 50);
	// Posición del texto
	cairo_move_to(cr, 50, 60);
	// Imprime texto
	cairo_show_text(cr, str);
	cairo_fill(cr);

	// Posición del círculo
	cairo_translate(cr, width/4, height/4);
	// Círculo
	cairo_arc(cr, 0, 0, 120, 0, 2*M_PI);
	cairo_stroke_preserve(cr);

	int var = 0;

	if (str == "Plaza 1 " || str == "Plaza 3 ") {			// Plaza ocupada
		cairo_set_source_rgb(cr, 1, 0, 0);	// Rojo
	}
	else if (str == "Plaza 2 " || str == "Plaza 4 ") {		// Plaza libre
		cairo_set_source_rgb(cr, 0, 1, 0);	// Verde
	}

	// Imprime círculo
	cairo_fill(cr);

	return FALSE;
}

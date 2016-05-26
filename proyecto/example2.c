#include <gtk/gtk.h>
#include <glib.h>
//#include <glade/glade.h>

/* This is the callback for the delete_event, i.e. window closing */
void
inform_user_of_time_wasted (GtkWidget *widget, GdkEvent * event, gpointer data)
{
	/* Get the elapsed time since the timer was started */
	GTimer * timer = (GTimer*) data;
	gulong dumb_API_needs_this_variable;
	gdouble time_elapsed = g_timer_elapsed (timer, &dumb_API_needs_this_variable);

	/* Tell the user how much time they used */
	printf ("You wasted %.2f seconds with this program.\n", time_elapsed);

	/* Free the memory from the timer */
	g_timer_destroy (timer);

	/* Make the main event loop quit */
	gtk_main_quit ();
}

gboolean
update_progress_bar (gpointer data)
{
	gtk_progress_bar_pulse (GTK_PROGRESS_BAR (data));

	/* Return true so the function will be called again; returning false removes
	* this timeout function.
	*/
	return TRUE;
}

int
main (int argc, char *argv[])
{
	GladeXML *what_a_waste;

	gtk_init (&argc, &argv);

	/* load the interface */
	what_a_waste = glade_xml_new ("example-2.glade", NULL, NULL);

	/* Get the progress bar widget and change it to "activity mode", i.e. a block
	* that bounces back and forth instead of a normal progress bar that fills
	* to completion.
	*/
	GtkWidget *progress_bar = glade_xml_get_widget (what_a_waste, "Progress Bar");
	gtk_progress_bar_pulse (GTK_PROGRESS_BAR (progress_bar));

	/* Add a timeout to update the progress bar every 100 milliseconds or so */
	gint func_ref = g_timeout_add (100, update_progress_bar, progress_bar);

	/* Start the wasted_time_tracker timer, and connect it to the callback */
	GTimer *wasted_time_tracker = g_timer_new ();
	GtkWidget *widget = glade_xml_get_widget (what_a_waste, "WasteTimeWindow");
	g_signal_connect (G_OBJECT (widget), "delete_event",
	G_CALLBACK (inform_user_of_time_wasted),
	wasted_time_tracker);

	/* start the event loop */
	gtk_main ();

	/* Remove the timeout function--not that it matters since we're about to end */
	g_source_remove (func_ref);

	return 0;
}

using Gtk;

public class MyTrueNorthApp : Gtk.Application {
    public MyTrueNorthApp () {
        Object (application_id: "com.github.lighthouselogic.mytruenorth");
    }

    protected override void activate () {
        var window = new Gtk.ApplicationWindow (this);
        window.set_default_size (800, 500);
        window.set_title ("MyTrueNorth");

        // Load Custom CSS for Black/Green Theme
        var provider = new Gtk.CssProvider ();
        provider.load_from_path ("style.css");
        Gtk.StyleContext.add_provider_for_display (
            Gdk.Display.get_default (), 
            provider, 
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        );

        var main_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        var stack = new Gtk.Stack ();
        stack.set_transition_type (Gtk.StackTransitionType.SLIDE_LEFT_RIGHT);

        // Sidebar Navigation
        var sidebar_list = new Gtk.ListBox ();
        sidebar_list.add_css_class ("sidebar");
        sidebar_list.set_size_request (250, -1);

        // Define our 5 Steps
        string[] steps = {
            "Step 1 - What's Important",
            "Step 2 - Weights (%)",
            "Step 3 - Scoring (1-10)",
            "Step 4 - Results",
            "Step 5 - Graph Results"
        };

        foreach (var step_name in steps) {
            var label = new Gtk.Label (step_name);
            label.set_margin_all (12);
            sidebar_list.append (label);

            // Create a placeholder page for each step
            var page = new Gtk.CenterBox ();
            page.set_center_widget (new Gtk.Label (step_name + " Interface Goes Here"));
            stack.add_titled (page, step_name, step_name);
        }

        // Logic to switch pages when sidebar is clicked
        sidebar_list.row_selected.connect ((row) => {
            var index = row.get_index ();
            stack.set_visible_child_name (steps[index]);
        });

        main_box.append (sidebar_list);
        main_box.append (stack);
        stack.set_hexpand (true);

        window.set_child (main_box);
        window.present ();
    }

    public static int main (string[] args) {
        return new MyTrueNorthApp ().run (args);
    }
}

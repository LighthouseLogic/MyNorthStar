using Gtk;

public class MyTrueNorthApp : Gtk.Application {
    // We store these as class variables so we can access them 
    // when switching between tabs
    private MyTrueNorth.StepOneVBox step1;
    private MyTrueNorth.StepTwoVBox step2;
    private Gtk.Stack stack;

    public MyTrueNorthApp () {
        Object (application_id: "com.github.lighthouselogic.mytruenorth");
    }

    protected override void activate () {
        var window = new Gtk.ApplicationWindow (this);
        window.set_default_size (900, 600);
        window.set_title ("MyTrueNorth");

        // Load CSS (Keep your style.css code)
        var provider = new Gtk.CssProvider ();
        provider.load_from_path ("style.css");
        Gtk.StyleContext.add_provider_for_display (Gdk.Display.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        var main_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        stack = new Gtk.Stack ();
        stack.set_transition_type (Gtk.StackTransitionType.SLIDE_LEFT_RIGHT);

        // 1. Create instances of your separate Step classes
        step1 = new MyTrueNorth.StepOneVBox ();
        step2 = new MyTrueNorth.StepTwoVBox ();

        // 2. Add them to the stack
        stack.add_titled (step1, "step1", "Step 1 - What's Important");
        stack.add_titled (step2, "step2", "Step 2 - Weights (%)");

        // Placeholder for future steps
        stack.add_titled (new Gtk.Label ("Step 3 logic coming soon"), "step3", "Step 3 - Scoring");

        // 3. Sidebar Navigation
        var sidebar_list = new Gtk.ListBox ();
        sidebar_list.add_css_class ("sidebar");
        sidebar_list.set_size_request (250, -1);

        string[] step_titles = { "Step 1 - What's Important", "Step 2 - Weights (%)", "Step 3 - Scoring" };
        foreach (var title in step_titles) {
            var label = new Gtk.Label (title);
            label.set_margin_all (12);
            sidebar_list.append (label);
        }

        // 4. THE CONNECTION LOGIC
        sidebar_list.row_selected.connect ((row) => {
            var index = row.get_index ();
            
            // If user clicks Step 2, grab the data from Step 1 and refresh the sliders
            if (index == 1) { 
                step2.refresh_list (step1.important_items);
            }
            
            stack.set_visible_child_full (index == 0 ? "step1" : (index == 1 ? "step2" : "step3"), Gtk.StackTransitionType.SLIDE_LEFT_RIGHT);
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

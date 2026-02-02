using Gtk;

public class MyTrueNorthApp : Gtk.Application {
    // We store these as class variables so we can access them 
    // when switching between tabs
    private MyTrueNorth.StepOneVBox step1;
    private MyTrueNorth.StepTwoVBox step2;
    private MyTrueNorth.StepThreeVBox step3;
    private MyTrueNorth.StepFourVBox step4;
    private MyTrueNorth.StepFiveVBox step5;
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
        step3 = new MyTrueNorth.StepThreeVBox ();
        step4 = new MyTrueNorth.StepFourVBox ();
        step5 = new MyTrueNorth.StepFiveVBox ();

        // 2. Add them to the stack
        stack.add_titled (step1, "step1", "Step 1 - What's Important");
        stack.add_titled (step2, "step2", "Step 2 - Weights (%)");
        stack.add_titled (step3, "step3", "Step 3 - Scoring (1-10)");
        stack.add_titled (step4, "step4", "Step 4 - Results");
        stack.add_titled (step5, "step5", "Step 5 - Graph Results");

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

            // Logic to prepare data for each specific step
            if (index == 1) { 
                step2.refresh_list (step1.important_items);
            } else if (index == 2) { 
                step3.refresh_list (step1.important_items);
            } else if (index == 3) {
                step4.calculate_and_display (step1.important_items, step2.weights_map, step3.scores_map);
            } else if (index == 4) {
                step5.update_chart (step1.important_items, step2.weights_map, step3.scores_map);
            }

            // Determine which "room" (string ID) to show based on the index
            string target_step = "step1";
            if (index == 1) target_step = "step2";
            else if (index == 2) target_step = "step3";
            else if (index == 3) target_step = "step4";
            else if (index == 4) target_step = "step5";

            // Switch the visible screen
            stack.set_visible_child_full (target_step, Gtk.StackTransitionType.SLIDE_LEFT_RIGHT);
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

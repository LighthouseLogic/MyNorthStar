using Gtk;
using Gee;

namespace MyTrueNorth {

    public class StepTwoVBox : Gtk.Box {
        private Gtk.ListBox sliders_list;
        private Gtk.Label total_label;
        public HashMap<string, double> weights_map;

        public StepTwoVBox () {
            Object (orientation: Gtk.Orientation.VERTICAL, spacing: 20);
            this.set_margin_all (40);
            
            weights_map = new HashMap<string, double> ();

            // Header
            var title = new Gtk.Label ("Step 2 - Assign Weights (%)");
            title.add_css_class ("title-label");
            this.append (title);

            var instruction = new Gtk.Label ("How much does each element contribute to your total fulfillment?");
            instruction.set_wrap (true);
            this.append (instruction);

            // List of Sliders
            sliders_list = new Gtk.ListBox ();
            sliders_list.set_selection_mode (Gtk.SelectionMode.NONE);
            sliders_list.add_css_class ("elements-list");
            
            var scroll = new Gtk.ScrolledWindow ();
            scroll.set_vexpand (true);
            scroll.set_child (sliders_list);
            this.append (scroll);

            // Footer Total
            total_label = new Gtk.Label ("Total Weight: 0%");
            total_label.add_css_class ("total-label");
            this.append (total_label);
        }

        // This method will be called when navigating TO this page
        public void refresh_list (ArrayList<string> items) {
            // Clear existing rows
            var child = sliders_list.get_first_child ();
            while (child != null) {
                var next = child.get_next_sibling ();
                sliders_list.remove (child);
                child = next;
            }

            foreach (var item in items) {
                var row_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 5);
                row_box.set_margin_all (10);

                var name_label = new Gtk.Label (item);
                name_label.set_halign (Gtk.Align.START);

                // Slider (Scale) from 0 to 100
                var adj = new Gtk.Adjustment (0, 0, 101, 1, 10, 0);
                var slider = new Gtk.Scale (Gtk.Orientation.HORIZONTAL, adj);
                slider.set_draw_value (true);
                slider.set_value_pos (Gtk.PositionType.RIGHT);
                slider.set_hexpand (true);

                slider.value_changed.connect (() => {
                    weights_map.set (item, slider.get_value ());
                    update_total ();
                });

                row_box.append (name_label);
                row_box.append (slider);
                sliders_list.append (row_box);
                
                // Initialize map
                weights_map.set (item, 0.0);
            }
        }

        private void update_total () {
            double total = 0;
            foreach (var val in weights_map.values) {
                total += val;
            }

            total_label.set_text ("Total Weight: %.0f%%".printf (total));

            // Visual feedback if over 100%
            if (total > 100) {
                total_label.add_css_class ("warning-text");
            } else {
                total_label.remove_css_class ("warning-text");
            }
        }
    }
}

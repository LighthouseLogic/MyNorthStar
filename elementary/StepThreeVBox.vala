using Gtk;
using Gee;

namespace MyTrueNorth {

    public class StepThreeVBox : Gtk.Box {
        private Gtk.ListBox scores_list;
        public HashMap<string, int> scores_map;

        public StepThreeVBox () {
            Object (orientation: Gtk.Orientation.VERTICAL, spacing: 20);
            this.set_margin_all (40);
            
            scores_map = new HashMap<string, int> ();

            var title = new Gtk.Label ("Step 3 - Current Score (1-10)");
            title.add_css_class ("title-label");
            this.append (title);

            var instruction = new Gtk.Label ("On a scale of 1-10, how well are you doing in each area?");
            this.append (instruction);

            scores_list = new Gtk.ListBox ();
            scores_list.set_selection_mode (Gtk.SelectionMode.NONE);
            scores_list.add_css_class ("elements-list");
            
            var scroll = new Gtk.ScrolledWindow ();
            scroll.set_vexpand (true);
            scroll.set_child (scores_list);
            this.append (scroll);
        }

        public void refresh_list (ArrayList<string> items) {
            var child = scores_list.get_first_child ();
            while (child != null) {
                var next = child.get_next_sibling ();
                scores_list.remove (child);
                child = next;
            }

            foreach (var item in items) {
                var row_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 5);
                row_box.set_margin_all (10);

                var name_label = new Gtk.Label (item);
                name_label.set_halign (Gtk.Align.START);

                // Slider from 1 to 10
                var adj = new Gtk.Adjustment (5, 1, 11, 1, 1, 0);
                var slider = new Gtk.Scale (Gtk.Orientation.HORIZONTAL, adj);
                slider.set_draw_value (true);
                slider.set_digits (0); // No decimals
                slider.set_has_origin (true);
                slider.set_hexpand (true);

                slider.value_changed.connect (() => {
                    scores_map.set (item, (int)slider.get_value ());
                });

                row_box.append (name_label);
                row_box.append (slider);
                scores_list.append (row_box);
                
                scores_map.set (item, 5); // Default to middle
            }
        }
    }
}

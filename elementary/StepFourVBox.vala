using Gtk;
using Gee;

namespace MyTrueNorth {

    public class StepFourVBox : Gtk.Box {
        private Gtk.ListBox results_list;
        private Gtk.Label total_score_label;

        public StepFourVBox () {
            Object (orientation: Gtk.Orientation.VERTICAL, spacing: 20);
            this.set_margin_all (40);

            var title = new Gtk.Label ("Step 4 - Results");
            title.add_css_class ("title-label");
            this.append (title);

            // Results Table Header
            var header_hbox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 10);
            header_hbox.add_css_class ("results-header");
            
            var name_h = new Gtk.Label ("Element");
            name_h.set_hexpand (true);
            name_h.set_halign (Gtk.Align.START);
            
            var weight_h = new Gtk.Label ("Weight");
            weight_h.set_size_request (80, -1);
            
            var score_h = new Gtk.Label ("Score");
            score_h.set_size_request (80, -1);
            
            var weighted_h = new Gtk.Label ("Weighted");
            weighted_h.set_size_request (100, -1);

            header_hbox.append (name_h);
            header_hbox.append (weight_h);
            header_hbox.append (score_h);
            header_hbox.append (weighted_h);
            this.append (header_hbox);

            // Results List
            results_list = new Gtk.ListBox ();
            results_list.set_selection_mode (Gtk.SelectionMode.NONE);
            results_list.add_css_class ("elements-list");
            
            var scroll = new Gtk.ScrolledWindow ();
            scroll.set_vexpand (true);
            scroll.set_child (results_list);
            this.append (scroll);

            // Final Total Score
            total_score_label = new Gtk.Label ("Total Fulfillment Score: 0.00");
            total_score_label.add_css_class ("total-label");
            this.append (total_score_label);
        }

        public void calculate_and_display (ArrayList<string> items, HashMap<string, double> weights, HashMap<string, int> scores) {
            // Clear existing rows
            var child = results_list.get_first_child ();
            while (child != null) {
                var next = child.get_next_sibling ();
                results_list.remove (child);
                child = next;
            }

            double grand_total = 0.0;

            foreach (var item in items) {
                double w = weights.get (item) / 100.0; // Convert % to decimal
                int s = scores.get (item);
                double weighted_score = w * s;
                grand_total += weighted_score;

                var row = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 10);
                row.set_margin_all (10);

                var name_l = new Gtk.Label (item);
                name_l.set_hexpand (true);
                name_l.set_halign (Gtk.Align.START);

                var weight_l = new Gtk.Label ("%.0f%%".printf (w * 100));
                weight_l.set_size_request (80, -1);

                var score_l = new Gtk.Label ("%d".printf (s));
                score_l.set_size_request (80, -1);

                var weighted_l = new Gtk.Label ("%.2f".printf (weighted_score));
                weighted_l.set_size_request (100, -1);

                row.append (name_l);
                row.append (weight_l);
                row.append (score_l);
                row.append (weighted_l);
                results_list.append (row);
            }

            total_score_label.set_text ("Total Fulfillment Score: %.2f / 10.00".printf (grand_total));
        }
    }
}

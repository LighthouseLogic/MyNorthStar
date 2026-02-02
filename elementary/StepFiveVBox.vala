using Gtk;
using Gee;
using Cairo;

namespace MyTrueNorth {

    public class StepFiveVBox : Gtk.Box {
        private Gtk.DrawingArea drawing_area;
        private ArrayList<FulfillmentElement> sorted_elements;

        public StepFiveVBox () {
            Object (orientation: Gtk.Orientation.VERTICAL, spacing: 20);
            this.set_margin_all (40);

            var title = new Gtk.Label ("Step 5 - Pareto Chart");
            title.add_css_class ("title-label");
            this.append (title);

            drawing_area = new Gtk.DrawingArea ();
            drawing_area.set_vexpand (true);
            drawing_area.set_draw_func (on_draw);
            this.append (drawing_area);

            sorted_elements = new ArrayList<FulfillmentElement> ();
        }

        public void update_chart (ArrayList<string> items, HashMap<string, double> weights, HashMap<string, int> scores) {
            sorted_elements.clear ();
            
            foreach (var item in items) {
                double w = weights.get (item) / 100.0;
                int s = scores.get (item);
                sorted_elements.add (new FulfillmentElement (item, w, s));
            }

            // Sort High to Low for Pareto effect
            sorted_elements.sort ((a, b) => {
                if (a.get_weighted_score () < b.get_weighted_score ()) return 1;
                if (a.get_weighted_score () > b.get_weighted_score ()) return -1;
                return 0;
            });

            drawing_area.queue_draw ();
        }

        private void on_draw (Gtk.DrawingArea area, Cairo.Context cr, int width, int height) {
            if (sorted_elements.size == 0) return;

            double margin = 50.0;
            double chart_width = width - (margin * 2);
            double chart_height = height - (margin * 2);
            double bar_width = chart_width / sorted_elements.size;

            // Background
            cr.set_source_rgb (0, 0, 0); // Black
            cr.paint ();

            double total_possible = 10.0;
            double cumulative_score = 0.0;

            // Draw Bars (Weighted Scores)
            for (int i = 0; i < sorted_elements.size; i++) {
                var el = sorted_elements.get (i);
                double val = el.get_weighted_score ();
                double bar_h = (val / total_possible) * chart_height;

                // Green Bars
                cr.set_source_rgb (0, 1, 0); 
                cr.rectangle (margin + (i * bar_width) + 5, height - margin - bar_h, bar_width - 10, bar_h);
                cr.fill ();

                // Cumulative Line Logic
                double prev_cum = cumulative_score;
                cumulative_score += val;

                // Draw Line (Percentage of total current fulfillment)
                cr.set_source_rgb (1, 1, 1); // White line for contrast
                cr.set_line_width (2.0);
                if (i > 0) {
                    double prev_x = margin + ((i - 1) * bar_width) + (bar_width / 2);
                    double prev_y = height - margin - ((prev_cum / 10.0) * chart_height);
                    double curr_x = margin + (i * bar_width) + (bar_width / 2);
                    double curr_y = height - margin - ((cumulative_score / 10.0) * chart_height);
                    
                    cr.move_to (prev_x, prev_y);
                    cr.line_to (curr_x, curr_y);
                    cr.stroke ();
                }
            }
        }
    }
}

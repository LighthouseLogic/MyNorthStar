using Gtk;
using Gee;

namespace MyTrueNorth {

    public class StepOneVBox : Gtk.Box {
        private Gtk.Entry element_entry;
        private Gtk.ListBox elements_list;
        public ArrayList<string> important_items;

        public StepOneVBox () {
            Object (orientation: Gtk.Orientation.VERTICAL, spacing: 20);
            this.set_margin_all (40);
            
            important_items = new ArrayList<string> ();

            // Header
            var title = new Gtk.Label ("What's important for a fulfilling life?");
            title.add_css_class ("title-label"); // We can style this in CSS
            this.append (title);

            // Input Area
            var input_hbox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 10);
            element_entry = new Gtk.Entry ();
            element_entry.set_placeholder_text ("e.g. Physical Health, Financial Freedom...");
            element_entry.set_hexpand (true);

            var add_button = new Gtk.Button.with_label ("Add Element");
            add_button.clicked.connect (on_add_clicked);
            element_entry.activate.connect (on_add_clicked); // Add on 'Enter' key

            input_hbox.append (element_entry);
            input_hbox.append (add_button);
            this.append (input_hbox);

            // List Display
            elements_list = new Gtk.ListBox ();
            elements_list.set_selection_mode (Gtk.SelectionMode.NONE);
            elements_list.add_css_class ("elements-list");
            
            var scroll = new Gtk.ScrolledWindow ();
            scroll.set_policy (Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
            scroll.set_vexpand (true);
            scroll.set_child (elements_list);
            
            this.append (scroll);
        }

        private void on_add_clicked () {
            var text = element_entry.get_text ().strip ();
            if (text != "") {
                important_items.add (text);
                
                // Add visual row to the list
                var row_label = new Gtk.Label (text);
                row_label.set_halign (Gtk.Align.START);
                row_label.set_margin_all (10);
                
                elements_list.append (row_label);
                element_entry.set_text (""); // Clear input
            }
        }
    }
}

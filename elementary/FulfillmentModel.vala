using Gee;

namespace MyTrueNorth {
    public class Element : Object {
        public string name { get; set; }
        public double weight { get; set; } // e.g., 0.20 for 20%
        public int score { get; set; }     // 1 to 10

        public Element (string name, double weight, int score) {
            this.name = name;
            this.weight = weight;
            this.score = score;
        }

        public double get_weighted_score () {
            return weight * score;
        }
    }

    public class Session : Object {
        public DateTime timestamp { get; set; }
        public ArrayList<Element> elements { get; set; }

        public Session () {
            this.timestamp = new DateTime.now_local ();
            this.elements = new ArrayList<Element> ();
        }

        public double get_total_fulfillment () {
            double total = 0.0;
            foreach (var el in elements) {
                total += el.get_weighted_score ();
            }
            return total;
        }

        // Prepares data for the Pareto Chart by sorting high to low
        public void sort_elements_for_pareto () {
            elements.sort ((a, b) => {
                double score_a = a.get_weighted_score ();
                double score_b = b.get_weighted_score ();
                if (score_a < score_b) return 1;
                if (score_a > score_b) return -1;
                return 0;
            });
        }
    }
}

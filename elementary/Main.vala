int main (string[] args) {
    var session = new MyTrueNorth.Session ();

    // Adding sample elements based on your requirements
    session.elements.add (new MyTrueNorth.Element ("Health", 0.40, 8));
    session.elements.add (new MyTrueNorth.Element ("Career", 0.30, 6));
    session.elements.add (new MyTrueNorth.Element ("Hobbies", 0.30, 9));

    session.sort_elements_for_pareto ();

    print ("--- MyTrueNorth Assessment (%s) ---\n", session.timestamp.format ("%Y-%m-%d"));
    
    foreach (var el in session.elements) {
        print ("%s: Weighted Score = %.2f\n", el.name, el.get_weighted_score ());
    }

    print ("------------------------------------\n");
    print ("Total Fulfillment Score: %.2f / 10.0\n", session.get_total_fulfillment ());

    return 0;
}

class ItineraryItem {
  final String day;
  final String city;
  final String locationName;
  final String type;
  final String budgetEstimate; // Changed to double

  ItineraryItem({
    required this.day,
    required this.city,
    required this.locationName,
    required this.type,
    required this.budgetEstimate,
  });

  factory ItineraryItem.fromJson(Map<String, dynamic> json) {
    return ItineraryItem(
      day: json['day'] ?? 'Unknown Day',
      city: json['city'] ?? 'Unknown City',
      locationName: json['location_name'] ?? 'Unknown Location',
      type: json['type'] ?? 'Unknown Type',
      // Handle both String and int types and convert to double
      budgetEstimate:
          json['budget_estimate'] is String
              ? double.tryParse(json['budget_estimate']) ?? 0.0
              : json['budget_estimate'] is int
              ? (json['budget_estimate'] as int).toDouble()
              : json['budget_estimate'] is double
              ? json['budget_estimate']
              : 0.0,
    );
  }
}

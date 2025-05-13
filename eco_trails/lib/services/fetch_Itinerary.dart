import 'dart:convert';
import 'package:eco_trails/models/Itinerary.dart';
import 'package:http/http.dart' as http;

class FetchItinerary {
  Future<List<ItineraryItem>> fetchItineraryData() async {
    try {
      final response = await http.post(
        Uri.parse(
          'https://0513-34-23-115-117.ngrok-free.app/generate-itinerary',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "mode": "Uttarakhand",
          "selected_city": "Rishikesh",
          "trip_duration_days": 3,
          "group_type": "family",
          "preferences": ["nature", "temples", "hiking"],
          "budget_per_day": 2000,
        }),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> data = decoded['data'];

        return data.map((item) => ItineraryItem.fromJson(item)).toList();
      } else {
        throw Exception(
          "Failed to load itinerary. Status code: ${response.statusCode}",
        );
      }
    } catch (e) {
      throw Exception("Error fetching itinerary: $e");
    }
  }
}

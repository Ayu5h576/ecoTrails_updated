import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class TripPlanPage extends StatefulWidget {
  const TripPlanPage({super.key});

  @override
  State<TripPlanPage> createState() => _TripPlanPageState();
}

class _TripPlanPageState extends State<TripPlanPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DocumentSnapshot? todayTripDoc;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchTodayTrip();
  }

  Future<void> fetchTodayTrip() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    final snapshot =
        await FirebaseFirestore.instance
            .collection('trips')
            .orderBy('createdAt', descending: true)
            .where(
              'selectedDate',
              isGreaterThanOrEqualTo: startOfDay.toIso8601String(),
            )
            .limit(1)
            .get();

    if (snapshot.docs.isNotEmpty) {
      setState(() {
        todayTripDoc = snapshot.docs.first;
      });
    } else {
      setState(() {
        todayTripDoc = null;
      });
    }
  }

  Future<void> cancelTrip() async {
    if (todayTripDoc != null) {
      await FirebaseFirestore.instance
          .collection('trips')
          .doc(todayTripDoc!.id)
          .delete();
      setState(() {
        todayTripDoc = null;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(201, 219, 213, 1),
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(201, 219, 213, 1),
        centerTitle: true,
        title: Text(
          "Trip Plan",
          style: GoogleFonts.poppins(
            color: const Color.fromRGBO(111, 119, 137, 1),
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (todayTripDoc != null)
            IconButton(
              icon: const Icon(Icons.cancel, color: Colors.red),
              onPressed: () async {
                final confirm = await showDialog(
                  context: context,
                  builder:
                      (_) => AlertDialog(
                        title: const Text("Cancel Trip?"),
                        content: const Text(
                          "Are you sure you want to cancel today's trip?",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text("No"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text("Yes"),
                          ),
                        ],
                      ),
                );
                if (confirm == true) {
                  await cancelTrip();
                }
              },
            ),
        ],
        bottom:
            todayTripDoc != null
                ? TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.red,
                  labelColor: Colors.red,
                  unselectedLabelColor: Colors.grey,
                  labelStyle: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  tabs: const [
                    Tab(text: "Planned Trip"),
                    Tab(text: "Generated Plan"),
                  ],
                )
                : null,
      ),
      body:
          todayTripDoc == null
              ? const Center(child: Text("No trips planned for today."))
              : TabBarView(
                controller: _tabController,
                children: [
                  FirebaseTripsPage(tripDoc: todayTripDoc!),
                  ApiItineraryPage(tripDoc: todayTripDoc!),
                ],
              ),
    );
  }
}

class FirebaseTripsPage extends StatelessWidget {
  final DocumentSnapshot tripDoc;
  const FirebaseTripsPage({super.key, required this.tripDoc});

  @override
  Widget build(BuildContext context) {
    final data = tripDoc.data() as Map<String, dynamic>;
    final placeId = data['placeId'];

    return SingleChildScrollView(
      child: Container(
        color: const Color.fromRGBO(201, 219, 213, 1),
        child: FutureBuilder<QuerySnapshot>(
          future:
              FirebaseFirestore.instance
                  .collection('places')
                  .where('name', isEqualTo: placeId)
                  .limit(1)
                  .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("Place data not found."));
            }

            final placeData =
                snapshot.data!.docs.first.data() as Map<String, dynamic>;
            final images = placeData['multiple images'] ?? [];
            final firstImageUrl = images.isNotEmpty ? images[0] : null;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (firstImageUrl != null)
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                        child: CachedNetworkImage(
                          imageUrl: firstImageUrl,
                          width: double.infinity,
                          height: 250,
                          fit: BoxFit.cover,
                          placeholder:
                              (context, url) => Container(
                                width: double.infinity,
                                height: 250,
                                color: Colors.grey[300],
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                          errorWidget: (context, error, stackTrace) {
                            return Container(
                              width: double.infinity,
                              height: 250,
                              color: Colors.grey[300],
                              child: const Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  size: 50,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${data['placeTitle']} (${data['selectedTripDuration']})",
                            style: const TextStyle(
                              fontSize: 22.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Transport: ${data['selectedTransport']}",
                            style: const TextStyle(fontSize: 16.0),
                          ),
                          Text(
                            "Eco Mode: ${data['ecoMode']} | Eco Home Stay: ${data['ecoHomeStay'] == 1 ? 'Yes' : 'No'}",
                            style: const TextStyle(fontSize: 16.0),
                          ),
                          const Divider(),
                          Row(
                            children: [
                              Text(
                                "Budget: ₹${data['price']}",
                                style: const TextStyle(
                                  fontSize: 18.0,
                                  color: Color.fromARGB(255, 1, 90, 92),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                "Group Type: ${data['groupType']}",
                                style: const TextStyle(fontSize: 16.0),
                              ),
                            ],
                          ),
                          const Divider(),
                          Text(
                            "Interests:",
                            style: const TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ...List.generate(
                            data['interests']?.length ?? 0,
                            (index) => Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4.0,
                              ),
                              child: Text(
                                "- ${data['interests'][index]}",
                                style: const TextStyle(fontSize: 16.0),
                              ),
                            ),
                          ),
                          const Divider(),
                          Text(
                            "Adventure Level: ${data['adventureLevel']}",
                            style: const TextStyle(fontSize: 16.0),
                          ),
                          Text(
                            "Health Notes: ${data['healthNotes'] ?? 'None'}",
                            style: const TextStyle(fontSize: 16.0),
                          ),
                          const Divider(),
                          Text(
                            "Plastic Avoidance: ${data['plasticAvoidance'] ? 'Yes' : 'No'}",
                            style: const TextStyle(fontSize: 16.0),
                          ),
                          Text(
                            "Created At: ${data['createdAt']?.toDate().toLocal().toString().substring(0, 19)}",
                            style: const TextStyle(fontSize: 16.0),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class ApiItineraryPage extends StatefulWidget {
  final DocumentSnapshot tripDoc;
  const ApiItineraryPage({super.key, required this.tripDoc});

  @override
  State<ApiItineraryPage> createState() => _ApiItineraryPageState();
}

class _ApiItineraryPageState extends State<ApiItineraryPage> {
  List? itineraryData;
  bool isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchTripAndItinerary();
  }

  Future<void> fetchTripAndItinerary() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final tripData = widget.tripDoc.data() as Map<String, dynamic>;

    try {
      // Updated API endpoint - replace this with your actual working API endpoint
      final apiUrl =
          'https://c2d8-34-34-13-142.ngrok-free.app/generate-itinerary';

      // Improved logging for debugging
      print('Sending request to: $apiUrl');
      print(
        'Request payload: ${jsonEncode({
          "mode": tripData['mode'] ?? "uttarakhand",
          "selected_city": tripData['placeTitle'] ?? "Rishikesh",
          "trip_duration_days": tripData['selectedTripDuration'] ?? 3,
          "group_type": tripData['groupType'] ?? "family",
          "preferences": tripData['interests'] ?? [], // Fixed: Changed from preferences to interests
          "budget_per_day": tripData['price'] ?? 2000,
        })}',
      );

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "mode": tripData['mode'] ?? "uttarakhand",
          "selected_city": tripData['placeTitle'] ?? "Rishikesh",
          "trip_duration_days": tripData['selectedTripDuration'] ?? 3,
          "group_type": tripData['groupType'] ?? "family",
          "preferences":
              tripData['interests'] ??
              [], // Fixed: Changed from preferences to interests
          "budget_per_day": tripData['price'] ?? 2000,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['data'] != null && decoded['data'] is List) {
          setState(() {
            itineraryData = decoded['data'];
          });
        } else {
          setState(() {
            errorMessage = "Unexpected data format: ${response.body}";
          });
        }
      } else {
        setState(() {
          errorMessage =
              "Failed to load itinerary. Status Code: ${response.statusCode}, Response: ${response.body}";
        });
      }
    } catch (e) {
      print('Exception caught: $e');
      setState(() {
        errorMessage =
            "Connection error: $e. Please check your internet connection and try again.";
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : errorMessage != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Error loading itinerary",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Text(
                        errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: fetchTripAndItinerary,
                      child: const Text("Try Again"),
                    ),
                  ],
                ),
              )
              : itineraryData == null || itineraryData!.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      color: Color.fromARGB(255, 0, 0, 0),
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "No itinerary data available",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "We couldn't generate an itinerary for your trip.",
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: fetchTripAndItinerary,
                      child: const Text("Generate Itinerary"),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                itemCount: itineraryData?.length ?? 0,
                itemBuilder: (context, index) {
                  final item = itineraryData![index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${item['day']} - ${item['city']}',
                            style: const TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8.0),
                          Text(
                            '${item['location_name']} (${item['type']})',
                            style: const TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            'Budget: ₹${item['budget_estimate']}',
                            style: const TextStyle(
                              fontSize: 14.0,
                              color: Colors.green,
                            ),
                          ),
                          Text(
                            'Crowd Level: ${item['crowd_level']}',
                            style: const TextStyle(
                              fontSize: 14.0,
                              color: Colors.blueGrey,
                            ),
                          ),
                          const Divider(),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}

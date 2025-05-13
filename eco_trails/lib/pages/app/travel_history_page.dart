import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class TravelHistoryPage extends StatefulWidget {
  const TravelHistoryPage({super.key});

  @override
  State<TravelHistoryPage> createState() => _TravelHistoryPageState();
}

class _TravelHistoryPageState extends State<TravelHistoryPage> {
  late final String currentUserId;

  @override
  void initState() {
    super.initState();
    currentUserId = FirebaseAuth.instance.currentUser!.uid;
  }

  Widget _buildTripCard(Map<String, dynamic> tripData) {
    final title = tripData['placeTitle'] ?? 'Untitled Trip';
    final Timestamp? timestamp = tripData['createdAt'];
    final String date =
        timestamp != null
            ? DateFormat('MMM dd, yyyy – kk:mm').format(timestamp.toDate())
            : 'Date not available';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFFE3F2FD), Color(0xFFFFFFFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title & Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(date, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ],
            ),
            const Divider(height: 24, thickness: 1),

            // Basic Info
            Row(
              children: [
                const Icon(Icons.group, color: Colors.teal),
                const SizedBox(width: 8),
                Text("Group: ${tripData['groupType']}"),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.directions_car, color: Colors.teal),
                const SizedBox(width: 8),
                Text("Transport: ${tripData['selectedTransport']}"),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.access_time, color: Colors.teal),
                const SizedBox(width: 8),
                Text("Duration: ${tripData['selectedTripDuration']}"),
              ],
            ),

            const Divider(height: 24, thickness: 1),

            // Preferences
            Text(
              "Preferences",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 6),
            Text("Dietary: ${tripData['dietary']}"),
            Text("Eco Mode: ${tripData['ecoMode']}"),
            Text("Eco Home Stay: ${tripData['ecoHomeStay']}"),
            Text(
              "Plastic Avoidance: ${tripData['plasticAvoidance'] ? 'Yes' : 'No'}",
            ),
            Text("Adventure Level: ${tripData['adventureLevel']}"),

            if ((tripData['healthNotes'] as String?)?.isNotEmpty ?? false) ...[
              const SizedBox(height: 8),
              Text("Health Notes: ${tripData['healthNotes']}"),
            ],

            const Divider(height: 24, thickness: 1),

            // Interests & Cost
            Text("Interests: ${tripData['interests']?.join(', ') ?? 'None'}"),
            const SizedBox(height: 8),
            Text(
              "Cost: ₹${tripData['price']}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD1E0DC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFD1E0DC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color.fromRGBO(111, 119, 137, 1),
            size: 30,
          ),
          onPressed: () => context.go('/home'),
        ),
        title: const Text(
          "Travel History",
          style: TextStyle(
            color: Color.fromRGBO(111, 119, 137, 1),
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('trips')
                .where('userId', isEqualTo: currentUserId)
                .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No travel history found.'));
          }

          final trips = snapshot.data!.docs;

          return ListView.builder(
            itemCount: trips.length,
            itemBuilder: (context, index) {
              final tripData = trips[index].data() as Map<String, dynamic>;
              return _buildTripCard(tripData);
            },
          );
        },
      ),
    );
  }
}

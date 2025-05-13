import 'package:eco_trails/models/place.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

class TravelScreen extends StatelessWidget {
  final Place place;

  const TravelScreen({super.key, required this.place});

  @override
  Widget build(BuildContext context) {
    final panelHeight = MediaQuery.of(context).size.height * 0.60;

    return Scaffold(
      backgroundColor: const Color(0xFF93B7AC),
      body: Stack(
        children: [
          // Map background
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(35),
            ),
            child: MapView(place.location),
          ),

          // Back button
          Positioned(
            top: 40,
            left: 20,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () {
                  (context).go('/home');
                },
              ),
            ),
          ),
          // Bottom Panel
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(30),
              ),
              child: Container(
                height: panelHeight,
                color: const Color.fromARGB(255, 210, 240, 235),
                child: travelContent(place, context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget travelContent(Place place, BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and location
            Text(
              place.title,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  place.title,
                  style: GoogleFonts.poppins(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Rating
            Row(
              children: [
                Text(
                  place.rating.toString(),
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                ...List.generate(
                  place.rating.floor(),
                  (index) =>
                      const Icon(Icons.star, color: Colors.orange, size: 16),
                ),
                if (place.rating % 1 != 0)
                  const Icon(Icons.star_half, color: Colors.orange, size: 16),
              ],
            ),
            const SizedBox(height: 12),

            // Tabs
            const TabBar(
              labelColor: Colors.red,
              unselectedLabelColor: Colors.black,
              indicatorColor: Colors.red,
              tabs: [
                Tab(text: 'About'),
                Tab(text: 'Reviews'),
                Tab(text: 'Photos'),
              ],
            ),
            const SizedBox(height: 8),

            // Tab content
            Expanded(
              child: TabBarView(
                children: [
                  SingleChildScrollView(
                    child: Text(
                      place.description,
                      style: GoogleFonts.poppins(fontSize: 13),
                    ),
                  ),
                  Center(
                    child: Text(
                      "“Amazing spiritual place with serene views!” - A traveler",
                      style: GoogleFonts.poppins(fontSize: 13),
                    ),
                  ),
                  GridView.builder(
                    itemCount: place.images.length,
                    // Make it scrollable
                    physics:
                        const BouncingScrollPhysics(), // or ScrollPhysics() for basic
                    shrinkWrap:
                        true, // Add this if it's inside a scrollable parent like SingleChildScrollView
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                    itemBuilder: (context, index) {
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.grey[300],
                          image: DecorationImage(
                            image: NetworkImage(place.images[index]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Start Journey Button
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    (context).go('/trip-planner', extra: place);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00432D),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.directions_walk, color: Colors.white),
                  label: Text(
                    'Start your journey',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget MapView(LatLng center) {
    return FlutterMap(
      options: MapOptions(initialCenter: center, initialZoom: 13),
      children: [
        TileLayer(
          urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
          userAgentPackageName: 'com.example.ecotrails',
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: center,
              width: 40,
              height: 40,
              child: const Icon(
                Icons.location_on,
                color: Colors.blueAccent,
                size: 36,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

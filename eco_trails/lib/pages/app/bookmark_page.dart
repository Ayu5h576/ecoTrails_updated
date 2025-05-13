import 'package:cached_network_image/cached_network_image.dart';
import 'package:eco_trails/models/place.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

class BookmarkScreen extends StatefulWidget {
  const BookmarkScreen({super.key});

  @override
  _BookmarkScreenState createState() => _BookmarkScreenState();
}

class _BookmarkScreenState extends State<BookmarkScreen> {
  bool isLoading = true;
  List<DocumentSnapshot> bookmarkedPlaces = [];

  @override
  void initState() {
    super.initState();
    fetchBookmarkedPlaces();
  }

  // Fetch bookmarked places from Firestore
  Future<void> fetchBookmarkedPlaces() async {
    try {
      // Get the current user's UID
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        // Handle case where user is not signed in
        setState(() {
          isLoading = false;
        });
        return;
      }

      // Fetch the user document from Firestore using UID
      final userDoc = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);
      final userSnapshot = await userDoc.get();

      if (!userSnapshot.exists) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      final bookmarks = List.from(userSnapshot.data()?['bookmarks'] ?? []);

      List<DocumentSnapshot> placesList = [];
      for (var bookmarkRef in bookmarks) {
        final placeDoc = await bookmarkRef.get();
        if (placeDoc.exists) {
          placesList.add(placeDoc);
        }
      }

      setState(() {
        bookmarkedPlaces = placesList;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching bookmarks: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Remove place from bookmarks
  Future<void> removeFromBookmarks(DocumentReference placeRef) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userDoc = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);
      await userDoc.update({
        'bookmarks': FieldValue.arrayRemove([placeRef]),
      });

      // Remove the place from the list immediately after updating Firestore
      setState(() {
        bookmarkedPlaces.removeWhere((place) => place.reference == placeRef);
      });
    } catch (e) {
      print('Error removing bookmark: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF27474E),
      body: Column(
        children: [
          // Header with back button, centered title, and add button
          Container(
            height: screenHeight * 0.15,
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
            color: const Color(0xFF27474E),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Centered Title
                Center(
                  child: Text(
                    'Bookmarks',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: screenWidth * 0.06,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Back Button - aligned left
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () {
                      (context).go('/home'); // Navigate back
                    },
                    icon: const Icon(Icons.arrow_back),
                    color: Colors.white,
                    iconSize: screenWidth * 0.065,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Stack(
              children: [
                // Main Content Container
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.only(
                    top: 0,
                    left: screenWidth * 0.05,
                    right: screenWidth * 0.05,
                    bottom: screenHeight * 0.12,
                  ),
                  decoration: const BoxDecoration(
                    color: Color.fromARGB(255, 184, 236, 219),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child:
                      isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ListView.builder(
                            itemCount: bookmarkedPlaces.length,
                            itemBuilder: (context, index) {
                              final place = bookmarkedPlaces[index];
                              final placeName = place['name'];
                              final placeImages =
                                  place['multiple images'] as List;
                              final placeImage =
                                  placeImages.isNotEmpty
                                      ? placeImages[0]
                                      : 'https://via.placeholder.com/150';
                              final placeRating = place['rating'] ?? 0.0;

                              return GestureDetector(
                                onTap: () {
                                  final placeObj = Place.fromFirestore(
                                    place as Map<String, dynamic>,
                                  );

                                  GoRouter.of(
                                    context,
                                  ).go('/place', extra: placeObj);
                                },
                                child: Container(
                                  margin: EdgeInsets.only(
                                    bottom: screenHeight * 0.01,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color.fromARGB(
                                      255,
                                      255,
                                      255,
                                      255,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color.fromARGB(179, 0, 0, 0),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(12),
                                          bottomLeft: Radius.circular(12),
                                        ),
                                        child: CachedNetworkImage(
                                          imageUrl: placeImage,
                                          width: screenWidth * 0.25,
                                          height: screenWidth * 0.25,
                                          fit: BoxFit.cover,
                                          placeholder:
                                              (context, url) => Container(
                                                width: screenWidth * 0.25,
                                                height: screenWidth * 0.25,
                                                color: Colors.grey.shade200,
                                                child: const Center(
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                      ),
                                                ),
                                              ),
                                          errorWidget:
                                              (context, url, error) =>
                                                  Container(
                                                    width: screenWidth * 0.25,
                                                    height: screenWidth * 0.25,
                                                    color: Colors.grey.shade300,
                                                    child: const Icon(
                                                      Icons.broken_image,
                                                      size: 40,
                                                    ),
                                                  ),
                                        ),
                                      ),
                                      SizedBox(width: screenWidth * 0.03),
                                      Expanded(
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                            vertical: screenHeight * 0.015,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // Place Name
                                              Text(
                                                placeName,
                                                style: TextStyle(
                                                  color: const Color.fromARGB(
                                                    255,
                                                    0,
                                                    0,
                                                    0,
                                                  ),
                                                  fontSize: screenWidth * 0.04,
                                                ),
                                              ),
                                              SizedBox(
                                                height: screenHeight * 0.005,
                                              ),

                                              // Place Rating (e.g., star icons or numeric rating)
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.star,
                                                    color: Colors.amber,
                                                    size: screenWidth * 0.045,
                                                  ),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    '$placeRating',
                                                    style: TextStyle(
                                                      color: Colors.black,
                                                      fontSize:
                                                          screenWidth * 0.035,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(
                                                height: screenHeight * 0.005,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.only(
                                          right: screenWidth * 0.03,
                                        ),
                                        child: IconButton(
                                          icon: const Icon(Icons.delete),
                                          color: Colors.red,
                                          onPressed: () {
                                            removeFromBookmarks(
                                              place.reference,
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

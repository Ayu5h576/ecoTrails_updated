import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eco_trails/models/place.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  List<Map<String, dynamic>> allPlaces = [];
  bool isLoading = true;
  List<DocumentReference> bookmarkedRefs = [];
  String searchQuery = '';

  Future<void> fetchBookmarkedRefs() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      if (userDoc.exists) {
        setState(() {
          bookmarkedRefs = List<DocumentReference>.from(
            userDoc.data()?['bookmarks'] ?? [],
          );
        });
      }
    }
  }

  Future<void> fetchPlaces() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('places').get();

      final data =
          snapshot.docs
              .where((doc) {
                // Check if the essential fields are not null or empty
                final place = doc.data();
                return place['name'] != null &&
                    place['name'].isNotEmpty &&
                    place['category'] != null &&
                    place['category'].isNotEmpty;
              })
              .map((doc) {
                final place = doc.data();

                return {
                  'name': place['name'] ?? '',
                  'location': place['location'] ?? '',
                  'multiple images':
                      (place['multiple images'] as List?)?.cast<String>() ?? [],
                  'rating': place['rating'] ?? 0.0,
                  'description': place['description'] ?? '',
                  'category': place['category'] ?? '',
                  'isHiddenGem': place['isHiddenGem'] ?? false,
                  'crowd': place['crowd'] ?? 0,
                  'isPopular': place['isPopular'] ?? false,
                  'reference': doc.reference, // Add reference to each place
                };
              })
              .toList();

      setState(() {
        allPlaces = data;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching places: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    fetchPlaces();
    fetchBookmarkedRefs();
  }

  List<Map<String, dynamic>> get searchedPlaces {
    if (searchQuery.isEmpty) return allPlaces;

    return allPlaces
        .where(
          (place) => place['name'].toString().toLowerCase().contains(
            searchQuery.toLowerCase(),
          ),
        )
        .toList();
  }

  Future<void> addBookmark(DocumentReference placeRef) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid);
        final userSnapshot = await userDoc.get();

        if (userSnapshot.exists) {
          final userData = userSnapshot.data();
          List<dynamic> bookmarks = List.from(userData?['bookmarks'] ?? []);

          // Avoid adding duplicate bookmarks
          if (!bookmarks.contains(placeRef)) {
            bookmarks.add(placeRef);
            await userDoc.update({'bookmarks': bookmarks});
            await userDoc.update({'bookmarks': bookmarks});
            setState(() {
              bookmarkedRefs = bookmarks.cast<DocumentReference>();
            });

            // Show success snackbar
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Place added to bookmarks!')),
            );
          } else {
            // Show a snackbar if already bookmarked
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Place already in bookmarks!')),
            );
          }
        }
      }
    } catch (e) {
      debugPrint("Error adding bookmark: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to add bookmark')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(201, 219, 213, 1),
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(201, 219, 213, 1),
        centerTitle: true,
        title: Text(
          'Search',
          style: GoogleFonts.poppins(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: const Color.fromRGBO(111, 119, 137, 1),
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Color.fromRGBO(111, 119, 137, 1),
            size: 30,
          ),
          onPressed: () => (context).go('/home', extra: {'initialTabIndex': 1}),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 4),
                ],
              ),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search places',
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  border: InputBorder.none,
                  icon: const Icon(Icons.search, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child:
                  isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : searchedPlaces.isEmpty
                      ? const Center(child: Text('No places found'))
                      : ListView.builder(
                        itemCount: searchedPlaces.length,
                        itemBuilder: (context, index) {
                          final place = searchedPlaces[index];
                          final images = place['multiple images'] as List;
                          final imageUrl =
                              images.isNotEmpty
                                  ? images[0]
                                  : 'https://via.placeholder.com/150';

                          return GestureDetector(
                            onTap: () {
                              final placeObj = Place.fromFirestore(place);
                              GoRouter.of(
                                context,
                              ).go('/place', extra: placeObj);
                            },
                            child: Card(
                              margin: const EdgeInsets.only(
                                bottom: 8,
                                right: 5,
                                left: 5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              color: const Color.fromARGB(255, 156, 174, 177),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: CachedNetworkImage(
                                      imageUrl: imageUrl,
                                      width: 150,
                                      height: 100,
                                      fit: BoxFit.cover,
                                      placeholder:
                                          (context, url) => Container(
                                            width: 150,
                                            height: 100,
                                            color: Colors.grey.shade200,
                                            child: const Center(
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            ),
                                          ),
                                      errorWidget:
                                          (context, url, error) => Container(
                                            width: 150,
                                            height: 100,
                                            color: Colors.grey.shade300,
                                            child: const Icon(
                                              Icons.broken_image,
                                              size: 40,
                                            ),
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12.0,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            place['name'],
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(
                                                CupertinoIcons.star,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                place['rating'].toString(),
                                                style: GoogleFonts.poppins(
                                                  fontSize: 12,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w200,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      bookmarkedRefs.contains(
                                            place['reference'],
                                          )
                                          ? Icons.bookmark
                                          : Icons.bookmark_border,
                                    ),
                                    color: Colors.white,
                                    onPressed: () {
                                      addBookmark(place['reference']);
                                    },
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
    );
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eco_trails/models/place.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class TripPlannerPage extends StatefulWidget {
  final Place place;
  const TripPlannerPage({super.key, required this.place});

  @override
  State<TripPlannerPage> createState() => _TripPlannerPageState();
}

class _TripPlannerPageState extends State<TripPlannerPage> {
  final PageController _controller = PageController();
  int currentPage = 0;

  bool validatePage(int page) {
    switch (page) {
      case 0:
        return selectedTripDuration.isNotEmpty &&
            (isFamily || isSolo || isFriends) &&
            price > 0;
      case 1:
        return interests.containsValue(true) && adventureLevel > 0;
      default:
        return false;
    }
  }

  void planSummary() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("User not logged in")));
        return;
      }

      final tripData = {
        'userId': user.uid,
        'placeId': widget.place.title,
        'placeTitle': widget.place.title,
        'selectedTripDuration': selectedTripDuration,
        'selectedDate': selectedDate.toIso8601String(),
        'groupType':
            isFamily
                ? 'Family'
                : isSolo
                ? 'Solo'
                : 'Friends',
        'price': price,
        'interests':
            interests.entries.where((e) => e.value).map((e) => e.key).toList(),
        'adventureLevel': adventureLevel,
        'selectedTransport': selectedTransport,
        'plasticAvoidance': plasticAvoidance,
        'ecoHomeStay': ecoHomeStay,
        'healthNotes': healthController.text,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('trips').add(tripData);

      showDialog(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: Text('Trip Planned for ${widget.place.title}'),
              content: const Text('All preferences saved. Enjoy your journey!'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    context.go('/home', extra: {'initialTabIndex': 3});
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
      );
    } catch (e) {
      print("Error saving trip: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to save trip. Try again.")),
      );
    }
  }

  // Page 1
  String selectedTripDuration = '1 Day';
  DateTime selectedDate = DateTime.now();
  bool isFamily = false;
  bool isSolo = false;
  bool isFriends = false;
  double price = 0;

  // Page 2
  Map<String, bool> interests = {
    'Adventure': false,
    'Culture & Heritage': false,
    'Spirituality': false,
    'Photography': false,
    'Hiking': false,
    'Peace': false,
  };
  double adventureLevel = 1;

  String selectedTransport = 'Car';
  bool plasticAvoidance = true;
  bool ecoHomeStay = false;
  final TextEditingController healthController = TextEditingController();

  void nextPage() {
    if (validatePage(currentPage)) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
    }
  }

  void previousPage() {
    if (currentPage > 0) {
      _controller.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 225, 251, 244),
      body: Padding(
        padding: const EdgeInsets.only(top: 25.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  onPressed:
                      currentPage > 0
                          ? previousPage
                          : () => context.go('/place', extra: widget.place),
                  icon: const Icon(Icons.arrow_back),
                ),
                Text(
                  'Planner',
                  style: GoogleFonts.poppins(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: const Color.fromRGBO(111, 119, 137, 1),
                  ),
                ),
                currentPage == 0
                    ? TextButton(
                      onPressed: nextPage,
                      child: Text(
                        'Next',
                        style: GoogleFonts.poppins(fontSize: 16),
                      ),
                    )
                    : const SizedBox(width: 60),
              ],
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => currentPage = i),
                children: [page1(), page2()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget page1() {
    return plannerCard([
      detailContainer(
        title: 'Trip Duration',
        child: dropdownTile(
          '',
          ['1 Day', '2 Day', '3 Day', '4 Day', '5 Day', '6 Day', '7 Day'],
          selectedTripDuration,
          (val) => setState(() => selectedTripDuration = val),
        ),
      ),
      detailContainer(
        title: 'Trip Date',
        child: CalendarDatePicker(
          initialDate: selectedDate,
          firstDate: DateTime.now(),
          lastDate: DateTime(2027),
          onDateChanged: (picked) => setState(() => selectedDate = picked),
        ),
      ),
      detailContainer(
        title: 'Group Type',
        child: Column(
          children:
              ['Family', 'Solo', 'Friends'].map((option) {
                return RadioListTile(
                  title: Text(option),
                  value: option,
                  groupValue:
                      isFamily
                          ? 'Family'
                          : isSolo
                          ? 'Solo'
                          : isFriends
                          ? 'Friends'
                          : '',
                  onChanged: (val) {
                    setState(() {
                      isFamily = val == 'Family';
                      isSolo = val == 'Solo';
                      isFriends = val == 'Friends';
                    });
                  },
                );
              }).toList(),
        ),
      ),
      detailContainer(
        title: 'Budget (Rs)',
        child: TextField(
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: 'Enter your budget',
            border: OutlineInputBorder(),
          ),
          onChanged: (val) {
            setState(() {
              price = double.tryParse(val) ?? 0;
            });
          },
        ),
      ),
    ]);
  }

  Widget page2() {
    return plannerCard([
      detailContainer(
        title: 'Preferences',
        child: Column(
          children:
              interests.keys.map((key) {
                return CheckboxListTile(
                  title: Text(key),
                  value: interests[key],
                  onChanged: (val) => setState(() => interests[key] = val!),
                );
              }).toList(),
        ),
      ),
      detailContainer(
        title: 'Plastic Avoidance',
        child: SwitchListTile(
          title: const Text('Plastic Avoidance'),
          value: plasticAvoidance,
          onChanged: (val) => setState(() => plasticAvoidance = val),
        ),
      ),
      detailContainer(
        title: 'Adventure Level',
        child: sliderTile(
          'Level',
          adventureLevel,
          1,
          5,
          (val) => setState(() => adventureLevel = val),
        ),
      ),
      detailContainer(
        title: 'Transport Mode',
        child: Column(
          children:
              ['Public', 'Private'].map((mode) {
                return RadioListTile(
                  title: Text(mode),
                  value: mode,
                  groupValue: selectedTransport,
                  onChanged: (val) => setState(() => selectedTransport = val!),
                );
              }).toList(),
        ),
      ),
      detailContainer(
        title: 'Homestays',
        child: SwitchListTile(
          title: const Text('Homestays Available'),
          value: ecoHomeStay,
          onChanged: (val) => setState(() => ecoHomeStay = val),
        ),
      ),
      detailContainer(
        title: 'Health Condition',
        child: textFieldTile('Health Notes', healthController),
      ),
      const SizedBox(height: 20),
      ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontSize: 24),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        ),
        onPressed: () {
          if (validatePage(1)) {
            planSummary();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please complete all fields')),
            );
          }
        },
        child: const Text('Submit'),
      ),
    ]);
  }

  Widget plannerCard(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(64, 147, 183, 172),
        borderRadius: BorderRadius.circular(30),
      ),
      child: SingleChildScrollView(child: Column(children: children)),
    );
  }

  Widget detailContainer({required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F2F1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget dropdownTile(
    String label,
    List<String> items,
    String value,
    Function(String) onChanged,
  ) {
    return DropdownButton<String>(
      isExpanded: true,
      value: value,
      items:
          items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: (v) => onChanged(v!),
    );
  }

  Widget sliderTile(
    String label,
    double value,
    double min,
    double max,
    Function(double) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("$label: ${value.toStringAsFixed(0)}"),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: (max - min).round(),
          label: value.toStringAsFixed(0),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget textFieldTile(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [Text(label), TextField(controller: controller)],
    );
  }
}

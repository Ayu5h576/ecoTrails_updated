// ignore_for_file: use_build_context_synchronously

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    final spacingUnit = screenHeight * 0.01;
    final avatarRadius = screenWidth * 0.09;
    final iconSize = screenWidth * 0.06;
    final fontSize = screenWidth * 0.038;

    return Drawer(
      backgroundColor: const Color.fromARGB(255, 160, 194, 184),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            SizedBox(height: spacingUnit * 4),
            Container(
              width: avatarRadius * 2,
              height: avatarRadius * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color.fromARGB(255, 38, 70, 83),
                  width: 4,
                ),
              ),
              child: const CircleAvatar(
                backgroundImage: AssetImage(
                  'assets/images/places/ranikhet.jpg',
                ),
              ),
            ),
            SizedBox(height: spacingUnit * 1.5),
            Text(
              user?.displayName ?? 'ecoTrails User',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: fontSize + 2,
              ),
            ),
            SizedBox(height: spacingUnit),
            if (user?.email != null)
              Text(user!.email!, style: TextStyle(fontSize: fontSize - 1)),
            if (user?.phoneNumber != null)
              Text(
                user!.phoneNumber!,
                style: TextStyle(fontSize: fontSize - 1),
              ),

            SizedBox(height: spacingUnit * 3),
            DrawerItem(
              icon: Icons.bookmark_border,
              title: 'Bookmarks',
              dense: true,
              fontSize: fontSize,
              iconSize: iconSize,
              onTap: () {
                Navigator.pop(context);
                context.go('/bookmarks');
              },
            ),

            DrawerItem(
              icon: CupertinoIcons.car_detailed,
              title: 'Trip History',
              dense: true,
              fontSize: fontSize,
              iconSize: iconSize,
              onTap: () {
                Navigator.pop(context);
                context.go('/history');
              },
            ),

            const Spacer(),
            const Divider(thickness: 1),
            DrawerItem(
              icon: Icons.logout,
              title: 'Logout',
              dense: true,
              fontSize: fontSize,
              iconSize: iconSize,
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                context.go('/signin');
              },
            ),
            SizedBox(height: spacingUnit * 2),
          ],
        ),
      ),
    );
  }
}

class DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isDisabled;
  final bool dense;
  final double? fontSize;
  final double? iconSize;
  final VoidCallback? onTap;

  const DrawerItem({
    super.key,
    required this.icon,
    required this.title,
    this.isDisabled = false,
    this.dense = false,
    this.fontSize,
    this.iconSize,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: dense,
      enabled: !isDisabled,
      leading: Icon(icon, size: iconSize),
      title: Text(
        title,
        style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w500),
      ),
      onTap: onTap,
    );
  }
}

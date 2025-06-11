import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth/admin_login_page.dart';
import 'flagged_reviews_page.dart';
import 'users_related/verified_users_page.dart';
import 'users_related/pending_users_page.dart';
import 'accommodations/verified_accommodations_page.dart';
import 'accommodations/pending_accommodations_page.dart';
import 'places_to_visit/verified_places_page.dart';
import 'places_to_visit/pending_places_page.dart';
import 'users_related/manage_users_page.dart';

class Dashboard extends StatefulWidget {
  final String location;
  final String role;

  const Dashboard({super.key, required this.location, required this.role});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int selectedIndex = 0;

  void logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const AdminLoginPage()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      VerifiedUsersPage(location: widget.location),
      PendingUsersPage(location: widget.location),
      VerifiedAccommodationsPage(location: widget.location),
      PendingAccommodationsPage(location: widget.location),
      VerifiedPlacesPage(location: widget.location),
      PendingPlacesPage(location: widget.location),
      FlaggedReviewsPage(location: widget.location),
    ];

    if (widget.role == 'admin_general') {
      pages.add(const ManageUsersPage());
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard - ${widget.location}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: logout,
          )
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            destinations: [
              const NavigationRailDestination(
                icon: Icon(Icons.verified_user),
                label: Text('Verified Users'),
              ),
              const NavigationRailDestination(
                icon: Icon(Icons.person_add),
                label: Text('Pending Users'),
              ),
              const NavigationRailDestination(
                icon: Icon(Icons.hotel_class),
                label: Text('Verified Accommodations'),
              ),
              const NavigationRailDestination(
                icon: Icon(Icons.hotel),
                label: Text('Pending Accommodations'),
              ),
              const NavigationRailDestination(
                icon: Icon(Icons.place),
                label: Text('Verified Places'),
              ),
              const NavigationRailDestination(
                icon: Icon(Icons.new_releases),
                label: Text('Pending Places'),
              ),
              const NavigationRailDestination(
                icon: Icon(Icons.rate_review),
                label: Text('Reviews'),
              ),
              if (widget.role == 'admin_general')
                const NavigationRailDestination(
                  icon: Icon(Icons.manage_accounts),
                  label: Text('Manage Users'),
                ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: pages[selectedIndex]),
        ],
      ),
    );
  }
}

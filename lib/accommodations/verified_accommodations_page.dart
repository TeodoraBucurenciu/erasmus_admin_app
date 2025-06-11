import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_accommodation_page.dart';

class VerifiedAccommodationsPage extends StatelessWidget {
  final String location;

  const VerifiedAccommodationsPage({super.key, required this.location});

  Future<void> _deleteAccommodation(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    final docId = doc.id;

    await FirebaseFirestore.instance
        .doc('$location/accommodations/deleted_accommodations/$docId')
        .set(data);

    await doc.reference.delete();
  }

  @override
  Widget build(BuildContext context) {
    final verifiedRef = FirebaseFirestore.instance
        .collection(location)
        .doc('accommodations')
        .collection('verified_accommodations');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verified Accommodations'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: verifiedRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(child: Text('No verified accommodations.'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final title = data['title'] ?? 'No title';
              final category = data['locationCategory'] ?? '';
              final price = data['price']?.toStringAsFixed(0) ?? '-';
              final rooms = data['rooms']?.toString() ?? '?';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(title),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$price€ / $rooms rooms'),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => EditAccommodationPage(doc: doc),
                          ));
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          await _deleteAccommodation(doc);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

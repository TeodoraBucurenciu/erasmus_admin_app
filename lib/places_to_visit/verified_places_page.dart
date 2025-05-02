import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_places_to_visit_page.dart';

class VerifiedPlacesPage extends StatelessWidget {
  final String location;

  const VerifiedPlacesPage({super.key, required this.location});

  Future<void> _deletePlace(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    final docId = doc.id;

    await FirebaseFirestore.instance
        .doc('$location/places_to_visit/deleted_places/$docId')
        .set(data);

    await doc.reference.delete();
  }

  @override
  Widget build(BuildContext context) {
    final placesRef = FirebaseFirestore.instance
        .collection(location)
        .doc('places_to_visit')
        .collection('verified_places_to_visit');

    return Scaffold(
      appBar: AppBar(title: const Text('Verified Places')),
      body: StreamBuilder<QuerySnapshot>(
        stream: placesRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text('No verified places.'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(data['name'] ?? 'No name'),
                  subtitle: Text(data['category'] != null
                      ? '${data['category']} • ${data['location'] ?? ''}'
                      : data['location'] ?? ''),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditPlacePage(doc: doc),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deletePlace(doc),
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

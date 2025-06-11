import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_places_to_visit_page.dart';

class PendingPlacesPage extends StatelessWidget {
  final String location;

  const PendingPlacesPage({super.key, required this.location});

  Future<void> _approve(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    final docId = doc.id;

    final updatedData = Map<String, dynamic>.from(data)..['status'] = 'verified';

    await FirebaseFirestore.instance
        .doc('$location/places_to_visit/verified_places_to_visit/$docId')
        .set(updatedData);

    await doc.reference.delete();
  }

  Future<void> _delete(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    final docId = doc.id;

    await FirebaseFirestore.instance
        .doc('$location/places_to_visit/deleted_places_to_visit/$docId')
        .set(data);

    await doc.reference.delete();
  }

  @override
  Widget build(BuildContext context) {
    final placesRef = FirebaseFirestore.instance
        .collection(location)
        .doc('places_to_visit')
        .collection('pending_places_to_visit');

    return Scaffold(
      appBar: AppBar(title: const Text('Pending Places')),
      body: StreamBuilder<QuerySnapshot>(
        stream: placesRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) return const Center(child: Text('No pending places.'));

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
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () => _approve(doc),
                      ),
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
                        onPressed: () => _delete(doc),
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

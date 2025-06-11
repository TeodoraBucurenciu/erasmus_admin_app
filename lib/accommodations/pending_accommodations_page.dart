import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_accommodation_page.dart';

class PendingAccommodationsPage extends StatelessWidget {
  final String location;

  const PendingAccommodationsPage({super.key, required this.location});

  Future<void> _approve(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    final docId = doc.id;

    final updatedData = Map<String, dynamic>.from(data)..['status'] = 'verified';

    await FirebaseFirestore.instance
        .doc('$location/accommodations/verified_accommodations/$docId')
        .set(updatedData);

    await doc.reference.delete();
  }

  Future<void> _delete(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    final docId = doc.id;

    await FirebaseFirestore.instance
        .doc('$location/accommodations/deleted_accommodations/$docId')
        .set(data);

    await doc.reference.delete();
  }

  @override
  Widget build(BuildContext context) {
    final pendingRef = FirebaseFirestore.instance
        .collection(location)
        .doc('accommodations')
        .collection('pending_accommodations');

    return Scaffold(
      appBar: AppBar(title: const Text('Pending Accommodations')),
      body: StreamBuilder<QuerySnapshot>(
        stream: pendingRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) return const Center(child: Text('No pending accommodations.'));

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
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(title),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$price€ / $rooms rooms'),
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
                              builder: (_) => EditAccommodationPage(doc: doc),
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

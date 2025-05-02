import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VerifiedUsersPage extends StatelessWidget {
  final String location;

  const VerifiedUsersPage({super.key, required this.location});

  Future<void> _deleteUser(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;

    await FirebaseFirestore.instance
        .collection('deleted_users')
        .doc(doc.id)
        .set({
      ...data,
      'deletedAt': FieldValue.serverTimestamp(),
      'deletedBy': FirebaseAuth.instance.currentUser?.uid,
    });
    await doc.reference.delete();
  }


  @override
  Widget build(BuildContext context) {
    final usersRef = FirebaseFirestore.instance
        .collection('users')
        .where('location', isEqualTo: location)
        .where('verified', isEqualTo: true)
        .where('role', isEqualTo: 'student');

    return Scaffold(
      appBar: AppBar(title: const Text('Verified Users')),
      body: StreamBuilder<QuerySnapshot>(
        stream: usersRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(child: Text('No verified users.'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final fullName = '${data['firstName'] ?? ''} ${data['secondName'] ?? ''}';
              final email = data['email'] ?? 'No email';
              final study = data['levelOfStudy'] ?? '';
              final currency = data['currency'] ?? '';
              final budget = data['budget']?.toString() ?? '-';

              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(fullName),
                  subtitle: Text('$email\n$study • $currency • Budget: $budget'),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteUser(doc),
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

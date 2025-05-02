import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PendingUsersPage extends StatelessWidget {
  final String location;

  const PendingUsersPage({super.key, required this.location});

  Future<void> _approveUser(DocumentSnapshot doc) async {
    await doc.reference.update({'verified': true});
  }

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
        .where('verified', isEqualTo: false)
        .where('role', isEqualTo: 'student');

    return Scaffold(
      appBar: AppBar(title: const Text('Pending Users')),
      body: StreamBuilder<QuerySnapshot>(
        stream: usersRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(child: Text('No pending users.'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final fullName = '${data['firstName'] ?? ''} ${data['secondName'] ?? ''}';
              final email = data['email'] ?? 'No email';
              final study = data['levelOfStudy'] ?? 'Unknown';

              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(fullName),
                  subtitle: Text('$email\nLevel: $study'),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () => _approveUser(doc),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteUser(doc),
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

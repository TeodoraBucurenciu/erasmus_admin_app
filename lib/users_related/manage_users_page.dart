import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageUsersPage extends StatefulWidget {
  const ManageUsersPage({super.key});

  @override
  State<ManageUsersPage> createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends State<ManageUsersPage> {
  final Map<String, String> selectedRoles = {};

  Future<void> _updateRole(String userId, String newRole, String? newLocation) async {
    final Map<String, dynamic> data = {'role': newRole};
    if (newRole == 'admin_sibiu' || newRole == 'admin_heraklion') {
      data['location'] = newLocation;
    } else {
      data['location'] = null;
    }
    await FirebaseFirestore.instance.collection('users').doc(userId).update(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Users')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final users = snapshot.data!.docs;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final uid = user.id;
              final email = user['email'] ?? '';
              final role = user['role'] ?? 'user';

              final selectedRole = selectedRoles[uid] ?? role;

              return ListTile(
                title: Text(email),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButton<String>(
                      value: ['user', 'admin_sibiu', 'admin_heraklion', 'admin_general']
                          .contains(selectedRole)
                          ? selectedRole
                          : 'user',
                      items: const [
                        DropdownMenuItem(value: 'user', child: Text('User')),
                        DropdownMenuItem(value: 'admin_sibiu', child: Text('Admin Sibiu')),
                        DropdownMenuItem(value: 'admin_heraklion', child: Text('Admin Heraklion')),
                        DropdownMenuItem(value: 'admin_general', child: Text('Admin General')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedRoles[uid] = value;
                          });
                        }
                      },
                    ),
                    if (selectedRole.startsWith('admin_') && selectedRole != 'admin_general')
                      Text('Locație: ${selectedRole.split('_').last}')
                  ],
                ),
                trailing: ElevatedButton(
                  child: const Text('Update'),
                  onPressed: () async {
                    await _updateRole(
                      uid,
                      selectedRole,
                      selectedRole == 'admin_sibiu'
                          ? 'Sibiu'
                          : selectedRole == 'admin_heraklion'
                          ? 'Heraklion'
                          : null,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Role updated')),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

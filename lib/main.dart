import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'auth/choose_location_page.dart';
import 'dashboard.dart';
import 'firebase_options.dart';
import 'auth/admin_login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const ErasmusAdminApp());
}

class ErasmusAdminApp extends StatelessWidget {
  const ErasmusAdminApp({super.key});

  Future<Widget> _resolveRedirect(User user) async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final role = userDoc.get('role');

    if (role == 'admin_sibiu') {
      return const Dashboard(location: 'Sibiu', role: 'admin_sibiu');
    } else if (role == 'admin_heraklion') {
      return const Dashboard(location: 'Heraklion', role: 'admin_heraklion');
    } else if (role == 'admin_general') {
      return const ChooseLocationPage(role: 'admin_general');
    }

    await FirebaseAuth.instance.signOut();
    return const AdminLoginPage(); // fallback return
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Erasmus Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          if (!snapshot.hasData) {
            return const AdminLoginPage();
          }

          return FutureBuilder<Widget>(
            future: _resolveRedirect(snapshot.data!),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
              return snap.data!;
            },
          );
        },
      ),
      routes: {
        '/login': (context) => const AdminLoginPage(),
        '/dashboard': (context) => const Dashboard(location: '', role: ''),
        '/choose_location': (context) => const ChooseLocationPage(role: ''),
      },
    );
  }
}

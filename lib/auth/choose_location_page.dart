import 'package:flutter/material.dart';
import '../dashboard.dart';

class ChooseLocationPage extends StatelessWidget {
  final String role;

  const ChooseLocationPage({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Location'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Dashboard(location: 'Heraklion', role: role),
                  ),
                );
              },
              child: const Text('Heraklion'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Dashboard(location: 'Sibiu', role: role),
                  ),
                );
              },
              child: const Text('Sibiu'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditAccommodationPage extends StatefulWidget {
  final DocumentSnapshot doc;

  const EditAccommodationPage({super.key, required this.doc});

  @override
  State<EditAccommodationPage> createState() => _EditAccommodationPageState();
}

class _EditAccommodationPageState extends State<EditAccommodationPage> {
  late TextEditingController _titleController;
  late TextEditingController _priceController;
  late TextEditingController _roomsController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationCategoryController;
  late TextEditingController _mapLinkController;


  @override
  void initState() {
    super.initState();
    final data = widget.doc.data() as Map<String, dynamic>;
    _titleController = TextEditingController(text: data['title']);
    _priceController = TextEditingController(text: '${data['price']}');
    _roomsController = TextEditingController(text: '${data['rooms']}');
    _descriptionController = TextEditingController(text: data['description']);
    _mapLinkController = TextEditingController(text: data['mapLink'] ?? '');
    _locationCategoryController = TextEditingController(text: data['locationCategory']);
  }

  Future<void> _saveChanges() async {
    try {
      await widget.doc.reference.update({
        'title': _titleController.text.trim(),
        'price': double.tryParse(_priceController.text.trim()) ?? 0,
        'rooms': int.tryParse(_roomsController.text.trim()) ?? 1,
        'description': _descriptionController.text.trim(),
        'mapLink': _mapLinkController.text.trim(),
        'locationCategory': _locationCategoryController.text.trim(),
        'lastEditedAt': FieldValue.serverTimestamp(),
      });

      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _roomsController.dispose();
    _descriptionController.dispose();
    _mapLinkController.dispose();
    _locationCategoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Accommodation')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: 'Price (€)'),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _roomsController,
              decoration: const InputDecoration(labelText: 'Rooms'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _mapLinkController,
              decoration: const InputDecoration(labelText: 'Google Maps Link'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _locationCategoryController,
              decoration: const InputDecoration(labelText: 'Location Category'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveChanges,
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}

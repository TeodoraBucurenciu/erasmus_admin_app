import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditPlacePage extends StatefulWidget {
  final DocumentSnapshot doc;

  const EditPlacePage({super.key, required this.doc});

  @override
  State<EditPlacePage> createState() => _EditPlacePageState();
}

class _EditPlacePageState extends State<EditPlacePage> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _mapLinkController;

  late String _selectedCategory;
  final List<String> _categories = [
    "Beaches",
    "Hiking Trails",
    "Historical Sites",
    "Museums",
    "Viewpoints",
    "Cultural Spots",
    "Local Markets",
    "Restaurants",
    "Cafes",
    "Nightlife",
    "Nature Parks",
    "Religious Sites",
    "Outdoor Activities",
    "Outside Crete",
  ];

  @override
  void initState() {
    super.initState();
    final data = widget.doc.data() as Map<String, dynamic>;
    _nameController = TextEditingController(text: data['name']);
    _selectedCategory = _categories.contains(data['category']) ? data['category'] : _categories.first;
    _descriptionController = TextEditingController(text: data['description']);
    _mapLinkController = TextEditingController(text: data['mapLink'] ?? '');
  }

  Future<void> _saveChanges() async {
    try {
      await widget.doc.reference.update({
        'name': _nameController.text.trim(),
        'category': _selectedCategory,
        'description': _descriptionController.text.trim(),
        'mapLink': _mapLinkController.text.trim(),
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
    _nameController.dispose();
    _descriptionController.dispose();
    _mapLinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Place to Visit')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(labelText: 'Category'),
              items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
              onChanged: (val) => setState(() => _selectedCategory = val!),
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

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FlaggedReviewsPage extends StatefulWidget {
  final String location;

  const FlaggedReviewsPage({super.key, required this.location});

  @override
  State<FlaggedReviewsPage> createState() => _FlaggedReviewsPageState();
}

class _FlaggedReviewsPageState extends State<FlaggedReviewsPage> {
  String selectedType = 'place_flagged'; // default

  Future<void> _approveReview(String id) async {
    await FirebaseFirestore.instance.collection('reviews').doc(id).update({
      'status': 'approved',
      'autoFlagged': false,
    });
  }

  Future<void> _deleteReview(String id) async {
    await FirebaseFirestore.instance.collection('reviews').doc(id).delete();
  }

  Stream<QuerySnapshot> _buildReviewStream() {
    final base = FirebaseFirestore.instance
        .collection('reviews')
        .where('location', isEqualTo: widget.location);

    if (selectedType == 'place_flagged') {
      return base
          .where('type', isEqualTo: 'place')
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .snapshots();
    } else if (selectedType == 'accommodation_flagged') {
      return base
          .where('type', isEqualTo: 'accommodation')
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .snapshots();
    } else if (selectedType == 'place_all') {
      return base
          .where('type', isEqualTo: 'place')
          .orderBy('createdAt', descending: true)
          .snapshots();
    } else {
      return base
          .where('type', isEqualTo: 'accommodation')
          .orderBy('createdAt', descending: true)
          .snapshots();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flagged Reviews')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              value: selectedType,
              items: const [
                DropdownMenuItem(value: 'place_flagged', child: Text('Flagged - Places')),
                DropdownMenuItem(value: 'accommodation_flagged', child: Text('Flagged - Accommodations')),
                DropdownMenuItem(value: 'place_all', child: Text('All - Places')),
                DropdownMenuItem(value: 'accommodation_all', child: Text('All - Accommodations')),
              ],
              onChanged: (value) {
                setState(() => selectedType = value ?? 'place_flagged');
              },
              decoration: const InputDecoration(labelText: 'Review Scope'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _buildReviewStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No reviews found.'));
                  }

                  final reviews = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: reviews.length,
                    itemBuilder: (context, index) {
                      final review = reviews[index].data() as Map<String, dynamic>;
                      final docId = reviews[index].id;
                      final name = review['userName'] ?? 'User';
                      final comment = review['comment'] ?? '';
                      final rating = review['rating'] ?? 0;
                      final status = review['status'] ?? 'pending';

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          title: Text(name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(comment),
                              const SizedBox(height: 4),
                              Row(
                                children: List.generate(5, (i) {
                                  return Icon(
                                    i < rating ? Icons.star : Icons.star_border,
                                    color: Colors.amber,
                                    size: 20,
                                  );
                                }),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (status == 'pending')
                                IconButton(
                                  icon: const Icon(Icons.check, color: Colors.green),
                                  onPressed: () => _approveReview(docId),
                                ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteReview(docId),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

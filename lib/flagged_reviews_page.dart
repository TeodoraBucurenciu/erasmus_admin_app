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

  int classifySentiment(String comment) {
    final negativeWords = {
      "not", "disappointing", "dirty", "bad", "waste", "noisy", "boring", "terrible", "worst",
      "underwhelming", "unfriendly", "poor", "dull", "messy", "overrated", "unsafe", "annoying",
      "sketchy", "lame", "creepy", "regret", "trash", "broken", "smell", "loud", "far", "off",
      "bother", "crowded", "maintenance", "awkward", "unpleasant"
    };

    final positiveWords = {
      "amazing", "great", "peaceful", "loved", "beautiful", "perfect", "relaxing", "wonderful",
      "excellent", "welcoming", "impressive", "enjoyed", "calm", "nice", "charming", "fantastic", "brilliant",
      "chill", "awesome", "cozy", "lovely", "gem", "clean", "safe", "sunset", "friendly", "worth", "exceeded",
      "picturesque", "vibe", "energy", "hangout", "scenic"
    };

    final words = comment
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .split(RegExp(r'\s+'));

    int score = 0;

    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      final isNegated = i > 0 && (words[i - 1] == 'not' || words[i - 1] == 'never');

      if (positiveWords.contains(word)) {
        score += isNegated ? -1 : 1;
      } else if (negativeWords.contains(word)) {
        score += isNegated ? 1 : -1;
      }
    }

    return score;
  }

  Future<void> _updateSentimentForPlace(String placeId) async {
    final firestore = FirebaseFirestore.instance;

    final reviewsSnapshot = await firestore
        .collection('reviews')
        .where('placeId', isEqualTo: placeId)
        .where('location', isEqualTo: widget.location)
        .where('type', isEqualTo: 'place')
        .where('status', isEqualTo: 'approved')
        .get();

    if (reviewsSnapshot.docs.isEmpty) return;

    final sentimentScores = <int>[];
    final ratingScores = <int>[];

    for (final doc in reviewsSnapshot.docs) {
      final data = doc.data();
      final comment = data['comment'] ?? '';
      final rating = data['rating'];

      sentimentScores.add(classifySentiment(comment));

      if (rating is int) {
        ratingScores.add(rating);
      }
    }

    final sentimentAvg = sentimentScores.reduce((a, b) => a + b) / sentimentScores.length;

    String color;
    if (sentimentAvg > 0.4) {
      color = 'green';
    } else if (sentimentAvg >= -0.4) {
      color = 'yellow';
    } else {
      color = 'red';
    }

    final docRef = firestore
        .collection(widget.location)
        .doc('places_to_visit')
        .collection('verified_places_to_visit')
        .doc(placeId);

    final updateData = {
      'sentimentScore': sentimentAvg,
      'sentimentClass': color == 'green'
          ? 'positive'
          : color == 'yellow'
          ? 'neutral'
          : 'negative',
      'sentimentColor': color,
    };

    if (ratingScores.isNotEmpty) {
      final ratingAvg = ratingScores.reduce((a, b) => a + b) / ratingScores.length;
      updateData['rating'] = ratingAvg;
    }

    try {
      await docRef.update(updateData);
    } catch (_) {
    }
  }

  Future<void> analyzeAndUpdateSentiments({
    required String location,
    required String collectionPath,
  }) async {
    final firestore = FirebaseFirestore.instance;

    final reviewSnapshot = await firestore
        .collection('reviews')
        .where('location', isEqualTo: location)
        .where('type', isEqualTo: 'place')
        .where('status', isEqualTo: 'approved')
        .get();

    Map<String, List<int>> scoresByPlace = {};

    for (final doc in reviewSnapshot.docs) {
      final data = doc.data();
      final placeId = data['placeId'];
      final comment = data['comment'];

      if (placeId == null || comment == null) continue;

      final sentimentScore = classifySentiment(comment);
      scoresByPlace.putIfAbsent(placeId, () => []).add(sentimentScore);
    }

    for (final entry in scoresByPlace.entries) {
      final placeId = entry.key;
      final scores = entry.value;
      if (scores.isEmpty) continue;

      final avg = scores.reduce((a, b) => a + b) / scores.length;

      String color;
      if (avg > 0.4) {
        color = 'green';
      } else if (avg >= -0.4) {
        color = 'yellow';
      } else {
        color = 'red';
      }

      final docRef = firestore
          .collection(location)
          .doc('places_to_visit')
          .collection(collectionPath)
          .doc(placeId);

      try {
        await docRef.update({
          'sentimentColor': color,
          'sentimentScore': avg,
          'sentimentClass': color == 'green'
              ? 'positive'
              : color == 'yellow'
              ? 'neutral'
              : 'negative',
        });
      } catch (_) {
        // document inexistent – ignorat
        continue;
      }
    }
  }

  Future<void> updateAverageRatings({
    required String location,
    required String collectionPath,
  }) async {
    final firestore = FirebaseFirestore.instance;

    final reviewsSnapshot = await firestore
        .collection('reviews')
        .where('location', isEqualTo: location)
        .where('type', isEqualTo: 'place')
        .where('status', isEqualTo: 'approved')
        .get();

    Map<String, List<int>> ratingMap = {};

    for (final doc in reviewsSnapshot.docs) {
      final data = doc.data();
      final placeId = data['placeId'];
      final rating = data['rating'];

      if (placeId == null || rating == null || rating is! int) continue;

      ratingMap.putIfAbsent(placeId, () => []).add(rating);
    }

    for (final entry in ratingMap.entries) {
      final placeId = entry.key;
      final ratings = entry.value;
      if (ratings.isEmpty) continue;

      final avgRating = ratings.reduce((a, b) => a + b) / ratings.length;

      final docRef = firestore
          .collection(location)
          .doc('places_to_visit')
          .collection(collectionPath)
          .doc(placeId);

      try {
        await docRef.update({"rating": avgRating});
      } catch (_) {
        continue;
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reviews'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Update Sentiment All',
              onPressed: () async {
                await updateAverageRatings(
                  location: widget.location,
                  collectionPath: 'verified_places_to_visit',
                );

                await analyzeAndUpdateSentiments(
                  location: widget.location,
                  collectionPath: 'verified_places_to_visit',
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Rating and sentiment updated for all places')),
                );
              },
          ),
        ],
      ),
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
                              IconButton(
                                icon: const Icon(Icons.refresh, color: Colors.blue),
                                onPressed: () async {
                                  final placeId = review['placeId'];
                                  if (placeId != null) {
                                    await _updateSentimentForPlace(placeId);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Rating and sentiment updated')),
                                    );
                                  }
                                },
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

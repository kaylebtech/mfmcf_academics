// devotional_list_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DevotionalListScreen extends StatelessWidget {
  const DevotionalListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFF8F0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF333333)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Daily Devotion',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            fontFamily: 'Poppins',
            color: Color(0xFF333333),
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Devotional')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: Color(0xFFE75480)),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.book_outlined,
                      size: 64,
                      color: Color(0xFFE75480).withOpacity(0.5),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No devotionals yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF666666),
                        fontFamily: 'Poppins',
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Check back later for daily inspiration.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF999999),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final devotionals = snapshot.data!.docs;

          return ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            itemCount: devotionals.length,
            itemBuilder: (context, index) {
              final doc = devotionals[index];
              final data = doc.data() as Map<String, dynamic>;

              final topic = data['topic'] ?? 'Untitled';
              final text = data['text'] ?? '';
              final creatorName = data['creatorName'] ?? 'Anonymous';
              final createdAt = data['createdAt'];

              String formattedDate = 'Unknown Date';
              if (createdAt is Timestamp) {
                formattedDate = DateFormat('MMM d, yyyy').format(createdAt.toDate());
              }

              return Card(
                margin: EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
                shadowColor: Colors.black.withOpacity(0.05),
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Topic
                      Text(
                        topic,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins',
                          color: Color(0xFF333333),
                        ),
                      ),
                      SizedBox(height: 8),

                      // Creator & Date
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: 'By $creatorName'),
                            TextSpan(text: ' • $formattedDate'),
                          ],
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF999999),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),

                      // Devotional Text
                      Text(
                        text,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.6,
                          color: Color(0xFF333333),
                        ),
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
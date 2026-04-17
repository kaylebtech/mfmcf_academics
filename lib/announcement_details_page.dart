// announcement_detail_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AnnouncementDetailPage extends StatelessWidget {
  final Map<String, dynamic> announcement;

  const AnnouncementDetailPage({super.key, required this.announcement});

  @override
  Widget build(BuildContext context) {
    final timestamp = announcement['createdAt'];
    String formattedDate = 'Unknown date';
    if (timestamp is Timestamp) {
      formattedDate = DateFormat('EEEE, MMMM d, yyyy • h:mm a').format(timestamp.toDate());
    } else if (timestamp is String) {
      try {
        final dateTime = DateTime.parse(timestamp);
        formattedDate = DateFormat('EEEE, MMMM d, yyyy • h:mm a').format(dateTime);
      } catch (e) {
        formattedDate = 'Invalid date';
      }
    }

    return Scaffold(
      backgroundColor: Color(0xFFFFF8F0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Announcement',
          style: TextStyle(
            color: Color(0xFF333333),
            fontSize: 20,
            fontWeight: FontWeight.w700,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF333333)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                announcement['title'] ?? 'No Title',
                style: TextStyle(
                  color: Color(0xFF333333),
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Poppins',
                ),
              ),
              SizedBox(height: 8),
              Text(
                formattedDate,
                style: TextStyle(
                  color: Color(0xFF999999),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  announcement['message'] ?? 'No message available.',
                  style: TextStyle(
                    color: Color(0xFF333333),
                    fontSize: 15,
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
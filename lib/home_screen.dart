import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:mfmcf_academics/ai_screen.dart';
import 'package:mfmcf_academics/announcement_details_page.dart';
import 'package:mfmcf_academics/announcement_screen.dart';
import 'package:mfmcf_academics/devotional_screen.dart';
import 'package:mfmcf_academics/profile_screen.dart';
import 'package:mfmcf_academics/programs_screen.dart';
import 'package:mfmcf_academics/tutorial_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _currentUser;
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _verseOfTheDay;
  List<Map<String, dynamic>> _announcements = [];
  List<Map<String, dynamic>> _upcomingPrograms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Future.wait([
        _loadUserData(),
        _loadVerseOfTheDay(),
        _loadAnnouncements(),
        _loadUpcomingPrograms(),
      ]);
    } catch (e) {
      print('Error loading all data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserData() async {
    try {
      _currentUser = _auth.currentUser;
      if (_currentUser != null) {
        final userDoc = await _firestore
            .collection('users')
            .doc(_currentUser!.uid)
            .get();
        if (userDoc.exists) {
          setState(() {
            _userData = userDoc.data() as Map<String, dynamic>;
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _loadVerseOfTheDay() async {
    try {
      // Get today's date range for filtering
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(Duration(days: 1));
      
      print('Fetching verse of the day - looking for verses created between $startOfDay and $endOfDay');

      // Try to get the verse created today
      final verseQuery = await _firestore
          .collection('VerseForTheDay')
          .where('createdAt', isGreaterThanOrEqualTo: startOfDay)
          .where('createdAt', isLessThan: endOfDay)
          .limit(1)
          .get();

      if (verseQuery.docs.isNotEmpty) {
        final verseDoc = verseQuery.docs.first;
        print('Found verse created today: ${verseDoc.id}');
        setState(() {
          _verseOfTheDay = verseDoc.data();
          _verseOfTheDay?['id'] = verseDoc.id;
        });
      } else {
        // If no verse created today, get the most recent one
        print('No verse found created today, fetching most recent...');
        final verseQuery = await _firestore
            .collection('VerseForTheDay')
            .orderBy('createdAt', descending: true)
            .limit(1)
            .get();

        if (verseQuery.docs.isNotEmpty) {
          final verseDoc = verseQuery.docs.first;
          print('Found most recent verse: ${verseDoc.id}');
          setState(() {
            _verseOfTheDay = verseDoc.data();
            _verseOfTheDay?['id'] = verseDoc.id;
          });
        } else {
          print('No verses found in collection');
          setState(() {
            _verseOfTheDay = null;
          });
        }
      }
    } catch (e) {
      print('Error loading verse of the day: $e');
      setState(() {
        _verseOfTheDay = null;
      });
    }
  }

  Future<void> _loadAnnouncements() async {
    try {
      final snapshot = await _firestore
          .collection('announcements')
          .where('isPublished', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      setState(() {
        _announcements = snapshot.docs.map((doc) => doc.data()).toList();
      });
    } catch (e) {
      print('Error loading announcements: $e');
    }
  }

  Future<void> _loadUpcomingPrograms() async {
    try {
      final now = DateTime.now();
      final snapshot = await _firestore
          .collection('programs')
          .where('isPublished', isEqualTo: true)
          .where(
            'date',
            isGreaterThanOrEqualTo: DateFormat('yyyy-MM-dd').format(now),
          )
          .orderBy('date')
          .limit(3)
          .get();

      setState(() {
        _upcomingPrograms = snapshot.docs.map((doc) => doc.data()).toList();
      });
    } catch (e) {
      print('Error loading programs: $e');
    }
  }

  Future<void> _refreshData() async {
    try {
      await _loadAllData();
    } catch (e) {
      print('Error refreshing data: $e');
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  void _showComingSoonToast() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Coming soon! Please wait for version 1.1.0',
          style: TextStyle(fontSize: 14),
        ),
        backgroundColor: Color(0xFFE75480),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0), // Cream background from signup page
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFE75480), // Pink color from signup
                  strokeWidth: 2,
                ),
              )
            : RefreshIndicator(
                onRefresh: _refreshData,
                color: Color(0xFFE75480),
                backgroundColor: Color(0xFFFFF8F0),
                child: CustomScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // Custom Header with greeting and icons - FIXED OVERFLOW
                    SliverToBoxAdapter(
                      child: Container(
                        color: const Color(0xFFFFF8F0), // Cream background
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top row with greeting and icons - REORDERED
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                // Profile Icon FIRST
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 8,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.person,
                                      color: Color(0xFF666666),
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ProfilePage(),
                                        ),
                                      );
                                    },
                                    padding: EdgeInsets.zero,
                                  ),
                                ),
                                SizedBox(width: 4),

                                // FAQ Icon SECOND (commented out as per original)
                                // Container(
                                //   width: 40,
                                //   height: 40,
                                //   decoration: BoxDecoration(
                                //     shape: BoxShape.circle,
                                //     border: Border.all(
                                //       color: const Color(
                                //         0xFFE75480,
                                //       ).withOpacity(0.2),
                                //       width: 1,
                                //     ),
                                //     boxShadow: [
                                //       BoxShadow(
                                //         color: Colors.black.withOpacity(0.05),
                                //         blurRadius: 8,
                                //         offset: Offset(0, 2),
                                //       ),
                                //     ],
                                //   ),
                                //   child: IconButton(
                                //     icon: Icon(
                                //       Icons.help_outline,
                                //       color: Color(0xFFE75480), // Pink color
                                //       size: 20,
                                //     ),
                                //     onPressed: () {
                                //       // Handle FAQ tap
                                //     },
                                //     padding: EdgeInsets.zero,
                                //   ),
                                // ),
                                SizedBox(width: 12),

                                // Personalized greeting section THIRD
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _getGreeting(),
                                        style: TextStyle(
                                          color: Color(0xFF666666),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        _userData?['username'] ?? 'Welcome',
                                        style: TextStyle(
                                          color: Color(0xFF333333),
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                          fontFamily: 'Poppins',
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            // Date display
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                DateFormat(
                                  'EEEE, MMMM d, yyyy',
                                ).format(DateTime.now()),
                                style: TextStyle(
                                  color: Color(0xFF999999),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Main Content
                    SliverPadding(
                      padding: EdgeInsets.all(20),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          // Verse of the Day Section
                          _buildVerseOfTheDay(),
                          SizedBox(height: 24),

                          // Featured Content Section
                          _buildFeaturedContent(),
                          SizedBox(height: 24),

                          // Quick Actions Section
                          _buildQuickActions(),
                          SizedBox(height: 24),

                          // Announcements Section
                          if (_announcements.isNotEmpty) ...[
                            _buildAnnouncements(),
                            SizedBox(height: 24),
                          ],

                          // Upcoming Programs Section
                          if (_upcomingPrograms.isNotEmpty) ...[
                            _buildUpcomingPrograms(),
                            SizedBox(height: 24),
                          ],
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildVerseOfTheDay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE75480), Color(0xFFF8C8DC)], // Pink gradient
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFE75480).withOpacity(0.2),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.book_outlined,
                color: Colors.white.withOpacity(0.9),
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'VERSE OF THE DAY',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          if (_verseOfTheDay != null && _verseOfTheDay!['text'] != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '"${_verseOfTheDay!['text']}"',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins',
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  '— ${_verseOfTheDay!['reference'] ?? ''}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '"For God so loved the world that he gave his one and only Son, that whoever believes in him shall not perish but have eternal life."',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins',
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  '— John 3:16',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          SizedBox(height: 6),
          Text(
            _verseOfTheDay?['translation'] ?? 'World English Bible',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          if (_verseOfTheDay != null && _verseOfTheDay!['createdAt'] != null)
            Text(
              'Date: ${DateFormat('MMMM d, yyyy').format(_verseOfTheDay!['createdAt'].toDate())}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 10,
                fontWeight: FontWeight.w400,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFeaturedContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Featured Content',
          style: TextStyle(
            color: Color(0xFF333333),
            fontSize: 20,
            fontWeight: FontWeight.w700,
            fontFamily: 'Poppins',
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Explore our curated resources',
          style: TextStyle(
            color: Color(0xFF666666),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.9,
          children: [
            _buildFeaturedButton('Tutorials', 'assets/tutorial.png', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => TutorialScreen()),
              );
            }),
            _buildFeaturedButton('Devotional', 'assets/devotion.png', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => DevotionalListScreen()),
              );
            }),
            _buildFeaturedButton('Programs', 'assets/programs.png', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProgramsScreen()),
              );
            }),
            _buildFeaturedButton('Community', 'assets/community.png', () {
              _showComingSoonToast();
            }),
            _buildFeaturedButton('AI Assistant', 'assets/ai.png', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AIPage()),
              );
            }),
            _buildFeaturedButton('Connect', 'assets/connect.png', () {
              _showComingSoonToast();
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildFeaturedButton(
    String title,
    String iconPath,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
          border: Border.all(color: Color(0xFFF0F0F0), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFF8F7FF),
              ),
              child: Center(
                child: Image.asset(iconPath, width: 28, height: 28),
              ),
            ),
            SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                color: Color(0xFF333333),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            color: Color(0xFF333333),
            fontSize: 20,
            fontWeight: FontWeight.w700,
            fontFamily: 'Poppins',
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Instant access to key features',
          style: TextStyle(
            color: Color(0xFF666666),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionButton(
                'Study Now',
                'assets/study.png',
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => TutorialScreen()),
                  );
                },
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionButton('Pray', 'assets/pray.png', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => DevotionalListScreen()),
                );
              }),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionButton(
                'Connect',
                'assets/connect.png',
                () {
                  _showComingSoonToast();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionButton(
    String title,
    String iconPath,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
          border: Border.all(color: Color(0xFFF0F0F0), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(iconPath, width: 36, height: 36),
            SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                color: Color(0xFF333333),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncements() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Announcements',
              style: TextStyle(
                color: Color(0xFF333333),
                fontSize: 20,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins',
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AnnouncementsPage()),
                );
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'View All',
                style: TextStyle(
                  color: Color(0xFFE75480), // Pink color
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 6),
        Text(
          'Latest updates and notices',
          style: TextStyle(
            color: Color(0xFF666666),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 16),
        ..._announcements.map(
          (announcement) => _buildAnnouncementCard(announcement),
        ),
      ],
    );
  }

  Widget _buildAnnouncementCard(Map<String, dynamic> announcement) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
        border: Border.all(color: Color(0xFFF0F0F0), width: 1),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(14),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Color(0xFFE75480).withOpacity(0.1), // Pink tint
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.announcement_outlined,
            color: Color(0xFFE75480), // Pink color
            size: 22,
          ),
        ),
        title: Text(
          announcement['title'] ?? '',
          style: TextStyle(
            color: Color(0xFF333333),
            fontSize: 15,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
        subtitle: Text(
          announcement['message'] ?? '',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Color(0xFF666666), fontSize: 13),
        ),
        trailing: Icon(Icons.chevron_right, color: Color(0xFF666666), size: 20),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  AnnouncementDetailPage(announcement: announcement),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUpcomingPrograms() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Upcoming Programs',
              style: TextStyle(
                color: Color(0xFF333333),
                fontSize: 20,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins',
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ProgramsScreen()),
                );
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'View All',
                style: TextStyle(
                  color: Color(0xFFE75480), // Pink color
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 6),
        Text(
          'Join our upcoming events',
          style: TextStyle(
            color: Color(0xFF666666),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 16),
        ..._upcomingPrograms.map((program) => _buildProgramCard(program)),
      ],
    );
  }

  Widget _buildProgramCard(Map<String, dynamic> program) {
    final date = program['date'] != null
        ? DateFormat('MMM d, yyyy').format(DateTime.parse(program['date']))
        : 'TBD';

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
        border: Border.all(color: Color(0xFFF0F0F0), width: 1),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(14),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Color(0xFFE75480).withOpacity(0.1), // Pink tint
          ),
          child: Icon(Icons.event_outlined, color: Color(0xFFE75480), size: 22),
        ),
        title: Text(
          program['title'] ?? '',
          style: TextStyle(
            color: Color(0xFF333333),
            fontSize: 15,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text(
              '$date • ${program['startTime'] ?? ''}',
              style: TextStyle(color: Color(0xFF666666), fontSize: 13),
            ),
            SizedBox(height: 4),
            Text(
              program['location'] ?? '',
              style: TextStyle(
                color: Color(0xFFE75480), // Pink color
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: Icon(Icons.chevron_right, color: Color(0xFF666666), size: 20),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ProgramsScreen()),
          );
        },
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: Offset(0, -3),
          ),
        ],
        border: Border(top: BorderSide(color: Color(0xFFF0F0F0), width: 1)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavItem(Icons.home_rounded, 'Home', true, () {}),
              _buildNavItem(Icons.smart_toy_outlined, 'AI', false, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AIPage()),
                );
              }),
              _buildNavItem(Icons.person_outline_rounded, 'Profile', false, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ProfilePage()),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    bool isActive,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? Color(0xFFE75480).withOpacity(0.1) // Pink tint
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive
                  ? Color(0xFFE75480)
                  : Color(0xFF999999), // Pink when active
              size: 22,
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isActive
                    ? Color(0xFFE75480)
                    : Color(0xFF999999), // Pink when active
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Updated Community and Connect pages with version 1.1.0 message
class CommunityPage extends StatelessWidget {
  const CommunityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Community',
          style: TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF333333)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction, size: 64, color: Color(0xFFE75480)),
            SizedBox(height: 20),
            Text(
              'Coming Soon!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xFF333333),
                fontFamily: 'Poppins',
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Community features will be available\nin version 1.1.0',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Color(0xFF666666)),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFE75480),
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Go Back',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ConnectPage extends StatelessWidget {
  const ConnectPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Connect',
          style: TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF333333)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction, size: 64, color: Color(0xFFE75480)),
            SizedBox(height: 20),
            Text(
              'Coming Soon!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xFF333333),
                fontFamily: 'Poppins',
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Connect features will be available\nin version 1.1.0',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Color(0xFF666666)),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFE75480),
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Go Back',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
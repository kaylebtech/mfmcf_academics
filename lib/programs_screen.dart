import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProgramsScreen extends StatefulWidget {
  const ProgramsScreen({super.key});

  @override
  State<ProgramsScreen> createState() => _ProgramsScreenState();
}

class _ProgramsScreenState extends State<ProgramsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _currentUser;
  bool _isLoading = true;

  List<Map<String, dynamic>> _upcomingPrograms = [];
  List<Map<String, dynamic>> _pastPrograms = [];
  List<Map<String, dynamic>> _filteredPrograms = [];

  String _selectedFilter = 'Upcoming';
  final List<String> _filters = ['Upcoming', 'Past', 'All'];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadPrograms();
  }

  Future<void> _loadPrograms() async {
    try {
      final now = DateTime.now();
      final todayStr = DateFormat('yyyy-MM-dd').format(now);

      // Load upcoming programs (today and future)
      final upcomingSnapshot = await _firestore
          .collection('programs')
          .where('isPublished', isEqualTo: true)
          .where('date', isGreaterThanOrEqualTo: todayStr)
          .orderBy('date')
          .get();

      // Load past programs
      final pastSnapshot = await _firestore
          .collection('programs')
          .where('isPublished', isEqualTo: true)
          .where('date', isLessThan: todayStr)
          .orderBy('date', descending: true)
          .get();

      setState(() {
        _upcomingPrograms = upcomingSnapshot.docs
            .map((doc) {
              final data = doc.data();
              return {
                ...data,
                'id': doc.id,
                'status': _getProgramStatus(data['date']),
              };
            })
            .toList();

        _pastPrograms = pastSnapshot.docs
            .map((doc) {
              final data = doc.data();
              return {
                ...data,
                'id': doc.id,
                'status': 'Past',
              };
            })
            .toList();

        _filteredPrograms = List.from(_upcomingPrograms);
      });
    } catch (e) {
      print('Error loading programs: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _getProgramStatus(String date) {
    final programDate = DateTime.parse(date);
    final now = DateTime.now();
    
    if (programDate.isBefore(now)) return 'Past';
    
    final difference = programDate.difference(now);
    if (difference.inDays == 0) return 'Today';
    if (difference.inDays == 1) return 'Tomorrow';
    if (difference.inDays <= 7) return 'This Week';
    return 'Upcoming';
  }

  void _filterPrograms(String filter) {
    setState(() {
      _selectedFilter = filter;
      switch (filter) {
        case 'Upcoming':
          _filteredPrograms = List.from(_upcomingPrograms);
          break;
        case 'Past':
          _filteredPrograms = List.from(_pastPrograms);
          break;
        case 'All':
          _filteredPrograms = [..._upcomingPrograms, ..._pastPrograms];
          break;
      }

      // Apply search filter if exists
      if (_searchQuery.isNotEmpty) {
        _filteredPrograms = _filteredPrograms
            .where((program) =>
                program['title'].toLowerCase().contains(_searchQuery) ||
                program['description'].toLowerCase().contains(_searchQuery) ||
                program['location'].toLowerCase().contains(_searchQuery))
            .toList();
      }
    });
  }

  void _searchPrograms(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      if (query.isEmpty) {
        _filterPrograms(_selectedFilter);
      } else {
        List<Map<String, dynamic>> searchList;
        switch (_selectedFilter) {
          case 'Upcoming':
            searchList = _upcomingPrograms;
            break;
          case 'Past':
            searchList = _pastPrograms;
            break;
          case 'All':
            searchList = [..._upcomingPrograms, ..._pastPrograms];
            break;
          default:
            searchList = _upcomingPrograms;
        }

        _filteredPrograms = searchList
            .where((program) =>
                program['title'].toLowerCase().contains(_searchQuery) ||
                program['description'].toLowerCase().contains(_searchQuery) ||
                program['location'].toLowerCase().contains(_searchQuery))
            .toList();
      }
    });
  }

  Widget _buildProgramCard(Map<String, dynamic> program) {
    final date = program['date'] != null
        ? DateFormat('MMM d, yyyy').format(DateTime.parse(program['date']))
        : '';
    final time = program['startTime'] != null
        ? '${program['startTime']} - ${program['endTime'] ?? ''}'
        : '';

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.05),
      child: InkWell(
        onTap: () => _openProgramDetail(program),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(program['status']).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  program['status'].toUpperCase(),
                  style: TextStyle(
                    color: _getStatusColor(program['status']),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(height: 12),

              // Title
              Text(
                program['title'] ?? '',
                style: TextStyle(
                  color: Color(0xFF333333),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                ),
              ),
              SizedBox(height: 8),

              // Date & Type
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 14, color: Color(0xFF999999)),
                  SizedBox(width: 6),
                  Text(
                    date,
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF999999),
                    ),
                  ),
                  SizedBox(width: 12),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Color(0xFF8E44AD).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      program['type']?.toUpperCase() ?? 'EVENT',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF8E44AD),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),

              // Description
              if (program['description'] != null)
                Text(
                  program['description']!,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.6,
                    color: Color(0xFF333333),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              SizedBox(height: 12),

              // Time & Location
              Row(
                children: [
                  Icon(Icons.access_time_outlined,
                      size: 14, color: Color(0xFF999999)),
                  SizedBox(width: 6),
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF999999),
                    ),
                  ),
                  SizedBox(width: 16),
                  Icon(Icons.location_on_outlined,
                      size: 14, color: Color(0xFF999999)),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      program['location'] ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF999999),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Today':
        return Color(0xFFE74C3C);
      case 'Tomorrow':
        return Color(0xFFF39C12);
      case 'This Week':
        return Color(0xFF3498DB);
      case 'Upcoming':
        return Color(0xFF2ECC71);
      case 'Past':
        return Color(0xFF95A5A6);
      default:
        return Color(0xFF8E44AD);
    }
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;
          return Container(
            margin: EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) => _filterPrograms(filter),
              selectedColor: Color(0xFF8E44AD),
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Color(0xFF666666),
                fontWeight: FontWeight.w500,
              ),
              backgroundColor: Color(0xFFF0F0F0),
              shape: StadiumBorder(
                side: BorderSide(
                  color: isSelected ? Color(0xFF8E44AD) : Color(0xFFE0E0E0),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFF0F0F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _searchPrograms,
        decoration: InputDecoration(
          hintText: 'Search programs...',
          hintStyle: TextStyle(color: Color(0xFF999999)),
          border: InputBorder.none,
          prefixIcon: Icon(Icons.search, color: Color(0xFF666666)),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close, color: Color(0xFF666666)),
                  onPressed: () {
                    _searchController.clear();
                    _searchPrograms('');
                  },
                )
              : null,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  void _openProgramDetail(Map<String, dynamic> program) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProgramDetailScreen(program: program),
      ),
    );
  }

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
          'Programs & Events',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            fontFamily: 'Poppins',
            color: Color(0xFF333333),
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Color(0xFF8E44AD),
                strokeWidth: 2,
              ),
            )
          : Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Bar
                  _buildSearchBar(),
                  SizedBox(height: 20),

                  // Filter Chips
                  Text(
                    'Filter by',
                    style: TextStyle(
                      color: Color(0xFF333333),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  SizedBox(height: 8),
                  _buildFilterChips(),
                  SizedBox(height: 24),

                  // Programs List Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedFilter == 'Upcoming'
                            ? 'Upcoming Programs'
                            : _selectedFilter == 'Past'
                                ? 'Past Programs'
                                : 'All Programs',
                        style: TextStyle(
                          color: Color(0xFF333333),
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      Text(
                        '${_filteredPrograms.length} ${_filteredPrograms.length == 1 ? 'program' : 'programs'}',
                        style: TextStyle(
                          color: Color(0xFF666666),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  // Programs List
                  Expanded(
                    child: _filteredPrograms.isEmpty
                        ? Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.event_busy_outlined,
                                    size: 64,
                                    color: Color(0xFF8E44AD).withOpacity(0.5),
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'No programs found',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF666666),
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    _searchQuery.isNotEmpty
                                        ? 'Try a different search term'
                                        : 'No ${_selectedFilter.toLowerCase()} programs available',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF999999),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            physics: BouncingScrollPhysics(),
                            itemCount: _filteredPrograms.length,
                            itemBuilder: (context, index) {
                              return _buildProgramCard(_filteredPrograms[index]);
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}

// Program Detail Screen
class ProgramDetailScreen extends StatelessWidget {
  final Map<String, dynamic> program;

  const ProgramDetailScreen({super.key, required this.program});

  @override
  Widget build(BuildContext context) {
    final date = program['date'] != null
        ? DateFormat('EEEE, MMMM d, yyyy').format(DateTime.parse(program['date']))
        : '';
    final time = program['startTime'] != null
        ? '${program['startTime']} - ${program['endTime'] ?? ''}'
        : '';

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
          'Program Details',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            fontFamily: 'Poppins',
            color: Color(0xFF333333),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Image
            if (program['bannerUrl'] != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  program['bannerUrl']!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            SizedBox(height: 20),

            // Title and Type
            Container(
              padding: EdgeInsets.all(20),
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
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Color(0xFF8E44AD).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      program['type']?.toUpperCase() ?? 'EVENT',
                      style: TextStyle(
                        color: Color(0xFF8E44AD),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    program['title'] ?? '',
                    style: TextStyle(
                      color: Color(0xFF333333),
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Date and Time
            Container(
              padding: EdgeInsets.all(20),
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
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Date & Time',
                    style: TextStyle(
                      color: Color(0xFF333333),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          size: 20, color: Color(0xFF8E44AD)),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Date',
                              style: TextStyle(
                                color: Color(0xFF666666),
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              date,
                              style: TextStyle(
                                color: Color(0xFF333333),
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.access_time_outlined,
                          size: 20, color: Color(0xFF8E44AD)),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Time',
                              style: TextStyle(
                                color: Color(0xFF666666),
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              time,
                              style: TextStyle(
                                color: Color(0xFF333333),
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Location
            Container(
              padding: EdgeInsets.all(20),
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
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Location',
                    style: TextStyle(
                      color: Color(0xFF333333),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 20, color: Color(0xFF8E44AD)),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              program['location'] ?? '',
                              style: TextStyle(
                                color: Color(0xFF333333),
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 8),
                            Container(
                              height: 150,
                              decoration: BoxDecoration(
                                color: Color(0xFFF0F0F0),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.map_outlined,
                                        size: 40, color: Color(0xFFCCCCCC)),
                                    SizedBox(height: 8),
                                    Text(
                                      'Map View',
                                      style: TextStyle(
                                        color: Color(0xFF999999),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Description
            if (program['description'] != null)
              Container(
                padding: EdgeInsets.all(20),
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
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'About This Program',
                      style: TextStyle(
                        color: Color(0xFF333333),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      program['description']!,
                      style: TextStyle(
                        color: Color(0xFF666666),
                        fontSize: 15,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(height: 20),

            // Action Buttons
            Container(
              padding: EdgeInsets.all(20),
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
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Add to calendar functionality
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF8E44AD),
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_today_outlined, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Add to Calendar',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        // Share functionality
                      },
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Color(0xFF8E44AD)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.share_outlined,
                              size: 18, color: Color(0xFF8E44AD)),
                          SizedBox(width: 8),
                          Text(
                            'Share with Friends',
                            style: TextStyle(
                              color: Color(0xFF8E44AD),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
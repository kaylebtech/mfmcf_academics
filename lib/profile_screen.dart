import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mfmcf_academics/ai_screen.dart';
import 'package:mfmcf_academics/login_screen.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _currentUser;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  bool _isEditing = false;

  // Controllers for edit mode
  late TextEditingController _usernameController;
  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _matricController;
  
  // Dropdowns
  String? _selectedCollege;
  String? _selectedDepartment;
  String? _selectedLevel;

  final List<String> colleges = ['CHS', 'CSET', 'JUPEB'];
  Map<String, List<String>> departments = {
    'CHS': ['Medicine', 'Nursing', 'Pharmacy'],
    'CSET': ['Computer Science', 'Electrical Engineering', 'Mathematics'],
    'JUPEB': ['Science', 'Arts', 'Social Sciences'],
  };
  final List<String> levels = ['100', '200', '300', '400', '500'];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _initializeControllers();
  }

  void _initializeControllers() {
    _usernameController = TextEditingController();
    _fullNameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _matricController = TextEditingController();
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
            _populateControllers();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() => _isLoading = false);
    }
  }

  void _populateControllers() {
    if (_userData != null) {
      _usernameController.text = _userData!['username'] ?? '';
      _fullNameController.text = _userData!['fullName'] ?? '';
      _emailController.text = _userData!['email'] ?? '';
      _phoneController.text = _userData!['phone'] ?? '';
      _matricController.text = _userData!['matricNumber'] ?? '';
      _selectedCollege = _userData!['college'];
      _selectedDepartment = _userData!['department'];
      _selectedLevel = _userData!['level'];
    }
  }

  Future<void> _updateProfile() async {
    if (_currentUser == null) return;

    try {
      final updatedData = {
        'username': _usernameController.text.trim(),
        'fullName': _fullNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'matricNumber': _matricController.text.trim(),
        'college': _selectedCollege,
        'department': _selectedDepartment,
        'level': _selectedLevel,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('users')
          .doc(_currentUser!.uid)
          .update(updatedData);

      setState(() {
        _isEditing = false;
      });
      
      // Reload user data
      _loadUserData();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Color(0xFFE75480),
        ),
      );
    } catch (e) {
      print('Error updating profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _signOut() async {
    try {
      await _auth.signOut();
      // Replace with your actual LoginPage widget
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Container(
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
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Color(0xFFE75480).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Color(0xFFE75480), size: 20),
        ),
        title: Text(
          label,
          style: TextStyle(
            color: Color(0xFF666666),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          value,
          style: TextStyle(
            color: Color(0xFF333333),
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Color(0xFFE75480)),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Color(0xFFE75480), width: 2),
          ),
        ),
        style: TextStyle(fontSize: 15, color: Color(0xFF333333)),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Text('Select $label', style: TextStyle(color: Colors.grey[500])),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(item, style: TextStyle(color: Color(0xFF333333))),
            );
          }).toList(),
          onChanged: onChanged,
          icon: Icon(Icons.keyboard_arrow_down, color: Color(0xFFE75480)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFF8F0),
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFE75480),
                  strokeWidth: 2,
                ),
              )
            : CustomScrollView(
                physics: BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Container(
                      color: Color(0xFFFFF8F0),
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.arrow_back),
                                onPressed: () => Navigator.pop(context),
                                color: Color(0xFF333333),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Profile',
                                style: TextStyle(
                                  color: Color(0xFF333333),
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              Spacer(),
                              if (!_isEditing)
                                IconButton(
                                  icon: Icon(Iconsax.edit),
                                  onPressed: () => setState(() => _isEditing = true),
                                  color: Color(0xFFE75480),
                                ),
                            ],
                          ),
                          SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                  
                  SliverPadding(
                    padding: EdgeInsets.all(20),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        children: [
                          // Profile Header
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFFE75480), Color(0xFFF8C8DC)],
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
                              children: [
                                CircleAvatar(
                                  radius: 50,
                                  backgroundColor: Colors.white,
                                  backgroundImage: _userData?['profileImage'] != null && _userData!['profileImage'].isNotEmpty
                                      ? NetworkImage(_userData!['profileImage'])
                                      : null,
                                  child: _userData?['profileImage'] == null || _userData!['profileImage'].isEmpty
                                      ? Icon(
                                          Iconsax.profile_circle,
                                          size: 50,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  _userData?['fullName'] ?? 'No Name',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  _userData?['username'] ?? '',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _userData?['role']?.toString().toUpperCase() ?? 'STUDENT',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 24),

                          if (_isEditing) ...[
                            // Edit Form
                            _buildEditableField(
                              label: 'Username',
                              controller: _usernameController,
                              icon: Iconsax.user,
                            ),
                            _buildEditableField(
                              label: 'Full Name',
                              controller: _fullNameController,
                              icon: Iconsax.profile_2user,
                            ),
                            _buildEditableField(
                              label: 'Email',
                              controller: _emailController,
                              icon: Iconsax.direct_right,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            _buildEditableField(
                              label: 'Phone Number',
                              controller: _phoneController,
                              icon: Iconsax.call,
                              keyboardType: TextInputType.phone,
                            ),
                            _buildEditableField(
                              label: 'Matric Number',
                              controller: _matricController,
                              icon: Iconsax.document_text_1,
                            ),
                            _buildDropdown(
                              label: 'College',
                              value: _selectedCollege,
                              items: colleges,
                              onChanged: (val) => setState(() {
                                _selectedCollege = val;
                                _selectedDepartment = null;
                              }),
                            ),
                            _buildDropdown(
                              label: 'Department',
                              value: _selectedDepartment,
                              items: _selectedCollege != null
                                  ? departments[_selectedCollege]!
                                  : [],
                              onChanged: (val) => setState(() => _selectedDepartment = val),
                            ),
                            _buildDropdown(
                              label: 'Level',
                              value: _selectedLevel,
                              items: levels,
                              onChanged: (val) => setState(() => _selectedLevel = val),
                            ),
                            
                            // Save/Cancel Buttons
                            SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => setState(() => _isEditing = false),
                                    style: OutlinedButton.styleFrom(
                                      padding: EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      side: BorderSide(color: Color(0xFFE75480)),
                                    ),
                                    child: Text(
                                      'Cancel',
                                      style: TextStyle(
                                        color: Color(0xFFE75480),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _updateProfile,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFFE75480),
                                      padding: EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      elevation: 4,
                                    ),
                                    child: Text(
                                      'Save Changes',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 32),
                          ] else ...[
                            // View Mode
                            Column(
                              children: [
                                _buildInfoItem(
                                  'Email',
                                  _userData?['email'] ?? 'Not provided',
                                  Iconsax.direct_right,
                                ),
                                SizedBox(height: 12),
                                _buildInfoItem(
                                  'Phone Number',
                                  _userData?['phone'] ?? 'Not provided',
                                  Iconsax.call,
                                ),
                                SizedBox(height: 12),
                                _buildInfoItem(
                                  'Matric Number',
                                  _userData?['matricNumber'] ?? 'Not provided',
                                  Iconsax.document_text_1,
                                ),
                                SizedBox(height: 12),
                                _buildInfoItem(
                                  'College',
                                  _userData?['college'] ?? 'Not selected',
                                  Iconsax.building,
                                ),
                                SizedBox(height: 12),
                                _buildInfoItem(
                                  'Department',
                                  _userData?['department'] ?? 'Not selected',
                                  Iconsax.building_3,
                                ),
                                SizedBox(height: 12),
                                _buildInfoItem(
                                  'Level',
                                  _userData?['level'] ?? 'Not selected',
                                  Iconsax.ranking,
                                ),
                                SizedBox(height: 12),
                                _buildInfoItem(
                                  'Account Status',
                                  _userData?['accountStatus'] ?? 'Active',
                                  _userData?['accountStatus'] == 'active'
                                      ? Iconsax.verify
                                      : Iconsax.warning_2,
                                ),
                                SizedBox(height: 12),
                                if (_userData?['createdAt'] != null)
                                  _buildInfoItem(
                                    'Member Since',
                                    DateFormat('MMM d, yyyy').format(
                                      (_userData!['createdAt'] as Timestamp).toDate(),
                                    ),
                                    Iconsax.calendar,
                                  ),
                              ],
                            ),
                            
                            // Logout Button
                            SizedBox(height: 32),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _signOut,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.red,
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 0,
                                  side: BorderSide(color: Colors.red.withOpacity(0.3)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Iconsax.logout, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Log Out',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildNavItem(Icons.home_rounded, 'Home', false, () {
                  Navigator.pop(context);
                }),
                _buildNavItem(Icons.smart_toy_outlined, 'AI', false, () {
                  // Replace with your actual AIPage widget
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AIPage()),
                  );
                }),
                _buildNavItem(Icons.person_outline_rounded, 'Profile', true, () {}),
              ],
            ),
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
              ? Color(0xFFE75480).withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? Color(0xFFE75480) : Color(0xFF999999),
              size: 22,
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isActive ? Color(0xFFE75480) : Color(0xFF999999),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _matricController.dispose();
    super.dispose();
  }
}

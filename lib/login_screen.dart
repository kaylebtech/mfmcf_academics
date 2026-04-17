import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mfmcf_academics/forgot_password.dart';
import 'package:mfmcf_academics/home_screen.dart';
import 'package:mfmcf_academics/signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  // Controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  // Check if user is already logged in
  void _checkAuthState() {
    auth.FirebaseAuth.instance.authStateChanges().listen((auth.User? user) {
      if (user != null && mounted) {
        // User is already logged in, navigate to home
        debugPrint("User already logged in with UID: ${user.uid}");
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
          (route) => false,
        );
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Show beautiful toast
  void _showToast(String message, {bool isError = true}) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 3,
      backgroundColor: isError
          ? Colors.red.withOpacity(0.9)
          : Colors.green.withOpacity(0.9),
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  Future<void> _login() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      _showToast("Please fill all required fields correctly");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Get trimmed values
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      debugPrint("Starting login process for email: $email");

      // Sign in with Firebase Auth
      final authResult = await auth.FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      final user = authResult.user;
      if (user == null) {
        throw Exception("Login failed - no user returned");
      }

      final uid = user.uid;
      debugPrint("User logged in successfully with UID: $uid");

      // Update last login time in Firestore
      try {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'lastLoginAt': FieldValue.serverTimestamp(),
        });
        debugPrint("Last login time updated in Firestore");
      } catch (e) {
        // Don't fail login if Firestore update fails
        debugPrint("Warning: Failed to update last login time: $e");
      }

      // Show success message
      _showToast("Welcome back!", isError: false);

      // Navigate to Home after a short delay
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      // Navigate to Home (Firebase Auth automatically persists the session)
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
        (route) => false,
      );
    } on auth.FirebaseAuthException catch (e) {
      debugPrint("FirebaseAuthException: ${e.code} - ${e.message}");
      String message = "Login failed";

      switch (e.code) {
        case 'user-not-found':
          message = "No account found with this email. Please sign up.";
          break;
        case 'wrong-password':
          message = "Incorrect password. Please try again.";
          break;
        case 'invalid-email':
          message = "Invalid email format. Please check and try again.";
          break;
        case 'user-disabled':
          message = "This account has been disabled. Contact support.";
          break;
        case 'invalid-credential':
          message = "Invalid email or password. Please try again.";
          break;
        case 'too-many-requests':
          message = "Too many failed attempts. Please try again later.";
          break;
        case 'network-request-failed':
          message = "Network error. Please check your internet connection.";
          break;
        default:
          message = "Login failed: ${e.message ?? 'Unknown error'}";
      }
      _showToast(message);
    } on FirebaseException catch (e) {
      debugPrint("FirebaseException: ${e.code} - ${e.message}");
      String message = "Database error occurred";

      if (e.code == 'permission-denied') {
        message = "Permission denied. Please contact support.";
      } else if (e.code == 'unavailable') {
        message = "Service unavailable. Please try again later.";
      } else {
        message = "Database error: ${e.message ?? 'Unknown error'}";
      }
      _showToast(message);
    } catch (e) {
      debugPrint("Unexpected error during login: $e");
      _showToast("An unexpected error occurred. Please try again.");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Google Sign-In method (you'll need to implement this with google_sign_in package)
  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      // TODO: Implement Google Sign-In
      // You'll need to add google_sign_in package and configure it
      // For now, showing a placeholder message
      _showToast("Google Sign-In coming soon", isError: false);

      /* Example implementation:
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;
      
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      await auth.FirebaseAuth.instance.signInWithCredential(credential);
      // Navigation will be handled by authStateChanges listener
      */
    } catch (e) {
      debugPrint("Google Sign-In error: $e");
      _showToast("Google Sign-In failed. Please try again.");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0), // Cream
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: size.width * 0.06,
            vertical: size.height * 0.04,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: size.height * 0.08),

                // Welcome Back Text
                Text(
                  'Welcome Back',
                  style: GoogleFonts.inter(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFE75480), // Pink shade
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Login to continue your journey',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 48),

                // Email Field
                _buildTextField(
                  controller: _emailController,
                  label: 'Email',
                  icon: Iconsax.direct_right,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Email is required';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) {
                      return 'Enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  enabled: !_isLoading,
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Password is required';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(
                      Iconsax.password_check,
                      color: Color(0xFFE75480),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Iconsax.eye_slash : Iconsax.eye,
                        color: const Color(0xFFE75480),
                      ),
                      onPressed: _isLoading
                          ? null
                          : () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                    ),
                    labelStyle: GoogleFonts.inter(
                      color: Colors.grey[600],
                      fontSize: 15,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 18,
                      horizontal: 16,
                    ),
                    floatingLabelBehavior: FloatingLabelBehavior.auto,
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Color(0xFFE75480),
                        width: 2,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Colors.red,
                        width: 1.5,
                      ),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Colors.red, width: 2),
                    ),
                  ),
                  style: GoogleFonts.inter(fontSize: 16, color: Colors.black87),
                ),
                const SizedBox(height: 12),

                // Remember Me & Forgot Password Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          activeColor: const Color(0xFFE75480),
                          onChanged: _isLoading
                              ? null
                              : (bool? value) => setState(
                                  () => _rememberMe = value ?? false,
                                ),
                        ),
                        Text(
                          'Remember Me',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ForgotPasswordPage(),
                              ),
                            ),
                      child: Text(
                        'Forgot Password?',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: _isLoading
                              ? Colors.grey
                              : const Color(0xFFE75480),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Login Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE75480),
                      disabledBackgroundColor: Colors.grey[400],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      shadowColor: Colors.pink.withOpacity(0.3),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            'Login',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 24),

                // Divider with "OR"
                Row(
                  children: [
                    Expanded(
                      child: Divider(color: Colors.grey[400], thickness: 1),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR',
                        style: GoogleFonts.inter(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(color: Colors.grey[400], thickness: 1),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Google Sign-In Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _signInWithGoogle,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: BorderSide(color: Colors.grey[300]!, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset('assets/google.png', height: 24, width: 24),
                        const SizedBox(width: 12),
                        Text(
                          'Continue with Google',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Don't have account?
                Center(
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: Colors.grey[600],
                      ),
                      children: [
                        const TextSpan(text: "Don't have an account? "),
                        TextSpan(
                          text: 'Sign Up',
                          style: const TextStyle(
                            color: Color(0xFFE75480),
                            fontWeight: FontWeight.bold,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = _isLoading
                                ? null
                                : () => Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const SignupScreen(),
                                    ),
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      enabled: !_isLoading,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFFE75480)),
        labelStyle: GoogleFonts.inter(color: Colors.grey[600], fontSize: 15),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 18,
          horizontal: 16,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE75480), width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
      style: GoogleFonts.inter(fontSize: 16, color: Colors.black87),
    );
  }
}

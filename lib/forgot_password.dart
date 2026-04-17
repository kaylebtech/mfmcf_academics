import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:fluttertoast/fluttertoast.dart';

// Updated ForgotPasswordPage with full functionality
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  final TextEditingController _emailController = TextEditingController();
  bool _isEmailSent = false;
  String? _sentToEmail;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

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

  Future<void> _sendPasswordResetEmail() async {
    if (!_formKey.currentState!.validate()) {
      _showToast("Please enter a valid email address");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      debugPrint("Sending password reset email to: $email");

      await auth.FirebaseAuth.instance.sendPasswordResetEmail(
        email: email,
      );

      // Success
      setState(() {
        _isEmailSent = true;
        _sentToEmail = email;
      });

      _showToast("Password reset email sent successfully!", isError: false);
      debugPrint("Password reset email sent to $email");

    } on auth.FirebaseAuthException catch (e) {
      debugPrint("FirebaseAuthException: ${e.code} - ${e.message}");
      String message = "Failed to send reset email";
      
      switch (e.code) {
        case 'user-not-found':
          message = "No account found with this email address.";
          break;
        case 'invalid-email':
          message = "Invalid email address format.";
          break;
        case 'user-disabled':
          message = "This account has been disabled.";
          break;
        case 'too-many-requests':
          message = "Too many attempts. Please try again later.";
          break;
        case 'network-request-failed':
          message = "Network error. Check your internet connection.";
          break;
        default:
          message = "Error: ${e.message ?? 'Unknown error'}";
      }
      _showToast(message);
      
    } catch (e) {
      debugPrint("Unexpected error: $e");
      _showToast("An unexpected error occurred. Please try again.");
      
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _goBackToLogin() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0), // Cream background
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
                // Back Button
                IconButton(
                  onPressed: _isLoading ? null : _goBackToLogin,
                  icon: const Icon(Iconsax.arrow_left, color: Color(0xFFE75480)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(height: 16),

                // Main Content
                SizedBox(height: size.height * 0.05),
                
                // Title
                Text(
                  _isEmailSent ? 'Check Your Email' : 'Forgot Password',
                  style: GoogleFonts.inter(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFE75480), // Pink shade
                  ),
                ),
                const SizedBox(height: 8),
                
                // Subtitle
                Text(
                  _isEmailSent 
                      ? 'We\'ve sent password reset instructions to'
                      : 'Enter your email to reset your password',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                
                if (_isEmailSent && _sentToEmail != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _sentToEmail!,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFE75480),
                    ),
                  ),
                ],
                
                const SizedBox(height: 48),

                if (!_isEmailSent) ...[
                  // Email Field
                  _buildEmailField(),
                  const SizedBox(height: 32),

                  // Send Reset Email Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _sendPasswordResetEmail,
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
                              'Send Reset Link',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ] else ...[
                  // Success State
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Iconsax.message,
                          size: 80,
                          color: const Color(0xFFE75480).withOpacity(0.8),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Email Sent Successfully',
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFE75480),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Check your inbox for the password reset link. '
                          'If you don\'t see it, check your spam folder.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: Colors.grey[600],
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Link expires in 1 hour.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.orange[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Resend Email Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _sendPasswordResetEmail,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(
                            color: Color(0xFFE75480),
                            width: 2,
                          ),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Color(0xFFE75480),
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              'Resend Email',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFE75480),
                              ),
                            ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey[400], thickness: 1)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR',
                        style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 14),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey[400], thickness: 1)),
                  ],
                ),

                const SizedBox(height: 24),

                // Back to Login Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _goBackToLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Back to Login',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFE75480),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Help Text
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Iconsax.info_circle, size: 20, color: Colors.blue[700]),
                          const SizedBox(width: 8),
                          Text(
                            'Need help?',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'If you\'re having trouble resetting your password, '
                        'contact our support team at mfmcfuniosun.academics@gmail.com',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
                      ),
                    ],
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

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
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
      enabled: !_isLoading,
      decoration: InputDecoration(
        labelText: 'Email Address',
        prefixIcon: const Icon(Iconsax.direct_right, color: Color(0xFFE75480)),
        suffixIcon: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFFE75480),
                ),
              )
            : null,
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
        hintText: 'you@example.com',
        hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
      ),
      style: GoogleFonts.inter(fontSize: 16, color: Colors.black87),
    );
  }
}

// The rest of your LoginScreen class remains exactly the same...
// [Keep all your existing LoginScreen code from _LoginScreenState onwards]
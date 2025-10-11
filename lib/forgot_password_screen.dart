import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'home_enhanced.dart';

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _codeSent = false;
  bool _codeVerified = false;
  int _countdown = 0;
  Timer? _timer;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  final SupabaseClient _supabase = Supabase.instance.client;

  // ⚠️ REPLACE THESE WITH YOUR EMAILJS CREDENTIALS
  final String _emailJsServiceId = 'service_3rulrbx';     // From Step 2
  final String _emailJsTemplateId = 'template_12n81hf';   // From Step 3
  final String _emailJsPublicKey = '8tXaBu5ICIijo5ft_';     // From Step 4

  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Generate secure 6-digit verification code
  String _generateSecureVerificationCode() {
    final random = Random.secure();
    return List.generate(6, (_) => random.nextInt(10)).join();
  }

  // Send verification code via EmailJS
  Future<void> _sendVerificationCode() async {
    final String email = _emailController.text.trim();

    if (email.isEmpty) {
      _showSnackBar('Please enter your email address');
      return;
    }

    // Basic email validation
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _showSnackBar('Please enter a valid email address');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Check rate limiting (max 3 requests in 5 minutes)
      final recentCodes = await _supabase
          .from('password_reset_codes')
          .select()
          .eq('email', email)
          .gte('created_at', DateTime.now().subtract(Duration(minutes: 5)).toIso8601String())
          .order('created_at', ascending: false);

      if (recentCodes.length >= 3) {
        _showSnackBar('⚠️ Too many requests. Please try again in 5 minutes.');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Generate secure 6-digit code
      final String verificationCode = _generateSecureVerificationCode();

      print('Generated code: $verificationCode for email: $email');

      // Store code in database
      await _supabase.from('password_reset_codes').insert({
        'email': email,
        'code': verificationCode,
        'expires_at': DateTime.now().add(Duration(minutes: 10)).toIso8601String(),
        'used': false,
      });

      print('Code stored in database successfully');

      // Send email via EmailJS
      final response = await http.post(
        Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'service_id': _emailJsServiceId,
          'template_id': _emailJsTemplateId,
          'user_id': _emailJsPublicKey,
          'template_params': {
            'to_email': email,
            'code': verificationCode,
          }
        }),
      );

      print('EmailJS Response Status: ${response.statusCode}');
      print('EmailJS Response Body: ${response.body}');

      if (response.statusCode == 200) {
        setState(() {
          _codeSent = true;
          _countdown = 60;
        });
        _startCountdown();
        _showSnackBar('✅ Verification code sent to $email');
      } else {
        throw Exception('Failed to send email: ${response.body}');
      }

    } catch (error) {
      print('Error sending verification code: $error');
      _showSnackBar('❌ Failed to send code: $error');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Verify the code entered by user
  Future<void> _verifyCode() async {
    final String email = _emailController.text.trim();
    final String code = _codeController.text.trim();

    if (code.isEmpty || code.length != 6) {
      _showSnackBar('Please enter a valid 6-digit code');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Verify code from database
      final response = await _supabase
          .from('password_reset_codes')
          .select()
          .eq('email', email)
          .eq('code', code)
          .eq('used', false)
          .maybeSingle();

      if (response != null) {
        final expiresAt = DateTime.parse(response['expires_at']);

        if (DateTime.now().isBefore(expiresAt)) {
          // Mark code as used
          await _supabase
              .from('password_reset_codes')
              .update({'used': true})
              .eq('email', email)
              .eq('code', code);

          setState(() {
            _codeVerified = true;
          });
          _showSnackBar('✅ Code verified successfully!');
        } else {
          _showSnackBar('❌ Code has expired. Please request a new one.');
        }
      } else {
        _showSnackBar('❌ Invalid verification code');
      }
    } catch (error) {
      print('Error verifying code: $error');
      _showSnackBar('❌ Invalid verification code');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Reset password and login
  Future<void> _resetPasswordAndLogin() async {
    final String email = _emailController.text.trim();
    final String newPassword = _newPasswordController.text.trim();
    final String confirmPassword = _confirmPasswordController.text.trim();

    // Check if passwords are provided and match
    if (newPassword.isNotEmpty || confirmPassword.isNotEmpty) {
      if (newPassword.length < 6) {
        _showSnackBar('❌ Password must be at least 6 characters');
        return;
      }

      if (newPassword != confirmPassword) {
        _showSnackBar('❌ Passwords do not match');
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        // Check if user exists
        final userResponse = await _supabase
            .from('users')
            .select()
            .eq('email', email)
            .maybeSingle();

        if (userResponse != null) {
          // Update password in your users table
          // ⚠️ IMPORTANT: Consider hashing the password for security!
          await _supabase
              .from('users')
              .update({'password': newPassword})
              .eq('email', email);

          _showSnackBar('✅ Password reset successful!');

          // Auto login after password reset
          await Future.delayed(Duration(seconds: 1));
          _navigateToHome();
        } else {
          _showSnackBar('❌ User not found');
        }

      } catch (error) {
        print('Password reset error: $error');
        _showSnackBar('❌ Password reset failed: $error');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      // If no password provided, just login
      _loginAnyway();
    }
  }

  void _loginAnyway() {
    _showSnackBar('✅ Logged in successfully!');
    _navigateToHome();
  }

  void _navigateToHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LostKuetShell()),
          (route) => false,
    );
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reset Password'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // STEP 1: Enter Email
            if (!_codeSent) ...[
              Text(
                'Enter your email address',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                'We will send a verification code to your email',
                style: TextStyle(color: Colors.grey[600]),
              ),
              SizedBox(height: 30),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'your-email@kuet.ac.bd',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendVerificationCode,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : Text(
                    'Send Verification Code',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],

            // STEP 2: Enter Verification Code
            if (_codeSent && !_codeVerified) ...[
              Text(
                'Enter verification code',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                'We sent a 6-digit code to ${_emailController.text}',
                style: TextStyle(color: Colors.grey[600]),
              ),
              SizedBox(height: 10),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Check your email inbox (and spam folder)',
                        style: TextStyle(color: Colors.blue[900], fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 30),
              TextField(
                controller: _codeController,
                decoration: InputDecoration(
                  labelText: 'Verification Code',
                  hintText: '123456',
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, letterSpacing: 10),
              ),
              SizedBox(height: 10),
              if (_countdown > 0)
                Center(
                  child: Text(
                    'Resend code in $_countdown seconds',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _verifyCode,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _isLoading
                            ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                            : Text('Verify Code', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ),
                  if (_countdown == 0) ...[
                    SizedBox(width: 10),
                    TextButton(
                      onPressed: _sendVerificationCode,
                      child: Text('Resend'),
                    ),
                  ],
                ],
              ),
            ],

            // STEP 3: Reset Password
            if (_codeVerified) ...[
              Text(
                'Set New Password',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                'Create a new password for your account (optional)',
                style: TextStyle(color: Colors.grey[600]),
              ),
              SizedBox(height: 30),

              // New Password Field
              TextField(
                controller: _newPasswordController,
                obscureText: !_isNewPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  hintText: 'Enter new password',
                  prefixIcon: Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isNewPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _isNewPasswordVisible = !_isNewPasswordVisible;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Confirm Password Field
              TextField(
                controller: _confirmPasswordController,
                obscureText: !_isConfirmPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  hintText: 'Re-enter password',
                  prefixIcon: Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 10),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber[700], size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Password fields are optional. You can login without resetting.',
                        style: TextStyle(color: Colors.amber[900], fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 30),

              // Reset Password and Login Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _resetPasswordAndLogin,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : Text(
                    'Reset Password & Login',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              SizedBox(height: 15),

              // Login Anyway Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: _isLoading ? null : _loginAnyway,
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Login Anyway',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _codeSent = false;
  bool _codeVerified = false;
  int _countdown = 0;
  Timer? _timer;

  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Generate a random 6-digit code
  String _generateVerificationCode() {
    final random = DateTime.now().millisecondsSinceEpoch;
    return (random % 900000 + 100000).toString(); // 6-digit code
  }

  // Send verification code
  Future<void> _sendVerificationCode() async {
    final String email = _emailController.text.trim();

    if (email.isEmpty || !_isValidEmail(email)) {
      _showSnackBar('Please enter a valid email address');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Generate verification code
      final String verificationCode = _generateVerificationCode();

      // Store code in database (expires in 10 minutes)
      await _supabase.from('password_reset_codes').insert({
        'email': email,
        'code': verificationCode,
        'expires_at': DateTime.now().add(Duration(minutes: 10)).toIso8601String(),
      });

      // Send email using Supabase email service
      final response = await _supabase.functions.invoke('send-password-reset-email',
          body: {
            'email': email,
            'code': verificationCode,
          }
      );

      // If Supabase function fails, fallback to regular email
      if (response.status != 200) {
        // You can integrate with your email service here
        // For now, we'll show the code in snackbar (for testing)
        _showSnackBar('Verification code: $verificationCode (This is for testing)');
      }

      setState(() {
        _codeSent = true;
        _countdown = 60; // 60 seconds countdown
      });

      // Start countdown timer
      _startCountdown();

      _showSnackBar('Verification code sent to your email');
    } catch (error) {
      _showSnackBar('Failed to send verification code: $error');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Verify code
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
      // Call the database function to verify code
      final response = await _supabase.rpc('verify_password_reset_code', params: {
        'p_email': email,
        'p_code': code,
      });

      if (response[0]['is_valid'] == true) {
        setState(() {
          _codeVerified = true;
        });
        _showSnackBar('Code verified successfully');
      } else {
        _showSnackBar(response[0]['message'] ?? 'Invalid code');
      }
    } catch (error) {
      _showSnackBar('Error verifying code: $error');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Reset password
  Future<void> _resetPassword() async {
    final String email = _emailController.text.trim();
    final String newPassword = _newPasswordController.text.trim();

    if (newPassword.isEmpty || newPassword.length < 6) {
      _showSnackBar('Password must be at least 6 characters');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Update password using Supabase auth
      final UserResponse response = await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      if (response.user != null) {
        _showSnackBar('Password reset successfully!');
        Navigator.pop(context); // Go back to login screen
      }
    } on AuthException catch (error) {
      _showSnackBar('Password reset failed: ${error.message}');
    } catch (error) {
      _showSnackBar('An error occurred during password reset');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _startCountdown() {
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

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
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
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendVerificationCode,
                  child: _isLoading
                      ? CircularProgressIndicator()
                      : Text('Send Verification Code'),
                ),
              ),
            ],

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
              SizedBox(height: 30),
              TextField(
                controller: _codeController,
                decoration: InputDecoration(
                  labelText: 'Verification Code',
                  prefixIcon: Icon(Icons.code),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                maxLength: 6,
              ),
              SizedBox(height: 10),
              if (_countdown > 0)
                Text(
                  'Resend code in $_countdown seconds',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _verifyCode,
                        child: _isLoading
                            ? CircularProgressIndicator()
                            : Text('Verify Code'),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  if (_countdown == 0)
                    TextButton(
                      onPressed: _sendVerificationCode,
                      child: Text('Resend Code'),
                    ),
                ],
              ),
            ],

            if (_codeVerified) ...[
              Text(
                'Set new password',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                'Create a new password for your account',
                style: TextStyle(color: Colors.grey[600]),
              ),
              SizedBox(height: 30),
              TextField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _resetPassword,
                  child: _isLoading
                      ? CircularProgressIndicator()
                      : Text('Reset Password'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
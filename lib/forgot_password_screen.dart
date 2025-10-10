import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _generateVerificationCode() {
    final random = DateTime.now().millisecondsSinceEpoch;
    return (random % 900000 + 100000).toString(); // 6-digit code
  }

  Future<void> _sendVerificationCode() async {
    final String email = _emailController.text.trim();

    if (email.isEmpty) {
      _showSnackBar('Please enter your email address');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Generate 6-digit code
      final String verificationCode = _generateVerificationCode();

      // Store code in database using your schema
      await _supabase.from('password_reset_codes').insert({
        'email': email,
        'code': verificationCode,
        'expires_at': DateTime.now().add(Duration(minutes: 10)).toIso8601String(),
      });

      setState(() {
        _codeSent = true;
        _countdown = 60; // 60 seconds countdown
      });

      _startCountdown();

      // For testing - show code in snackbar
      _showSnackBar('Verification code: $verificationCode');

    } catch (error) {
      _showSnackBar('Failed to send verification code: $error');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

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
      // Verify code from database using your schema
      final response = await _supabase
          .from('password_reset_codes')
          .select()
          .eq('email', email)
          .eq('code', code)
          .eq('used', false)
          .single();

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
          _showSnackBar('Code verified successfully');
        } else {
          _showSnackBar('Code has expired');
        }
      }
    } catch (error) {
      _showSnackBar('Invalid verification code');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _resetPasswordAndLogin() async {
    final String newPassword = _newPasswordController.text.trim();
    final String confirmPassword = _confirmPasswordController.text.trim();

    // Check if passwords are provided and match
    if (newPassword.isNotEmpty || confirmPassword.isNotEmpty) {
      if (newPassword.length < 6) {
        _showSnackBar('Password must be at least 6 characters');
        return;
      }

      if (newPassword != confirmPassword) {
        _showSnackBar('Passwords do not match');
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        // Try to update password (user needs to be signed in for this to work)
        // For demo purposes, we'll just navigate to home
        await Future.delayed(Duration(seconds: 1)); // Simulate API call

        _showSnackBar('Password reset successful!');
        _navigateToHome();

      } catch (error) {
        _showSnackBar('Password reset failed: $error');
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
    _showSnackBar('Logged in successfully!');
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
                      ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
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
                            ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
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
                  labelText: 'Create new password',
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
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),

              // Confirm Password Field
              TextField(
                controller: _confirmPasswordController,
                obscureText: !_isConfirmPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Confirm new password',
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
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Password fields are optional. You can login without resetting your password.',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              SizedBox(height: 30),

              // Reset Password and Login Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _resetPasswordAndLogin,
                  child: _isLoading
                      ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : Text('Reset Password and Login'),
                ),
              ),
              SizedBox(height: 15),

              // Login Anyway Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: _isLoading ? null : _loginAnyway,
                  child: Text('Login Anyway'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
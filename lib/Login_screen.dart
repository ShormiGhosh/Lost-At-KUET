import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'forgot_password.dart';
import 'home_enhanced.dart';
import 'main.dart';
String _generateUniqueUsername(String name) {
  // Clean the name and make it URL-safe
  final cleanName = name.toLowerCase().replaceAll(' ', '_').replaceAll(RegExp(r'[^a-z0-9_]'), '');
  // Add timestamp to ensure uniqueness
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  return '${cleanName}_$timestamp';
}
class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool flag = false;
  bool textAnimationFlag = false;
  bool isLoading = false;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isPasswordVisible = false;

  final SupabaseClient supabase = Supabase.instance.client;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    Timer(const Duration(milliseconds: 500), () {
      setState(() {
        flag = true;
      });
      Future.delayed(const Duration(milliseconds: 500), () {
        setState(() {
          textAnimationFlag = true;
        });
      });
    });
  }

  Future<void> _signIn() async {
    final String email = emailController.text.trim();
    final String password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar('Please enter both email and password');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final AuthResponse response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Verify profile exists
        try {
          await supabase
              .from('profiles')
              .select()
              .eq('id', response.user!.id)
              .single();

          // Save login state
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);
          await prefs.setString('email', email);

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => LostKuetShell()),
                (route) => false,
          );
        } on PostgrestException catch (e) {
          // Profile doesn't exist, create one
          await _createOrUpdateUserProfile(
            response.user!.id,
            response.user!.email?.split('@').first ?? 'User',
            response.user!.email ?? '',
            null,
          );

          // Then navigate
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);
          await prefs.setString('email', email);

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => LostKuetShell()),
                (route) => false,
          );
        }
      }
    } on AuthException catch (error) {
      _showSnackBar(error.message);
    } catch (error) {
      _showSnackBar('An error occurred during login');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _resetPassword() async {
    final String email = emailController.text.trim();

    if (email.isEmpty) {
      _showSnackBar('Please enter your email address');
      return;
    }

    try {
      await supabase.auth.resetPasswordForEmail(email);
      _showSnackBar('Password reset email sent!');
    } on AuthException catch (error) {
      _showSnackBar(error.message);
    } catch (error) {
      _showSnackBar('Failed to send reset email');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
  // Add Google Sign-In method
  Future<void> _signInWithGoogle() async {
    setState(() {
      isLoading = true;
    });

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      final AuthResponse response = await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken,
      );

      if (response.user != null) {
        // Check if user profile exists, if not create one
        await _createOrUpdateUserProfile(
            response.user!.id,
            googleUser.displayName ?? 'User',
            googleUser.email,
            googleUser.photoUrl

        );

        // Save login state in SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('email', googleUser.email);

        // Successfully logged in - navigate to enhanced home screen
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LostKuetShell()),
              (route) => false,
        );
      }
    } on AuthException catch (error) {
      _showSnackBar('Google Sign-In failed: ${error.message}');
    } catch (error) {
      _showSnackBar('An error occurred during Google Sign-In');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
  Future<void> _createOrUpdateUserProfile(
      String userId,
      String name,
      String email,
      String? avatarUrl
      ) async {
    try {
      await supabase.from('profiles').upsert({
        'id': userId,
        'name': name,
        'username': _generateUniqueUsername(name), // USE THE FUNCTION HERE
        'email': email,
        'avatar_url': avatarUrl,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } on PostgrestException catch (e) {
      if (e.code == '23505') { // Unique violation
        // Retry with different username
        await supabase.from('profiles').upsert({
          'id': userId,
          'name': name,
          'username': _generateUniqueUsername(name), // USE THE FUNCTION HERE
          'email': email,
          'avatar_url': avatarUrl,
          'updated_at': DateTime.now().toIso8601String(),
        });
      } else {
        rethrow;
      }
    }
  }

  void _navigateToSignUp() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => MyHomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 1),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                duration: const Duration(milliseconds: 500),
                secondChild: Image.asset(
                  "assets/images/lostatkuet_icon.png",
                  width: 100,
                  height: 100,
                ),
                sizeCurve: Curves.easeOut,
                crossFadeState:
                flag ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              ),
              const SizedBox(height: 15),
              AnimatedOpacity(
                opacity: textAnimationFlag ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 500),
                child: Text(
                  "Lost @ KUET",
                  style: TextStyle(
                    fontSize: 35,
                    color: const Color(0xFF292929),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(flex: 1),
              _buildEmailField(),
              const SizedBox(height: 30),
              _buildPasswordField(),
              const SizedBox(height: 10),
              _buildForgotPasswordButton(),
              const SizedBox(height: 20),
              _buildLoginButton(),
              const SizedBox(height: 20),
              _buildDivider(), // Add divider
              const SizedBox(height: 20),
              _buildGoogleSignInButton(), // Add Google Sign-In button
              const SizedBox(height: 10),
              _buildSignUpRedirect(),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return TextField(
      controller: emailController,
      decoration: const InputDecoration(
        hintText: 'Email',
        hintStyle: TextStyle(color: Color(0xFF585858)),
        prefixIcon: Icon(Icons.email_outlined),
      ),
      keyboardType: TextInputType.emailAddress,
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: passwordController,
      obscureText: !isPasswordVisible,
      decoration: InputDecoration(
        hintText: 'Password',
        hintStyle: const TextStyle(color: Color(0xFF585858)),
        prefixIcon: const Icon(Icons.lock),
        suffixIcon: IconButton(
          icon: Icon(
            isPasswordVisible ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: () {
            setState(() {
              isPasswordVisible = !isPasswordVisible;
            });
          },
        ),
      ),
    );
  }

  Widget _buildForgotPasswordButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {
          // Navigate to ForgotPasswordScreen
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ForgotPasswordScreen()),
          );
        },
        child: const Text('Forgot Password?'),
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: 100,
      child: ElevatedButton(
        onPressed: isLoading ? null : _signIn,
        child: isLoading
            ? SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF292929)),
          ),
        )
            : const Text("Login"),
      ),
    );
  }

  Widget _buildSignUpRedirect() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Don't have any account?"),
        TextButton(
          child: const Text("Sign Up"),
          onPressed: _navigateToSignUp,
        ),
      ],
    );
  }
  // Add divider widget
  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(color: Colors.grey[400]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR',
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Divider(color: Colors.grey[400]),
        ),
      ],
    );
  }
  Widget _buildGoogleSignInButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: isLoading ? null : _signInWithGoogle,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF292929),
          side: const BorderSide(color: Color(0xFF585858)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/google_icon.png',
              width: 20,
              height: 20,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.account_circle,
                  color: Color(0xFF292929),
                );
              },
            ),
            const SizedBox(width: 10),
            const Text('Sign in with Google'),
          ],
        ),
      ),
    );
  }

}
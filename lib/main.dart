import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'Login_screen.dart';
import 'Splash_Screen.dart';
import 'home_enhanced.dart';
import 'supabase_config.dart';
import 'package:google_sign_in/google_sign_in.dart';
String _generateUniqueUsername(String name) {
  // Clean the name and make it URL-safe
  final cleanName = name.toLowerCase().replaceAll(' ', '_').replaceAll(RegExp(r'[^a-z0-9_]'), '');
  // Add timestamp to ensure uniqueness
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  return '${cleanName}_$timestamp';
}
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
    final event = data.event;
    final session = data.session;
    final user = session?.user;

    print('Auth state changed: $event');

    if (event == AuthChangeEvent.signedIn && user != null) {
      print('User signed in: ${user.id}');

      // Wait a bit to ensure session is established
      await Future.delayed(const Duration(seconds: 2));

      try {
        final profile = await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle()
            .timeout(const Duration(seconds: 10));

        if (profile == null) {
          print('Creating profile for new user: ${user.id}');

          final userMetadata = user.userMetadata ?? {};
          final appMetadata = user.appMetadata ?? {};

          // Extract user info from multiple possible sources
          final userName = userMetadata['name'] ??
              userMetadata['full_name'] ??
              appMetadata['name'] ??
              'User';

          final userEmail = user.email ??
              userMetadata['email'] ??
              appMetadata['email'] ??
              '';

          // Generate unique username
          final username = _generateUniqueUsername(userName);

          await Supabase.instance.client.from('profiles').upsert({
            'id': user.id,
            'name': userName,
            'username': username,
            'email': userEmail,
            'avatar_url': userMetadata['avatar_url'],
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });

          print('Profile created successfully for user: ${user.id}');
        } else {
          print('Profile already exists for user: ${user.id}');
        }
      } catch (error) {
        print('Error handling profile creation: $error');
      }
    }
  });

  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lost @ KUET',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFFFFFFF),
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: Color(0xFFFFC815),
          onPrimary: Color(0xFF292929),
          secondary: Color(0xFF585858),
          onSecondary: Color(0xFFFFFFFF),
          surface: Color(0xFFFFFFFF),
          onSurface: Color(0xFF292929),
          error: Colors.red,
          onError: Color(0xFFFFFFFF),
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            color: Color(0xFF292929),
            fontWeight: FontWeight.bold,
          ),
          bodyLarge: TextStyle(color: Color(0xFF292929)),
          bodyMedium: TextStyle(color: Color(0xFF585858)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          prefixIconColor: const Color(0xFFFFC815),
          suffixIconColor: const Color(0xFFFFC815),
          labelStyle: const TextStyle(color: Color(0xFF585858)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: const BorderSide(
              color: Color(0xFFFFC815),
              width: 2.0,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: const BorderSide(
              color: Color(0xFF585858),
              width: 1.0,
            ),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFC815),
            foregroundColor: const Color(0xFF292929),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFFFFC815),
          ),
        ),
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  bool isPasswordVisible = false;
  bool flag = false;
  bool isLoading = false;

  final SupabaseClient supabase = Supabase.instance.client;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    clientId: '419649202011-cfb29t2j094ev24l8td2e84sp8s2sgrb.apps.googleusercontent.com', // ← replace with your exact Web client ID
  );


  @override
  void initState() {
    super.initState();
    _initializeAnimation();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    super.dispose();
  }

  void _initializeAnimation() {
    Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          flag = true;
        });
      }
    });
  }

  Future<void> _signUp() async {
    final String name = nameController.text.trim();
    final String email = emailController.text.trim();
    final String password = passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showSnackBar('Please fill all fields');
      return;
    }

    if (!_isValidEmail(email)) {
      _showSnackBar('Please enter a valid email address (e.g., name@example.com)');
      return;
    }

    if (password.length < 6) {
      _showSnackBar('Password must be at least 6 characters');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final AuthResponse response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
        },
      );

      if (response.user != null) {
        if (mounted) {
          _showSnackBar('Registration successful! Please check your email for verification.');
          _navigateToLogin();
        }
      }
    } on AuthException catch (error) {
      if (mounted) {
        _showSnackBar(error.message);
      }
    } catch (error) {
      if (mounted) {
        _showSnackBar('An error occurred during registration');
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }



  bool _isValidEmail(String email) {
    // More permissive email validation
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }
  Future<void> _signInWithGoogle() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Clear any cached credentials first
      await _googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      if (googleAuth.idToken == null) {
        throw AuthException('Google authentication failed: No ID token received');
      }

      // Use the ID token method (working approach)
      final AuthResponse response = await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken,
      );

      if (response.user != null) {
        print('Google Sign-In successful for user: ${response.user!.id}');

        // Wait a bit for the auth state to propagate
        await Future.delayed(const Duration(seconds: 2));

        if (mounted) {
          _showSnackBar('Google Sign-In successful!');
          _navigateToLogin();
        }
      }
    } on AuthException catch (error) {
      print('Google Sign-In AuthException: ${error.message}');
      if (mounted) {
        _showSnackBar('Google Sign-In failed: ${error.message}');
      }
    } catch (error) {
      print('Google Sign-In error: $error');
      if (mounted) {
        _showSnackBar('An error occurred during Google Sign-In');
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }
  Future<void> _createOrUpdateUserProfile(
      String userId,
      String name,
      String email, [
        String? avatarUrl,
      ]) async {
    try {
      await supabase.from('profiles').upsert({
        'id': userId,
        'name': name,
        'username': _generateUniqueUsername(name),
        'email': email,
        'avatar_url': avatarUrl, // This will be null for email signups
        'updated_at': DateTime.now().toIso8601String(),
      });
    } on PostgrestException catch (e) {
      if (e.code == '23505') { // Unique violation
        // Retry with different username
        await supabase.from('profiles').upsert({
          'id': userId,
          'name': name,
          'username': _generateUniqueUsername(name),
          'email': email,
          'avatar_url': avatarUrl,
          'updated_at': DateTime.now().toIso8601String(),
        });
      } else {
        rethrow;
      }
    }
  }

  void _navigateToHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => SplashScreen()), // Remove const if HomeEnhanced has issues
          (route) => false,
    );
  }
  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LostKuetShell()),
    );
  }

  void _togglePasswordVisibility() {
    setState(() {
      isPasswordVisible = !isPasswordVisible;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  _buildAnimatedLogo(),
                  const SizedBox(height: 20),
                  _buildTitle(),
                  const SizedBox(height: 40),
                  _buildNameField(),
                  const SizedBox(height: 25),
                  _buildEmailField(),
                  const SizedBox(height: 25),
                  _buildPasswordField(),
                  const SizedBox(height: 30),
                  _buildSignUpButton(),
                  const SizedBox(height: 20),
                  _buildDivider(),
                  const SizedBox(height: 20),
                  _buildGoogleSignInButton(), // Add Google Sign-In button
                  const SizedBox(height: 10),
                  _buildLoginRedirect(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
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
        child: isLoading // ADDED: Loading indicator for Google button
            ? const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF292929)),
          ),
        )
            : Row(
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
            const Text('Sign up with Google'),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedLogo() {
    return AnimatedCrossFade(
      firstChild: const SizedBox.shrink(),
      duration: const Duration(milliseconds: 500),
      secondChild: Image.asset(
        "assets/images/lostatkuet_icon.png",
        width: 100,
        height: 100,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFFFFC815),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.location_on,
              size: 60,
              color: Color(0xFF292929),
            ),
          );
        },
      ),
      crossFadeState: flag ? CrossFadeState.showSecond : CrossFadeState.showFirst,
    );
  }

  Widget _buildTitle() {
    return const Text(
      "Sign Up",
      style: TextStyle(
        fontSize: 40,
        color: Color(0xFF292929),
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildNameField() {
    return TextField(
      controller: nameController,
      enabled: !isLoading,
      decoration: const InputDecoration(
        labelText: 'Enter username',
        prefixIcon: Icon(Icons.person_outline),
      ),
      textInputAction: TextInputAction.next,
    );
  }

  Widget _buildEmailField() {
    return TextField(
      controller: emailController,
      enabled: !isLoading,
      decoration: const InputDecoration(
        labelText: 'Enter email',
        prefixIcon: Icon(Icons.email_outlined),
      ),
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: passwordController,
      enabled: !isLoading,
      obscureText: !isPasswordVisible,
      decoration: InputDecoration(
        labelText: 'Set password',
        prefixIcon: const Icon(Icons.lock),
        suffixIcon: IconButton(
          icon: Icon(
            isPasswordVisible ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: _togglePasswordVisibility,
        ),
      ),
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _signUp(),
    );
  }

  Widget _buildSignUpButton() {
    return SizedBox(
      width: 160,
      height: 48,
      child: ElevatedButton(
        onPressed: isLoading ? null : _signUp,
        child: isLoading
            ? const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF292929)),
          ),
        )
            : const Text("Create Account"),
      ),
    );
  }

  Widget _buildLoginRedirect() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Already have an account?"),
        TextButton(
          onPressed: isLoading ? null : _navigateToLogin,
          child: const Text("Login"),
        ),
      ],
    );
  }


}
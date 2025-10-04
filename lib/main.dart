import 'dart:async';
import 'package:LostAtKuet/chat_detail_screen.dart';
import 'package:LostAtKuet/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'Login_screen.dart';
import 'Splash_Screen.dart';
import 'supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

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
      _showSnackBar('Please enter a valid email address');
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
          'username': name.toLowerCase().replaceAll(' ', '_'),
        },
      );

      if (response.user != null) {
        await _createUserProfile(response.user!.id, name, email);
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
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  Future<void> _createUserProfile(String userId, String name, String email) async {
    await supabase.from('profiles').upsert({
      'id': userId,
      'name': name,
      'username': name.toLowerCase().replaceAll(' ', '_'),
      'email': email,
      'updated_at': DateTime.now().toIso8601String(),
    });
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
      MaterialPageRoute(builder: (context) => LoginScreen()),
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
import 'dart:async';

import 'package:LostAtKuet/Login_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'Splash_Screen.dart';
import 'supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase with your actual credentials
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
          background: Color(0xFFFFFFFF),
          onBackground: Color(0xFF292929),
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

  void _initializeAnimation() {
    Timer(const Duration(milliseconds: 500), () {
      setState(() {
        flag = true;
      });
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

    setState(() {
      isLoading = true;
    });

    try {
      final AuthResponse response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'username': name.toLowerCase(),
        },
      );

      if (response.user != null) {
        await _createUserProfile(response.user!.id, name, email);
        _showSnackBar('Registration successful! Please check your email for verification.');
        _navigateToLogin();
      }
    } on AuthException catch (error) {
      _showSnackBar(error.message);
    } catch (error) {
      _showSnackBar('An error occurred during registration');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _createUserProfile(String userId, String name, String email) async {
    await supabase.from('profiles').upsert({
      'id': userId,
      'name': name,
      'username': name.toLowerCase(),
      'email': email,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
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
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 1),
              _buildAnimatedLogo(),
              const SizedBox(height: 20),
              _buildTitle(),
              const Spacer(flex: 1),
              _buildNameField(),
              const SizedBox(height: 25),
              _buildEmailField(),
              const SizedBox(height: 25),
              _buildPasswordField(),
              const SizedBox(height: 30),
              _buildSignUpButton(),
              const SizedBox(height: 10),
              _buildLoginRedirect(),
              const Spacer(flex: 2),
            ],
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
      ),
      crossFadeState: flag ? CrossFadeState.showSecond : CrossFadeState.showFirst,
    );
  }

  Widget _buildTitle() {
    return Text(
      "Sign Up",
      style: TextStyle(
        fontSize: 40,
        color: const Color(0xFF292929),
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildNameField() {
    return TextField(
      controller: nameController,
      decoration: const InputDecoration(
        label: Text('Enter username'),
        prefixIcon: Icon(Icons.person_outline),
      ),
    );
  }

  Widget _buildEmailField() {
    return TextField(
      controller: emailController,
      decoration: const InputDecoration(
        label: Text('Enter email'),
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
        label: const Text('Set password'),
        prefixIcon: const Icon(Icons.lock),
        suffixIcon: IconButton(
          icon: Icon(
            isPasswordVisible ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: _togglePasswordVisibility,
        ),
      ),
    );
  }

  Widget _buildSignUpButton() {
    return SizedBox(
      width: 160,
      child: ElevatedButton(
        onPressed: isLoading ? null : _signUp,
        child: isLoading
            ? SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF292929)),
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
          child: const Text("Login"),
          onPressed: _navigateToLogin,
        ),
      ],
    );
  }
}
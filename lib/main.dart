import 'dart:async';

import 'package:LostAtKuet/Login_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'Login_screen.dart';
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
        scaffoldBackgroundColor: Color(0xFFFFFFFF),
        colorScheme: ColorScheme(
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
        textTheme: TextTheme(
          titleLarge: TextStyle(
            color: Color(0xFF292929),
            fontWeight: FontWeight.bold,
          ),
          bodyLarge: TextStyle(color: Color(0xFF292929)),
          bodyMedium: TextStyle(color: Color(0xFF585858)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          prefixIconColor: Color(0xFFFFC815),
          suffixIconColor: Color(0xFFFFC815),
          labelStyle: TextStyle(color: Color(0xFF585858)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(
              color: Color(0xFFFFC815),
              width: 2.0,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(
              color: Color(0xFF585858),
              width: 1.0,
            ),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFFFFC815),
            foregroundColor: Color(0xFF292929),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Color(0xFFFFC815),
          ),
        ),
      ),
      home: SplashScreen(),
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
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  bool isPasswordVisible = false;
  bool flag = false;
  bool isLoading = false;

  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    Timer(Duration(milliseconds: 500), () {
      setState(() {
        flag = true;
      });
    });
  }

  Future<void> _signUp() async {
    if (nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final AuthResponse response = await supabase.auth.signUp(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        data: {
          'name': nameController.text.trim(),
          'username': nameController.text.trim().toLowerCase(),
        },
      );

      if (response.user != null) {
        // Update user profile with additional data
        await supabase.from('profiles').upsert({
          'id': response.user!.id,
          'name': nameController.text.trim(),
          'username': nameController.text.trim().toLowerCase(),
          'email': emailController.text.trim(),
          'updated_at': DateTime.now().toIso8601String(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration successful! Please check your email for verification.')),
        );

        // Navigate to login screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      }
    } on AuthException catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred during registration')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Spacer(flex: 1),
              AnimatedCrossFade(
                firstChild: SizedBox.shrink(),
                duration: Duration(milliseconds: 500),
                secondChild: Image.asset(
                  "assets/images/lostatkuet_icon.png",
                  width: 100,
                  height: 100,
                ),
                crossFadeState:
                flag ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              ),
              SizedBox(height: 20),
              Text(
                "Sign Up",
                style: TextStyle(
                  fontSize: 40,
                  color: Color(0xFF292929),
                  fontWeight: FontWeight.bold,
                ),
              ),
              Spacer(flex: 1),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  label: Text('Enter username'),
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              SizedBox(height: 25),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  label: Text('Enter email'),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 25),
              TextField(
                controller: passwordController,
                obscureText: !isPasswordVisible,
                decoration: InputDecoration(
                  label: Text('Set password'),
                  prefixIcon: Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        isPasswordVisible = !isPasswordVisible;
                      });
                    },
                  ),
                ),
              ),
              SizedBox(height: 30),
              SizedBox(
                width: 160,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _signUp,
                  child: isLoading
                      ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF292929)),
                    ),
                  )
                      : Text("Create Account"),
                ),
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Already have an account?"),
                  TextButton(
                    child: Text("Login"),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LoginScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
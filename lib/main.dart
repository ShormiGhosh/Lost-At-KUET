import 'dart:async';

import 'package:LostAtKuet/Login_screen.dart';
import 'package:flutter/material.dart';

import 'Splash_Screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key}); // Default value for userId

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lost @ KUET',
        theme: ThemeData(
        // Base colors
        scaffoldBackgroundColor: Color(0xFFFFFFFF), // White background
    colorScheme: ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFFFFC815), // Yellow
    onPrimary: Color(0xFF292929), // Dark grey text on yellow
    secondary: Color(0xFF585858), // Light grey
    onSecondary: Color(0xFFFFFFFF), // White text on light grey
    surface: Color(0xFFFFFFFF), // White
    onSurface: Color(0xFF292929), // Dark grey
    background: Color(0xFFFFFFFF), // White
    onBackground: Color(0xFF292929), // Dark grey
    error: Colors.red,
    onError: Color(0xFFFFFFFF),
    ),
          // Text theme
          textTheme: TextTheme(
            titleLarge: TextStyle(
              color: Color(0xFF292929),
              fontWeight: FontWeight.bold,
            ),
            bodyLarge: TextStyle(color: Color(0xFF292929)),
            bodyMedium: TextStyle(color: Color(0xFF585858)),
          ),

          // Input decoration theme
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

          // Elevated button theme
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFFFC815),
              foregroundColor: Color(0xFF292929),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // Text button theme
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
  var emailController = TextEditingController();
  var passwordController = TextEditingController();
  var nameController = TextEditingController();
  bool isPasswordVisible = false;
  bool flag = false;

  @override
  void initState() {
    super.initState();
    Timer(Duration(milliseconds: 500), () {
      setState(() {
        flag = true;
      });
    });
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
                  child: Text("Create Account"),
                  onPressed: () {
                    // ... existing sign up logic ...
                  },
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
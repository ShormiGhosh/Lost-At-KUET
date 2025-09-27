import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'main.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool flag = false;
  bool textAnimationFlag = false;

  @override
  void initState() {
    super.initState();
    Timer(Duration(milliseconds: 500), () {
      setState(() {
        flag = true;
      });
      Future.delayed(Duration(milliseconds: 500), () {
        setState(() {
          textAnimationFlag = true;
        });
      });
    });
  }

  var usernameController = TextEditingController();
  var passController = TextEditingController();
  bool isPasswordVisible = false;

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
                sizeCurve: Curves.easeOut,
                crossFadeState:
                flag ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              ),
              SizedBox(height: 15),
              AnimatedOpacity(
                opacity: textAnimationFlag ? 1.0 : 0.0,
                duration: Duration(milliseconds: 500),
                child: Text(
                  "Lost @ KUET!",
                  style: TextStyle(
                    fontSize: 35,
                    color: Color(0xFF292929),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Spacer(flex: 1),
              TextField(
                controller: usernameController,
                decoration: InputDecoration(
                  hintText: 'Username',
                  hintStyle: TextStyle(color: Color(0xFF585858)),
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              SizedBox(height: 30),
              TextField(
                controller: passController,
                obscureText: !isPasswordVisible,
                decoration: InputDecoration(
                  hintText: 'Password',
                  hintStyle: TextStyle(color: Color(0xFF585858)),
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
                width: 100,
                child: ElevatedButton(
                  child: Text("Login"),
                  onPressed: () async {
                    // ... existing login logic ...
                  },
                ),
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don't have any account?"),
                  TextButton(
                    child: Text("Sign Up"),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MyHomePage(),
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
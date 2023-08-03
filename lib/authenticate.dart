import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:Smart_Student/HomeScreen.dart';

import 'package:flutter/services.dart';
import 'package:email_validator/email_validator.dart';
import 'package:Smart_Student/Register.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isEmailValid = true;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _validateEmail(String email) {
    setState(() {
      _isEmailValid = EmailValidator.validate(email);
    });
  }

  void _loginUser(BuildContext context) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      // Login successful, navigate to home screen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Login failed. Please check your email and password.',
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Image.asset(
              'assets/logo.png',
              height: 250,
              width: 250,
            ),
            SizedBox(height: 32.0),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                errorText: _isEmailValid ? null : 'Invalid email format',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              onChanged: (value) => _validateEmail(value),
              keyboardType: TextInputType.emailAddress,
              inputFormatters: [FilteringTextInputFormatter.singleLineFormatter],
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
            ),
            SizedBox(height: 16.0),
            ElevatedButton.icon(
              icon: Icon(Icons.login),
              label: Text('Login'),
              onPressed: () => _loginUser(context),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16.0),
              ),
            ),
            SizedBox(height: 8.0),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RegisterScreen()),
                );
              },
              child: Text(
                "Not a member? Register now",
                style: TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}



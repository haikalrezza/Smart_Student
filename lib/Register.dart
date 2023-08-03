import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:email_validator/email_validator.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isEmailValid = true;
  bool _isPasswordValid = true;
  bool _isPasswordMatched = true;

  void _validateEmail(String email) {
    setState(() {
      _isEmailValid = EmailValidator.validate(email);
    });
  }

  void _validatePassword(String password) {
    setState(() {
      _isPasswordValid = password.length >= 6;
    });
  }

  void _validateConfirmPassword(String confirmPassword) {
    String password = _passwordController.text;
    setState(() {
      _isPasswordMatched = password == confirmPassword;
    });
  }

  void _registerUser(BuildContext context) async {
    try {
      String email = _emailController.text;
      String password = _passwordController.text;
      String confirmPassword = _confirmPasswordController.text;

      if (!_isEmailValid || !_isPasswordValid || !_isPasswordMatched) {
        Fluttertoast.showToast(
          msg: 'Please fix the validation errors.',
          gravity: ToastGravity.BOTTOM,
        );
        return;
      }

      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Registration successful, navigate to home screen or any other screen
      // as desired
      Navigator.pop(context);
      Fluttertoast.showToast(
        msg: 'Registration successful.',
        gravity: ToastGravity.BOTTOM,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Registration failed. Please try again later.',
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
                errorText: _isEmailValid ? null : 'Invalid email format',
              ),
              keyboardType: TextInputType.emailAddress,
              onChanged: (value) => _validateEmail(value),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
                errorText: _isPasswordValid ? null : 'Password should be at least 6 characters',
              ),
              obscureText: true,
              onChanged: (value) => _validatePassword(value),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _confirmPasswordController,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
                errorText: _isPasswordMatched ? null : 'Passwords do not match',
              ),
              obscureText: true,
              onChanged: (value) => _validateConfirmPassword(value),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              child: Text('Register'),
              onPressed: () => _registerUser(context),
            ),
          ],
        ),
      ),
    );
  }
}

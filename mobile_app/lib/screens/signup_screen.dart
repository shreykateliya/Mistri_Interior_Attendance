import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  bool _isLoading = false;

  Future<void> _signUp() async {
    setState(() => _isLoading = true);
    try {
      var response = await http.post(
        Uri.parse(Config.signup), // <--- FIXED: Added comma here
        body: {
          "username": _userController.text.trim(),
          "password": _passController.text.trim()
        },
      );
      
      var data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Account Created! Please Login.")));
          Navigator.pop(context); // Go back to Login
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'])));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Connection Error")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("New Employee Sign Up")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: _userController, decoration: const InputDecoration(labelText: "Full Name")),
            const SizedBox(height: 10),
            TextField(controller: _passController, decoration: const InputDecoration(labelText: "Create Password")),
            const SizedBox(height: 20),
            _isLoading 
            ? const CircularProgressIndicator()
            : ElevatedButton(onPressed: _signUp, child: const Text("CREATE ACCOUNT")),
          ],
        ),
      ),
    );
  }
}
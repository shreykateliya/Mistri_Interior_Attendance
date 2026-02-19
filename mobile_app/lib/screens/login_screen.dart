import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'attendance_screen.dart';
import 'admin_screen.dart';
import 'signup_screen.dart'; 
import 'forgot_password_screen.dart';
import '../config.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState(); // <--- FIXED
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  String _message = "";
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);
    
    try {
      var response = await http.post(
        Uri.parse(Config.login),
        body: {
          "username": _userController.text.trim(),
          "password": _passController.text.trim() 
        },
      );

      if (!mounted) return; // <--- FIXED ASYNC GAP

      var data = jsonDecode(response.body);

      if (data['status'] == 'success') {
        if (data['role'] == 'admin') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminScreen()));
        } else {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => AttendanceScreen(
            id: data['id'], 
            username: data['username'],
            profilePic: data['profile_pic'],      
            initialStatus: data['current_status'] 
          )));
        }
      } else {
        setState(() => _message = "❌ Login Failed: ${data['message']}");
      }
    } catch (e) {
      if (mounted) setState(() => _message = "Connection Error. Check IP in config.dart");
      debugPrint("Login Error: $e"); // <--- FIXED
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.maps_home_work, size: 80, color: Colors.blueAccent),
            const SizedBox(height: 20),
            const Text("MISTRI INTERIOR", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
            
            TextField(
              controller: _userController, 
              decoration: const InputDecoration(labelText: "Enter Name (Admin or Worker)", border: OutlineInputBorder())
            ),
            const SizedBox(height: 15),
            
            TextField(
              controller: _passController, 
              obscureText: true, 
              decoration: const InputDecoration(labelText: "Password", border: OutlineInputBorder())
            ),
            const SizedBox(height: 25),
            
            _isLoading 
            ? const CircularProgressIndicator()
            : SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _login,
                  child: const Text("LOGIN", style: TextStyle(fontSize: 18)),
                ),
              ),
            const SizedBox(height: 20),
            
            TextButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SignUpScreen()));
              },
              child: const Text("New Employee? Sign Up Here"),
            ),
            
            TextButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()));
              },
              child: const Text("Forgot Password?", style: TextStyle(color: Colors.grey)),
            ),

            const SizedBox(height: 10),
            Text(_message, style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}
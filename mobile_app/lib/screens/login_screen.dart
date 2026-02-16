import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'attendance_screen.dart';
import 'admin_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  String _message = "";
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);
    // REMEMBER: Check if your IP is still 192.168.1.6
    final String url = "http://192.168.1.6:8000/api/login/";
    
    try {
      var response = await http.post(
        Uri.parse(url),
        body: {
          "username": _userController.text.trim(),
          "password": _passController.text.trim() 
        },
      );

      var data = jsonDecode(response.body);

      if (data['status'] == 'success') {
        if (data['role'] == 'admin') {
          // Go to Admin Dashboard
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminScreen()));
        } else {
          // --- THIS IS THE CHANGE ---
          // Go to Employee Dashboard AND pass the extra data (Pic & Status)
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => AttendanceScreen(
            username: data['username'],
            profilePic: data['profile_pic'],      // <--- NEW: Pass Profile Pic
            initialStatus: data['current_status'] // <--- NEW: Pass 'IN' or 'OUT'
          )));
        }
      } else {
        setState(() => _message = "❌ Login Failed: ${data['message']}");
      }
    } catch (e) {
      setState(() => _message = "Connection Error. Check IP.");
    } finally {
      setState(() => _isLoading = false);
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
              decoration: const InputDecoration(labelText: "Password (Leave empty for Workers)", border: OutlineInputBorder())
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
            const SizedBox(height: 15),
            Text(_message, style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}
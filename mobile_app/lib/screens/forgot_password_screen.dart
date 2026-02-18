import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _userController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPassController = TextEditingController();
  
  bool _otpSent = false;
  bool _isLoading = false;

  // Step 1: Request OTP
  Future<void> _sendOTP() async {
    if (_userController.text.isEmpty) return;
    setState(() => _isLoading = true);

    try {
      var response = await http.post(
        Uri.parse("http://192.168.1.4:8000/api/forgot-password/"),
        body: {"username": _userController.text.trim()}
      );
      var data = jsonDecode(response.body);

      if (data['status'] == 'success') {
        setState(() => _otpSent = true);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'])));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'])));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Connection Error")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Step 2: Confirm Reset
  Future<void> _resetPassword() async {
    setState(() => _isLoading = true);
    try {
      var response = await http.post(
        Uri.parse("http://192.168.1.6:8000/api/reset-password-confirm/"),
        body: {
          "username": _userController.text.trim(),
          "otp": _otpController.text.trim(),
          "new_password": _newPassController.text.trim()
        }
      );
      var data = jsonDecode(response.body);

      if (data['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password Reset! Please Login.")));
        Navigator.pop(context); // Go back to Login
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'])));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error Resetting Password")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Reset Password")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text("Enter your username to receive an OTP code.", textAlign: TextAlign.center),
            const SizedBox(height: 20),
            
            TextField(
              controller: _userController, 
              decoration: const InputDecoration(labelText: "Enter Username", border: OutlineInputBorder()),
              enabled: !_otpSent, // Disable after OTP sent
            ),
            const SizedBox(height: 20),

            if (!_otpSent)
              _isLoading 
                ? const CircularProgressIndicator()
                : ElevatedButton(onPressed: _sendOTP, child: const Text("SEND OTP CODE")),

            if (_otpSent) ...[
              const Divider(),
              const Text("OTP Sent! Check Admin Console or Email.", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextField(
                controller: _otpController, 
                decoration: const InputDecoration(labelText: "Enter 4-Digit OTP", border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _newPassController, 
                decoration: const InputDecoration(labelText: "New Password", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),
              _isLoading 
                ? const CircularProgressIndicator()
                : ElevatedButton(onPressed: _resetPassword, style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text("RESET PASSWORD", style: TextStyle(color: Colors.white))),
            ]
          ],
        ),
      ),
    );
  }
}
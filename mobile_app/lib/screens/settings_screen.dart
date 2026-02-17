import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  final int userId;
  final String role; // 'admin' or 'employee'

  const SettingsScreen({super.key, required this.userId, required this.role});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _passController = TextEditingController();
  bool _isLoading = false;

  // 1. Change Password
  Future<void> _changePassword() async {
    if (_passController.text.isEmpty) return;
    setState(() => _isLoading = true);
    
    // CHANGE IP HERE IF NEEDED
    try {
      await http.post(
        Uri.parse("http://192.168.1.6:8000/api/change-password/"),
        body: {
          "id": widget.userId.toString(),
          "role": widget.role,
          "new_password": _passController.text.trim()
        }
      );
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password Changed Successfully!")));
      _passController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error changing password")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 2. Upload Profile Pic
  Future<void> _updateProfilePic() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() => _isLoading = true);
      var request = http.MultipartRequest('POST', Uri.parse("http://192.168.1.6:8000/api/update-profile-pic/"));
      request.fields['id'] = widget.userId.toString();
      request.files.add(await http.MultipartFile.fromPath('profile_pic', pickedFile.path));
      
      var response = await request.send();
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile Pic Updated! (Re-login to see changes)")));
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (widget.role == 'employee') ...[
              ElevatedButton.icon(
                onPressed: _updateProfilePic, 
                icon: const Icon(Icons.image), 
                label: const Text("Upload Profile Picture")
              ),
              const Divider(),
            ],
            
            const Text("Change Password", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(controller: _passController, decoration: const InputDecoration(labelText: "New Password")),
            const SizedBox(height: 10),
            _isLoading 
              ? const CircularProgressIndicator()
              : ElevatedButton(onPressed: _changePassword, child: const Text("UPDATE PASSWORD")),
            
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false),
              child: const Text("Log Out", style: TextStyle(color: Colors.red)),
            )
          ],
        ),
      ),
    );
  }
}
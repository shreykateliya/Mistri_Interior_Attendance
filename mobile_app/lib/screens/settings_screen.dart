import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'login_screen.dart';
import '../config.dart';

class SettingsScreen extends StatefulWidget {
  final int userId;
  final String role; 

  const SettingsScreen({super.key, required this.userId, required this.role});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState(); // <--- FIXED
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _passController = TextEditingController();
  bool _isLoading = false;

  Future<void> _changePassword() async {
    if (_passController.text.isEmpty) return;
    setState(() => _isLoading = true);
    
    try {
      await http.post(
        Uri.parse(Config.changePassword),
        body: {
          "id": widget.userId.toString(),
          "role": widget.role,
          "new_password": _passController.text.trim()
        }
      );

      if (!mounted) return; // <--- FIXED ASYNC GAP
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password Changed Successfully!")));
      _passController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error changing password")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfilePic() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() => _isLoading = true);
      
      var request = http.MultipartRequest('POST', Uri.parse(Config.updateProfilePic));
      request.fields['id'] = widget.userId.toString();
      request.files.add(await http.MultipartFile.fromPath('profile_pic', pickedFile.path));
      
      try {
        var response = await request.send();
        if (!mounted) return; // <--- FIXED ASYNC GAP
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile Pic Updated! (Re-login to see changes)")));
        }
      } catch (e) {
         debugPrint("Error: $e"); // <--- FIXED
      }
      if (mounted) setState(() => _isLoading = false);
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
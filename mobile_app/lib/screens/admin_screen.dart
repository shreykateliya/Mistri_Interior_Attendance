import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_screen.dart';
import 'report_screen.dart'; 
import '../config.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState(); // <--- FIXED
}

class _AdminScreenState extends State<AdminScreen> {
  List employees = [];
  bool _isLoading = true;

  String? _getValidImageUrl(String url) {
    if (url.isEmpty) return null;
    if (url.startsWith('http')) return url;
    return "${Config.baseUrl}$url";
  }

  @override
  void initState() {
    super.initState();
    _fetchDashboard();
  }

  Future<void> _fetchDashboard() async {
    try {
      var response = await http.get(Uri.parse(Config.adminDashboard));
      if (mounted) {
        setState(() {
          employees = jsonDecode(response.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error: $e"); // <--- FIXED
    }
  }

  Future<void> _forceLogout(int empId, String name) async {
    await http.post(Uri.parse(Config.forceLogout), body: {"employee_id": empId.toString()});
    
    if (!mounted) return; // <--- FIXED ASYNC GAP
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Forced logout for $name")));
    
    _fetchDashboard(); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mistri Admin"),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchDashboard),
          IconButton(icon: const Icon(Icons.logout), onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()))),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            itemCount: employees.length,
            itemBuilder: (context, index) {
              var emp = employees[index];
              bool isWorking = emp['is_working'];
              String? profileUrl = _getValidImageUrl(emp['profile_pic']);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  onTap: () {
                     Navigator.push(context, MaterialPageRoute(builder: (_) => ReportScreen(userId: emp['id'], role: 'admin')));
                  },
                  leading: CircleAvatar(
                    backgroundImage: profileUrl != null 
                        ? NetworkImage(profileUrl) 
                        : null,
                    child: profileUrl == null ? const Icon(Icons.person) : null,
                  ),
                  title: Text(emp['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(isWorking ? "🟢 Working Now" : "⚪ Offline (Last: ${emp['last_seen']})"),
                  trailing: isWorking 
                    ? TextButton(
                        onPressed: () => _forceLogout(emp['id'], emp['name']),
                        child: const Text("Force Out", style: TextStyle(color: Colors.red)),
                      )
                    : const Icon(Icons.check_circle, color: Colors.grey),
                ),
              );
            },
          ),
    );
  }
}
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; 
import 'login_screen.dart';
import 'settings_screen.dart';
import 'report_screen.dart'; 
import '../config.dart';

class AttendanceScreen extends StatefulWidget {
  final int id;
  final String username;
  final String profilePic;
  final String initialStatus;

  const AttendanceScreen({
    super.key, 
    required this.id, 
    required this.username, 
    required this.profilePic,
    required this.initialStatus
  });

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState(); // <--- FIXED
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  String _currentStatus = "OUT"; 
  String _timeString = "";
  bool _isLoading = false;
  Timer? _timer; 

  String? _getValidImageUrl(String url) {
    if (url.isEmpty) return null;
    if (url.startsWith('http')) return url;
    return "${Config.baseUrl}$url";
  }

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.initialStatus;
    _timeString = _formatDateTime(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) => _getTime());
  }

  @override
  void dispose() {
    _timer?.cancel(); 
    super.dispose();
  }

  void _getTime() {
    final DateTime now = DateTime.now();
    if (mounted) {
      setState(() {
        _timeString = _formatDateTime(now);
      });
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('hh:mm:ss a').format(dateTime);
  }

  Future<void> _handlePunch(String type) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera, imageQuality: 30);
    
    if (pickedFile == null) return;

    if (mounted) setState(() => _isLoading = true);

    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

      var uri = Uri.parse(Config.punchIn); 
      var request = http.MultipartRequest('POST', uri);
      
      request.fields['employee_id'] = widget.username;
      request.fields['type'] = type; 
      request.fields['latitude'] = position.latitude.toString();
      request.fields['longitude'] = position.longitude.toString();
      
      request.files.add(await http.MultipartFile.fromPath('live_photo', pickedFile.path));

      // 1. First Async Call
      var response = await request.send();
      
      // 2. Second Async Call (Read error body if it failed)
      String responseBody = "";
      if (response.statusCode != 201 && response.statusCode != 200) {
        responseBody = await response.stream.bytesToString();
      }

      // --- ALL AWAITS ARE DONE. NOW WE CHECK MOUNTED ONCE. ---
      if (!mounted) return; 

      if (response.statusCode == 201 || response.statusCode == 200) {
        setState(() {
          _currentStatus = type; 
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Successfully Punched $type!"), 
          backgroundColor: type == 'IN' ? Colors.green : Colors.red
        ));
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed: $responseBody")));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isPunchedIn = _currentStatus == 'IN';
    String? validProfileUrl = _getValidImageUrl(widget.profilePic);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("My Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => ReportScreen(userId: widget.id, role: 'employee')));
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen(userId: widget.id, role: 'employee')));
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout), 
            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()))
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey[300],
              backgroundImage: validProfileUrl != null 
                  ? NetworkImage(validProfileUrl) 
                  : null, 
              child: validProfileUrl == null 
                  ? const Icon(Icons.person, size: 60, color: Colors.grey) 
                  : null,
            ),
            const SizedBox(height: 15),
            Text(widget.username, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isPunchedIn ? Colors.green[100] : Colors.grey[300],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isPunchedIn ? "Currently Working" : "Currently Offline",
                style: TextStyle(color: isPunchedIn ? Colors.green[800] : Colors.grey[800], fontWeight: FontWeight.bold),
              ),
            ),
            
            const SizedBox(height: 30),
            Text(_timeString, style: const TextStyle(fontSize: 45, fontWeight: FontWeight.w300, fontFamily: 'monospace')),
            const SizedBox(height: 30),

            _isLoading 
              ? const CircularProgressIndicator()
              : SizedBox(
                  width: 200,
                  height: 60,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPunchedIn ? Colors.red : Colors.green, 
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    onPressed: () => _handlePunch(isPunchedIn ? 'OUT' : 'IN'),
                    child: Text(
                      isPunchedIn ? "PUNCH OUT" : "PUNCH IN",
                      style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            
            const SizedBox(height: 30),
            
            TextButton.icon(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => ReportScreen(userId: widget.id, role: 'employee')));
              }, 
              icon: const Icon(Icons.calendar_month, size: 28), 
              label: const Text("View My Attendance History", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
            )
          ],
        ),
      ),
    );
  }
}
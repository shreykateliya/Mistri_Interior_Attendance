import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; 
import 'login_screen.dart';

class AttendanceScreen extends StatefulWidget {
  final String username;
  final String profilePic;
  final String initialStatus; // 'IN' or 'OUT'

  const AttendanceScreen({
    super.key, 
    required this.username, 
    required this.profilePic,
    required this.initialStatus
  });

  @override
  _AttendanceScreenState createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  String _currentStatus = "OUT"; 
  String _timeString = "";
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.initialStatus;
    _timeString = _formatDateTime(DateTime.now());
    Timer.periodic(const Duration(seconds: 1), (Timer t) => _getTime());
  }

  void _getTime() {
    final DateTime now = DateTime.now();
    final String formattedDateTime = _formatDateTime(now);
    if (mounted) {
      setState(() {
        _timeString = formattedDateTime;
      });
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('hh:mm:ss a').format(dateTime);
  }

  Future<void> _handlePunch(String type) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera, imageQuality: 40);
    
    if (pickedFile == null) return;

    setState(() => _isLoading = true);

    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

      // CHANGE THIS IP IF YOUR WIFI CHANGES
      var uri = Uri.parse("http://192.168.1.6:8000/api/punch-in/"); 
      var request = http.MultipartRequest('POST', uri);
      
      request.fields['employee_id'] = widget.username;
      request.fields['type'] = type; 
      request.fields['latitude'] = position.latitude.toString();
      request.fields['longitude'] = position.longitude.toString();
      request.files.add(await http.MultipartFile.fromPath('live_photo', pickedFile.path));

      var response = await request.send();

      if (response.statusCode == 201) {
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Server Error!")));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isPunchedIn = _currentStatus == 'IN';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("My Dashboard"),
        actions: [
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
            // --- FIX IS HERE ---
            // If photo exists, show it. If not, show a Person Icon.
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey[300],
              backgroundImage: widget.profilePic.isNotEmpty 
                  ? NetworkImage(widget.profilePic) 
                  : null, // No image? No problem.
              child: widget.profilePic.isEmpty 
                  ? const Icon(Icons.person, size: 60, color: Colors.grey) // Show Icon instead
                  : null,
            ),
            // -------------------
            
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
            
            const SizedBox(height: 40),
            
            // Digital Clock
            Text(_timeString, style: const TextStyle(fontSize: 45, fontWeight: FontWeight.w300, fontFamily: 'monospace')),
            const SizedBox(height: 50),

            // Toggle Button
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
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../config.dart';

class ReportScreen extends StatefulWidget {
  final int userId;
  final String role; // 'admin' or 'employee'

  const ReportScreen({super.key, required this.userId, required this.role});

  @override
  _ReportScreenState createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  DateTime _focusedDay = DateTime.now();
  Map<String, dynamic> _reportData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchReport();
  }

  Future<void> _fetchReport() async {
    setState(() => _isLoading = true);
    final url = "${Config.monthlyReport}?employee_id=${widget.userId}&month=${_focusedDay.month}&year=${_focusedDay.year}";
    
    try {
      var response = await http.get(Uri.parse(url));
      if (mounted) {
        setState(() {
          _reportData = jsonDecode(response.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  // Generate PDF (Whole Month)
  Future<void> _generatePdf() async {
    final doc = pw.Document();
    final List<dynamic> dailyData = _reportData['daily_data'];
    final summary = _reportData['summary'];

    doc.addPage(pw.Page(
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text("Mistri Interior - Attendance Report", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Text("Employee: ${_reportData['employee']}", style: const pw.TextStyle(fontSize: 18)),
            pw.Text("Month: ${_focusedDay.month}/${_focusedDay.year}"),
            pw.SizedBox(height: 10),
            pw.Text("Summary: Present: ${summary['total_present']} | Absent: ${summary['total_absent']} | Forgot Out: ${summary['forgot_out']}"),
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              headers: ['Date', 'Status', 'Time Details'],
              data: dailyData.map((day) => [day['date'], day['status'], day['details']]).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignment: pw.Alignment.centerLeft,
            ),
          ]
        );
      },
    ));

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => doc.save());
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    var summary = _reportData['summary'];
    List dailyData = _reportData['daily_data'];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Monthly Report"),
        actions: [
          IconButton(icon: const Icon(Icons.picture_as_pdf), onPressed: _generatePdf)
        ],
      ),
      body: Column(
        children: [
          // 1. Calendar
          TableCalendar(
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.now(), // Stop at today to avoid future scrolling if desired
            focusedDay: _focusedDay,
            calendarFormat: CalendarFormat.month,
            onPageChanged: (focusedDay) {
              setState(() => _focusedDay = focusedDay);
              _fetchReport();
            },
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                // Find status for this date
                var dayData = dailyData.firstWhere((d) => d['day'] == date.day, orElse: () => null);
                
                if (dayData != null) {
                  Color color = Colors.transparent;
                  if (dayData['status'] == 'Present') color = Colors.green;
                  if (dayData['status'] == 'Absent') color = Colors.red;
                  if (dayData['status'] == 'Forgot Out') color = Colors.orange;
                  if (dayData['status'] == 'Forced Out') color = Colors.purple; // New Color
                  
                  return Positioned(
                    bottom: 1,
                    child: Container(
                      width: 6, height: 6,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                  );
                }
                return null;
              },
            ),
          ),
          
          const Divider(),
          
          // 2. Summary Cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _summaryCard("Present", "${summary['total_present']}", Colors.green),
                _summaryCard("Absent", "${summary['total_absent']}", Colors.red),
                _summaryCard("Missed", "${summary['forgot_out']}", Colors.orange),
                _summaryCard("Forced", "${summary['forced_out'] ?? 0}", Colors.purple), // New Card
              ],
            ),
          ),
          
          const Divider(),
          
          // 3. List View
          Expanded(
            child: ListView.builder(
              itemCount: dailyData.length,
              itemBuilder: (context, index) {
                var day = dailyData[index];
                
                // Colors for text
                Color statusColor = Colors.grey;
                if (day['status'] == 'Present') statusColor = Colors.green;
                if (day['status'] == 'Absent') statusColor = Colors.red;
                if (day['status'] == 'Forgot Out') statusColor = Colors.orange;
                if (day['status'] == 'Forced Out') statusColor = Colors.purple;

                return ListTile(
                  leading: Text(day['date'].toString().substring(8), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  title: Text(day['status'], style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
                  subtitle: Text(day['details']),
                  // Deleted the Trailing Delete Button here
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(String title, String count, Color color) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            children: [
              Text(count, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
              Text(title, style: const TextStyle(fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}
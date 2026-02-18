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
    // CHANGE IP
    final url = "${Config.monthlyReport}?employee_id=${widget.userId}&month=${_focusedDay.month}&year=${_focusedDay.year}";
    
    try {
      var response = await http.get(Uri.parse(url));
      setState(() {
        _reportData = jsonDecode(response.body);
        _isLoading = false;
      });
    } catch (e) {
      print("Error: $e");
    }
  }

  // Generate PDF
  Future<void> _generatePdf() async {
    final doc = pw.Document();
    final List<dynamic> dailyData = _reportData['daily_data'];

    doc.addPage(pw.Page(
      build: (pw.Context context) {
        return pw.Column(
          children: [
            pw.Text("Mistri Interior - Attendance Report", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 20),
            pw.Text("Employee: ${_reportData['employee']}"),
            pw.Text("Month: ${_focusedDay.month}/${_focusedDay.year}"),
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              headers: ['Date', 'Status', 'Time Details'],
              data: dailyData.map((day) => [day['date'], day['status'], day['details']]).toList(),
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
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: CalendarFormat.month,
            onPageChanged: (focusedDay) {
              setState(() => _focusedDay = focusedDay);
              _fetchReport(); // Reload data when month changes
            },
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                // Find status for this date
                var dayData = dailyData.firstWhere((d) => d['day'] == date.day, orElse: () => null);
                if (dayData != null) {
                  Color color = Colors.grey;
                  if (dayData['status'] == 'Present') color = Colors.green;
                  if (dayData['status'] == 'Absent') color = Colors.red;
                  if (dayData['status'] == 'Forgot Out') color = Colors.orange;
                  
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _summaryCard("Present", "${summary['total_present']}", Colors.green),
              _summaryCard("Absent", "${summary['total_absent']}", Colors.red),
              _summaryCard("Forgot Out", "${summary['forgot_out']}", Colors.orange),
            ],
          ),
          
          const Divider(),
          
          // 3. List View
          Expanded(
            child: ListView.builder(
              itemCount: dailyData.length,
              itemBuilder: (context, index) {
                var day = dailyData[index];
                if (day['status'] == 'Absent') return const SizedBox.shrink(); // Hide absent days in list to save space
                
                return ListTile(
                  leading: Text(day['date'].toString().substring(8), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  title: Text(day['status'], style: TextStyle(
                    color: day['status'] == 'Present' ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.bold
                  )),
                  subtitle: Text(day['details']),
                  trailing: widget.role == 'admin' 
                    ? IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                           // Admin Delete Logic Here (Call API)
                        },
                      ) 
                    : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(String title, String count, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text(count, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            Text(title, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
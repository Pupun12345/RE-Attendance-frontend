import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart'; // <-- New import
import 'dart:convert';
import 'package:smartcare_app/utils/constants.dart';

// Model for our Holiday data
class Holiday {
  final String title;
  final DateTime date;
  final String type; // 'national' or 'company'

  Holiday({required this.title, required this.date, required this.type});

  factory Holiday.fromJson(Map<String, dynamic> json) {
    return Holiday(
      title: json['name'],
      date: DateTime.parse(json['date']),
      type: json['type'],
    );
  }
}

class HolidayCalendarScreen extends StatefulWidget {
  HolidayCalendarScreen({super.key});

  @override
  State<HolidayCalendarScreen> createState() => _HolidayCalendarScreenState();
}

class _HolidayCalendarScreenState extends State<HolidayCalendarScreen> {
  final Color themeBlue = const Color(0xFF0B3B8C);

  // --- IMPORTANT ---
  // Make sure this is the same IP address you used in the login screen
  //final String _apiUrl = "http://10.5.114.51:5000"; // <-- REPLACE WITH YOUR IP
  final String _apiUrl = apiBaseUrl;

  List<Holiday> _holidays = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchHolidays();
  }

  Future<void> _fetchHolidays() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.get(
        Uri.parse("$_apiUrl/api/v1/holidays"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        List<dynamic> holidaysJson = responseData['holidays'];
        setState(() {
          _holidays = holidaysJson.map((json) => Holiday.fromJson(json)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = "Failed to load holidays.";
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = "Could not connect to server. Check your network.";
        _isLoading = false;
      });
    }
  }

  // Helper function to format the date
  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date); // e.g., "15 Aug 2025"
  }

  // Helper function to get an icon
  IconData _getIconForType(String type) {
    return type == 'national' 
      ? Icons.flag_rounded 
      : Icons.business_center_rounded;
  }
  
  Color _getColorForType(String type) {
    return type == 'national' 
      ? Colors.green 
      : Colors.orange;
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!, style: const TextStyle(color: Colors.red)));
    }
    if (_holidays.isEmpty) {
      return const Center(child: Text("No holidays found."));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _holidays.length,
      itemBuilder: (context, index) {
        final item = _holidays[index];
        final icon = _getIconForType(item.type);
        final color = _getColorForType(item.type);

        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(item.date),
                    style: const TextStyle(
                        fontSize: 14, color: Colors.black54),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      appBar: AppBar(
        backgroundColor: themeBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          "Holiday Calendar",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: _buildBody(),
    );
  }
}
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartcare_app/utils/constants.dart';

// Model to hold holiday data
class Holiday {
  final String id;
  final String name;
  final DateTime date;
  final String type;

  Holiday({required this.id, required this.name, required this.date, required this.type});

  factory Holiday.fromJson(Map<String, dynamic> json) {
    return Holiday(
      id: json['_id'],
      name: json['name'],
      date: DateTime.parse(json['date']),
      type: json['type'] ?? 'company',
    );
  }
}

class AdminHolidaySetupScreen extends StatefulWidget {
  const AdminHolidaySetupScreen({super.key});

  @override
  State<AdminHolidaySetupScreen> createState() =>
      _AdminHolidaySetupScreenState();
}

class _AdminHolidaySetupScreenState extends State<AdminHolidaySetupScreen> {
  final Color primaryBlue = const Color(0xFF0D47A1);
  final Color lightGrey = Colors.grey.shade100;

  List<Holiday> _holidays = [];
  bool _isLoading = true;
  String? _token;

  bool _showAddForm = false;
  DateTime? _selectedDate;
  final TextEditingController _holidayNameController = TextEditingController();
  String _selectedType = 'company';

  @override
  void initState() {
    super.initState();
    _fetchHolidays();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  Future<void> _fetchHolidays() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('token');
      if (_token == null) {
        _showError("Not authorized.");
        return;
      }

      final url = Uri.parse('$apiBaseUrl/api/v1/holidays');
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $_token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _holidays = (data['holidays'] as List)
              .map((h) => Holiday.fromJson(h))
              .toList();
        });
      } else {
        _showError("Failed to load holidays.");
      }
    } catch (e) {
      _showError("An error occurred: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme:
                ColorScheme.light(primary: primaryBlue, onPrimary: Colors.white),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _saveHoliday() async {
    if (_selectedDate == null || _holidayNameController.text.isEmpty) {
      _showError("Please enter holiday name and select a date.");
      return;
    }

    if (_token == null) {
      _showError("Not authorized. Please restart the app.");
      return;
    }

    try {
      final url = Uri.parse('$apiBaseUrl/api/v1/holidays');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': _holidayNameController.text.trim(),
          'date': _selectedDate!.toIso8601String(),
          'type': _selectedType,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        _fetchHolidays(); // Refresh the list
        setState(() {
          _holidayNameController.clear();
          _selectedDate = null;
          _showAddForm = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Holiday added successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        _showError(data['message'] ?? 'Failed to save holiday.');
      }
    } catch (e) {
      _showError("An error occurred: ${e.toString()}");
    }
  }

  Future<void> _deleteHoliday(String holidayId) async {
    if (_token == null) {
      _showError("Not authorized.");
      return;
    }

    try {
      final url = Uri.parse('$apiBaseUrl/api/v1/holidays/$holidayId');
      final response = await http.delete(
        url,
        headers: {'Authorization': 'Bearer $_token'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        _fetchHolidays(); // Refresh the list
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Holiday deleted successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        _showError(data['message'] ?? 'Failed to delete holiday.');
      }
    } catch (e) {
      _showError("An error occurred: ${e.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGrey,
      appBar: AppBar(
        // ... (App Bar is the same) ...
// ...
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        title: Text(
          "Holiday Setup",
          style: TextStyle(
            color: primaryBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.bell, color: primaryBlue),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: CircleAvatar(
              backgroundImage: const AssetImage("assets/images/profile.png"),
              radius: 18,
              backgroundColor: Colors.grey[300],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Company Holidays",
              style: TextStyle(
                color: primaryBlue,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _holidays.isEmpty
                    ? const Center(child: Text("No holidays added yet."))
                    : Column(
                        children: _holidays.map((holiday) {
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 2,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue[50],
                                child: Icon(LucideIcons.calendar,
                                    color: primaryBlue),
                              ),
                              title: Text(
                                DateFormat("MMM dd, yyyy").format(holiday.date),
                                style: TextStyle(
                                  color: primaryBlue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                holiday.name,
                                style: const TextStyle(color: Colors.black54),
                              ),
                              trailing: IconButton(
                                icon: const Icon(LucideIcons.trash2,
                                    color: Colors.redAccent),
                                onPressed: () => _deleteHoliday(holiday.id),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
            const SizedBox(height: 20),

            // 🔹 Pick a Date Button
            OutlinedButton.icon(
              onPressed: () {
                setState(() => _showAddForm = !_showAddForm);
              },
              icon: Icon(
                  _showAddForm ? LucideIcons.x : LucideIcons.calendarDays,
                  color: primaryBlue),
              label: Text(_showAddForm ? "Cancel" : "Add New Holiday"),
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                side: BorderSide(color: primaryBlue),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            // 🔹 Show Add Holiday Form
            if (_showAddForm) ...[
              const SizedBox(height: 16),
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 3,
                shadowColor: Colors.black26,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🔸 Holiday Name Field
                      TextFormField(
                        controller: _holidayNameController,
                        decoration: InputDecoration(
                          labelText: "Holiday Name",
                          labelStyle: TextStyle(color: primaryBlue),
                          icon: Icon(LucideIcons.calendar, color: primaryBlue),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: primaryBlue),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 🔸 Holiday Type Dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedType,
                        decoration: InputDecoration(
                          labelText: 'Holiday Type',
                          labelStyle: TextStyle(color: primaryBlue),
                          icon: Icon(LucideIcons.tag, color: primaryBlue),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: primaryBlue),
                          ),
                        ),
                        items: ['company', 'national']
                            .map((role) => DropdownMenuItem(
                                  value: role,
                                  child: Text(
                                      role[0].toUpperCase() + role.substring(1)),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedType = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 20),

                      // 🔸 Date Picker Row
                      Row(
                        children: [
                          Icon(LucideIcons.clock, color: primaryBlue),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: _pickDate,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: Colors.grey.shade400, width: 1),
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.white,
                                ),
                                child: Text(
                                  _selectedDate == null
                                      ? "Select Date"
                                      : DateFormat("MMM dd, yyyy")
                                          .format(_selectedDate!),
                                  style: TextStyle(
                                    color: _selectedDate == null
                                        ? Colors.black54
                                        : primaryBlue,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // 🔸 Save Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _saveHoliday,
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: const Text(
                            "Save Holiday",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
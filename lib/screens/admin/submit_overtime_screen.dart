// lib/screens/submit_overtime_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../utils/constants.dart';

class SubmitOvertimeScreen extends StatefulWidget {
  const SubmitOvertimeScreen({super.key});

  @override
  State<SubmitOvertimeScreen> createState() => _SubmitOvertimeScreenState();
}

class _SubmitOvertimeScreenState extends State<SubmitOvertimeScreen> {
  final Color primaryBlue = const Color(0xFF0D47A1);
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _hoursController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  DateTime? _selectedDate = DateTime.now();

  bool _isSubmitting = false;

  // 🔹 --- Pick Date ---
  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
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

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // 🔹 --- Show Error ---
  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  // 🔹 --- Submit Overtime Request ---
  Future<void> _submitOvertime() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDate == null) {
      _showError("Please select a date.");
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token'); // This must be the user's token
      if (token == null) {
        _showError("Authentication error. Please log in again.");
        setState(() => _isSubmitting = false);
        return;
      }

      final url = Uri.parse('$apiBaseUrl/api/v1/overtime');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'date': _selectedDate!.toIso8601String(),
          'hours': double.tryParse(_hoursController.text) ?? 0,
          'reason': _reasonController.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Overtime request submitted successfully!"),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context); // Go back to the previous screen
        }
      } else {
        _showError(data['message'] ?? 'Failed to submit request.');
      }
    } catch (e) {
      _showError("An error occurred. Please check your connection.");
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: primaryBlue),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Submit Overtime",
          style: TextStyle(
            color: primaryBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Submit a request for overtime approval.",
                style: TextStyle(color: Colors.grey[700], fontSize: 15),
              ),
              const SizedBox(height: 24),

              // --- Date Picker ---
              _buildDatePicker(),
              const SizedBox(height: 16),

              // --- Hours Field ---
              _buildTextField(
                _hoursController,
                "Hours Worked",
                "e.g., 2.5",
                LucideIcons.clock,
                TextInputType.number,
              ),
              const SizedBox(height: 16),

              // --- Reason Field ---
              _buildTextField(
                _reasonController,
                "Reason for Overtime",
                "Describe the task...",
                LucideIcons.clipboardList,
                TextInputType.multiline,
                maxLines: 4,
              ),
              const SizedBox(height: 30),

              // --- Submit Button ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitOvertime,
                  icon: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(LucideIcons.send, color: Colors.white),
                  label: Text(
                    _isSubmitting ? "Submitting..." : "Submit Request",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
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
    );
  }

  // --- Helper Widget for TextFields ---
  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hint,
    IconData icon,
    TextInputType keyboardType, {
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return "$label is required";
        }
        if (keyboardType == TextInputType.number) {
          if (double.tryParse(value) == null) {
            return "Please enter a valid number";
          }
          if (double.parse(value) <= 0) {
            return "Hours must be greater than 0";
          }
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: primaryBlue),
        prefixIcon: Icon(icon, color: primaryBlue, size: 20),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: primaryBlue, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  // --- Helper Widget for Date Picker ---
  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Date of Overtime",
          style: TextStyle(
            color: primaryBlue,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickDate,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.calendar, color: primaryBlue, size: 20),
                const SizedBox(width: 12),
                Text(
                  _selectedDate == null
                      ? "Select a date"
                      : DateFormat("MMM dd, yyyy").format(_selectedDate!),
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
                const Spacer(),
                const Icon(Icons.arrow_drop_down, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

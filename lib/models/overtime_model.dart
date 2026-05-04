// lib/models/overtime_model.dart
import 'package:flutter/material.dart';

// This model handles the 'user' object nested inside the overtime record
class OvertimeUser {
  final String id;
  final String name;
  final String role;

  OvertimeUser({required this.id, required this.name, required this.role});

  factory OvertimeUser.fromJson(Map<String, dynamic> json) {
    return OvertimeUser(
      id: json['_id'] ?? '',
      name: json['name'] ?? 'Unknown User',
      role: json['role'] ?? 'worker',
    );
  }
}

// This is the main model for the Overtime record
class OvertimeRecord {
  final String id;
  final OvertimeUser user;
  final DateTime date;
  final double hours;
  String status; // <-- ✅ **FIX: REMOVED 'final' FROM THIS LINE**
  final String reason;

  OvertimeRecord({
    required this.id,
    required this.user,
    required this.date,
    required this.hours,
    required this.status,
    required this.reason,
  });

  factory OvertimeRecord.fromJson(Map<String, dynamic> json) {
    return OvertimeRecord(
      id: json['_id'],
      user: OvertimeUser.fromJson(json['user'] ?? {}),
      date: DateTime.parse(json['date']),
      hours: (json['hours'] as num).toDouble(), // Ensure hours is a double
      status: json['status'],
      reason: json['reason'] ?? 'No reason provided',
    );
  }
}
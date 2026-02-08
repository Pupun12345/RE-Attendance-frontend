// lib/models/pending_attendance_model.dart
import 'package:flutter/material.dart';

// This model handles the 'user' object nested inside the attendance record
class PendingUser {
  final String id;
  final String name;
  final String? profileImageUrl;

  PendingUser({
    required this.id,
    required this.name,
    this.profileImageUrl,
  });

  factory PendingUser.fromJson(Map<String, dynamic> json) {
    return PendingUser(
      id: json['_id'] ?? '',
      name: json['name'] ?? 'Unknown User',
      profileImageUrl: json['profileImageUrl'],
    );
  }
}

// This is the main model for the attendance record itself
class PendingAttendance {
  final String id;
  final PendingUser user;
  final DateTime checkInTime;
  final String status;
  // You can add 'notes' or other fields here if your API sends them
  // final String? notes; 

  PendingAttendance({
    required this.id,
    required this.user,
    required this.checkInTime,
    required this.status,
    // this.notes,
  });

  factory PendingAttendance.fromJson(Map<String, dynamic> json) {
    return PendingAttendance(
      id: json['_id'],
      user: PendingUser.fromJson(json['user'] ?? {}),
      // Use 'createdAt' or 'checkInTime' depending on your API response
      checkInTime: DateTime.parse(json['checkInTime'] ?? json['createdAt']), 
      status: json['status'],
      // notes: json['notes'],
    );
  }
}
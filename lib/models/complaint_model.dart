// lib/models/complaint_model.dart
import 'package:flutter/material.dart';

// A simple model for the nested user data
class ComplaintUser {
  final String id;
  final String name;
  final String userId;

  ComplaintUser({required this.id, required this.name, required this.userId});

  factory ComplaintUser.fromJson(Map<String, dynamic> json) {
    return ComplaintUser(
      id: json['_id'] ?? '',
      name: json['name'] ?? 'N/A',
      userId: json['userId'] ?? 'N/A',
    );
  }
}

class Complaint {
  final String id;
  final String title;
  final String description;
  String status; // This will be mutable
  final ComplaintUser user;
  final DateTime createdAt;

  Complaint({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.user,
    required this.createdAt,
  });

  factory Complaint.fromJson(Map<String, dynamic> json) {
    return Complaint(
      id: json['_id'],
      title: json['title'],
      description: json['description'],
      status: json['status'],
      user: ComplaintUser.fromJson(json['user'] ?? {}),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
// lib/models/pending_attendance_model.dart

class PendingUser {
  final String id;
  final String name;
  final String userId;          // ← ADD THIS
  final String? profileImageUrl;

  PendingUser({
    required this.id,
    required this.name,
    required this.userId,       // ← ADD THIS
    this.profileImageUrl,
  });

  factory PendingUser.fromJson(Map<String, dynamic> json) {
    return PendingUser(
      id: json['_id'] ?? '',
      name: json['name'] ?? 'Unknown User',
      userId: json['userId'] ?? '',   // ← ADD THIS
      profileImageUrl: json['profileImageUrl'],
    );
  }
}

class PendingAttendance {
  final String id;
  final PendingUser user;
  final DateTime checkInTime;
  final String status;

  PendingAttendance({
    required this.id,
    required this.user,
    required this.checkInTime,
    required this.status,
  });

  factory PendingAttendance.fromJson(Map<String, dynamic> json) {
    // Some records only have checkOutTime (no checkInTime)
    final timeStr = json['checkInTime'] ?? json['checkOutTime'] ?? json['createdAt'];
    return PendingAttendance(
      id: json['_id'],
      user: PendingUser.fromJson(json['user'] ?? {}),
      checkInTime: DateTime.parse(timeStr),
      status: json['status'],
    );
  }
}
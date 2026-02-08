// // lib/screens/supervisor/attendance_detail_screen.dart
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:intl/intl.dart';
// import 'package:smartcare_app/utils/constants.dart';
// import 'package:smartcare_app/screens/supervisor/supervisor_dashboard_screen.dart';
//
// class AttendanceDetailScreen extends StatefulWidget {
//   const AttendanceDetailScreen({Key? key}) : super(key: key);
//
//   @override
//   State<AttendanceDetailScreen> createState() => _AttendanceDetailScreenState();
// }
//
// class _AttendanceDetailScreenState extends State<AttendanceDetailScreen> {
//   final Color themeBlue = const Color(0xFF0B3B8C);
//
//   bool _isLoading = true;
//   List<dynamic> _selfAttendanceList = [];
//   List<dynamic> _employeeList = [];
//
//   // Summary Counters
//   int _presentCount = 0;
//   int _absentCount = 0;
//   int _lateCount = 0;
//   int _leaveCount = 0;
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchAllData();
//   }
//
//   Future<void> _fetchAllData() async {
//     setState(() => _isLoading = true);
//     try {
//       await Future.wait([
//         _fetchSelfAttendanceHistory(),
//         _fetchEmployeeDailyStatus(),
//       ]);
//     } catch (e) {
//       debugPrint("Error fetching data: $e");
//     } finally {
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }
//
//   // 1. Fetch Supervisor's own attendance for the last 5 days
//   Future<void> _fetchSelfAttendanceHistory() async {
//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString('token');
//     final userString = prefs.getString('user');
//
//     if (token == null || userString == null) return;
//
//     final user = jsonDecode(userString);
//     final String myUserId = user['id'] ?? user['_id'];
//
//     // Date Range: Today back to 5 days ago
//     final now = DateTime.now();
//     final fiveDaysAgo = now.subtract(const Duration(days: 5));
//     final dateFormat = DateFormat('yyyy-MM-dd');
//
//     final url = Uri.parse(
//         '$apiBaseUrl/api/v1/reports/attendance/daily?startDate=${dateFormat.format(fiveDaysAgo)}&endDate=${dateFormat.format(now)}'
//     );
//
//     print(token);
//     print(url);
//
//     try {
//       final response = await http.get(
//         url,
//         headers: {'Authorization': 'Bearer $token'},
//       );
//
//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         final List<dynamic> allRecords = data['data'];
//
//         // Filter only MY records
//         final myRecords = allRecords.where((record) {
//           if (record['user'] is Map) {
//             return record['user']['_id'] == myUserId || record['user']['id'] == myUserId;
//           }
//           return record['user'] == myUserId;
//         }).toList();
//
//         // Sort by date descending (newest first)
//         myRecords.sort((a, b) {
//           DateTime dateA = DateTime.parse(a['date']);
//           DateTime dateB = DateTime.parse(b['date']);
//           return dateB.compareTo(dateA);
//         });
//
//         if (mounted) {
//           setState(() {
//             _selfAttendanceList = myRecords;
//           });
//         }
//       }
//     } catch (e) {
//       debugPrint("Error fetching self attendance: $e");
//     }
//   }
//
//   // 2. Fetch Status of all Workers for Today
//   Future<void> _fetchEmployeeDailyStatus() async {
//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString('token');
//
//     if (token == null) return;
//
//     final url = Uri.parse('$apiBaseUrl/api/v1/attendance/status/today');
//
//     try {
//       final response = await http.get(
//         url,
//         headers: {'Authorization': 'Bearer $token'},
//       );
//
//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         final List<dynamic> employees = data['data'];
//
//         // Calculate Stats
//         int present = 0;
//         int absent = 0;
//         int leave = 0;
//         int late = 0;
//
//         for (var emp in employees) {
//           String status = (emp['status'] ?? 'absent').toString().toLowerCase();
//           if (status == 'present') present++;
//           else if (status == 'absent') absent++;
//           else if (status == 'leave') leave++;
//           else if (status == 'late') late++;
//         }
//
//         if (mounted) {
//           setState(() {
//             _employeeList = employees;
//             _presentCount = present;
//             _absentCount = absent;
//             _leaveCount = leave;
//             _lateCount = late;
//           });
//         }
//       }
//     } catch (e) {
//       debugPrint("Error fetching employee status: $e");
//     }
//   }
//
//   // Helper to format ISO time string
//   String _formatTime(String? isoString) {
//     if (isoString == null) return '--:--';
//     try {
//       return DateFormat('hh:mm a').format(DateTime.parse(isoString));
//     } catch (e) {
//       return '--:--';
//     }
//   }
//
//   // Helper to format Date string
//   String _formatDate(String? isoString) {
//     if (isoString == null) return '';
//     try {
//       return DateFormat('dd MMM, yyyy').format(DateTime.parse(isoString));
//     } catch (e) {
//       return '';
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF7F7FB),
//       appBar: AppBar(
//         backgroundColor: themeBlue,
//         centerTitle: true,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
//           onPressed: () {
//             Navigator.pushReplacement(
//               context,
//               MaterialPageRoute(
//                 builder: (_) => const SupervisorDashboardScreen(),
//               ),
//             );
//           },
//         ),
//         title: const Text(
//           "Attendance Detail",
//           style: TextStyle(
//             color: Colors.white,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//       ),
//       body: RefreshIndicator(
//         onRefresh: _fetchAllData,
//         child: SingleChildScrollView(
//           physics: const AlwaysScrollableScrollPhysics(),
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               /// 🔹 SUMMARY CARDS
//               Row(
//                 children: [
//                   _statCard("Present", _presentCount.toString(), Colors.green),
//                   const SizedBox(width: 10),
//                   _statCard("Absent", _absentCount.toString(), Colors.red),
//                 ],
//               ),
//               const SizedBox(height: 12),
//               Row(
//                 children: [
//                   _statCard("Late", _lateCount.toString(), Colors.orange),
//                   const SizedBox(width: 10),
//                   _statCard("Leave", _leaveCount.toString(), Colors.blueGrey),
//                 ],
//               ),
//
//               const SizedBox(height: 24),
//
//               /// 🔹 SELF ATTENDANCE
//               Text(
//                 "Self Attendance (Last 5 Days)",
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.w700,
//                   color: themeBlue,
//                 ),
//               ),
//               const SizedBox(height: 10),
//
//               _isLoading
//                   ? const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
//                   : _selfAttendanceList.isEmpty
//                   ? _emptyBox("No self attendance records found")
//                   : ListView.builder(
//                 shrinkWrap: true,
//                 physics: const NeverScrollableScrollPhysics(),
//                 itemCount: _selfAttendanceList.length,
//                 itemBuilder: (context, index) {
//                   return _selfAttendanceCard(_selfAttendanceList[index]);
//                 },
//               ),
//
//               const SizedBox(height: 24),
//
//               /// 🔹 EMPLOYEE LIST
//               const Text(
//                 "Employee List (Today)",
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//               const SizedBox(height: 10),
//
//               _isLoading
//                   ? const SizedBox() // Loader already shown above
//                   : _employeeList.isEmpty
//                   ? _emptyBox("No employee attendance data available")
//                   : ListView.builder(
//                 shrinkWrap: true,
//                 physics: const NeverScrollableScrollPhysics(),
//                 itemCount: _employeeList.length,
//                 itemBuilder: (context, index) {
//                   return _employeeTile(_employeeList[index]);
//                 },
//               ),
//               const SizedBox(height: 30),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   // 🔹 SUMMARY CARD
//   Widget _statCard(String title, String count, Color color) {
//     return Expanded(
//       child: Container(
//         padding: const EdgeInsets.symmetric(vertical: 18),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(12),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.grey.withOpacity(0.15),
//               blurRadius: 6,
//             )
//           ],
//         ),
//         child: Column(
//           children: [
//             Text(
//               count,
//               style: TextStyle(
//                 color: color,
//                 fontSize: 22,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 4),
//             Text(title),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // 🔹 EMPTY PLACEHOLDER
//   Widget _emptyBox(String text) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(10),
//         border: Border.all(color: Colors.grey.shade300),
//       ),
//       child: Center(
//         child: Text(
//           text,
//           style: const TextStyle(color: Colors.black54),
//         ),
//       ),
//     );
//   }
//
//   // 🔹 SELF ATTENDANCE CARD
//   Widget _selfAttendanceCard(dynamic record) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 8),
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(10),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.08),
//             blurRadius: 4,
//             offset: const Offset(0, 2),
//           )
//         ],
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   _formatDate(record['date']),
//                   style: const TextStyle(
//                     fontWeight: FontWeight.w600,
//                     fontSize: 15,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   "In: ${_formatTime(record['checkInTime'])}  Out: ${_formatTime(record['checkOutTime'])}",
//                   style: const TextStyle(
//                     fontSize: 13,
//                     color: Colors.black54,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           _statusChip(record['status'] ?? 'absent'),
//         ],
//       ),
//     );
//   }
//
//   // 🔹 EMPLOYEE TILE
//   Widget _employeeTile(dynamic emp) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 8),
//       padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(10),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.08),
//             blurRadius: 4,
//             offset: const Offset(0, 2),
//           )
//         ],
//       ),
//       child: Row(
//         children: [
//           CircleAvatar(
//             radius: 18,
//             backgroundColor: themeBlue.withOpacity(0.1),
//             backgroundImage: (emp['profileImageUrl'] != null && emp['profileImageUrl'].isNotEmpty)
//                 ? NetworkImage(emp['profileImageUrl'])
//                 : null,
//             child: (emp['profileImageUrl'] == null || emp['profileImageUrl'].isEmpty)
//                 ? Icon(Icons.person, size: 20, color: themeBlue)
//                 : null,
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   emp['name'] ?? 'Unknown',
//                   style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
//                 ),
//                 Text(
//                   emp['userId'] ?? '',
//                   style: const TextStyle(color: Colors.grey, fontSize: 12),
//                 ),
//               ],
//             ),
//           ),
//           _statusChip(emp['status'] ?? 'absent'),
//         ],
//       ),
//     );
//   }
//
//   // 🔹 STATUS CHIP
//   Widget _statusChip(String status) {
//     Color c;
//     String label = status.toUpperCase();
//
//     switch (status.toLowerCase()) {
//       case 'present':
//         c = Colors.green;
//         break;
//       case 'absent':
//         c = Colors.red;
//         break;
//       case 'late':
//         c = Colors.orange;
//         break;
//       case 'leave':
//         c = Colors.blueGrey;
//         break;
//       case 'pending':
//         c = Colors.amber;
//         break;
//       default:
//         c = Colors.grey;
//     }
//
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//       decoration: BoxDecoration(
//         color: c.withOpacity(0.15),
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: Text(
//         label,
//         style: TextStyle(
//           color: c,
//           fontSize: 11,
//           fontWeight: FontWeight.w700,
//         ),
//       ),
//     );
//   }
// }



// lib/screens/supervisor/attendance_detail_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:smartcare_app/utils/constants.dart';
import 'package:smartcare_app/screens/supervisor/supervisor_dashboard_screen.dart';

class AttendanceDetailScreen extends StatefulWidget {
  const AttendanceDetailScreen({Key? key}) : super(key: key);

  @override
  State<AttendanceDetailScreen> createState() => _AttendanceDetailScreenState();
}

class _AttendanceDetailScreenState extends State<AttendanceDetailScreen> {
  final Color themeBlue = const Color(0xFF0B3B8C);

  bool _isLoading = true;
  List<dynamic> _selfAttendanceList = [];
  List<dynamic> _employeeList = [];

  // Summary Counters
  int _presentCount = 0;
  int _absentCount = 0;
  int _lateCount = 0;
  int _leaveCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchAllData();
  }

  Future<void> _fetchAllData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _fetchSelfAttendanceHistory(),
        _fetchEmployeeDailyStatus(),
      ]);
    } catch (e) {
      debugPrint("Error fetching data: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 1. Fetch Supervisor's own attendance for the last 5 days
  Future<void> _fetchSelfAttendanceHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userString = prefs.getString('user');

    if (token == null || userString == null) return;

    final user = jsonDecode(userString);
    final String myUserId = user['id'] ?? user['_id'];

    // Date Range: Today back to 5 days ago (IST timezone)
    final now = DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
    final fiveDaysAgo = now.subtract(const Duration(days: 5));
    final dateFormat = DateFormat('yyyy-MM-dd');

    final url = Uri.parse(
        '$apiBaseUrl/api/v1/reports/attendance/daily?startDate=${dateFormat.format(fiveDaysAgo)}&endDate=${dateFormat.format(now)}'
    );

    print(token);
    print(url);

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> allRecords = data['data'];

        // Filter only MY records
        final myRecords = allRecords.where((record) {
          if (record['user'] is Map) {
            return record['user']['_id'] == myUserId || record['user']['id'] == myUserId;
          }
          return record['user'] == myUserId;
        }).toList();

        // Sort by date descending (newest first)
        myRecords.sort((a, b) {
          DateTime dateA = DateTime.parse(a['date']);
          DateTime dateB = DateTime.parse(b['date']);
          return dateB.compareTo(dateA);
        });

        // Take only last 5 days
        final last5Days = myRecords.take(5).toList();

        if (mounted) {
          setState(() {
            _selfAttendanceList = last5Days;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching self attendance: $e");
    }
  }

  // 2. Fetch Status of all Workers for Today
  Future<void> _fetchEmployeeDailyStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) return;

    final url = Uri.parse('$apiBaseUrl/api/v1/attendance/status/today');

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> employees = data['data'];

        // Calculate Stats
        int present = 0;
        int absent = 0;
        int leave = 0;
        int late = 0;

        for (var emp in employees) {
          String status = (emp['status'] ?? 'absent').toString().toLowerCase();
          if (status == 'present') present++;
          else if (status == 'absent') absent++;
          else if (status == 'leave') leave++;
          else if (status == 'late') late++;
        }

        if (mounted) {
          setState(() {
            _employeeList = employees;
            _presentCount = present;
            _absentCount = absent;
            _leaveCount = leave;
            _lateCount = late;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching employee status: $e");
    }
  }

  // Helper to format ISO time string to Indian Time (IST)
  String _formatTime(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '--:--';
    try {
      // Parse UTC time and convert to IST (UTC+5:30)
      final utcTime = DateTime.parse(isoString);
      final istTime = utcTime.add(const Duration(hours: 5, minutes: 30));
      return DateFormat('hh:mm a').format(istTime);
    } catch (e) {
      return '--:--';
    }
  }

  // Helper to format Date string to Indian Time (IST)
  String _formatDate(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '';
    try {
      // Parse UTC date and convert to IST (UTC+5:30)
      final utcDate = DateTime.parse(isoString);
      final istDate = utcDate.add(const Duration(hours: 5, minutes: 30));
      return DateFormat('dd MMM, yyyy').format(istDate);
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      appBar: AppBar(
        backgroundColor: themeBlue,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const SupervisorDashboardScreen(),
              ),
            );
          },
        ),
        title: const Text(
          "Attendance Detail",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchAllData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 🔹 SUMMARY CARDS
              Row(
                children: [
                  _statCard("Present", _presentCount.toString(), Colors.green),
                  const SizedBox(width: 10),
                  _statCard("Absent", _absentCount.toString(), Colors.red),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _statCard("Late", _lateCount.toString(), Colors.orange),
                  const SizedBox(width: 10),
                  _statCard("Leave", _leaveCount.toString(), Colors.blueGrey),
                ],
              ),

              const SizedBox(height: 24),

              /// 🔹 SELF ATTENDANCE
              Text(
                "Self Attendance (Last 5 Days)",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: themeBlue,
                ),
              ),
              const SizedBox(height: 10),

              _isLoading
                  ? const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                  : _selfAttendanceList.isEmpty
                  ? _emptyBox("No self attendance records found")
                  : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _selfAttendanceList.length,
                itemBuilder: (context, index) {
                  return _selfAttendanceCard(_selfAttendanceList[index]);
                },
              ),

              const SizedBox(height: 24),

              /// 🔹 EMPLOYEE LIST
              const Text(
                "Employee List (Today)",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),

              _isLoading
                  ? const SizedBox() // Loader already shown above
                  : _employeeList.isEmpty
                  ? _emptyBox("No employee attendance data available")
                  : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _employeeList.length,
                itemBuilder: (context, index) {
                  return _employeeTile(_employeeList[index]);
                },
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // 🔹 SUMMARY CARD
  Widget _statCard(String title, String count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              blurRadius: 6,
            )
          ],
        ),
        child: Column(
          children: [
            Text(
              count,
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(title),
          ],
        ),
      ),
    );
  }

  // 🔹 EMPTY PLACEHOLDER
  Widget _emptyBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(color: Colors.black54),
        ),
      ),
    );
  }

  // 🔹 SELF ATTENDANCE CARD
  Widget _selfAttendanceCard(dynamic record) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(record['date']),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "In: ${_formatTime(record['checkInTime'])}  Out: ${_formatTime(record['checkOutTime'])}",
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          _statusChip(record['status'] ?? 'absent'),
        ],
      ),
    );
  }

  // 🔹 EMPLOYEE TILE
  Widget _employeeTile(dynamic emp) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: themeBlue.withOpacity(0.1),
            backgroundImage: (emp['profileImageUrl'] != null && emp['profileImageUrl'].isNotEmpty)
                ? NetworkImage(emp['profileImageUrl'])
                : null,
            child: (emp['profileImageUrl'] == null || emp['profileImageUrl'].isEmpty)
                ? Icon(Icons.person, size: 20, color: themeBlue)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  emp['name'] ?? 'Unknown',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                Text(
                  emp['userId'] ?? '',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          _statusChip(emp['status'] ?? 'absent'),
        ],
      ),
    );
  }

  // 🔹 STATUS CHIP
  Widget _statusChip(String status) {
    Color c;
    String label = status.toUpperCase();

    switch (status.toLowerCase()) {
      case 'present':
        c = Colors.green;
        break;
      case 'absent':
        c = Colors.red;
        break;
      case 'late':
        c = Colors.orange;
        break;
      case 'leave':
        c = Colors.blueGrey;
        break;
      case 'pending':
        c = Colors.amber;
        break;
      default:
        c = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: c.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: c,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
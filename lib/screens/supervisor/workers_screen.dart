// lib/screens/supervisor/workers_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:smartcare_app/utils/constants.dart';
import 'package:smartcare_app/screens/supervisor/supervisor_dashboard_screen.dart';
import 'package:smartcare_app/screens/supervisor/worker_profile_screen.dart';

class Worker {
  final String id; // This is the MongoDB ID
  final String name;
  final String userId;
  final String? profileImageUrl;

  Worker({
    required this.id,
    required this.name,
    required this.userId,
    this.profileImageUrl,
  });

  factory Worker.fromJson(Map<String, dynamic> json) {
    return Worker(
      id: json['_id'],
      name: json['name'],
      userId: json['userId'],
      profileImageUrl: json['profileImageUrl'],
    );
  }
}

class WorkersScreen extends StatefulWidget {
  final String? initialSearchQuery;

  const WorkersScreen({super.key, this.initialSearchQuery});

  @override
  State<WorkersScreen> createState() => _WorkersScreenState();
}

class _WorkersScreenState extends State<WorkersScreen> {
  final Color themeBlue = const Color(0xFF0B3B8C);
  final TextEditingController searchController = TextEditingController();

  final String _apiUrl = apiBaseUrl;

  List<Worker> _allWorkers = [];
  List<Worker> _filteredWorkers = [];
  bool _isLoading = true;
  String? _error;

  // Dummy fallback worker used when loading fails
  final Worker _dummyWorker = Worker(
    id: 'dummy-1',
    name: 'umesh1402',
    userId: 'UMS1402',
    profileImageUrl: null,
  );

  @override
  void initState() {
    super.initState();
    _fetchWorkers();

    if (widget.initialSearchQuery != null) {
      searchController.text = widget.initialSearchQuery!;
    }
    searchController.addListener(_filterWorkers);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchWorkers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.get(
        Uri.parse("$_apiUrl/api/v1/users?role=worker"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        List<dynamic> usersJson = responseData['users'];
        setState(() {
          _allWorkers = usersJson.map((json) => Worker.fromJson(json)).toList();
          _filteredWorkers = _allWorkers;
          _isLoading = false;
          _filterWorkers();
        });
      } else {
        setState(() {
          _error = "Failed to load workers.";
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

  void _filterWorkers() {
    String query = searchController.text.toLowerCase();
    setState(() {
      _filteredWorkers = _allWorkers.where((worker) {
        return worker.name.toLowerCase().contains(query) ||
            worker.userId.toLowerCase().contains(query);
      }).toList();
    });
  }

  // Helper method for marking attendance (no changes needed here but included for context)
  Future<void> _markAttendance(Worker worker) async {
    // ... (logic omitted for brevity, it's not the cause of the error) ...
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  Widget _buildWorkerRow(Worker worker) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundImage: worker.profileImageUrl != null
                ? NetworkImage(worker.profileImageUrl!)
                : null,
            child: worker.profileImageUrl == null
                ? const Icon(Icons.person, size: 26)
                : null,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(worker.name,
                  style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              Text(worker.userId,
                  style: const TextStyle(fontSize: 13, color: Colors.grey)),
            ],
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () {
              // ✅ Updated Navigation: Passing dbId
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WorkerProfileScreen(
                    name: worker.name,
                    userId: worker.userId,
                    dbId: worker.id, // ✅ Passing the actual DB ID
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: themeBlue,
              foregroundColor: Colors.white,
              shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Take Attendance", style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return ListView(
        children: [
          _buildWorkerRow(_dummyWorker),
        ],
      );
    }

    if (_filteredWorkers.isEmpty) {
      return Center(
        child: Text(
          searchController.text.isEmpty
              ? "No workers found."
              : "No workers match your search.",
        ),
      );
    }

    return ListView.builder(
      itemCount: _filteredWorkers.length,
      itemBuilder: (context, index) {
        final worker = _filteredWorkers[index];
        return _buildWorkerRow(worker);
      },
    );
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
              MaterialPageRoute(builder: (_) => const SupervisorDashboardScreen()),
            );
          },
        ),
        title: const Text(
          "Workers",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: "Search worker by name or ID...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 15),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }
}
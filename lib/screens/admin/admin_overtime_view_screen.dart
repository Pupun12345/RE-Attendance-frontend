// lib/screens/admin/admin_overtime_view_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:smartcare_app/models/overtime_model.dart';
import 'package:smartcare_app/utils/constants.dart';

class AdminOvertimeViewScreen extends StatefulWidget {
  const AdminOvertimeViewScreen({super.key});

  @override
  State<AdminOvertimeViewScreen> createState() =>
      _AdminOvertimeViewScreenState();
}

class _AdminOvertimeViewScreenState extends State<AdminOvertimeViewScreen>
    with SingleTickerProviderStateMixin {
  final Color primaryBlue = const Color(0xFF0D47A1);
  final Color lightBlue = const Color(0xFFE3F2FD);

  late TabController _tabController;
  bool _isLoading = true;
  String? _token;

  List<OvertimeRecord> _pendingRequests = [];
  List<OvertimeRecord> _approvedRequests = [];
  List<OvertimeRecord> _rejectedRequests = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchAllOvertime();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  Future<void> _fetchAllOvertime() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('token');
      if (_token == null) {
        _showError("Not authorized.");
        return;
      }

      final url = Uri.parse('$apiBaseUrl/api/v1/overtime');
      final response =
      await http.get(url, headers: {'Authorization': 'Bearer $_token'});

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final allRecords = (data['data'] as List)
            .map((r) => OvertimeRecord.fromJson(r))
            .toList();

        setState(() {
          _pendingRequests =
              allRecords.where((r) => r.status == 'pending').toList();
          _approvedRequests =
              allRecords.where((r) => r.status == 'approved').toList();
          _rejectedRequests =
              allRecords.where((r) => r.status == 'rejected').toList();
        });
      } else {
        _showError("Failed to load overtime records.");
      }
    } catch (e) {
      _showError("An error occurred: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleOvertimeAction(
      OvertimeRecord request, bool isApproved) async {
    if (_token == null) return;

    final action = isApproved ? 'approve' : 'reject';
    final url = Uri.parse('$apiBaseUrl/api/v1/overtime/${request.id}/$action');

    final response =
    await http.put(url, headers: {'Authorization': 'Bearer $_token'});

    if (response.statusCode == 200) {
      setState(() {
        _pendingRequests.remove(request);
        if (isApproved) {
          request.status = 'approved';
          _approvedRequests.add(request);
        } else {
          request.status = 'rejected';
          _rejectedRequests.add(request);
        }
      });
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
          "Overtime View",
          style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: primaryBlue,
          labelColor: primaryBlue,
          unselectedLabelColor: Colors.grey,
          tabs: [
            _buildTab(LucideIcons.clock3, "Pending", _pendingRequests.length),
            _buildTab(
                LucideIcons.checkCircle, "Approved", _approvedRequests.length),
            _buildTab(
                LucideIcons.xCircle, "Rejected", _rejectedRequests.length),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryBlue))
          : TabBarView(
        controller: _tabController,
        children: [
          _buildListView(
              requests: _pendingRequests,
              emptyMessage: "No pending overtime requests.",
              isPendingTab: true),
          _buildListView(
              requests: _approvedRequests,
              emptyMessage: "No approved overtime records."),
          _buildListView(
              requests: _rejectedRequests,
              emptyMessage: "No rejected overtime records."),
        ],
      ),
    );
  }

  Widget _buildTab(IconData icon, String title, int count) {
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              "$title ($count)",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView({
    required List<OvertimeRecord> requests,
    required String emptyMessage,
    bool isPendingTab = false,
  }) {
    if (requests.isEmpty) {
      return Center(
          child: Text(emptyMessage,
              style:
              const TextStyle(fontSize: 16, color: Colors.black54)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        return isPendingTab
            ? _buildPendingRequestCard(request)
            : _buildHistoryRequestCard(request);
      },
    );
  }

  Widget _buildPendingRequestCard(OvertimeRecord request) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(
              backgroundColor: lightBlue,
              child: Icon(LucideIcons.user, color: primaryBlue),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(request.user.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: primaryBlue)),
                    Text("Role: ${request.user.role}",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                        const TextStyle(fontSize: 13, color: Colors.grey)),
                  ]),
            ),
          ]),
          const Divider(),
          Text(
              "Date: ${DateFormat("MMM dd, yyyy").format(request.date)}"),
          Text("Hours: ${request.hours.toStringAsFixed(1)} hrs"),
          Text("Reason: ${request.reason}",
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontStyle: FontStyle.italic)),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            ElevatedButton(
                onPressed: () => _handleOvertimeAction(request, true),
                style:
                ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text("Approve")),
            const SizedBox(width: 10),
            ElevatedButton(
                onPressed: () => _handleOvertimeAction(request, false),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent),
                child: const Text("Reject")),
          ])
        ]),
      ),
    );
  }

  Widget _buildHistoryRequestCard(OvertimeRecord request) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: lightBlue,
          child: Icon(
              request.status == 'approved'
                  ? LucideIcons.check
                  : LucideIcons.x,
              color:
              request.status == 'approved' ? Colors.green : Colors.red),
        ),
        title: Text(request.user.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style:
            TextStyle(color: primaryBlue, fontWeight: FontWeight.bold)),
        subtitle: Text(
          "Date: ${DateFormat("MMM dd, yyyy").format(request.date)}\nReason: ${request.reason}",
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text("${request.hours} hrs",
            style: TextStyle(
                color: request.status == 'approved'
                    ? Colors.green
                    : Colors.red,
                fontWeight: FontWeight.bold)),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ✅ 1. Import this

class AdminSystemConfigurationScreen extends StatefulWidget {
  const AdminSystemConfigurationScreen({super.key});

  @override
  State<AdminSystemConfigurationScreen> createState() =>
      _AdminSystemConfigurationScreenState();
}

class _AdminSystemConfigurationScreenState
    extends State<AdminSystemConfigurationScreen> {
  final Color primaryBlue = const Color(0xFF0D47A1);
  final Color lightBlue = const Color(0xFFE3F2FD);
  bool _isLoading = true; // ✅ 2. Add loading state

  // Controllers
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  TimeOfDay? startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay? endTime = const TimeOfDay(hour: 18, minute: 0);

  bool overtimeEnabled = true;
  bool autoLockAttendance = false;
  bool darkMode = false;
  bool notificationsEnabled = true;
  String backupFrequency = "Weekly";

  @override
  void initState() {
    super.initState();
    _loadConfiguration(); // ✅ 3. Load saved data on init
  }

  // ✅ 4. NEW: Load data from local storage
  Future<void> _loadConfiguration() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Use setState to update the UI with loaded data
    setState(() {
      // Load strings
      _companyNameController.text =
          prefs.getString('config_companyName') ?? 'SmartCare Technologies';
      _emailController.text =
          prefs.getString('config_email') ?? 'admin@smartcare.com';
      _contactController.text =
          prefs.getString('config_contact') ?? '+91 9876543210';
      _locationController.text =
          prefs.getString('config_location') ?? 'Bhubaneswar, Odisha';

      // Load booleans
      overtimeEnabled = prefs.getBool('config_overtime') ?? true;
      autoLockAttendance = prefs.getBool('config_autoLock') ?? false;
      darkMode = prefs.getBool('config_darkMode') ?? false;
      notificationsEnabled = prefs.getBool('config_notifications') ?? true;

      // Load dropdown
      backupFrequency = prefs.getString('config_backup') ?? 'Weekly';

      // Load TimeOfDay (stored as ints)
      startTime = TimeOfDay(
        hour: prefs.getInt('config_startTime_hour') ?? 9,
        minute: prefs.getInt('config_startTime_min') ?? 0,
      );
      endTime = TimeOfDay(
        hour: prefs.getInt('config_endTime_hour') ?? 18,
        minute: prefs.getInt('config_endTime_min') ?? 0,
      );
      
      _isLoading = false; // Data loaded, stop loading
    });
  }

  // Pick Time
  Future<void> _pickTime(bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? startTime! : endTime!,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          startTime = picked;
        } else {
          endTime = picked;
        }
      });
    }
  }

  // ✅ 5. UPDATED: Save data to local storage
  void _saveConfiguration() async {
    final prefs = await SharedPreferences.getInstance();

    // Save strings
    await prefs.setString('config_companyName', _companyNameController.text);
    await prefs.setString('config_email', _emailController.text);
    await prefs.setString('config_contact', _contactController.text);
    await prefs.setString('config_location', _locationController.text);

    // Save booleans
    await prefs.setBool('config_overtime', overtimeEnabled);
    await prefs.setBool('config_autoLock', autoLockAttendance);
    await prefs.setBool('config_darkMode', darkMode);
    await prefs.setBool('config_notifications', notificationsEnabled);

    // Save dropdown
    await prefs.setString('config_backup', backupFrequency);

    // Save TimeOfDay as separate ints
    await prefs.setInt('config_startTime_hour', startTime!.hour);
    await prefs.setInt('config_startTime_min', startTime!.minute);
    await prefs.setInt('config_endTime_hour', endTime!.hour);
    await prefs.setInt('config_endTime_min', endTime!.minute);

    // Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("System Configuration Saved Successfully!"),
          backgroundColor: primaryBlue,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        // ... (AppBar is the same as your file) ...
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: CircleAvatar(
            backgroundImage: const AssetImage("assets/images/profile.png"),
            radius: 18,
            backgroundColor: Colors.grey[300],
          ),
        ),
        title: Text(
          "System Configuration",
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
        ],
      ),
      // ✅ 6. Show loader while data is loading
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryBlue))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildSectionTitle("Company Information"),
                  _buildTextField(_companyNameController, "Company Name"),
                  const SizedBox(height: 12),
                  _buildTextField(_emailController, "Company Email"),
                  const SizedBox(height: 12),
                  _buildTextField(_contactController, "Contact Number"),
                  const SizedBox(height: 12),
                  _buildTextField(_locationController, "Company Location"),
                  const SizedBox(height: 24),
                  _buildSectionTitle("Attendance Settings"),
                  _buildTimeCard(),
                  const SizedBox(height: 12),
                  _buildSwitch("Enable Overtime", overtimeEnabled, (val) {
                    setState(() => overtimeEnabled = val);
                  }),
                  _buildSwitch("Auto Attendance Lock", autoLockAttendance,
                      (val) {
                    setState(() => autoLockAttendance = val);
                  }),
                  const SizedBox(height: 24),
                  _buildSectionTitle("System Preferences"),
                  _buildSwitch("Dark Mode", darkMode, (val) {
                    setState(() => darkMode = val);
                  }),
                  _buildSwitch(
                      "Enable Notifications", notificationsEnabled, (val) {
                    setState(() => notificationsEnabled = val);
                  }),
                  _buildDropdown(),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saveConfiguration, // This now saves data
                      icon: const Icon(LucideIcons.save, color: Colors.white),
                      label: const Text(
                        "Save Configuration",
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
    );
  }

  // ... (All your helper widgets _buildSectionTitle, _buildTextField, etc. are correct)
  // ... (No changes needed to the helper widgets below)

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: primaryBlue,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: primaryBlue),
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

  Widget _buildTimeCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildTimeTile("Start Time", startTime!, true),
            _buildTimeTile("End Time", endTime!, false),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeTile(String label, TimeOfDay time, bool isStart) {
    return GestureDetector(
      onTap: () => _pickTime(isStart),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: primaryBlue,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: lightBlue,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              time.format(context),
              style: TextStyle(
                color: primaryBlue,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitch(String title, bool value, Function(bool) onChanged) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Icon(
          LucideIcons.settings,
          color: primaryBlue,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: primaryBlue,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        trailing: Switch(
          activeColor: primaryBlue,
          value: value,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Icon(LucideIcons.database, color: primaryBlue),
        title: Text(
          "Backup Frequency",
          style: TextStyle(
            color: primaryBlue,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        trailing: DropdownButton<String>(
          value: backupFrequency,
          underline: const SizedBox(),
          onChanged: (String? newValue) {
            setState(() => backupFrequency = newValue!);
          },
          items: ["Daily", "Weekly", "Monthly"]
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value, style: const TextStyle(fontSize: 14)),
            );
          }).toList(),
        ),
      ),
    );
  }
}
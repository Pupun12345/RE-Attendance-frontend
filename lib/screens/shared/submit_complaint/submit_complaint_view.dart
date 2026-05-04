import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smartcare_app/screens/supervisor/views/worker_complaint_view.dart';
import 'submit_complaint_controller.dart';

class SubmitComplaintView extends StatelessWidget {
  const SubmitComplaintView({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ GetView hataya, StatelessWidget use kiya
    // ✅ controller pehle put karo, phir use karo
    final controller = Get.put(SubmitComplaintController());

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      body: RefreshIndicator(
        onRefresh: controller.refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWorkerSection(controller),

              const SizedBox(height: 20),
              const Divider(),
              const Center(
                child: Text("Or submit a general complaint",
                    style: TextStyle(color: Colors.grey)),
              ),
              const SizedBox(height: 10),

              const Text("Complaint Title",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: controller.titleController,
                decoration: InputDecoration(
                  hintText: "Enter title...",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),

              const SizedBox(height: 16),
              const Text("Description",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: controller.descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Describe issue...",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),

              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: controller.captureImage,
                      icon: const Icon(Icons.camera_alt, color: Colors.white),
                      label: const Text("Take Photo",
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: controller.themeBlue),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: controller.pickImageFromGallery,
                      icon: Icon(Icons.file_upload, color: controller.themeBlue),
                      label: Text("Upload Image",
                          style: TextStyle(color: controller.themeBlue)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: BorderSide(color: controller.themeBlue),
                      ),
                    ),
                  ),
                ],
              ),

              Obx(() => controller.selectedImage.value != null
                  ? Padding(
                padding: const EdgeInsets.only(top: 15),
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      controller.selectedImage.value!,
                      height: 140,
                      width: 140,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              )
                  : const SizedBox.shrink()),

              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: Obx(() => ElevatedButton(
                  onPressed: controller.isSubmitting.value
                      ? null
                      : controller.submitComplaint,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: controller.themeBlue),
                  child: controller.isSubmitting.value
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Submit General Complaint",
                      style: TextStyle(color: Colors.white)),
                )),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkerSection(SubmitComplaintController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Select Worker",
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: controller.searchController,
          decoration: InputDecoration(
            hintText: "Search worker by name or ID...",
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        Obx(() => Container(
          height: 300, // ✅ constraints ki jagah fixed height
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: controller.isLoadingWorkers.value
              ? const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          )
              : controller.filteredWorkers.isEmpty
              ? const Padding(
            padding: EdgeInsets.all(20),
            child: Text("No workers found."),
          )
              : ListView.separated(
            // ✅ NeverScrollableScrollPhysics hataya
            physics: const BouncingScrollPhysics(),
            itemCount: controller.filteredWorkers.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: Colors.grey.shade200),
            itemBuilder: (context, index) {
              final worker = controller.filteredWorkers[index];
              final String name = worker['name'] ?? 'Unknown';
              final String userId = worker['userId'] ?? 'N/A';
              final String dbId = worker['_id'] ?? worker['id'];

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                  controller.themeBlue.withOpacity(0.1),
                  child: Icon(Icons.person,
                      color: controller.themeBlue),
                ),
                title: Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600)),
                subtitle: Text(userId,
                    style: const TextStyle(
                        fontSize: 12, color: Colors.grey)),
                trailing: const Icon(Icons.arrow_forward_ios,
                    size: 14, color: Colors.grey),
                onTap: () => Get.to(() => WorkerComplaintView(
                  name: name,
                  userId: userId,
                  dbId: dbId,
                )),
              );
            },
          ),
        )),
      ],
    );
  }
}
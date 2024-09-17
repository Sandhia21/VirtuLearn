import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:learn_smart/api_service.dart';
import 'package:learn_smart/view_models/auth_view_model.dart';
import 'package:learn_smart/screens/widgets/app_bar.dart';
import 'package:learn_smart/screens/widgets/bottom_navigation.dart'; // Import the BottomNavigation widget
import 'package:motion_tab_bar_v2/motion-tab-controller.dart'; // Import for the tab bar controller

import '../models/enrollment.dart';

class NotificationsScreen extends StatefulWidget {
  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  List<StudentEnrollmentRequest> _studentEnrollmentRequests = [];

  late MotionTabBarController
      _motionTabBarController; // Declare controller for BottomNavigation
  int _selectedIndex = 2; // Default index for the Notifications tab

  @override
  void initState() {
    super.initState();
    _motionTabBarController = MotionTabBarController(
      initialIndex:
          _selectedIndex, // Set the initial index for Notifications tab
      length: 4,
      vsync: this,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      final apiService = ApiService(baseUrl: 'http://10.0.2.2:8000/api/');
      apiService.updateToken(authViewModel.user.token ?? '');

      if (authViewModel.user.token != null) {
        if (authViewModel.user.isStudent()) {
          // Fetch student enrollment requests
          await _fetchStudentEnrollmentRequests(apiService);
        } else {}
      } else {
        print('Token is null, cannot fetch enrollment requests');
      }
    });
  }

  Future<void> _fetchStudentEnrollmentRequests(ApiService apiService) async {
    try {
      // Fetch student enrollment requests
      List<StudentEnrollmentRequest> requests =
          await apiService.fetchStudentEnrollmentRequests();

      setState(() {
        _studentEnrollmentRequests = requests;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _motionTabBarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Notifications'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? Center(
                  child: Text('Error fetching notifications: $_errorMessage'))
              : _studentEnrollmentRequests.isEmpty
                  ? const Center(child: Text('No Updates Yet'))
                  : _buildNotificationsList(),
      bottomNavigationBar: BottomNavigation(
        // Add the BottomNavigation bar here
        controller: _motionTabBarController,
        currentIndex: _selectedIndex,
      ),
    );
  }

  Widget _buildNotificationsList() {
    return ListView.builder(
      itemCount: _studentEnrollmentRequests.length,
      itemBuilder: (context, index) {
        final request = _studentEnrollmentRequests[index];
        return _studentNotificationCard(request);
      },
    );
  }

  Widget _studentNotificationCard(StudentEnrollmentRequest request) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Course Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 60,
                height: 60,
                child: request.courseImage.isNotEmpty
                    ? Image.network(
                        'http://10.0.2.2:8000${request.courseImage}',
                        fit: BoxFit.cover,
                      )
                    : Image.asset(
                        'assets/icons/default_course_image.png',
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            const SizedBox(width: 12),
            // Course Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.courseName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    request.courseDescription,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Enrollment Status
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: _getStatusColor(request.status),
              ),
              child: Text(
                request.status,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'declined':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

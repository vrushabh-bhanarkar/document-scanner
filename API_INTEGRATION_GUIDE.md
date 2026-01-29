/// API Integration Setup Guide
/// 
/// This guide explains how to properly set up and use the API services
/// in your Flutter app with the Employee and Task APIs.

/// STEP 1: Initialize the Service Provider in main.dart
/// 
/// Replace your main function with:
/// 
/// ```dart
/// import 'package:provider/provider.dart';
/// import 'services/api_service_provider.dart';
///
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   
///   // Initialize API Service Provider with token (if user is logged in)
///   // You can get token from SharedPreferences or secure storage
///   final String? savedToken = await getTokenFromStorage();
///   
///   final apiProvider = ApiServiceProvider(token: savedToken);
///   ServiceLocator().initialize(apiProvider);
///
///   runApp(
///     MultiProvider(
///       providers: [
///         ChangeNotifierProvider.value(value: apiProvider),
///       ],
///       child: const MyApp(),
///     ),
///   );
/// }
///
/// Future<String?> getTokenFromStorage() async {
///   // Get from SharedPreferences or other secure storage
///   return null; // Replace with actual implementation
/// }
/// ```

/// STEP 2: Use API Services in Your Screens
///
/// Example 1: Simple data loading
/// ```dart
/// class MyScreen extends StatefulWidget {
///   @override
///   State<MyScreen> createState() => _MyScreenState();
/// }
///
/// class _MyScreenState extends State<MyScreen> {
///   List<Employee> employees = [];
///   bool isLoading = false;
///
///   @override
///   void initState() {
///     super.initState();
///     _loadEmployees();
///   }
///
///   Future<void> _loadEmployees() async {
///     setState(() => isLoading = true);
///
///     try {
///       final employeeService = ServiceLocator().employees;
///       final response = await employeeService.getEmployees();
///
///       if (response.success && response.data != null) {
///         setState(() => employees = response.data!);
///       } else {
///         ScaffoldMessenger.of(context).showSnackBar(
///           SnackBar(content: Text('Error: ${response.message}')),
///         );
///       }
///     } finally {
///       setState(() => isLoading = false);
///     }
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     if (isLoading) return const CircularProgressIndicator();
///     if (employees.isEmpty) return const Text('No employees');
///     
///     return ListView.builder(
///       itemCount: employees.length,
///       itemBuilder: (context, index) => ListTile(
///         title: Text(employees[index].name),
///       ),
///     );
///   }
/// }
/// ```

/// STEP 3: Create Employee Example
/// ```dart
/// Future<void> _createEmployee() async {
///   final employeeService = ServiceLocator().employees;
///   
///   final response = await employeeService.createEmployee(
///     name: 'John Doe',
///     email: 'john@example.com',
///     username: 'johndoe',
///     password: 'password123',
///     departmentId: 1,
///     postId: 1,
///     roleId: 2,
///     joiningDate: '2024-01-15',
///   );
///   
///   if (response.success) {
///     // Employee created successfully
///     print('Employee: ${response.data?.name}');
///   } else {
///     // Handle error
///     print('Error: ${response.message}');
///   }
/// }
/// ```

/// STEP 4: Get Tasks for Project
/// ```dart
/// Future<void> _loadProjectTasks(int projectId) async {
///   final taskService = ServiceLocator().tasks;
///   
///   final response = await taskService.getTasksByProject(projectId);
///   
///   if (response.success && response.data != null) {
///     for (final task in response.data!) {
///       print('Task: ${task.name} - ${task.getStatusLabel()}');
///     }
///   }
/// }
/// ```

/// STEP 5: Update Task Status
/// ```dart
/// Future<void> _updateTaskStatus(int taskId, String newStatus) async {
///   final taskService = ServiceLocator().tasks;
///   
///   final response = await taskService.updateTaskStatus(taskId, newStatus);
///   
///   if (response.success) {
///     print('Task status updated to: ${response.data?.status}');
///   } else {
///     print('Error: ${response.message}');
///   }
/// }
/// ```

/// STEP 6: Handle Authentication Token After Login
/// ```dart
/// Future<void> loginUser(String username, String password) async {
///   // Call your login API endpoint
///   // After successful login, you'll receive a token
///   
///   final token = 'your_jwt_token_here';
///   
///   // Update the service provider with the token
///   ServiceLocator().setToken(token);
///   
///   // Save token for future app launches
///   await saveTokenToStorage(token);
/// }
/// ```

/// STEP 7: Handle Logout
/// ```dart
/// Future<void> logoutUser() async {
///   // Clear token from service provider
///   ServiceLocator().clearToken();
///   
///   // Clear token from storage
///   await clearTokenFromStorage();
///   
///   // Navigate to login screen
///   Navigator.of(context).pushReplacementNamed('/login');
/// }
/// ```

/// AVAILABLE SERVICES
///
/// EmployeeService Methods:
/// - getEmployees() -> List<Employee>
/// - getEmployeeById(int id) -> Employee
/// - createEmployee(...) -> Employee
/// - updateEmployee(int id, ...) -> Employee
/// - deleteEmployee(int id) -> Map
/// - toggleEmployeeStatus(int id) -> Employee
/// - forceLogout(int id) -> Map
/// - changePassword(int id, password, confirmation) -> Map
///
/// TaskService Methods:
/// - getTasks() -> List<Task>
/// - getTaskById(int id) -> Task
/// - getTasksByProject(int projectId) -> List<Task>
/// - createTask(...) -> Task
/// - updateTask(int id, ...) -> Task
/// - deleteTask(int id) -> Map
/// - updateTaskStatus(int id, status) -> Task
/// - addTaskMembers(int id, members) -> Task
/// - removeTaskMember(int id, memberId) -> Task

/// ERROR HANDLING
///
/// ApiResponse structure:
/// ```dart
/// if (response.success) {
///   // Access data
///   var data = response.data;
/// } else {
///   // Handle error
///   String message = response.message;
///   String? error = response.error;
///   int? statusCode = response.statusCode;
/// }
/// ```

/// MODELS
///
/// Employee Model Properties:
/// - id, name, email, phone, username, departmentId, postId, branchId
/// - roleId, gender, dob, address, joiningDate, employmentType, allowHdCheckin
/// - isActive, createdAt, updatedAt
///
/// Task Model Properties:
/// - id, projectId, name, description, startDate, endDate
/// - priority (low/medium/high/urgent), status (not_started/on_hold/in_progress/completed/cancelled)
/// - members (List<int>), createdAt, updatedAt
///
/// Helpful Methods:
/// - task.getStatusLabel() -> Returns human readable status
/// - task.getPriorityColor() -> Returns hex color for priority

class ApiIntegrationGuide {
  // This file is for documentation only
}

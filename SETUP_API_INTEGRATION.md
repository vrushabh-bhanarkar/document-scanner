# API Integration Setup Instructions

## Quick Start

### 1. Update Dependencies
Run this command to get the new HTTP dependency:
```bash
flutter pub get
```

### 2. Initialize in main.dart
Update your `main.dart`:

```dart
import 'package:provider/provider.dart';
import 'services/api_service_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Get saved token if user was logged in before
  // String? savedToken = await SharedPreferences.getInstance().then((prefs) => prefs.getString('auth_token'));
  
  final apiProvider = ApiServiceProvider(token: null); // Add token here after login
  ServiceLocator().initialize(apiProvider);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: apiProvider),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const HomeScreen(),
      // ... rest of your config
    );
  }
}
```

### 3. View Example Implementation
Check `lib/views/employee_task_demo_screen.dart` for a complete working example showing:
- Loading employees from API
- Loading tasks from API
- Creating employees
- Creating tasks
- Deleting items
- Error handling
- Loading states

### 4. Use in Your Screens

#### Example 1: Load Employees
```dart
import 'services/api_service_provider.dart';

class MyScreen extends StatefulWidget {
  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  List<Employee> employees = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    
    try {
      final response = await ServiceLocator().employees.getEmployees();
      
      if (response.success && response.data != null) {
        setState(() => employees = response.data!);
      } else {
        print('Error: ${response.message}');
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const CircularProgressIndicator();
    
    return ListView.builder(
      itemCount: employees.length,
      itemBuilder: (context, index) => ListTile(
        title: Text(employees[index].name),
        subtitle: Text(employees[index].email),
      ),
    );
  }
}
```

#### Example 2: Create Employee
```dart
Future<void> createNewEmployee() async {
  final response = await ServiceLocator().employees.createEmployee(
    name: 'John Doe',
    email: 'john@example.com',
    username: 'johndoe',
    password: 'secure_password',
    departmentId: 1,
    postId: 1,
    roleId: 2,
    joiningDate: '2024-01-20',
  );

  if (response.success) {
    print('Employee created: ${response.data?.name}');
  } else {
    print('Error: ${response.message}');
  }
}
```

#### Example 3: Load and Update Tasks
```dart
Future<void> loadAndUpdateTasks() async {
  // Get all tasks
  final tasksResponse = await ServiceLocator().tasks.getTasks();
  
  if (tasksResponse.success && tasksResponse.data != null) {
    for (final task in tasksResponse.data!) {
      print('Task: ${task.name} - ${task.getStatusLabel()}');
    }
    
    // Update first task status
    if (tasksResponse.data!.isNotEmpty) {
      final firstTask = tasksResponse.data!.first;
      final updateResponse = await ServiceLocator().tasks.updateTaskStatus(
        firstTask.id,
        'completed',
      );
      
      if (updateResponse.success) {
        print('Task updated to: completed');
      }
    }
  }
}
```

## File Structure

```
lib/
├── models/
│   ├── employee_model.dart      # Employee data model
│   ├── task_model.dart          # Task data model
│   └── api_response.dart        # Generic API response wrapper
├── services/
│   ├── api_client.dart          # HTTP client
│   ├── employee_service.dart    # Employee API methods
│   ├── task_service.dart        # Task API methods
│   └── api_service_provider.dart # Service locator & provider
└── views/
    └── employee_task_demo_screen.dart # Complete working example
```

## API Base URL

The API client uses: `https://demohrm.n2nhostings.com/api`

Change this in `lib/services/api_client.dart` if needed:
```dart
static const String baseUrl = 'https://your-api-url.com/api';
```

## Authentication

After user login, set the token:
```dart
final loginResponse = await login(username, password);

if (loginResponse.success) {
  final token = loginResponse.data?.token;
  ServiceLocator().setToken(token);
  
  // Save for next app launch
  await SharedPreferences.getInstance()
    .then((prefs) => prefs.setString('auth_token', token));
}
```

On logout:
```dart
ServiceLocator().clearToken();
await SharedPreferences.getInstance()
  .then((prefs) => prefs.remove('auth_token'));
```

## Common Issues & Solutions

### 1. Token Not Being Used
Make sure to call `ServiceLocator().setToken(token)` after login with a valid JWT token.

### 2. 401 Unauthorized
The API requires authentication. Ensure token is set and valid.

### 3. 422 Validation Error
Check the required fields match the API requirements. The error response will contain details.

### 4. Connection Timeout
Check:
- Internet connection
- API server is running
- Base URL is correct
- No firewall blocking requests

## Available Endpoints

### Employee Endpoints
- `GET /admin/employees` - Get all employees
- `GET /admin/employees/{id}` - Get employee by ID
- `POST /admin/employees` - Create employee
- `POST /admin/employees/{id}/update` - Update employee
- `POST /admin/employees/{id}/delete` - Delete employee
- `POST /admin/employees/{id}/toggle-status` - Toggle active status
- `POST /admin/employees/{id}/force-logout` - Force logout
- `POST /admin/employees/{id}/change-password` - Change password

### Task Endpoints
- `GET /admin/tasks` - Get all tasks
- `GET /admin/tasks/{id}` - Get task by ID
- `POST /admin/tasks` - Create task
- `POST /admin/tasks/{id}/update` - Update task
- `POST /admin/tasks/{id}/delete` - Delete task
- `POST /admin/tasks/{id}/add-members` - Add members
- `POST /admin/tasks/{id}/remove-member` - Remove member

## Need Help?

Refer to:
1. `API_INTEGRATION_GUIDE.md` - Detailed documentation
2. `lib/views/employee_task_demo_screen.dart` - Working example
3. API models in `lib/models/` - Data structures
4. Service classes - Implementation details

## Testing

To test the implementation:
1. Run the example screen: `employee_task_demo_screen.dart`
2. Tap FAB to create items
3. Tap items to view details
4. Pull to refresh to reload data
5. Use popup menus to delete items

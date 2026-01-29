class Task {
  final int id;
  final int projectId;
  final String name;
  final String? description;
  final String startDate;
  final String endDate;
  final String? priority; // low/medium/high/urgent
  final String? status; // not_started/on_hold/in_progress/completed/cancelled
  final List<int>? members;
  final String? createdAt;
  final String? updatedAt;

  Task({
    required this.id,
    required this.projectId,
    required this.name,
    this.description,
    required this.startDate,
    required this.endDate,
    this.priority,
    this.status,
    this.members,
    this.createdAt,
    this.updatedAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as int? ?? 0,
      projectId: json['project_id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      startDate: json['start_date'] as String? ?? '',
      endDate: json['end_date'] as String? ?? '',
      priority: json['priority'] as String?,
      status: json['status'] as String?,
      members: json['members'] != null
          ? List<int>.from(json['members'] as List)
          : null,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'project_id': projectId,
      'name': name,
      'description': description,
      'start_date': startDate,
      'end_date': endDate,
      'priority': priority,
      'status': status,
      'members': members,
    };
  }

  Task copyWith({
    int? id,
    int? projectId,
    String? name,
    String? description,
    String? startDate,
    String? endDate,
    String? priority,
    String? status,
    List<int>? members,
    String? createdAt,
    String? updatedAt,
  }) {
    return Task(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      name: name ?? this.name,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      members: members ?? this.members,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper to get priority color
  String getPriorityColor() {
    switch (priority?.toLowerCase()) {
      case 'urgent':
        return '#FF4444';
      case 'high':
        return '#FF9800';
      case 'medium':
        return '#2196F3';
      case 'low':
        return '#4CAF50';
      default:
        return '#9E9E9E';
    }
  }

  // Helper to get status label
  String getStatusLabel() {
    switch (status?.toLowerCase()) {
      case 'not_started':
        return 'Not Started';
      case 'on_hold':
        return 'On Hold';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status ?? 'Unknown';
    }
  }
}

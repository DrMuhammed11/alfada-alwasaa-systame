class AnalyticsSummary {
  final int total;
  final int incoming;
  final int outgoing;
  final int internal;
  final int closed;
  final int archived;
  final int active;

  AnalyticsSummary({
    this.total = 0,
    this.incoming = 0,
    this.outgoing = 0,
    this.internal = 0,
    this.closed = 0,
    this.archived = 0,
    this.active = 0,
  });

  factory AnalyticsSummary.fromJson(Map<String, dynamic>? json) {
    if (json == null) return AnalyticsSummary();
    return AnalyticsSummary(
      total: json['total'] ?? 0,
      incoming: json['incoming'] ?? 0,
      outgoing: json['outgoing'] ?? 0,
      internal: json['internal'] ?? 0,
      closed: json['closed'] ?? 0,
      archived: json['archived'] ?? 0,
      active: json['active'] ?? 0,
    );
  }
}

class SlaMetrics {
  final int totalTasks;
  final int onTimeTasks;
  final int overdueTasks;
  final int pendingTasks;
  final double complianceRate;

  SlaMetrics({
    this.totalTasks = 0,
    this.onTimeTasks = 0,
    this.overdueTasks = 0,
    this.pendingTasks = 0,
    this.complianceRate = 100.0,
  });

  factory SlaMetrics.fromJson(Map<String, dynamic>? json) {
    if (json == null) return SlaMetrics();
    return SlaMetrics(
      totalTasks: json['totalTasks'] ?? 0,
      onTimeTasks: json['onTimeTasks'] ?? 0,
      overdueTasks: json['overdueTasks'] ?? 0,
      pendingTasks: json['pendingTasks'] ?? 0,
      complianceRate: (json['complianceRate'] is num) ? (json['complianceRate'] as num).toDouble() : 100.0,
    );
  }
}

class PriorityBreakdown {
  final int urgent;
  final int high;
  final int normal;
  final int low;

  PriorityBreakdown({
    this.urgent = 0,
    this.high = 0,
    this.normal = 0,
    this.low = 0,
  });

  factory PriorityBreakdown.fromJson(Map<String, dynamic>? json) {
    if (json == null) return PriorityBreakdown();
    return PriorityBreakdown(
      urgent: json['urgent'] ?? 0,
      high: json['high'] ?? 0,
      normal: json['normal'] ?? 0,
      low: json['low'] ?? 0,
    );
  }
}

class DepartmentStat {
  final String id;
  final String name;
  final String code;
  final int correspondences;
  final int tasksTotal;
  final int tasksCompleted;
  final int tasksPending;
  final double complianceRate;

  DepartmentStat({
    required this.id,
    required this.name,
    required this.code,
    this.correspondences = 0,
    this.tasksTotal = 0,
    this.tasksCompleted = 0,
    this.tasksPending = 0,
    this.complianceRate = 100.0,
  });

  factory DepartmentStat.fromJson(Map<String, dynamic> json) {
    return DepartmentStat(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      correspondences: json['correspondences'] ?? 0,
      tasksTotal: json['tasksTotal'] ?? 0,
      tasksCompleted: json['tasksCompleted'] ?? 0,
      tasksPending: json['tasksPending'] ?? 0,
      complianceRate: (json['complianceRate'] is num) ? (json['complianceRate'] as num).toDouble() : 100.0,
    );
  }
}

class TrendPoint {
  final String date;
  final int incoming;
  final int outgoing;
  final int closed;

  TrendPoint({
    required this.date,
    this.incoming = 0,
    this.outgoing = 0,
    this.closed = 0,
  });

  factory TrendPoint.fromJson(Map<String, dynamic> json) {
    return TrendPoint(
      date: json['date'] ?? '',
      incoming: json['incoming'] ?? 0,
      outgoing: json['outgoing'] ?? 0,
      closed: json['closed'] ?? 0,
    );
  }
}

class AdminAnalyticsData {
  final String period;
  final AnalyticsSummary summary;
  final SlaMetrics sla;
  final PriorityBreakdown priorities;
  final List<DepartmentStat> departmentPerformance;
  final List<TrendPoint> trend;

  AdminAnalyticsData({
    this.period = '30d',
    required this.summary,
    required this.sla,
    required this.priorities,
    this.departmentPerformance = const [],
    this.trend = const [],
  });

  factory AdminAnalyticsData.fromJson(Map<String, dynamic> json) {
    final deptsList = (json['departmentPerformance'] as List? ?? [])
        .map((d) => DepartmentStat.fromJson(d))
        .toList();
    final trendList = (json['trend'] as List? ?? [])
        .map((t) => TrendPoint.fromJson(t))
        .toList();

    return AdminAnalyticsData(
      period: json['period'] ?? '30d',
      summary: AnalyticsSummary.fromJson(json['summary']),
      sla: SlaMetrics.fromJson(json['sla']),
      priorities: PriorityBreakdown.fromJson(json['priorities']),
      departmentPerformance: deptsList,
      trend: trendList,
    );
  }
}

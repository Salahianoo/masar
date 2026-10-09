import 'package:masar/domain/entities/enums.dart';
import 'package:masar/core/utils/json_utils.dart';

class ConceptMastery {
  final String conceptId;
  final String name;
  final double weight;
  final int mastery;
  final int attempts;
  final MasteryStatus status;

  const ConceptMastery({
    required this.conceptId,
    required this.name,
    required this.weight,
    required this.mastery,
    required this.attempts,
    required this.status,
  });

  factory ConceptMastery.fromJson(Map<String, dynamic> json) => ConceptMastery(
        conceptId: json['conceptId'] as String,
        name: json['name'] as String,
        weight: asDouble(json['weight']),
        mastery: asInt(json['mastery']),
        attempts: asInt(json['attempts']),
        status: MasteryStatus.values.byName(json['status'] as String),
      );

  Map<String, dynamic> toJson() => {
        'conceptId': conceptId,
        'name': name,
        'weight': weight,
        'mastery': mastery,
        'attempts': attempts,
        'status': status.name,
      };
}

class SubjectProgress {
  final String subjectId;
  final int readiness;
  final int projectedReadiness;

  /// Sorted by weight, highest first.
  final List<ConceptMastery> concepts;

  const SubjectProgress({
    required this.subjectId,
    required this.readiness,
    required this.projectedReadiness,
    required this.concepts,
  });

  factory SubjectProgress.fromJson(Map<String, dynamic> json) => SubjectProgress(
        subjectId: json['subjectId'] as String,
        readiness: asInt(json['readiness']),
        projectedReadiness: asInt(json['projectedReadiness']),
        concepts: asJsonList(json['concepts']).map(ConceptMastery.fromJson).toList(),
      );

  Map<String, dynamic> toJson() => {
        'subjectId': subjectId,
        'readiness': readiness,
        'projectedReadiness': projectedReadiness,
        'concepts': concepts.map((c) => c.toJson()).toList(),
      };
}

class PlanItem {
  final String conceptId;
  final String conceptName;
  final int count;
  final int done;
  final bool isReview;
  final MasteryStatus status;

  const PlanItem({
    required this.conceptId,
    required this.conceptName,
    required this.count,
    required this.done,
    required this.isReview,
    required this.status,
  });

  bool get isDone => done >= count;

  factory PlanItem.fromJson(Map<String, dynamic> json) => PlanItem(
        conceptId: json['conceptId'] as String,
        conceptName: json['conceptName'] as String,
        count: asInt(json['count']),
        done: asInt(json['done']),
        isReview: json['isReview'] as bool? ?? false,
        status: MasteryStatus.values.byName(json['status'] as String),
      );

  Map<String, dynamic> toJson() => {
        'conceptId': conceptId,
        'conceptName': conceptName,
        'count': count,
        'done': done,
        'isReview': isReview,
        'status': status.name,
      };

  PlanItem copyWith({int? done, MasteryStatus? status}) => PlanItem(
        conceptId: conceptId,
        conceptName: conceptName,
        count: count,
        done: done ?? this.done,
        isReview: isReview,
        status: status ?? this.status,
      );
}

class TodayPlan {
  final String subjectId;
  final int daysLeft;
  final int minutes;
  final List<PlanItem> items;
  final bool completed;

  const TodayPlan({
    required this.subjectId,
    required this.daysLeft,
    required this.minutes,
    required this.items,
    required this.completed,
  });

  int get totalCount => items.fold(0, (sum, i) => sum + i.count);
  int get totalDone => items.fold(0, (sum, i) => sum + (i.done > i.count ? i.count : i.done));

  factory TodayPlan.fromJson(Map<String, dynamic> json) => TodayPlan(
        subjectId: json['subjectId'] as String,
        daysLeft: asInt(json['daysLeft']),
        minutes: asInt(json['minutes']),
        items: asJsonList(json['items']).map(PlanItem.fromJson).toList(),
        completed: json['completed'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'subjectId': subjectId,
        'daysLeft': daysLeft,
        'minutes': minutes,
        'items': items.map((i) => i.toJson()).toList(),
        'completed': completed,
      };

  TodayPlan copyWith({List<PlanItem>? items, bool? completed}) => TodayPlan(
        subjectId: subjectId,
        daysLeft: daysLeft,
        minutes: minutes,
        items: items ?? this.items,
        completed: completed ?? this.completed,
      );
}

class ReadinessPoint {
  final DateTime day;
  final int readiness;

  const ReadinessPoint({required this.day, required this.readiness});

  factory ReadinessPoint.fromJson(Map<String, dynamic> json) => ReadinessPoint(
        day: asDate(json['day']),
        readiness: asInt(json['readiness']),
      );

  Map<String, dynamic> toJson() => {'day': dateToIso(day), 'readiness': readiness};
}

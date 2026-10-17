enum LearningReason {
  travel('Travel'),
  work('Work'),
  family('Family and friends'),
  culture('Culture');

  const LearningReason(this.label);
  final String label;
}

enum SpanishLevel {
  beginner('Brand new'),
  elementary('I know a few words'),
  conversational('I can hold a conversation');

  const SpanishLevel(this.label);
  final String label;
}

enum CancelReason {
  tooExpensive('too_expensive', 'It costs too much'),
  notUsing('not_using', "I'm not using it enough"),
  tooHard('too_hard', 'The lessons are too hard'),
  switchingApp('switching_app', "I'm switching to another app"),
  other('other', 'Something else');

  const CancelReason(this.id, this.label);
  final String id;
  final String label;
}

class OnboardingAnswers {
  const OnboardingAnswers({this.reason, this.level, this.dailyGoalMinutes});

  final LearningReason? reason;
  final SpanishLevel? level;
  final int? dailyGoalMinutes;

  OnboardingAnswers copyWith({LearningReason? reason, SpanishLevel? level, int? dailyGoalMinutes}) =>
      OnboardingAnswers(
        reason: reason ?? this.reason,
        level: level ?? this.level,
        dailyGoalMinutes: dailyGoalMinutes ?? this.dailyGoalMinutes,
      );
}

class User {
  const User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.marketingOptIn,
    required this.onboarded,
    required this.createdAt,
    this.phone,
    this.reason,
    this.level,
    this.dailyGoalMinutes,
  });

  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final bool marketingOptIn;
  final bool onboarded;
  final LearningReason? reason;
  final SpanishLevel? level;
  final int? dailyGoalMinutes;
  final DateTime createdAt;

  String get firstName => fullName.trim().split(RegExp(r'\s+')).first;

  /// Minutes per day the user aims for; 10 when they skipped onboarding.
  int get dailyGoal => dailyGoalMinutes ?? 10;

  User copyWith({bool? onboarded, LearningReason? reason, SpanishLevel? level, int? dailyGoalMinutes}) => User(
        id: id,
        email: email,
        fullName: fullName,
        phone: phone,
        marketingOptIn: marketingOptIn,
        onboarded: onboarded ?? this.onboarded,
        reason: reason ?? this.reason,
        level: level ?? this.level,
        dailyGoalMinutes: dailyGoalMinutes ?? this.dailyGoalMinutes,
        createdAt: createdAt,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'email': email,
        'fullName': fullName,
        'phone': phone,
        'marketingOptIn': marketingOptIn,
        'onboarded': onboarded,
        'reason': reason?.name,
        'level': level?.name,
        'dailyGoalMinutes': dailyGoalMinutes,
        'createdAt': createdAt.toIso8601String(),
      };

  factory User.fromJson(Map<String, Object?> json) => User(
        id: json['id']! as String,
        email: json['email']! as String,
        fullName: json['fullName']! as String,
        phone: json['phone'] as String?,
        marketingOptIn: json['marketingOptIn']! as bool,
        onboarded: json['onboarded']! as bool,
        reason: _byName(LearningReason.values, json['reason']),
        level: _byName(SpanishLevel.values, json['level']),
        dailyGoalMinutes: json['dailyGoalMinutes'] as int?,
        createdAt: DateTime.parse(json['createdAt']! as String),
      );
}

class Session {
  const Session({required this.token, required this.user});

  final String token;
  final User user;

  Map<String, Object?> toJson() => {'token': token, 'user': user.toJson()};

  factory Session.fromJson(Map<String, Object?> json) =>
      Session(token: json['token']! as String, user: User.fromJson((json['user']! as Map).cast()));
}

class Question {
  const Question(this.prompt, this.options, this.answerIndex);

  final String prompt;
  final List<String> options;
  final int answerIndex;
}

class Lesson {
  const Lesson({
    required this.id,
    required this.unit,
    required this.title,
    required this.summary,
    required this.minutes,
    required this.questions,
    this.premium = false,
  });

  final String id;
  final String unit;
  final String title;
  final String summary;
  final int minutes;
  final bool premium;
  final List<Question> questions;
}

class LessonResult {
  const LessonResult({
    required this.lessonId,
    required this.correct,
    required this.total,
    required this.xpEarned,
    required this.minutes,
    required this.completedAt,
  });

  final String lessonId;
  final int correct;
  final int total;
  final int xpEarned;
  final int minutes;
  final DateTime completedAt;

  int get scorePercent => total == 0 ? 0 : (correct * 100 / total).round();

  Map<String, Object?> toJson() => {
        'lessonId': lessonId,
        'correct': correct,
        'total': total,
        'xpEarned': xpEarned,
        'minutes': minutes,
        'completedAt': completedAt.toIso8601String(),
      };

  factory LessonResult.fromJson(Map<String, Object?> json) => LessonResult(
        lessonId: json['lessonId']! as String,
        correct: json['correct']! as int,
        total: json['total']! as int,
        xpEarned: json['xpEarned']! as int,
        minutes: json['minutes']! as int,
        completedAt: DateTime.parse(json['completedAt']! as String),
      );
}

enum BillingPeriod { month, year }

class Plan {
  const Plan({required this.id, required this.title, required this.period, required this.priceCents});

  final String id;
  final String title;
  final BillingPeriod period;
  final int priceCents;
  String get currency => 'USD';
}

enum SubscriptionStatus { active, canceled }

class Subscription {
  const Subscription({required this.planId, required this.status, required this.renewsAt, this.canceledAt});

  final String planId;
  final SubscriptionStatus status;
  final DateTime renewsAt;
  final DateTime? canceledAt;

  /// Premium stays on until the end of the paid period, also after a cancel.
  bool get grantsPremium => renewsAt.isAfter(DateTime.now());

  Map<String, Object?> toJson() => {
        'planId': planId,
        'status': status.name,
        'renewsAt': renewsAt.toIso8601String(),
        'canceledAt': canceledAt?.toIso8601String(),
      };

  factory Subscription.fromJson(Map<String, Object?> json) => Subscription(
        planId: json['planId']! as String,
        status: SubscriptionStatus.values.byName(json['status']! as String),
        renewsAt: DateTime.parse(json['renewsAt']! as String),
        canceledAt: json['canceledAt'] == null ? null : DateTime.parse(json['canceledAt']! as String),
      );
}

class Receipt {
  const Receipt({required this.subscription, required this.amountCents, required this.currency});

  final Subscription subscription;
  final int amountCents;
  final String currency;
}

T? _byName<T extends Enum>(List<T> values, Object? name) {
  if (name is! String) return null;
  for (final value in values) {
    if (value.name == name) return value;
  }
  return null;
}

import 'package:flutter/foundation.dart';

import '../data/lesson_repository.dart';
import '../data/models.dart';
import 'auth_controller.dart';

class LessonCompletion {
  const LessonCompletion(this.result, {required this.reachedDailyGoal});

  final LessonResult result;

  /// True for the lesson that took today's minutes to the daily goal.
  final bool reachedDailyGoal;
}

/// Lessons, the signed-in learner's results, and daily-goal progress.
class ProgressController extends ChangeNotifier {
  ProgressController(this._repository, this._auth) {
    _auth.addListener(_onAuthChanged);
    _onAuthChanged();
  }

  final LessonRepository _repository;
  final AuthController _auth;
  String? _token;
  List<Lesson> _lessons = const [];
  List<LessonResult> _results = const [];

  List<Lesson> get lessons => _lessons;
  List<LessonResult> get results => _results;

  Future<void> loadLessons() async {
    _lessons = await _repository.listLessons();
    notifyListeners();
  }

  Future<Lesson> fetchLesson(String lessonId) => _repository.getLesson(lessonId);

  bool isCompleted(String lessonId) => _results.any((r) => r.lessonId == lessonId);

  int get totalXp => _results.fold(0, (sum, r) => sum + r.xpEarned);

  int minutesOn(DateTime day) => _results
      .where((r) => CalendarDays.isSameDay(r.completedAt.toLocal(), day))
      .fold(0, (sum, r) => sum + r.minutes);

  /// Consecutive days, ending today or yesterday, with at least one lesson.
  int streakDays(DateTime today) {
    var day = CalendarDays.dateOnly(today);
    if (minutesOn(day) == 0) day = day.subtract(const Duration(days: 1));
    var streak = 0;
    while (minutesOn(day) > 0) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  Future<LessonCompletion> completeLesson(String lessonId, List<int> answers) async {
    final token = _token;
    final user = _auth.user;
    if (token == null || user == null) throw StateError('Not signed in');
    final now = DateTime.now();
    final before = minutesOn(now);
    final result = await _repository.completeLesson(token, lessonId, answers);
    _results = [..._results, result];
    notifyListeners();
    final goal = user.dailyGoal;
    return LessonCompletion(result, reachedDailyGoal: before < goal && minutesOn(now) >= goal);
  }

  void _onAuthChanged() {
    final token = _auth.token;
    if (token == _token) return;
    _token = token;
    _results = const [];
    notifyListeners();
    if (token != null) {
      _repository.listResults(token).then((loaded) {
        if (_token != token) return;
        _results = loaded;
        notifyListeners();
      }, onError: (Object _) {});
    }
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }
}

/// Date helpers that don't need a BuildContext.
abstract final class CalendarDays {
  static DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

  static bool isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}

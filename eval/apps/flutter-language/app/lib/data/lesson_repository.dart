import 'auth_repository.dart';
import 'fake_backend.dart';
import 'fixtures.dart';
import 'models.dart';

class LessonRepository {
  LessonRepository(this._backend, this._auth);

  final FakeBackend _backend;
  final AuthRepository _auth;

  Future<List<Lesson>> listLessons() => _backend.request(() => lessons);

  Future<Lesson> getLesson(String id) => _backend.request(() => _find(id));

  Future<List<LessonResult>> listResults(String token) {
    return _backend.request(() {
      final user = _auth.userFor(token);
      final stored = (_backend.table('results')[user.id] as List?) ?? const [];
      return [for (final r in stored) LessonResult.fromJson((r as Map).cast())];
    });
  }

  /// Grades [answers] (one option index per question) and records the result.
  Future<LessonResult> completeLesson(String token, String lessonId, List<int> answers) {
    return _backend.request(() {
      final user = _auth.userFor(token);
      final lesson = _find(lessonId);
      if (answers.length != lesson.questions.length) {
        throw const ApiException('validation_error', 'Answer every question first.');
      }
      var correct = 0;
      for (var i = 0; i < answers.length; i++) {
        if (answers[i] == lesson.questions[i].answerIndex) correct++;
      }
      final result = LessonResult(
        lessonId: lesson.id,
        correct: correct,
        total: lesson.questions.length,
        xpEarned: 5 + correct * 5,
        minutes: lesson.minutes,
        completedAt: DateTime.now().toUtc(),
      );
      final results = _backend.table('results');
      results[user.id] = [...((results[user.id] as List?) ?? const []), result.toJson()];
      return result;
    });
  }

  Lesson _find(String id) {
    for (final lesson in lessons) {
      if (lesson.id == id) return lesson;
    }
    throw const ApiException('not_found', 'That lesson is not available.', status: 404);
  }
}

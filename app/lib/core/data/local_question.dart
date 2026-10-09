import '../models/models.dart';

/// A question plus the fields only the server would know: its answer, its
/// difficulty (learns from answers), and whether its source answer is suspect.
class LocalQuestion {
  final Question question;
  final String answer;
  double difficulty;

  /// The paper's own answer looks wrong (concepts.json → suspect). Kept for
  /// the record, never served in practice.
  final bool flagged;

  LocalQuestion(this.question, this.answer, this.difficulty, {this.flagged = false});
}

/// Reusable form validators for teacher and parent flows.
///
/// Every helper returns a `FormFieldValidator<String>`-compatible function
/// (`String? Function(String?)`) so they can be plugged directly into
/// `TextFormField.validator`. Cross-field rules (e.g. "score must be ≤ max
/// score") are handled in the submit handler — see [Validators.scoreAgainstMax]
/// for a helper that takes the max as a parameter.
class Validators {
  Validators._();

  /// Required, non-empty (after trimming).
  static String? Function(String?) required({
    String label = 'This field',
  }) =>
      (v) {
        if (v == null || v.trim().isEmpty) return '$label is required.';
        return null;
      };

  /// Required text with min/max character bounds.
  static String? Function(String?) text({
    String label = 'This field',
    int min = 1,
    int? max,
    bool requiredField = true,
  }) =>
      (v) {
        final t = (v ?? '').trim();
        if (t.isEmpty) {
          return requiredField ? '$label is required.' : null;
        }
        if (t.length < min) {
          return '$label must be at least $min characters.';
        }
        if (max != null && t.length > max) {
          return '$label must be at most $max characters.';
        }
        return null;
      };

  /// Numeric validator with optional range and integer-only mode.
  static String? Function(String?) number({
    String label = 'Value',
    num? min,
    num? max,
    bool integer = false,
    bool requiredField = true,
  }) =>
      (v) {
        final t = (v ?? '').trim();
        if (t.isEmpty) {
          return requiredField ? '$label is required.' : null;
        }
        final n = num.tryParse(t);
        if (n == null) return '$label must be a number.';
        if (integer && n != n.truncateToDouble()) {
          return '$label must be a whole number.';
        }
        if (min != null && n < min) return '$label must be ≥ $min.';
        if (max != null && n > max) return '$label must be ≤ $max.';
        return null;
      };

  /// Score against a dynamic upper bound. Empty values are allowed (treated
  /// as "no score yet"), since grade entry intentionally supports leaving
  /// students blank.
  static String? Function(String?) scoreAgainstMax(num maxScore) =>
      (v) {
        final t = (v ?? '').trim();
        if (t.isEmpty) return null;
        final n = num.tryParse(t);
        if (n == null) return 'Score must be a number.';
        if (n < 0) return 'Score cannot be negative.';
        if (n > maxScore) return 'Score cannot exceed $maxScore.';
        return null;
      };

  /// Simple phone validator: 7–15 digits, optional leading +. Empty allowed
  /// unless `requiredField` is true.
  static String? Function(String?) phone({bool requiredField = false}) =>
      (v) {
        final t = (v ?? '').trim();
        if (t.isEmpty) {
          return requiredField ? 'Phone is required.' : null;
        }
        final cleaned = t.replaceAll(RegExp(r'[\s\-()]'), '');
        if (!RegExp(r'^\+?\d{7,15}$').hasMatch(cleaned)) {
          return 'Enter a valid phone number.';
        }
        return null;
      };

  /// Email format check. Empty allowed unless `requiredField` is true.
  static String? Function(String?) email({bool requiredField = true}) =>
      (v) {
        final t = (v ?? '').trim();
        if (t.isEmpty) {
          return requiredField ? 'Email is required.' : null;
        }
        if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(t)) {
          return 'Enter a valid email address.';
        }
        return null;
      };

  /// Password with a minimum length.
  static String? Function(String?) password({int minLength = 6}) =>
      (v) {
        final t = v ?? '';
        if (t.isEmpty) return 'Password is required.';
        if (t.length < minLength) {
          return 'Password must be at least $minLength characters.';
        }
        return null;
      };

  /// Conduct grade: A/B/C/D/E/F with optional + or -, OR a number 0–100.
  static String? Function(String?) conductGrade({bool requiredField = false}) =>
      (v) {
        final t = (v ?? '').trim();
        if (t.isEmpty) {
          return requiredField ? 'Conduct grade is required.' : null;
        }
        if (RegExp(r'^[A-Fa-f][+\-]?$').hasMatch(t)) return null;
        final n = num.tryParse(t);
        if (n != null && n >= 0 && n <= 100) return null;
        return 'Use a letter (A–F, optional +/-) or a number 0–100.';
      };

  /// Returns null if [date] is today or in the future, else an error.
  static String? dateNotInPast(DateTime? date, {String label = 'Date'}) {
    if (date == null) return '$label is required.';
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    if (date.isBefore(startOfToday)) return '$label cannot be in the past.';
    return null;
  }
}

/// Input validation for the onboarding / login forms.
abstract final class Validators {
  static final RegExp _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? name(String? value) {
    if ((value ?? '').trim().length < 2) return 'Enter your full name';
    return null;
  }

  static String? email(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Enter your work email';
    if (!_email.hasMatch(text)) return "That email doesn't look right";
    return null;
  }

  static String? password(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return 'Enter your password';
    if (text.length < 6) return 'Use at least 6 characters';
    return null;
  }
}

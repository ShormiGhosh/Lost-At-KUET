class KuetEmailValidator {
  static bool isValidStudentEmail(String email) {
    final RegExp studentPattern = RegExp(
      r'^[a-zA-Z]+[0-9]{7}@stud\.kuet\.ac\.bd$',
      caseSensitive: false,
    );
    return studentPattern.hasMatch(email.toLowerCase());
  }

  static bool isValidTeacherEmail(String email) {
    final RegExp teacherPattern = RegExp(
      r'^[a-zA-Z.]+@[a-zA-Z]+\.kuet\.ac\.bd$',
      caseSensitive: false,
    );
    return teacherPattern.hasMatch(email.toLowerCase());
  }

  static bool isKuetEmail(String email) {
    return isValidStudentEmail(email) || isValidTeacherEmail(email);
  }
}
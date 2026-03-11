import 'package:intl/intl.dart' as intl;

class AppDateUtils {
  AppDateUtils._();

  static String formatDate(DateTime date) =>
      intl.DateFormat('yyyy-MM-dd').format(date);

  static String formatTime(DateTime date) =>
      intl.DateFormat('HH:mm').format(date);

  static String formatDateTime(DateTime date) =>
      intl.DateFormat('yyyy-MM-dd HH:mm').format(date);

  static String formatReadable(DateTime date) =>
      intl.DateFormat('MMM dd, yyyy').format(date);
}

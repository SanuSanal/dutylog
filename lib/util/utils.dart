import 'package:intl/intl.dart';

String getSheetNameFromDate(DateTime now) {
  DateFormat formatter = DateFormat('MMM_yyyy');
  return formatter.format(now);
}

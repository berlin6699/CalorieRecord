/// Calendar spacing, independent of local daylight-saving transitions.
double chartDayOffset(DateTime date, DateTime origin) =>
    DateTime.utc(date.year, date.month, date.day)
        .difference(DateTime.utc(origin.year, origin.month, origin.day))
        .inDays
        .toDouble();

DateTime chartDateAt(DateTime origin, double offset) =>
    DateTime(origin.year, origin.month, origin.day + offset.round());

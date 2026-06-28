class RemainingTime {
  const RemainingTime({
    required this.months,
    required this.days,
    required this.hours,
    required this.minutes,
    required this.expired,
  });

  final int months;
  final int days;
  final int hours;
  final int minutes;
  final bool expired;

  static const expiredState = RemainingTime(
    months: 0,
    days: 0,
    hours: 0,
    minutes: 0,
    expired: true,
  );
}

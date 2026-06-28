import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/countly_colors.dart';
import '../utils/countdown_utils.dart';
class CountlyDatePickerField extends StatefulWidget {
  const CountlyDatePickerField({
    super.key,
    required this.value,
    required this.currentTime,
    required this.onChanged,
    this.compact = false,
  });

  final String value;
  final DateTime currentTime;
  final ValueChanged<String> onChanged;
  final bool compact;

  @override
  State<CountlyDatePickerField> createState() => _CountlyDatePickerFieldState();
}

class _CountlyDatePickerFieldState extends State<CountlyDatePickerField> {
  late final TextEditingController _controller;
  late DateTime _visibleMonth;
  bool _pickerOpen = false;
  String? _lastEmittedValue;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.value.isEmpty ? '' : formatBrazilianDateInput(widget.value),
    );
    _lastEmittedValue = widget.value.isEmpty ? null : normalizeTargetDate(widget.value);
    _visibleMonth = _resolveInitialVisibleMonth();
    _controller.addListener(_handleInputChanged);
  }

  DateTime _resolveInitialVisibleMonth() {
    if (widget.value.isNotEmpty) {
      final localDate = isoDateToLocalDate(normalizeTargetDate(widget.value));
      if (localDate != null) {
        return getMonthStart(localDate);
      }
    }
    return getMonthStart(widget.currentTime);
  }

  @override
  void didUpdateWidget(covariant CountlyDatePickerField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && widget.value != _lastEmittedValue) {
      _controller.text = widget.value.isEmpty ? '' : formatBrazilianDateInput(widget.value);
      _lastEmittedValue = widget.value.isEmpty ? null : normalizeTargetDate(widget.value);
      final localDate = widget.value.isEmpty ? null : isoDateToLocalDate(_lastEmittedValue!);
      if (localDate != null) {
        _visibleMonth = getMonthStart(localDate);
      }
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleInputChanged);
    _controller.dispose();
    super.dispose();
  }

  void _handleInputChanged() {
    final draft = _controller.text;
    _syncVisibleMonthFromDraft(draft);

    final digits = draft.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 8) {
      return;
    }

    final normalized = normalizeTargetDate(draft);
    final localDate = isoDateToLocalDate(normalized);
    if (localDate == null || isDateBeforeToday(localDate, widget.currentTime)) {
      return;
    }

    if (_lastEmittedValue != normalized) {
      _lastEmittedValue = normalized;
      widget.onChanged(normalized);
    }
  }

  void _syncVisibleMonthFromDraft(String text) {
    final digits = text.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 4) {
      if (!_pickerOpen && digits.isNotEmpty) {
        setState(() => _pickerOpen = true);
      }
      return;
    }

    final month = int.tryParse(digits.substring(2, 4));
    if (month == null || month < 1 || month > 12) {
      return;
    }

    var year = widget.currentTime.year;
    if (digits.length >= 8) {
      final parsedYear = int.tryParse(digits.substring(4, 8));
      if (parsedYear != null && parsedYear >= 1900) {
        year = parsedYear;
      }
    }

    final nextMonth = DateTime(year, month);
    final shouldOpenPicker = !_pickerOpen;
    final monthChanged = nextMonth.year != _visibleMonth.year || nextMonth.month != _visibleMonth.month;

    if (monthChanged || shouldOpenPicker) {
      setState(() {
        _visibleMonth = getMonthStart(nextMonth);
        _pickerOpen = true;
      });
    }
  }
  DateTime get _currentMonthStart => getMonthStart(widget.currentTime);

  bool get _isViewingFutureMonth => isMonthAfterReference(_visibleMonth, _currentMonthStart);

  bool get _canGoToPreviousMonth => _isViewingFutureMonth;

  void _openPicker() {
    if (isMonthBeforeReference(_visibleMonth, _currentMonthStart)) {
      _visibleMonth = _currentMonthStart;
    }
    setState(() => _pickerOpen = true);
  }

  void _selectDate(DateTime date) {
    if (isDateBeforeToday(date, widget.currentTime)) {
      return;
    }

    final iso = toDateInputValue(date);
    widget.onChanged(iso);
    _lastEmittedValue = iso;
    _controller.text = formatBrazilianDateInput(iso);
    setState(() {
      _visibleMonth = getMonthStart(date);
      _pickerOpen = false;
    });
  }

  void _commitInput() {
    final draft = _controller.text.trim();
    if (draft.isEmpty) {
      _lastEmittedValue = null;
      widget.onChanged('');
      return;
    }
    final normalized = normalizeTargetDate(draft);
    final localDate = isoDateToLocalDate(normalized);
    if (localDate == null || isDateBeforeToday(localDate, widget.currentTime)) {
      _controller.text = widget.value.isEmpty ? '' : formatBrazilianDateInput(widget.value);
      return;
    }

    widget.onChanged(normalized);
    _lastEmittedValue = normalized;
    _controller.text = formatBrazilianDateInput(normalized);    setState(() => _visibleMonth = getMonthStart(localDate));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.countlyColors;
    final calendarDays = getMonthCalendarDays(_visibleMonth.year, _visibleMonth.month);
    final fieldHeight = widget.compact ? 44.0 : 52.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: fieldHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.borderStrong),
            color: colors.input,
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: _openPicker,
                icon: Icon(Icons.calendar_today_rounded, size: 18, color: colors.muted),
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  onTap: _openPicker,
                  inputFormatters: const [BrazilianDateInputFormatter()],
                  onSubmitted: (_) {
                    _commitInput();
                    setState(() => _pickerOpen = false);
                  },
                  onEditingComplete: () {
                    _commitInput();
                    setState(() => _pickerOpen = false);
                  },
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'dd/mm/aaaa',
                    hintStyle: TextStyle(color: colors.softMuted),
                  ),
                  style: TextStyle(color: colors.inputText, fontSize: 14),
                ),
              ),              IconButton(
                onPressed: () => setState(() => _pickerOpen = !_pickerOpen),
                icon: Icon(
                  _pickerOpen ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                  size: 20,
                  color: colors.muted,
                ),
              ),
            ],
          ),
        ),
        if (_pickerOpen) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.border),
              color: colors.card,
              boxShadow: [
                BoxShadow(
                  color: colors.text.withValues(alpha: 0.12),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 68,
                      child: Row(
                        children: [
                          if (_canGoToPreviousMonth)
                            _CalendarNavButton(
                              icon: Icons.chevron_left_rounded,
                              colors: colors,
                              onTap: () => setState(() {
                                _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1);
                              }),
                            )
                          else
                            const SizedBox(width: 34),
                          if (_isViewingFutureMonth)
                            _CalendarNavButton(
                              icon: Icons.undo_rounded,
                              colors: colors,
                              onTap: () => setState(() => _visibleMonth = _currentMonthStart),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Text(
                        formatCalendarMonth(_visibleMonth),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colors.text,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    _CalendarNavButton(
                      icon: Icons.chevron_right_rounded,
                      colors: colors,
                      onTap: () => setState(() {
                        _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1);
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb']
                      .map(
                        (weekday) => Expanded(
                          child: Text(
                            weekday,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: colors.softMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 7),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: calendarDays.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                  ),
                  itemBuilder: (context, index) {
                    final date = calendarDays[index];
                    if (date == null) {
                      return const SizedBox.shrink();
                    }

                    final iso = toDateInputValue(date);
                    final isSelected = widget.value == iso;
                    final isDisabled = isDateBeforeToday(date, widget.currentTime);

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: isDisabled ? null : () => _selectDate(date),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            gradient: isSelected
                                ? LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [colors.accent, colors.accentDark],
                                  )
                                : null,
                            color: isSelected ? null : Colors.transparent,
                          ),
                          child: Text(
                            '${date.day}',
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : isDisabled
                                      ? colors.softMuted.withValues(alpha: 0.45)
                                      : colors.text,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class BrazilianDateInputFormatter extends TextInputFormatter {
  const BrazilianDateInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(text: '', selection: TextSelection.collapsed(offset: 0));
    }

    final limited = digits.length > 8 ? digits.substring(0, 8) : digits;
    final buffer = StringBuffer();

    for (var index = 0; index < limited.length; index++) {
      if (index == 2 || index == 4) {
        buffer.write('/');
      }
      buffer.write(limited[index]);
    }

    final formatted = buffer.toString();
    final selectionOffset = _cursorOffsetForDigitCount(
      formatted,
      _digitCountBeforeCursor(newValue.text, newValue.selection.baseOffset),
    );

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: selectionOffset),
    );
  }

  int _digitCountBeforeCursor(String text, int cursor) {
    final safeCursor = cursor.clamp(0, text.length);
    return text.substring(0, safeCursor).replaceAll(RegExp(r'\D'), '').length;
  }

  int _cursorOffsetForDigitCount(String formatted, int digitCount) {
    if (digitCount <= 0) {
      return 0;
    }

    var seenDigits = 0;
    for (var index = 0; index < formatted.length; index++) {
      if (formatted[index] != '/') {
        seenDigits++;
      }
      if (seenDigits >= digitCount) {
        return index + 1;
      }
    }

    return formatted.length;
  }
}

class _CalendarNavButton extends StatelessWidget {  const _CalendarNavButton({
    required this.icon,
    required this.colors,
    required this.onTap,
  });

  final IconData icon;
  final CountlyColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 34,
      child: Material(
        color: colors.accentSoft,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Icon(icon, size: 17, color: colors.muted),
        ),
      ),
    );
  }
}

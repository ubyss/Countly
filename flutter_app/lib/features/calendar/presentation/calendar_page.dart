import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/widgets/round_icon_button.dart';
import '../../counters/domain/counter.dart';
import '../../counters/presentation/counter_detail_page.dart';
import '../../counters/presentation/counter_editor_sheet.dart';
import '../domain/calendar_events.dart';
import 'widgets/agenda_view.dart';
import 'widgets/day_panel.dart';
import 'widgets/month_view.dart';

const _basePageIndex = 1200;

enum _CalendarMode { month, agenda }

/// Página de calendário: visão mensal com swipe entre meses, linha do
/// tempo do dia selecionado e modo agenda contínua.
class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final PageController _pageController =
      PageController(initialPage: _basePageIndex);

  late final DateTime _baseMonth;
  late DateTime _visibleMonth;
  DateTime _selectedDay = dateOnly(DateTime.now());
  _CalendarMode _mode = _CalendarMode.month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _baseMonth = DateTime(now.year, now.month);
    _visibleMonth = _baseMonth;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  DateTime _monthForPage(int page) =>
      DateTime(_baseMonth.year, _baseMonth.month + (page - _basePageIndex));

  void _goToToday() {
    final today = dateOnly(DateTime.now());
    setState(() => _selectedDay = today);
    _pageController.animateToPage(
      _basePageIndex,
      duration: Motion.slow,
      curve: Motion.emphasized,
    );
  }

  void _openCounter(Counter counter) {
    Navigator.of(context).push(
      SoftSlideRoute(builder: (_) => CounterDetailPage(counterId: counter.id)),
    );
  }

  void _quickAdd(DateTime day) {
    showCounterEditorSheet(context, initialDate: day);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final controller = AppScope.of(context).counters;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(Gap.page, Gap.x4, Gap.page, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: Motion.base,
                        switchInCurve: Motion.standard,
                        switchOutCurve: Motion.standard,
                        transitionBuilder: (child, animation) =>
                            FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.2),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        ),
                        child: Text(
                          _mode == _CalendarMode.month
                              ? formatMonthYear(_visibleMonth)
                              : 'Agenda',
                          key: ValueKey(
                            _mode == _CalendarMode.month
                                ? formatMonthYear(_visibleMonth)
                                : 'agenda',
                          ),
                          style: AppType.largeTitle(palette)
                              .copyWith(fontSize: 26),
                        ),
                      ),
                    ),
                    RoundIconButton(
                      icon: Icons.today_rounded,
                      tooltip: 'Ir para hoje',
                      onTap: _goToToday,
                    ),
                    const SizedBox(width: Gap.x2),
                    _ModeToggle(
                      mode: _mode,
                      onChanged: (mode) => setState(() => _mode = mode),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Gap.x3),
              Expanded(
                child: AnimatedSwitcher(
                  duration: Motion.base,
                  switchInCurve: Motion.standard,
                  switchOutCurve: Motion.standard,
                  child: _mode == _CalendarMode.agenda
                      ? AgendaView(
                          key: const ValueKey('agenda'),
                          counters: controller.active,
                          onOpenCounter: _openCounter,
                        )
                      : _buildMonthMode(controller.active),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMonthMode(List<Counter> counters) {
    return Column(
      key: const ValueKey('month'),
      children: [
        Expanded(
          flex: 11,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (page) =>
                setState(() => _visibleMonth = _monthForPage(page)),
            itemBuilder: (context, page) {
              final month = _monthForPage(page);
              final events = eventsForRange(
                counters,
                DateTime(month.year, month.month, 1),
                DateTime(month.year, month.month + 1, 0),
              );
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: Gap.page),
                child: MonthGrid(
                  month: month,
                  events: events,
                  selectedDay: _selectedDay,
                  onSelectDay: (day) => setState(() => _selectedDay = day),
                  onQuickAdd: _quickAdd,
                ),
              );
            },
          ),
        ),
        Expanded(
          flex: 9,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(Gap.page, Gap.x2, Gap.page, 130),
            child: AnimatedSwitcher(
              duration: Motion.base,
              switchInCurve: Motion.standard,
              switchOutCurve: Motion.standard,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.04),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: DayPanel(
                day: _selectedDay,
                events: eventsForRange(
                  counters,
                  _selectedDay,
                  _selectedDay,
                )[dateOnly(_selectedDay)] ??
                    const [],
                onOpenCounter: _openCounter,
                onAddForDay: _quickAdd,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.mode, required this.onChanged});

  final _CalendarMode mode;
  final ValueChanged<_CalendarMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    Widget item(_CalendarMode value, IconData icon, String label) {
      final selected = mode == value;
      return Pressable(
        onTap: () => onChanged(value),
        pressedScale: 0.9,
        semanticLabel: label,
        child: AnimatedContainer(
          duration: Motion.base,
          curve: Motion.emphasized,
          width: 40,
          height: 34,
          decoration: BoxDecoration(
            color: selected ? palette.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(Corner.pill),
            boxShadow: selected ? Elevations.soft(palette) : null,
          ),
          child: Icon(
            icon,
            size: 19,
            color: selected ? palette.accent : palette.textTertiary,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: palette.surfaceSunken,
        borderRadius: BorderRadius.circular(Corner.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          item(_CalendarMode.month, Icons.calendar_view_month_rounded, 'Mês'),
          item(_CalendarMode.agenda, Icons.view_agenda_rounded, 'Agenda'),
        ],
      ),
    );
  }
}

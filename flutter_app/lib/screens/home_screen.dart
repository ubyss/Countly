import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:uuid/uuid.dart';

import '../models/countdown.dart';
import '../models/repeat_mode.dart';
import '../services/countdown_platform_sync.dart';
import '../services/countdown_storage.dart';
import '../theme/countly_colors.dart';
import '../utils/countdown_utils.dart';
import '../widgets/countdown_card.dart';
import '../widgets/creation_sheet.dart';
import '../widgets/liquid_glass_bar.dart';
import '../widgets/year_calendar.dart';

enum CountdownViewMode { carousel, single, grid }

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.isDark,
    required this.onThemeChanged,
  });

  final bool isDark;
  final ValueChanged<bool> onThemeChanged;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _storage = CountdownStorage();
  final _uuid = const Uuid();

  List<Countdown> _countdowns = [];
  CountlyNavTab _activeTab = CountlyNavTab.countdowns;
  String _sortMode = 'soonest';
  CountdownViewMode _viewMode = CountdownViewMode.carousel;
  final ValueNotifier<DateTime> _currentTime = ValueNotifier(DateTime.now());
  String? _editingId;
  bool _loaded = false;

  @override
  void dispose() {
    _currentTime.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadCountdowns();
    _startClock();
  }

  Future<void> _loadCountdowns() async {
    final stored = await _storage.load();
    if (!mounted) {
      return;
    }
    setState(() {
      _countdowns = stored;
      _loaded = true;
    });
    await CountdownPlatformSync.sync(stored);
  }

  void _startClock() {
    Future<void>.delayed(const Duration(seconds: 1), () {
      if (!mounted) {
        return;
      }
      setState(() => _currentTime.value = DateTime.now());
      _startClock();
    });
  }

  Future<void> _persist() async {
    if (!_loaded) {
      return;
    }
    await _storage.save(_countdowns);
    await CountdownPlatformSync.sync(_countdowns);
  }

  List<Countdown> get _visibleCountdowns {
    final sorted = [..._countdowns];
    sorted.sort((first, second) {
      final firstTime = getTargetEndTimestamp(normalizeTargetDate(first.targetDate)) ?? 0;
      final secondTime = getTargetEndTimestamp(normalizeTargetDate(second.targetDate)) ?? 0;
      return _sortMode == 'soonest' ? firstTime.compareTo(secondTime) : secondTime.compareTo(firstTime);
    });
    return sorted;
  }

  void _openCreation({Countdown? editing}) {
    setState(() => _editingId = editing?.id);
    showCreationSheet(
      context: context,
      currentTime: _currentTime,
      editing: editing,
      onSubmit: ({
        required String name,
        required String targetDate,
        required CountlyRepeatMode repeat,
        String? imageBase64,
      }) {
        final saved = Countdown(
          id: editing?.id ?? _uuid.v4(),
          name: name,
          targetDate: targetDate,
          repeat: repeat,
          imageBase64: imageBase64,
        );

        setState(() {
          if (editing != null) {
            _countdowns = _countdowns
                .map((item) => item.id == editing.id ? saved : item)
                .toList();
          } else {
            _countdowns = [saved, ..._countdowns];
          }
          _editingId = null;
        });
        _persist();
      },
    ).whenComplete(() => setState(() => _editingId = null));
  }

  void _removeCountdown(String id) {
    setState(() {
      _countdowns = _countdowns.where((item) => item.id != id).toList();
      if (_editingId == id) {
        _editingId = null;
      }
    });
    _persist();
  }

  @override
  Widget build(BuildContext context) {
    final colors = CountlyColors.forDark(widget.isDark);
    final visibleCountdowns = _visibleCountdowns;

    return GlassPage(
      child: Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.page,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colors.accent.withValues(alpha: widget.isDark ? 0.11 : 0.07),
              colors.page,
            ],
            stops: const [0, 0.42],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _CountlyHeader(
                colors: colors,
                isDark: widget.isDark,
                onThemeToggle: () => widget.onThemeChanged(!widget.isDark),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: _activeTab == CountlyNavTab.countdowns
                      ? _CountdownsView(
                          key: const ValueKey('countdowns'),
                          colors: colors,
                          isDark: widget.isDark,
                          countdowns: visibleCountdowns,
                          currentTime: _currentTime,
                          sortMode: _sortMode,
                          onSortChanged: (value) => setState(() => _sortMode = value),
                          viewMode: _viewMode,
                          onViewModeChanged: (value) => setState(() => _viewMode = value),
                          onEdit: (countdown) => _openCreation(editing: countdown),
                          onRemove: _removeCountdown,
                        )
                      : _CalendarTabView(
                          key: const ValueKey('calendar'),
                          colors: colors,
                          isDark: widget.isDark,
                          countdowns: visibleCountdowns,
                          currentTime: _currentTime,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: LiquidGlassBar(
        activeTab: _activeTab,
        isDark: widget.isDark,
        onTabChanged: (tab) => setState(() => _activeTab = tab),
        onAddPressed: () => _openCreation(),
      ),
    ),
    );
  }
}

class _CountlyHeader extends StatelessWidget {
  const _CountlyHeader({
    required this.colors,
    required this.isDark,
    required this.onThemeToggle,
  });

  final CountlyColors colors;
  final bool isDark;
  final VoidCallback onThemeToggle;

  @override
  Widget build(BuildContext context) {
    final logoColor = isDark ? colors.text : Colors.white;
    final toggleBorder = isDark ? colors.border : Colors.white.withValues(alpha: 0.32);
    final toggleFill = isDark ? colors.card : Colors.white.withValues(alpha: 0.14);
    final toggleIcon = isDark ? colors.text : Colors.white;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
      child: Row(
        children: [
          SvgPicture.asset(
            'assets/Logo-name.svg',
            height: 28,
            colorFilter: ColorFilter.mode(logoColor, BlendMode.srcIn),
          ),
          const Spacer(),
          Tooltip(
            message: isDark ? 'Tema claro' : 'Tema escuro',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onThemeToggle,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: toggleBorder),
                    color: toggleFill,
                  ),
                  child: Icon(
                    isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                    size: 20,
                    color: toggleIcon,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CountdownsView extends StatelessWidget {
  const _CountdownsView({
    super.key,
    required this.colors,
    required this.isDark,
    required this.countdowns,
    required this.currentTime,
    required this.sortMode,
    required this.onSortChanged,
    required this.viewMode,
    required this.onViewModeChanged,
    required this.onEdit,
    required this.onRemove,
  });

  final CountlyColors colors;
  final bool isDark;
  final List<Countdown> countdowns;
  final ValueListenable<DateTime> currentTime;
  final String sortMode;
  final ValueChanged<String> onSortChanged;
  final CountdownViewMode viewMode;
  final ValueChanged<CountdownViewMode> onViewModeChanged;
  final void Function(Countdown countdown) onEdit;
  final void Function(String id) onRemove;

  Widget _buildCard(Countdown countdown) {
    return CountdownCard(
      countdown: countdown,
      currentTime: currentTime,
      onEdit: () => onEdit(countdown),
      onRemove: () => onRemove(countdown.id),
    );
  }

  Widget _buildCountdownLayout(double maxWidth) {
    switch (viewMode) {
      case CountdownViewMode.carousel:
        return _CountdownCarousel(
          countdowns: countdowns,
          currentTime: currentTime,
          onEdit: onEdit,
          onRemove: onRemove,
        );
      case CountdownViewMode.single:
        const targetCardHeight = 480.0;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 1,
            mainAxisSpacing: 14,
            childAspectRatio: maxWidth / targetCardHeight,
          ),
          itemCount: countdowns.length,
          itemBuilder: (context, index) => _buildCard(countdowns[index]),
        );
      case CountdownViewMode.grid:
        const spacing = 12.0;
        const targetCardHeight = 290.0;
        const crossAxisCount = 2;
        final itemWidth = (maxWidth - spacing) / crossAxisCount;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: itemWidth / targetCardHeight,
          ),
          itemCount: countdowns.length,
          itemBuilder: (context, index) => _buildCard(countdowns[index]),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleColor = isDark ? colors.text : Colors.white;
    final subtitleColor = isDark ? colors.muted : Colors.white.withValues(alpha: 0.78);

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
          sliver: SliverToBoxAdapter(
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Suas contagens',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  _CountBadge(count: countdowns.length, colors: colors, isDark: isDark),
                ],
              ),
              if (countdowns.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    _ViewModeSelector(
                      viewMode: viewMode,
                      colors: colors,
                      isDark: isDark,
                      onChanged: onViewModeChanged,
                    ),
                    const Spacer(),
                    if (countdowns.length > 1)
                      _SortToggleButton(
                        sortMode: sortMode,
                        colors: colors,
                        isDark: isDark,
                        onToggle: () => onSortChanged(sortMode == 'soonest' ? 'latest' : 'soonest'),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 9),
              Text(
                'Crie e acompanhe seus momentos importantes.',
                style: TextStyle(color: subtitleColor, fontSize: 14),
              ),
            ],
            ),
          ),
        ),
        if (countdowns.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Center(
                child: Text(
                  'Você ainda não tem contagens.\nToque no + para adicionar uma.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.muted,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            sliver: SliverToBoxAdapter(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: KeyedSubtree(
                      key: ValueKey(viewMode),
                      child: _buildCountdownLayout(constraints.maxWidth),
                    ),
                  );
                },
              ),
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
          sliver: SliverToBoxAdapter(
            child: _LocalTimezoneNote(colors: colors),
          ),
        ),
      ],
    );
  }
}

class _CountdownCarousel extends StatefulWidget {
  const _CountdownCarousel({
    required this.countdowns,
    required this.currentTime,
    required this.onEdit,
    required this.onRemove,
  });

  final List<Countdown> countdowns;
  final ValueListenable<DateTime> currentTime;
  final void Function(Countdown countdown) onEdit;
  final void Function(String id) onRemove;

  @override
  State<_CountdownCarousel> createState() => _CountdownCarouselState();
}

class _CountdownCarouselState extends State<_CountdownCarousel> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.88);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 400,
      child: PageView.builder(
        controller: _pageController,
        clipBehavior: Clip.hardEdge,
        padEnds: false,
        itemCount: widget.countdowns.length,
        itemBuilder: (context, index) {
          final countdown = widget.countdowns[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: CountdownCard(
              countdown: countdown,
              currentTime: widget.currentTime,
              showShadow: false,
              onEdit: () => widget.onEdit(countdown),
              onRemove: () => widget.onRemove(countdown.id),
            ),
          );
        },
      ),
    );
  }
}

class _CalendarTabView extends StatelessWidget {
  const _CalendarTabView({
    super.key,
    required this.colors,
    required this.isDark,
    required this.countdowns,
    required this.currentTime,
  });

  final CountlyColors colors;
  final bool isDark;
  final List<Countdown> countdowns;
  final ValueListenable<DateTime> currentTime;

  @override
  Widget build(BuildContext context) {
    final titleColor = isDark ? colors.text : Colors.white;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
      children: [
        ValueListenableBuilder<DateTime>(
          valueListenable: currentTime,
          builder: (context, time, _) {
            return Row(
              children: [
                Text(
                  'Calendário ${time.year}',
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 14),
                _CountBadge(count: countdowns.length, colors: colors, isDark: isDark),
              ],
            );
          },
        ),
        const SizedBox(height: 14),
        ValueListenableBuilder<DateTime>(
          valueListenable: currentTime,
          builder: (context, time, _) {
            final nextEvent = findNextUpcomingCountdown(countdowns, time);
            if (nextEvent == null) {
              return const SizedBox.shrink();
            }

            final message = formatTimeUntilNextEvent(
              nextEvent.targetDate,
              time,
              eventName: nextEvent.name,
            );

            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: colors.accentSoft,
                border: Border.all(color: colors.accent.withValues(alpha: 0.22)),
              ),
              child: Row(
                children: [
                  FaIcon(
                    FontAwesomeIcons.hourglassHalf,
                    size: 14,
                    color: colors.accent,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      message,
                      style: TextStyle(
                        color: isDark ? colors.text : colors.accentDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        if (countdowns.isEmpty)
          Container(
            height: 128,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.borderStrong, style: BorderStyle.solid),
              color: colors.card,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy_rounded, color: colors.muted),
                const SizedBox(width: 12),
                Text('Nenhuma contagem criada.', style: TextStyle(color: colors.muted)),
              ],
            ),
          )
        else
          YearCalendarView(
            countdowns: countdowns,
            currentTime: currentTime,
          ),
        const SizedBox(height: 24),
        _LocalTimezoneNote(colors: colors),
      ],
    );
  }
}

class _LocalTimezoneNote extends StatelessWidget {
  const _LocalTimezoneNote({required this.colors});

  final CountlyColors colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(Icons.public_rounded, size: 17, color: colors.softMuted),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Text(
            'Os horários são exibidos no seu fuso local',
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.softMuted, fontSize: 14, height: 1.4),
          ),
        ),
      ],
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({
    required this.count,
    required this.colors,
    required this.isDark,
  });

  final int count;
  final CountlyColors colors;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final badgeFill = isDark ? colors.accentSoft : Colors.white.withValues(alpha: 0.2);
    final badgeText = isDark ? colors.muted : Colors.white;

    return Container(
      constraints: const BoxConstraints(minWidth: 26),
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: badgeFill,
      ),
      child: Text(
        '$count',
        style: TextStyle(
          color: badgeText,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ViewModeSelector extends StatelessWidget {
  const _ViewModeSelector({
    required this.viewMode,
    required this.colors,
    required this.isDark,
    required this.onChanged,
  });

  final CountdownViewMode viewMode;
  final CountlyColors colors;
  final bool isDark;
  final ValueChanged<CountdownViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final fill = isDark ? colors.card.withValues(alpha: 0.7) : Colors.white.withValues(alpha: 0.16);
    final border = isDark ? colors.border : Colors.white.withValues(alpha: 0.28);

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: fill,
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ViewModeButton(
            tooltip: 'Carrossel',
            icon: Icons.view_carousel_outlined,
            selected: viewMode == CountdownViewMode.carousel,
            colors: colors,
            isDark: isDark,
            onTap: () => onChanged(CountdownViewMode.carousel),
          ),
          _ViewModeButton(
            tooltip: '1 por linha',
            icon: Icons.view_agenda_outlined,
            selected: viewMode == CountdownViewMode.single,
            colors: colors,
            isDark: isDark,
            onTap: () => onChanged(CountdownViewMode.single),
          ),
          _ViewModeButton(
            tooltip: '2 por linha',
            icon: Icons.grid_view_rounded,
            selected: viewMode == CountdownViewMode.grid,
            colors: colors,
            isDark: isDark,
            onTap: () => onChanged(CountdownViewMode.grid),
          ),
        ],
      ),
    );
  }
}

class _ViewModeButton extends StatelessWidget {
  const _ViewModeButton({
    required this.tooltip,
    required this.icon,
    required this.selected,
    required this.colors,
    required this.isDark,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final bool selected;
  final CountlyColors colors;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final idleColor = isDark ? colors.muted : Colors.white.withValues(alpha: 0.72);
    final selectedBackground = isDark
        ? Colors.white.withValues(alpha: 0.22)
        : Colors.white.withValues(alpha: 0.32);
    final selectedIconColor = Colors.white;
    final selectedBorder = isDark
        ? Border.all(color: Colors.white.withValues(alpha: 0.35))
        : null;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 30,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: selected ? selectedBackground : Colors.transparent,
              border: selected ? selectedBorder : null,
            ),
            child: Icon(
              icon,
              size: 16,
              color: selected ? selectedIconColor : idleColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _SortToggleButton extends StatelessWidget {
  const _SortToggleButton({
    required this.sortMode,
    required this.colors,
    required this.isDark,
    required this.onToggle,
  });

  final String sortMode;
  final CountlyColors colors;
  final bool isDark;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final isSoonest = sortMode == 'soonest';
    final iconColor = isDark ? colors.muted : Colors.white.withValues(alpha: 0.88);

    return Tooltip(
      message: isSoonest ? 'Ordenar: mais distantes' : 'Ordenar: mais próximas',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: FaIcon(
              isSoonest ? FontAwesomeIcons.arrowDownWideShort : FontAwesomeIcons.arrowUpWideShort,
              size: 15,
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }
}

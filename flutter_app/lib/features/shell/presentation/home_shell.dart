import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/pressable.dart';
import '../../calendar/presentation/calendar_page.dart';
import '../../counters/presentation/counter_editor_sheet.dart';
import '../../counters/presentation/counters_page.dart';
import '../../habits/presentation/habit_editor_sheet.dart';
import '../../habits/presentation/habits_page.dart';
import '../../settings/presentation/settings_page.dart';
import 'floating_nav_bar.dart';

/// Estrutura principal do app: páginas em [IndexedStack], navegação
/// flutuante e FAB contextual que muda de ação conforme a aba.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  AppTab _tab = AppTab.counters;

  void _onFabPressed() {
    switch (_tab) {
      case AppTab.counters:
      case AppTab.calendar:
        showCounterEditorSheet(context);
      case AppTab.habits:
        showHabitEditorSheet(context);
      case AppTab.settings:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final showFab = _tab != AppTab.settings;

    return Scaffold(
      extendBody: true,
      body: AnimatedSwitcher(
        duration: Motion.base,
        switchInCurve: Motion.standard,
        switchOutCurve: Motion.standard,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.008),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
        child: switch (_tab) {
          AppTab.counters => const CountersPage(key: ValueKey('counters')),
          AppTab.calendar => const CalendarPage(key: ValueKey('calendar')),
          AppTab.habits => const HabitsPage(key: ValueKey('habits')),
          AppTab.settings => const SettingsPage(key: ValueKey('settings')),
        },
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.only(bottom: Gap.x3),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Gap.x4),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FloatingNavBar(
                  current: _tab,
                  fabVisible: showFab,
                  onChanged: (tab) => setState(() => _tab = tab),
                ),
                _FabSlot(
                  visible: showFab,
                  tab: _tab,
                  onPressed: _onFabPressed,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Entrada suave do FAB; saída instantânea para não deixar sombra/ícone
/// fantasma ao ir para Ajustes.
class _FabSlot extends StatelessWidget {
  const _FabSlot({
    required this.visible,
    required this.tab,
    required this.onPressed,
  });

  final bool visible;
  final AppTab tab;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (!visible) {
      return const SizedBox.shrink();
    }

    return TweenAnimationBuilder<double>(
      key: const ValueKey('fab-enter'),
      tween: Tween(begin: 0, end: 1),
      duration: Motion.base,
      curve: Motion.spring,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.scale(
            scale: 0.88 + 0.12 * value,
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(left: Gap.x3),
        child: _ContextFab(
          tab: tab,
          onPressed: onPressed,
        ),
      ),
    );
  }
}

/// FAB com gradiente e ícone que troca com animação conforme o contexto.
class _ContextFab extends StatelessWidget {
  const _ContextFab({required this.tab, required this.onPressed});

  final AppTab tab;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Pressable(
      onTap: onPressed,
      pressedScale: 0.9,
      semanticLabel: tab == AppTab.habits ? 'Novo hábito' : 'Nova contagem',
      child: Material(
        color: Colors.transparent,
        elevation: 10,
        shadowColor: palette.accent.withValues(alpha: 0.42),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                palette.accentGradientStart,
                palette.accentGradientEnd,
              ],
            ),
            shape: BoxShape.circle,
          ),
          child: AnimatedSwitcher(
            duration: Motion.base,
            switchInCurve: Motion.spring,
            transitionBuilder: (child, animation) => RotationTransition(
              turns: Tween<double>(begin: 0.85, end: 1).animate(animation),
              child: ScaleTransition(scale: animation, child: child),
            ),
            child: Icon(
              tab == AppTab.habits
                  ? Icons.local_fire_department_rounded
                  : Icons.add_rounded,
              key: ValueKey(tab == AppTab.habits),
              color: palette.onAccent,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/round_icon_button.dart';
import '../../../core/widgets/staggered_list.dart';
import '../../../core/widgets/tag_chip.dart';
import '../application/counters_controller.dart';
import '../domain/counter.dart';
import 'counter_detail_page.dart';
import 'counter_editor_sheet.dart';
import 'widgets/counter_grid_card.dart';
import 'widgets/counter_list_tile.dart';
import 'widgets/counter_timeline.dart';
import 'widgets/view_mode_switcher.dart';

/// Página principal de contagens: busca, filtros por tag, três
/// visualizações e seleção múltipla para ações em massa.
class CountersPage extends StatefulWidget {
  const CountersPage({super.key});

  @override
  State<CountersPage> createState() => _CountersPageState();
}

class _CountersPageState extends State<CountersPage> {
  final _searchController = TextEditingController();

  Timer? _ticker;
  DateTime _now = DateTime.now();

  bool _searching = false;
  String? _selectedTag;
  bool _favoritesOnly = false;
  final Set<String> _selection = {};

  bool get _selectionMode => _selection.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    });
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  List<Counter> _visibleCounters(CountersController controller) {
    var counters = controller.active;
    if (_favoritesOnly) {
      counters = counters.where((counter) => counter.favorite).toList();
    }
    final tag = _selectedTag;
    if (tag != null) {
      counters =
          counters.where((counter) => counter.tags.contains(tag)).toList();
    }
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      counters = counters.where((counter) {
        return counter.title.toLowerCase().contains(query) ||
            counter.description.toLowerCase().contains(query) ||
            counter.tags.any((t) => t.toLowerCase().contains(query));
      }).toList();
    }
    return controller.sortedByRelevance(counters, _now);
  }

  void _openDetail(Counter counter) {
    Navigator.of(context).push(
      SoftSlideRoute(builder: (_) => CounterDetailPage(counterId: counter.id)),
    );
  }

  void _toggleSelection(String id) {
    setState(() {
      if (!_selection.remove(id)) {
        _selection.add(id);
      }
    });
  }

  Future<void> _archiveSelection(CountersController controller) async {
    await controller.archiveMany(Set.of(_selection));
    setState(_selection.clear);
  }

  Future<void> _deleteSelection(CountersController controller) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Excluir ${_selection.length} contagens?',
      message: 'Essa ação não pode ser desfeita.',
      confirmLabel: 'Excluir',
      destructive: true,
    );
    if (!confirmed) {
      return;
    }
    await controller.removeMany(Set.of(_selection));
    setState(_selection.clear);
  }

  @override
  Widget build(BuildContext context) {
    final dependencies = AppScope.of(context);
    final controller = dependencies.counters;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final counters = _visibleCounters(controller);
        final hasAny = controller.active.isNotEmpty;

        return SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(controller),
              AnimatedSize(
                duration: Motion.base,
                curve: Motion.emphasized,
                alignment: Alignment.topCenter,
                child: _searching
                    ? _SearchField(controller: _searchController)
                    : const SizedBox.shrink(),
              ),
              if (hasAny) _buildFilters(controller),
              const SizedBox(height: Gap.x3),
              Expanded(
                child: !hasAny
                    ? EmptyState(
                        icon: Icons.hourglass_bottom_rounded,
                        title: 'Nenhuma contagem ainda',
                        message:
                            'Crie sua primeira contagem para acompanhar os dias até (ou desde) os momentos que importam.',
                        actionLabel: 'Criar contagem',
                        onAction: () => showCounterEditorSheet(context),
                      )
                    : counters.isEmpty
                        ? const EmptyState(
                            icon: Icons.search_off_rounded,
                            title: 'Nada por aqui',
                            message:
                                'Nenhuma contagem corresponde aos filtros atuais.',
                          )
                        : _buildContent(controller, counters),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(CountersController controller) {
    final palette = context.palette;

    if (_selectionMode) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(Gap.page, Gap.x4, Gap.page, 0),
        child: Row(
          children: [
            RoundIconButton(
              icon: Icons.close_rounded,
              tooltip: 'Cancelar seleção',
              onTap: () => setState(_selection.clear),
            ),
            const SizedBox(width: Gap.x3),
            Expanded(
              child: Text(
                '${_selection.length} selecionadas',
                style: AppType.title(palette),
              ),
            ),
            RoundIconButton(
              icon: Icons.archive_rounded,
              tooltip: 'Arquivar selecionadas',
              onTap: () => _archiveSelection(controller),
            ),
            const SizedBox(width: Gap.x2),
            RoundIconButton(
              icon: Icons.delete_rounded,
              tooltip: 'Excluir selecionadas',
              color: palette.danger,
              background: palette.dangerSoft,
              onTap: () => _deleteSelection(controller),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.page, Gap.x4, Gap.page, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Contagens', style: AppType.largeTitle(palette)),
                const SizedBox(height: Gap.x1),
                Text(
                  pluralize(
                    controller.active.length,
                    'contagem ativa',
                    'contagens ativas',
                  ),
                  style: AppType.footnote(palette),
                ),
              ],
            ),
          ),
          RoundIconButton(
            icon: _searching ? Icons.search_off_rounded : Icons.search_rounded,
            tooltip: 'Buscar',
            onTap: () => setState(() {
              _searching = !_searching;
              if (!_searching) {
                _searchController.clear();
              }
            }),
          ),
          const SizedBox(width: Gap.x2),
          ViewModeSwitcher(
            mode: controller.viewMode,
            onChanged: (mode) {
              controller.setViewMode(mode);
              AppScope.of(context).settings.saveCounterViewMode(mode.name);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(CountersController controller) {
    final tags = controller.allTags;
    final hasFavorites = controller.favorites.isNotEmpty;
    if (tags.isEmpty && !hasFavorites) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: Gap.x4),
      child: SizedBox(
        height: 36,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: Gap.page),
          children: [
            TagChip(
              label: 'Todas',
              selected: _selectedTag == null && !_favoritesOnly,
              onTap: () => setState(() {
                _selectedTag = null;
                _favoritesOnly = false;
              }),
            ),
            if (hasFavorites) ...[
              const SizedBox(width: Gap.x2),
              TagChip(
                label: 'Favoritas',
                selected: _favoritesOnly,
                leading: Icon(
                  Icons.star_rounded,
                  size: 14,
                  color: _favoritesOnly
                      ? context.palette.onAccent
                      : const Color(0xFFEFB018),
                ),
                onTap: () => setState(() {
                  _favoritesOnly = !_favoritesOnly;
                  _selectedTag = null;
                }),
              ),
            ],
            for (final tag in tags) ...[
              const SizedBox(width: Gap.x2),
              TagChip(
                label: '#$tag',
                selected: _selectedTag == tag,
                onTap: () => setState(() {
                  _selectedTag = _selectedTag == tag ? null : tag;
                  _favoritesOnly = false;
                }),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContent(CountersController controller, List<Counter> counters) {
    return AnimatedSwitcher(
      duration: Motion.base,
      switchInCurve: Motion.standard,
      switchOutCurve: Motion.standard,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.985, end: 1).animate(animation),
          child: child,
        ),
      ),
      child: switch (controller.viewMode) {
        CounterViewMode.grid => _GridView(
            key: const ValueKey('grid'),
            counters: counters,
            now: _now,
            selection: _selection,
            selectionMode: _selectionMode,
            onTap: (counter) => _selectionMode
                ? _toggleSelection(counter.id)
                : _openDetail(counter),
            onLongPress: (counter) => _toggleSelection(counter.id),
          ),
        CounterViewMode.list => _ListView(
            key: const ValueKey('list'),
            counters: counters,
            now: _now,
            controller: controller,
            selection: _selection,
            selectionMode: _selectionMode,
            onTap: (counter) => _selectionMode
                ? _toggleSelection(counter.id)
                : _openDetail(counter),
            onLongPress: (counter) => _toggleSelection(counter.id),
          ),
        CounterViewMode.timeline => _TimelineView(
            key: const ValueKey('timeline'),
            counters: counters,
            now: _now,
            onTap: _openDetail,
          ),
      },
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.page, Gap.x4, Gap.page, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Gap.x4),
        decoration: BoxDecoration(
          color: palette.surfaceSunken,
          borderRadius: BorderRadius.circular(Corner.sm),
        ),
        child: Row(
          children: [
            Icon(Icons.search_rounded, size: 20, color: palette.textTertiary),
            const SizedBox(width: Gap.x2),
            Expanded(
              child: TextField(
                controller: controller,
                autofocus: true,
                style: AppType.body(palette),
                decoration: InputDecoration(
                  hintText: 'Buscar por título, descrição ou tag',
                  hintStyle: AppType.body(palette)
                      .copyWith(color: palette.textTertiary),
                  border: InputBorder.none,
                ),
              ),
            ),
            if (controller.text.isNotEmpty)
              GestureDetector(
                onTap: controller.clear,
                child: Icon(
                  Icons.cancel_rounded,
                  size: 18,
                  color: palette.textTertiary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

const _bottomPadding = 130.0;

class _GridView extends StatelessWidget {
  const _GridView({
    super.key,
    required this.counters,
    required this.now,
    required this.selection,
    required this.selectionMode,
    required this.onTap,
    required this.onLongPress,
  });

  final List<Counter> counters;
  final DateTime now;
  final Set<String> selection;
  final bool selectionMode;
  final ValueChanged<Counter> onTap;
  final ValueChanged<Counter> onLongPress;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 900
            ? 4
            : constraints.maxWidth > 600
                ? 3
                : 2;

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(
            Gap.page,
            Gap.x2,
            Gap.page,
            _bottomPadding,
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: Gap.x4,
            crossAxisSpacing: Gap.x4,
            childAspectRatio: 0.82,
          ),
          itemCount: counters.length,
          itemBuilder: (context, index) {
            final counter = counters[index];
            return StaggeredReveal(
              index: index,
              child: CounterGridCard(
                counter: counter,
                now: now,
                selected: selection.contains(counter.id),
                selectionMode: selectionMode,
                onTap: () => onTap(counter),
                onLongPress: () => onLongPress(counter),
              ),
            );
          },
        );
      },
    );
  }
}

class _ListView extends StatelessWidget {
  const _ListView({
    super.key,
    required this.counters,
    required this.now,
    required this.controller,
    required this.selection,
    required this.selectionMode,
    required this.onTap,
    required this.onLongPress,
  });

  final List<Counter> counters;
  final DateTime now;
  final CountersController controller;
  final Set<String> selection;
  final bool selectionMode;
  final ValueChanged<Counter> onTap;
  final ValueChanged<Counter> onLongPress;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        Gap.page,
        Gap.x2,
        Gap.page,
        _bottomPadding,
      ),
      itemCount: counters.length,
      separatorBuilder: (_, _) => const SizedBox(height: Gap.x3),
      itemBuilder: (context, index) {
        final counter = counters[index];
        return StaggeredReveal(
          index: index,
          child: CounterListTile(
            counter: counter,
            now: now,
            selected: selection.contains(counter.id),
            selectionMode: selectionMode,
            onTap: () => onTap(counter),
            onLongPress: () => onLongPress(counter),
            onFavorite: () => controller.toggleFavorite(counter.id),
            onArchive: () => controller.setArchived(counter.id, true),
          ),
        );
      },
    );
  }
}

class _TimelineView extends StatelessWidget {
  const _TimelineView({
    super.key,
    required this.counters,
    required this.now,
    required this.onTap,
  });

  final List<Counter> counters;
  final DateTime now;
  final ValueChanged<Counter> onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final groups = buildTimelineGroups(counters, now);

    var runningIndex = 0;
    final children = <Widget>[];
    for (final group in groups) {
      children.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(Gap.x2, Gap.x4, 0, Gap.x3),
          child: Text(
            group.label.toUpperCase(),
            style: AppType.overline(palette),
          ),
        ),
      );
      for (var i = 0; i < group.entries.length; i++) {
        final entry = group.entries[i];
        children.add(
          TimelineTile(
            entry: entry,
            index: runningIndex,
            isFirst: i == 0,
            isLast: i == group.entries.length - 1,
            onTap: () => onTap(entry.counter),
          ),
        );
        runningIndex++;
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Gap.page,
        0,
        Gap.page,
        _bottomPadding,
      ),
      children: children,
    );
  }
}

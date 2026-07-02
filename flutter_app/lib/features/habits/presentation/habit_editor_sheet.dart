import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/pressable.dart';
import '../domain/habit.dart';
import '../domain/habit_kind.dart';
import 'widgets/habit_type_picker.dart';

const _suggestions = <(String, String, int, HabitKind)>[
  ('Sem fumar', 'nosmoking', 0xFF19A45B, HabitKind.timeTracker),
  ('Sem açúcar', 'nosugar', 0xFFDF8E0B, HabitKind.timeTracker),
  ('Meditação', 'meditation', 0xFF5551E8, HabitKind.session),
  ('Leitura', 'book', 0xFF0EA5B7, HabitKind.session),
  ('Água', 'water', 0xFF2F80ED, HabitKind.quantity),
  ('Academia', 'gym', 0xFFEA6A34, HabitKind.simple),
];

Future<void> showHabitEditorSheet(BuildContext context, {Habit? existing}) {
  return showAppSheet<void>(
    context,
    builder: (_) => _HabitEditor(
      existing: existing,
      dependencies: AppScope.of(context),
    ),
  );
}

class _HabitEditor extends StatefulWidget {
  const _HabitEditor({required this.dependencies, this.existing});

  final AppDependencies dependencies;
  final Habit? existing;

  @override
  State<_HabitEditor> createState() => _HabitEditorState();
}

class _HabitEditorState extends State<_HabitEditor> {
  late final TextEditingController _title =
      TextEditingController(text: widget.existing?.title ?? '');
  late final TextEditingController _notes =
      TextEditingController(text: widget.existing?.notes ?? '');
  late final TextEditingController _unit =
      TextEditingController(text: widget.existing?.unitLabel ?? 'copos');
  late final TextEditingController _goal = TextEditingController(
    text: '${widget.existing?.dailyGoal ?? 6}',
  );

  late HabitKind? _kind = widget.existing?.kind;
  late String _iconName = widget.existing?.iconName ?? 'spark';
  late int _accentColor =
      widget.existing?.accentColor ?? CountlyAccents.green.toARGB32();
  late String? _category = widget.existing?.category;
  late DateTime _startDate =
      widget.existing?.startAt ?? DateTime.now();
  late TimeOfDay _startTime = TimeOfDay.fromDateTime(_startDate);
  late bool _useStartTime;

  bool get _isEditing => widget.existing != null;
  bool get _canSave => _title.text.trim().isNotEmpty && (_isEditing || _kind != null);

  @override
  void initState() {
    super.initState();
    final startAt = widget.existing?.startAt;
    _useStartTime = startAt != null &&
        (startAt.hour != 0 || startAt.minute != 0);
    _title.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    _unit.dispose();
    _goal.dispose();
    super.dispose();
  }

  DateTime get _startAt {
    if (_useStartTime) {
      return DateTime(
        _startDate.year,
        _startDate.month,
        _startDate.day,
        _startTime.hour,
        _startTime.minute,
      );
    }
    return dateOnly(_startDate);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('pt', 'BR'),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null) {
      setState(() => _startTime = picked);
    }
  }

  Future<void> _save() async {
    if (!_canSave) {
      return;
    }
    final controller = widget.dependencies.habits;
    final base = widget.existing;
    final kind = _kind!;

    if (base == null) {
      await controller.add(
        Habit.create(
          title: _title.text.trim(),
          kind: kind,
          notes: _notes.text.trim(),
          category: _category,
          iconName: _iconName,
          accentColor: _accentColor,
          startAt: kind == HabitKind.timeTracker ? _startAt : null,
          dailyGoal: int.tryParse(_goal.text) ?? 1,
          unitLabel: _unit.text.trim(),
        ),
      );
    } else {
      await controller.update(
        base.copyWith(
          title: _title.text.trim(),
          notes: _notes.text.trim(),
          category: _category,
          clearCategory: _category == null,
          iconName: _iconName,
          accentColor: _accentColor,
          startAt: kind == HabitKind.timeTracker ? _startAt : base.startAt,
          dailyGoal: int.tryParse(_goal.text) ?? base.dailyGoal,
          unitLabel: _unit.text.trim(),
        ),
      );
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _applySuggestion((String, String, int, HabitKind) suggestion) {
    setState(() {
      _title.text = suggestion.$1;
      _iconName = suggestion.$2;
      _accentColor = suggestion.$3;
      _kind = suggestion.$4;
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final showTypePicker = !_isEditing && _kind == null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(Gap.x5, Gap.x3, Gap.x5, Gap.x6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  showTypePicker
                      ? 'Qual tipo?'
                      : _isEditing
                          ? 'Editar hábito'
                          : 'Novo ${_kind!.label.toLowerCase()}',
                  style: AppType.title(palette),
                ),
              ),
              if (!showTypePicker)
                Pressable(
                  onTap: _canSave ? _save : null,
                  child: _SaveChip(enabled: _canSave),
                ),
            ],
          ),
          const SizedBox(height: Gap.x5),
          if (showTypePicker) ...[
            HabitTypePicker(
              selected: _kind,
              onSelected: (kind) => setState(() => _kind = kind),
            ),
          ] else ...[
            if (!_isEditing) ...[
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _suggestions.length,
                  separatorBuilder: (_, _) => const SizedBox(width: Gap.x2),
                  itemBuilder: (context, index) {
                    final s = _suggestions[index];
                    return Pressable(
                      onTap: () => _applySuggestion(s),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: Gap.x3),
                        decoration: BoxDecoration(
                          color: Color(s.$3).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(Corner.pill),
                        ),
                        child: Row(
                          children: [
                            Icon(AppIcons.resolve(s.$2), size: 15, color: Color(s.$3)),
                            const SizedBox(width: Gap.x1),
                            Text(
                              s.$1,
                              style: AppType.footnote(palette).copyWith(
                                color: Color(s.$3),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: Gap.x5),
            ],
            _Field(
              controller: _title,
              hint: 'Nome do hábito',
              autofocus: !_isEditing,
            ),
            if (_kind == HabitKind.timeTracker) ...[
              const SizedBox(height: Gap.x5),
              Text('INÍCIO', style: AppType.overline(palette)),
              const SizedBox(height: Gap.x2),
              Row(
                children: [
                  Expanded(
                    child: _OutlineButton(
                      label: formatBrazilianDate(_startDate),
                      icon: Icons.calendar_today_rounded,
                      onTap: _pickDate,
                    ),
                  ),
                  const SizedBox(width: Gap.x2),
                  Expanded(
                    child: _OutlineButton(
                      label: _useStartTime
                          ? _startTime.format(context)
                          : 'Sem hora',
                      icon: Icons.schedule_rounded,
                      onTap: () async {
                        if (_useStartTime) {
                          await _pickTime();
                        } else {
                          setState(() => _useStartTime = true);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
            if (_kind == HabitKind.quantity) ...[
              const SizedBox(height: Gap.x5),
              Row(
                children: [
                  Expanded(
                    child: _Field(
                      controller: _goal,
                      hint: 'Meta diária',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: Gap.x3),
                  Expanded(
                    child: _Field(
                      controller: _unit,
                      hint: 'Unidade (copos)',
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: Gap.x5),
            Text('ÍCONE', style: AppType.overline(palette)),
            const SizedBox(height: Gap.x2),
            _IconPicker(
              iconName: _iconName,
              accentColor: _accentColor,
              onSelected: (name) => setState(() => _iconName = name),
            ),
            const SizedBox(height: Gap.x5),
            Text('COR', style: AppType.overline(palette)),
            const SizedBox(height: Gap.x2),
            _ColorPicker(
              selected: _accentColor,
              onSelected: (c) => setState(() => _accentColor = c),
            ),
            const SizedBox(height: Gap.x5),
            Text('CATEGORIA', style: AppType.overline(palette)),
            const SizedBox(height: Gap.x2),
            Wrap(
              spacing: Gap.x2,
              runSpacing: Gap.x2,
              children: [
                for (final cat in HabitCategories.all)
                  ChoiceChip(
                    label: Text(cat),
                    selected: _category == cat,
                    onSelected: (selected) => setState(
                      () => _category = selected ? cat : null,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: Gap.x5),
            _Field(
              controller: _notes,
              hint: 'Notas (opcional)',
              maxLines: 3,
            ),
            const SizedBox(height: Gap.x6),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _canSave ? _save : null,
                child: const Text('Salvar'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SaveChip extends StatelessWidget {
  const _SaveChip({required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return AnimatedContainer(
      duration: Motion.fast,
      padding: const EdgeInsets.symmetric(horizontal: Gap.x5, vertical: Gap.x2),
      decoration: BoxDecoration(
        gradient: enabled
            ? LinearGradient(
                colors: [palette.accentGradientStart, palette.accentGradientEnd],
              )
            : null,
        color: enabled ? null : palette.surfaceSunken,
        borderRadius: BorderRadius.circular(Corner.pill),
      ),
      child: Text(
        'Salvar',
        style: AppType.headline(palette).copyWith(
          color: enabled ? palette.onAccent : palette.textTertiary,
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.hint,
    this.autofocus = false,
    this.maxLines = 1,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String hint;
  final bool autofocus;
  final int maxLines;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return TextField(
      controller: controller,
      autofocus: autofocus,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: AppType.body(palette),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppType.body(palette).copyWith(color: palette.textTertiary),
        filled: true,
        fillColor: palette.surfaceSunken,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Gap.x4,
          vertical: Gap.x3,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Corner.sm),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Corner.sm),
          borderSide: BorderSide(color: palette.accent, width: 1.5),
        ),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  const _OutlineButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Gap.x3, vertical: Gap.x3),
        decoration: BoxDecoration(
          color: palette.surfaceSunken,
          borderRadius: BorderRadius.circular(Corner.sm),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: palette.textSecondary),
            const SizedBox(width: Gap.x2),
            Expanded(
              child: Text(label, style: AppType.footnote(palette)),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconPicker extends StatelessWidget {
  const _IconPicker({
    required this.iconName,
    required this.accentColor,
    required this.onSelected,
  });

  final String iconName;
  final int accentColor;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: AppIcons.all.length,
        separatorBuilder: (_, _) => const SizedBox(width: Gap.x2),
        itemBuilder: (context, index) {
          final entry = AppIcons.all.entries.elementAt(index);
          final selected = entry.key == iconName;
          return Pressable(
            onTap: () => onSelected(entry.key),
            pressedScale: 0.85,
            child: AnimatedContainer(
              duration: Motion.fast,
              width: 52,
              decoration: BoxDecoration(
                color: selected
                    ? Color(accentColor).withValues(alpha: 0.16)
                    : palette.surfaceSunken,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? Color(accentColor) : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Icon(
                entry.value,
                size: 22,
                color: selected ? Color(accentColor) : palette.textTertiary,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ColorPicker extends StatelessWidget {
  const _ColorPicker({required this.selected, required this.onSelected});

  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: CountlyAccents.all.length,
        separatorBuilder: (_, _) => const SizedBox(width: Gap.x2),
        itemBuilder: (context, index) {
          final color = CountlyAccents.all[index];
          final isSelected = color.toARGB32() == selected;
          return Pressable(
            onTap: () => onSelected(color.toARGB32()),
            pressedScale: 0.85,
            child: AnimatedContainer(
              duration: Motion.fast,
              width: 40,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? palette.textPrimary : Colors.transparent,
                  width: 3,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                  : null,
            ),
          );
        },
      ),
    );
  }
}

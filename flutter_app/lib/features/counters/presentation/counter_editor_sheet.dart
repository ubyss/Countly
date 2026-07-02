import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../app/app_scope.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/clipboard_image.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/image_utils.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/base64_image.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/widgets/tag_chip.dart';
import '../domain/counter.dart';
import '../domain/recurrence.dart';

/// Abre o editor de contagem (criação ou edição).
Future<void> showCounterEditorSheet(
  BuildContext context, {
  Counter? existing,
  DateTime? initialDate,
}) {
  return showAppSheet<void>(
    context,
    expand: true,
    builder: (_) => _CounterEditor(
      existing: existing,
      initialDate: initialDate,
      dependencies: AppScope.of(context),
    ),
  );
}

class _CounterEditor extends StatefulWidget {
  const _CounterEditor({
    required this.dependencies,
    this.existing,
    this.initialDate,
  });

  final AppDependencies dependencies;
  final Counter? existing;
  final DateTime? initialDate;

  @override
  State<_CounterEditor> createState() => _CounterEditorState();
}

class _CounterEditorState extends State<_CounterEditor> {
  late final TextEditingController _title =
      TextEditingController(text: widget.existing?.title ?? '');
  late final TextEditingController _description =
      TextEditingController(text: widget.existing?.description ?? '');
  late final TextEditingController _notes =
      TextEditingController(text: widget.existing?.notes ?? '');
  final TextEditingController _tagInput = TextEditingController();

  late String? _imageBase64 = widget.existing?.imageBase64;
  late Alignment _imageAlignment =
      widget.existing?.imageAlignment ?? Alignment.center;
  late String _iconName = widget.existing?.iconName ?? 'event';
  late int _accentColor =
      widget.existing?.accentColor ?? CountlyAccents.violet.toARGB32();
  late DateTime? _targetDate = widget.existing?.targetLocalDate ??
      (widget.initialDate == null ? null : dateOnly(widget.initialDate!));
  late Recurrence _recurrence =
      widget.existing?.recurrence ?? Recurrence.none;
  late List<String> _tags = [...?widget.existing?.tags];

  bool _saving = false;
  bool _loadingImage = false;

  bool get _isEditing => widget.existing != null;
  bool get _canSave => _title.text.trim().isNotEmpty && !_saving;

  @override
  void initState() {
    super.initState();
    _title.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _notes.dispose();
    _tagInput.dispose();
    super.dispose();
  }

  Future<void> _pickFromGallery() async {
    setState(() => _loadingImage = true);
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
      );
      if (picked == null) {
        return;
      }
      final bytes = await picked.readAsBytes();
      final encoded = await prepareImageBase64(bytes);
      if (encoded != null && mounted) {
        setState(() {
          _imageBase64 = encoded;
          _imageAlignment = Alignment.center;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _loadingImage = false);
      }
    }
  }

  Future<void> _pasteFromClipboard() async {
    setState(() => _loadingImage = true);
    try {
      final bytes = await readClipboardImageBytes();
      if (bytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nenhuma imagem na área de transferência'),
            ),
          );
        }
        return;
      }
      final encoded = await prepareImageBase64(bytes);
      if (encoded != null && mounted) {
        setState(() {
          _imageBase64 = encoded;
          _imageAlignment = Alignment.center;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _loadingImage = false);
      }
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? now,
      firstDate: DateTime(now.year - 80),
      lastDate: DateTime(now.year + 80),
      locale: const Locale('pt', 'BR'),
    );
    if (picked != null) {
      setState(() => _targetDate = dateOnly(picked));
    }
  }

  void _addTag(String raw) {
    final tag = raw.trim().replaceAll('#', '').toLowerCase();
    if (tag.isEmpty || _tags.contains(tag)) {
      _tagInput.clear();
      return;
    }
    setState(() {
      _tags = [..._tags, tag];
      _tagInput.clear();
    });
  }

  Future<void> _save() async {
    if (!_canSave) {
      return;
    }
    setState(() => _saving = true);

    final controller = widget.dependencies.counters;
    final base = widget.existing;
    final counter = Counter(
      id: base?.id ?? const Uuid().v4(),
      title: _title.text.trim(),
      description: _description.text.trim(),
      notes: _notes.text.trim(),
      createdAt: base?.createdAt ?? DateTime.now(),
      targetDate: _targetDate == null ? null : toIsoDate(_targetDate!),
      recurrence: _targetDate == null ? Recurrence.none : _recurrence,
      imageBase64: _imageBase64,
      imageAlignment: _imageAlignment,
      iconName: _iconName,
      accentColor: _accentColor,
      tags: _tags,
      archived: base?.archived ?? false,
      favorite: base?.favorite ?? false,
    );

    if (base == null) {
      await controller.add(counter);
    } else {
      await controller.update(counter);
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Gap.x5, Gap.x3, Gap.x5, Gap.x2),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _isEditing ? 'Editar contagem' : 'Nova contagem',
                  style: AppType.title(palette),
                ),
              ),
              _SaveButton(enabled: _canSave, saving: _saving, onTap: _save),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(Gap.x5, Gap.x2, Gap.x5, Gap.x8),
            children: [
              _FieldLabel('Título'),
              _TextInput(
                controller: _title,
                hint: 'Ex.: Viagem para o Japão',
                autofocus: !_isEditing,
              ),
              const SizedBox(height: Gap.x4),
              _FieldLabel('Descrição (opcional)'),
              _TextInput(
                controller: _description,
                hint: 'Um lembrete curto do que é essa contagem',
              ),
              const SizedBox(height: Gap.x5),
              _FieldLabel('Imagem'),
              _ImageSection(
                imageBase64: _imageBase64,
                alignment: _imageAlignment,
                loading: _loadingImage,
                onGallery: _pickFromGallery,
                onClipboard: _pasteFromClipboard,
                onRemove: () => setState(() => _imageBase64 = null),
                onAlignmentChanged: (alignment) =>
                    setState(() => _imageAlignment = alignment),
              ),
              const SizedBox(height: Gap.x5),
              _FieldLabel('Ícone'),
              _IconPicker(
                selected: _iconName,
                accent: Color(_accentColor),
                onChanged: (name) => setState(() => _iconName = name),
              ),
              const SizedBox(height: Gap.x5),
              _FieldLabel('Cor de destaque'),
              _ColorPicker(
                selected: _accentColor,
                onChanged: (color) => setState(() => _accentColor = color),
              ),
              const SizedBox(height: Gap.x5),
              _FieldLabel('Data alvo'),
              _DateSection(
                targetDate: _targetDate,
                onPick: _pickDate,
                onClear: () => setState(() {
                  _targetDate = null;
                  _recurrence = Recurrence.none;
                }),
              ),
              AnimatedSize(
                duration: Motion.base,
                curve: Motion.emphasized,
                alignment: Alignment.topCenter,
                child: _targetDate == null
                    ? const SizedBox.shrink()
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: Gap.x5),
                          _FieldLabel('Repetição'),
                          _RecurrencePicker(
                            recurrence: _recurrence,
                            onChanged: (value) =>
                                setState(() => _recurrence = value),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: Gap.x5),
              _FieldLabel('Tags'),
              _TagsSection(
                tags: _tags,
                input: _tagInput,
                onSubmit: _addTag,
                onRemove: (tag) => setState(
                  () => _tags = _tags.where((item) => item != tag).toList(),
                ),
              ),
              const SizedBox(height: Gap.x5),
              _FieldLabel('Notas (opcional)'),
              _TextInput(
                controller: _notes,
                hint: 'Detalhes, links, lembretes...',
                maxLines: 4,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({
    required this.enabled,
    required this.saving,
    required this.onTap,
  });

  final bool enabled;
  final bool saving;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Pressable(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: Motion.fast,
        padding: const EdgeInsets.symmetric(
          horizontal: Gap.x5,
          vertical: Gap.x2,
        ),
        decoration: BoxDecoration(
          gradient: enabled
              ? LinearGradient(
                  colors: [
                    palette.accentGradientStart,
                    palette.accentGradientEnd,
                  ],
                )
              : null,
          color: enabled ? null : palette.surfaceSunken,
          borderRadius: BorderRadius.circular(Corner.pill),
        ),
        child: saving
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: palette.onAccent,
                ),
              )
            : Text(
                'Salvar',
                style: AppType.headline(palette).copyWith(
                  color: enabled ? palette.onAccent : palette.textTertiary,
                ),
              ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.x2),
      child: Text(
        text.toUpperCase(),
        style: AppType.overline(context.palette),
      ),
    );
  }
}

class _TextInput extends StatelessWidget {
  const _TextInput({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return TextField(
      controller: controller,
      maxLines: maxLines,
      autofocus: autofocus,
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

class _ImageSection extends StatelessWidget {
  const _ImageSection({
    required this.imageBase64,
    required this.alignment,
    required this.loading,
    required this.onGallery,
    required this.onClipboard,
    required this.onRemove,
    required this.onAlignmentChanged,
  });

  final String? imageBase64;
  final Alignment alignment;
  final bool loading;
  final VoidCallback onGallery;
  final VoidCallback onClipboard;
  final VoidCallback onRemove;
  final ValueChanged<Alignment> onAlignmentChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (imageBase64 != null) ...[
          _DraggableImagePreview(
            base64: imageBase64!,
            alignment: alignment,
            onAlignmentChanged: onAlignmentChanged,
          ),
          const SizedBox(height: Gap.x3),
        ],
        Row(
          children: [
            Expanded(
              child: _ImageActionButton(
                icon: Icons.photo_library_rounded,
                label: 'Galeria',
                onTap: loading ? null : onGallery,
              ),
            ),
            const SizedBox(width: Gap.x3),
            Expanded(
              child: _ImageActionButton(
                icon: Icons.content_paste_rounded,
                label: 'Colar',
                onTap: loading ? null : onClipboard,
              ),
            ),
            if (imageBase64 != null) ...[
              const SizedBox(width: Gap.x3),
              _ImageActionButton(
                icon: Icons.delete_outline_rounded,
                label: null,
                color: palette.danger,
                onTap: onRemove,
              ),
            ],
          ],
        ),
        if (loading) ...[
          const SizedBox(height: Gap.x3),
          const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ],
      ],
    );
  }
}

/// Prévia da imagem com ajuste do enquadramento por arrasto.
class _DraggableImagePreview extends StatelessWidget {
  const _DraggableImagePreview({
    required this.base64,
    required this.alignment,
    required this.onAlignmentChanged,
  });

  final String base64;
  final Alignment alignment;
  final ValueChanged<Alignment> onAlignmentChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return GestureDetector(
      onPanUpdate: (details) {
        const sensitivity = 0.012;
        onAlignmentChanged(
          Alignment(
            (alignment.x - details.delta.dx * sensitivity).clamp(-1.0, 1.0),
            (alignment.y - details.delta.dy * sensitivity).clamp(-1.0, 1.0),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Corner.md),
        child: SizedBox(
          height: 160,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Base64Image(base64: base64, alignment: alignment),
              Positioned(
                right: Gap.x2,
                bottom: Gap.x2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Gap.x2,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(Corner.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.open_with_rounded,
                        size: 12,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Arraste para ajustar',
                        style: AppType.caption(palette)
                            .copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageActionButton extends StatelessWidget {
  const _ImageActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String? label;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final foreground = color ?? palette.textSecondary;

    return Pressable(
      onTap: onTap,
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: Gap.x4),
        decoration: BoxDecoration(
          color: palette.surfaceSunken,
          borderRadius: BorderRadius.circular(Corner.sm),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: foreground),
            if (label != null) ...[
              const SizedBox(width: Gap.x2),
              Text(
                label!,
                style:
                    AppType.footnote(palette).copyWith(color: foreground),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _IconPicker extends StatelessWidget {
  const _IconPicker({
    required this.selected,
    required this.accent,
    required this.onChanged,
  });

  final String selected;
  final Color accent;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return SizedBox(
      height: 116,
      child: GridView.builder(
        scrollDirection: Axis.horizontal,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: Gap.x2,
          crossAxisSpacing: Gap.x2,
        ),
        itemCount: AppIcons.all.length,
        itemBuilder: (context, index) {
          final entry = AppIcons.all.entries.elementAt(index);
          final isSelected = entry.key == selected;
          return Pressable(
            onTap: () => onChanged(entry.key),
            pressedScale: 0.88,
            child: AnimatedContainer(
              duration: Motion.fast,
              decoration: BoxDecoration(
                color: isSelected
                    ? accent.withValues(alpha: 0.16)
                    : palette.surfaceSunken,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? accent : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Icon(
                entry.value,
                size: 22,
                color: isSelected ? accent : palette.textTertiary,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ColorPicker extends StatelessWidget {
  const _ColorPicker({required this.selected, required this.onChanged});

  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: CountlyAccents.all.length,
        separatorBuilder: (_, _) => const SizedBox(width: Gap.x2),
        itemBuilder: (context, index) {
          final color = CountlyAccents.all[index];
          final isSelected = color.toARGB32() == selected;
          return Pressable(
            onTap: () => onChanged(color.toARGB32()),
            pressedScale: 0.85,
            child: AnimatedContainer(
              duration: Motion.fast,
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? context.palette.textPrimary
                      : Colors.transparent,
                  width: 3,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 20,
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }
}

class _DateSection extends StatelessWidget {
  const _DateSection({
    required this.targetDate,
    required this.onPick,
    required this.onClear,
  });

  final DateTime? targetDate;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Row(
      children: [
        Expanded(
          child: Pressable(
            onTap: onPick,
            pressedScale: 0.98,
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: Gap.x4),
              decoration: BoxDecoration(
                color: palette.surfaceSunken,
                borderRadius: BorderRadius.circular(Corner.sm),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.event_rounded,
                    size: 18,
                    color: targetDate == null
                        ? palette.textTertiary
                        : palette.accent,
                  ),
                  const SizedBox(width: Gap.x3),
                  Text(
                    targetDate == null
                        ? 'Sem data — contar dias desde a criação'
                        : formatFullDate(targetDate!),
                    style: AppType.body(palette).copyWith(
                      color: targetDate == null
                          ? palette.textTertiary
                          : palette.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (targetDate != null) ...[
          const SizedBox(width: Gap.x2),
          Pressable(
            onTap: onClear,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: palette.surfaceSunken,
                borderRadius: BorderRadius.circular(Corner.sm),
              ),
              child: Icon(
                Icons.close_rounded,
                size: 18,
                color: palette.textSecondary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _RecurrencePicker extends StatelessWidget {
  const _RecurrencePicker({
    required this.recurrence,
    required this.onChanged,
  });

  final Recurrence recurrence;
  final ValueChanged<Recurrence> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    const options = [
      (RecurrenceFrequency.never, 'Nunca'),
      (RecurrenceFrequency.daily, 'Diária'),
      (RecurrenceFrequency.weekly, 'Semanal'),
      (RecurrenceFrequency.monthly, 'Mensal'),
      (RecurrenceFrequency.yearly, 'Anual'),
      (RecurrenceFrequency.custom, 'Personalizada'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: Gap.x2,
          runSpacing: Gap.x2,
          children: [
            for (final (frequency, label) in options)
              TagChip(
                label: label,
                selected: recurrence.frequency == frequency,
                onTap: () => onChanged(
                  Recurrence(
                    frequency: frequency,
                    intervalDays: recurrence.intervalDays,
                  ),
                ),
              ),
          ],
        ),
        AnimatedSize(
          duration: Motion.base,
          curve: Motion.emphasized,
          alignment: Alignment.topCenter,
          child: recurrence.frequency != RecurrenceFrequency.custom
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(top: Gap.x3),
                  child: Row(
                    children: [
                      Text('A cada', style: AppType.body(palette)),
                      const SizedBox(width: Gap.x3),
                      _IntervalStepper(
                        value: recurrence.intervalDays,
                        onChanged: (days) => onChanged(
                          Recurrence(
                            frequency: RecurrenceFrequency.custom,
                            intervalDays: days,
                          ),
                        ),
                      ),
                      const SizedBox(width: Gap.x3),
                      Text(
                        recurrence.intervalDays == 1 ? 'dia' : 'dias',
                        style: AppType.body(palette),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

class _IntervalStepper extends StatelessWidget {
  const _IntervalStepper({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    Widget button(IconData icon, VoidCallback? onTap) {
      return Pressable(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: palette.surfaceSunken,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 18,
            color: onTap == null ? palette.textTertiary : palette.accent,
          ),
        ),
      );
    }

    return Row(
      children: [
        button(
          Icons.remove_rounded,
          value > 1 ? () => onChanged(value - 1) : null,
        ),
        SizedBox(
          width: 48,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: AppType.headline(palette),
          ),
        ),
        button(
          Icons.add_rounded,
          value < 999 ? () => onChanged(value + 1) : null,
        ),
      ],
    );
  }
}

class _TagsSection extends StatelessWidget {
  const _TagsSection({
    required this.tags,
    required this.input,
    required this.onSubmit,
    required this.onRemove,
  });

  final List<String> tags;
  final TextEditingController input;
  final ValueChanged<String> onSubmit;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (tags.isNotEmpty) ...[
          Wrap(
            spacing: Gap.x2,
            runSpacing: Gap.x2,
            children: [
              for (final tag in tags)
                TagChip(
                  label: '#$tag',
                  selected: true,
                  leading: const Icon(
                    Icons.close_rounded,
                    size: 13,
                    color: Colors.white,
                  ),
                  onTap: () => onRemove(tag),
                ),
            ],
          ),
          const SizedBox(height: Gap.x3),
        ],
        TextField(
          controller: input,
          onSubmitted: onSubmit,
          textInputAction: TextInputAction.done,
          style: AppType.body(palette),
          decoration: InputDecoration(
            hintText: 'Digite uma tag e pressione Enter',
            hintStyle:
                AppType.body(palette).copyWith(color: palette.textTertiary),
            filled: true,
            fillColor: palette.surfaceSunken,
            prefixIcon: Icon(
              Icons.tag_rounded,
              size: 18,
              color: palette.textTertiary,
            ),
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
        ),
      ],
    );
  }
}

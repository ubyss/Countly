import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pasteboard/pasteboard.dart';
import '../models/countdown.dart';
import '../models/repeat_mode.dart';
import '../theme/countly_colors.dart';
import '../utils/countdown_utils.dart';
import 'countdown_image.dart';
import 'countdown_time_overlay.dart';
import 'countly_date_picker.dart';
import 'repeat_toggle.dart';

class CreationSheet extends StatefulWidget {
  const CreationSheet({
    super.key,
    required this.initialName,
    required this.initialTargetDate,
    required this.initialRepeat,
    required this.initialImageBase64,
    required this.currentTime,
    required this.isEditing,
    required this.onSubmit,
    this.scrollController,
  });

  final String initialName;
  final String initialTargetDate;
  final CountlyRepeatMode initialRepeat;
  final String? initialImageBase64;
  final ValueListenable<DateTime> currentTime;
  final bool isEditing;
  final ScrollController? scrollController;
  final void Function({
    required String name,
    required String targetDate,
    required CountlyRepeatMode repeat,
    String? imageBase64,
  }) onSubmit;

  @override
  State<CreationSheet> createState() => _CreationSheetState();
}

class _CreationSheetState extends State<CreationSheet> {
  late final TextEditingController _nameController;
  late String _targetDate;
  late CountlyRepeatMode _repeat;
  String? _imageBase64;
  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _targetDate = widget.initialTargetDate;
    _repeat = widget.initialRepeat;
    _imageBase64 = widget.initialImageBase64;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 72,
      maxWidth: 900,
    );

    if (file == null) {
      return;
    }

    final bytes = await file.readAsBytes();
    setState(() {
      _imageBase64 = base64Encode(bytes);
    });
  }

  Future<void> _pasteImage() async {
    final bytes = await Pasteboard.image;
    if (!mounted) {
      return;
    }

    if (bytes == null || bytes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nenhuma imagem encontrada na área de transferência'),
        ),
      );
      return;
    }

    setState(() {
      _imageBase64 = base64Encode(bytes);
    });
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty || _targetDate.isEmpty) {
      return;
    }

    widget.onSubmit(
      name: name,
      targetDate: normalizeTargetDate(_targetDate),
      repeat: _repeat,
      imageBase64: _imageBase64,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.countlyColors;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + bottomInset),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.isEditing ? 'Editar contagem' : 'Nova contagem',
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(Icons.close_rounded, color: colors.muted, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ImageUploader(
            imageBase64: _imageBase64,
            colors: colors,
            targetDate: _targetDate,
            currentTime: widget.currentTime,
            onPickImage: _pickImage,
            onPasteImage: _pasteImage,
          ),
          const SizedBox(height: 14),
          _FieldLabel('Nome', colors: colors),
          const SizedBox(height: 6),
          TextField(
            controller: _nameController,
            decoration: _inputDecoration(colors, 'ex.: Meu aniversário'),
            style: TextStyle(color: colors.inputText, fontSize: 14),
          ),
          const SizedBox(height: 10),
          _FieldLabel('Data', colors: colors),
          const SizedBox(height: 6),
          CountlyDatePickerField(
            value: _targetDate,
            currentTime: widget.currentTime.value,
            onChanged: (value) => setState(() => _targetDate = value),
            compact: true,
          ),
          const SizedBox(height: 10),
          _FieldLabel('Repetir', colors: colors),
          const SizedBox(height: 6),
          RepeatToggle(
            value: _repeat,
            onChanged: (value) => setState(() => _repeat = value),
            compact: true,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _submit,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
              backgroundColor: colors.accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.event_available_rounded, size: 18),
            label: Text(
              widget.isEditing ? 'Salvar' : 'Adicionar',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(CountlyColors colors, String hint) {
    final isDark = colors.page.computeLuminance() < 0.5;
    final fillColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.white.withValues(alpha: 0.55);

    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: colors.softMuted),
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      isDense: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.borderStrong.withValues(alpha: 0.8)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.borderStrong.withValues(alpha: 0.8)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.accent, width: 1.4),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text, {required this.colors});

  final String text;
  final CountlyColors colors;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: colors.text,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _ImageUploader extends StatelessWidget {
  const _ImageUploader({
    required this.imageBase64,
    required this.colors,
    required this.targetDate,
    required this.currentTime,
    required this.onPickImage,
    required this.onPasteImage,
  });

  final String? imageBase64;
  final CountlyColors colors;
  final String targetDate;
  final ValueListenable<DateTime> currentTime;
  final VoidCallback onPickImage;
  final VoidCallback onPasteImage;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          SizedBox(
            height: 280,
            width: double.infinity,
            child: imageBase64 == null
                ? Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onPickImage,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              colors.accent.withValues(alpha: 0.1),
                              colors.accent.withValues(alpha: 0.02),
                            ],
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_outlined, size: 32, color: colors.muted),
                              const SizedBox(height: 14),
                              Text(
                                'Toque para escolher da galeria',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: colors.text,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Imagem opcional — dá um toque especial à contagem',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: colors.muted,
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                : CountdownImagePreview(
                    imageBase64: imageBase64,
                    colors: colors,
                    height: 280,
                    borderRadius: 0,
                  ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ValueListenableBuilder<DateTime>(
              valueListenable: currentTime,
              builder: (context, time, _) {
                return CountdownTimeOverlay(
                  targetDate: targetDate,
                  currentTime: time,
                  onCard: true,
                );
              },
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: _PasteImageButton(
              colors: colors,
              onTap: onPasteImage,
            ),
          ),
        ],
      ),
    );
  }
}

class _PasteImageButton extends StatelessWidget {
  const _PasteImageButton({
    required this.colors,
    required this.onTap,
  });

  final CountlyColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(20),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.content_paste_rounded, color: colors.muted, size: 18),
              const SizedBox(width: 6),
              Text(
                'Colar',
                style: TextStyle(
                  color: colors.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showCreationSheet({
  required BuildContext context,
  required ValueListenable<DateTime> currentTime,
  Countdown? editing,
  required void Function({
    required String name,
    required String targetDate,
    required CountlyRepeatMode repeat,
    String? imageBase64,
  }) onSubmit,
}) {
  final colors = context.countlyColors;

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return DraggableScrollableSheet(
        initialChildSize: 0.88,
        minChildSize: 0.38,
        maxChildSize: 0.92,
        expand: false,
        builder: (context, scrollController) {
          return DecoratedBox(
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 24,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: CreationSheet(
                    scrollController: scrollController,
                    initialName: editing?.name ?? '',
                    initialTargetDate: editing?.targetDate ?? '',
                    initialRepeat: editing?.repeat ?? CountlyRepeatMode.none,
                    initialImageBase64: editing?.imageBase64,
                    currentTime: currentTime,
                    isEditing: editing != null,
                    onSubmit: onSubmit,
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

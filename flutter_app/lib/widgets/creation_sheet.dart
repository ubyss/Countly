import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/countdown.dart';
import '../models/repeat_mode.dart';
import '../theme/countly_colors.dart';
import '../theme/countly_tokens.dart';
import '../utils/clipboard_image.dart';
import '../utils/countdown_image_utils.dart';
import '../utils/countdown_utils.dart';
import 'countdown_image.dart';
import 'countdown_time_overlay.dart';
import 'countly_date_picker.dart';
import 'pressable.dart';
import 'repeat_toggle.dart';

class CreationSheet extends StatefulWidget {
  const CreationSheet({
    super.key,
    required this.initialName,
    required this.initialTargetDate,
    required this.initialRepeat,
    required this.initialImageBase64,
    required this.initialImageAlignment,
    required this.currentTime,
    required this.isEditing,
    required this.onSubmit,
    this.onDelete,
    this.scrollController,
  });

  final String initialName;
  final String initialTargetDate;
  final CountlyRepeatMode initialRepeat;
  final String? initialImageBase64;
  final Alignment initialImageAlignment;
  final ValueListenable<DateTime> currentTime;
  final bool isEditing;
  final ScrollController? scrollController;
  final VoidCallback? onDelete;
  final void Function({
    required String name,
    required String targetDate,
    required CountlyRepeatMode repeat,
    String? imageBase64,
    Alignment imageAlignment,
  }) onSubmit;

  @override
  State<CreationSheet> createState() => _CreationSheetState();
}

class _CreationSheetState extends State<CreationSheet> {
  late final TextEditingController _nameController;
  late String _targetDate;
  late CountlyRepeatMode _repeat;
  String? _imageBase64;
  Alignment _imageAlignment = Alignment.center;
  bool _isPastingImage = false;
  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _targetDate = widget.initialTargetDate;
    _repeat = widget.initialRepeat;
    _imageBase64 = widget.initialImageBase64;
    _imageAlignment = widget.initialImageAlignment;
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
    final encoded = await prepareCountdownImageBase64(bytes);
    if (!mounted || encoded == null) {
      return;
    }

    setState(() {
      _imageBase64 = encoded;
      _imageAlignment = Alignment.center;
    });
  }

  Future<void> _pasteImage() async {
    if (_isPastingImage) {
      return;
    }

    setState(() => _isPastingImage = true);
    await Future<void>.delayed(Duration.zero);

    try {
      final bytes = await readClipboardImageBytes();
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

      final encoded = await prepareCountdownImageBase64(bytes);
      if (!mounted) {
        return;
      }

      if (encoded == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível usar esta imagem'),
          ),
        );
        return;
      }

      setState(() {
        _imageBase64 = encoded;
        _imageAlignment = Alignment.center;
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível colar a imagem'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPastingImage = false);
      }
    }
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
      imageAlignment: _imageAlignment,
    );
    Navigator.of(context).pop();
  }

  Future<void> _confirmDelete() async {
    if (widget.onDelete == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final colors = dialogContext.countlyColors;
        return AlertDialog(
          backgroundColor: colors.card,
          title: Text(
            'Excluir contagem?',
            style: TextStyle(color: colors.text, fontWeight: FontWeight.w800),
          ),
          content: Text(
            'Tem certeza que deseja excluir esta contagem? Esta ação não pode ser desfeita.',
            style: TextStyle(color: colors.muted, height: 1.45),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text('Cancelar', style: TextStyle(color: colors.muted)),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text(
                'Excluir',
                style: TextStyle(
                  color: Color(0xFFDC4B4B),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    widget.onDelete?.call();
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
            imageAlignment: _imageAlignment,
            colors: colors,
            targetDate: _targetDate,
            currentTime: widget.currentTime,
            onPickImage: _pickImage,
            onPasteImage: _pasteImage,
            onAlignmentChanged: (value) => setState(() => _imageAlignment = value),
            isPastingImage: _isPastingImage,
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
            opensAbove: true,
          ),
          const SizedBox(height: 10),
          _FieldLabel('Repetir', colors: colors),
          const SizedBox(height: 6),
          RepeatToggle(
            value: _repeat,
            onChanged: (value) => setState(() => _repeat = value),
            compact: true,
          ),
          const SizedBox(height: CountlySpacing.lg),
          Pressable(
            scaleDown: 0.98,
            child: FilledButton.icon(
              onPressed: _submit,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                backgroundColor: colors.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CountlyRadius.md)),
              ),
              icon: const Icon(Icons.event_available_rounded, size: 18),
              label: Text(
                widget.isEditing ? 'Salvar' : 'Adicionar',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
          ),
          if (widget.isEditing && widget.onDelete != null) ...[
            const SizedBox(height: CountlySpacing.sm + 2),
            Pressable(
              scaleDown: 0.98,
              child: OutlinedButton.icon(
                onPressed: _confirmDelete,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                  foregroundColor: const Color(0xFFDC4B4B),
                  side: BorderSide(color: const Color(0xFFDC4B4B).withValues(alpha: 0.45)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CountlyRadius.md)),
                ),
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text(
                  'Excluir contagem',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
            ),
          ],
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
        borderRadius: BorderRadius.circular(CountlyRadius.md),
        borderSide: BorderSide(color: colors.borderStrong.withValues(alpha: 0.8)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(CountlyRadius.md),
        borderSide: BorderSide(color: colors.borderStrong.withValues(alpha: 0.8)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(CountlyRadius.md),
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
    required this.imageAlignment,
    required this.colors,
    required this.targetDate,
    required this.currentTime,
    required this.onPickImage,
    required this.onPasteImage,
    required this.onAlignmentChanged,
    required this.isPastingImage,
  });

  final String? imageBase64;
  final Alignment imageAlignment;
  final CountlyColors colors;
  final String targetDate;
  final ValueListenable<DateTime> currentTime;
  final VoidCallback onPickImage;
  final VoidCallback onPasteImage;
  final ValueChanged<Alignment> onAlignmentChanged;
  final bool isPastingImage;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(CountlyRadius.lg),
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
                    alignment: imageAlignment,
                    panEnabled: true,
                    onAlignmentChanged: onAlignmentChanged,
                  ),
          ),
          if (imageBase64 != null)
            Positioned(
              left: 12,
              bottom: 62,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    'Arraste para ajustar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
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
              isLoading: isPastingImage,
              onTap: isPastingImage ? null : onPasteImage,
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
    required this.isLoading,
    required this.onTap,
  });

  final CountlyColors colors;
  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      scaleDown: 0.95,
      child: Material(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(20),
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLoading)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.accent,
                    ),
                  )
                else
                  Icon(Icons.content_paste_rounded, color: colors.muted, size: 17),
                const SizedBox(width: 5),
                Text(
                  'Colar da área de transferência',
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
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
  VoidCallback? onDelete,
  required void Function({
    required String name,
    required String targetDate,
    required CountlyRepeatMode repeat,
    String? imageBase64,
    Alignment imageAlignment,
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
              borderRadius: const BorderRadius.vertical(top: Radius.circular(CountlyRadius.lg)),
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
                    initialImageAlignment: editing?.imageAlignment ?? Alignment.center,
                    currentTime: currentTime,
                    isEditing: editing != null,
                    onDelete: onDelete,
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

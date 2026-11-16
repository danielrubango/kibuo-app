import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:kibuo/data/attachment_repository.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/kit/sheet.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_icons.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

/// A file picked to attach.
class PickedAttachment {
  const PickedAttachment({
    required this.bytes,
    required this.name,
    required this.kind,
  });

  final Uint8List bytes;

  /// The file's name, or null for a photo (named « Photo 2 »).
  final String? name;
  final AttachmentKind kind;
}

enum AttachmentSource { camera, gallery, file }

/// Where attachments come from: the phone's camera, gallery and files.
abstract class AttachmentPicker {
  Future<PickedAttachment?> pick(AttachmentSource source);
}

/// Photos reduced to 1 600 pixels (ADR 0011); files as they are.
class DeviceAttachmentPicker implements AttachmentPicker {
  const DeviceAttachmentPicker();

  @override
  Future<PickedAttachment?> pick(AttachmentSource source) async {
    if (source == AttachmentSource.file) {
      final files = await FilePicker.pickFiles();
      final file = files.singleOrNull;
      if (file == null) return null;
      final extension = file.extension?.toLowerCase().replaceAll('.', '');
      final pdf = extension == 'pdf';
      final image = ['jpg', 'jpeg', 'png', 'webp', 'heic'].contains(extension);
      return PickedAttachment(
        bytes: await file.readAsBytes(),
        name: file.name,
        kind: pdf
            ? AttachmentKind.pdf
            : image
            ? AttachmentKind.photo
            : AttachmentKind.file,
      );
    }
    final photo = await ImagePicker().pickImage(
      source: source == AttachmentSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 80,
    );
    if (photo == null) return null;
    return PickedAttachment(
      bytes: await photo.readAsBytes(),
      name: null,
      kind: AttachmentKind.photo,
    );
  }
}

/// « Prendre une photo », « Choisir dans la galerie », « Choisir un
/// fichier ».
Future<AttachmentSource?> pickAttachmentSource(BuildContext context) {
  final l = AppLocalizations.of(context);
  Widget line(
    BuildContext context,
    IconData icon,
    String label,
    AttachmentSource source,
  ) => InkWell(
    onTap: () => Navigator.of(context).pop(source),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: KibuoColors.accentTint,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 20, color: KibuoColors.accent),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: KibuoType.rowLabel)),
        ],
      ),
    ),
  );
  return showKibuoSheet<AttachmentSource>(
    context,
    title: l.attachTitle,
    builder: (context) => Material(
      color: KibuoColors.surface,
      borderRadius: BorderRadius.circular(KibuoTheme.radiusCard),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          line(
            context,
            KibuoIcons.camera,
            l.attachPhoto,
            AttachmentSource.camera,
          ),
          line(
            context,
            KibuoIcons.image,
            l.attachGallery,
            AttachmentSource.gallery,
          ),
          line(context, KibuoIcons.file, l.attachFile, AttachmentSource.file),
        ],
      ),
    ),
  );
}

/// « 240 Ko », « 1,2 Mo ».
String attachmentSize(BuildContext context, int bytes) {
  final lang = Localizations.localeOf(context).languageCode;
  final fr = lang == 'fr';
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).ceil()} ${fr ? 'Ko' : 'KB'}';
  }
  final mb = NumberFormat.decimalPatternDigits(
    locale: lang,
    decimalDigits: 1,
  ).format(bytes / 1024 / 1024);
  return '$mb ${fr ? 'Mo' : 'MB'}';
}

/// The « Pièces jointes 3/5 » card (canvas PJLignes): a line per file with
/// its preview, a circle to choose it; « Ajouter » until there are five.
class AttachmentsCard extends StatelessWidget {
  const AttachmentsCard({
    super.key,
    required this.items,
    required this.preview,
    this.selected = const {},
    this.onToggle,
    this.onAdd,
    this.onOpen,
    this.error,
  });

  final List<AttachmentInfo> items;

  /// The decrypted bytes of a photo, for its preview.
  final Future<Uint8List> Function(String id) preview;
  final Set<String> selected;

  /// Null in an operation's detail: attachments are only looked at there,
  /// and changed from « Modifier ».
  final ValueChanged<String>? onToggle;
  final VoidCallback? onAdd;

  /// Touching a line opens it, where lines can't be chosen.
  final ValueChanged<AttachmentInfo>? onOpen;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final full = items.length >= AttachmentRepository.maxCount;
    return Container(
      // 8 here and 8 in each line: titles, previews, « + Ajouter » and the
      // circles all sit 16 from the edges (PJLignes); a chosen line's tint
      // reaches 8 beyond them.
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      decoration: BoxDecoration(
        color: KibuoColors.surface,
        borderRadius: BorderRadius.circular(KibuoTheme.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: KibuoTheme.heightTouch,
            padding: const EdgeInsets.only(left: 8, right: 4),
            child: Row(
              children: [
                const Icon(
                  KibuoIcons.paperclip,
                  size: 14,
                  color: KibuoColors.inkSecondary,
                ),
                const SizedBox(width: 8),
                // One Expanded, not Flexible plus Spacer: those two would
                // split the free width and leave a gap after « Ajouter ».
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          l.attachTitle,
                          style: KibuoType.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (items.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          '${items.length}/${AttachmentRepository.maxCount}',
                          style: KibuoType.caption.copyWith(
                            color: KibuoColors.inkMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (items.isNotEmpty && !full && onAdd != null)
                  InkWell(
                    onTap: onAdd,
                    borderRadius: BorderRadius.circular(KibuoTheme.radiusPill),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(4, 12, 4, 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            KibuoIcons.plusBold,
                            size: 14,
                            color: KibuoColors.accent,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            l.attachAdd,
                            style: KibuoType.buttonSmall.copyWith(
                              fontSize: 13,
                              color: KibuoColors.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (items.isEmpty && onAdd != null)
            InkWell(
              onTap: onAdd,
              borderRadius: BorderRadius.circular(KibuoTheme.radiusTile),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: KibuoColors.accentTint,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        KibuoIcons.plusBold,
                        color: KibuoColors.accent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.attachEmpty,
                            style: KibuoType.rowLabel.copyWith(
                              color: KibuoColors.accent,
                              fontWeight: FontWeight.w600,
                              fontVariations: const [FontVariation.weight(600)],
                            ),
                          ),
                          Text(l.attachEmptyHelp, style: KibuoType.caption),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            for (final a in items)
              _Line(
                item: a,
                preview: preview,
                selected: selected.contains(a.id),
                choosable: onToggle != null,
                onTap: onToggle != null
                    ? () => onToggle!(a.id)
                    : onOpen == null
                    ? null
                    : () => onOpen!(a),
                // Where lines are chosen, the preview still opens the
                // attachment (owner, 15 November 2026).
                onPreviewTap: onToggle != null && onOpen != null
                    ? () => onOpen!(a)
                    : null,
              ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 8, 0),
              child: Text(
                error!,
                style: KibuoType.help.copyWith(color: KibuoColors.danger),
              ),
            ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({
    required this.item,
    required this.preview,
    required this.selected,
    required this.choosable,
    required this.onTap,
    this.onPreviewTap,
  });

  final AttachmentInfo item;
  final Future<Uint8List> Function(String id) preview;
  final bool selected;

  /// No circle when false.
  final bool choosable;
  final VoidCallback? onTap;

  /// Opens the attachment from its preview, apart from [onTap].
  final VoidCallback? onPreviewTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final kindText = switch (item.kind) {
      AttachmentKind.photo => l.attachKindPhoto,
      AttachmentKind.pdf => l.attachKindPdf,
      AttachmentKind.file => l.attachKindFile,
    };
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? KibuoColors.accentTint : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  Semantics(
                    button: onPreviewTap != null,
                    label: onPreviewTap == null
                        ? null
                        : AppLocalizations.of(context).attachView,
                    child: GestureDetector(
                      onTap: onPreviewTap,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox.square(
                          dimension: 52,
                          child: item.kind == AttachmentKind.photo
                              ? FutureBuilder<Uint8List>(
                                  future: preview(item.id),
                                  builder: (context, snap) => snap.hasData
                                      ? Image.memory(
                                          snap.data!,
                                          fit: BoxFit.cover,
                                          cacheWidth: 156,
                                        )
                                      : const ColoredBox(
                                          color: KibuoColors.fill,
                                        ),
                                )
                              : ColoredBox(
                                  color: KibuoColors.projectTint,
                                  child: Icon(
                                    item.kind == AttachmentKind.pdf
                                        ? KibuoIcons.filePdf
                                        : KibuoIcons.file,
                                    color: KibuoColors.projectInk,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: KibuoType.body.copyWith(
                            fontWeight: FontWeight.w500,
                            fontVariations: const [FontVariation.weight(500)],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$kindText · ${attachmentSize(context, item.size)}',
                          style: KibuoType.caption,
                        ),
                      ],
                    ),
                  ),
                  if (!choosable)
                    const SizedBox.shrink()
                  else if (selected) ...[
                    const SizedBox(width: 12),
                    const Icon(
                      KibuoIcons.checkCircleFill,
                      color: KibuoColors.accent,
                      size: 24,
                    ),
                  ] else ...[
                    const SizedBox(width: 12),
                    Container(
                      width: 22,
                      height: 22,
                      margin: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: KibuoColors.lineStrong,
                          width: 2,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The bar at the bottom while attachments are chosen (canvas PJSelBarre):
/// ✕, how many, « Retirer ».
class AttachmentSelectionBar extends StatelessWidget {
  const AttachmentSelectionBar({
    super.key,
    required this.count,
    required this.onClear,
    required this.onRemove,
    this.onView,
  });

  final int count;
  final VoidCallback onClear;
  final VoidCallback onRemove;

  /// Shown when exactly one attachment is chosen.
  final VoidCallback? onView;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: KibuoColors.surface,
        borderRadius: BorderRadius.circular(KibuoTheme.radiusCard),
        boxShadow: const [
          BoxShadow(
            color: KibuoColors.barShadow,
            blurRadius: 24,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onClear,
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            icon: const Icon(KibuoIcons.x, color: KibuoColors.inkSecondary),
          ),
          Expanded(
            child: Text(l.attachChosen(count), style: KibuoType.rowLabel),
          ),
          if (count == 1 && onView != null)
            TextButton(
              onPressed: onView,
              style: TextButton.styleFrom(
                foregroundColor: KibuoColors.accent,
                textStyle: KibuoType.buttonSmall,
              ),
              child: Text(l.attachView),
            ),
          TextButton(
            onPressed: onRemove,
            style: TextButton.styleFrom(
              foregroundColor: KibuoColors.danger,
              textStyle: KibuoType.buttonSmall,
            ),
            child: Text(l.attachRemove),
          ),
        ],
      ),
    );
  }
}

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:kibuo/data/attachment_repository.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_icons.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';
import 'package:kibuo/ui/transactions/attachments_card.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';

/// The first page of a PDF, drawn as an image.
class PdfFirstPage {
  const PdfFirstPage({required this.image, required this.pages});

  final Uint8List image;
  final int pages;
}

/// What the viewer needs from the phone: drawing a PDF's first page, and
/// handing a file to another app.
abstract class AttachmentOpener {
  Future<PdfFirstPage?> firstPage(Uint8List pdf);

  /// False when no app of the phone opens this kind of file.
  Future<bool> openWith(Uint8List bytes, String name);
}

class DeviceAttachmentOpener implements AttachmentOpener {
  const DeviceAttachmentOpener();

  @override
  Future<PdfFirstPage?> firstPage(Uint8List pdf) async {
    try {
      final doc = await PdfDocument.openData(pdf);
      try {
        final page = await doc.getPage(1);
        final image = await page.render(
          width: page.width * 2,
          height: page.height * 2,
          format: PdfPageImageFormat.png,
          backgroundColor: '#FFFFFF',
        );
        await page.close();
        if (image == null) return null;
        return PdfFirstPage(image: image.bytes, pages: doc.pagesCount);
      } finally {
        await doc.close();
      }
    } on Object {
      return null;
    }
  }

  /// The decrypted copy goes to Kibuo's cache, in a folder emptied each
  /// time, so at most one file sits there in clear (ADR 0011).
  @override
  Future<bool> openWith(Uint8List bytes, String name) async {
    final folder = Directory(
      p.join((await getTemporaryDirectory()).path, 'shared'),
    );
    if (folder.existsSync()) await folder.delete(recursive: true);
    await folder.create(recursive: true);
    final file = File(p.join(folder.path, p.basename(name)));
    await file.writeAsBytes(bytes);
    final result = await OpenFilex.open(file.path);
    return result.type == ResultType.done;
  }
}

/// An attachment seen on its own, on a dark background. Nothing is changed
/// here (owner, 15 November 2026).
class AttachmentViewer extends StatefulWidget {
  const AttachmentViewer({
    super.key,
    required this.item,
    required this.read,
    this.opener = const DeviceAttachmentOpener(),
  });

  final AttachmentInfo item;
  final Future<Uint8List> Function(String id) read;
  final AttachmentOpener opener;

  @override
  State<AttachmentViewer> createState() => _AttachmentViewerState();
}

class _AttachmentViewerState extends State<AttachmentViewer> {
  Uint8List? _bytes;
  PdfFirstPage? _page;
  bool _loaded = false;

  static const _soft = KibuoColors.lineStrong;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final bytes = await widget.read(widget.item.id);
    if (!mounted) return;
    setState(() {
      _bytes = bytes;
      _loaded = true;
    });
    // The page comes after: until then, and if it can't be drawn, the PDF
    // shows as an icon, with « Ouvrir avec… » already there.
    if (widget.item.kind != AttachmentKind.pdf) return;
    final page = await widget.opener.firstPage(bytes);
    if (mounted && page != null) setState(() => _page = page);
  }

  Future<void> _openWith() async {
    final bytes = _bytes;
    if (bytes == null) return;
    final l = AppLocalizations.of(context);
    final done = await widget.opener.openWith(bytes, widget.item.name);
    if (done || !mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(l.attachNoApp),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final item = widget.item;
    final kindText = switch (item.kind) {
      AttachmentKind.photo => l.attachKindPhoto,
      AttachmentKind.pdf => l.attachKindPdf,
      AttachmentKind.file => l.attachKindFile,
    };
    final photo = item.kind == AttachmentKind.photo;
    return Scaffold(
      backgroundColor: KibuoColors.ink,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 56,
              child: Row(
                children: [
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: MaterialLocalizations.of(context)
                        .closeButtonTooltip,
                    icon: const Icon(KibuoIcons.x, color: Colors.white),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: KibuoType.body.copyWith(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            fontVariations: const [FontVariation.weight(600)],
                          ),
                        ),
                        Text(
                          '$kindText · ${attachmentSize(context, item.size)}',
                          style: KibuoType.caption.copyWith(color: _soft),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
            ),
            Expanded(child: _content(l)),
            if (_loaded && !photo)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: TextButton(
                    onPressed: _openWith,
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.12),
                      foregroundColor: Colors.white,
                      textStyle: KibuoType.buttonSmall.copyWith(fontSize: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(l.attachOpenWith),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _content(AppLocalizations l) {
    final bytes = _bytes;
    if (!_loaded || bytes == null) return const SizedBox.shrink();
    switch (widget.item.kind) {
      case AttachmentKind.photo:
        return InteractiveViewer(
          maxScale: 5,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.memory(bytes, fit: BoxFit.contain),
              ),
            ),
          ),
        );
      case AttachmentKind.pdf:
        final page = _page;
        if (page != null) {
          return Column(
            children: [
              Expanded(
                child: InteractiveViewer(
                  maxScale: 5,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(40, 16, 40, 0),
                    child: Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.memory(page.image, fit: BoxFit.contain),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l.attachPage(page.pages),
                style: KibuoType.caption.copyWith(color: _soft),
              ),
            ],
          );
        }
        return _fileIcon(KibuoIcons.filePdf);
      case AttachmentKind.file:
        return _fileIcon(KibuoIcons.file);
    }
  }

  Widget _fileIcon(IconData icon) => Center(
    child: Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Icon(icon, size: 40, color: _soft),
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:kibuo/data/category_repository.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/categories/category_labels.dart';
import 'package:kibuo/ui/kit/buttons.dart';
import 'package:kibuo/ui/kit/cards.dart';
import 'package:kibuo/ui/kit/fields.dart';
import 'package:kibuo/ui/kit/form_top_bar.dart';
import 'package:kibuo/ui/kit/icon_grid.dart';
import 'package:kibuo/ui/kit/sheet.dart';
import 'package:kibuo/ui/lock/protect_sheet.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

/// « Nouvelle catégorie » or « Nouvelle sous-catégorie » under [parent]
/// (canvas: CatNouvelle), or the editing of [category] (CatModif): name,
/// icon, and « Retirer la catégorie ». Pops true when something changed.
class CategoryFormScreen extends StatefulWidget {
  const CategoryFormScreen({
    super.key,
    required this.categories,
    required this.kind,
    this.parent,
    this.category,
  });

  final CategoryRepository categories;
  final CategoryKind kind;
  final CategoryInfo? parent;
  final CategoryInfo? category;

  @override
  State<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends State<CategoryFormScreen> {
  final _name = TextEditingController();
  late String _icon = widget.category?.icon ?? categoryIcons.keys.first;
  String? _shownAtStart;

  bool get _editing => widget.category != null;
  bool get _isSub => widget.parent != null || widget.category?.parentId != null;

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final category = widget.category;
    if (category != null && _shownAtStart == null) {
      _shownAtStart = categoryName(AppLocalizations.of(context), category);
      _name.text = _shownAtStart!;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final category = widget.category;
    if (category == null) {
      await widget.categories.create(
        kind: widget.kind,
        name: _name.text,
        icon: _icon,
        parentId: widget.parent?.id,
      );
    } else {
      // An untouched provided name keeps following the app's language.
      final renamed = _name.text.trim() != _shownAtStart;
      await widget.categories.update(
        category.id,
        name: renamed || category.name != null ? _name.text : null,
        icon: _icon,
      );
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  /// « Supprimer Transport ? » (canvas ConfirmCategorie), then the code
  /// when important actions ask for it.
  Future<void> _remove() async {
    final l = AppLocalizations.of(context);
    final category = widget.category!;
    final name = categoryName(l, category);
    final sure = await confirmRemoval(
      context,
      title: l.confirmCategoryTitle(name),
      summary: RemovalSummary(
        leading: CategoryTile(category: category, size: 36),
        title: name,
        subtitle: category.subs.isEmpty
            ? null
            : [for (final s in category.subs) categoryName(l, s)].join(', '),
      ),
      text: l.confirmCategoryHelp(name, category.subs.length),
      action: l.confirmCategoryAction,
    );
    if (!sure || !mounted) return;
    if (!await confirmWithCode(context, l.protectDeleteCategory(name))) {
      return;
    }
    await widget.categories.remove(category.id);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final parent = widget.parent;
    final subs = widget.category?.subs.length ?? 0;
    final title = _editing
        ? (_isSub ? l.categoryEditSubTitle : l.categoryEditTitle)
        : (_isSub ? l.categoryNewSubTitle : l.categoryNewTitle);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            FormTopBar(title: title, cancel: l.cancel),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  if (parent != null) ...[
                    FieldLabel(l.categoryIn),
                    _ParentRow(parent: parent, name: categoryName(l, parent)),
                    const SizedBox(height: 16),
                  ],
                  KibuoTextField(
                    label: l.categoryNameLabel,
                    hint: l.categoryNameHint,
                    controller: _name,
                    autofocus: !_editing,
                  ),
                  const SizedBox(height: 16),
                  FieldLabel(l.categoryIcon),
                  IconGrid(
                    icons: categoryIcons,
                    chosen: _icon,
                    onPick: (name) => setState(() => _icon = name),
                  ),
                  if (_editing) ...[
                    const SizedBox(height: 24),
                    SettingsCard(
                      children: [
                        SettingsRow(
                          label: _isSub
                              ? l.categoryRemoveSub
                              : l.categoryRemove,
                          danger: true,
                          onTap: _remove,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    HelpText(
                      subs == 0
                          ? l.categoryRemoveHelp
                          : '${l.categoryRemoveHelp} '
                                '${l.categoryRemoveSubsToo(subs)}',
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: KibuoButton(
                label: _editing
                    ? l.categorySave
                    : (_isSub ? l.categoryCreateSub : l.categoryCreate),
                onPressed: _name.text.trim().isEmpty ? null : _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParentRow extends StatelessWidget {
  const _ParentRow({required this.parent, required this.name});

  final CategoryInfo parent;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: KibuoTheme.heightField,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: KibuoColors.surface,
        borderRadius: BorderRadius.circular(KibuoTheme.radiusTile),
      ),
      child: Row(
        children: [
          CategoryTile(category: parent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(name, style: KibuoType.body.copyWith(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}

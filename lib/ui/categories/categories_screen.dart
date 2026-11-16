import 'package:flutter/material.dart';
import 'package:kibuo/data/category_repository.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/categories/category_form_screen.dart';
import 'package:kibuo/ui/categories/category_labels.dart';
import 'package:kibuo/ui/kit/buttons.dart';
import 'package:kibuo/ui/kit/segmented_tabs.dart';
import 'package:kibuo/ui/kit/sheet.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_icons.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

/// Plus › Catégories (canvas: Catégories): expenses or income, each
/// category opening on its subcategories. Touching a name edits it.
class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key, required this.categories});

  final CategoryRepository categories;

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  CategoryKind _kind = CategoryKind.out;
  List<CategoryInfo> _list = const [];
  String? _open;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await widget.categories.categories(_kind);
    if (mounted) setState(() => _list = list);
  }

  Future<void> _form({CategoryInfo? parent, CategoryInfo? category}) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CategoryFormScreen(
          categories: widget.categories,
          kind: _kind,
          parent: parent,
          category: category,
        ),
      ),
    );
    if (changed ?? false) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.categoriesTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          SegmentedTabs(
            items: [
              (CategoryKind.out, l.categoriesExpenses),
              (CategoryKind.into, l.categoriesIncome),
            ],
            value: _kind,
            onPick: (kind) {
              setState(() {
                _kind = kind;
                _open = null;
              });
              _load();
            },
          ),
          const SizedBox(height: 12),
          if (_list.isNotEmpty)
            Material(
              color: KibuoColors.surface,
              borderRadius: BorderRadius.circular(KibuoTheme.radiusCard),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (final (i, c) in _list.indexed) ...[
                    if (i > 0 && _open != c.id && _open != _list[i - 1].id)
                      const Divider(
                        height: 1,
                        indent: 14,
                        endIndent: 14,
                        color: KibuoColors.background,
                      ),
                    _CategoryRow(
                      category: c,
                      name: categoryName(l, c),
                      count: c.subs.isEmpty
                          ? null
                          : l.categoriesSubCount(c.subs.length),
                      open: _open == c.id,
                      onEdit: () => _form(category: c),
                      onToggle: () =>
                          setState(() => _open = _open == c.id ? null : c.id),
                    ),
                    if (_open == c.id)
                      Container(
                        color: KibuoColors.fillSoft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final s in c.subs)
                              InkWell(
                                onTap: () => _form(category: s),
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    52,
                                    12,
                                    16,
                                    12,
                                  ),
                                  child: Text(
                                    categoryName(l, s),
                                    style: KibuoType.rowLabel,
                                  ),
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.only(left: 40),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: TextAction(
                                  label: l.categoriesAddSub,
                                  onPressed: () => _form(parent: c),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ],
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomAction(
        child: KibuoButton(label: l.categoriesAdd, onPressed: () => _form()),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.category,
    required this.name,
    required this.open,
    required this.onEdit,
    required this.onToggle,
    this.count,
  });

  final CategoryInfo category;
  final String name;
  final String? count;
  final bool open;
  final VoidCallback onEdit;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: open ? KibuoColors.fillSoft : null,
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onEdit,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                child: Row(
                  children: [
                    CategoryTile(category: category),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: KibuoType.rowLabel.copyWith(
                          fontWeight: open ? FontWeight.w600 : null,
                          fontVariations: open
                              ? const [FontVariation.weight(600)]
                              : null,
                        ),
                      ),
                    ),
                    if (count != null)
                      Text(
                        count!,
                        style: KibuoType.caption.copyWith(fontSize: 13),
                      ),
                  ],
                ),
              ),
            ),
          ),
          // The chevron opens the subcategories; it turns up when open.
          Semantics(
            label: count == null ? name : '$name · $count',
            button: true,
            expanded: open,
            excludeSemantics: true,
            child: InkWell(
              onTap: onToggle,
              customBorder: const CircleBorder(),
              child: SizedBox.square(
                dimension: KibuoTheme.heightTouch,
                child: Center(
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: open
                          ? KibuoColors.accentTintOpen
                          : KibuoColors.background,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      open ? KibuoIcons.caretUp : KibuoIcons.caretDown,
                      size: 16,
                      color: open ? KibuoColors.accent : KibuoColors.ink,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

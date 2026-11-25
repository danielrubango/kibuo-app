import 'package:flutter/material.dart';
import 'package:kibuo/data/account_repository.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/accounts/account_types.dart';
import 'package:kibuo/ui/kit/buttons.dart';
import 'package:kibuo/ui/kit/cards.dart';
import 'package:kibuo/ui/kit/fields.dart';
import 'package:kibuo/ui/kit/icon_grid.dart';
import 'package:kibuo/ui/kit/sheet.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_icons.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

/// « Nouveau type » (canvas: TypeCompte): a name and an icon among about
/// twenty. Pops the new type's id. With [type], « Modifier le type »: the
/// same form, and « Supprimer ce type » while no account uses it.
class AccountTypeScreen extends StatefulWidget {
  const AccountTypeScreen({super.key, required this.accounts, this.type});

  final AccountRepository accounts;
  final CustomAccountType? type;

  @override
  State<AccountTypeScreen> createState() => _AccountTypeScreenState();
}

class _AccountTypeScreenState extends State<AccountTypeScreen> {
  late final _name = TextEditingController(text: widget.type?.name);
  late String _icon = widget.type?.icon ?? customTypeIcons.keys.first;
  late final String _firstIcon = _icon;
  final _nameKey = GlobalKey();

  /// Saving touched without a name: it shows in red.
  bool _tried = false;

  /// Something typed or chosen (DIRECTION, 25 November 2026).
  bool get _touched =>
      _name.text.trim().isNotEmpty ||
      _icon != _firstIcon ||
      widget.type != null;

  void _trySave() {
    if (_name.text.trim().isNotEmpty) {
      _save();
      return;
    }
    setState(() => _tried = true);
    showMissing(_nameKey);
  }

  /// How many accounts use the type being changed.
  int? _use;

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
    if (widget.type case final type?) {
      widget.accounts.typeUse(type.id).then((n) {
        if (mounted) setState(() => _use = n);
      });
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final type = widget.type;
    final String id;
    if (type == null) {
      id = await widget.accounts.createType(name: _name.text, icon: _icon);
    } else {
      id = type.id;
      await widget.accounts.updateType(id, name: _name.text, icon: _icon);
    }
    if (mounted) Navigator.of(context).pop(id);
  }

  Future<void> _delete() async {
    final l = AppLocalizations.of(context);
    final type = widget.type!;
    final sure = await confirmRemoval(
      context,
      title: l.typeDeleteTitle(type.name),
      summary: Row(
        children: [
          Icon(customTypeIcons[type.icon] ?? KibuoIcons.wallet, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(type.name, style: KibuoType.rowLabel)),
        ],
      ),
      text: l.typeDeleteText,
      action: l.typeDeleteAction,
    );
    if (!sure) return;
    await widget.accounts.removeType(type.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.type == null ? l.typeNewTitle : l.typeEditTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          KibuoTextField(
            key: _nameKey,
            label: l.typeName,
            hint: l.typeNameHint,
            controller: _name,
            autofocus: true,
            missing: _tried && _name.text.trim().isEmpty,
          ),
          const SizedBox(height: 16),
          FieldLabel(l.typeIcon),
          IconGrid(
            icons: customTypeIcons,
            chosen: _icon,
            onPick: (name) => setState(() => _icon = name),
          ),
          if (widget.type != null && _use != null) ...[
            const SizedBox(height: 16),
            Center(
              child: TextAction(
                label: l.typeDelete,
                color: KibuoColors.danger,
                onPressed: _use == 0 ? _delete : null,
              ),
            ),
            if (_use! > 0) HelpText(l.typeInUse(_use!)),
          ],
        ],
      ),
      bottomNavigationBar: BottomAction(
        child: KibuoButton(
          label: l.typeSave,
          onPressed: _touched ? _trySave : null,
        ),
      ),
    );
  }
}

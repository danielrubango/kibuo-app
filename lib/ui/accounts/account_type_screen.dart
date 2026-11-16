import 'package:flutter/material.dart';
import 'package:kibuo/data/account_repository.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/accounts/account_types.dart';
import 'package:kibuo/ui/kit/buttons.dart';
import 'package:kibuo/ui/kit/fields.dart';
import 'package:kibuo/ui/kit/icon_grid.dart';
import 'package:kibuo/ui/kit/sheet.dart';

/// « Nouveau type » (canvas: TypeCompte): a name and an icon among about
/// twenty. Pops the new type's id.
class AccountTypeScreen extends StatefulWidget {
  const AccountTypeScreen({super.key, required this.accounts});

  final AccountRepository accounts;

  @override
  State<AccountTypeScreen> createState() => _AccountTypeScreenState();
}

class _AccountTypeScreenState extends State<AccountTypeScreen> {
  final _name = TextEditingController();
  String _icon = customTypeIcons.keys.first;

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final id = await widget.accounts.createType(name: _name.text, icon: _icon);
    if (mounted) Navigator.of(context).pop(id);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.typeNewTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          KibuoTextField(
            label: l.typeName,
            hint: l.typeNameHint,
            controller: _name,
            autofocus: true,
          ),
          const SizedBox(height: 16),
          FieldLabel(l.typeIcon),
          IconGrid(
            icons: customTypeIcons,
            chosen: _icon,
            onPick: (name) => setState(() => _icon = name),
          ),
        ],
      ),
      bottomNavigationBar: BottomAction(
        child: KibuoButton(
          label: l.typeSave,
          onPressed: _name.text.trim().isEmpty ? null : _save,
        ),
      ),
    );
  }
}

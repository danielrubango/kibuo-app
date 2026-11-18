import 'package:flutter/material.dart';
import 'package:kibuo/data/account_repository.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/accounts/account_type_screen.dart';
import 'package:kibuo/ui/accounts/account_types.dart';
import 'package:kibuo/ui/kit/buttons.dart';
import 'package:kibuo/ui/kit/cards.dart';
import 'package:kibuo/ui/kit/group_title.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_icons.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

/// « Types de compte » (PRODUCT: À reprendre): the provided types, which
/// stay as they are, then the user's, each opening « Modifier le type »,
/// and « Créer un autre type ».
class AccountTypesScreen extends StatefulWidget {
  const AccountTypesScreen({super.key, required this.accounts});

  final AccountRepository accounts;

  @override
  State<AccountTypesScreen> createState() => _AccountTypesScreenState();
}

class _AccountTypesScreenState extends State<AccountTypesScreen> {
  List<CustomAccountType>? _custom;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final custom = await widget.accounts.types();
    if (mounted) setState(() => _custom = custom);
  }

  Future<void> _open([CustomAccountType? type]) async {
    await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) =>
            AccountTypeScreen(accounts: widget.accounts, type: type),
      ),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final custom = _custom;
    if (custom == null) return const Scaffold(body: SizedBox.shrink());
    final labels = AccountTypeLabels(l, custom);
    Widget tile(IconData icon) => Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: KibuoColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 18, color: KibuoColors.inkSecondary),
    );
    return Scaffold(
      appBar: AppBar(title: Text(l.typesTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          const SizedBox(height: GroupTitle.before),
          GroupTitle(title: l.typesProvided),
          SettingsCard(
            children: [
              for (final t in AccountType.provided)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      tile(labels.icon(t)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(labels.name(t), style: KibuoType.rowLabel),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          HelpText(l.typesProvidedHelp),
          if (custom.isNotEmpty) ...[
            const SizedBox(height: GroupTitle.before),
            GroupTitle(title: l.typesYours, count: '${custom.length}'),
            SettingsCard(
              children: [
                for (final t in custom)
                  IconRow(
                    icon: customTypeIcons[t.icon] ?? KibuoIcons.wallet,
                    tint: KibuoColors.background,
                    iconColor: KibuoColors.inkSecondary,
                    label: t.name,
                    onTap: () => _open(t),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          KibuoButton(
            label: l.accountTypeCreate,
            kind: ButtonKind.create,
            icon: KibuoIcons.plusBold,
            onPressed: _open,
          ),
        ],
      ),
    );
  }
}

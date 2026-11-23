import 'package:flutter/widgets.dart';
import 'package:kibuo/ui/kit/cards.dart';
import 'package:kibuo/ui/kit/sheet.dart';

/// A sheet of [options], the [selected] one checked; touching one closes
/// the sheet with its value (Délai, Rappel).
Future<T?> showChoiceSheet<T>(
  BuildContext context, {
  required String title,
  required List<(T, String)> options,
  T? selected,
}) => showKibuoSheet<T>(
  context,
  title: title,
  builder: (context) => SettingsCard(
    children: [
      for (final (value, label) in options)
        CheckChoice(
          label: label,
          help: '',
          on: value == selected,
          onTap: () => Navigator.of(context).pop(value),
        ),
    ],
  ),
);

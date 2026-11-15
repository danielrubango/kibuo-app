/// The recovery code (GLOSSARY: Code de récupération): 16 characters,
/// shown in 4 groups of 4. Its alphabet leaves out 0, 1, I and O, which are
/// easy to confuse when written by hand: 32 signs, so 80 bits of chance.
library;

import 'dart:math';

const recoveryAlphabet = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';
const recoveryLength = 16;

/// A new code, drawn with [random] (use `Random.secure()` in the app).
String newRecoveryCode(Random random) => List.generate(
  recoveryLength,
  (_) => recoveryAlphabet[random.nextInt(recoveryAlphabet.length)],
).join();

/// « KB7Q-4M2X-9TPA-H3WD ».
String formatRecoveryCode(String code) => recoveryGroups(code).join('-');

List<String> recoveryGroups(String code) => [
  for (var i = 0; i < code.length; i += 4)
    code.substring(i, min(i + 4, code.length)),
];

/// What the user typed, without dashes, spaces or lowercase.
String normalizeRecoveryCode(String typed) =>
    typed.toUpperCase().replaceAll(RegExp('[^A-Z0-9]'), '');

final _code = RegExp('^[$recoveryAlphabet]{$recoveryLength}\$');

bool isRecoveryCode(String code) => _code.hasMatch(code);

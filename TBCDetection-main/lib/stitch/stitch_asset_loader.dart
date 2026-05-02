import 'package:flutter/services.dart';

Future<bool> stitchAssetExists(String assetPath) async {
  try {
    await rootBundle.load(assetPath);
    return true;
  } catch (_) {
    return false;
  }
}

/// Coba beberapa ekstensi (mis. hasil unduhan .jpg vs .png).
Future<String?> stitchFirstExistingAsset(List<String> paths) async {
  for (final p in paths) {
    if (await stitchAssetExists(p)) return p;
  }
  return null;
}

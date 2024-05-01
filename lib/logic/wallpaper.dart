import 'dart:io';
import 'package:flutter/painting.dart';

DecorationImage getWallpaper({
  required String? path,
  required ImageProvider<Object> fallback,
}) {
  if (path != null) {
    return DecorationImage(
      image: FileImage(File(path!)),
      fit: BoxFit.cover,
    );
  }

  return DecorationImage(
    image: fallback,
    fit: BoxFit.cover,
  );
}

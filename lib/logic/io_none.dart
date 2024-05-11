import 'dart:async';
import 'package:flutter_svg/src/utilities/_file_none.dart' as io;

class File extends io.File {
  File(this._path);

  String _path;

  @override
  String get path => _path;

  @override
  Future<Uint8List> readAsBytes() =>
    Future.value(readAsBytesSync());

  @override
  Uint8List readAsBytesSync() {
    throw new Exception('Unimplemented method: readAsBytesSync');
  }
}

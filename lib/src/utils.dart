import 'dart:io';

import 'package:meta/meta.dart';

@internal
extension HttpHeadersExt on HttpHeaders {
  String dump() {
    final buffer = StringBuffer();
    forEach((name, values) {
      buffer
        ..write('$name: ')
        ..writeln(values.join(', '));
    });
    return buffer.toString();
  }

  List<String>? get locationHeader => this['location'];
}

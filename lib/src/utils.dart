import 'dart:io';

import 'package:meta/meta.dart';

@internal
extension HttpHeadersExt on HttpHeaders {
  String dump({bool fold = false}) {
    final buffer = StringBuffer();
    final output = <MapEntry<String, String>>[];
    forEach((name, values) {
      if (fold) {
        values.forEach((value) => output.add(MapEntry(name, value)));
      } else {
        output.add(MapEntry(name, values.join(', ')));
      }
    });
    output
      ..sort(((a, b) => a.key.compareTo(b.key)))
      ..forEach((entry) => buffer.writeln('${entry.key}: ${entry.value}'));
    return buffer.toString();
  }

  List<String>? get locationHeader => this['location'];
}

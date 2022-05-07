import 'dart:io';

import 'package:meta/meta.dart';

@internal
class Body {
  const Body(this.string, this.contentType);
  final String string;
  final ContentType contentType;
}

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
}

@internal
String encodeFormFields(Map<String, String> formFields) =>
    Uri(queryParameters: formFields).query;

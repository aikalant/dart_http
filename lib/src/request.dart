import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:meta/meta.dart';

import 'client.dart';
import 'interface.dart';
import 'response.dart';
import 'utils.dart';

@internal
class RequestBase extends Request {
  RequestBase(
    this.clientBase,
    this.request,
    this.redirectsList,
    Map<String, Object>? headers,
    this._body,
    this.tag,
  ) {
    headers?.forEach((name, value) => request.headers.add(name, value));
    request.followRedirects = false;
  }

  final ClientBase clientBase;
  final HttpClientRequest request;
  final List<ResponseBase> redirectsList;
  @override
  dynamic tag;
  Object? _body;
  ResponseBase? _response;
  bool _sending = false;
  bool _locked = false;

  @override
  Client get client => clientBase;

  @override
  List<Response> get redirects => List.unmodifiable(redirectsList);

  @override
  String get method => request.method;

  @override
  Uri get url => request.uri;

  @override
  List<Cookie> get cookies => request.cookies;

  @override
  HttpHeaders get headers => request.headers;

  @override
  Object? get body => _body;
  @override
  set body(Object? body) => _locked
      ? throw Exception('cannot modify body after request has been sent')
      : _body = body;

  @override
  Response? get reponse => _response;

  /// if either `autoRedirect` is true, or `autoRedirect` is null and client's
  /// `autoRedirect` field is true, then returned response will continue
  /// redirects until a non-redirect response is sent.
  @override
  Future<Response> send({bool? autoRedirect}) async {
    if (_sending) throw Exception('cannot re-send a request');
    _sending = true;

    if (clientBase.sendHooks != null) {
      for (final hook in [...clientBase.sendHooks!]) {
        await hook(this);
      }
    }

    _locked = true;
    if (_body != null) _addBody(_body!);

    final response = _response = ResponseBase(this, await request.close());

    if (client.preReadBody) await response.readBody();

    if (clientBase.sendHooks != null) {
      for (final hook in [...clientBase.sendHooks!]) {
        await hook(this);
      }
    }

    if (response.canRedirect & (autoRedirect ?? client.autoRedirect)) {
      return response.redirect(autoRedirect: true);
    }
    return response;
  }

  @override
  void abort([Object? exception, StackTrace? stackTrace]) {
    _sending = _locked = true;
    request.abort(exception, stackTrace);
  }

  void _addBody(Object body) {
    final List<int> bytes;
    final ContentType? contentType;
    if (body is List<int>) {
      bytes = body;
      contentType = null;
    } else {
      final String bodyString;
      if (body is String) {
        bodyString = body;
        contentType = ContentType.text;
      } else if (body is Map<String, String>) {
        bodyString = _encodeFormFields(body);
        contentType = ContentType.parse('application/x-www-form-urlencoded');
      } else {
        throw Exception('Invalid body type [${body.runtimeType}]');
      }
      bytes = utf8.encode(bodyString);
    }
    request
      ..headers.contentType = contentType
      ..contentLength = bytes.length
      ..add(bytes);
  }

  @override
  List<int>? get bodyBytes {
    if (_body is List<int>) return _body! as List<int>;
    if (_body is String) return utf8.encode(_body! as String);
    if (_body is Map<String, String>) {
      return utf8.encode(_encodeFormFields(_body! as Map<String, String>));
    }
    return null;
  }

  @override
  String? get bodyString {
    if (_body is List<int>) return utf8.decode(_body! as List<int>);
    if (_body is String) return _body! as String;
    if (_body is Map<String, String>) {
      return _encodeFormFields(_body! as Map<String, String>);
    }
    return null;
  }

  static String _encodeFormFields(Map<String, String> formFields) =>
      Uri(queryParameters: formFields).query;

  @override
  String dump() {
    final buffer = StringBuffer()
      ..writeln(
        '${method.toUpperCase()} '
        '${url.path.isEmpty ? '/' : url.path}?${url.query} HTTP/1.1',
      )
      ..writeln('Host: ${url.host}');
    if (client.userAgent != null) {
      buffer.writeln('User-Agent: ${client.userAgent}');
    }
    buffer.write(request.headers.dump());
    return buffer.toString();
  }
}

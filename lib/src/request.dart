import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'client.dart';
import 'interface.dart';
import 'response.dart';

class RequestBase extends Request {
  RequestBase(
    this.clientBase,
    this.request,
    List<ResponseBase>? redirects,
    Map<String, Object>? headers,
    this._body,
    this.autoRedirect,
  ) : redirectsList = redirects == null ? null : List.unmodifiable(redirects) {
    headers?.forEach((name, value) => request.headers.add(name, value));
    request.followRedirects = false;
  }

  final ClientBase clientBase;
  final HttpClientRequest request;
  final List<ResponseBase>? redirectsList;
  Object? _body;
  bool? autoRedirect;
  ResponseBase? _response;
  bool _sending = false;
  bool _locked = false;

  @override
  Client get client => clientBase;

  @override
  UnmodifiableListView<Response>? get redirects => redirectsList == null
      ? null
      : UnmodifiableListView(redirectsList!.cast());

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
    if (_body != null) _encodeBody();

    final response = _response = ResponseBase(this, await request.close());

    if (clientBase.sendHooks != null) {
      for (final hook in [...clientBase.sendHooks!]) {
        await hook(this);
      }
    }

    if (response.canRedirect &&
        (await clientBase.shouldRedirect?.call(response) ??
            autoRedirect ??
            this.autoRedirect ??
            clientBase.autoRedirect)) {
      return response.redirect(autoRedirect: true);
    }
    return response;
  }

  void _encodeBody() {
    final body = _body;
    final List<int> bytes;
    if (body is List<int>) {
      bytes = body;
    } else if (body is String) {
      bytes = utf8.encode(body);
      request.headers.contentType = ContentType.text;
    } else if (body is Map<String, String>) {
      bytes = utf8.encode(Uri(queryParameters: body).query);
      request.headers.contentType =
          ContentType.parse('application/x-www-form-urlencoded');
    } else {
      throw Exception('Cannot encode body of type [${body.runtimeType}]');
    }

    request
      ..contentLength = bytes.length
      ..add(bytes);
  }
}

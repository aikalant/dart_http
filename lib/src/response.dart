import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'interface.dart';
import 'request.dart';

class ResponseBase extends Response {
  ResponseBase(this._request, this.response);

  final RequestBase _request;
  final HttpClientResponse response;
  List<int>? _bodyBytes;
  String? _bodyString;

  @override
  int get statusCode => response.statusCode;

  @override
  String get reasonPhrase => response.reasonPhrase;

  @override
  Request get request => _request;

  @override
  HttpHeaders get headers => response.headers;

  @override
  List<Cookie> get cookies => response.cookies;

  @override
  Future<List<int>> get bodyBytes async => _bodyBytes ??=
      _bodyString != null ? utf8.encode(_bodyString!) : await _readBodyBytes();

  @override
  Future<String> get bodyString async => _bodyString ??=
      _bodyBytes != null ? utf8.decode(_bodyBytes!) : await _readBodyString();

  Future<List<int>> _readBodyBytes() {
    final completer = Completer<List<int>>();
    final buffer = <int>[];
    response.listen(
      buffer.addAll,
      onDone: () => completer.complete(buffer),
    );
    return completer.future;
  }

  Future<String> _readBodyString() {
    final completer = Completer<String>();
    final buffer = StringBuffer();
    response.transform(utf8.decoder).listen(
          buffer.write,
          onDone: () => completer.complete(buffer.toString()),
        );
    return completer.future;
  }

  @override
  bool get canRedirect {
    switch (statusCode) {
      case HttpStatus.movedPermanently:
      case HttpStatus.permanentRedirect:
      case HttpStatus.found:
      case HttpStatus.seeOther:
      case HttpStatus.temporaryRedirect:
      case HttpStatus.multipleChoices:
      case HttpStatus.notModified:
        return true;
      default:
        return false;
    }
  }

  @override
  Future<Response> redirect({bool? autoRedirect}) async {
    switch (statusCode) {
      case HttpStatus.movedPermanently:
      case HttpStatus.permanentRedirect:
      case HttpStatus.found:
      case HttpStatus.seeOther:
      case HttpStatus.temporaryRedirect:
        final redirectRequest = RequestBase(
          _request.clientBase,
          await _request.clientBase.client.openUrl(
            request.method,
            Uri.parse(headers['location']!.first),
          ),
          [..._request.redirectsList ?? [], this],
          null, // headers
          null, // body
          autoRedirect, //not used
        );
        return redirectRequest.send();
      case HttpStatus.multipleChoices:
      case HttpStatus.notModified:
        throw UnimplementedError();
      default:
        throw Exception('unable to redirect $statusCode $reasonPhrase');
    }
  }
}

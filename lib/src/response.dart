import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:meta/meta.dart';

import 'interface.dart';
import 'request.dart';
import 'utils.dart';

@internal
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
  List<int> get body => _bodyBytes ??=
      throw Exception('Body has not been read yet. Call "readBody" first.');

  @override
  String get bodyString => _bodyString ??= utf8.decode(body);

  @override
  Future<List<int>> readBody() {
    if (_bodyBytes != null) return Future.value(_bodyBytes);
    final completer = Completer<List<int>>();
    final buffer = <int>[];
    response.listen(
      buffer.addAll,
      onDone: () => completer.complete(buffer),
    );
    return completer.future.then((body) => _bodyBytes = body);
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

  /// if either `autoRedirect` is true, or `autoRedirect` is null and client's
  /// `autoRedirect` field is true, then returned response will continue
  /// redirects until a non-redirect response is sent.
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
            Uri.parse(headers.locationHeader!.first),
          ),
          [..._request.redirectsList, this],
          null, // headers
          null, // body
        );
        return redirectRequest.send(autoRedirect: autoRedirect);
      case HttpStatus.multipleChoices:
      case HttpStatus.notModified:
        throw UnimplementedError();
      default:
        throw Exception('unable to redirect $statusCode $reasonPhrase');
    }
  }

  @override
  String dump() {
    final buffer = StringBuffer()
      ..writeln('HTTP/1.1 $statusCode $reasonPhrase')
      ..write(response.headers.dump());
    return buffer.toString();
  }
}

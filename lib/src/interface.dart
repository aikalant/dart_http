import 'dart:collection';
import 'dart:io';

import 'package:meta/meta.dart';

import 'client.dart';

typedef SendHook = Future<void> Function(Request);
typedef ReceiveHook = Future<void> Function(Response);
typedef ShouldRedirect = Future<bool?>? Function(Response);

@sealed
abstract class Client {
  factory Client({
    bool autoRedirect = true,
    ShouldRedirect? shouldRedirect,
    List<SendHook>? sendHooks,
    List<ReceiveHook>? receiveHooks,
  }) =>
      ClientBase(autoRedirect, shouldRedirect, sendHooks, receiveHooks);

  @internal
  Client.create();

  bool get autoRedirect;

  ShouldRedirect? get shouldRedirect;

  void addSendHook(SendHook sendHook);
  void removeSendHook(SendHook sendHook);

  void addReceiveHook(ReceiveHook receiveHook);
  void removeReceiveHook(ReceiveHook receiveHook);

  Future<Request> open(
    String method,
    Uri url, {
    Map<String, Object>? headers,
    Object? body,
    bool? autoRedirect,
  });

  Future<Response> send(
    String method,
    Uri url, {
    Map<String, Object>? headers,
    Object? body,
    bool? autoRedirect,
  }) =>
      open(
        method,
        url,
        headers: headers,
        body: body,
        autoRedirect: null,
      ).then((request) => request.send(autoRedirect: autoRedirect));
}

abstract class Request {
  Client get client;
  Response? get reponse;
  UnmodifiableListView<Response>? redirects;
  String get method;
  Uri get url;
  HttpHeaders get headers;
  List<Cookie> get cookies;
  Object? body;

  Future<Response> send({bool? autoRedirect});
}

abstract class Response {
  @nonVirtual
  Client get client => request.client;
  Request get request;
  int get statusCode;
  String get reasonPhrase;
  @nonVirtual
  Uri get initialUrl => request.redirects?.first.request.url ?? request.url;
  HttpHeaders get headers;
  List<Cookie> get cookies;
  Future<List<int>> get bodyBytes;
  Future<String> get bodyString;

  bool get canRedirect;
  Future<Response> redirect({bool? autoRedirect});
}

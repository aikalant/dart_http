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
  String? userAgent;

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
      ).then((request) => request.send(autoRedirect: autoRedirect));

  void close({bool force = false});
}

abstract class Request {
  Client get client;
  Response? get reponse;
  List<Response> get redirects;
  String get method;
  Uri get url;
  HttpHeaders get headers;
  List<Cookie> get cookies;
  Object? body;
  List<int>? get bodyBytes;
  String? get bodyString;

  Future<Response> send({bool? autoRedirect});
  void abort([Object? exception, StackTrace? stackTrace]);

  String dump();
}

abstract class Response {
  @nonVirtual
  Client get client => request.client;
  Request get request;
  int get statusCode;
  String get reasonPhrase;
  @nonVirtual
  Uri get initialUrl => request.redirects.isNotEmpty
      ? request.redirects.first.request.url
      : request.url;
  HttpHeaders get headers;
  List<Cookie> get cookies;
  Future<List<int>> readBody();
  List<int> get body;
  String get bodyString;

  bool get canRedirect;
  Future<Response> redirect({bool? autoRedirect});

  String dump();
}

import 'dart:io';

import 'package:meta/meta.dart';

import 'client.dart';

typedef SendHook = Future<void> Function(Request);
typedef ReceiveHook = Future<void> Function(Response);

@sealed
abstract class Client {
  factory Client({
    bool autoRedirect = true,
    bool preReadBody = true,
    List<SendHook>? sendHooks,
    List<ReceiveHook>? receiveHooks,
  }) =>
      ClientBase(
        autoRedirect,
        preReadBody,
        sendHooks,
        receiveHooks,
      );

  @internal
  Client.create();

  bool get autoRedirect;
  bool get preReadBody;
  String? userAgent;

  void addSendHook(SendHook sendHook);
  void removeSendHook(SendHook sendHook);

  void addReceiveHook(ReceiveHook receiveHook);
  void removeReceiveHook(ReceiveHook receiveHook);

  Future<Request> open(
    String method,
    Uri url, {
    Map<String, Object>? headers,
    Object? body,
    dynamic tag,
  });

  Future<Response> send(
    String method,
    Uri url, {
    Map<String, Object>? headers,
    Object? body,
    bool? autoRedirect,
    dynamic tag,
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
  dynamic get tag;

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

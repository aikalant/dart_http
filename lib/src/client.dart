import 'dart:io';

import 'package:meta/meta.dart';

import 'interface.dart';
import 'request.dart';

@internal
class ClientBase extends Client {
  ClientBase(
    this.autoRedirect,
    this.preReadBody,
    this.sendHooks,
    this.receiveHooks,
  )   : client = HttpClient(),
        super.create();

  final HttpClient client;
  @override
  bool autoRedirect;
  @override
  bool preReadBody;
  List<SendHook>? sendHooks;
  List<ReceiveHook>? receiveHooks;

  @override
  set userAgent(String? userAgent) => client.userAgent = userAgent;
  @override
  String? get userAgent => client.userAgent;

  @override
  void addSendHook(SendHook sendHook) => (sendHooks ??= []).add(sendHook);
  @override
  void removeSendHook(SendHook sendHook) => sendHooks?.remove(sendHook);

  @override
  void addReceiveHook(ReceiveHook receiveHook) =>
      (receiveHooks ??= []).add(receiveHook);
  @override
  void removeReceiveHook(ReceiveHook receiveHook) =>
      receiveHooks?.remove(receiveHook);

  @override
  Future<Request> open(
    String method,
    Uri url, {
    Map<String, Object>? headers,
    Object? body,
    bool? autoRedirect,
    dynamic tag,
  }) async =>
      RequestBase(
        this,
        await client.openUrl(method, url),
        const [],
        headers,
        body,
        tag,
      );

  @override
  void close({bool force = false}) => client.close(force: force);
}

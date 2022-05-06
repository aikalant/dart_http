import 'dart:io';

import 'package:meta/meta.dart';

import 'interface.dart';
import 'request.dart';

@internal
class ClientBase extends Client {
  ClientBase(
    this.autoRedirect,
    this.shouldRedirect,
    this.sendHooks,
    this.receiveHooks,
  )   : client = HttpClient(),
        super.create();

  final HttpClient client;
  @override
  bool autoRedirect;
  @override
  ShouldRedirect? shouldRedirect;
  late final List<SendHook>? sendHooks;
  late final List<ReceiveHook>? receiveHooks;

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
  }) async =>
      RequestBase(
        this,
        await client.openUrl(method, url),
        null,
        headers,
        body,
        autoRedirect,
      );
}

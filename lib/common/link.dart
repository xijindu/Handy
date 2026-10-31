import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

import 'print.dart';
import 'protocol.dart';
import 'string.dart';

String? profileUrlFromQrCodes(Iterable<String?> values) {
  for (final value in values) {
    final text = value?.trim();
    if (text == null || text.isEmpty) {
      continue;
    }
    if (text.isUrl || text.isShareLink) {
      return text;
    }
    final uri = Uri.tryParse(text);
    if (uri == null || !protocolSchemes.contains(uri.scheme)) {
      continue;
    }
    final url = _installConfigUrl(uri);
    if (url != null && url.isUrl) {
      return url;
    }
  }
  return null;
}

String? _installConfigUrl(Uri uri) {
  if (uri.host != 'install-config') {
    return null;
  }
  final url = uri.queryParameters['url']?.trim();
  return url == null || url.isEmpty ? null : url;
}

class LinkManager {
  static LinkManager? _instance;
  StreamSubscription? subscription;

  LinkManager._internal();

  @visibleForTesting
  Stream<Uri> Function() uriLinkStream = () => AppLinks().uriLinkStream;

  Future<void> initAppLinksListen(
    Function(String url) installConfigCallBack,
  ) async {
    destroy();
    subscription = uriLinkStream().listen((uri) {
      _handle(uri, installConfigCallBack);
    });
  }

  void _handle(Uri uri, Function(String url) installConfigCallBack) {
    commonPrint.log('onAppLink: $uri');
    final url = _installConfigUrl(uri);
    if (url != null) {
      installConfigCallBack(url);
    }
  }

  void destroy() {
    if (subscription != null) {
      subscription?.cancel();
      subscription = null;
    }
  }

  factory LinkManager() {
    _instance ??= LinkManager._internal();
    return _instance!;
  }
}

final linkManager = LinkManager();

import 'dart:io';

import 'proxy_platform_interface.dart';
import 'src/macos_proxy.dart';
import 'src/proxy_command.dart';
import 'src/windows_proxy.dart';

export 'src/proxy_command.dart' show ProxyProcessRunner;

class Proxy {
  static const int _minPort = 1;
  static const int _maxPort = 65535;

  late final MacosProxy _macosProxy;

  Proxy({ProxyProcessRunner? processRunner}) {
    final commandRunner = ProxyCommandRunner(processRunner ?? Process.run);
    _macosProxy = MacosProxy(commandRunner: commandRunner);
  }

  Future<bool> startProxy(
    int port, [
    List<String> bypassDomain = const [],
  ]) async {
    if (port < _minPort || port > _maxPort) {
      return false;
    }
    return switch (Platform.operatingSystem) {
      'macos' => await _macosProxy.start(port, bypassDomain),
      'windows' => await ProxyPlatform.instance.startProxy(
        port,
        windowsBypassList(bypassDomain),
      ),
      String() => false,
    };
  }

  Future<bool> stopProxy() async {
    return switch (Platform.operatingSystem) {
      'macos' => await _macosProxy.stop(),
      'windows' => await ProxyPlatform.instance.stopProxy(),
      String() => false,
    };
  }
}

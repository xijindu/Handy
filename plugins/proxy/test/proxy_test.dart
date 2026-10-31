import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proxy/proxy.dart';
import 'package:proxy/proxy_method_channel.dart';
import 'package:proxy/src/macos_proxy.dart';
import 'package:proxy/src/proxy_command.dart';
import 'package:proxy/src/windows_proxy.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Proxy', () {
    test('rejects ports outside the TCP port range', () async {
      final proxy = Proxy(
        processRunner: (executable, arguments, {runInShell = false}) async {
          fail('invalid ports must not execute platform commands');
        },
      );

      expect(await proxy.startProxy(0), isFalse);
      expect(await proxy.startProxy(65536), isFalse);
    });
  });

  group('ProxyCommandRunner', () {
    test('treats an empty command set as failure', () async {
      final runner = ProxyCommandRunner((
        executable,
        arguments, {
        runInShell = false,
      }) async {
        fail('empty command sets must not start a process');
      });

      expect(await runner.run(const []), isFalse);
    });

    test('stops after the first failed command', () async {
      var callCount = 0;
      final runner = ProxyCommandRunner((
        executable,
        arguments, {
        runInShell = false,
      }) async {
        callCount++;
        return ProcessResult(callCount, callCount == 1 ? 1 : 0, '', '');
      });

      final result = await runner.run([
        ProxyCommand('first', const []),
        ProxyCommand('second', const []),
      ]);

      expect(result, isFalse);
      expect(callCount, 1);
    });

    test('converts process launch failures to false', () async {
      final runner = ProxyCommandRunner((
        executable,
        arguments, {
        runInShell = false,
      }) async {
        throw ProcessException(executable, arguments);
      });

      expect(await runner.run([ProxyCommand('missing', const [])]), isFalse);
    });

    test('carries on past an optional command that fails', () async {
      final started = <String>[];
      final runner = ProxyCommandRunner((
        executable,
        arguments, {
        runInShell = false,
      }) async {
        started.add(executable);
        if (executable == 'missing') {
          throw ProcessException(executable, arguments);
        }
        return ProcessResult(0, executable == 'refused' ? 1 : 0, '', '');
      });

      final result = await runner.run([
        ProxyCommand('missing', const [], optional: true),
        ProxyCommand('refused', const [], optional: true),
        ProxyCommand('last', const []),
      ]);

      expect(result, isTrue);
      expect(started, ['missing', 'refused', 'last']);
    });
  });

  group('macOS proxy command builders', () {
    test(
      'filters networksetup service list headers, disabled services, and blanks',
      () {
        final services = MacosProxyCommands.parseNetworkServices('''
An asterisk (*) denotes that a network service is disabled.
Wi-Fi
*Thunderbolt Bridge
USB 10/100/1000 LAN

''');

        expect(services, ['Wi-Fi', 'USB 10/100/1000 LAN']);
      },
    );

    test('passes bypass domains as separate networksetup arguments', () {
      final command = MacosProxyCommands.buildProxyBypass('Wi-Fi', [
        'localhost',
        '127.0.0.1',
      ]);

      expect(command.executable, '/usr/sbin/networksetup');
      expect(command.args, [
        '-setproxybypassdomains',
        'Wi-Fi',
        'localhost',
        '127.0.0.1',
      ]);
    });

    test('uses Empty when clearing bypass domains', () {
      final command = MacosProxyCommands.buildProxyBypass('Wi-Fi', const []);

      expect(command.args, ['-setproxybypassdomains', 'Wi-Fi', 'Empty']);
    });

    test('configures values before enabling proxy states', () {
      final commands = MacosProxyCommands.buildStart('Wi-Fi', 7890, const [
        'localhost',
      ]);

      final firstStateCommand = commands.indexWhere(
        (command) => command.args.first.endsWith('proxystate'),
      );

      expect(firstStateCommand, 4);
      expect(commands[3].args.first, '-setproxybypassdomains');
    });

    test('reports failure when no active network service is found', () async {
      var callCount = 0;
      final proxy = MacosProxy(
        commandRunner: ProxyCommandRunner((
          executable,
          arguments, {
          runInShell = false,
        }) async {
          callCount++;
          return ProcessResult(
            callCount,
            0,
            'An asterisk (*) denotes that a network service is disabled.\n',
            '',
          );
        }),
      );

      expect(await proxy.start(7890, const []), isFalse);
      expect(callCount, 1);
    });
  });

  group('windowsBypassList', () {
    test('adds the intranet token once', () {
      expect(windowsBypassList(['localhost', '127.*', '<local>']), [
        'localhost',
        '127.*',
        '<local>',
      ]);
      expect(windowsBypassList(['localhost']), ['localhost', '<local>']);
    });

    test('brackets bare IPv6 literals and drops blank entries', () {
      expect(
        windowsBypassList([' ::1 ', 'fe80::1', '', '[fd00::1]', '*.lan']),
        ['[::1]', '[fe80::1]', '[fd00::1]', '*.lan', '<local>'],
      );
    });

    test('drops trailing slashes that fail the whole list', () {
      expect(
        windowsBypassList(['example.test/', 'example.test', 'nas//', '/']),
        ['example.test', 'nas', '<local>'],
      );
    });
  });

  group('MethodChannelProxy', () {
    final proxy = MethodChannelProxy();

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(proxy.methodChannel, null);
    });

    test('sends the Windows start contract', () async {
      MethodCall? capturedCall;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(proxy.methodChannel, (call) async {
            capturedCall = call;
            return true;
          });

      final result = await proxy.startProxy(7890, const ['localhost']);

      expect(result, isTrue);
      expect(capturedCall?.method, 'StartProxy');
      expect(capturedCall?.arguments, {
        'port': 7890,
        'bypassDomain': ['localhost'],
      });
    });

    test('maps a null native response to false', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(proxy.methodChannel, (_) async => null);

      expect(await proxy.stopProxy(), isFalse);
    });
  });
}

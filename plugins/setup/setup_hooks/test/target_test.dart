import 'package:setup_hooks/src/error.dart';
import 'package:setup_hooks/src/target.dart';
import 'package:test/test.dart';

void main() {
  group('resolve', () {
    test('finds the target for a platform and GOARCH', () {
      expect(
        Target.resolve(platform: 'windows', goarch: 'amd64'),
        Target.windowsAmd64,
      );
      expect(
        Target.resolve(platform: 'macos', goarch: 'arm64'),
        Target.macosArm64,
      );
      expect(
        Target.resolve(platform: 'windows', goarch: 'arm64'),
        Target.windowsArm64,
      );
    });

    test('rejects a GOARCH or platform without a Core', () {
      expect(
        () => Target.resolve(platform: 'windows', goarch: 'riscv64'),
        throwsA(isA<BuildException>()),
      );
      expect(
        () => Target.resolve(platform: 'ios', goarch: 'arm64'),
        throwsA(isA<BuildException>()),
      );
    });
  });

  test('only Windows ships the Helper', () {
    expect(Target.all.where((target) => target.hasHelper), [
      Target.windowsAmd64,
      Target.windowsArm64,
    ]);
  });

  test('names the Rust target triple for Helper platforms', () {
    expect(Target.windowsAmd64.rustTriple, 'x86_64-pc-windows-msvc');
    expect(() => Target.macosArm64.rustTriple, throwsA(isA<BuildException>()));
  });
}

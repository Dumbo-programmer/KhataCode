import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:khatacode/app_info.dart';

void main() {
  test('app info matches the package version and developers', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final version = RegExp(r'^version:\s*([^\s]+)', multiLine: true)
        .firstMatch(pubspec)!
        .group(1)!;
    expect(version.split('+').first.split('.').take(2).join('.'), appVersion);
    expect(developers, ['Tawhid Bin Omar', 'Intesher Alam Manam']);
  });
}

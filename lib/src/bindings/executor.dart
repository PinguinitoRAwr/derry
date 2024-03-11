import 'dart:ffi' as ffi;
import 'dart:io';
import 'dart:isolate' show Isolate;

import 'package:derry/src/bindings/get_object.dart';
import 'package:ffi/ffi.dart' show StringUtf8Pointer, Utf8;
import 'package:io/ansi.dart';

// ignore: avoid_private_typedef_functions
typedef _Executor = int Function(ffi.Pointer<Utf8>);
// ignore: avoid_private_typedef_functions
typedef _ExecutorFn = ffi.Int32 Function(ffi.Pointer<Utf8>);

/// Executes a given program and list of arguments, using `dart:io`.
///
/// Might not work because of how `derry` parses arguments (e.g. malfunctions
/// when you have unusual space placements). The advantage is that the program
/// inherits all of your current shell environment. If this doesn't work, use
/// [executor3].
Future<int> executor2(List<String> args) {
  stdout.writeln('\$ ${styleDim.wrap(args.join(' '))} \n');

  return Process.start(
    args[0],
    args.sublist(1),
    mode: ProcessStartMode.inheritStdio,
  ).then((process) => process.exitCode);
}

/// Executes a given input string in console using `dart:io`.
///
/// Runs inside `cmd` on Windows, `bash` on Linux & MacOS. Note that this
/// doesn't inherit your current shell environment. For that purpose, it's
/// recommended to use the more unstable [executor2].
Future<int> executor3(String command) {
  stdout.writeln('\$ ${styleDim.wrap(command)} \n');
  return Process.start(
    Platform.isWindows ? 'cmd' : 'bash',
    [if (Platform.isWindows) '/C' else '-c', command],
    mode: ProcessStartMode.inheritStdio,
  ).then((process) => process.exitCode);
}

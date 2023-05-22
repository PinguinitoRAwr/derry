import 'dart:io';

import 'package:console/console.dart';
import 'package:derry/error.dart';
import 'package:derry/helpers.dart';
import 'package:derry/models.dart';
import 'package:derry/src/bindings/executor.dart';
import 'package:yaml/yaml.dart';

/// The function to execute scripts from ffi, which
/// takes a [YamlMap] of definitions, an argument to parse and execute,
/// an extra bit of command which will be passed down to the script,
/// a `boolean` value to decide whether to print output
/// or not, and a [String] to print before executing the script.
int execute(
  Map definitions,
  String arg, {
  String extra = '',
  String? infoLine,
}) {
  final searchResult = search(definitions, arg);

  /// for incomplete calls for nested scripts
  if (searchResult is YamlMap && !searchResult.value.containsKey('(scripts)')) {
    throw DerryError(
      type: ErrorType.snf,
      body: {
        'script': arg,
        'definitions': makeKeys(definitions),
      },
    );
  }

  final definition = parseDefinition(searchResult);

  Console.init();
  Console.setBold(true);
  if (infoLine != null) stdout.writeln(infoLine);
  Console.setBold(false);

  List<String> executables = <String>[];

  final bool once = definition.execution == 'once';

  executables.addAll(getPreCommand(definitions, arg, once: once));

  for (final script in definition.scripts!) {
    final sub = subcommand(script);
    if (sub['command']!.isNotEmpty) {
      executables.addAll(getSubCommand(
        definitions,
        sub['command']!,
        extra: [sub['extra'], extra].map((x) => x!.trim()).join(' '),
        once: once,
        throwOnError: true,
      ));
    } else {
      // replace all \$ with $, they are not subcommands
      final unparsed = script.replaceAll('\\\$', '\$');
      executables.add('$unparsed $extra');
    }
  }
  executables.addAll(getPostCommand(definitions, arg, once: once));
  int exitCode = 0;
  if (once) {
    return executor3(executables.join(' && '));
  } else {
    for (final String executable in executables) {
      exitCode = executor3(executable);
    }
  }

  return exitCode;
}

List<String> getSubCommand(
  Map definitions,
  String arg, {
  String? extra = '',
  bool once = false,
  bool throwOnError = false,
}) {
  try {
    search(definitions, arg);

    return _getSubCommand(
      definitions,
      arg,
      once: once,
      throwOnError: throwOnError,
    );
  } on DerryError catch (_) {
    if (throwOnError) {
      rethrow;
    }
  }

  return [];
}

List<String> getPreCommand(
  Map definitions,
  String arg, {
  bool once = false,
}) {
  return _getPrefixedCommand(definitions, arg);
}

List<String> getPostCommand(
  Map definitions,
  String arg, {
  bool once = false,
}) {
  return _getPrefixedCommand(definitions, arg, prefix: 'post');
}

List<String> _getPrefixedCommand(
  Map definitions,
  String arg, {
  String prefix = 'pre',
  bool once = false,
}) {
  String name = '$prefix$arg';

  try {
    search(definitions, name);

    return _getSubCommand(definitions, name, once: once);
  } on DerryError catch (_) {
    // ignore
  }
  if (name.contains(' ')) {
    name = name.split(' ').first;
    try {
      search(definitions, name);

      return _getSubCommand(definitions, name, once: once);
    } on DerryError catch (_) {
      // ignore
    }
  }
  if (name.contains(':')) {
    name = name.split(':').first;
    try {
      search(definitions, name);

      return _getSubCommand(definitions, name, once: once);
    } on DerryError catch (_) {
      // ignore
    }
  }

  return [];
}

List<String> _getSubCommand(
  Map definitions,
  String arg, {
  String extra = '',
  bool once = false,
  bool throwOnError = false,
}) {
  final searchResult = search(definitions, arg);

  /// for incomplete calls for nested scripts
  if (searchResult is YamlMap && !searchResult.value.containsKey('(scripts)')) {
    throw DerryError(
      type: ErrorType.snf,
      body: {
        'script': arg,
        'definitions': makeKeys(definitions),
      },
    );
  }

  final definition = parseDefinition(searchResult);

  switch (definition.execution) {
    case 'once':
    case 'multiple':
      final scriptLines = <String>[];
      scriptLines.addAll(getPreCommand(definitions, arg, once: once));
      for (final script in definition.scripts!) {
        final sub = subcommand(script);
        if (sub['command']!.isNotEmpty) {
          scriptLines.addAll(getSubCommand(
            definitions,
            sub['command']!,
            extra: sub['extra'],
            once: once,
            throwOnError: true,
          ));
        } else {
          // replace all \$ with $ but are not subcommands
          final unparsed = script.replaceAll('\\\$', '\$');
          scriptLines.add('$unparsed $extra');
        }
      }
      scriptLines.addAll(getPostCommand(definitions, arg, once: once));
      if (once || definition.execution == 'once') {
        return [scriptLines.join(' && ')];
      }

      return scriptLines;
    default:
      throw 'Incorrect execution type ${definition.execution}.';
  }
}

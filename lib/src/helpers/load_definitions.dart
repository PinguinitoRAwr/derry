import 'package:derry/error.dart';
import 'package:derry/helpers.dart';
import 'package:derry/models.dart';
import 'package:yaml/yaml.dart';

/// Loads scripts from `pubspec.yaml` content.
Future<Map<String, dynamic>> loadDefinitions() async {
  final YamlDocument pubspec = await readPubspec();
  final definitions = pubspec.contents.value['scripts'];

  if (definitions == null) {
    throw const DerryError(type: ErrorType.dnf);
  }

  if (definitions is YamlMap) {
    return definitions.value.cast<String, dynamic>();
  } else if (definitions is String) {
    final fileScripts = await readYamlFile(definitions);

    if (fileScripts.contents.value is YamlMap) {
      return (fileScripts.contents.value as YamlMap).cast<String, dynamic>();
      // return fileScripts.contents.value as Map<String, dynamic>;
    } else {
      throw const DerryError(type: ErrorType.cpd);
    }
  } else {
    throw const DerryError(type: ErrorType.cpd);
  }
}

/// Gets keys as a list from the definitions.
List<String> makeKeys(Map input) {
  final result = [];

  for (final k in input.keys) {
    if (input[k] is Map) {
      result.addAll(makeKeys(input[k] as Map).map((v) => '$k $v'));
    } else if (k is String && RegExp(r'\(\w+\)').matchAsPrefix(k) != null) {
      result.add('');
    } else {
      result.add(k);
    }
  }

  return result.map((v) => v.toString().trim()).toSet().toList();
}

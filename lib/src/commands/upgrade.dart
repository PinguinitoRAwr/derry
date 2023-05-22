import 'package:args/command_runner.dart';

import 'package:derry/src/execute.dart';
import 'package:derry/version.dart';

/// The `derry upgrade` command
/// which will attempt to run the pub command to
/// upgrade the derry package itself.
///
/// It's an equivalent of executing the
/// `pub global activate derry` in the derry executor.
class UpgradeCommand extends Command {
  @override
  String get name => 'upgrade';

  @override
  String get description => 'upgrade to the latest version of derry itself';

  @override
  Future<void> run() async {
    {
      const infoLine = '> derry@$packageVersion upgrade';

      execute(
        {'upgrade': 'dart pub global activate -s git https://github.com/PinguinitoRAwr/derry'},
        'upgrade',
        infoLine: infoLine,
      );
    }
  }
}

import 'dart:io' show exit;
import 'package:args/args.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:libtokyo_flutter/libtokyo.dart' hide ColorScheme;
import 'package:libtokyo/libtokyo.dart' hide TokyoApp;
import 'package:provider/provider.dart';

import 'logic/account.dart';
import 'logic/applications.dart';
import 'logic/display.dart';
import 'logic/outputs.dart';
import 'logic/power.dart';
import 'logic/route_args.dart';

import 'views/desktop.dart';
import 'views/lock.dart';
import 'views/login.dart';

void main(List<String> argsList) async {
  final argsParser = ArgParser()
    ..addFlag('init-locked', help: 'Adding this option will start Genesis Shell in a locked state')
    ..addFlag('display-manager', help: 'Start as a display manager')
    ..addFlag('help', abbr: 'h', negatable: false);

  final args = argsParser.parse(argsList);

  if (args.flag('help')) {
    print(argsParser.usage);
    exit(0);
  }

  if (args.flag('display-manager') && args.flag('init-locked')) {
    print('Cannot run as a display manager and start locked');
    exit(1);
  }

  WidgetsFlutterBinding.ensureInitialized();

  runApp(GenesisShellApp(
    initLocked: args.flag('init-locked'),
    displayManager: args.flag('display-manager'),
  ));

  doWhenWindowReady(() {
    const initialSize = Size(600, 450);
    appWindow.size = initialSize;
    appWindow.alignment = Alignment.center;
    appWindow.show();
  });
}

class GenesisShellApp extends StatefulWidget {
  const GenesisShellApp({
    super.key,
    this.initLocked = false,
    this.displayManager = false,
  });

  final bool initLocked;
  final bool displayManager;

  @override
  State<GenesisShellApp> createState() => _GenesisShellAppState();
}

class _GenesisShellAppState extends State<GenesisShellApp> {
  late AccountManager _accountManager;
  late ApplicationsManager _applicationsManager;
  late DisplayManager _displayManager;
  late OutputManager _outputManager;
  late PowerManager _powerManager;

  @override
  void initState() {
    super.initState();

    _accountManager = AccountManager();
    _applicationsManager = ApplicationsManager();
    _displayManager = DisplayManager();
    _outputManager = OutputManager();
    _powerManager = PowerManager.auto();
    _powerManager.connect();
  }

  @override
  void dispose() {
    super.dispose();
    _powerManager.disconnect();
  }

  @override
  Widget build(BuildContext context) =>
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => _accountManager),
        Provider(create: (_) => _applicationsManager),
        ChangeNotifierProvider(create: (_) => _displayManager),
        ChangeNotifierProvider(create: (_) => _outputManager),
        Provider(create: (_) => _powerManager),
      ],
      child: TokyoApp(
        title: 'Genesis Shell',
        themeMode: ThemeMode.dark,
        routes: {
          '/': (context) {
            final args = AuthedRouteArguments.of(context);
            return DesktopView(
              userName: args.userName,
              isSession: args.isSession,
            );
          },
          '/lock': (context) => LockView(userName: AuthedRouteArguments.of(context).userName),
          '/login': (_) => const LoginView(),
        },
        initialRoute: widget.initLocked ? '/lock' : (widget.displayManager ? '/login' : '/'),
      ),
    );
}

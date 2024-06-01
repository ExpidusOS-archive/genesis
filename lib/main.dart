import 'dart:io' show exit;
import 'package:args/args.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/scheduler.dart';
import 'package:libtokyo_flutter/libtokyo.dart' hide ColorScheme;
import 'package:libtokyo/libtokyo.dart' hide TokyoApp;
import 'package:provider/provider.dart';

import 'logic/account.dart';
import 'logic/applications.dart';
import 'logic/display.dart';
import 'logic/network.dart';
import 'logic/outputs.dart';
import 'logic/power.dart';
import 'logic/route_args.dart';
import 'logic/sensors.dart';
import 'logic/system.dart';

import 'views/desktop.dart';
import 'views/lock.dart';
import 'views/login.dart';
import 'views/system/setup.dart';

void main(List<String> argsList) async {
  final argsParser = ArgParser()
    ..addFlag('init-locked', help: 'Adding this option will start Genesis Shell in a locked state')
    ..addFlag('display-manager', help: 'Start as a display manager')
    ..addFlag('init-setup', help: 'Starts the shell in the "initial setup" mode.')
    ..addFlag('disable-init-setup-check', help: 'Disables the initial setup check.')
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

  if (args.flag('init-locked') && args.flag('init-setup')) {
    print('Cannot run the initial setup and start locked');
    exit(1);
  }

  if (args.flag('disable-init-setup-check') && args.flag('init-setup')) {
    print('Cannot run the initial setup and disable the init setup check');
    exit(1);
  }

  WidgetsFlutterBinding.ensureInitialized();

  runApp(GenesisShellApp(
    initLocked: args.flag('init-locked'),
    initSetup: args.flag('init-setup'),
    disableInitSetupCheck: args.flag('disable-init-setup-check'),
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
    this.initSetup = false,
    this.disableInitSetupCheck = false,
    this.displayManager = false,
  });

  final bool initLocked;
  final bool initSetup;
  final bool disableInitSetupCheck;
  final bool displayManager;

  @override
  State<GenesisShellApp> createState() => _GenesisShellAppState();
}

class _GenesisShellAppState extends State<GenesisShellApp> {
  GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();
  late AccountManager _accountManager;
  late ApplicationsManager _applicationsManager;
  late DisplayManager _displayManager;
  late NetworkManager _networkManager;
  late OutputManager _outputManager;
  late PowerManager _powerManager;
  late SensorsManager _sensorsManager;
  late SystemManager _systemManager;

  @override
  void initState() {
    super.initState();

    _accountManager = AccountManager();
    _applicationsManager = ApplicationsManager();
    _displayManager = DisplayManager();

    _networkManager = NetworkManager.auto();
    _networkManager.connect();

    _outputManager = OutputManager();

    _powerManager = PowerManager.auto();
    _powerManager.connect();

    _sensorsManager = SensorsManager.auto();
    _sensorsManager.connect();

    _systemManager = SystemManager();

    if (!widget.disableInitSetupCheck) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_accountManager.account.isEmpty) {
            _navKey.currentState!.pushReplacementNamed('/system/setup');
          }
        });
      });
    }
  }

  @override
  void dispose() {
    super.dispose();

    _networkManager.disconnect();
    _powerManager.disconnect();
    _sensorsManager.disconnect();
  }

  @override
  Widget build(BuildContext context) =>
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => _accountManager),
        Provider(create: (_) => _applicationsManager),
        ChangeNotifierProvider(create: (_) => _displayManager),
        Provider(create: (_) => _networkManager),
        ChangeNotifierProvider(create: (_) => _outputManager),
        Provider(create: (_) => _powerManager),
        Provider(create: (_) => _sensorsManager),
        ChangeNotifierProvider(create: (_) => _systemManager),
      ],
      child: TokyoApp(
        navigatorKey: _navKey,
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
          '/system/setup': (_) => const SystemSetupView(),
        },
        initialRoute: widget.initLocked ? '/lock' : (widget.displayManager ? '/login' : (widget.initSetup ? '/system/setup' : '/')),
      ),
    );
}

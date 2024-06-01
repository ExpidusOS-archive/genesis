import 'dart:io' as io;
import 'dart:io' if (dart.library.html) '../../logic/io_none.dart';

import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:libtokyo_flutter/libtokyo.dart' hide ColorScheme;
import 'package:libtokyo/libtokyo.dart' hide TokyoApp;
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';

import '../../logic/system.dart';
import '../../logic/wallpaper.dart';

import '../../widgets/clock.dart';
import '../../widgets/keypad.dart';
import '../../widgets/system_layout.dart';

class _WelcomePage extends StatelessWidget {
  const _WelcomePage({
    super.key,
    required this.onProgress,
  });

  final VoidCallback onProgress;

  @override
  Widget build(BuildContext context) =>
    Consumer<SystemManager>(
      builder: (context, sys, _) {
        if (sys.metadata == null) return const SizedBox();
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Spacer(),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                sys.metadata!.logo != null
                  ? (path.extension(sys.metadata!.logo!) == '.svg'
                    ? SvgPicture.file(
                        File(sys.metadata!.logo!),
                        width: 192,
                        height: 192,
                      ) : Image.file(
                        io.File(sys.metadata!.logo!),
                        width: 192,
                        height: 192,
                      )) : null,
                sys.metadata!.prettyName != null
                  ? Text(
                      'Welcome to ${sys.metadata!.prettyName!}',
                      style: Theme.of(context).textTheme.displayMedium,
                      textAlign: TextAlign.center,
                    ) : null,
              ].where((e) => e != null).toList().cast<Widget>(),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(Icons.chevronRight),
                  onPressed: onProgress,
                ),
              ],
            ),
          ],
        );
      },
    );
}

typedef _LangRegionSetLocale = void Function(Locale locale);

class _LangRegionPage extends StatefulWidget {
  const _LangRegionPage({
    super.key,
    required this.locale,
    required this.onProgress,
    required this.setLocale,
  });

  final Locale locale;
  final VoidCallback onProgress;
  final _LangRegionSetLocale setLocale; 

  @override
  State<_LangRegionPage> createState() => _LangRegionPageState();
}

class _LangRegionPageState extends State<_LangRegionPage> {
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  int _step = 0;

  Widget _buildLang(String title, String languageCode) =>
    ListTile(
      title: Text(title),
      leading: Radio<String>(
        value: languageCode,
        groupValue: widget.locale.languageCode,
        onChanged: (String? languageCode) =>
          widget.setLocale(Locale.fromSubtags(
            languageCode: languageCode!,
            scriptCode: widget.locale.scriptCode,
            countryCode: widget.locale.countryCode,
          )),
      ),
    );

  Widget _buildCountry(String title, String? countryCode) =>
    ListTile(
      title: Text(title),
      leading: Radio<String?>(
        value: countryCode,
        groupValue: widget.locale.countryCode,
        onChanged: (String? countryCode) =>
          widget.setLocale(Locale.fromSubtags(
            languageCode: widget.locale.languageCode,
            scriptCode: widget.locale.scriptCode,
            countryCode: countryCode,
          )),
      ),
    );

  @override
  Widget build(BuildContext context) {
    if (_step == 0) {
      return Column(
        children: [
          Row(
            children: [
              Text(
                'Language',
                style: Theme.of(context).textTheme.displayMedium,
              ),
            ],
          ),
          ListView(
            shrinkWrap: true,
            children: [
              _buildLang('English', 'en'),
              _buildLang('日本語', 'ja'),
            ],
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                icon: Icon(Icons.chevronRight),
                onPressed: () =>
                  setState(() {
                    _step = 1;
                  }),
              ),
            ],
          ),
        ],
      );
    }
    if (_step == 1) {
      return Column(
        children: [
          Row(
            children: [
              Text(
                'Region',
                style: Theme.of(context).textTheme.displayMedium,
              ),
            ],
          ),
          ListView(
            shrinkWrap: true,
            children: [
              _buildCountry('Japan', 'JP'),
              _buildCountry('United States', 'US'),
              _buildCountry('United Kingdom', 'UK'),
            ],
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                icon: Icon(Icons.chevronLeft),
                onPressed: () =>
                  setState(() {
                    _step = 0;
                  }),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.chevronRight),
                onPressed: widget.onProgress,
              ),
            ],
          ),
        ],
      );
    }
    return const SizedBox();
  }
}

class _InternetPage extends StatelessWidget {
  const _InternetPage({
    super.key,
    required this.onProgress,
  });

  final VoidCallback onProgress;

  @override
  Widget build(BuildContext context) =>
    Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Padding(
              padding: const EdgeInsets.all(12.0),
              child: const CircularProgressIndicator(),
            ),
            Text(
              'Checking your network connection',
              style: Theme.of(context).textTheme.displaySmall,
            ),
          ],
        ),
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              icon: Icon(Icons.chevronRight),
              onPressed: onProgress,
            ),
          ],
        ),
      ],
    );
}

class _UserPage extends StatefulWidget {
  const _UserPage({
    super.key,
    required this.onProgress,
  });

  final VoidCallback onProgress;

  @override
  State<_UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<_UserPage> {
  TextEditingController passcodeController = TextEditingController();

  String? _displayName;
  String? _username;

  @override
  Widget build(BuildContext context) =>
    Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: TextField(
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Name',
            ),
            onChanged: (value) =>
              setState(() {
                _displayName = value;
              })
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: TextField(
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'User Name',
            ),
            onChanged: (value) =>
              setState(() {
                _username = value;
              }),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: TextField(
            controller: passcodeController,
            obscureText: true,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Password',
            ),
          ),
        ),
        Keypad(
          hasNextButton: false,
          onTextPressed: (str) {
            setState(() {
              passcodeController.text += str;
            });
          },
          onIconPressed: (icon) {
            if (icon == Icons.backspace) {
              setState(() {
                final text = passcodeController.text;
                if (text.length > 0) {
                  passcodeController.text = text.substring(0, text.length - 1);
                }
              });
            }
          },
        ),
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              icon: Icon(Icons.chevronRight),
              onPressed: _username == null && _displayName == null ? null : widget.onProgress,
            ),
          ],
        ),
      ],
    );
}

class SystemSetupView extends StatefulWidget {
  const SystemSetupView({
    super.key,
    this.wallpaper = null,
    this.desktopWallpaper = null,
    this.mobileWallpaper = null,
  });

  final String? wallpaper;
  final String? desktopWallpaper;
  final String? mobileWallpaper;

  @override
  State<SystemSetupView> createState() => _SystemSetupViewState();
}

class _SystemSetupViewState extends State<SystemSetupView> {
  int _step = 0;
  int _maxStep = 0;
  Locale? _locale;

  set step(int i) {
    _step = i;
    if (_maxStep < i) _maxStep = i;
  }

  @override
  Widget build(BuildContext context) {
    Widget value = Localizations.override(
      context: context,
      locale: _locale,
      child: SystemLayout(
        userMode: false,
        isLocked: true,
        body: Container(
          decoration: !Breakpoints.large.isActive(context)
            ? BoxDecoration(
                image: getWallpaper(
                  path: widget.mobileWallpaper ?? widget.wallpaper,
                  fallback: AssetImage('assets/wallpaper/mobile/default.jpg'),
                ),
              ) : null,
          child: Center(
            child: Card(
              margin: const EdgeInsets.all(36),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: LayoutBuilder(
                  builder: (context, constraints) =>
                    Stepper(
                      type: StepperType.horizontal,
                      currentStep: _step,
                      steps: [
                        Step(
                          title: Text('Welcome'),
                          content: SizedBox(
                            width: constraints.maxWidth,
                            height: constraints.maxHeight - 116.0,
                            child: _WelcomePage(
                              onProgress: () =>
                                setState(() {
                                  step = 1;
                                }),
                            ),
                          ),
                        ),
                        Step(
                          title: Text('Language & Region'),
                          state: _maxStep < 1 ? StepState.disabled : StepState.indexed,
                          content: SizedBox(
                            width: constraints.maxWidth,
                            height: constraints.maxHeight - 116.0,
                            child: _LangRegionPage(
                              locale: _locale ?? Localizations.localeOf(context),
                              onProgress: () =>
                                setState(() {
                                  step = 2;
                                }),
                              setLocale: (locale) =>
                                setState(() {
                                  _locale = locale;
                                }),
                            ),
                          ),
                        ),
                        Step(
                          title: Text('Internet'),
                          state: _maxStep < 2 ? StepState.disabled : StepState.indexed,
                          content: SizedBox(
                            width: constraints.maxWidth,
                            height: constraints.maxHeight - 116.0,
                            child: _InternetPage(
                              onProgress: () =>
                                setState(() {
                                  step = 3;
                                }),
                            ),
                          ),
                        ),
                        Step(
                          title: Text('User Setup'),
                          state: _maxStep < 3 ? StepState.disabled : StepState.indexed,
                          content: SizedBox(
                            width: constraints.maxWidth,
                            height: constraints.maxHeight - 116.0,
                            child: _UserPage(
                              onProgress: () =>
                                Navigator.of(context).pushReplacementNamed('/login'),
                            ),
                          ),
                        ),
                      ],
                      onStepTapped: (i) =>
                        setState(() {
                          _step = i;
                        }),
                    ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (Breakpoints.large.isActive(context)) {
      value = Container(
        decoration: BoxDecoration(
          image: getWallpaper(
            path: widget.desktopWallpaper ?? widget.wallpaper,
            fallback: AssetImage('assets/wallpaper/desktop/default.jpg'),
          ),
        ),
        child: value,
      );
    }

    return value;
  }
}

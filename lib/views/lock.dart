import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:intl/intl.dart';

import '../../widgets/clock.dart';
import '../../widgets/draggable.dart';
import '../../widgets/keypad.dart';
import '../../widgets/system_layout.dart';

class LockView extends StatefulWidget {
  const LockView({ super.key });

  @override
  State<LockView> createState() => _LockViewState();
}

class _LockViewState extends State<LockView> {
  static const platform = MethodChannel('com.expidusos.genesis.shell/auth');

  TextEditingController passcodeController = TextEditingController();
  String? errorText = null;

  void _onSubmitted(BuildContext context, String input) {
    setState(() {
      errorText = null;
    });

    platform.invokeMethod<void>('auth', <String, dynamic>{
      'password': input,
    }).then((_) {
      setState(() {
        passcodeController.clear();
        errorText = null;
      });

      final nav = Navigator.of(context);
      if (nav.canPop()) nav.pop();
      else nav.pushReplacementNamed('/');
    }).catchError((err) => setState(() {
      if (err is PlatformException) {
        errorText = '${err.code}: ${err.message}: ${err.details.toString()}';
      } else {
        errorText = err.toString();
      }
    }));
  }

  @override
  void dispose() {
    super.dispose();
    passcodeController.dispose();
  }

  @override
  Widget build(BuildContext context) =>
    SystemLayout(
      body: Container(
        decoration: BoxDecoration(
          image: Breakpoints.small.isActive(context)
            ? const DecorationImage(
                image: AssetImage('assets/wallpaper/mobile/default.jpg'),
                fit: BoxFit.fitHeight,
              )
            : const DecorationImage(
                image: AssetImage('assets/wallpaper/desktop/default.jpg'),
                fit: BoxFit.cover,
              ),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                children: [
                  const Spacer(),
                  DigitalClock(
                    style: Theme.of(context).textTheme.displayLarge,
                  ),
                  DigitalClock(
                    format: DateFormat.yMMMd(),
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const Spacer(),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: VerticalDragContainer(
                startHeight: 56.0,
                minHeight: 56.0,
                expandedHeight: MediaQuery.of(context).size.height - 37,
                onExpanded: () => passcodeController.clear(),
                onUnexpanded: () => passcodeController.clear(),
                handleBuilder: (context, isExpanded) =>
                  Container(
                    decoration: BoxDecoration(
                      color: isExpanded ? Theme.of(context).colorScheme.surface.withOpacity(0.8) : Colors.transparent,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                        child: Icon(Icons.lock),
                      ),
                    ),
                  ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                  ),
                  child: AnimatedDefaultTextStyle(
                    style: Theme.of(context).textTheme.titleMedium!.apply(
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                    duration: kThemeChangeDuration,
                    child: Center(
                      child: Column(
                        children: [
                          const Spacer(),
                          SizedBox(
                            width: 200,
                            child: TextField(
                              controller: passcodeController,
                              obscureText: true,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 4.0),
                                errorMaxLines: 5,
                                errorText: errorText,
                              ),
                              style: Theme.of(context).textTheme.displayMedium,
                              onSubmitted: (input) => _onSubmitted(context, input),
                            ),
                          ),
                          Keypad(
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
                              } else if (icon == Icons.keyboard_return) {
                                _onSubmitted(context, passcodeController.text);
                              }
                            },
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
}
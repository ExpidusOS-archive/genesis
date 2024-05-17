import 'package:flutter/services.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:libtokyo_flutter/libtokyo.dart' hide ColorScheme;
import 'package:libtokyo/libtokyo.dart' hide TokyoApp;
import 'package:intl/intl.dart';

import '../logic/wallpaper.dart';

import '../widgets/clock.dart';
import '../widgets/draggable.dart';
import '../widgets/login.dart';
import '../widgets/system_layout.dart';

class LockView extends StatelessWidget {
  const LockView({
    super.key,
    this.wallpaper = null,
    this.desktopWallpaper = null,
    this.mobileWallpaper = null,
    this.userName = null,
  });

  final String? wallpaper;
  final String? desktopWallpaper;
  final String? mobileWallpaper;
  final String? userName;

  @override
  Widget build(BuildContext context) {
    Widget widget = SystemLayout(
      userMode: true,
      isLocked: true,
      userName: userName,
      body: Container(
        decoration: !Breakpoints.large.isActive(context)
          ? BoxDecoration(
              image: getWallpaper(
                path: mobileWallpaper ?? wallpaper,
                fallback: AssetImage('assets/wallpaper/mobile/default.jpg'),
              ),
            ) : null,
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
                startHeight: 57.0,
                minHeight: 57.0,
                expandedHeight: MediaQuery.of(context).size.height - 37,
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
                          LoginPrompt(
                            onLogin: () {
                              final nav = Navigator.of(context);
                              if (nav.canPop()) nav.pop();
                              else nav.pushReplacementNamed('/');
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

    if (Breakpoints.large.isActive(context)) {
      widget = Container(
        decoration: BoxDecoration(
          image: getWallpaper(
            path: desktopWallpaper ?? wallpaper,
            fallback: AssetImage('assets/wallpaper/desktop/default.jpg'),
          ),
        ),
        child: widget,
      );
    }

    return widget;
  }
}

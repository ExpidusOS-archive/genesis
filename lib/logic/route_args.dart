import 'package:libtokyo_flutter/libtokyo.dart' hide ColorScheme;
import 'package:libtokyo/libtokyo.dart' hide TokyoApp;

class AuthedRouteArguments {
  const AuthedRouteArguments({
    this.userName = null,
    this.isSession = false,
  });

  final String? userName;
  final bool isSession;

  static AuthedRouteArguments? maybeOf(BuildContext context) {
    final route = ModalRoute.of(context);
    if (route == null) return null;
    if (route.settings.arguments == null) return null;
    return route.settings.arguments as AuthedRouteArguments;
  }

  static AuthedRouteArguments of(BuildContext context) {
    return maybeOf(context) ?? AuthedRouteArguments();
  }
}

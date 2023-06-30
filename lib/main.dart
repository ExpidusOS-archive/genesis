import 'package:libtokyo/libtokyo.dart' show ColorScheme;
import 'package:libtokyo_flutter/libtokyo.dart' hide ColorScheme;
import 'package:genesis_shell/views.dart';

void main() {
  runApp(const GenesisShell());
}

class GenesisShell extends StatelessWidget {
  const GenesisShell({super.key});

  @override
  Widget build(BuildContext context) =>
    TokyoApp(
      title: 'Genesis Shell',
      themeMode: ThemeMode.dark,
      colorScheme: ColorScheme.night,
      colorSchemeDark: ColorScheme.night,
      routes: {
        '/': (ctx) => const GenesisShellLogIn(),
        '/desktop': (ctx) => const GenesisShellDesktop(),
      },
    );
}

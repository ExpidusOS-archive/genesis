import 'package:libtokyo/libtokyo.dart' show ColorScheme;
import 'package:libtokyo_flutter/libtokyo.dart' hide ColorScheme;
import 'package:genesis_shell/widgets.dart';

void main() {
  runApp(const GenesisShell());
}

class GenesisShell extends StatelessWidget {
  const GenesisShell({super.key});

  @override
  Widget build(BuildContext context) =>
    const TokyoApp(
      title: 'Genesis Shell',
      themeMode: ThemeMode.dark,
      colorScheme: ColorScheme.night,
      colorSchemeDark: ColorScheme.night,
      home: GenesisShellView(),
    );
}

class GenesisShellView extends StatefulWidget {
  const GenesisShellView({super.key});

  @override
  State<GenesisShellView> createState() => _GenesisShellViewState();
}

class _GenesisShellViewState extends State<GenesisShellView> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/wallpaper/desktop/default.jpg'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Scaffold(
          backgroundColor: convertFromColor(Colors.transparent),
          appBar: const GenesisShellPanel(),
          drawer: Drawer(
            width: 608,
          ),
          endDrawer: Drawer(
            width: 608,
          ),
        )
      ],
    );
  }
}

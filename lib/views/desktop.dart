import 'package:libtokyo_flutter/libtokyo.dart' hide ColorScheme;
import 'package:genesis_shell/widgets.dart';

class GenesisShellDesktop extends StatefulWidget {
  const GenesisShellDesktop({super.key});

  @override
  State<GenesisShellDesktop> createState() => _GenesisShellDesktopState();
}

class _GenesisShellDesktopState extends State<GenesisShellDesktop> {
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
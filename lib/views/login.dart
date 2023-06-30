import 'package:libtokyo_flutter/libtokyo.dart' hide ColorScheme;
import 'package:genesis_shell/widgets.dart';

class GenesisShellLogIn extends StatefulWidget {
  const GenesisShellLogIn({super.key});

  @override
  State<GenesisShellLogIn> createState() => _GenesisShellLogInState();
}

class _GenesisShellLogInState extends State<GenesisShellLogIn> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/wallpaper/desktop/dark-sand.jpg'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Scaffold(
          backgroundColor: convertFromColor(Colors.transparent),
          appBar: const GenesisShellPanel(
            showLeading: false,
          ),
          endDrawer: Drawer(
            width: 608,
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Card(
                child: Container(
                  width: 600,
                  height: 400,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Text(
                          'Log In',
                          style: Theme.of(context).textTheme.displayMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        )
      ],
    );
  }
}
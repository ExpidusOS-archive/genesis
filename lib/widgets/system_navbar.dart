import 'package:libtokyo_flutter/libtokyo.dart' hide ColorScheme;
import 'package:libtokyo/libtokyo.dart' hide TokyoApp, Scaffold;

class SystemNavbar extends StatelessWidget {
  const SystemNavbar({ super.key });

  @override
  Widget build(BuildContext context) =>
    BottomAppBar(
      height: 45,
      padding: EdgeInsets.zero,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.chevronLeft),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.circleDot),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.bars),
          ),
        ],
      ),
    );
}

import 'dart:io';

import 'package:libtokyo_flutter/libtokyo.dart' hide ColorScheme;
import 'package:libtokyo/libtokyo.dart' hide TokyoApp, Scaffold;
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';

import '../logic/applications.dart';
import '../logic/display.dart';
import '../logic/wm.dart';

import 'toplevel.dart';

class UserDrawer extends StatelessWidget {
  const UserDrawer({
    super.key,
    required this.onClose,
  });

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => 
    ListView(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: context.watch<DisplayServer>().toplevels.map(
              (toplevel) =>
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: InkWell(
                    onTap: () {
                      final wm = Provider.of<WindowManager>(context, listen: false);
                      final win = wm.fromToplevel(toplevel);

                      win.toplevel.setActive(true);
                      win.minimized = false;
                      win.layer++;

                      onClose();
                    },
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: ToplevelView(
                        toplevel: toplevel,
                        isFocusable: false,
                        isSizable: false,
                        buildDecor: (context, toplevel, content) =>
                          !Breakpoints.small.isActive(context)
                            ? Container(
                                width: toplevel.size != null ? (toplevel.size!.width ?? 0).toDouble() : null,
                                child: Column(
                                  children: [
                                    ToplevelDecor(
                                      toplevel: toplevel,
                                    ),
                                    ClipRRect(
                                      borderRadius: BorderRadius.only(
                                        bottomLeft: Radius.circular(12),
                                        bottomRight: Radius.circular(12),
                                      ),
                                      child: content,
                                    ),
                                  ],
                                ),
                              ) : null,
                      ),
                    ),
                  ),
                )
            ).toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: GridView.count(
            crossAxisCount: 5,
            shrinkWrap: true,
            children: (Provider.of<ApplicationsManager>(context).applications.toList()..where((app) => !app.isHidden))
              .map(
                (app) =>
                  InkWell(
                    onTap: () {
                      app.launch();
                      onClose();
                    },
                    child: Column(
                      children: [
                        app.icon != null
                          ? (path.extension(app.icon!) == '.svg'
                            ? SvgPicture.file(
                                File(app.icon!),
                                width: 40,
                                height: 40,
                              ) : Image.file(
                                    File(app.icon!),
                                    width: 40,
                                    height: 40,
                                  )) : Icon(Icons.tablet, size: 40),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: Text(
                            app.displayName ?? app.name ?? '',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  )
              ).toList(),
          ),
        ),
      ],
    );
}

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

class ActivityDrawer extends StatelessWidget {
  const ActivityDrawer({
    super.key,
    required this.onClose,
    this.hasDisplayServer = false,
  });

  final VoidCallback onClose;
  final bool hasDisplayServer;

  @override
  Widget build(BuildContext context) => 
    ListView(
      children: [
        hasDisplayServer
          ? Container(height: MediaQuery.of(context).size.height / 3, child: SingleChildScrollView(
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
            )) : null,
        Padding(
          padding: const EdgeInsets.all(8),
          child: GridView(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 84,
              mainAxisExtent: 84,
            ),
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
                        const Spacer(),
                        app.icon != null
                          ? (path.extension(app.icon!) == '.svg'
                            ? SvgPicture.file(
                                File(app.icon!),
                                width: 64,
                                height: 64,
                              ) : Image.file(
                                    File(app.icon!),
                                    width: 64,
                                    height: 64,
                                  )) : Icon(Icons.tablet, size: 58),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: Text(
                            app.displayName ?? app.name ?? '',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                  )
              ).toList(),
          ),
        ),
      ].where((e) => e != null).toList().cast<Widget>(),
    );
}

import 'dart:io' as io;
import 'dart:io' if (dart.library.html) '../logic/io_none.dart';

import 'package:libtokyo_flutter/libtokyo.dart' hide ColorScheme;
import 'package:libtokyo/libtokyo.dart' hide TokyoApp, Scaffold;
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';

import '../logic/applications.dart';
import '../logic/display.dart';
import '../logic/wm.dart';

import 'surface.dart';

class ActivityDrawer extends StatelessWidget {
  const ActivityDrawer({
    super.key,
    required this.onClose,
    required this.outputIndex,
    this.hasDisplayServer = false,
  });

  final VoidCallback onClose;
  final int outputIndex;
  final bool hasDisplayServer;

  List<Window> _getWindows(BuildContext context) {
    final displayServer = context.watch<DisplayServer>();
    final wm = context.watch<WindowManager>();

    final list = displayServer.surfaces.map((surface) => wm.fromSurface(surface))
      .where((win) => win.monitor == outputIndex).toList();
    list.sort((a, b) => a.layer.compareTo(b.layer));
    return list;
  }

  @override
  Widget build(BuildContext context) => 
    ListView(
      children: [
        hasDisplayServer
          ? Container(
              height: _getWindows(context).isEmpty ? 0 : MediaQuery.of(context).size.height / 3,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _getWindows(context).map(
                    (win) =>
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: InkWell(
                          onTap: () {
                            win.surface.setActive(true);
                            win.minimized = false;
                            win.raiseToTop();

                            onClose();
                          },
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: SurfaceView(
                              surface: win.surface,
                              isFocusable: false,
                              isSizable: false,
                              buildDecor: (context, surface, content) =>
                                !Breakpoints.small.isActive(context)
                                  ? Container(
                                      width: surface.size != null ? (surface.size!.width ?? 0).toDouble() : null,
                                      child: Column(
                                        children: [
                                          SurfaceDecor(
                                            surface: surface,
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
            ) : null,
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
                                    io.File(app.icon!),
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
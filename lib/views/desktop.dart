import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';

import '../logic/wallpaper.dart';

import '../widgets/system_layout.dart';
import '../widgets/system_navbar.dart';

class DesktopView extends StatefulWidget {
  const DesktopView({
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
  State<DesktopView> createState() => _DesktopViewState();
}

class _DesktopViewState extends State<DesktopView> {
  static const sessionChannel = MethodChannel('com.expidusos.genesis.shell/session');

  String? sessionName = null;

  @override
  void initState() {
    super.initState();

    sessionChannel.invokeMethod('open').then((name) => setState(() {
      sessionName = name;
    })).catchError((err) {
      print(err);
    });
  }

  @override
  void dispose() {
    super.dispose();

    sessionChannel.invokeMethod('close', sessionName).catchError((err) {
      print(err);
    });
  }

  @override
  Widget build(BuildContext context) =>
    SystemLayout(
      userMode: true,
      userName: widget.userName,
      body: Container(
        decoration: BoxDecoration(
          image: getWallpaper(
            path: (Breakpoints.small.isActive(context) ? widget.mobileWallpaper : widget.desktopWallpaper) ?? widget.wallpaper,
            fallback: AssetImage('assets/wallpaper/${Breakpoints.small.isActive(context) ? 'mobile' : 'desktop'}/default.jpg'),
          ),
        ),
      ),
      bottomNavigationBar: Breakpoints.small.isActive(context)
        ? SystemNavbar() : null,
    );
}

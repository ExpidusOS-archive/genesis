import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:provider/provider.dart';

import '../logic/outputs.dart';
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
    this.isSession = false,
  });

  final String? wallpaper;
  final String? desktopWallpaper;
  final String? mobileWallpaper;
  final String? userName;
  final bool isSession;

  @override
  State<DesktopView> createState() => _DesktopViewState();
}

class _DesktopViewState extends State<DesktopView> {
  static const authChannel = MethodChannel('com.expidusos.genesis.shell/auth');
  static const displayChannel = MethodChannel('com.expidusos.genesis.shell/display');
  static const outputsChannel = MethodChannel('com.expidusos.genesis.shell/outputs');
  static const sessionChannel = MethodChannel('com.expidusos.genesis.shell/session');

  String? sessionName = null;
  String? displayName = null;
  GlobalKey _key = GlobalKey();

  void _syncOutputs() {
    if (displayName != null) {
      outputsChannel.invokeListMethod('list').then(
        (list) => displayChannel.invokeMethod('setOutputs', <String, dynamic>{
          'name': displayName!,
          'list': list,
        })
      ).catchError((err) {
        print(err);
      });
    }
  }

  @override
  void initState() {
    super.initState();

    sessionChannel.invokeMethod('open').then((name) {
      setState(() {
        sessionName = name;
      });

      displayChannel.invokeMethod('start', <String, dynamic>{
        'sessionName': name,
      }).then((name) {
        setState(() {
          displayName = name;
          print(name);
        });

        _syncOutputs();
      }).catchError((err) {
        print(err);
      });
    }).catchError((err) {
      print(err);
    });

    SchedulerBinding.instance.addPostFrameCallback((_) {
      final outputs = Provider.of<OutputManager>(_key.currentContext!, listen: false);
      outputs.addListener(_syncOutputs);
    });
  }

  @override
  void dispose() {
    super.dispose();

    if (sessionName != null) {
      sessionChannel.invokeMethod('close', sessionName!).catchError((err) {
        print(err);
      });
    }

    if (displayName != null) {
      displayChannel.invokeMethod('stop', displayName!).catchError((err) {
        print(err);
      });
    }

    if (widget.isSession && widget.userName != null) {
      authChannel.invokeMethod('deauth', widget.userName).catchError((err) {
        print(err);
      });
    }

    final outputs = Provider.of<OutputManager>(_key.currentContext!, listen: false);
    outputs.removeListener(_syncOutputs);
  }

  @override
  Widget build(BuildContext context) =>
    SystemLayout(
      key: _key,
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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:intl/intl.dart';

import '../logic/route_args.dart';
import '../logic/wallpaper.dart';

import '../widgets/account_profile.dart';
import '../widgets/clock.dart';
import '../widgets/login.dart';
import '../widgets/system_layout.dart';

class LoginView extends StatefulWidget {
  const LoginView({
    super.key,
    this.wallpaper = null,
    this.desktopWallpaper = null,
    this.mobileWallpaper = null,
  });

  final String? wallpaper;
  final String? desktopWallpaper;
  final String? mobileWallpaper;

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  static const accChannel = MethodChannel('com.expidusos.genesis.shell/account');

  List<String> users = List.empty(growable: true);
  String? _selectedUser = null;

  @override
  void initState() {
    super.initState();

    accChannel.invokeListMethod('list').then((values) => setState(() {
      users.clear();
      users.addAll(values!.map((value) => value['name']));
    })).catchError((err) {
      print(err);
    });
  }

  Widget _buildPicker(BuildContext context) =>
    Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Log In',
              style: Theme.of(context).textTheme.displayLarge,
            ),
          ],
        ),
        const Spacer(),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: users.map(
              (name) =>
                InkWell(
                  onTap: () =>
                    setState(() {
                      _selectedUser = name;
                    }),
                  child: AccountProfile.name(
                    name: name,
                    direction: Axis.vertical,
                    iconSize: 140,
                    textStyle: Theme.of(context).textTheme.displaySmall,
                  ),
                ),
            ).toList(),
          ),
        ),
        const Spacer(),
      ],
    );

  Widget _buildPrompt(BuildContext context) =>
    Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () =>
                  setState(() {
                    _selectedUser = null;
                  }),
                icon: Icon(Icons.navigate_before),
              ),
            ),
            const Spacer(),
            AccountProfile.name(name: _selectedUser!),
            const Spacer(),
          ],
        ),
        const Spacer(),
        LoginPrompt(
          isSession: true,
          onLogin: () {
            final nav = Navigator.of(context);
            nav.pushNamed(
              '/',
              arguments: AuthedRouteArguments(
                userName: _selectedUser!,
                isSession: true,
              ),
            );
          },
        ),
        const Spacer(),
      ],
    );

  @override
  Widget build(BuildContext context) =>
    SystemLayout(
      userMode: false,
      isLocked: true,
      body: Container(
        decoration: BoxDecoration(
          image: getWallpaper(
            path: (Breakpoints.small.isActive(context) ? widget.mobileWallpaper : widget.desktopWallpaper) ?? widget.wallpaper,
            fallback: AssetImage('assets/wallpaper/${Breakpoints.small.isActive(context) ? 'mobile' : 'desktop'}/default.jpg'),
          ),
        ),
        child: Center(
          child: Card(
            margin: const EdgeInsets.all(36),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: _selectedUser != null ? _buildPrompt(context) : _buildPicker(context),
            ),
          ),
        ),
      ),
    );
}

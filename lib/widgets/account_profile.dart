import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AccountProfile extends StatefulWidget {
  const AccountProfile({
    super.key,
    this.direction = Axis.horizontal,
    this.iconSize = 40,
    this.textStyle,
  }) : uid = null, name = null;

  const AccountProfile.uid({
    super.key,
    required this.uid,
    this.direction = Axis.horizontal,
    this.iconSize = 40,
    this.textStyle,
  }) : name = null;

  const AccountProfile.name({
    super.key,
    required this.name,
    this.direction = Axis.horizontal,
    this.iconSize = 40,
    this.textStyle,
  }) : uid = null;

  final int? uid;
  final String? name;
  final Axis direction;
  final double iconSize;
  final TextStyle? textStyle;

  @override
  State<AccountProfile> createState() => _AccountProfileState();
}

class _AccountProfileState extends State<AccountProfile> {
  static const platform = MethodChannel('com.expidusos.genesis.shell/account');

  String? displayName = null;
  String? icon = null;

  dynamic _getData() {
    if (widget.uid != null) return widget.uid;
    if (widget.name != null) return widget.name;
    return null;
  }

  @override
  void initState() {
    super.initState();

    platform.invokeMethod('get', _getData()).then((user) => setState(() {
      displayName = user['displayName'];
      icon = user['icon'];
    })).catchError((err) {
      print(err);
    });
  }

  Widget build(BuildContext context) =>
    Flex(
      direction: widget.direction,
      children: [
        icon == null
          ? Icon(Icons.account_circle, size: widget.iconSize)
          : ClipRRect(
              borderRadius: BorderRadius.circular(360.0),
              child: Image.file(
                File(icon!),
                width: widget.iconSize,
                height: widget.iconSize,
                errorBuilder: (context, err, stackTrace) =>
                  Icon(Icons.account_circle, size: widget.iconSize),
              ),
            ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
            displayName ?? '',
            style: widget.textStyle ?? Theme.of(context).textTheme.titleLarge,
          ),
        ),
      ],
    );
}

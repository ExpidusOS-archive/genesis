import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AccountProfile extends StatefulWidget {
  const AccountProfile({ super.key }) : uid = null, name = null;
  const AccountProfile.uid({ super.key, required this.uid }) : name = null;
  const AccountProfile.name({ super.key, required this.name }) : uid = null;

  final int? uid;
  final String? name;

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
    Row(
      children: [
        icon == null
          ? const Icon(Icons.account_circle, size: 40)
          : ClipRRect(
              borderRadius: BorderRadius.circular(360.0),
              child: Image.file(
                File(icon!),
                width: 40,
                height: 40,
                errorBuilder: (context, err, stackTrace) =>
                  const Icon(Icons.account_circle, size: 40),
              ),
            ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
            displayName ?? '',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
      ],
    );
}
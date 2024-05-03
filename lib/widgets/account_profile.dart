import 'dart:io';

import 'package:flutter/services.dart';
import 'package:libtokyo_flutter/libtokyo.dart' hide ColorScheme;
import 'package:libtokyo/libtokyo.dart' hide TokyoApp;
import 'package:provider/provider.dart';

import '../logic/account.dart';

class AccountProfile extends StatelessWidget {
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
  Widget build(BuildContext context) =>
    Consumer<AccountManager>(
      builder: (context, mngr, _) {
        final account = mngr.find(
          uid: uid,
          name: name,
        );

        final icon = account == null ? null : account.icon;
        final displayName = account == null ? null : account.displayName;

        return Flex(
          direction: direction,
          children: [
            icon == null
              ? Icon(Icons.user, size: iconSize)
              : ClipRRect(
                  borderRadius: BorderRadius.circular(360.0),
                  child: Image.file(
                    File(icon!),
                    width: iconSize,
                    height: iconSize,
                    errorBuilder: (context, err, stackTrace) =>
                      Icon(Icons.user, size: iconSize),
                  ),
                ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(
                displayName ?? '',
                style: textStyle ?? Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ],
        );
      },
    );
}

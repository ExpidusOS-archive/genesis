import 'dart:collection';

import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AccountManager extends ChangeNotifier {
  static const channel = MethodChannel('com.expidusos.genesis.shell/account');

  AccountManager() {
    channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'loaded':
          _sync();
          break;
        default:
          throw MissingPluginException();
      }
    });

    _sync();
  }

  final List<Account> _accounts = [];
  UnmodifiableListView<Account> get account => UnmodifiableListView(_accounts);

  Account? find({
    int? uid,
    String? name,
  }) {
    for (final account in _accounts) {
      if (account.uid == uid || account.name == name) return account;
    }
    return null;
  }

  Account? findByUid(int uid) {
    for (final account in _accounts) {
      if (account.uid == uid) return account;
    }
    return null;
  }

  Account? findByName(String name) {
    for (final account in _accounts) {
      if (account.name == name) return account;
    }
    return null;
  }

  void _sync() {
    channel.invokeListMethod('list').then((list) {
      _accounts.clear();
      _accounts.addAll(list!.map(
        (account) =>
          Account(
            name: account['name'],
            uid: account['uid'],
            icon: account['icon'],
            displayName: account['displayName'],
            home: account['home'],
            passwordHint: account['passwordHint'],
          )
      ));
      notifyListeners();
    }).catchError((err) {
      print(err);
    });
  }
}

class Account {
  const Account({
    this.name = null,
    this.uid = null,
    this.icon = null,
    this.displayName = null,
    this.home = null,
    this.passwordHint = null,
  });

  final String? name;
  final int? uid;
  final String? icon;
  final String? displayName;
  final String? home;
  final String? passwordHint;
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/keypad.dart';

class LoginPrompt extends StatefulWidget {
  const LoginPrompt({
    super.key,
    this.name,
    this.isSession = false,
    required this.onLogin,
  });

  final String? name;
  final bool isSession;
  final VoidCallback onLogin;

  @override
  State<LoginPrompt> createState() => _LoginPromptState();
}

class _LoginPromptState extends State<LoginPrompt> {
  static const accChannel = MethodChannel('com.expidusos.genesis.shell/account');
  static const authChannel = MethodChannel('com.expidusos.genesis.shell/auth');

  TextEditingController passcodeController = TextEditingController();
  String? passwordHint = null;
  String? errorText = null;

  void _onSubmitted(BuildContext context, String input) {
    setState(() {
      errorText = null;
    });

    var args = <String, dynamic>{
      'password': input,
      'session': widget.isSession,
    };

    if (widget.name != null) {
      args['name'] = widget.name!;
    }

    authChannel.invokeMethod<void>('auth', args).then((_) {
      setState(() {
        passcodeController.clear();
        errorText = null;
      });

      widget.onLogin();
    }).catchError((err) => setState(() {
      if (err is PlatformException) {
        errorText = '${err.code}: ${err.message}: ${err.details.toString()}';
      } else {
        errorText = err.toString();
      }
    }));
  }

  @override
  void initState() {
    super.initState();

    accChannel.invokeMethod('get', widget.name).then((user) => setState(() {
      passwordHint = user['passwordHint'];
    })).catchError((err) {
      print(err);
    });
  }

  @override
  void dispose() {
    super.dispose();
    passcodeController.dispose();
  }

  @override
  Widget build(BuildContext context) =>
    Column(
      children: [
        SizedBox(
          width: 200,
          child: TextField(
            controller: passcodeController,
            obscureText: true,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 4.0),
              hintText: passwordHint,
              errorMaxLines: 5,
              errorText: errorText,
            ),
            style: Theme.of(context).textTheme.displayMedium,
            onSubmitted: (input) => _onSubmitted(context, input),
          ),
        ),
        Keypad(
          onTextPressed: (str) {
            setState(() {
              passcodeController.text += str;
            });
          },
          onIconPressed: (icon) {
            if (icon == Icons.backspace) {
              setState(() {
                final text = passcodeController.text;
                if (text.length > 0) {
                  passcodeController.text = text.substring(0, text.length - 1);
                }
              });
            } else if (icon == Icons.keyboard_return) {
              _onSubmitted(context, passcodeController.text);
            }
          },
        ),
      ],
    );
}

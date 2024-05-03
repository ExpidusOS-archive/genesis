import 'package:libtokyo_flutter/libtokyo.dart' hide ColorScheme;
import 'package:libtokyo/libtokyo.dart' hide TokyoApp;
import 'rounded_button.dart';

class KeypadKey extends StatelessWidget {
  const KeypadKey.icon(IconData i, {
    super.key,
    this.textTheme = null,
    this.padding = null,
    required this.onPressed
  }) : text = null, icon = i;

  const KeypadKey.text(String s, {
    super.key,
    this.textTheme = null,
    this.padding = null,
    required this.onPressed
  }) : text = s, icon = null;

  final String? text;
  final IconData? icon;
  final TextTheme? textTheme;
  final VoidCallback onPressed;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final _textTheme = (textTheme ?? (text != null ? Theme.of(context).textTheme.displayMedium : Theme.of(context).textTheme.displaySmall)) as TextStyle;
    return RoundedButton(
      onPressed: onPressed,
      padding: icon != null ? const EdgeInsets.symmetric(horizontal: 9, vertical: 18) : null,
      child: text != null
        ? Text(text!, style: _textTheme)
        : Icon(icon!, size: _textTheme.fontSize),
    );
  }
}

class Keypad extends StatelessWidget {
  const Keypad({
    super.key,
    this.labelTextTheme = null,
    this.iconSize = null,
    required this.onTextPressed,
    required this.onIconPressed,
  });

  final TextTheme? labelTextTheme;
  final double? iconSize;
  final void Function(String text) onTextPressed;
  final void Function(IconData icon) onIconPressed;

  @override
  Widget build(BuildContext context) {
    const keypadKeys = [
      [
        '1',
        '2',
        '3',
      ],
      [
        '4',
        '5',
        '6',
      ],
      [
        '7',
        '8',
        '9',
      ],
      [
        Icons.backspace,
        '0',
        Icons.arrowRight,
      ],
    ];

    final _iconSize = iconSize ?? Theme.of(context).textTheme.displaySmall!.fontSize!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: keypadKeys.map(
        (row) => Padding(
          padding: const EdgeInsets.all(4.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: row.map((value) {
              if (value is String) {
                return KeypadKey.text(
                  value,
                  textTheme: labelTextTheme,
                  onPressed: () => onTextPressed(value),
                );
              }

              return KeypadKey.icon(
                value as IconData,
                padding: EdgeInsets.symmetric(horizontal: _iconSize, vertical: _iconSize * 2),
                onPressed: () => onIconPressed(value as IconData),
              );
            }).map(
              (widget) => Padding(
                padding: const EdgeInsets.all(4.0),
                child: widget,
              )
            ).toList(),
          ),
        ),
      ).toList(),
    );
  }
}

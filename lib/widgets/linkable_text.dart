import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class LinkableText extends StatelessWidget {
  const LinkableText(
      {super.key,
      required this.text1,
      required this.text2,
      required this.text3,
      required this.url,
      required this.textStyle});

  final String text1;
  final String text2;
  final String text3;
  final String url;
  final TextStyle textStyle;

  Future<void> _launchUrl(String url, BuildContext context) async {
    final Uri uri = Uri.parse(url);
    // Sprawdź, czy system w ogóle raportuje możliwość otwarcia linku
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode
              .externalApplication, // Wymusza otwarcie w zewnętrznej przeglądarce
        );
      } else {
        throw Exception('Couldn\'t open link $url');
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isBright = theme.brightness == Brightness.dark ? false : true;
    final multiplier = isBright ? 1.33 : 0.5;
    final themeColor = Theme.of(context).colorScheme.primary;
    final linkColor = themeColor.withValues(
        red: themeColor.r * multiplier,
        green: themeColor.g * multiplier,
        blue: themeColor.b * multiplier);

    return Text.rich(
      TextSpan(
        style: textStyle,
        children: [
          TextSpan(text: text1, style: textStyle),
          TextSpan(
            text: text2,
            style: textStyle.copyWith(
              fontFamily: 'Computer Modern Typewriter',
              color: linkColor,
              decoration: TextDecoration.underline,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () => _launchUrl(url, context),
          ),
          TextSpan(text: text3, style: textStyle),
        ],
      ),
    );
  }
}

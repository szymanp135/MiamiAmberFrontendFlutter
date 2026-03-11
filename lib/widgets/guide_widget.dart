import 'package:flutter/material.dart';
import 'package:miami_amber_frontend/constants.dart';
import 'package:miami_amber_frontend/widgets/linkable_text.dart';

TextStyle guideTitleStyle(ThemeData theme) => TextStyle(
    fontWeight: FontWeight.bold, fontSize: 16, color: theme.canvasColor);

TextStyle guideTextStyle(ThemeData theme) =>
    TextStyle(fontSize: 14, color: theme.canvasColor, height: 1.5);

class GuideWidget extends StatelessWidget {
  const GuideWidget(
      {super.key, required this.title, required this.text, this.linkableText});

  final String title;
  final String text;
  final LinkableText? linkableText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kMiamiAmberColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(blurRadius: 4, color: Colors.black26, offset: Offset(2, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: guideTitleStyle(theme)),
          Divider(color: theme.canvasColor),
          Text(text, style: guideTextStyle(theme)),
          if (linkableText != null) ...[
            Divider(color: theme.canvasColor),
            linkableText!,
          ]
        ],
      ),
    );
  }
}

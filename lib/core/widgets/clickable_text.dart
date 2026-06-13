import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ClickableText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign textAlign;

  const ClickableText({
    super.key,
    required this.text,
    this.style,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    final words = text.split(' ');
    final List<TextSpan> spans = [];

    for (var i = 0; i < words.length; i++) {
      final word = words[i];
      final isLast = i == words.length - 1;
      
      // Détection simplifiée d'URL
      if (word.startsWith('http://') || word.startsWith('https://') || word.startsWith('www.')) {
        final url = word.startsWith('www.') ? 'https://$word' : word;
        spans.add(
          TextSpan(
            text: word + (isLast ? '' : ' '),
            style: (style ?? const TextStyle()).copyWith(
              color: Colors.cyanAccent,
              decoration: TextDecoration.underline,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () async {
                final uri = Uri.tryParse(url);
                if (uri != null && await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
          ),
        );
      } else {
        spans.add(TextSpan(text: word + (isLast ? '' : ' ')));
      }
    }

    return RichText(
      textAlign: textAlign,
      text: TextSpan(
        style: style ?? const TextStyle(color: Colors.white, fontSize: 14),
        children: spans,
      ),
    );
  }
}

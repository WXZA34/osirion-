import 'dart:convert';
import 'dart:io';

void main() async {
  final file = File('assets/branding/osirion-logo-animation12.json');
  final jsonStr = await file.readAsString();
  final data = jsonDecode(jsonStr);

  bool modified = false;

  void traverse(dynamic node, dynamic parent, String keyInParent) {
    if (node is Map) {
      if (node.containsKey('a') && node['a'] == 1 && node.containsKey('k')) {
        final k = node['k'];
        if (k is List) {
          if (k.length == 1) {
            // Fix single keyframe
            final kf = k[0];
            if (kf is Map && kf.containsKey('s')) {
              node['a'] = 0;
              node['k'] = kf['s'];
              modified = true;
            }
          } else {
            // Fix missing 'e' in multi-keyframe animations
            for (int i = 0; i < k.length - 1; i++) {
              final kf = k[i];
              if (kf is Map) {
                if (!kf.containsKey('e') || kf['e'] == null) {
                  final nextKf = k[i + 1];
                  if (nextKf is Map && nextKf.containsKey('s')) {
                    kf['e'] = nextKf['s'];
                    modified = true;
                  }
                }
              }
            }
          }
        }
      }
      node.forEach((key, value) {
        if (value is Map || value is List) {
          traverse(value, node, key);
        }
      });
    } else if (node is List) {
      for (int i = 0; i < node.length; i++) {
        final value = node[i];
        if (value is Map || value is List) {
          traverse(value, node, i.toString());
        }
      }
    }
  }

  traverse(data, null, '');

  if (modified) {
    final fixedJson = jsonEncode(data);
    await file.writeAsString(fixedJson);
    print('Lottie JSON successfully repaired!');
  } else {
    print('No repairs needed.');
  }
}

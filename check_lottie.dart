import 'dart:convert';
import 'dart:io';

void main() async {
  final file = File('assets/branding/osirion-logo-animation12.json');
  final jsonStr = await file.readAsString();
  final data = jsonDecode(jsonStr);

  void traverse(dynamic node, String path) {
    if (node is Map) {
      if (node.containsKey('a') && node['a'] == 1 && node.containsKey('k')) {
        final k = node['k'];
        if (k is List) {
          if (k.length == 1) {
            print('Found animated property with 1 keyframe at $path');
            print(k);
          } else {
            for (int i = 0; i < k.length - 1; i++) {
              final kf = k[i];
              if (kf is Map) {
                if (!kf.containsKey('e') || kf['e'] == null) {
                  print('Found keyframe missing "e" at $path[$i]');
                  print(kf);
                }
              }
            }
          }
        }
      }
      node.forEach((key, value) {
        traverse(value, '$path.$key');
      });
    } else if (node is List) {
      for (int i = 0; i < node.length; i++) {
        traverse(node[i], '$path[$i]');
      }
    }
  }

  traverse(data, 'root');
}

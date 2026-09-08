const fs = require('fs');

function replaceConfig(file) {
  let c = fs.readFileSync(file, 'utf8');
  let changed = false;
  
  if (!c.includes("import 'package:valerion/features/dojo/utils/dojo_translator.dart';") && 
      !c.includes("import '../../utils/dojo_translator.dart';") &&
      !c.includes("import '../utils/dojo_translator.dart';")) {
      
    c = "import 'package:valerion/features/dojo/utils/dojo_translator.dart';\n" + c;
  }
  
  // Replace config.name -> DojoTranslator.translate(context, config.name)
  // Be careful to not replace if already wrapped
  if (c.includes('config.name') && !c.includes('DojoTranslator.translate(context, config.name)')) {
    c = c.split('config.name').join('DojoTranslator.translate(context, config.name)');
    changed = true;
  }
  if (c.includes('config.description') && !c.includes('DojoTranslator.translateDescription(context, config.description)')) {
    c = c.split('config.description').join('DojoTranslator.translateDescription(context, config.description)');
    changed = true;
  }
  
  if (c.includes('widget.config.name') && !c.includes('DojoTranslator.translate(context, widget.config.name)')) {
    c = c.split('widget.config.name').join('DojoTranslator.translate(context, widget.config.name)');
    changed = true;
  }
  if (c.includes('widget.config.description') && !c.includes('DojoTranslator.translateDescription(context, widget.config.description)')) {
    c = c.split('widget.config.description').join('DojoTranslator.translateDescription(context, widget.config.description)');
    changed = true;
  }
  
  if (changed) {
    fs.writeFileSync(file, c);
    console.log(`Updated ${file}`);
  }
}

replaceConfig('lib/features/dojo/exercise_selector_screen.dart');
replaceConfig('lib/features/dojo/exercise_demo_screen.dart');
replaceConfig('lib/features/dojo/widgets/recap_dialog.dart');

const fs = require('fs');

const file = 'lib/features/home/widgets/daily_pulse.dart';
let c = fs.readFileSync(file, 'utf8');
if (!c.includes('daily_pulse_translator.dart')) {
  c = c.replace("import '../providers/daily_pulse_provider.dart';", "import '../providers/daily_pulse_provider.dart';\nimport '../utils/daily_pulse_translator.dart';");
}
c = c.replace(/quest\.title/g, 'DailyPulseTranslator.translateTitle(context, quest.title)');
c = c.replace(/quest\.desc/g, 'DailyPulseTranslator.translateDesc(context, quest.desc)');

fs.writeFileSync(file, c);
console.log('Daily Pulse updated');

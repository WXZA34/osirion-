const fs = require('fs');
const path = require('path');

const filesToProcess = [
  'lib/features/pantheon/pantheon_screen.dart',
  'lib/features/laboratory/laboratory_screen.dart',
  'lib/features/library/library_screen.dart',
  'lib/features/dojo/widgets/recap_dialog.dart',
  'lib/features/arsenal/arsenal_screen.dart',
  'lib/features/profile/widgets/focus_timer.dart',
  'lib/features/profile/profile_screen.dart',
  'lib/features/pantheon/widgets/video_message_bubble.dart',
  'lib/features/pantheon/screens/alpha_camera_screen.dart'
];

const replacements = [
  { regex: /Text\(['"]FERMER['"]/g, replace: 'Text(AppLocalizations.of(context)!.commonClose' },
  { regex: /Text\(['"]ANNULER['"]/g, replace: 'Text(AppLocalizations.of(context)!.commonCancel' },
  { regex: /Text\(['"]MODIFIER['"]/g, replace: 'Text(AppLocalizations.of(context)!.commonModify' },
  { regex: /Text\(['"]EFFACER['"]/g, replace: 'Text(AppLocalizations.of(context)!.commonErase' },
  { regex: /Text\(['"]ENVOYER['"]/g, replace: 'Text(AppLocalizations.of(context)!.commonSend' },
  { regex: /Text\(['"]REJOUER['"]/g, replace: 'Text(AppLocalizations.of(context)!.commonReplay' },
  { regex: /Text\(['"]TERMINER['"]/g, replace: 'Text(AppLocalizations.of(context)!.commonFinish' },
  { regex: /Text\(['"]Accepter['"]/g, replace: 'Text(AppLocalizations.of(context)!.commonAccept' },
  { regex: /Text\(['"]SUSPENDRE['"]/g, replace: 'Text(AppLocalizations.of(context)!.commonSuspend' },
  { regex: /Text\(['"]PURGER['"]/g, replace: 'Text(AppLocalizations.of(context)!.commonPurge' },
  { regex: /Text\(['"]Franais['"]/g, replace: 'Text(AppLocalizations.of(context)!.commonFrench' },
  { regex: /Text\(['"]Français['"]/g, replace: 'Text(AppLocalizations.of(context)!.commonFrench' },
  { regex: /Text\(['"]English['"]/g, replace: 'Text(AppLocalizations.of(context)!.commonEnglish' },
  
  // Errors
  { regex: /Text\(['"]Erreur\s*:\s*\$e['"]\)/g, replace: 'Text(AppLocalizations.of(context)!.commonError(e.toString()))' },
  { regex: /Text\(['"]Erreur\s*:\s*\\\$e['"]\)/g, replace: 'Text(AppLocalizations.of(context)!.commonError(e.toString()))' },
  { regex: /Text\(['"]Erreur téléchargement:\s*\$e['"]\)/g, replace: 'Text(AppLocalizations.of(context)!.commonError(e.toString()))' },
  { regex: /Text\(['"]Erreur de récupération\s*:\s*\$e['"]\)/g, replace: 'Text(AppLocalizations.of(context)!.commonError(e.toString()))' },
  { regex: /Text\(['"]Oups, erreur d'envoi\s*:\s*\$cleanMsg['"]\)/g, replace: 'Text(AppLocalizations.of(context)!.commonError(cleanMsg.toString()))' },
  { regex: /Text\(['"]Oups, erreur d'envoi vocal\s*:\s*\$e['"]\)/g, replace: 'Text(AppLocalizations.of(context)!.commonError(e.toString()))' },
  { regex: /Text\(['"]Erreur micro:\s*\$e['"]\)/g, replace: 'Text(AppLocalizations.of(context)!.commonError(e.toString()))' },
  { regex: /Text\(['"]Échec de l'envoi d'une photo:\s*\$e['"]\)/g, replace: 'Text(AppLocalizations.of(context)!.commonError(e.toString()))' },
  { regex: /Text\(['"]Oups, échec de l'envoi vidéo\s*:\s*\$e['"]\)/g, replace: 'Text(AppLocalizations.of(context)!.commonError(e.toString()))' },
  { regex: /Text\(['"]Échec de la suppression\s*:\s*\$e['"]\)/g, replace: 'Text(AppLocalizations.of(context)!.commonError(e.toString()))' },
  { regex: /Text\(['"]Erreur de profil:\s*\\\$e['"]\)/g, replace: 'Text(AppLocalizations.of(context)!.commonError(e.toString()))' },
  { regex: /Text\(['"]Échec de la sauvegarde\s*:\s*\$e['"]\)/g, replace: 'Text(AppLocalizations.of(context)!.commonError(e.toString()))' },
  { regex: /Text\(['"]Échec de l'exportation\s*:\s*\$e['"]\)/g, replace: 'Text(AppLocalizations.of(context)!.commonError(e.toString()))' },
  { regex: /Text\(['"]Erreur lors du nettoyage\s*:\s*\$e['"]\)/g, replace: 'Text(AppLocalizations.of(context)!.commonError(e.toString()))' },
  { regex: /Text\(['"]Erreur de sauvegarde:\s*\$e['"]\)/g, replace: 'Text(AppLocalizations.of(context)!.commonError(e.toString()))' },
  { regex: /Text\(['"]❌ Erreur\s*:\s*\$e['"]\)/g, replace: 'Text(AppLocalizations.of(context)!.commonError(e.toString()))' },
  { regex: /Text\(['"]❌ Erreur purge\s*:\s*\$e['"]\)/g, replace: 'Text(AppLocalizations.of(context)!.commonError(e.toString()))' },
  { regex: /Text\(['"]Échec de la transaction\s*:\s*\$e['"]\)/g, replace: 'Text(AppLocalizations.of(context)!.commonError(e.toString()))' },
];

filesToProcess.forEach(file => {
  const fullPath = path.join('c:/Users/rolan/Videos/application mobile/valerion', file);
  if (fs.existsSync(fullPath)) {
    let content = fs.readFileSync(fullPath, 'utf8');
    
    // Check if AppLocalizations is imported, if not and if we make changes, import it
    let changed = false;
    
    replacements.forEach(r => {
      const newContent = content.replace(r.regex, r.replace);
      if (newContent !== content) {
        content = newContent;
        changed = true;
      }
    });

    if (changed) {
      if (!content.includes('package:flutter_gen/gen_l10n/app_localizations.dart')) {
        content = "import 'package:flutter_gen/gen_l10n/app_localizations.dart';\n" + content;
      }
      fs.writeFileSync(fullPath, content);
      console.log('Updated', file);
    }
  }
});

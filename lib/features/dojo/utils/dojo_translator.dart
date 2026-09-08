import 'package:flutter/material.dart';

class DojoTranslator {
  static String translate(BuildContext context, String text) {
    if (Localizations.localeOf(context).languageCode != 'en') return text;
    
    switch (text) {
      // dojo_screen.dart
      case 'FORCE': return 'STRENGTH';
      case 'ENDURANCE': return 'ENDURANCE';
      
      // recap_dialog.dart coach messages
      case "Commence par te placer devant la caméra. L'IA veille sur toi !": return "Start by positioning yourself in front of the camera. The AI is watching you!";
      case "Bon début ! La régularité forge les champions.": return "Good start! Consistency forges champions.";
      case "Solide. Tu construis une base en béton armé. 💪": return "Solid. You are building a concrete foundation. 💪";
      case "Impressionnant ! Ton moteur tourne à plein régime. 🔥": return "Impressive! Your engine is running at full speed. 🔥";
      case "LÉGENDAIRE ! Tu repousses tes limites à chaque session. 🏆": return "LEGENDARY! You push your limits every session. 🏆";
      
      // recap_dialog.dart others
      case 'SECONDES': return 'SECONDS';
      
      // Exercise Names
      case "Tractions à un bras": return "One-arm pull-ups";
      case "Pompes à un bras": return "One-arm push-ups";
      case "Pompes en poirier": return "Handstand push-ups";
      case "Tractions sautées": return "Jumping pull-ups";
      case "Pompes claquées": return "Clapping push-ups";
      case "Squats sautés": return "Jump squats";
      case "Fentes sautées": return "Jumping lunges";
      case "Sauts de singe": return "Monkey jumps";
      case "Tractions lestées": return "Weighted pull-ups";
      case "Tractions machine à écrire": return "Typewriter pull-ups";
      case "Pompes Diamant": return "Diamond push-ups";
      case "Tractions en supination": return "Chin-ups";
      case "Pompes en équilibre": return "Handstand push-ups";
      case "Tractions pronation": return "Pull-ups";
      case "Pompes classiques": return "Push-ups";
      case "Dips sur barres parallèles": return "Parallel bar dips";
      case "Tractions australiennes": return "Australian pull-ups";
      case "Pompes larges": return "Wide push-ups";
      case "Pompes déclinées": return "Decline push-ups";
      case "Pompes surélevées": return "Incline push-ups";
      case "Tractions prise serrée": return "Close-grip pull-ups";
      case "Shadow boxing très rapide": return "Fast shadow boxing";
      case "Squats Cosaques": return "Cossack squats";
      case "Fentes Bulgares": return "Bulgarian split squats";
      case "Élévations de mollets à une jambe": return "Single-leg calf raises";
      case "Squats profonds avec une pause isométrique de 10 secondes en bas": return "Deep squats with 10s isometric hold";
      case "Fentes avant marchées": return "Walking lunges";
      case "Squats poids du corps": return "Bodyweight squats";
      case "Fentes sautées alternées": return "Alternating jumping lunges";
      case "Sauts de patineur": return "Skater jumps";
      case "Sprint navette": return "Shuttle sprint";
      case "Fentes marchées": return "Walking lunges";
      case "Élévations de mollets à deux jambes": return "Two-leg calf raises";
      case "Course en gradins ou escaliers": return "Stair running";
      case "Relevés de jambes à la barre fixe": return "Toes to bar";
      case "Essuie-glaces suspendus à la barre": return "Windshield wipers";
      case "Planche Lean": return "Planche lean";
      case "Relevés de genoux obliques à la barre": return "Oblique knee raises";
      case "Gainage cuillère": return "Hollow body hold";
      case "Mountain Climbers croisés": return "Cross mountain climbers";
      case "Ciseaux croisés au sol": return "Scissor kicks";
      case "Gainage latéral": return "Side plank";
      case "Relevés de genoux suspendus à la barre": return "Hanging knee raises";
      case "Crunches inversés": return "Reverse crunches";
      case "Tractions scapulaires": return "Scapular pull-ups";
      case "Maintien isométrique en bas des Dips": return "Isometric hold at bottom of dips";
      case "Maintien isométrique menton au-dessus de la barre": return "Isometric hold chin over bar";
      case "Maintien isométrique en fente": return "Isometric lunge hold";
      case "Planche latérale étoile": return "Star side plank";
      case "Suspension passive à la barre": return "Passive bar hang";
      case "Rotations d'épaules": return "Shoulder rotations";
      case "Step-ups très lents": return "Very slow step-ups";
      case "Montées sur pointes de pieds à deux pieds au sol": return "Calf raises on toes";
      case "Élévations frontales et latérales à vide": return "Empty front and lateral raises";
      case "Shadow boxing très lent et relâché": return "Slow and relaxed shadow boxing";
      
            case "Dips aux anneaux ou Dips bulgares": return "Ring dips or Bulgarian dips";
      case "Pompes Pseudo-Planche": return "Pseudo-Planche Push-ups";
      case "Dips sur banc": return "Bench dips";
      case "Glute Bridge unilatéral": return "Unilateral Glute Bridge";
      case "Step-ups explosifs": return "Explosive step-ups";
      case "Crunches classiques au sol": return "Classic crunches";
      case "Bicyclette": return "Bicycle crunches";
      case "Gainage coudes": return "Elbow plank";
      case "Jackknives assis sur un banc de parc": return "Seated jackknives on a park bench";
      case "Chaise contre un poteau ou muret": return "Wall sit against a pole or wall";
      case "Pont": return "Bridge";
      case "Maintien de fausse prise": return "False grip hold";
      case "Élévations de mollets unilatérales": return "Unilateral calf raises";
      case "Pompes au mur": return "Wall push-ups";
      case "Tractions australiennes très inclinées": return "Very inclined Australian pull-ups";
      case "Step-ups très lents et sans élan sur un tout petit trottoir": return "Very slow step-ups on a curb";
      case "Balanciers de jambe": return "Leg swings";
      case "Rotations du buste debout": return "Standing torso rotations";
      case "Flexions/extensions de poignets dans le vide": return "Empty wrist flexions/extensions";

      // Fallback
      default: 
        if (text.startsWith("Erreur lecteur vidéo : ")) {
          return text.replaceFirst("Erreur lecteur vidéo : ", "Video player error: ");
        }
        if (text == "Vidéo ignorée par l'utilisateur.") {
          return "Video skipped by user.";
        }
        return text;
    }
  }
  
  static String translateDescription(BuildContext context, String text) {
    if (Localizations.localeOf(context).languageCode != 'en') return text;
    if (text == "Renforcement spécifique.") return "Specific strengthening.";
    if (text == "stricts, sans élan") return "strict, no momentum";
    if (text == "maintien isométrique ou tirages") return "isometric hold or pulls";
    if (text == "maintien isométrique") return "isometric hold";
    if (text == "ou Archer pull-ups très lentes") return "or very slow Archer pull-ups";
    if (text == "ou Archer push-ups") return "or Archer push-ups";
    if (text == "très lents, contrôle de la descente") return "very slow, controlled descent";
    if (text == "descente contrôlée au maximum") return "maximally controlled descent";
    if (text == "sur barre droite") return "on straight bar";
    if (text == "pieds bloqués sous la barre basse du parc") return "feet locked under a low bar";
    if (text == "avec pompe et saut") return "with push-up and jump";
    if (text == "rythme sprint") return "sprint pace";
    if (text == "Marche de l'ours sur la longueur du spot") return "Bear crawl across the area";
    if (text == "Burpees sans la pompe") return "Burpees without push-up";
    if (text == "avec élan, pour enchaîner les reps") return "with momentum, to chain reps";
    if (text == "Sauts genoux poitrine") return "Knees to chest jumps";
    if (text == "Monkey jumps / déplacements latéraux au sol") return "Monkey jumps / lateral ground movements";
    if (text == "PPPU - mains au niveau des hanches") return "PPPU - hands at hip level";
    if (text == "si tu as un gilet") return "if you have a vest";
    if (text == "Dips avec passage sur les coudes") return "Dips with elbow transition";
    if (text == "Extensions triceps au sol, poids du corps") return "Bodyweight tricep extensions on the floor";
    if (text == "sur parallettes ou au sol") return "on parallettes or floor";
    if (text == "Tirages bras tendus de la verticale à l'horizontale") return "Straight arm pulls from vertical to horizontal";
    if (text == "tempo très lent : 4 sec descente, 2 sec pause") return "very slow tempo: 4s descent, 2s pause";
    if (text == "aux anneaux ou sous une barre basse") return "on rings or under a low bar";
    if (text == "extensions triceps sur barres parallèles") return "tricep extensions on parallel bars";
    if (text == "séries max") return "max sets";
    if (text == "rythme rapide") return "fast pace";
    if (text == "Rowing poids du corps sous une barre basse") return "Bodyweight rows under a low bar";
    if (text == "mains très écartées") return "hands very wide";
    if (text == "Tractions prise alternée d'un côté et de l'autre de la barre") return "Pull-ups with alternating grip side to side";
    if (text == "pieds sur un banc ou un muret") return "feet on a bench or wall";
    if (text == "mains sur un banc") return "hands on a bench";
    if (text == "Pompes piquées pour les épaules, rythme soutenu") return "Pike push-ups for shoulders, fast pace";
    if (text == "focus sur l'engagement des bras et épaules") return "focus on arm and shoulder engagement";
    if (text == "descendre jusqu'au mollet") return "go down to the calf";
    if (text == "unilatéral, genou arrière touche le sol") return "unilateral, back knee touches the ground";
    if (text == "fentes latérales très profondes et lentes") return "very deep and slow lateral lunges";
    if (text == "pied arrière sur le banc du parc, descente lente") return "back foot on bench, slow descent";
    if (text == "focus quadriceps extrême, poids du corps vers l'arrière") return "extreme quad focus, bodyweight shifted back";
    if (text == "au sol, si tu peux bloquer tes chevilles") return "on the ground, if you can lock your ankles";
    if (text == "sur le bord d'un trottoir, maintien en haut") return "on a curb, hold at the top";
    if (text == "Fentes sans jamais poser le genou au sol ni tendre la jambe") return "Lunges without ever touching knee or locking leg";
    if (text == "Squats sur la pointe des pieds, talons collés") return "Squats on toes, heels touching";
    if (text == "au sol, poussée lente du bassin") return "on the ground, slow hip thrust";
    if (text == "tempo très lent, pas de rebond") return "very slow tempo, no bouncing";
    if (text == "séries de 50 à 100 reps") return "sets of 50 to 100 reps";
    if (text == "Sauts sur un muret ou un gros bloc") return "Jumps onto a wall or large block";
    if (text == "Sauts en longueur à pieds joints dans l'herbe") return "Broad jumps in the grass";
    if (text == "montées rapides sur un banc") return "fast step-ups on a bench";
    if (text == "Skater jumps latéraux") return "Lateral skater jumps";
    if (text == "aller-retour sur 10 mètres") return "back and forth over 10 meters";
    if (text == "rythme très rapide") return "very fast pace";
    if (text == "Montées de genoux sur place à vitesse max") return "High knees in place at max speed";
    if (text == "rebonds rapides") return "fast bounces";
    if (text == "si disponibles près du spot") return "if available near the area";
    if (text == "sur un banc") return "on a bench";
    if (text == "évolution du L-sit, jambes levées plus haut") return "V-sit, legs raised higher";
    if (text == "Essuie-glaces suspendus à la barre") return "Windshield wipers hanging from the bar";
    if (text == "maintien ou tentatives") return "hold or attempts";
    if (text == "Planche penchée au maximum en avant, bassin rétroversé") return "Maximum forward lean planche, retroverted pelvis";
    if (text == "avec des anneaux ras du sol ou un t-shirt glissant sur l'herbe") return "with low rings or sliding t-shirt on grass";
        if (text == "Tuck planche, Straddle ou Full") return "Tuck planche, Straddle or Full";
    if (text == "Handstand push-ups - HSPU") return "Handstand push-ups - HSPU";
    if (text == "Drapeau") return "Flag";
    if (text == "HSPU") return "HSPU";
    if (text == "Bench dips") return "Bench dips";
    if (text == "maintien isométrique au sol ou sur parallettes") return "isometric hold on floor or parallettes";
    if (text == "Relevés de genoux obliques à la barre, avec pause") return "Oblique knee raises on bar, with pause";
    if (text == "Gainage cuillère, bas du dos plaqué, maintien long") return "Hollow body hold, lower back flat, long hold";
    if (text == "Petits battements en position de Dragon Flag") return "Small flutters in Dragon Flag position";
    if (text == "engage massivement les lombaires et la ceinture abdo") return "massively engages lower back and core";
    if (text == "Bicycle crunches") return "Bicycle crunches";
    if (text == "Planche - tenir le temps maximum") return "Plank - hold for max time";
    if (text == "genou vers coude opposé") return "knee to opposite elbow";
    if (text == "Portefeuille rapide") return "Fast V-ups";
    if (text == "Battements de jambes au sol, ras de l'herbe") return "Flutter kicks on ground";
    if (text == "sans poids, focus sur la vitesse de rotation") return "no weight, focus on rotation speed";
    if (text == "Knee raises, rythme rapide") return "Knee raises, fast pace";
    if (text == "Tractions scapulaires, bras tendus, haussements d'épaules") return "Scapular pull-ups, straight arms, shrugs";
    if (text == "Pompes scapulaires au sol") return "Scapular push-ups on floor";
    if (text == "étirement actif des pecs/épaules") return "active stretch for pecs/shoulders";
    if (text == "Lock-off") return "Lock-off";
    if (text == "Wall sit") return "Wall sit";
    if (text == "Bridge hold") return "Bridge hold";
    if (text == "False grip") return "False grip";
    if (text == "Pompes sur les poignets ou dos des mains, sur les genoux") return "Wrist push-ups on knees";
    if (text == "maintien de 10 sec en contraction maximale") return "10 sec hold in max contraction";
    if (text == "suspension inversée aux anneaux/barre, étirement actif des épaules") return "inverted hang on rings/bar, active shoulder stretch";
    if (text == "genou arrière à 1 cm du sol") return "back knee 1 cm from ground";
    if (text == "Star plank") return "Star plank";
    if (text == "Suspension passive à la barre - le plus longtemps possible pour décompresser") return "Passive bar hang - as long as possible to decompress";
    if (text == "Wall push-ups - séries très longues, effort minime") return "Wall push-ups - very long sets, minimal effort";
    if (text == "Arm circles à vide - séries de 100") return "Empty arm circles - sets of 100";
    if (text == "presque debout, tirages légers") return "almost standing, light pulls";
    if (text == "Leg swings avant/arrière et latéraux pour la hanche") return "Leg swings forward/back and lateral for hips";
    if (text == "Twists légers") return "Light twists";
    if (text == "pour les avant-bras") return "for forearms";
    if (text == "moulinage très rapide et léger") return "very fast and light circling";
    if (text == "Dos rond / Dos creux au sol sur l'herbe") return "Cat-cow on the grass";
    if (text == "sans poids, focus sur le mouvement") return "no weight, focus on movement";
    if (text == "Flow, déliement articulaire") return "Flow, joint mobility";
    return text;
  }
}

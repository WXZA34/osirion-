const fs = require('fs');

const path = 'lib/l10n/app_en.arb';
let raw = fs.readFileSync(path, 'utf8');
let json = JSON.parse(raw);

const translations = {
  "pantheonUploadDuLogoEn": "Uploading logo...",
  "pantheonLogoDuClanMis": "Clan logo updated!",
  "pantheonLePanthOn": "THE PANTHEON",
  "pantheonChangerVotreStatut": "CHANGE YOUR STATUS",
  "pantheonAucunCanalActifNrejoignez": "NO ACTIVE CHANNEL.\nJOIN A CLAN OR ADD FRIENDS.",
  "pantheonRechercherUnAlpha": "SEARCH FOR AN ALPHA",
  "pantheonAucunAlphaTrouv": "No Alpha found",
  "pantheonEnAttente": "PENDING",
  "pantheonModuleEnCoursDe": "MODULE UNDER DEVELOPMENT",
  "pantheonLeCentreDeCommandement": "The OSIRION strategic command center is coming soon. Prepare your clans for territorial conquest.",
  "pantheonAucunImmortelTrouv": "No immortal found...",
  "pantheonFonderUnNouveauClan": "FOUND A NEW CLAN",
  "pantheonAucunClanNExiste": "No clan exists yet...",
  "pantheonVousNeFaitesPartie": "You are not part of any clan.\nJoin one via the leaderboards or found your own!",
  "pantheonForgerUnNouveauClan": "FORGE A NEW CLAN",
  "pantheonCrErLeClan": "CREATE CLAN",
  "pantheonDissoudreLeClan": "Disband Clan",
  "pantheonLeClanAT": "The clan was successfully disbanded.",
  "pantheonQuitterLeClan": "Leave Clan",
  "pantheonActionRequise": "Action Required",
  "pantheonNouvelleDemandeLancE": "New request sent!",
  "pantheonRInviter": "RE-INVITE",
  "pantheonLAccSAu": "Microphone access is required in your phone settings.",
  "pantheonPermissionMicroRefusE": "Microphone permission denied.",
  "pantheonPrendreUnePhoto": "Take a photo",
  "pantheonPhotosGalerie": "Photos (Gallery)",
  "pantheonVidOclip15sMax": "Video clip (15s max)",
  "pantheonChargementDuProfil": "Loading profile...",
  "pantheonChatIndisponibleMockup": "Chat unavailable (Mockup)",
  "pantheonCodageH264R": "H.264 Encoding & Bitrate Reduction",
  "pantheonEffacerDFinitivement": "Delete permanently?",
  "pantheonCeMessageSeraSupprim": "This message will be deleted for everyone and will be unrecoverable from the database.",
  "pantheonMessageEffacDFinitivement": "Message permanently deleted.",
  "pantheonDButDeLa": "Start of alpha secure conversation.",
  "pantheonTLChargementDe": "Downloading photo...",
  "pantheonPhotoEnregistrE": "Photo saved! ✅",
  "pantheonVousDevezTreChef": "You must be a leader to recruit.",
  "pantheonRecruterAmis": "RECRUIT / FRIENDS",
  "pantheonRetirerDesAmis": "Remove from friends?",
  "pantheonVoulezVousGalementEffacer": "Do you also want to permanently delete all your conversation history?",
  "pantheonGarderChat": "KEEP CHAT",
  "pantheonEffacerTout": "DELETE ALL",
  "pantheonRetirerDeMesAmis": "REMOVE FROM MY FRIENDS",
  "pantheonLeCrAteurNe": "The creator cannot be banned.",
  "pantheonAucunMembreTrouv": "No member found.",
  "pantheonDemandeDAdhSion": "Join request sent!",
  "pantheonEnregistrerDansLaPellicule": "Save to camera roll",
  "pantheonRechercherUneFaction": "SEARCH FOR A FACTION...",
  "pantheonExLesSpartiatesDu": "Ex: The Park Spartans",
  "pantheonTransmettreUnMessage": "Transmit a message...",
  "pantheonAlphaCam": "ALPHA CAM",
  "pantheonVidOEnregistrE": "Video saved to camera roll! ✅"
};

for (const [key, value] of Object.entries(translations)) {
  if (json[key] !== undefined) {
    json[key] = value;
  }
}

fs.writeFileSync(path, JSON.stringify(json, null, 2));
console.log('Pantheon translations applied.');

import 'package:flutter/material.dart';
import 'package:valerion/l10n/app_localizations.dart';
class BookEntity {
  final String id;
  final String title;
  final String author;
  final String tag;
  final String theme;
  final String whyRead;
  final String keyPhrase;
  final String? pdfPath; // Chemin local du fichier PDF
  final String? thumbnailUrl; // URL directe ou chemin d'asset de la couverture
  final String arc; // 'Winter Arc', 'Summer Body', 'Royal Arc'

  BookEntity({
    required this.id,
    required this.title,
    required this.author,
    required this.tag,
    required this.theme,
    required this.whyRead,
    required this.keyPhrase,
    required this.arc,
    this.pdfPath,
    this.thumbnailUrl,
  });

  factory BookEntity.fromMap(String id, Map<String, dynamic> map) {
    return BookEntity(
      id: id,
      title: map['title'] ?? '',
      author: map['author'] ?? '',
      tag: map['tag'] ?? '',
      theme: map['theme'] ?? '',
      whyRead: map['whyRead'] ?? '',
      keyPhrase: map['keyPhrase'] ?? '',
      arc: map['arc'] ?? 'Winter Arc',
      pdfPath: map['pdfPath'],
      thumbnailUrl: map['thumbnailUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'author': author,
      'tag': tag,
      'theme': theme,
      'whyRead': whyRead,
      'keyPhrase': keyPhrase,
      'arc': arc,
      'pdfPath': pdfPath,
      'thumbnailUrl': thumbnailUrl,
    };
  }
}

// Données statiques de la Bibliothèque
Map<String, List<BookEntity>> getLibraryCatalog(BuildContext context) {
  return {
  'Winter Arc': [
    BookEntity(
      id: "b_hagakure",
      title: AppLocalizations.of(context)!.bookHagakureTitle,
      author: "Yamamoto Tsunetomo",
      tag: AppLocalizations.of(context)!.bookHagakureTag,
      theme: AppLocalizations.of(context)!.bookHagakureTheme,
      whyRead:
          AppLocalizations.of(context)!.bookHagakureWhyRead,
      keyPhrase:
          AppLocalizations.of(context)!.bookHagakureKeyPhrase,
      arc: "Winter Arc",
      pdfPath: "assets/books/hagakure.pdf",
      thumbnailUrl: "assets/images/covers/b_hagakure.webp",
    ),
    BookEntity(
      id: "b_obstacle",
      title: AppLocalizations.of(context)!.bookObstacleTitle,
      author: "Ryan Holiday",
      tag: AppLocalizations.of(context)!.bookObstacleTag,
      theme: AppLocalizations.of(context)!.bookObstacleTheme,
      whyRead:
          AppLocalizations.of(context)!.bookObstacleWhyRead,
      keyPhrase:
          AppLocalizations.of(context)!.bookObstacleKeyPhrase,
      arc: "Winter Arc",
      pdfPath: "assets/books/obstacle.pdf",
      thumbnailUrl: "assets/images/covers/b_obstacle.webp",
    ),
    BookEntity(
      id: "b_epictete",
      title: AppLocalizations.of(context)!.bookEpicteteTitle,
      author: "Épictète",
      tag: AppLocalizations.of(context)!.bookObstacleTag,
      theme: AppLocalizations.of(context)!.bookEpicteteTheme,
      whyRead:
          AppLocalizations.of(context)!.bookEpicteteWhyRead,
      keyPhrase:
          AppLocalizations.of(context)!.bookEpicteteKeyPhrase,
      arc: "Winter Arc",
      pdfPath: "assets/books/epictete_manuel.pdf",
      thumbnailUrl: "assets/images/covers/b_epictete.webp",
    ),
    BookEntity(
      id: "b_aurele",
      title: AppLocalizations.of(context)!.bookAureleTitle,
      author: "Marc Aurèle",
      tag: AppLocalizations.of(context)!.bookObstacleTag,
      theme: AppLocalizations.of(context)!.bookAureleTheme,
      whyRead:
          AppLocalizations.of(context)!.bookAureleWhyRead,
      keyPhrase:
          AppLocalizations.of(context)!.bookAureleKeyPhrase,
      arc: "Winter Arc",
      pdfPath: "assets/books/aurele_pensees.pdf",
      thumbnailUrl: "assets/images/covers/b_aurele.webp",
    ),
    BookEntity(
      id: "b_seneque_temps",
      title: AppLocalizations.of(context)!.bookSenequeTempsTitle,
      author: "Sénèque",
      tag: AppLocalizations.of(context)!.bookObstacleTag,
      theme: AppLocalizations.of(context)!.bookSenequeTempsTheme,
      whyRead:
          AppLocalizations.of(context)!.bookSenequeTempsWhyRead,
      keyPhrase:
          AppLocalizations.of(context)!.bookSenequeTempsKeyPhrase,
      arc: "Winter Arc",
      pdfPath: "assets/books/seneque_brievete.pdf",
      thumbnailUrl: "assets/images/covers/b_seneque_temps.webp",
    ),
    BookEntity(
      id: "b_seneque_ame",
      title: AppLocalizations.of(context)!.bookSenequeAmeTitle,
      author: "Sénèque",
      tag: AppLocalizations.of(context)!.bookObstacleTag,
      theme: AppLocalizations.of(context)!.bookSenequeAmeTheme,
      whyRead:
          AppLocalizations.of(context)!.bookSenequeAmeWhyRead,
      keyPhrase:
          AppLocalizations.of(context)!.bookSenequeAmeKeyPhrase,
      arc: "Winter Arc",
      pdfPath: "assets/books/seneque_tranquillite.pdf",
      thumbnailUrl: "assets/images/covers/b_seneque_ame.webp",
    ),
    BookEntity(
      id: "b_boece",
      title: AppLocalizations.of(context)!.bookBoeceTitle,
      author: "Boèce",
      tag: AppLocalizations.of(context)!.bookObstacleTag,
      theme: AppLocalizations.of(context)!.bookBoeceTheme,
      whyRead:
          AppLocalizations.of(context)!.bookBoeceWhyRead,
      keyPhrase:
          AppLocalizations.of(context)!.bookBoeceKeyPhrase,
      arc: "Winter Arc",
      pdfPath: "assets/books/boece_consolation.pdf",
      thumbnailUrl: "assets/images/covers/b_boece.webp",
    ),
  ],
  'Summer Body': [
    BookEntity(
      id: "b_atomic",
      title: AppLocalizations.of(context)!.bookAtomicTitle,
      author: "James Clear",
      tag: AppLocalizations.of(context)!.bookAtomicTag,
      theme: AppLocalizations.of(context)!.bookAtomicTheme,
      whyRead:
          AppLocalizations.of(context)!.bookAtomicWhyRead,
      keyPhrase:
          AppLocalizations.of(context)!.bookAtomicKeyPhrase,
      arc: "Summer Body",
      thumbnailUrl: "assets/images/covers/b_atomic.webp",
    ),
    BookEntity(
      id: "b_le_bon",
      title: AppLocalizations.of(context)!.bookLeBonTitle,
      author: "Gustave Le Bon",
      tag: AppLocalizations.of(context)!.bookLeBonTag,
      theme: AppLocalizations.of(context)!.bookLeBonTheme,
      whyRead:
          AppLocalizations.of(context)!.bookLeBonWhyRead,
      keyPhrase:
          AppLocalizations.of(context)!.bookLeBonKeyPhrase,
      arc: "Summer Body",
      pdfPath: "assets/books/le_bon_foules.pdf",
      thumbnailUrl: "assets/images/covers/b_le_bon.webp",
    ),
    BookEntity(
      id: "b_schopenhauer",
      title: AppLocalizations.of(context)!.bookSchopenhauerTitle,
      author: "Arthur Schopenhauer",
      tag: AppLocalizations.of(context)!.bookLeBonTag,
      theme: AppLocalizations.of(context)!.bookSchopenhauerTheme,
      whyRead:
          AppLocalizations.of(context)!.bookSchopenhauerWhyRead,
      keyPhrase:
          AppLocalizations.of(context)!.bookSchopenhauerKeyPhrase,
      arc: "Summer Body",
      pdfPath: "assets/books/schopenhauer_raison.pdf",
      thumbnailUrl: "assets/images/covers/b_schopenhauer.webp",
    ),
    BookEntity(
      id: "b_la_bruyere",
      title: AppLocalizations.of(context)!.bookLaBruyereTitle,
      author: "Jean de La Bruyère",
      tag: AppLocalizations.of(context)!.bookLeBonTag,
      theme: AppLocalizations.of(context)!.bookLaBruyereTheme,
      whyRead:
          AppLocalizations.of(context)!.bookLaBruyereWhyRead,
      keyPhrase:
          AppLocalizations.of(context)!.bookLaBruyereKeyPhrase,
      arc: "Summer Body",
      pdfPath: "assets/books/la_bruyere_caracteres.pdf",
      thumbnailUrl: "assets/images/covers/b_la_bruyere.webp",
    ),
    BookEntity(
      id: "b_la_rochefoucauld",
      title: AppLocalizations.of(context)!.bookRochefoucauldTitle,
      author: "François de La Rochefoucauld",
      tag: AppLocalizations.of(context)!.bookLeBonTag,
      theme: AppLocalizations.of(context)!.bookRochefoucauldTheme,
      whyRead:
          AppLocalizations.of(context)!.bookRochefoucauldWhyRead,
      keyPhrase: AppLocalizations.of(context)!.bookRochefoucauldKeyPhrase,
      arc: "Summer Body",
      pdfPath: "assets/books/rochefoucauld_maximes.pdf",
      thumbnailUrl: "assets/images/covers/b_la_rochefoucauld.webp",
    ),
    BookEntity(
      id: "b_balzac",
      title: AppLocalizations.of(context)!.bookBalzacTitle,
      author: "Honoré de Balzac",
      tag: AppLocalizations.of(context)!.bookLeBonTag,
      theme: AppLocalizations.of(context)!.bookBalzacTheme,
      whyRead:
          AppLocalizations.of(context)!.bookBalzacWhyRead,
      keyPhrase:
          AppLocalizations.of(context)!.bookBalzacKeyPhrase,
      arc: "Summer Body",
      pdfPath: "assets/books/rochefoucauld_maximes.pdf", // TEMPORAIRE : balzac_elegance.pdf retiré pour l'App Bundle
      thumbnailUrl: "assets/images/covers/b_balzac.webp",
    ),
  ],
  'Royal Arc': [
    BookEntity(
      id: "b_art_of_war",
      title: AppLocalizations.of(context)!.bookArtOfWarTitle,
      author: "Sun Tzu",
      tag: AppLocalizations.of(context)!.bookArtOfWarTag,
      theme: AppLocalizations.of(context)!.bookArtOfWarTheme,
      whyRead:
          AppLocalizations.of(context)!.bookArtOfWarWhyRead,
      keyPhrase:
          AppLocalizations.of(context)!.bookArtOfWarKeyPhrase,
      arc: "Royal Arc",
      pdfPath: "assets/books/sun_tzu_art_de_la_guerre_.pdf",
      thumbnailUrl: "assets/images/covers/b_art_of_war.webp",
    ),
    BookEntity(
      id: "b_machaivel",
      title: AppLocalizations.of(context)!.bookMachiavelTitle,
      author: "Nicolas Machiavel",
      tag: AppLocalizations.of(context)!.bookArtOfWarTag,
      theme: AppLocalizations.of(context)!.bookMachiavelTheme,
      whyRead:
          AppLocalizations.of(context)!.bookMachiavelWhyRead,
      keyPhrase:
          AppLocalizations.of(context)!.bookMachiavelKeyPhrase,
      arc: "Royal Arc",
      pdfPath: "assets/books/machiavel_le_prince.pdf",
      thumbnailUrl: "assets/images/covers/b_machiavel.webp",
    ),
    BookEntity(
      id: "b_musashi",
      title: AppLocalizations.of(context)!.bookMusashiTitle,
      author: "Miyamoto Musashi",
      tag: AppLocalizations.of(context)!.bookMusashiTag,
      theme: AppLocalizations.of(context)!.bookMusashiTheme,
      whyRead:
          AppLocalizations.of(context)!.bookMusashiWhyRead,
      keyPhrase: AppLocalizations.of(context)!.bookMusashiKeyPhrase,
      arc: "Royal Arc",
      pdfPath: "assets/books/musashi_cinq_roues.pdf",
      thumbnailUrl: "assets/images/covers/b_musashi.webp",
    ),
    BookEntity(
      id: "b_lao_tseu",
      title: AppLocalizations.of(context)!.bookLaoTseuTitle,
      author: "Lao-Tseu",
      tag: AppLocalizations.of(context)!.bookMusashiTag,
      theme: AppLocalizations.of(context)!.bookLaoTseuTheme,
      whyRead:
          AppLocalizations.of(context)!.bookLaoTseuWhyRead,
      keyPhrase:
          AppLocalizations.of(context)!.bookLaoTseuKeyPhrase,
      arc: "Royal Arc",
      pdfPath: "assets/books/lao_tseu_tao.pdf",
      thumbnailUrl: "assets/images/covers/b_lao_tseu.webp",
    ),
    BookEntity(
      id: "b_castiglione",
      title: AppLocalizations.of(context)!.bookCastiglioneTitle,
      author: "Baldassare Castiglione",
      tag: AppLocalizations.of(context)!.bookMusashiTag,
      theme: AppLocalizations.of(context)!.bookCastiglioneTheme,
      whyRead:
          AppLocalizations.of(context)!.bookCastiglioneWhyRead,
      keyPhrase:
          AppLocalizations.of(context)!.bookCastiglioneKeyPhrase,
      arc: "Royal Arc",
      pdfPath: "assets/books/castiglione_courtisan.pdf",
      thumbnailUrl: "assets/images/covers/b_castiglione.webp",
    ),
  ],
};
}

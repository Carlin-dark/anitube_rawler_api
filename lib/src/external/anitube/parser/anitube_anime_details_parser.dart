import 'package:html/dom.dart';
import 'package:html/parser.dart';
import '../../../domain/entities/Item.dart';
import '../../../domain/exceptions/CrawlerApiException.dart';
import '../../../domain/entities/AnimeDetails.dart';
import '../../../domain/entities/parser/ihtml_parser.dart';

class AnitubeAnimeDetailsParser implements IHTMLParser<AnimeDetails> {
  @override
  AnimeDetails parseHTML(String? html) {
    if (html == null) throw ParserException(message: "Null html data");

    try {
      Document doc = parse(html);
      var bodies = doc.getElementsByTagName('body');
      if (bodies.isEmpty) {
        throw ParserException(message: "Empty HTML body");
      }
      var body = bodies[0];

      var animeTitle = _parseAnimeTitle(body);
      var coverElement = doc.getElementById(_AnimeDetailsPageNames.ID_ANIME_COVER);
      var coverImg = coverElement?.querySelector('img');
      var imageUrl = coverImg?.attributes['src'] ??
          coverImg?.attributes['data-src'] ??
          '';

      var resume =
          doc.getElementById(_AnimeDetailsPageNames.ID_RESUME)?.text.trim() ??
              '';

      var infoBoxes =
          body.getElementsByClassName(_AnimeDetailsPageNames.ANIME_BOX_ABOUT_IT);
      var infoMap = infoBoxes.isNotEmpty
          ? _parseAnimeInfo(infoBoxes[0])
          : <String, dynamic>{};

      var containers = body.getElementsByClassName(
          _AnimeDetailsPageNames.ANIME_EPISODES_CONTAINER);

      List> episodesItemList = [];

      if (containers.isNotEmpty) {
        final anchors = containers[0].querySelectorAll('a').isNotEmpty
            ? containers[0].querySelectorAll('a')
            : containers[0].children;

        episodesItemList = anchors.map>((anchor) {
          final href = anchor.attributes['href'] ?? '';
          final uri = Uri.tryParse(href);
          final segments = (uri?.pathSegments ?? href.split('/'))
              .where((s) => s.isNotEmpty)
              .toList();
          final epId = segments.isNotEmpty ? segments.last : '';

          final epTitle = anchor.attributes['title']?.trim().isNotEmpty == true
              ? anchor.attributes['title']!.trim()
              : anchor.text.trim();

          return {
            Item.ID: epId,
            Item.TITLE: epTitle,
            Item.PAGE_URL: href,
            Item.IMAGE_URL: imageUrl,
            Item.CC: infoMap[AnimeDetails.CC] ?? 'Legendado',
          };
        }).toList();
      }

      return AnimeDetails.fromJson({
        AnimeDetails.TITLE: animeTitle,
        AnimeDetails.IMAGE_URL: imageUrl,
        AnimeDetails.DESCRIPTION: resume,
        AnimeDetails.EPISODES_LIST: episodesItemList,
        AnimeDetails.EPISODES_NUMBER: episodesItemList.length.toString(),
        AnimeDetails.FORMAT: infoMap[AnimeDetails.FORMAT] ?? "",
        AnimeDetails.DIRECTOR: infoMap[AnimeDetails.DIRECTOR] ?? "",
        AnimeDetails.STUDIO: infoMap[AnimeDetails.STUDIO] ?? "",
        AnimeDetails.GENRE: infoMap[AnimeDetails.GENRE] ?? "",
        AnimeDetails.AUTHOR: infoMap[AnimeDetails.AUTHOR] ?? "",
        AnimeDetails.CC: infoMap[AnimeDetails.CC] ?? "",
        AnimeDetails.YEAR: infoMap[AnimeDetails.YEAR] ?? "",
        AnimeDetails.MOVIES: infoMap[AnimeDetails.MOVIES] ?? "",
        AnimeDetails.OVAS: infoMap[AnimeDetails.OVAS] ?? "",
      });
    } catch (ex) {
      print("AnimeDetailsPageParser\n$ex");
      throw ParserException(message: "Error parsing anime details page.");
    }
  }

  String _parseAnimeTitle(Element body) {
    final titleBlocks =
        body.getElementsByClassName(_AnimeDetailsPageNames.TITLE_ELEMENT);
    if (titleBlocks.isNotEmpty) {
      final h1 = titleBlocks[0].querySelector('h1');
      if (h1 != null && h1.text.trim().isNotEmpty) {
        return h1.text.trim();
      }
      if (titleBlocks[0].text.trim().isNotEmpty) {
        return titleBlocks[0].text.trim();
      }
    }
    final fallbackH1 = body.querySelector('h1');
    return fallbackH1?.text.trim() ?? '';
  }

  Map<String, dynamic> _parseAnimeInfo(Element infoContainer) {
    var infoChildren = infoContainer
        .getElementsByClassName(_AnimeDetailsPageNames.ANIME_BOX_INFO);

    Map<String, dynamic> map = {};

    for (final element in infoChildren) {
      final text = element.text.trim();
      final colonIndex = text.indexOf(':');
      if (colonIndex > 0) {
        final key = text.substring(0, colonIndex).trim();
        final value = text.substring(colonIndex + 1).trim();
        map.putIfAbsent(key, () => value);
      }
    }

    return map;
  }
}

class _AnimeDetailsPageNames {
  static const TITLE_ELEMENT = "pagAniTitulo";
  static const ID_ANIME_COVER = "capaAnime";
  static const ID_RESUME = "sinopse2";

  static const ANIME_BOX_ABOUT_IT = "boxAnimeSobre";
  static const ANIME_BOX_INFO = "boxAnimeSobreLinha";
  static const ANIME_VIDEO_LIST = "pagAniLista";
  static const ANIME_EPISODES_CONTAINER = "pagAniListaContainer";
}
import 'package:html/dom.dart';
import 'package:html/parser.dart';
import '../../../domain/entities/parser/ihtml_parser.dart';
import '../../../domain/exceptions/CrawlerApiException.dart';
import '../../../domain/entities/HomePageInfo.dart';
import '../../../external/anitube/parser/anitube_elements_name.dart';
import '../../../external/anitube/parser/anitube_item_parser_utils.dart';
import '../../../domain/entities/AnimeItem.dart';
import '../../../domain/entities/EpisodeItem.dart';

enum _HomePageAnimeCategory { MOST_SHOWED, MOST_RECENT, DAY_RELEASE }

class AnitubeHomePageParser implements IHTMLParser<HomePageInfo> {
  @override
  HomePageInfo parseHTML(String? html) {
    if (html == null)
      throw ParserException(message: "AnitubeHomePageParser HTML is null");

    final latestEpisodes = _extractLatestEpisodes(html);
    final mostShowedAnimes = _extractMostShowedAnimes(html);
    final recentAnimes = _extractRecentAnimes(html);
    final dailyReleases = _extractDayRelease(html);

    return HomePageInfo(
      recentAnimes.map((e) => AnimeItem.fromJson(e)).toList(),
      mostShowedAnimes.map((e) => AnimeItem.fromJson(e)).toList(),
      latestEpisodes.map((e) => EpisodeItem.fromJson(e)).toList(),
      dailyReleases.map((e) => AnimeItem.fromJson(e)).toList(),
    );
  }

  List> _parseAnimeItemContent(String page,
      {_HomePageAnimeCategory category = _HomePageAnimeCategory.MOST_SHOWED}) {
    var dataList = >[];

    if (page.isNotEmpty) {
      try {
        Document pageDocument = parse(page);
        var bodies = pageDocument.getElementsByTagName('body');
        if (bodies.isEmpty) return dataList;

        var containers =
            bodies[0].getElementsByClassName(AnitubeElementName.ANI_CONTAINER);
        if (category.index >= containers.length) return dataList;

        var targetContainer = containers[category.index];
        var aniItemList =
            targetContainer.getElementsByClassName(AnitubeElementName.ANI_ITEM);

        for (final aniItem in aniItemList) {
          try {
            dataList.add(parseItem(
              aniItem,
              AnitubeElementName.ANI_ITEM_IMG,
              AnitubeElementName.ANI_CC,
            ));
          } on ParserException catch (ex) {
            print('HomePageParser::_parseAnimeItemContent ${ex.message}');
          }
        }
      } catch (ex) {
        print(
            'HomePageParser::_parseAnimeItemContent error while parsing.\n$ex');
      }
    }

    return dataList;
  }

  /// Obtem os episodios mais recentes
  List> _extractLatestEpisodes(String page) {
    var dataList = >[];
    if (page.isEmpty) return dataList;

    try {
      var bodies = parse(page).getElementsByTagName('body');
      if (bodies.isEmpty) return dataList;

      var epiContainers =
          bodies[0].getElementsByClassName(AnitubeElementName.EPI_CONTAINER);
      if (epiContainers.isEmpty) return dataList;

      var subContainers = epiContainers[0]
          .getElementsByClassName(AnitubeElementName.EPI_SUBCONTAINER);
      var targetElement =
          subContainers.isNotEmpty ? subContainers[0] : epiContainers[0];

      for (final epiItem in targetElement.children) {
        try {
          dataList.add(parseItem(
            epiItem,
            AnitubeElementName.EPI_ITEM_IMG,
            AnitubeElementName.EPI_CC,
          ));
        } on ParserException catch (ex) {
          print('HomePageParser::extractLatestEpisodes ${ex.message}');
        }
      }
    } catch (ex) {
      print('HomePageParser::extractLatestEpisodes error: $ex');
    }

    return dataList;
  }

  List> _extractMostShowedAnimes(String page) =>
      _parseAnimeItemContent(page,
          category: _HomePageAnimeCategory.MOST_SHOWED);

  List> _extractRecentAnimes(String page) =>
      _parseAnimeItemContent(page,
          category: _HomePageAnimeCategory.MOST_RECENT);

  List> _extractDayRelease(String page) =>
      _parseAnimeItemContent(page,
          category: _HomePageAnimeCategory.DAY_RELEASE);
}
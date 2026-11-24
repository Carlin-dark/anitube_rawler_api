import 'package:html/dom.dart';
import 'package:html/parser.dart';
import '../../../domain/entities/AnimeListPageInfo.dart';
import '../../../domain/exceptions/CrawlerApiException.dart';
import '../../../domain/entities/parser/ihtml_parser.dart';
import '../../../external/anitube/parser/anitube_elements_name.dart';
import '../../../external/anitube/parser/anitube_item_parser_utils.dart';

class AnimeListPageParser implements IHTMLParser<AnimeListPageInfo> {
  final bool isSearch;

  AnimeListPageParser({required this.isSearch});

  @override
  AnimeListPageInfo parseHTML(
    String? html,
  ) {
    if (html == null)
      throw ParserException(message: "AnimeListPageParser html is null");
    return AnimeListPageInfo.fromJson(
        _parseAnimeListPage(html, isSearch: isSearch));
  }

  Map<String, dynamic> _parseAnimeListPage(String page,
      {bool isSearch = false}) {
    var bodies = parse(page).getElementsByTagName('body');
    if (bodies.isEmpty) {
      return {
        AnimeListPageInfo.ANIME_ITEMS: >[],
        AnimeListPageInfo.CURRENT_PAGE: '1',
        AnimeListPageInfo.MAX_PAGE_NUMBER: '1',
      };
    }

    var body = bodies[0];

    try {
      var animeItems = _parseAnimeItems(
          body,
          isSearch
              ? _AnimeListPageClasses.SEARCH_CONTAINER
              : _AnimeListPageClasses.ANIME_LIST);

      var paginationInfo = _parsePaginationData(body);

      return {
        AnimeListPageInfo.ANIME_ITEMS: animeItems,
        AnimeListPageInfo.CURRENT_PAGE:
            paginationInfo[AnimeListPageInfo.CURRENT_PAGE],
        AnimeListPageInfo.MAX_PAGE_NUMBER:
            paginationInfo[AnimeListPageInfo.MAX_PAGE_NUMBER]
      };
    } catch (ex) {
      print(
          'Error in parsing process. AnimeListPageParser::parseAnimeListPage\n$ex');
      throw ParserException(message: "Error parsing anime list page");
    }
  }

  List> _parseAnimeItems(
      Element body, String containerClassName) {
    var container = body.getElementsByClassName(containerClassName);
    List> resultsList = [];

    if (container.isNotEmpty) {
      var elementList = container[0];

      try {
        if (elementList.children.isNotEmpty) {
          final firstClass = elementList.children[0].attributes['class'] ?? '';
          if (!firstClass.contains(_AnimeListPageClasses.LIST_NOT_FOUND)) {
            for (int i = 0; i < elementList.children.length; i++) {
              try {
                var item = parseItem(elementList.children[i],
                    AnitubeElementName.ANI_ITEM_IMG, AnitubeElementName.ANI_CC);
                resultsList.add(item);
              } catch (ex) {
                print(
                    'AnimeListPageParser::_parseAnimeItems when try parseItem $ex');
              }
            }
          }
        }
      } catch (ex) {
        print('AnimeListParser::_parseAnimeItems ${ex.toString()}');
      }
    }

    return resultsList;
  }

  Map<String, dynamic> _parsePaginationData(Element body) {
    try {
      var currentPageNumber = '1';
      var totalPageNumber = '1';

      var elementList =
          body.getElementsByClassName(_AnimeListPageClasses.PAGINATION);

      if (elementList.isNotEmpty) {
        var paginationDiv = elementList[0];
        var currentElements =
            paginationDiv.getElementsByClassName(_AnimeListPageClasses.CURRENT);

        if (currentElements.isNotEmpty &&
            currentElements[0].text.trim().isNotEmpty) {
          currentPageNumber = currentElements[0].text.trim();
          totalPageNumber = currentPageNumber;
        }

        for (var i = 0; i < paginationDiv.children.length; i++) {
          var element = paginationDiv.children[i];
          if ((element.attributes['class'] ?? '')
                  .contains(_AnimeListPageClasses.NEXT) &&
              i > 0) {
            final prevText = paginationDiv.children[i - 1].text.trim();
            if (prevText.isNotEmpty) {
              totalPageNumber = prevText;
            }
          }
        }
      }

      return {
        AnimeListPageInfo.CURRENT_PAGE: currentPageNumber,
        AnimeListPageInfo.MAX_PAGE_NUMBER: totalPageNumber,
      };
    } catch (ex) {
      print('AnimeListParser::_parsePaginationData ${ex.toString()}');
      return {
        AnimeListPageInfo.CURRENT_PAGE: '1',
        AnimeListPageInfo.MAX_PAGE_NUMBER: '1',
      };
    }
  }
}

class _AnimeListPageClasses {
  static const SEARCH_CONTAINER = "searchPagContainer";
  static const PAGINATION = "paginacao";
  static const ANIME_LIST = "listaPagAnimes";
  static const LIST_NOT_FOUND = "listaPagNotfound";
  static const PAGE_NUMBERS = "page-numbers";
  static const NEXT = "next";
  static const CURRENT = "current";
}
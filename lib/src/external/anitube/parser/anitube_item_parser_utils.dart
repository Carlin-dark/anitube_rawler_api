import 'package:html/dom.dart';
import '../../../domain/entities/Item.dart';
import '../../../domain/exceptions/CrawlerApiException.dart';

String _extractIdFromUrl(String? rawUrl) {
  if (rawUrl == null || rawUrl.isEmpty) return '';
  final uri = Uri.tryParse(rawUrl);
  final segments = (uri?.pathSegments ?? rawUrl.split('/'))
      .where((segment) => segment.isNotEmpty)
      .toList();
  if (segments.isEmpty) return '';
  return segments.last;
}

Map<String, dynamic> parseItem(Element itemElement, String divImageClassName,
    String closedCaptionClassName) {
  String? pageLink;
  String? title;
  String id = '';
  String? imageUrl;
  String cc = 'Legendado';

  try {
    final anchor = itemElement.localName == 'a'
        ? itemElement
        : itemElement.querySelector('a');

    pageLink = anchor?.attributes['href'] ??
        (itemElement.children.isNotEmpty
            ? itemElement.children[0].attributes['href']
            : null);

    title = anchor?.attributes['title'] ??
        anchor?.querySelector('img')?.attributes['alt'] ??
        anchor?.text.trim();

    id = _extractIdFromUrl(pageLink);

    var itemImgDivs = itemElement.getElementsByClassName(divImageClassName);
    var imgElement = itemImgDivs.isNotEmpty
        ? itemImgDivs[0].querySelector('img')
        : itemElement.querySelector('img');

    imageUrl = imgElement?.attributes['src'] ??
        imgElement?.attributes['data-src'] ??
        imgElement?.attributes['data-lazy-src'];

    var ccElements = itemImgDivs.isNotEmpty
        ? itemImgDivs[0].getElementsByClassName(closedCaptionClassName)
        : itemElement.getElementsByClassName(closedCaptionClassName);

    if (ccElements.isNotEmpty && ccElements[0].text.trim().isNotEmpty) {
      cc = ccElements[0].text.trim();
    }

    if (title == null || title.isEmpty || pageLink == null || pageLink.isEmpty) {
      throw ParserException(message: "Missing title or pageLink in item");
    }

    return {
      Item.ID: id,
      Item.TITLE: title.trim(),
      Item.PAGE_URL: pageLink.trim(),
      Item.IMAGE_URL: (imageUrl ?? '').trim(),
      Item.CC: cc,
    };
  } catch (ex) {
    print("ItemParser::parseItem error parsing item.\n $ex");
    print('PageLink: $pageLink\n'
        'ID: $id\n'
        'title: $title\n'
        'imageUrl: $imageUrl\n'
        'CC: $cc');

    throw ParserException(message: "Error parsing item");
  }
}
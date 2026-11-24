import 'package:dio/dio.dart';
import '../../infra/data_source/page_fetcher.dart';
import '../../domain/exceptions/CrawlerApiException.dart';

class AnitubeDataSource extends IHTMLPageFetcher {
  final Dio httpClient;

  AnitubeDataSource(this.httpClient, {String? url});

  @override
  Future<String> downloadHTMLPage({
    required String url,
  }) async {
    try {
      final response = await httpClient.get(
        url,
        options: Options(
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
            'Referer': 'https://www.anitube.zip/',
          },
        ),
      );
      return response.data.toString();
    } on DioError catch (error) {
      throw NetworkException(message: error.response?.statusMessage);
    }
  }
}
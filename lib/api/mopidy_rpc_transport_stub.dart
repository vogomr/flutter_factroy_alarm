import 'dart:io';
import 'dart:convert';

class RpcResponse {
  final int statusCode;
  final String body;

  const RpcResponse({required this.statusCode, required this.body});
}

Future<RpcResponse> postJson(Uri uri, Object payload) async {
  final client = HttpClient();
  try {
    final request = await client.postUrl(uri);
    request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
    request.write(jsonEncode(payload));

    final response = await request.close();
    final body = await utf8.decoder.bind(response).join();
    return RpcResponse(statusCode: response.statusCode, body: body);
  } finally {
    client.close(force: true);
  }
}
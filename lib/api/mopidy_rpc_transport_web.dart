import 'dart:convert';
import 'dart:html' as html;

class RpcResponse {
  final int statusCode;
  final String body;

  const RpcResponse({required this.statusCode, required this.body});
}

Future<RpcResponse> postJson(Uri uri, Object payload) async {
  final request = await html.HttpRequest.request(
    uri.toString(),
    method: 'POST',
    sendData: jsonEncode(payload),
    requestHeaders: const {'Content-Type': 'application/json'},
  );

  return RpcResponse(
    statusCode: request.status ?? 0,
    body: request.responseText ?? '',
  );
}
import 'dart:convert';

import 'package:http/http.dart' as http;

class RpcResponse {
  final int statusCode;
  final String body;

  const RpcResponse({required this.statusCode, required this.body});
}

Future<RpcResponse> postJson(Uri uri, Object payload) async {
  final response = await http.post(
    uri,
    headers: const {'Content-Type': 'application/json'},
    body: jsonEncode(payload),
  );

  return RpcResponse(statusCode: response.statusCode, body: response.body);
}
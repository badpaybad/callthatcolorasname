import 'dart:async';
import 'dart:convert';
import 'dart:io';



class WebServerApiMvc {

  WebServerApiMvc._(){
//wss://meet.jit.si/xmpp-websocket
  }

  static WebServerApiMvc instance = WebServerApiMvc._();

  final Map<String, Future<String> Function(HttpRequest)> _route =
      <String, Future<String> Function(HttpRequest)>{};

  Future<void> _registerRequestHandle() async {
//register handle for routing similar to mvc
    _route["/"] = (request) async {
      return "Root path";
    };
    _route["/swagger"] = (request) async {
      return "Some blade engin to render swagger docs";
    };
    _route["/jsontest"] = (request) async {
      return jsonEncode({"name": "Nguyen Phan Du"});
    };
  }

  late HttpServer _http_server;

  Future<void> start() async {
    await _registerRequestHandle();

    _http_server = await HttpServer.bind(InternetAddress.anyIPv4, 8123);
    print("webserver listening: ${_http_server.address.host}:${_http_server.port}");
    _loopServeRequest();
  }

  Future<void> _loopServeRequest() async {
    await _http_server.forEach((HttpRequest request) async {
      print("request.requestedUri.path: ${request.requestedUri.path}");

      if (_route.containsKey(request.requestedUri.path)) {
        var responseData = await _route![request.requestedUri.path]!(request);
        request.response.write(responseData);
      } else {
        request.response.write('404');
        request.response.statusCode = 404;
      }
      request.response.close();
    });
    print("End web server");
  }
}
//
// final channel =
// WebSocketChannel.connect(Uri.parse('wss://meet.jit.si/xmpp-websocket'),
//     //   Uri.parse('wss://ws-feed.pro.coinbase.com'),
//     protocols: ["xmpp"]);
//
// channel.stream.listen((message) {
// print("WebSocketChannel--------------------------");
// print(message);
// // channel.sink.add('received!');
// // channel.sink.close(WssStatus.goingAway);
// });
//
// channel.sink.add('received!');
// //
// // channel.sink.add(
// //   jsonEncode(
// //     {
// //       "type": "subscribe",
// //       "channels": [
// //         {
// //           "name": "ticker",
// //           "product_ids": [
// //             "BTC-EUR",
// //           ]
// //         }
// //       ]
// //     },
// //   ),
// // );

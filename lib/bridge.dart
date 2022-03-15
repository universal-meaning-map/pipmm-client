import 'dart:developer';
import 'package:web_socket_channel/web_socket_channel.dart';

class Bridge  {
  String websocketsPort = "";
  Bridge();

  void startWs({required Function onIid, required String port}) async {
    websocketsPort = port;
    log("Starting bridge on port: " + websocketsPort);

    /// Create the WebSocket channel
    final channel = WebSocketChannel.connect(
      Uri.parse('ws://localhost:' + websocketsPort),
    );

    /// Listen for all incoming data
    channel.stream.listen(
      (data) {
        onIid(data);
      },
      onError: (error) => log(error.toString()),
    );
  }
}

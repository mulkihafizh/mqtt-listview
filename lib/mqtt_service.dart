import 'dart:async';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttManager {
  static MqttServerClient? client;
  static Function? onConnected;
  static Function? onDisconnected;
  static StreamController<MqttConnectionState> _connectionStateController =
      StreamController<MqttConnectionState>();
  static Stream<MqttConnectionState> get connectionStateStream =>
      _connectionStateController.stream;
  static void connect() async {
    client = MqttServerClient('192.168.150.25', '');
    client!.port = 1883;
    client!.logging(on: true);
    client!.onDisconnected = () {
      print('Disconnected');
      _connectionStateController.add(MqttConnectionState.connected);
      onDisconnected?.call();
    };
    client!.onConnected = () {
      print('Connected');
      _connectionStateController.add(MqttConnectionState.disconnected);
      onConnected?.call();
    };
    client!.onSubscribed = (String topic) {
      print('Subscribed to topic $topic');
    };
    client!.onSubscribeFail = (String topic) {
      print('Failed to subscribe to topic $topic');
    };
    try {
      await client?.connect('mulki', 'mulki123');
    } catch (e) {
      print('Exception: $e');
      client?.disconnect();
    }
  }

  static void subscribe(String topic, Function(String) onMessage) {
    client!.subscribe(topic, MqttQos.atLeastOnce);
    client!.updates!.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
      messages.forEach((message) {
        final MqttPublishMessage receivedMessage =
            message.payload as MqttPublishMessage;
        final String payload = MqttPublishPayload.bytesToStringAsString(
            receivedMessage.payload.message);
        print('New received message: $payload');
        onMessage(payload);
      });
    });
  }

  static void publish(String topic, String message) {
    final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
    builder.addString(message);
    client!.publishMessage(topic, MqttQos.exactlyOnce, builder.payload!);
  }

  static void disconnect() {
    client?.disconnect();
  }
}

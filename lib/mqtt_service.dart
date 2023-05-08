import 'dart:async';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'home_screen.dart';

class MqttManager {
  static MqttServerClient? client = MqttServerClient(host, '');
  static Function? onConnected;
  static Function? onDisconnected;
  static Function()? onDisconnectedCall;
  static bool intentionalDisconnection = false;
  static final StreamController<MqttConnectionState>
      _connectionStateController = StreamController<MqttConnectionState>();
  static Stream<MqttConnectionState> get connectionStateStream =>
      _connectionStateController.stream;
  static void connect(
    host,
  ) async {
    client?.port = 1883;
    client?.logging(on: true);
    client?.keepAlivePeriod = 30;
    client?.setProtocolV311();

    client?.onDisconnected = () {
      print("Disconnected | Time: ${DateTime.now().toUtc()}");
      _connectionStateController.add(MqttConnectionState.disconnected);
      onDisconnected?.call();
      if (!intentionalDisconnection) {
        onDisconnectedCall?.call();
      }
    };
    client?.onConnected = () {
      intentionalDisconnection = false;
      print('Connected');
      connectionStatus = 'Connected';
      _connectionStateController.add(MqttConnectionState.connected);
      onConnected?.call();
    };
    client?.onSubscribed = (String topic) {
      print('Subscribed to topic $topic');
    };
    client?.onSubscribeFail = (String topic) {
      print('Failed to subscribe to topic $topic');
    };
    try {
      await client?.connect('/smkwikramabogor:smkwikramabogor', 'qwerty');
    } catch (e) {
      print('Exception: $e');
      client?.disconnect();
    }
  }

  static void subscribe(String topic, Function(String) onMessage) {
    client?.subscribe(topic, MqttQos.atLeastOnce);
    client?.updates!.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
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
    client?.publishMessage(topic, MqttQos.atMostOnce, builder.payload!);
  }

  static void disconnect() {
    intentionalDisconnection = true;
    client?.disconnect();
  }
}

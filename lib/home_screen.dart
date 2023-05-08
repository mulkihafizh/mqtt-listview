import 'package:flutter/material.dart';
import 'mqtt_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

String host = 'rmq2.pptik.id';
String connectionStatus = 'Disconnected';
String topic = 'testingmessage';
String publish = '';
List<String> messages = [];
final fieldText = TextEditingController();

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    MqttManager.onDisconnectedCall = onDisconnectedCall;
    connect(host);
  }

  void onDisconnectedCall() {
    setState(() {
      connectionStatus = 'Disconnected';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Error Connection Timeout or Server Refused to Connect'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => {
          setState(() {
            messages = [];
          }),
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              duration: Duration(seconds: 1),
              content: Text('Cleared all messages'),
            ),
          )
        },
        child: const Icon(Icons.delete_outline),
      ),
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('MQTT Client'),
        centerTitle: true,
        titleTextStyle: const TextStyle(fontSize: 14),
      ),
      body: Container(
          height: double.infinity,
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(children: [
                TextField(
                  cursorColor: Colors.white,
                  decoration: const InputDecoration(
                    hintText: 'Enter a message to publish',
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white, width: 1.0),
                    ),
                  ),
                  onChanged: (value) {
                    publish = value;
                  },
                  controller: fieldText,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    ElevatedButton(
                      style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all<Color>(
                              Colors.grey[800]!),
                          shape:
                              MaterialStateProperty.all<RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(18.0)))),
                      onPressed: () => publishMessage(context),
                      child: const Text('Publish'),
                    ),
                    const SizedBox(width: 10),
                    if (connectionStatus == 'Connected')
                      ElevatedButton(
                          style: ButtonStyle(
                              backgroundColor:
                                  MaterialStateProperty.all<Color>(Colors.red),
                              shape: MaterialStateProperty.all<
                                      RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(18.0)))),
                          onPressed: disconnect,
                          child: const Text('Disconnect')),
                    if (connectionStatus == 'Disconnected')
                      ElevatedButton(
                          style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all<Color>(
                                  Colors.green),
                              shape: MaterialStateProperty.all<
                                      RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(18.0)))),
                          onPressed: () {
                            connect(host);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                duration: const Duration(seconds: 1),
                                content: Text('Connecting to $host')));
                          },
                          child: const Text('Connect')),
                  ],
                )
              ]),
              const SizedBox(height: 20),
              Text('Host: $host'),
              const SizedBox(height: 20),
              connectionStates(),
              const SizedBox(height: 20),
              if (messages.isEmpty) const Text('No Message Received'),
              if (messages.isNotEmpty) const Text('Received Messages:'),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemBuilder: (BuildContext context, int index) {
                    return Card(
                      child: ListTile(
                        title: Text(messages[index]),
                      ),
                    );
                  },
                  itemCount: messages.length,
                  shrinkWrap: true,
                ),
              ),
            ],
          )),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  void connect(host) {
    MqttManager.connect(host);
    MqttManager.onConnected = () {
      MqttManager.subscribe(topic, (String message) {
        setState(() {
          messages.insert(0, message);
          print(messages);
        });
      });
      setState(() {
        connectionStatus = 'Connected';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 1),
          content: Text('Connected to MQTT Broker'),
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 1),
          content: Text('Subscribed to topic: $topic'),
        ),
      );
    };
  }

  void disconnect() {
    MqttManager.disconnect();
    setState(() {
      connectionStatus = 'Disconnected';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Disconnected from MQTT Broker'),
        duration: Duration(seconds: 1),
      ),
    );
  }
}

Widget connectionStates() {
  return Row(
    children: [
      Text('Connection Status: $connectionStatus'),
      const SizedBox(width: 10),
      if (connectionStatus == 'Connected')
        const Icon(
          Icons.check_circle,
          color: Colors.green,
          size: 16,
        ),
      if (connectionStatus == 'Disconnected')
        const Icon(
          Icons.cancel,
          color: Colors.red,
          size: 16,
        )
    ],
  );
}

void publishMessage(BuildContext context) {
  if (publish.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      duration: Duration(seconds: 1),
      content: Text('Please enter a message to publish'),
    ));
  } else if (connectionStatus == 'Disconnected') {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      duration: Duration(seconds: 1),
      content: Text('Please connect to the broker'),
    ));
  } else {
    MqttManager.publish(topic, publish);
    publish = '';
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Message published'),
      duration: Duration(seconds: 1),
    ));
  }
  fieldText.clear();
  FocusScope.of(context).unfocus();
}

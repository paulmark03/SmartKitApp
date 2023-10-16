import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final devicesList = <DiscoveredDevice>[];
  final flutterReactiveBle = FlutterReactiveBle();
  Stream<DiscoveredDevice> discoveredDevices = Stream.empty();
  String receivedValue = 'Awaiting Data...';

  @override
  void initState() {
    super.initState();
    discoveredDevices = flutterReactiveBle.scanForDevices(
      withServices: [], // Can be left empty to discover all nearby devices
      scanMode: ScanMode.lowLatency,
    );
  }

  _discoverCharacteristics(DiscoveredDevice device) async {
    final services = await flutterReactiveBle.discoverServices(device.id);
    final targetServices = services.where((service) => service.serviceId == Uuid.parse("YOUR_SERVICE_UUID"));



    if (targetServices.isNotEmpty) {
      final targetService = targetServices.first;
      for (final characteristic in targetService.characteristics) {
        final characteristicObj = QualifiedCharacteristic(
          serviceId: targetService.serviceId,
          characteristicId: characteristic.characteristicId,
          deviceId: device.id,
        );
        flutterReactiveBle.subscribeToCharacteristic(characteristicObj).listen((data) {
          setState(() {
            receivedValue = String.fromCharCodes(data);
          });
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Bluetooth Value Receiver'),
        ),
        body: Column(
          children: [
            Expanded(
              child: StreamBuilder<DiscoveredDevice>(
                stream: discoveredDevices,
                builder: (context, snapshot) {
                  if (snapshot.hasData && !devicesList.contains(snapshot.data)) {
                    devicesList.add(snapshot.data!);
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (devicesList.isEmpty) {
                    return Center(child: Text('No devices found'));
                  }

                  return ListView.builder(
                    itemCount: devicesList.length,
                    itemBuilder: (context, index) {
                      final device = devicesList[index];
                      return ListTile(
                        title: Text(device.name ?? "Unknown Device"),
                        subtitle: Text(device.id),
                        onTap: () async {
                          await _discoverCharacteristics(device);
                        },
                      );
                    },
                  );
                },
              ),
            ),
            Divider(),
            Text('Received Value: $receivedValue'),
          ],
        ),
      ),
    );
  }
}

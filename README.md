# Aid.io Dart 


Simple Dart Socket library in Dart

Protocol: ``[cmd,ack,data.size,data]`` Uint8 in Dart

Explain: ``head(10byte) [cmd:1,ack:1,size:8] body:[data] `` 


## Server Usage  

[Server.dart](./test/ser.dart) - Example

```dart
import 'package:aidio/io.dart';

main() async {
  var io = AidioServer();
  await io.init(host: '127.0.0.1', port: 1999);
  io.stream.listen((AidioData data) {
    print("recieve:$data");
  });
}

```


## Client Usage 

[Client.dart](./test/cli.dart) - Example

```dart
import 'package:aidio/io.dart';

main() async {
  var io = AidioClient();
  await io.init(host: '127.0.0.1', port: 1999);
  var tick = 0;
  io.stream.listen((AidioData data) {
    print("recieve:$data");
    tick++;
    if (tick > 10) {
      io.close();
      return;
    }
    Future.delayed(Duration(seconds: 1), () {
      io.send(IoCommond.emit, "timer:${tick}");
    });
  });
}

```


## Document 

IoCommonds

```dart

enum IoCommond {
  none,
  error,
  connected,
  denied,
  ack,
  msg,
  emit,
  ///  here set up your commonds, if you need
}

```



AidioServer


```dart

class AidioServer extends AidioProtocol {
  bool auth = false;

  init({String host = '127.0.0.1', int port = 4041}) async {
    try {
      io = await ServerSocket.bind(host, port);
      ....
    } catch (e) {
      ....  
    }
  }
}

```



AidioServer


```dart

class AidioClient extends AidioProtocol {
  init({String host = '127.0.0.1', int port = 4041}) async {
    try {
      socket = await Socket.connect(host, port);
      ....
    } catch (e) {
      ....
    }
  }
}

```

## Protocol 

Data Transform Package Format:

```dart
[cmd,ack,data.size,data]
```

Example Process:

```dart

 *   1.client-> auth to ->server
 *   2.client receive [IoCommond.connected,0,data.size,data] or [IoCommond.denied,0,data.size,data]
 *   3.client send [IoCommond.file,0,data.size,data]
 *   4.server receive [IoCommond.file,1,data.size,data]

```


## Contributors

AlmPazel, Fehrim, Dina, Jaffar

Welcome to join [Contributors] !



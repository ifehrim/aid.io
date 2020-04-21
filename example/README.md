# Aid.io Dart  Example


Simple Dart Socket library in Dart

Protocol: ``[cmd,ack,data.size,data]`` Uint8 in Dart

Explain: ``head(10byte) [cmd:1,ack:1,size:8][body] `` 




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

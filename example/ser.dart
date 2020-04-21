import 'package:aidio/aidio.dart';

main() async {
  var io = AidioServer();
  await io.init(host: '127.0.0.1', port: 1999);
  io.stream.listen((AidioData data) {
    print("recieve:$data");
  });
}

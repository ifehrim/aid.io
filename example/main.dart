import 'package:aidio/aidio.dart';

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

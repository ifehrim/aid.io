import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

//IoCommond
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

/**
 * Server io
 */

class AidioServer extends AidioProtocol {
  bool auth = false;

  init({String host = '127.0.0.1', int port = 4041}) async {
    try {
      io = await ServerSocket.bind(host, port);
      print("Server:$host:$port bind success!\n$version\n\nwating->>>");
      server = await io.listen((Socket soc) {
        socket = soc;
        auth = false;
        listen = socket.listen((data) {
          if (!auth) {
            auth = (utf8.decode(data) == securityKey);
            if (!auth) {
              send(IoCommond.denied, "Access Denied");
              socket.close();
              listen.cancel();
            }
            send(IoCommond.connected, version);
          } else {
            _decode(data);
          }
        });
      });
    } catch (e) {
      controller.add(AidioData.error(IoCommond.error, "[$runtimeType-${socket.hashCode}]id:$id,$commond,ack:$ack," + e.toString()));
    }
  }
}

/**
 * Client io
 */

class AidioClient extends AidioProtocol {
  init({String host = '127.0.0.1', int port = 4041}) async {
    try {
      socket = await Socket.connect(host, port);
      print("Client:$host:$port connect success!\n$version\n\nwating->>>");
      listen = socket.listen((Uint8List data) {
        _decode(data);
      });
      socket.write(securityKey);
    } catch (e) {
      controller.add(AidioData.error(IoCommond.error, "[$runtimeType-${socket.hashCode}]id:$id,$commond,ack:$ack," + e.toString()));
    }
  }

  @override
  _onData(IoCommond cmd, Uint8List data) {
    if (id == 1) {
      send(IoCommond.connected, version);
    } else {
      controller.add(AidioData(cmd, id, data));
    }
  }
}

/**
 * Socket Data Utilities
 */

class AidioData {
  IoCommond commond;
  Uint8List data;
  int id = 0;

  String get body => utf8.decode(data);

  AidioData(this.commond, this.id, this.data);

  AidioData.error(IoCommond commond, String input) {
    this.commond = commond;
    this.data = utf8.encode(input);
  }

  @override
  String toString() {
    return 'AidioData{commond: $commond, body: $body, id: $id}';
  }
}

/**
 *
 * Socket Data Protocol
 *
 *   [cmd,ack,data.size,data]
 *
 *
 * Example:
 *
 *   1.client-> auth to ->server
 *   2.client receive [IoCommond.connected,0,data.size,data] or [IoCommond.denied,0,data.size,data]
 *   3.client send [IoCommond.file,0,data.size,data]
 *   4.server receive [IoCommond.file,1,data.size,data]
 *
 */

class AidioProtocol {
  ServerSocket io;
  Socket socket;
  StreamSubscription<Socket> server;
  StreamSubscription<Uint8List> listen;
  StreamController controller = StreamController<AidioData>();

  Stream<AidioData> get stream => controller.stream;

  String securityKey = "Aidio:auth"; // setup your security key
  String version = "Aid.io version 0.0.1;";

  IoCommond get commond => IoCommond.values[cmd];

  Uint8List _buffer;
  int id = 0;
  int ack = 0;
  int cmd = 0;
  bool _ackLook = false;
  int _diff = 0;
  int _length = 0;
  int _size = 0;

  Future<void> close() async {
    try{
      await listen?.cancel();
      await socket?.close();
      await controller?.close();
      await io?.close();
    }catch(ignore){}
  }

  send(IoCommond cmd, Object obj) {
    var bytes = utf8.encode(obj.toString());
    ack++;
    if (ack >= 255) ack = 0;
    var byteSize = Uint64List.fromList([bytes.length]).buffer.asUint8List();
    var pack = Uint8List.fromList([
      ...[cmd.index, ack],
      ...byteSize,
      ...bytes
    ]);
    socket.add(pack);
  }

  _onData(IoCommond cmd, Uint8List data) {
    controller.add(AidioData(cmd, id, data));
  }

  _decode(Uint8List data) {
    id++;
    _ackLook = false;
    _depack(data);
  }

  _depack(Uint8List data) {
    if (_buffer != null) {
      data = Uint8List.fromList([..._buffer, ...data]);
      _buffer = null;
      //body is coming, need to resolve
      if (_diff < 0) {
        _diff = data.length - _size;
        if (_diff == 0) {
          _buffer = null;
          _onData(commond, data);
        } else if (_diff > 0) {
          _buffer = data.sublist(_size);
          var body = data.sublist(0, _size);
          _onData(commond, body);
        } else if (_diff < 0) {
          _buffer = data;
        }
        return;
      }
    }

    if (data.length < 11) {
      _buffer = data;
      return;
    }
    //head should be 10 byte
    var head = data.sublist(0, 10);
    cmd = head[0];
    ack = head[1];
    _size = head.sublist(2).buffer.asUint64List().first;

    //body should be size byte to full
    var body = data.sublist(10);

    _length = body.length;
    _diff = _length - _size;

    // perfect time body full
    if (_diff == 0) {
      _buffer = null;
      _onData(commond, body);
      // extra package should be solve
    } else if (_diff > 0) {
      _buffer = body.sublist(_size);
      body = body.sublist(0, _size);
      _onData(commond, body);

      //body is coming, need to receive
    } else if (_diff < 0) {
      _buffer = data.sublist(0);
    }

    if (commond != IoCommond.ack && !_ackLook) send(IoCommond.ack, _length.toString());

    //extra package solving
    if (_buffer != null && _buffer.length > 10) {
      _ackLook = true;
      var data = _buffer.sublist(0);
      _buffer = null;
      _depack(data);
    }
  }
}

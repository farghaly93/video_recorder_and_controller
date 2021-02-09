import "package:flutter_socket_io/flutter_socket_io.dart";
import "package:flutter_socket_io/socket_io_manager.dart";

class Socket {
  static SocketIO socket;

  static void initSocket() {
    socket = SocketIOManager().createSocketIO('https://farghaly-socket-server.herokuapp.com', '/');
    socket.init();
    socket.connect();
  }
}
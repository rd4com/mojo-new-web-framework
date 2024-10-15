from python import PythonObject, Python
from collections import OptionalReg, Dict, Optional
from sys.param_env import is_defined
from time import sleep

struct HttpServer:
    alias host="127.0.0.1"
    alias port=8080
    
    var socket: PythonObject
    var websockets: Dict[String, PythonObject] 
    
    fn __len__(self)->Int: return len(self.websockets)
    fn __init__(inout self):
        self.socket = PythonObject(None)
        self.websockets = __type_of(self.websockets)()
        try:
            py_socket = Python.import_module("socket")
            self.socket = py_socket.socket(py_socket.AF_INET, py_socket.SOCK_STREAM)
            self.socket.setsockopt(py_socket.SOL_SOCKET, py_socket.SO_REUSEADDR, 1)
            self.socket.bind((Self.host, Self.port))
            self.socket.listen(1)
            print("http://"+str(Self.host)+":"+str(Self.port))
        except e:
            self.socket = PythonObject(None)
            print(e)
    
    def handle_one_request(
        inout self, 
        ref[_]index_html:String,
        ref[_]style_css:String,
        ref[_]exit_if_client_not_in: PythonObject
    )->Optional[String]:
        try:   
            if not Python.import_module("select").select([self.socket], [], [], 0)[0]:
                raise "No request"
            py_base64 = Python.import_module("base64")
            py_sha1 = Python.import_module("hashlib").sha1
            client = PythonObject(None)
            client = self.socket.accept()
            
            if not exit_if_client_not_in.__contains__(client[1][0]): 
                print("Exit, request from: "+str(client[1][0]))
                raise "exit_app" 
            
            if not Python.import_module("select").select([client[0]], [], [], 0)[0]:
                raise "No request"
            request = client[0].recv(1024).decode()
            request_header = Dict[String,String]()
            
            var end_header = int(request.find("\r\n\r\n"))
            if end_header == -1:
                raise "end_header == -1, no \\r\\n\\r\\n"
            var request_split = str(request)[:end_header].split("\r\n")
            if len(request_split) == 0: 
                raise "error: len(request_split) == 0"
            if request_split[0] != "GET / HTTP/1.1":
                if request_split[0] == "GET /style.css HTTP/1.1":
                    var tmp_response = String("HTTP/1.1 200 OK\r\n")
                    tmp_response+= "Content-Type: text/css; charset=UTF-8\r\n"
                    tmp_response+= "\r\n"
                    tmp_response += style_css
                    tmp_response+= "\r\n"
                    if not Python.import_module("select").select([], [client[0]], [], 0)[1]:
                        client[0].close()
                        raise "No request"
                    client[0].send(PythonObject(tmp_response).encode("utf-8"))
                    client[0].close()
                    return
                if not request_split[0].startswith("GET /api/"):
                    var tmp_response = String("HTTP/1.1 404 Not Found\r\n")
                    tmp_response+= "\r\n"
                    if not Python.import_module("select").select([], [client[0]], [], 0)[1]:
                        client[0].close()
                        raise "No request"
                    client[0].send(PythonObject(tmp_response).encode("utf-8"))
                    client[0].close()
                    print(request_split[0])
                    raise "request_split[0] not GET / HTTP/1.1"
            url = request_split.pop(0).split(" ")[1]
            print(url)
            if len(request_split) == 0: 
                raise "error: no headers"
            
            for e in request_split: 
                var header_pos = e[].find(":")
                if header_pos == -1:
                    raise "header_pos == -1"
                if len(e[]) == header_pos+2:
                    raise "len(e[]) == header_pos+2"
                var k = e[][:header_pos]
                var v = e[][header_pos+2:]
                request_header[k^]=v^
            
            for h in request_header:
                print(h[], request_header[h[]])
            
            if "Upgrade" not in request_header:
                var tmp_response = String("HTTP/1.1 200 OK\r\n")
                tmp_response+= "Content-Type: text/html; charset=UTF-8\r\n"
                tmp_response+= "\r\n"
                tmp_response += index_html
                tmp_response+= "\r\n"
                if not Python.import_module("select").select([], [client[0]], [], 0)[1]:
                    client[0].close()
                    raise "No request"
                client[0].send(PythonObject(tmp_response).encode("utf-8"))
                client[0].close()
                return

            if request_header["Upgrade"] != "websocket":
                raise "Not an upgrade to websocket"
            
            if "Sec-WebSocket-Key" not in request_header:
                raise "No Sec-WebSocket-Key for upgrading to websocket"
            
            if str(request_header["Sec-WebSocket-Key"]) in self.websockets:
                raise "Already connected"

            var accept = PythonObject(request_header["Sec-WebSocket-Key"])
            accept += PythonObject(WebSocketFrame.MAGIC_CONSTANT)
            accept = accept.encode()
            accept = py_base64.b64encode(py_sha1(accept).digest())
            
            var response = String("HTTP/1.1 101 Switching Protocols\r\n")
            response += "Upgrade: websocket\r\n"
            response += "Connection: Upgrade\r\n"
            response += "Sec-WebSocket-Accept: "
            response += str(accept.decode("utf-8")) 
            response += String("\r\n\r\n")
            
            print(response)
            
            if not Python.import_module("select").select([], [client[0]], [], 0)[1]:
                client[0].close()
                raise "No request"
            client[0].send(PythonObject(response).encode())
            self.websockets[str(request_header["Sec-WebSocket-Key"])]=client[0]
            return str(request_header["Sec-WebSocket-Key"])

        except e:
            print(e)
            if str(e) == "exit_app": raise e
        return None

struct WebSocketFrame:
    alias storage_type = List[UInt8]
    
    # constants
    alias byte_0_text: UInt8 = 1
    alias byte_0_fin: UInt8 = 128
    
    alias byte_1_uint8: UInt8 = 125
    alias byte_1_uint16: UInt8 = 126
    alias byte_1_uint64: UInt8 = 127
    alias byte_1_mask: UInt8 = 128
    
    alias MAGIC_CONSTANT = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"
    
    alias NotConnected = "NotConnected"
    alias NoMessage = "NoMessage"
    alias NoMask = "NoMask"
    alias NotSupported = "NotSupported"
    
    @staticmethod
    fn read_message(ws: PythonObject) raises -> String:
        """
        If raises any error: 
            1. Need to close the connection.
            2. Remove the websocket from the List.
        """
        data = Self.storage_type()
        select = Python.import_module("select").select
        if not select([ws],[],[], 0)[0]:
            raise Self.NoMessage
        data.append(Self.read_byte(ws))
        if not data[0]&Self.byte_0_fin:
            raise Self.NotSupported
        if not data[0]&Self.byte_0_text:
            raise Self.NotSupported
        
        data.append(Self.read_byte(ws))
        size = data[1].cast[DType.uint64]()
        if not size.cast[DType.uint8]()&Self.byte_1_mask.cast[DType.uint8]():
            raise Self.NoMask
        else:
            size^=Self.byte_1_mask.cast[DType.uint64]()
        if size <= Self.byte_1_uint8.cast[DType.uint64]():
            ...
        elif size == Self.byte_1_uint16.cast[DType.uint64]():
            size = Self.read_byte(ws).cast[DType.uint64]() << 8
            size |= Self.read_byte(ws).cast[DType.uint64]()
        elif size == Self.byte_1_uint64.cast[DType.uint64]():
            size = 0
            for i in range(0,8):
                pos = (7-i)*8
                size |= Self.read_byte(ws).cast[DType.uint64]()<<pos
        mask = SIMD[DType.uint8, 4](
            Self.read_byte(ws),
            Self.read_byte(ws),
            Self.read_byte(ws),
            Self.read_byte(ws),
        )
        message = Self.storage_type()
        for i in range(size): 
            #FIXME: remove int()
            message.append(Self.read_byte(ws)^(mask[int(i&3)]))
        message.append(0)
        return String(message^)

    @staticmethod
    fn send_message(ws: PythonObject, message: String) raises:
        """
        If raises any error: 
            1. Need to close the connection.
            2. Remove the websocket from the List.
        """
        data = Self.storage_type()
        data.append(Self.byte_0_fin|Self.byte_0_text)
        
        as_bytes = message.as_bytes()
        len_message = len(as_bytes)
        
        if len_message <= int(Self.byte_1_uint8):
            data.append(UInt8(len_message))
        elif len_message < (2**16):
            data.append(Self.byte_1_uint16)
            data.append(len_message>>8)
            data.append(len_message&255)
        elif UInt64(len_message) < (UInt64(1<<63)):
            data.append(Self.byte_1_uint64)
            for i in range(0,8):
                pos = (7-i)*8
                data.append((len_message>>pos)&255)
        else:
            print("error, first bit should always be 0")
        byte_array = Python.evaluate("bytearray")
        res = byte_array(len(data))
        for e in range(len(data)):
            res[e] = data[e]
        res2 = byte_array(len_message)
        for i in range(len_message):
            res2[i] = as_bytes[i]
        ws.send(res+res2)
                
    @staticmethod
    def read_byte(ws: PythonObject) -> UInt8:
        b = ws.recv(1)
        if not b: 
            raise Self.NotConnected
        return Int(b[0])
    

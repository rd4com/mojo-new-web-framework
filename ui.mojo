from python import PythonObject, Python
from pathlib import Path
from collections import Dict
from memory import UnsafePointer
from ui_websocket import *
from ui_html_elements import *

@value
struct Session:
    var local_instances: UnsafePointer[Dict[String, Instance]]
    var InstanceName: String
    var _appdata: UnsafePointer[PythonObject]
    var _sessiondata: UnsafePointer[PythonObject]
    
    fn appdata(inout self)->ref[self]PythonObject:
        """An app-wide dictionary usable by all websocket sessions."""
        return self._appdata[]
    
    fn sessiondata(inout self)->ref[self]PythonObject:
       """A client-wide dictionary for all components in the current session."""
       return self._sessiondata[]
    
    def Render[C: Component](
        inout self, 
        instance_name: String,
        **kwargs: PythonObject
    )->PythonObject:
        cpy = self
        cpy.InstanceName = instance_name
        var _ref = Pointer.address_of(cpy.local_instances[])
        if instance_name not in _ref[]:
            #TODO: print create component: instance_name
            _ref[][instance_name] = Instance(C(cpy)^)
        try:
            _ref[][instance_name].rendered[] = True
            tmp = _ref[][instance_name]
            _ref2 = Pointer.address_of(tmp.ptr.bitcast[C]()[])
            var tmp_props = Python.evaluate("{}")
            for k in kwargs:
                tmp_props[k[]] = kwargs[k[]]
            #TODO: print render component: instance_name
            tmp2 = _ref2[].Render(tmp_props)
            tmp2["data-instance_name"]= instance_name
            return tmp2
        except e: print(e)
        raise "error rendering:"+instance_name
    
    def _event(
        inout self, 
        props: PythonObject
    )->Action:
        var _ref = Pointer.address_of(self.local_instances[])
        if not props.__contains__("instance_name"):
            raise "Event: instance_name not in props"
        if str(props["instance_name"]) not in _ref[]:
            raise "Event: instance_name"
        instance = _ref[][str(props["instance_name"])]
        instance.rendered[] = True
        #TODO: print component event instance_name: props
        return instance._event(instance.ptr, props)

def serve_app[
    L: MutableOrigin,
    L2: ImmutableOrigin,
    //, 
    T:Component
](
    ref[L]appdata: PythonObject, 
    ref[L2]exit_if_client_not_in: PythonObject
):
    """Start the HTTP server and serve the app. 
    (`index.html`, `style.css`, `websockets`).
    
    Parameters:
        L: The lifetime of appdata.
        L2: The lifetime of exit_if_client_not_in.
        T: The main component.
    
    Args:
        appdata: An app-wide dictionary for all websocket sessions.
        exit_if_client_not_in: Exit the app if new connection host not in it.
    """
    http_server = HttpServer()
    client_states = Dict[
        String, Dict[String,Instance]
    ]() 
    session_data = Dict[String,PythonObject]()
    todel = PythonObject([])
    
    index_html = OpenOrRaise("index.html")
    style_css = OpenOrRaise("style.css")
    
    while True:
        new_websocket = http_server.handle_one_request(
            index_html,
            style_css,
            exit_if_client_not_in
        )
        if new_websocket:
            print("new websocket", new_websocket.value())
            client_states[new_websocket.value()] = Dict[String, Instance]()
            session_data[new_websocket.value()] = Python.dict()
            
            app = Session(
                UnsafePointer.address_of(
                    client_states._find_ref(new_websocket.value())
                ),
                "main_component",
                UnsafePointer.address_of(appdata),
                UnsafePointer.address_of(session_data[new_websocket.value()])
            )
            resp = IntoJson(app.Render[T]("main_component"))

            ws = http_server.websockets[new_websocket.value()]
            try:
                if not Python.import_module("select").select([], [ws], [], 0)[1]:
                    raise WebSocketFrame.NotConnected
                WebSocketFrame.send_message(ws, str(resp))
            except e:
                todel.append(new_websocket.value())
                print(e)
            # print(resp)
        
        for w in http_server.websockets:
            ws = http_server.websockets[w[]]
            try:
                tmp = WebSocketFrame.read_message(ws)
                print("------\nevent", w[])
                as_json = Python.import_module("json").loads(tmp)
                print("event value", as_json,"\n------")
                
                if not as_json.__contains__("instance_name"):
                    raise "instance_name"
                
                for i_ in client_states[w[]]:
                    client_states[w[]][i_[]].rendered[]=False
                
                app = Session(
                    UnsafePointer.address_of(client_states._find_ref(w[])),
                    str(as_json["instance_name"]),
                    UnsafePointer.address_of(appdata),
                    UnsafePointer.address_of(session_data[w[]])
                )
                res_from_event = app._event(as_json)
                if res_from_event.value == Action.Error:
                    raise ("error: _event")

                #TODO: while unhandledevents: outer_component_event(e)

                resp = IntoJson(app.Render[T]("main_component"))
                WebSocketFrame.send_message(ws, str(resp))
                
                #TODO: Move into a new function:
                instances_to_del = PythonObject([])
                for instance_ in client_states[w[]]:
                    if not client_states[w[]][instance_[]].rendered[]:
                        instances_to_del.append(instance_[])
                
                print("instances to del:", len(instances_to_del))
                for instance_to_del in instances_to_del:
                    tmp_instance_to_del = client_states._find_ref(w[]).pop(
                        str(instance_to_del)
                    )
                    tmp_instance_to_del.rendered.free()
                    tmp_instance_to_del._del(tmp_instance_to_del.ptr)
                    print("instance del: ", str(instance_to_del))
                
            except e: 
                if str(e) == WebSocketFrame.NoMessage:
                    ...
                else:
                    ws.close()
                    todel.append(w[])
                print(e)
        
        #TODO: Move into an instance:
        if todel:
            for w in todel:
                if str(w) in http_server.websockets:
                    http_server.websockets.pop(str(w))
                    # TODO: check if closed
                if str(w) in session_data:
                    _ = session_data.pop(str(w))
                if str(w) in client_states:
                    tmp_client_state = client_states.pop(str(w))
                    for s in tmp_client_state:
                        tmp_instance = tmp_client_state[s[]]
                        tmp_instance._del(tmp_instance.ptr)
                        tmp_instance.rendered.free()
                    _ = tmp_client_state^
            todel = PythonObject([])
        
        #FIXME: improve the PythonObject.__init__([http_socket,...websockets])
        # (creating a list on each iteration is slow)
        # block until new http request or existing websocket event:
        tmp_slow_all_sockets = PythonObject([])
        tmp_slow_all_sockets.append(http_server.socket)
        for s in http_server.websockets.values(): 
            tmp_slow_all_sockets.append(s[])
        print("connected:", len(http_server), len(client_states))
        Python.import_module("select").select(tmp_slow_all_sockets, [], [])

@value
struct Instance:
    var ptr: UnsafePointer[NoneType]
    var _del: fn(UnsafePointer[NoneType])->None
    var _event: fn(ptr: UnsafePointer[NoneType], props: PythonObject)->Action
    var rendered: UnsafePointer[Bool]
    
    fn __init__[T:Component](inout self, owned arg: T):
        self.rendered = UnsafePointer[Bool].alloc(1)
        self.rendered[] = False
        var tmp_ptr = UnsafePointer[T].alloc(1)
        tmp_ptr.init_pointee_move(arg^)
        self.ptr = tmp_ptr.bitcast[NoneType]()
        fn tmp_del(ptr: UnsafePointer[NoneType]):
            ptr.bitcast[T]().destroy_pointee()
            ptr.free()
        self._del = tmp_del
        fn tmp_event(ptr: UnsafePointer[NoneType], props: PythonObject)->Action:
            _ref = Pointer.address_of(ptr.bitcast[T]()[])
            try:
                return _ref[].Event(props)
            except e: print(e)
            return Action.Error
        self._event = tmp_event
    
    fn __getitem__[T:Component](inout self)->ref[__origin_of(self)]T:
        return self.ptr.bitcast[T]()[]

trait Component(CollectionElement):
    def __init__(inout self, session: Session): ...     
    def Render(inout self, props: PythonObject)->PythonObject:
        ...
    def Event(inout self, data: PythonObject)->Action:
        ...

@value
struct Action:
    alias Render = 1 # update ui on current websocket
    alias Error = 2
    alias RenderSessions = 3 #TODO: update ui on all websockets
    var value: Int

def IntoJson(owned dom_tree: PythonObject) -> PythonObject:
    resp_py = Python.evaluate("{}")
    resp_py["event_type"] = "render"
    resp_py["dom_tree"] = dom_tree
    return Python.import_module("json").dumps(resp_py)

def AppendElement(el: PythonObject,*, to:PythonObject):
    to["element_nested"].append(el)

def Event(
    event_name: String,
    **kwargs: PythonObject
)->PythonObject:
    
    var tmp_py = Python.evaluate("{}")
    tmp_py["attribute_type"] = "event"
    tmp_py["EventName"] = event_name
    # default is event go to current component
    # TODO: if InstanceName in kwargs: js event there (example: "main_component")
    # (changes in index.html render_dom)
    for k in kwargs:
        tmp_py[k[]] = kwargs[k[]]
    return tmp_py

def OpenOrRaise(arg: String)->String:
    if (not Path(arg).exists()):
        raise "index.html and style.css"
    
    tmp_handler = open(arg, "rb")
    tmp_result = tmp_handler.read()
    tmp_handler.close()
    return tmp_result

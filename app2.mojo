from ui import *

# Example of creating routing and login system with components, 
# (don't use it as a login system, it's not complete)

def main():
    appdata = Python.dict()
    appdata["users"] = ["user1", "user2"]
    exit_if_client_not_in = PythonObject(["127.0.0.1"])
    serve_app[MainComponent](appdata, exit_if_client_not_in)

@value
struct MainComponent: #(Component):
    var input_login: String
    var connected: Optional[String]
    var session: Session
    def __init__(inout self, session: Session):
        self.connected = None
        self.input_login = "user name (user1 or user2)"
        self.session = session  

    def Event(inout self, data: PythonObject)->Action:
        if data["EventName"] == "change_input_login":
            self.input_login = str(data["value"])
        if data["EventName"] == "connect":
            if self.session.appdata()["users"].__contains__(self.input_login):
                self.connected = str(self.input_login)
        if data["EventName"] == "disconnect":
            self.connected = None
        return Action.Render
    
    def Render(inout self, props: PythonObject)->PythonObject:
        if self.connected:
            return Div(
                H1(
                    Text("Connected! " + self.connected.value()),
                    `class`= "bg-green"
                ),
                Button(
                    Text("Disconnect"),
                    click = Event("disconnect"),
                ),
                self.session.Render[Router]("simple_router"),
            )
        else: return Div(
            Text("login:"),
            Input(
                type='text', value=self.input_login,
                change=Event("change_input_login"),
            ),
            Button(
                Text("connect"),
                `class`= "btn", 
                click = Event("connect"),
            ),
            `class` = "bg-blue"
        )

@value
struct Router: #(Component):
    var current_page: String
    var session: Session
    def __init__(inout self, session: Session):
        self.current_page = "home"
        self.session = session 
    
    def Event(inout self, data: PythonObject)->Action:
        if data["EventName"] == "change_route":
            self.current_page = str(data["page_name"])
        return Action.Render
    
    def Render(inout self, props: PythonObject)->PythonObject:
        page = Div(
            Button(Text("home"), click=Event("change_route",page_name="home")),
            Button(Text("test"), click=Event("change_route",page_name="test"))
        )
        if self.current_page == "home":
            AppendElement(
                Div(
                    H1(Text("home")),
                    Text("Welcome to the home page!"),
                ), to = page
            )
        else:
            AppendElement(Div(H1(Text(self.current_page))), to=page)
        return page
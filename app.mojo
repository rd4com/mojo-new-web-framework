from ui import *

def main():
    appdata = Python.dict()
    appdata["messages"] = []
    exit_if_client_not_in = PythonObject(["127.0.0.1"])
    serve_app[MainComponent](appdata, exit_if_client_not_in)

@value
struct MainComponent: #(Component):
    var current_message: String
    var session: Session
    def __init__(inout self, session: Session):
        self.current_message = "Hello websocket"
        self.session = session  
    
    def Event(inout self, data: PythonObject)->Action:
        if data["EventName"] == "change_current_message":
            self.current_message = str(data["value"])
        if data["EventName"] == "add_message":
            self.session.appdata()["messages"].append(
                self.current_message
            )
        return Action.Render
    
    def Render(inout self, props: PythonObject)->PythonObject:
        all_messages = Div(style="background-color: lightblue;")
        for m in self.session.appdata()["messages"]:
            AppendElement(Text(m), to=all_messages)
            AppendElement(Br(), to=all_messages)

        return Div(
            Input(
                type='text', value=self.current_message,
                change=Event("change_current_message"),
            ),
            Button(
                Text("add message"),
                `class`= "btn", 
                click = Event("add_message"),
            ),
            self.session.Render[Counter]("counter"),
            self.session.Render[Counter]("counter2"),
            Br(),
            Button(
                Text("Messages"),
                HtmlSpan(
                    Text(len(self.session.appdata()["messages"])),
                    `class` = "badge"
                ),
                `class` = "btn btn-primary", type="button"
            ),
            all_messages,
        )

@value
struct Counter: #(Component):
    var count: Int
    var session: Session
    
    def __init__(inout self, session: Session):
        self.count = 0
        self.session = session
    
    def Event(inout self, data: PythonObject)->Action:
        if data["EventName"] == "increment":
            if data.__contains__("amount"):
                self.count += int(data["amount"])
            else:
                self.count+=1
        return Action.Render
    
    def Render(inout self, props: PythonObject)->PythonObject:
        return Div(
            H1(
                Text(self.session.InstanceName + " " + str(self.count))
            ),
            Button(
                Text("Increment"),
                `class` = "btn btn-success",
                click = Event("increment", amount = 2),
                # mouseover = Event("increment", amount = 1),
            )
        )


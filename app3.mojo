from ui import *

# Example for `session.sessiondata()`
# (A client-wide dictionary for all components in the current session)

def main():
    appdata = Python.dict()
    exit_if_client_not_in = PythonObject(["127.0.0.1"])
    serve_app[MainComponent](appdata, exit_if_client_not_in)

@value
struct MainComponent: #(Component):
    var session: Session
    def __init__(inout self, session: Session):
        self.session = session  
        self.session.sessiondata()["count"]=0
    
    def Event(inout self, data: PythonObject)->Action:
        return Action.Render
    
    def Render(inout self, props: PythonObject)->PythonObject:
        return Div(
            H1(
                Text(str(self.session.sessiondata()["count"])),
            ),
            self.session.Render[Counter]("counter"),
            self.session.Render[Counter]("counter2"),
        )

@value
struct Counter: #(Component):
    var session: Session
    
    def __init__(inout self, session: Session):
        self.session = session
    
    def Event(inout self, data: PythonObject)->Action:
        if data["EventName"] == "increment":
            self.session.sessiondata()["count"] += 1
        return Action.Render
    
    def Render(inout self, props: PythonObject)->PythonObject:
        return Div(
            H1(Text(self.session.sessiondata()["count"])),
            Button(
                Text("Increment"),
                click = Event("increment"),
            )
        )
<!-- # 🌐🦜mojo-web-framework -->
<!-- # 🏄🌊  -->
# 🐣 mojo-new-web-framework

> ⏭️ See at least [Server](#server) (if don't feel like reading the whole page now)

"The back-end and the front-end in the same structs!"

Work in progress, don't use in production.

**The hope is to give this an opportunity to grow,
feel free to fork, also to contribute fixes to bugs or suggestions.**

&nbsp;

    ✨ mojoproject.toml:
    🔮 nightly 2️⃣0️⃣2️⃣4️⃣🟪1️⃣0️⃣🟪1️⃣4️⃣0️⃣5️⃣

&nbsp;

### 🥚Summary
The idea is to build pages with structs instances stored on the server,

connected visitors remotely mutate their own instances with events.

The render method send the result page back.

The structs can be nested in html and html can be nested in structs.

It is done by abstracting html tags as functions that returns a tree.

The instances have an id so they are either created, retrieved or deleted.

An instance is deleted if it is not rendered anymore.

All of this is done on the server.

The json is rendered into HtmlElement in the browser!

&nbsp;

### 🐣 Examples: 
- [app.mojo](./app.mojo) is a small websocket chat
- [app2.mojo](./app2.mojo) is a simple login system with a page router

&nbsp;

**The `ui.mojo` need a lot of work,**
**it is using too much `UnsafePointer`.**

**`ui.mojo` should instead use the latest features of mojo.**

**`Variant` which always existed would simplify the `ui.mojo` a lot too 👍**

Next commits will be about making `ui.mojo` user-friendly!

&nbsp;

# More about

Components: 
    They are one or more instances of a struct.
    Web-frameworks use them to store states on the client-side,
    here, we create and store them on the server-side.
    That way, we can create them in mojo🔥 and Python🐍.
    The client-side send events and render html elements from json.

Sessions:
    They are websocket connections,
    each "visitor" have one to communicate with the server.
    When the session is closed, it's component instances are removed.

Appdata:
    It is a `PythonObject` dictionnary available to all sessions.
    That way, any Component of any session can have things in common.
    It is quite a simple way to have an in-memory simple DB.
    For example, multiple sessions can increment the same counter.

Sessiondata:
    It is a `PythonObject` dictionnary only available to one session.
    That way, any Component of one session can have things in common.
    Still in the todo list, quick to implement.


## Server
Because it is a work in progress, it should not be used in production.
(there could be a bug or an unexpected behaviour)

There is an additional safeguard for the server but it is untested:
    - `serve_app` takes a list of hosts as an argument,
        server check if new connections are from a host within the list.
        If it is not, the app should exit as a safeguard.

See [./ui_websocket.mojo](./ui_websocket.mojo) for default host and port:
```mojo
alias host="127.0.0.1"
alias port=8080
```

## Next Todos 
1. `sessiondata` (`self.session[]`)
- `Variant` for `ui.mojo` 


## Design
- `return Action.UpdateSessions` but what if page is currently interacted  ? 
    - how browser can remember focus of elements between new pages
- `**kwargs` props for `Render` or `__init__` or both ?
    - ✅ Added for `Render`
- `Event("increment")` with any instance_name ?
- url to event ?: `/api/?event_name='change_page'&value='home'`
    url->json->`T._event`
- let's let events bubble up trough their outer components if unhandled?
    - that way, nested components can send event to outer components

## Features
- ✅ each websocket has it's session and instances of `T:Component`
- ✅ garbage collection of `Component` instances
    - for example:
    ```mojo
    if rand()>0.5: 
        AppendElement(
            Render[Counter]("instance_name")
            to = page
        )
    ```
- ✅ render dom from a json tree
- ✅ an app-wide dictionary usable by all websocket sessions.
    (`self.session.appdata()`)
- ✅ hybrid events mixing js dom value with `**kwargs` !
    ```mojo
    return Input(
        type='colorpicker',
        value = self.input_value,
        change = Event("changed_input", lets_go=True)
    )
    ```
- ✅ Add a new html element easily
    ```python
    # my_elements.mojo
    alias H3 = CreateHtmlElement["h3"]()
    # Somewhere else:
    from my_elements import H3
    Div(H3(Text("Hello world")))
    ```

- ✅ `**kwargs` goes to html elements attributes

    Inspired by [lsx](https://github.com/lsh/lsx): 
    thanks to @ lukas 💯
    ```mojo
    return Div(
        Button(Text("Hello world")),
        `class` = "container",
        style = "border 1px blue",
        `id` = "MainDiv"
    )
    ```

- ✅ `style.css`

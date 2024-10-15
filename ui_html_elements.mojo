from python import PythonObject, Python

fn CreateHtmlElement[name: String]()->fn(*args: PythonObject, **kwargs: PythonObject) raises ->PythonObject:
    """Makes a new html tag usable in `Render`.
        Example:
        ```mojo
        # my_elements.mojo
        alias H3 = CreateHtmlElement["h3"]()
        # Somewhere else:
        from my_elements import H3
        Div(H3(Text("Hello world")))
        ```
        (`H3` in the example is defined once and then can be reused).
    """
    fn tmp(*args: PythonObject, **kwargs: PythonObject) raises ->PythonObject:
        var tmp_return = Python.evaluate("{}")
        tmp_return["element_type"] = name
        tmp_return["element_nested"] = []
        for arg in args:
            if arg[] is not None:
                tmp_return["element_nested"].append(arg[])
        for k in kwargs:
            tmp_return[k[]] = kwargs[k[]]
        return tmp_return
    return tmp

alias Div = CreateHtmlElement["div"]()
alias Button = CreateHtmlElement["button"]()
alias H1 = CreateHtmlElement["h1"]()
alias H2 = CreateHtmlElement["h2"]()
alias Text = CreateHtmlElement["text"]()
alias Input = CreateHtmlElement["input"]()
alias Br = CreateHtmlElement["br"]()
alias HtmlSpan = CreateHtmlElement["span"]()

# def main():
#     var x = Div(
#         Input(value="hello world"),
#         Button(Text("Add"))
#     )
#     print(x)

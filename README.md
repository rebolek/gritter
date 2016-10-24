# gritter

[![Join the chat at https://gitter.im/red-gitter/Lobby](https://badges.gitter.im/red-gitter/Lobby.svg)](https://gitter.im/red-gitter/Lobby?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
Gitter client written in Red

## About

This is very basic and unfinished Gitter client written in Red. To run it, type `do %gritter.red` in Red console. 
You would be prompted to type your Gitter token (there is no OAuth login yet).
After that, Gritter can run.

Do NOT expect it to be very useful right now, DO expect bugs and crashes.

## Structure

[Gitter API](https://github.com/rebolek/gritter/blob/master/gitter-api.red) can read/post Gitter messages. It has (I think) all Gitter functions implemented, but not all of them have been tested, so there may be some bugs. It converts JSON to Red format using [JSON parser](https://github.com/rebolek/gritter/blob/master/json.red). This parser is pretty simple, but it looks very stable.

Gitter messages are in Markdown format, that is converted with [Marky-Mark](https://github.com/rebolek/gritter/blob/master/marky-mark.red) that is extremly light version of [this Rebol script](https://github.com/rebolek/MarkyMark). More features will be added later, but current version is good enough to show most messages. Original Marky Mark emitted to HTML, this version emits to [Lest](http://lest.qyz.cz), which allows for more targets. Currently, Rich Text Dialect target is implemented only.

Rich Text Dialect (RTD) is an abstraction over the Draw dialect that allows to just care about the text and not about the placement, as the dialect does it automatically. RTD will be covered in separate document.

So the data flow is like this:

```
[JSON from Gitter]--converted to Red-->[Markdown from Gitter]--converted to Lest-->[Lest source]--converted to RTD-->[RTD source]--converted to Draw-->[Displayed by Red/View]
```

Of course it would be possible to generate the Draw dialect directly from Markdown, but the code would be ugly and not reusable. Lest and RTD are powerful tools that have their use outside of Gitter.

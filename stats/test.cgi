#!/usr/local/bin/r3 -cs

REBOL []

handle-get: function [] [
    prin [
        "Content-type: text/html" crlf
        crlf
        <!doctype html>
        <title> "Rebol 3 CGI Sample: Form" </title>
        <form method="POST">
            "Your name:"
            <input type="text" name="field">
            <input type="submit">
        </form>
    ]   
]

handle-post: function [] [
    data: to string! read system/ports/input
    fields: parse data "&="
    value: dehex select fields "field"
    prin [
        "Content-type: text/html" crlf
        crlf
        <!doctype html>
        <title> "Rebol 3 CGI Sample: Response" </title>
        "Hello," (join value "!")
    ]
]

main: does [
    switch get-env "REQUEST_METHOD" [
        "GET" [handle-get]
        "POST" [handle-post]
    ]
]

main


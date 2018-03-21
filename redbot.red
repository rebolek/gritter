Red []

do load %redbot-options.red

do %gitter-api.red
do %github-v3.red

; --- support funcs

strip-newline: function [text] [replace/all text newline space]

; ---


asterisk: #"*"
colon: #":"
open-block: #"["
close-block: #"]"
open-paren: #"("
close-paren: #")"

; --- global vars

bot-name: "@botthebot" ; "@redlangbot_twitter"
user: none
room: none
messages: none
reply: none

help: {
* `/help` - show this help
* `/time` - show current bot's time
* `@botthebot do <code>` - do following code and print last value
}
{
* **/issues**  - show five latest issues
* **/commits** - show five latest commits
}

; --- basic commands
;
;		TODO: some verbosity switch
;

join-room: func [
	room-name
] [
	print "=== Login sequence"
	user: gitter/user-info
	room: gitter/join-room user room-name
]

read-messages: func [] [
	print "=== Read messages"
	messages: gitter/get-unread user room
]

; TODO: move rules elsewhere

hallo-rule: [
	thru ["hi" | "hello"]
	(reply: "Hi!") ; TODO: add author's name
]

commits-rule: [
	thru ["show" | "list"]
	thru "commits"
	(reply: list-commits)
]

issues-rule: [
	thru ["show" | "list"]
	thru "issues"
	(reply: list-issues)
]

do-rule: [
	thru ["do"]
	any space
	copy value
	to end
	(reply: do-code value)
]

do-code: func [
	value
	/local id reply
][
	replace/all value "load" ""
	replace/all value "save" ""
	replace/all value "read" ""
	replace/all value "write" ""
	save/header %temp.red compose/deep [
		write %out mold do [(load value)]
	] []
	id: call "red %temp.red"
	wait 0.5
	call rejoin ["kill " id]
	read %out	
]

parse-command: func [
	message
	/local reply
] [
	reply: switch message/text [
		"/time" [reply: rejoin ["It is " now/time]]
		"/help" [help]
		"/issues" [list-issues]
		"/commits" [list-commits]
	]
	print ["=== Reply:" mold reply]
	if reply [gitter/send-message room reply]
]

parse-message: func [
	message
] [
	print ["--- Parsing" message/id]
	reply: none
	parse message/text [
		thru bot-name ; TODO: we expect that mention is at the beginning. it could not.
		[
			hallo-rule
		|	commits-rule
		|	issues-rule
		|	do-rule
		|	help-rule
		]
	]
	print ["=== Reply:" mold reply]
	if reply [gitter/send-message room reply]
]

process-mentions: func [] [
	print ["=== Process" length? messages/mention "messages"]
	foreach message messages/mention [
		print ["--- Processing" message]
		; we care only about messages for our bot (may change later)
		parse-message gitter/get-message room message
	]
]

process-messages: func [] [
print ["=== Process" length? messages/chat "messages"]
	foreach message messages/chat [
		print ["--- Processing" message]
		; we care only about messages for our bot (may change later)
		parse-command gitter/get-message room message
	]	
]

mark-messages: func [] [
	print ["=== Mark as read" length? messages/chat "messages"]
	gitter/mark-as-read user room messages/chat
]

; --- format responses

; TODO: make one function, it is basically the same

list-commits: function [] [
	return "TODO"
	; TODO
	output: copy {Here are five latest commits for [red](http://github.com/red/red):^/^/}
	commits: head remove/part skip to block! github/list-commits 'red/red 5 25
	foreach commit commits [
		append output rejoin [
			asterisk space open-block strip-newline commit/commit/message close-block
			open-paren commit/commit/url close-paren
			newline newline
		]
	]
	output
]

list-issues: func [] [
	return "TODO"
	; TODO
	output: copy {Here are five latest issues for [red](http://github.com/red/red):^/^/}
	issues: head remove/part skip to block! github/get-issues/repo 'red/red 5 25
	foreach issue issues [
		append output rejoin [
			asterisk space open-block issue/number close-block
			open-paren issue/html_url close-paren
			colon space issue/title
			newline newline
		]
	]
	output
]

; --- main

redbot: does [
	join-room 'red-gitter/lobby
	; TODO: this should be in forever loop
	forever [
		read-messages
		process-mentions ; TODO: use just process messages here?
		process-messages
		mark-messages
		wait 3 ; do not run like mad
	]
]

"Run Redbot by typing >> redbot"

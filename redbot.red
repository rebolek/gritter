Red []

do load %redbot-options.red

do %gitter-api.red
do %github.red

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

bot-name: "@redlangbot_twitter"
user: none
room: none
messages: none
reply: none

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
	messages: gitter/list-unread user room
]

; TODO: move rules elswhere

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
	(reply: attempt [do load value]) ; TODO: rewrite to be safer
]

parse-command: func [
	message
] [
	reply: none
	switch message/text [
		"/time" [reply: rejoin ["It is " now/time]]
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

; TODO: make oe function, it is basically the same

list-commits: function [] [
	output: copy {Here are five latest commits for [red](http://github.com/red/red):^/^/}
	commits: head remove/part skip github/list-commits 'red/red 5 25
	foreach commit commits [
		append output rejoin [
			asterisk space open-block strip-newline commit/commit/message close-block
			open-paren commit/commit/url close-paren
			newline newline
		]
	]
	output
]

list-issues: function [] [
	output: copy {Here are five latest issues for [red](http://github.com/red/red):^/^/}
	issues: head remove/part skip github/get-issues/repo 'red/red 5 25
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

join-room 'red-gitter/lobby
; TODO: this should be in forever loop
forever [
	read-messages
	process-mentions ; TODO: use just process messages here?
	process-messages
	mark-messages
	wait 3 ; do not run like mad
]


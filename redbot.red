Red []

do %redbot-options.red

do %gitter-api.red
do %github.red

asterisk: #"*"
open-block: #"["
close-block: #"]"
open-paren: #"("
close-paren: #")"

list-commits: function [] [
	output: copy {Here are five latest commits for [red](http://github.com/red/red):^/^/}
	issues: head remove/part skip github/list-commits 'red/red 5 25
	foreach issue issues [
		append output rejoin [
			asterisk space open-block
		]
	]
]

; --- main

room-name: 'red-gitter/lobby

user: gitter/user-info
room: gitter/join-room user room-name

; TODO: this should be in forever loop

messages: gitter/list-unread user room
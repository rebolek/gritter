Red[
	Title: "Stats Client"
	Author: "Boleslav Březovský"
]

#include %ansi-seq.red

base-url: https://rebolek.com/stats/data/red

sc: context [
	rooms: none
	users: none
	user-cache: #()
	room-cache: #()

	init: does [
		print "Init stats client"
		rooms: load base-url/room-list.red
		users: load base-url/user-list.red
		unless all [rooms users][do make error! "Cannot load user/room data"]
		; remove header and dummy value
		remove rooms
		remove users
		if 'none = users/1/1 [remove users]
		; BUILD build cache
		build-room-cache
		room-list: collect [foreach room rooms [keep room/1]]
		print "done!"
	]

	select-user: func [
		name
	][
		name: form name
		foreach user users [
			if equal? user/1 name [return user/2]
		]
	]

	select-room: func [
		name
	][
		name: form name
		foreach room rooms [
			if equal? room/1 name [return room/2]
		]
	]

	load-user: func	[
		name
		/local id
	][
		id: select-user name
		unless user-cache/:id [
			user-cache/:id: do load rejoin [base-url %/users/ id %.red]
		]
		user-cache/:id
	]
	load-room: func	[
		name
		/local id
	][
		id: select-room name
		unless room-cache/:id [
			room-cache/:id: load rejoin [base-url %/rooms/ id %.red]
		]
		room-cache/:id
	]

	show-user: func [name][
		user: load-user name
		print [
			"Name:" user/name newline
			"Joined on:" user/first newline
			"Messages:" user/total newline
			"Average messages per day:" user/total / (to float! now/date - user/first/date) newline
			"Most chatty on:" t: first sort/skip/compare/reverse to block! user/days 2 2 rejoin [#"(" select user/days t " messages)"] newline
			"Active in:" length? words-of user/rooms "rooms" newline
			"Favorite room:" t: first sort/skip/compare/reverse to block! user/rooms 2 2 rejoin [#"(" to percent! (select user/rooms t) / (to float! user/total) #")"] newline
		]
	]

	build-room-cache: func [
		; number of rooms is small enough we can prebuild our rooms cache
		; for easier manipulation
	][
		print "building cache..."
		foreach room rooms [
			load-room room/1
		]
	]
]
; --- GUI ---

window: [
	text-list data room-list [
		chart: load-room pick face/data face/selected
	]
]

; --- main ---
sc/init

either system/view [
	view window
][
	sc/show-user "rebolek"
]


Red[
	Title: "Stats Client"
	Author: "Boleslav Březovský"
]

base-url: http://stats.rebolek.com/data/red

rooms: load base-url/room-list.red
users: load base-url/user-list.red

; remove header and dummy value
remove rooms
remove users
if 'none = users/1/1 [remove users]

user-cache: #()
room-cache: #()

select-user: func [
	name
][
	foreach user users [
		if equal? user/1 name [return user/2]
	]
]

select-room: func [
	name
][
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
		user-cache/:id: load probe rejoin [base-url %/users/ id %.red]
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

build-room-cache: func [
	; number of rooms is small enough we can prebuild our rooms cache
	; for easier manipulation
][
	foreach room rooms [
		load-room room
	]
]

; --- GUI ---

window: [
	text-list data room-list [
		chart: load-room pick face/data face/selected
	]
]

; --- main ---

print "building cache..."
build-room-cache
room-list: collect [foreach room rooms [keep room/1]]
print "done!"

view window
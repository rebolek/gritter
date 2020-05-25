Red [
	Title: "Gitter API"
	Author: "Boleslav Březovský"
	File: %gitter-api.red
	Rights: "Copyright © 2016-2019 Boleslav Březovský. All rights reserved."
	License: 'BSD
	Date: "23-10-2016"
	Note: {
This link returns non-UTF8 data: https://api.gitter.im/v1/rooms/572d874bc43b8c6019719620/chatMessages?beforeId=5aede3eeff26986d0835ca5e 
	}
]

#include %http-tools.red

gitter: context [

token: none

verbose?: false ; force verbose mode

any-map?: func [
	"Return TRUE if VALUE is MAP! or OBJECT!"
	value
] [
	any [map? value object? value]
]

get-id: func [
	"Return ID from user or room object/map or pass ID"
	data
] [
	if path? data [data: get-room-info data] ; TODO: cache room info
	if any-map? data [data: data/id]
	data
]

map: function [
	"Make map with reduce/no-set emulation"
	data
] [
	value: none
	parse data: copy data [
		some [
			change set value set-word! (reduce ['quote value])
		|	skip
		]
	]
	make map! reduce data
]

; ----------------------------------------------------------------------------
;		gitter api
; ----------------------------------------------------------------------------
response: none
remaining-requests: 100
next-reset: (to integer! now) - 1

; TODO: store verbose output somewhere
info: func [value][if verbose? [print value]]

send: func [
	data
	"Send GET request to gitter API"
	/post "Send POST request"
		post-data
	/put
		put-data
	/delete
	/verbose
	/local
		call method link header ts print print* nowi
] [
	if verbose [verbose?: true]
	method: case [
		post   ['POST]
		put    ['PUT]
		delete ['DELETE]
		true   ['GET]
	]
	info ["Send/method:" method "data:" data "add.data:" any [post-data put-data]]
	link: make-url compose [https://api.gitter.im/v1/ (data)]
	append header: clear [] [
		Accept: "application/json"
	]
	if any [post put] [
		insert header [Content-Type: "application/json"]
		post-data: map any [post-data put-data]
	]
	if all [
		remaining-requests < 2
		0 < till-reset: next-reset - to integer! now
	][
		info ["Rate limit reached. Waiting" till-reset "seconds..."]
		wait till-reset
	]
	response: send-request/data/with/auth link method post-data header 'Bearer token
	if response/headers/X-RateLimit-Remaining [
		remaining-requests: to integer! response/headers/X-RateLimit-Remaining
	]
	if response/headers/X-RateLimit-Reset [
		ts: copy response/headers/X-RateLimit-Reset
		next-reset: to integer! (load ts) / 1000
	]
	switch/default response/code [
		200 [response/data]
		401 [
			; NOTE: we can be here not only because of rate limiting, but also because "unauthorized" access.
			if equal? response/data/error "Unauthorized" [
				; TODO: This is not best error handling that can be done, but it's at least something
				return none
			]
			; wait until next reset when applicable
			nowi: to integer! now
			either next-reset >= nowi [
				info ["Error 401: Need to wait for" next-reset - nowi "seconds."]
				wait next-reset - nowi + 1
				info "Wait over."
				call: [send]
				unless equal? 'get method [
					call/1: make path! call/1
					append call/1 method
					append call data
					if equal? 'post method [append call post-data]
					if equal? 'put method [append call put-data]
					do reduce probe call
				]
			][
				do make error! response/data/error
			]
		]
	][
		; TODO: what else can happen?
		info ["Return code: " response/code]
		response/data
	]
	response/data
]

; --- groups resource --------------------------------------------------------

get-groups: does [
	send %groups
]

group-rooms: func [
	group
] [
	send [%groups group %rooms]
]

; --- rooms resource

user-rooms: function [
	user
] [
	user: get-id user
	send [%user user %rooms]
]

get-room-info: function [
	room "Room name"
] [
	res: send/post %rooms [uri: room]
	if res/error [cause-error 'user 'message [rejoin ["error getting room '" room "': ^"" copy/part res/error 80 "^""]]]
	res
]

join-room: function [
	user
	room ""
	/by-id "Room arg is id instead of name"
] [
	user: get-id user
	unless by-id [room: select get-room-info room 'id]
	send/post [%user user %rooms] [id: room]
]

remove-user: function [
	user
	room
] [
	send/delete [%rooms room %users user]
]

update-topic: function [
	room
	topic
] [
	send/put [%rooms room] [topic: topic]
]

room-tags: function [
	room
	tags [string! issue! block!]
] [
	unless block? tags [tags: reduce tags]
;	tags: collect [foreach tag tags [keep rejoin [form tag ", "]]]
;	remove/part back back tail tags 2
;	send/put [%rooms room] rejoin [{^{"tags":"} tags {"^}}]
	send/put [%rooms room] json-map [tags: tags]
]

; TODO: index room

remove-room: function [
	room
] [
	send/delete [%rooms room]
]

get-users: function [
	room
] [
	room: get-id room
	send [%rooms room %users]
]

; --- messages resource

get-messages: function [
	room
	/with "skip, beforeId, afterId, aroundId, limit, q (search query)"
		values
] [
	room: get-id room
	data: copy [%rooms room %chatMessages]
	if with [append/only data values]
	messages: send data
	; if there's only one message in room, we get map! instead of block!,
	; so we need to make sure that block! is returned in all cases
	unless block? messages [messages: reduce [messages]]
	; Do date conversion. TODO: avatarUrl conversion (would probably need some checks)
	foreach message messages [
		message/sent: load message/sent
	]
	messages
]

get-message: function [
	room 	"Room object or ID"
	id 		"Message ID"
	/local message
] [
	room: get-id room
	message: send [%rooms room %chatMessages id]
	message/sent: load message/sent
	message
]

send-message: function [
	room
	text
] [
	room: get-id room
	send/post [%rooms room %chatMessages] [text: text]
]

update-message: function [
	room
	text
	id
] [
	room: get-id room
	send/post [%rooms room %chatMessages id] [text: text]
]

; --- user resource

user-info: does [first send %user]

get-user: func [name] [send [%users name]]

; TODO: make part of get-messages?
get-unread: function [
	user
	room
] [
	user: get-id user
	room: get-id room
	send [%user user %rooms room %unreadItems]
]

mark-as-read: function [
	user
	room
	messages [string! issue! block!]
] [
	user: get-id user
	room: get-id room
	unless block? messages [messages: reduce messages]
	unless empty? messages [
		send/post [%user user %rooms room %unreadItems] [chat: messages]
	]
]

get-orgs: function [
	user
] [
	user: get-id user
	send [%user user %orgs]
]

get-repos: function [
	user
] [
	user: get-id user
	send [%user user %repos]
]

get-channels: function [
	user
] [
	user: get-id user
	; TODO
]

; --- end of Gitter context

]

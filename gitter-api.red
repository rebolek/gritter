Red [
	Title: "Gitter API"
	Author: "Boleslav Březovský"
	File: %gitter-api.red
	Rights: "Copyright (C) 2016 Boleslav Březovský. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
	}
	Date: "23-10-2016"
	Note: {
	}
]

do %json.red
do %http-tools.red

gitter: context [

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

send: function [
	data
	"Send GET request to gitter API"
	/post "Send POST request"
		post-data
	/put
		put-data
] [
	method: case [
		post   ['POST]
		put    ['PUT]
		delete ['DELETE]
		true   ['GET]
	]
	link: make-url compose [https://api.gitter.im/v1/ (data)]
	header: [
		Accept: "application/json"
	]
	if any [post put] [
		insert header [Content-Type: "application/json"]
		post-data: json/encode map any [post-data put-data]
	] 
	ret: send-request/data/with/auth link method post-data header 'Bearer token
	ret/data
]

; --- groups resource --------------------------------------------------------

list-groups: does [
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
	send/post %rooms [uri: room]
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

list-users: function [
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
	send data
]

get-message: function [
	room 	"Room object or ID"
	id 		"Message ID"
] [
	room: get-id room
	send [%rooms room %chatMessages id]
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

; TODO: make part of get-messages?
list-unread: function [
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

list-orgs: function [
	user
] [
	user: get-id user
	send [%user user %orgs]
]

list-repos: function [
	user
] [
	user: get-id user
	send [%user user %repos]
]

list-channels: function [
	user
] [
	user: get-id user
	; TODO
]

; --- end of Gritter context

]
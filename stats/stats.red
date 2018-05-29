Red[
	Title: "Gitter statistics"
	Author: "Boleslav Březovský"
	Notes: {
Defines ROOMS and MESSAGES in global context (would be moved to stats context later).
ROOMS is rooms metadata.
MESSAGES is map of room messages with room id as key.
}
	To-Do: [
		"USERS should be USER-MESSAGES"
		{
			Room stats:
				room created on
				total messages
				top day
				top posters (should change top20 graph)
		}
		{
			Users stats:
				first message
				total messages
				top day
				top rooms (absolute/percentage)
		}
	]
]

do %../../red-tools/csv.red
do %../gitter-tools.red
do %../options.red

from: make op! func [value series][select series value]

circular!: object [
	size: 5
	list: []

	init: func [
		siz
	] [
		size: siz
		clear list
		insert/dup list 0 1 + size
	]

	on-deep-change*: function [owner word target action new index part][
		switch action [
			insert [
				remove target
			]
		]
	]
]

; ------------------------------------- 
; globals

messages: make hash! 100'000
users: #()
mentions: #() 	; TODO: move to users?
code: #()		; TODO: move to users?

; ------------------------------------- 

store: func [
	"Store data in respective directories in right file formats"
	file
	data
	/local path
][
	path: %stats/data/
	try [save rejoin [path %red/ file %.red] data]
	try [write rejoin [path %csv/ file %.csv] csv/encode data]
	try [write rejoin [path %json/ file %.json] json/encode data]
]

; todo add order, do all in refirements
sort-by-value: func [this that][this/2 > that/2]
sort-by-key: func [this that][this/1 < that/1]

sort-by: func [
	/key
	/value
	/asc
	/desc
	/local index fn
][
	case/all [
		key   [index: 1]
		value [index: 2]
		asc   [fn: '<]
		desc  [fn: '>]
	]
	func [this that][]
]

;  -------------- init func

init-rooms: func [
	/local room-files
] [
	print "Init rooms"
	room-files: read %messages/
	remove-each file room-files [not equal? %.red suffix? file]
	rooms: #()
	room-messages: #()
;	messages: make hash! 100'000
	foreach room room-files [
		room-id: form first split room #"."
		print ["Room:" room-id stats]
		r: rooms/:room-id: load rejoin [%rooms/ room-id %.red]
		room-messages/:room-id: load rejoin [%messages/ room]
		foreach message room-messages/:room-id [
			message/room: r/name
			message/room-id: room-id
			append messages message
		]  
	]
]
get-name: func [value][
	value: next split form value #"-"
	if equal? "datatype" last value [remove back tail value]
	if equal? ["gui" "branch"] next value [value/3: "gui"]
	last value
]
; message count for each room
get-message-count: func [
	;TODO: pass room name here as arg
;	/local msg-count
][
	print "Get messages"
	msg-count: copy []
	names: copy []
	foreach room words-of room-messages [
	;	room-info: gitter/get-room-info room 
		room-info: select rooms room
		; TODO: last split.. will produce just "datatype" from "red-red-map-datatype"
		name: last split room-info/name #"/"
		name: first split name #"-"
		repend/only names [name room-info/id]
		if get room-info/public [ ; FIXME: TRUE/FALSE here are WORD!, not LOGIC!
			print [room-info/name room-info/public]
			repend/only msg-count [name length? room-messages/:room]
		]
	]
	sort/compare msg-count :sort-by-value
	remove-each value msg-count [zero? value/2]
	insert/only msg-count [name count]
	store %msg-count msg-count
	insert/only names [name file]
	store %room-list names]

store: func [
	data		"Data to save"
	path 		"Path where to save (without /<filetype>/)"
	filename	"Filename without extension"
][
	save rejoin [to file! path %red/ file %.red] data
	write rejoin [to file! path %csv/ file %.csv] csv/encode data
	write rejoin [to file! path %json/ file %.json] json/encode data
]

init-users: func [
	/local name user user-cache
][
	; TODO: Init users should not rely on messages, so I would be able
	;		to download only compact form
	;		but AFAIK there's no API call to get user info
	print "Init users"
	user-cache: #()
	if exists? %users.red [user-cache: load %users.red]
	; 
	foreach message messages [
		name: any [message/author message/fromUser/username]
		; check if user is cached and if not, download their data
		unless user-cache/:name [
			print ["User" name "not cached, downloading"]
			wait 1 ; prevent hitting rate limit, before Gitter will go after me
			user-cache/:name: either message/author [
				user: gitter/get-user name ; NOTE: This is for compact mode, to get info about user
					; but this does not get avatalr url, that's available only in messages
					; which is stupid, what can I do, OMG
				user/avatars: copy []
				user/messages: copy []
				repend user/avatars ['full rejoin [https://avatars-02.gitter.im/gh/uv/4/ name]]
				user
			][
				make map! compose/deep [
					name: (name)
					id: (message/fromUser/id)
					avatars: [
						small (message/fromUser/avatarUrlSmall)
						medium (message/fromUser/avatarUrlMedium)
						full (message/fromUser/avatarUrl)
					]
					messages: (copy [])
				]
			]
		]
		; populate users object with cache data when required
		unless users/:name [
			users/:name: copy/deep user-cache/:name
		]
		; add current message to user
		append users/:name/messages message
	]
	save %users.red user-cache
	users
]

init-mentions: func [][
	print "Init mentions"
	foreach message messages [
		foreach mention message/mentions [
			name: mention/screenName
			either mentions/:name [
				mentions/:name: mentions/:name + 1 
			][
				mentions/:name: 1
			]
		]
	]
	mentions
]

init-code: func [][
	print "Init code"
	foreach message messages [
		if message-code: get-code message [
			name: message/fromUser/username
			either code/:name [
				code/:name: code/:name + length? message-code
			][
				code/:name: length? message-code
			]
		]
	]
]

; -- query

query: func [
	"Simple query dialect for filtering messages"
	dialect
	/local 
		name-rule room-rule match-rule
		value
][
	conditions: clear []
	value: none

	name-rule: ['name ['is | '=] set value string! (
		append conditions compose [equal? message/fromUser/username (value)]
	)]
	room-rule: ['room ['is | '=] set value string! (
		append conditions compose [equal? message/room-name (value)]
	)]
	match-rule: [set value string!(
		append conditions compose [find message/text (value)]
	)]

	parse dialect [
		some [
			name-rule
		|	room-rule
		|	match-rule
		]
	]

	collect [
		foreach message messages [
			if all conditions [keep message]
		]
	]
]

; -- stats for users

get-user-info: func [
	name
	/local messages comparator days rooms day room user
][
{
	Users stats:
		first message
		total messages
		top day
		top rooms (absolute/percentage)
}
	user: users/:name
	messages: select user 'messages
	comparator: func [this that][this/sent < that/sent]
	sort/compare messages :comparator

	days: copy #()
	rooms: copy #()
	print ["Checking messages for" name]
	foreach message messages [
		day: message/sent/date
		room: message/room
		either days/:day [days/:day: days/:day + 1][days/:day: 0]
		either rooms/:room [rooms/:room: rooms/:room + 1][rooms/:room: 0]
	]
	context compose [
		name: (name)
		id: (user/id)
		first: (messages/1/sent)
		total: (length? messages) 
		avatar: (user/avatars/full)
;		avatar_small: (user/avatars/small)
;		avatar_medium: (user/avatars/medium)
		days: (sort/skip/compare/reverse to block! days 2 2) ; NOTE: use map! here?
		rooms: (to map! sort/skip/compare/reverse to block! rooms 2 2)
	]
]

export-users: func [
	/local info comparator user-list
][
	print "-- Export users"
	user-list: copy []
	comparator: func [this that][this/sent < that/sent]
	foreach user words-of users [
		info: get-user-info user
		store rejoin [%users/ info/id] info
		repend/only user-list [info/name info/id]
	]
	insert/only user-list [none none] 	; NOTE: This is here to prevent problem in JS, where D3's CSV loader has some trouble
										;		identifying second line in data right. By inserting some line we can prevent it.
	insert/only user-list [name id]
	print "save user list and we're done"
	store %user-list user-list
]

get-top-users: func [
	/local top-messages
][
	; get top20 users by messags
	top-messages: sort/compare collect [
		foreach user words-of users [keep/only reduce [user length? users/:user/messages]]
	] :sort-by-value
	store %top20-messages head insert/only copy/part top-messages 20 ["name" "count"] 
	top-chars: sort/compare collect [
		foreach user words-of users [
			count: 0
			foreach m users/:user/messages [count: count + length? m/text]
			keep/only reduce [user count]
		]
	] :sort-by-value
	store %top20-chars head insert/only copy/part top-chars 20 ["name" "count"] 
]

fix-missing-dates: func [
	"Some days may not be present in dataset, let's add them with zero value"
	data
	/local dates index
][
	print "Fix-missing-dates"
	dates: sort words-of data
	repeat i (last dates) - first dates [
		index: i + first dates 
		unless select data index [
			data/:index: 0
		]
	]
	data
]

select-room: func [
	"Select room by ID or name"
	rooms	[block!]
	name
	/local room
][
	; try to select by ID
	if room: select rooms form name [return room]
	; try to select by name
	foreach room rooms [
		if equal? room/name form name [return room]
	]
	; give up
	none
]

get-dates: func [
	"We expect that messages are in disk cache"
	name "Room name , i.e.: red/red"
	; TODO: support passing in-memory cache
	/with
		data "TODO: Not implemented"
;	/local date dates msgs room
][
	print ["Get usage for" name]
	dates: copy #()
	msgs: any [
		attempt [
			room: gitter/get-room-info name
			select room-messages room/id
		]
		select select users form name 'messages
	]
	if empty? msgs [return none]
	filename: any [
		room/id
		name
	]
	print ["Room/user" name "has" length? msgs "messages."]
	print ["Memory usage:" stats]
	foreach message msgs [
		date: message/sent/date
		unless dates/:date [dates/:date: 0]
		dates/:date: dates/:date + 1
	]
	; TODO: fix missing should be here
	dates: fix-missing-dates dates
	dates: collect [
		foreach date words-of dates [
			keep/only reduce [date dates/:date]
		]
	]
	sort/compare dates :sort-by-key
; smooth data
	smoothed7: moving-average dates 7
	smoothed30: moving-average dates 30
	forall dates [
		index: index? dates
		append first dates pick smoothed7 index
		append first dates pick smoothed30 index
	]

	insert/only dates ["date" "value" "avg7" "avg30"]
	print ["Saving" filename]
	store rejoin [%rooms/ filename] dates
	dates
]

old-moving-average: func [
	"Naive implementation [modifies]"
	data "In form of [[key value][key value]...]"
	size "Filter size"
][
	forall data [
		sum: 0.0
		repeat i size [
			sum: sum + either data/:i [
				last-data: data/:i/2
			][
				last-data ; compensation for last value
			]
		]
		data/1/2: sum / size
	]
	data
]

sum: func [
	block
][
	total: 0.0
	forall block [total: total + block/1]
	total
]

moving-average: func [
	"Naive implementation"
	data "In form of [[key value][key value]...]"
	size "Filter size"
][
	buffer: make circular! []
	buffer/init size
	collect [
		forall data [
			append buffer/list data/1/2 ; data/1/2 because we expect data be in [key value][key value]... format
			keep (sum buffer/list) / size
		]
	]
]

count-qaa: func [
	"Count questions and answers (requires `rooms`)"
][
	qaa: copy []
	foreach room words-of room-messages [
		msgs: room-messages/:room
		forall msgs [
			if question? msgs/1 [
				answer: find-answer msgs/1 copy/part next msgs 50
				if answer [
					; only answered questions are added
					repend qaa [msgs/1 answer]
				]
			]
		]
	]
	qaa
]

find-answer: func [
	question
	messages
][
	author: question/fromUser/username
	foreach message messages [
		foreach mentioned message/mentions [
			if equal? author mentioned/screenName [
				return message
			]
		]
	]
	none
]

; --- get funcs

get-data: func [
	"Download and/or update rooms"
	/local groups group-id rooms 
][
	groups: gitter/get-groups
	group-id: groups/8/id
	rooms: gitter/group-rooms group-id
	unless exists? %rooms/ [make-dir %rooms/] ; TODO: move to prepare-environment
	foreach room rooms [
		if room/public [download-room/compact/verbose to path! room/name]
		save rejoin [%rooms/ room/id %.red] room
	]
	; FIXME: when #3223 is fixed, remove this
	workaround-3223
]

prepare-environment: func [
	"Make sure all required directories exist"
	/local dir dirs
][
	; prepare environment
	dirs: [
		%stats/ %stats/data/ 
		%stats/data/red/ %stats/data/red/rooms/ %stats/data/red/users/
		%stats/data/csv/ %stats/data/csv/rooms/ %stats/data/csv/users/
		%stats/data/json/ %stats/data/json/rooms/ %stats/data/json/users/
	]
	foreach dir dirs [
		unless exists? dir [
			make-dir dir
		]
	]
]

get-stats: func [
	"Generate stats CSV files"
][
	print "Starting..."
	prepare-environment
	; get data
	init-rooms
	init-users
;	init-mentions
;	init-code
	; export stats
	get-message-count
	foreach room words-of rooms [
		get-dates rooms/:room/name
	]
	get-top-users
	export-users
]

; ------------------------------------------------------------------------------

workaround-3223: func [
	"Fix %5780ef02c2f0db084a2231b0.red suffering from #3223"
;	/local data
][
	print "Workaround for #3223"
	data: read %messages/5780ef02c2f0db084a2231b0.red
	; first message
	print "fix message #1"
	data: find data "59bce6de1081499f1f3a89e8"
	replace data {"^{"} {"^^^{"}
	replace data {"^{"} {"^^^{"}
	replace data {"^}"} {"^^^}"} 
	replace data {"^}"} {"^^^}"}
	; second message
	print "fix message #2"
	data: find head data "5ac48eddc574b1aa3e65d82a"
	replace data {^}} {^^^}}
	data: find data "SHA256"
	data: next find data "}"
	replace data {^}} {^^^}}
	replace data {^{} "^^{"
	data: find data "and not this"
	replace data {^{} "^^{"
	write %messages/5780ef02c2f0db084a2231b0.red head data
]

; ------------------------------------------------------------------------------

; main code
print [
	"Red Gitter Stats loaded" newline
	"-----------------------" newline
	newline
	"Usage:" newline
	newline
	"* get-data - downloads new messages" newline
	"* get-stats - create csv files for web" newline
] 
; get-data ; downloads new messages
; get-stats ; create csv files for web

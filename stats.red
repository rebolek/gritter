Red[
	Title: "Gitter statistics"
	Author: "Boleslav Březovský"
	Notes: {
Defines ROOMS and MESSAGES in global context (would be moved to stats context later).
ROOMS is rooms metadata.
MESSAGES is map of room messages with room id as key.
}
	To-Do: [
		"MESSAGES should be ROOM-MESSAGES and USERS should be USER-MESSAGES"
		"and ALL-MESSAGES should be MESSAGES"
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

do %../red-tools/csv.red
do %gitter-tools.red
do %options.red


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

init-rooms: func [
	/local room-files
] [
	print "Init rooms"
	print "Loading..."
	room-files: read %messages/
	rooms: #()
	messages: #()
	all-messages: make hash! 50'000
	foreach room room-files [
		room-id: probe form first split room #"."
		rooms/:room-id: load rejoin [%rooms/ room-id %.red]
		messages/:room-id: load rejoin [%messages/ room]
		foreach message messages/:room-id [append all-messages message]  
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
	foreach room words-of messages [
	;	room-info: gitter/get-room-info room 
		room-info: select rooms room
		; TODO: last split.. will produce just "datatype" from "red-red-map-datatype"
		name: last split room-info/name #"/"
		name: first split name #"-"
		repend/only names [name room-info/id]
		if get room-info/public [ ; FIXME: TRUE/FALSE here are WORD!, not LOGIC!
			print [room-info/name room-info/public]
			repend/only msg-count [name length? messages/:room]
		]
	]
	sort/compare msg-count :sort-by-value
	remove-each value msg-count [zero? value/2]
	insert/only msg-count [name count]
	write %stats/data/msg-count.csv csv/encode msg-count
	insert/only names [name file]
	write %stats/data/names.csv csv/encode names
]

init-users: func [
	/local name
][
	print "Init users"
	users: #()
	foreach room words-of messages [
		foreach message messages/:room [
			name: message/fromUser/username
			unless users/:name [users/:name: copy []]
			append users/:name message
		]
	]
	users
]

; -- stats for users

get-user-info: func [
	name
	/local messages comparator days rooms
][
{
	Users stats:
		first message
		total messages
		top day
		top rooms (absolute/percentage)
}
	messages: select users name
	comparator: func [this that][this/sent < that/sent]
	sort/compare messages :comparator

	days: #()
	rooms: #()

	foreach message messages [
		day: message/sent/date
		either days/:day [
			days/:day: days/:day + 1
		][
			days/:day: 0
		]
	]

	user-stats: context compose [
		first: (messages/1/sent)
		total: (length? messages)
		days: (sort/skip/compare/reverse days 2 2) ; NOTE: use map! here?
	]
]

get-top-users: func [
	/local top-messages
][
	; get top20 users by messags
	top-messages: sort/compare collect [
		foreach user words-of users [keep/only reduce [user length? users/:user]]
	] :sort-by-value
	write %stats/data/top20-messages.csv csv/encode head insert/only copy/part top-messages 20 ["name" "count"] 
	top-chars: sort/compare collect [
		foreach user words-of users [
			count: 0
			foreach m users/:user [count: count + length? m/text]
			keep/only reduce [user count]
		]
	] :sort-by-value
	write %stats/data/top20-chars.csv csv/encode head insert/only copy/part top-chars 20 ["name" "count"] 
	
]

fix-missing-dates: func [
	"Some days may not be present in dataset, let's add them with zero value"
	data
	/local dates index
][
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
	rooms
	name
	/id "Select by ID instead of name"
][
	foreach room rooms [
		if any [
		;	equal? room
		][

		]
	]
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
			select messages room/id
		]
		select users form name
	]
	if empty? msgs [return none]
	filename: any [
		room/id
		name
	]
	print ["Room/user" name "has" length? msgs "messages."]
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
	smoothed: moving-average dates 7
	forall dates [
		index: index? dates
		dates/1/2: smoothed/:index
	]

	insert/only dates ["date" "count"]
	write probe rejoin [%stats/data/ filename %-dates.csv] csv/encode dates
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
	foreach room words-of messages [
		msgs: messages/:room
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
	unless exists? %rooms/ [make-dir %rooms/]
	foreach room rooms [
		if room/public [download-room/verbose to path! room/name]
		save rejoin [%rooms/ room/id %.red] room
	]
]

get-stats: func [
	"Generate stats CSV files"
][
	print "Starting..."
	init-rooms
	init-users
	unless exists? %stats/data/ [
		make-dir %stats/
		make-dir %stats/data/ ; TODO: can be it be done in one pass? 
	]
	get-message-count

	foreach room words-of rooms [
		get-dates rooms/:room/name

	]
	get-top-users
;	get-dates 'rebolek
]


; main code

; get-data ; downloads new messages
; get-stats ; create csv files for web

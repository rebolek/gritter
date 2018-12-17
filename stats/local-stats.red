Red[
	Note: "This file expects that `messages` is already filled with messages."
]

do %qobom.red ; TODO: redquire

today: now/date
yesterday: today - 1
sum: func [data /local result][result: 0 forall data [result: result + data/1] result]

print-top: func [
	"Print top five"
	data 
	/count value "Print different count"
][
	data: to block! data
	data: sort/skip/compare/reverse data 2 2
	value: any [value 5]
	repeat i value [
		print rejoin [i ". @" pick data i * 2 - 1 " - " pick data i * 2]
	]
]
top-chatters: make map! compose [
	last-day: (qobom messages [keep 'author where 'sent > (now - 24:00:00) count])
	last-3days: (qobom messages [keep 'author where 'sent > (now - 72:00:00) count])
	last-7days: (qobom messages [keep 'author where 'sent > (now - 168:00:00) count])
	last-30days: (qobom messages [keep 'author where 'sent > (now - 720:00:00) count]) ; FIXM: last-month
	total: (qobom messages [keep 'author where 'sent > (to date! 0) count])
]

activity: make map! compose [
	last-day: (sum values-of top-chatters/last-day)
	last-3days: (sum values-of top-chatters/last-3days)
	last-7days: (sum values-of top-chatters/last-7days)
	last-30days: (sum values-of top-chatters/last-30days)
	total: (sum values-of top-chatters/total)
]

unique-activity: make map! compose [
	last-day: (length? unique words-of top-chatters/last-day)
	last-3days: (length? unique words-of top-chatters/last-3days)
	last-7days: (length? unique words-of top-chatters/last-7days)
	last-30days: (length? unique words-of top-chatters/last-30days)
	total: (length? unique words-of top-chatters/total)
]

room-info: func [
	room-name
	/local room room-msgs
][
	room: select-room rooms room-name
	room-name: room/name
	room-msgs: qobom messages compose [keep * as map where 'room = (form room-name)]
	room/total-messages: length? room-msgs
	room/messages: room-msgs
	room/made-on: select last room-msgs 'sent
	if string? room/lastAccessTime [
		room/lastAccessTime: load room/lastAccessTime
	]
	room
]

round01: func [number][round/to number 0.01]

print-room-info: func [
	room
;	/local info days activity
][
	info: room-info room
	days: now/date - info/made-on
	activity: context [
		last-day: qobom info/messages [keep * as map where 'sent > (now - 24:00:00)]
	]
	print [
		"Room '" room "' exists for" days "days, has" info/userCount "users who posted" info/total-messages "messages," round01 to percent! (info/total-messages / to float! length? messages) "of all watched rooms." newline
		"There are" round01 (length? messages) / days "messages per day on average with" length? activity/last-day "messages in last 24 hours."
	]
]

print-rooms-info: func [
	/local info
][
comment [
	; update room data
	foreach room words-of rooms [
		info: room-info room
		rooms/:room: info
	]
]
	; print room info
	; TODO: sorting (by number of messages, users, age, ...)
	foreach room words-of rooms [
		room: select rooms room
		room: room-info room/name
		print [
			pad room/name 25 #"-" 
			pad/left form room/userCount 4 "users," 
			pad/left form length? room/messages 6 "messages, active for" 
			pad/left form now/date - room/made-on 5 "days."
		]
	]
]

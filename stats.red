Red[]

do %../red-tools/csv.red
do %gitter-tools.red

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
	unless value? 'rooms [
		print "Loading..."
		room-files: read %messages/
		rooms: #()
	 	foreach room room-files [
			room-name: probe to word! form first split room #"."
			rooms/:room-name: load rejoin [%messages/ room] 
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
;	/local msg-count
][
	print "Get messages"
	msg-count: []
	foreach room words-of rooms [
		; TODO: last split.. will produce just "datatype" from "red-red-map-datatype"
		repend/only msg-count [get-name room length? rooms/:room]
	]
	sort/compare msg-count :sort-by-value
	remove-each value msg-count [zero? value/2]
	insert/only msg-count [name count]
	write %stats/msg-count.csv csv/encode msg-count
]



init-users: func [
	/local name
][
	users: #()
	foreach room words-of rooms [
		foreach message rooms/:room [
			name: message/fromUser/username
			unless users/:name [users/:name: copy []]
			append users/:name message
		]
	]
	users
]


; -- stats for users

get-top10-users: func [
	/local top
][
	top: sort/compare collect [
		foreach user words-of users [keep/only reduce [user length? users/:user]]
	] :sort-by-value
	write %stats/top20.csv csv/encode head insert/only copy/part top 20 ["name" "count"] 
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

get-dates: func [
	name ; in "red-red" format instead of "red/red" (should fix in loader/saver)
	room
	/local date dates
][
	print ["Get usage for" name]
	dates: copy #()
	foreach message room [
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
	moving-average dates 7

	insert/only dates ["date" "count"]
	write rejoin [%stats/ name %-dates.csv] csv/encode dates
	dates
]

moving-average: func [
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

; main code

print "Starting..."
init-rooms
init-users
get-message-count

room: 'red-red
get-dates room select rooms room
user: "rebolek"
get-dates user select users user
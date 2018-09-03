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


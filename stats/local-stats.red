Red[
	Note: "This file expects that `messages` is already filled with messages."
]

do %qobom.red ; TODO: redquire

top-chatters: make map! compose [
	last-day: (sobom qobom messages [keep * where 'sent > (now - 24:00:00)] 'author)
	last-3days: (sobom qobom messages [keep * where 'sent > (now - 72:00:00)] 'author)
	last-7days: (sobom qobom messages [keep * where 'sent > (now - 168:00:00)] 'author)
	last-30days: (sobom qobom messages [keep * where 'sent > (now - 720:00:00)] 'author)
	total: (sobom qobom messages [keep * where 'sent > (to date! 0)] 'author)
]

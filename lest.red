Red []

lest: function [
	data
] [
	value: none
	stack: make block! 20
	out: make block! 2 * length? data
	temp: none

	; --- functions
	emit: func [value] [
		repend out value
		value
	]

	; --- rules
	emoji-rule: [
		'emoji set value word! (
			; TODO: improve this switch to support images also
			;		move TYPE out somewhere to settings
			type: 'plain-text ; unicode, image
			get-emoji: func [values] [pick values index? find [plain-text unicode] type]
			emit [
				'font 'fonts/emoji probe get-emoji probe switch value [
					smile smiley 	[[":)" "😀"]]
					disappointed 	[[":(" "😞"]]
				]
			]
		)
	]
	heading-rule: [
		set value ['h1 | 'h2 | 'h3 | 'h4 | 'h5 | 'h6]
		(append stack value)
		set value text-rule
		(
			; TODO: TEMP can be removed once TO matrix works as expected
			temp: 'fonts/temp
			temp/2: take/last stack
			emit ['newline 'font copy temp value 'newline]
		)
	]
	list-rule: [
		'ul
		some [
			'li set value text-rule (
				emit ['newline 'bullet 'font 'fonts/text value 'newline]
			)
		]
	]
	text-rule: [string! | char!]

	rules: [
		some [
			set value text-rule (emit ['font 'fonts/text value])
		|	'bold set value text-rule (emit ['font 'fonts/bold value])
		|	'italic set value text-rule (emit ['font 'fonts/italic value])
		|	'code set value text-rule (emit ['font 'fonts/fixed value])
		|	'nick set value text-rule (emit ['font 'fonts/nick value])
		|	'link set value text-rule (append stack value) set value url! (emit ['link take/last stack value])
		|	'newline 'blank (emit ['newline 'blank])
		|	'newline (emit ['newline])
		|	heading-rule
		|	list-rule
		|	emoji-rule
		]
	]

	; --- main
	parse data rules
	out
]
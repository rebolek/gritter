Red []

lest: function [
	data
] [
	value: none
	stack: make block! 20
	out: make block! 2 * length? data
	temp: none
	emoji-rule: [
		'emoji set value word! (
			; TODO: improve this switch to support images also
			;		move TYPE out somewhere to settings
			type: 'plain-text ; unicode, image
			get-emoji: func [values] [pick values index? find [plain-text unicode] type]
			append out probe reduce [
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
		set value string!
		(
			; TODO: TEMP can be removed once TO matrix works as expected
			temp: 'fonts/temp
			temp/2: take/last stack
			repend out ['newline 'font copy temp value 'newline]
		)
	]

	parse data [
		some [
			set value string! (repend out ['font 'fonts/text value])
		|	'bold set value string! (repend out ['font 'fonts/bold value])
		|	'italic set value string! (repend out ['font 'fonts/italic value])
		|	'code set value string! (repend out ['font 'fonts/fixed value])
		|	'nick set value string! (repend out ['font 'fonts/nick value])
		|	'link set value string! (append stack value) set value url! (repend out ['link take/last stack value])
		|	'newline (append out 'newline)
		|	heading-rule
		|	emoji-rule
		]
	]
	out
]
Red []

do %fonts.red
do %lest.red
do %rich-text.red

helpr: func [
	"Display helping informations about words and other values in GUI window"
	'word 		[any-type!] "Word to display help for"
	/only 		"Return RTD output only and do not show window"
	/local f i data
] [

	; ---

	draw-function-help: function [
		'word
		width
	] [
		; --- vars
		out: make string! 300
		spec: spec-of get word
		value: none
		usage: make string! 80
		description: make block! 5
		args: make block! 20
		refs: make block! 20
		data: make block! 20
		tabs: tab
		; --- rules
		help-string-rule: [
			set value string! (
				repend description [
					'font 'fonts/text
					rejoin [value #"."] 'newline
					'font 'fonts/fixed mold word
					'font 'fonts/text " is of type: "
					'font 'fonts/bold mold type? get word 
				]
			)
		]
		args-rule: [
			set value [word! | lit-word! | get-word!]
			opt [set type block!]
			opt [(desc: none) set desc string!]
			(
				repend data ['font 'fonts/text mold value]
				if desc [repend data ['tab 'font 'fonts/italic desc]]
				repend data ['newline 'tab 'font 'fonts/fixed mold type]
				append data 'newline 
			)
		]
		refinement-rule: [
			set value refinement!
			opt [(desc: none) set desc string!]
			(
				append usage rejoin [mold value #" "]
				repend data ['font 'fonts/text mold value tab 'font 'fonts/italic desc 'newline]
				tabs: "^-^-"
			)
			any args-rule
		]
		; --- main code
		append usage rejoin [word #" "]
		parse spec [
			opt help-string-rule
			any args-rule
			(args: copy data clear data)
			any refinement-rule
			(refs: data)
		]
		rich-text/info compose [
			para indent 5 origin 0x0
			font fonts/h5 "Usage" newline
			para indent 5 origin 0x0
			font fonts/fixed 
			para indent 0 origin 20x10
			(usage)
			para indent 5 origin 0x0
			font fonts/h5 "Description" newline
			para indent 0 origin 20x10
			(description)
			para indent 5 origin 0x0
			font fonts/h5 "Arguments" newline
			para indent 0 origin 20x10 tabs 40
			(args)
			para indent 5 origin 0x0
			font fonts/h5 "Refinements" newline
			para indent 0 origin 20x10 tabs 40
			(refs)
		] width
	]

	draw-object-help: function [
		"Return text description of an object"
		symbol 			[word!]
		width 			[integer!]
	] [
		; TODO: put various length limits to settings
		;	and allow to change them with refinements
		value: get symbol
		words: words-of value
		values: values-of value
		out: make block! 30
		tip: rejoin [
			symbol " is " type? value " with " length? values " values." newline
		]
		length: min 20 length? values
		probe tip
		out: compose/deep [
			para indent 5 origin 0x0
			font fonts/fixed (mold symbol)
			font fonts/text " is "
			font fonts/fixed (mold type? value)
			font fonts/text " with "
			font fonts/bold (form length? values)
			font fonts/text " values:"
			newline
			para tabs [40 140 240]
		] 
		repeat i length [
			value: either object? value: values/:i [
				mold words-of value
			] [
				trim/lines mold value
			]
			repend out [
				'tab 
				'font 'fonts/fixed 
				mold words/:i ":" 

				'tab
				mold type? values/:i

				'tab 
				'font 'fonts/text 
				copy/part value 30 
				either 30 < length? value ["..."][""] 
				'newline
			]
		]
		if length < length? values [
			append out [tab "..."]
		]
		rich-text/info probe out width
	]

	get-help: function [
		'word
		width
	] [
		switch/default type?/word get :word [
			function! action! op! native!	[draw-function-help :word width]
			object! map!					[draw-object-help :word width]
		] [
			rich-text/info probe compose/deep [
				para indent 5 origin 0x0
				font fonts/fixed (mold :word)
				font fonts/text " is of type "
				font fonts/fixed (mold type? get :word)
			] width
		]
	]

	; ---

	f: i: none
	width: 500 ; TODO: user configurable?

	data: get-help :word width

	either only [
		data/data
	] [
		view layout compose/deep [
			below
			f: field 500 (mold word) [
				print "ebter"
				w: load face/text
				o: probe get-help :w 500
				diff: i/size - o/size
				i/size: o/size
				i/draw: o/data
				p: face/parent
				; FIXME: This crashes View on macOS
			;	p/size: p/size - diff
				show p
			]
			i: image 
				253.246.227 
				(data/size) 
				draw [(data/data)]
		]
	]

]

describe-object: func [
	"Return text description of an object"
	symbol 			[word!]
	/local
		tip 		[string!]
		length 		[integer!]
		words 		[block!]
		values 		[block!]
] [
	; TODO: put various length limits to settings
	;	and allow to change them with refinements
	value: get symbol
	words: words-of value
	values: values-of value
	tip: rejoin [
		symbol " is " type? value " with " length? values " values." newline
	]
	length: min 10 length? values
	repeat i length [
		value: trim/lines mold values/:i
		append tip rejoin [
			tab words/:i ":" 
			tab copy/part value 15 
			either 15 < length? value ["..."][""] 
			newline
		]
	]
	if length < length? values [
		append tip "..."
	]
	tip
]

get-calltip: func [
	src 			[string!]
	/local
		code 		[block!]
		symbol 		[any-type!]
		value 		[any-type!]
		calltip 	[string!]
		tip length words values
] [
	; TODO: simplify the conditions, add more types
	code: try [load/all src]
	unless empty? code [
		symbol: first code
		value: either word? symbol [
			if unset? get/any symbol [return ""]
			get symbol
		] [
			symbol
		]
		calltip: case [
			any [
				function? :value
				action? :value
				routine? :value
				native? :value
				op? :value
			] [
				parse-calltip-spec symbol
			]
			string? value [
				rejoin [
					symbol " is string! with " length? value " characters." newline
					copy/part value 40 either (length? value) > 40 ["..."] [""]
				]
			]
			block? value [
				rejoin [
					symbol " is block! with " length? value " values." newline
					form copy/part value 10 either (length? value) > 10 ["..."] [""]
				]
			]
			any [
				object? value
				map? value
			] [
				describe-object symbol
			]
			not word? value [
				rejoin [mold type? value " with value " mold value]
			]
			true [
				mold value
			]
		]
	]
	calltip
]
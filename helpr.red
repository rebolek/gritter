Red []

do %fonts.red
do %lest.red
do %rich-text.red

helpr: func [
	"Display helping informations about words and other values in GUI window"
	'word 		[any-type!] "Word to display help for"
	/local
		out 	[string!]
		spec 	[block!]
		value
		type
		desc
		help-string-rule 	[block!]
		param-rule 			[block!]
		refinement-rule 	[block!]
		tabs 				[string!]
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
;	print mold description
	data: rich-text/info compose [
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
	] 500

	f: i: none

	view layout compose/deep [
		below
		f: field 500 (mold word)
		i: image 
			253.246.227 
			(data/size) 
			draw [(data/data)]
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
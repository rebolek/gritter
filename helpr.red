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
	] [
		print "func help"
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
		compose [
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
		]
	]

	draw-object-help: function [
		"Return text description of an object"
		symbol 			[word!]
	] [
		; TODO: put various length limits to settings
		;	and allow to change them with refinements
		value: get symbol
		words: words-of value
		values: values-of value
		out: make block! 30
		length: min 20 length? values
		append out draw-word-info/length symbol
		append out [
			"."
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
		out
	]

	draw-word-help: function [
		symbol
		/length
		/index
	] [
		value: get symbol
		out: make block! 30
		compose [
			para indent 5 origin 0x0
			font fonts/fixed (mold symbol)
			font fonts/text " is "
			font fonts/fixed (mold type? value)
			(either length [
				length: length? either block? value [value] [words-of value]
				compose [
					font fonts/text " with "
					font fonts/bold (form length)
					font fonts/text " values"
				]
			] [])
			(either index [
				compose [
					font fonts/text ", current index is "
					font fonts/bold (form index? value)
					font fonts/text
				]
			] [])
		]
	]

	get-help: function [
		'word
		width
	] [
		rich-text/info probe switch/default type?/word get :word [
			function! action! op! native!	[draw-function-help :word]
			object! map!					[probe draw-object-help :word]
			block! hash!					[draw-word-help/length/index :word]
		] [draw-word-help :word] width
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

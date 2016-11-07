Red [
	Title: "Marky Mark"
	Author: "Boleslav Březovský"
	File: %marky-mark.red
	Rights: "Copyright (C) 2016 Boleslav Březovský. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
	}
	Date: "7-11-2016"
	Note: {
		This is very basic MarkDown parser just for use in the Red Gitter client.
		It will be rewritten later based onRebol version of Marky-Mark.
	}
]

marky-mark: func [
	data
] [
	out: make block! 5'000
	text: make string! 2'000
	value: make string! 500
	stack: make block! 20
	; ---

	store: [
		(
			unless empty? text [
				append out copy text
				clear text
			]
		)
	]

	digits: 		charset [#"0" - #"9"]
	letters: 		charset [#"a" - #"z" #"A" - #"Z"]
	alphanum: 		union digits letters
	symbols: 		charset "@#$~&-/*%()[]{}=+<>,."
	alphanumsym: 	union alphanum symbols
	emoji-chars: 	charset [#"a" - #"z" #"0" - #"9" #"_"]

	; ---

	temp: []
	temp-pos: temp
	mark-stack: []

	select-command: func [mark] [
		print ["select-command from" mark]
		case [
			find ["**" "__"] mark ('bold)
			find ["*" "_"] mark ('italic)
			equal? "`" mark ('code)
		]
	]

	emit: func [
		value [block!]
	] [
		append out compose [(copy text) (reduce value)]
		clear text
	]

	; --- parse rules

	mark-rule: [
		(temp-pos: clear temp)
		copy mark ["**" | "__" | "*" | "_" | "`"]
		(insert mark-stack mark)
		(repend temp-pos reduce [quote select-command mark copy []])
		(temp-pos: last temp)
		some [
			mark-rule
		|	[(mark: first mark-stack) ahead mark break]
		|	content-rule	
		]
		(mark: take mark-stack)
		mark
		(if empty? mark-stack [append out temp])
	]

	content-rule: [
		(unless string? temp-pos [temp-pos: first append temp-pos copy ""])
		set value skip
		(append temp-pos value)
	]

	; ---

	code-rule: [
		#"`" copy value to #"`" skip (emit ['code value])
	]

	fenced-code-rule: [
		0 3 space
		copy mark ["```" | "~~~"]
		; TODO: info string ignored for now
		thru newline
		copy value
		to mark
		thru mark
		(emit ['code value])
	]

	link-rule: [
		#"["
		copy value 
		to #"]" ; TODO: should be much less forgiving
		skip
		(append stack value)
		#"("
		copy value
		to ")"	; TODO: see above
		skip
		(emit ['link take/last stack to url! value])
	]

	auto-link-rule: [
		copy value [
			["https" | "http"] "://" 
			some [some alphanum dot] 
			some alphanum
			any alphanumsym
		] 
		(emit ['link value to url! value])
	]

	nick-rule: [
		copy value [#"@" to space] ; TODO: improve ending condition
		(emit ['nick value])
	]

	em-rule: [
		#"*" copy value to #"*" skip 
		(emit ['italic value])
	]

	strong-rule: [
		"**" copy value to "**" 2 skip 
		(emit ['bold value])
	]

	atx-heading-rule: [
		copy value some [#"#"]
		(append stack length? value)
		some space
		copy value [to newline skip | to end]
		(emit [to word! rejoin ["h" take/last stack] value])
	]

	para-char-rule: [
		char-rule (append text value)
	]

	char-rule: [ ; rule [value]
		tab
	|	set value skip
	]

; --- additional rules

	emoji-rule: [
		#":" 
		copy value [some emoji-chars]
		#":" 
		(emit ['emoji to word! value])
	]

; ---

	rules: [
		some [
	;		mark-rule
			nick-rule
		|	fenced-code-rule	
		|	code-rule	
		|	link-rule
		|	auto-link-rule
		|	strong-rule
		|	em-rule
		|	atx-heading-rule
		; additional rules
		|	emoji-rule
		; catch all rule
		|	para-char-rule
		]
	]

	out: make block! 1000
	clear text
	parse data rules
	unless empty? text [append out copy text]
	copy out
]

; --- Lest

emit-rich: function [
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
			repend out ['font copy temp value]
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
		|	heading-rule
		|	emoji-rule
		]
	]
	out
]

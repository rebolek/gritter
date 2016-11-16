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
		It will be rewritten later based on Rebol version of Marky-Mark.
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
	mark: none

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

	line-start?: [
		mark:
		if (
			any [
				equal? mark head mark
				equal? newline first back mark
			]
		)
	]

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
		line-start?
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

; --- main rule

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

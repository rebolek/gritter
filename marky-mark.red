Red [
	Title: "Marky Mark"
	Author: "Boleslav Březovský"
	File: %marky-mark.red
	Rights: "Copyright (C) 2016 Boleslav Březovský. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
	}
	Date: "23-10-2016"
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

	digits: charset [#"0" - #"9"]
	letters: charset [#"a" - #"z" #"A" - #"Z"]
	alphanum: union digits letters
	symbols: charset "@#$~&-/*%()[]{}=+<>,."
	alphanumsym: union alphanum symbols

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
		copy mark ["```" | #"`"] copy value to mark thru mark (
			repend out [copy text 'code value]
			clear text
		)
	]

	fenced-code-rule: [
		0 3 space
		copy mark ["```" | "~~~"]
		; TODO: info string ignored for now
		thru newline
		copy value
		to mark
		thru mark
		(
			repend out [copy text 'code value]
			clear text
		)
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
		(
			append out reduce [copy text 'link take/last stack to url! copy value]
			clear text
		)
	]

	auto-link-rule: [
		copy value [
			["https" | "http"] "://" 
			some [some alphanum dot] 
			some alphanum
			any alphanumsym
		] (
			append out reduce [copy text 'link copy value to url! value]
			clear text
		)
	]

	nick-rule: [
		copy value [#"@" copy value to space] (
			repend out [copy text 'nick copy value]
			clear text
		)
	]

	em-rule: [
		#"*" copy value to #"*" skip (
			repend out [copy text 'italic copy value]
			clear text		
		)
	]

	strong-rule: [
		"**" copy value to "**" 2 skip (
			repend out [copy text 'bold copy value]
			clear text		
		)
	]

	para-char-rule: [
		char-rule (append text value)
	]

	char-rule: [ ; rule [value]
		tab
	|	set value skip
	]

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
		|	para-char-rule
		]
	]

	out: make block! 1000
	clear text
	parse data rules
	unless empty? text [append out copy text]
	copy out
]

; ---

emit-rich: function [
	data
] [
	value: none
	stack: make block! 20
	out: make block! 2 * length? data
	parse data [
		some [
			set value string! (repend out ['font 'fonts/text value])
		|	'bold set value string! (repend out ['font 'fonts/bold value])
		|	'italic set value string! (repend out ['font 'fonts/italic value])
		|	'code set value string! (repend out ['font 'fonts/fixed value])
		|	'nick set value string! (repend out ['font 'fonts/underline value])
		|	'link set value string! (append stack value) set value url! (repend out ['link take/last stack value])
		]
	]
	out
]

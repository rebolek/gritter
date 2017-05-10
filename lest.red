Red [
	Title: "Lest"
	Purpose: "Lest emitters"
	Author: "boelslav Březovský"
]

; rich-text emitter

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

; --- text-box! emiter

add-style: func [

] []

emit-text-box: function [
	data
	/width
		x-size
] [
	unless width [x-size: 530]
	value: none
	link: none
	stack: make block! 20
	styles: make block! 2 * length? data
	text: clear ""
	areas: copy [] ; TODO: CLEAR ?
	links: copy []
	position: 1
	length: 0 ; last text length, set by ADD-TEXT, used by ADD-STYLE

	add-text: func [value] [
		length: length? value
		unless empty? value [append text value]
	]
	add-style: func [value] [
		append styles probe compose [(position) (length) (value)]
		position: position + length ; TODO: is this necessary?
	]

	parse data [
		some [
			set value string! (
				add-text value
				add-style reduce ['font-name fonts/text/name 'font-size fonts/text/size]
			)
		|	'code set value string! (
				add-text value
				add-style reduce ['font-name fonts/fixed/name 'font-size fonts/fixed/size]
		)	
		|	'bold set value string! (
				add-text value
				add-style 'bold
		)
		|	'italic set value string! (
				add-text value
				add-style 'italic
		)
		|	'underline set value string! (
				add-text value
				add-style 'underline
		)
		|	'link set value string! (append stack value)
			set value url! (
				link: value
				add-text value: take/last stack
				repend links [position length? value link 1 + length? styles] ; text-position length value styles-position
				add-style reduce ['underline 'bold 'font-name fonts/text/name 'font-size fonts/text/size] ; FIXME: putting color here messes all styles
		)
		|	set value ['h1 | 'h2 | 'h3 | 'h4 | 'h5 | 'h6] (append stack value)
			set value string! (
				append value newline
				add-text value
				add-style reduce ['font-size (select [h1 24 h2 22 h3 20 h4 28 h5 15 h6 12] take/last stack)] ; TODO: do not set just size, but whole style
			)
		|	skip	
		]
	]
	make text-box! copy/deep compose/deep [
		text: (text)
		styles: [(styles)] 
		size: (as-pair x-size 300) ; TODO: how to get max Y-SIZE ?
		links: [(links)]
		link: [active 10.150.120 inactive 0.50.20]
	]
]

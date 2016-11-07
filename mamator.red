Red [
	Title: "Mamator - Markdown editor"
]

do %fonts.red
do %rich-text.red
do %marky-mark.red

clear fonts

fonts/base: make font! [
	name: "Segoe UI"
	size: 14
	color: 131.148.150
	style: []
	anti-alias?: yes
]

make-fonts [
	text: base 14 7.54.66 ;88.110.117
	bold: text #bold
	italic: text #italic
	underline: #underline
	link: #bold 38.139.210
	active-link: link #underline
	fixed: "Lucida Console" 42.161.152
	nick: underline 181.137.0
	emoji: "Segoe UI Symbol" 12 #bold 203.75.22
	h1: text 32 #bold
	h2: text 28 #underline
]

view layout [
	editor: area 300x200
		on-key-up [display/draw: rich-text emit-rich marky-mark editor/text 400]
	display: base 400x200 253.246.227
]
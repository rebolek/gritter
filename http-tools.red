Red [
	Title: "HTTP Tools"
	File: %http-tools.red
	Author: "Boleslav Březovský"
	Description: "Collection of tools to make using HTTP easier"
	Date: 10-4-2017
]

do %json.red

make-url: function [
	"Make URL from simple dialect"
	data
] [
	value: none
	args: clear []
	link: make url! 80
	args-rule: [
		ahead block! into [
			some [
				set value set-word! (append args rejoin [form value #"="])
				set value [word! | string! | integer!] (
					if word? value [value: get :value]
					append args rejoin [value #"&"]
				)
			]
		]
	]
	parse append clear [] data [
		some [
			args-rule
		|	set value [set-word! | file! | url! ] (append link dirize form value)
		|	set value word! (append link dirize form get :value)	
		]
	]
	unless empty? args [
		change back tail link #"?"
		append link args
	]
	head remove back tail link	
]

send-request: function [
	link 
	method
	/data 		"Use with POST and other methods"
		content
	/with 
		args
	/auth
		auth-type [word!]
		auth-data
] [
	header: clear #()
	if with [extend header args]
	if auth [
		switch auth-type [
			Basic [
				; TODO: Add basic authentization (see GitHub API)
			]
			OAuth [
				; TODO: Add OAuth (see Twitter API)
			]
			Bearer [
				; token passing for Gitter
				extend header compose [
					Authorization: (rejoin [auth-type space auth-data])
				]
			]
		]
	]
	data: reduce [method body-of header]
	if content [append data content]
	reply: write/info link data
	type: first split reply/2/Content-Type #";"
	map [
		code: reply/1
		headers: reply/2
		raw: reply/3
; TODO: decode data based on reply/2/Content-Type		
;		data: (www-form/decode reply/3 type)
		data: json/decode reply/3
	]
]
Red[
	Title: "QOBOM - Query over block of maps"
	Author: "Boleslav Březovský"
	Usage: {
```
keep [ <column> or * ] where
	<column> is <value>
	<column> [ = < > <= >= ] <value>
	<column> contains <value>
	<column> matches <parse rule>
```

<value> can be `paren!` and then is evaluated first
<value> can be `block!` and then is interpred as list of values that can match
	}
]

select-deep: func [
	series
	value
][
	either word? value [
		select series value
	][
		; path
		foreach elem value [
			series: select series elem
		]
	]
]

sort-by: func [
	"Sort block of maps"
	data
	match-column
;	keep-column ; TODO: support * for keeping everything 
;	TODO: sorting order
	/local result value
][
;	NOTE: How expensive is map!->block!->map! ? Is there other way?
	result: clear #()
	foreach item data [
		value: item/:match-column
		result/:value: either result/:value [
			result/:value + 1
		][
			1
		]
	]
	to map! sort/skip/compare/reverse to block! result 2 2
]

do-conditions: func [data conditions selector][
	collect [
		;probe conditions
		foreach item data [
			if all conditions [
				case [
					equal? '* selector 	[keep/only item]
					block? selector		[keep/only collect [foreach s selector [keep select-column item s]]]
					'default			[keep select-column item selector]
				]
			]
		]
	]
]

select-column: func [item selector][
	switch type?/word selector [
		none! [item]
		lit-word! lit-path! [select-deep item to path! selector]
		block! [
			collect [
				foreach key selector [keep select-deep item to path! key]
			]
		]
	]
]

count-values: func [
	"Count occurences of each value in DATA. Return map! with values as keys and count as values"
	data
	; TODO: support some refinement to return block! instead (or make it default?)
	/local result
][
	result: copy #()
	foreach value data [
		result/:value: either result/:value [result/:value + 1][1]
	]
	to map! sort/skip/compare/reverse to block! result 2 2
]

qobom: func [
	"Simple query dialect for filtering messages"
	data
	dialect
;	/local
;		name-rule room-rule match-rule
;		conditions value selector
;		result
][
	conditions: clear []
	value: none

	value-rule: [
		set value skip (
			if paren? value [value: compose value]
		)
	]

	col-rule: [
		set column [lit-word! | lit-path!]
		[
			'is 'from set value block! (
				append conditions compose/deep [
					find [(value)] select-deep item (column)
				]
			)
		|	['is | '=] value-rule (
				append conditions compose [
					equal? select-deep item (column) (value)
				]
			)
		|	set symbol ['< | '> | '<= | '>=] value-rule (
				append conditions compose [
					(to paren! reduce ['select-deep 'item column]) (symbol) (value)
				]
			)
		]
	]
	find-rule: [
		set column [lit-word! | lit-path!]
		'contains
		value-rule (
			append conditions compose [
				find select-deep item (column) (value)
			]
		)
	]
	match-rule: [
		set column [lit-word! | lit-path!]
		'matches
		value-rule (
			append value [to end]
			append conditions compose/deep [
				parse select-deep item (column) [(value)]
			]
		)
	]
	keep-rule: [
		; TODO: `keep` is filler just now, should probably do something
		; TODO: support multiple selectors
		'keep
		[
			set selector ['* | block! | lit-word! | lit-path!]
		]
		'where
	]
	sort-rule: [
		'sort 'by set value skip (
			sort-by result value
		)
	]
	do-cond-rule: [(
		result: do-conditions data conditions selector
	)]
	count-rule: [
		'count (result: count-values result)
	]
	parse dialect [
		opt keep-rule
		some [
			col-rule
		|	find-rule
		|	match-rule
		|	'and ; filler, so we can write [column contains something and column contains something-else] instead of [column contains something column contains something-else] (but both work)
		; TODO: add `OR` rule
		]
		do-cond-rule
;		opt sort-rule
		opt count-rule
	]
	result
]

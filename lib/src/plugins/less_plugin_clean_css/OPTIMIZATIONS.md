## Optimizations
Clean-css optimizations implemented in the less plugin

### Call function
	Remove spaces			Example: add(2, 2) -> add(2,2)

### Color
	Short name				Use shorter color name, #rrggbb, #rgb
	Alpha without 0.		Use .4 better than 0.4. Example: rgb(20,20,20,.4)
	Transparent				Use transparent instead of rgb(0,0,0,0.0)

### Dimension
	Remove units for 0		Example: 0px, 0deg -> 0

### Directive
	Remove empty block		Example: @-ms-viewport {} -> nothing

### Expression
	Remove space after )	Example: translate(0,11em)rotate(-90deg);

### Fonts
	Change bold				Example: font-weight: bold; -> font-weight:700;
	Change normal			Example: font-weight: normal; -> font-weight:400;

### Selectors
	Remove quotes			Example: input[type = "text"] -> input[type=text]




less-plugin-advanced-color-functions
====================================

Adds some advanced colour functions that helps in finding more contrasting colors: 

 - invertluma: inverts the luma of a color giving a version darken or lighter than the original
 - contrastmore: if color1 and color2 have a similar luma, it contrast color2 a little bit more. If the color2 luma resultant is greater than 1, or less than 0, its luma is pivoted around color1 luma.
 - autocontrast: if color1 and color2 have a similar luma, it contrast color2 a little bit more. 
If the color2 luma resultant is greater than 1, or less than 0, its luma gets inverted.

## Source & original copyright

https://github.com/less/less-plugin-advanced-color-functions

## lessc usage

```
npm install -g less-plugin-advanced-color-functions
```

and then on the command line,

```
lessc file.less --advanced-color-functions
```

## Programmatic usage

```
var LessPluginAdvancedColorFunctions = require('less-plugin-advanced-color-functions'),
    AdvancedColorFunctions = new LessPluginAdvancedColorFunctions();
less.render(lessString, { plugins: [AdvancedColorFunctions] })
  .then(
```

## Browser usage

Browser usage is not supported at this time.

## Example

```css
@color1: #ff0000;
@color2: #ee0000;

.colors {
invertluma: invertluma(@color1);
contrastmore: contrastmore(@color1,@color2);
autocontrast: autocontrast(@color1,@color2);
autocontrast50: autocontrast(@color1,@color2,50%);
}
```

outputs:

```css
.colors {
  invertluma: #ff0000;
  contrastmore: #650000;
  autocontrast: #ff7878;
  autocontrast50: #ffdede;
}
```

The compiled coloures will look like that shown below:
![contrasting colours used in buttons](http://imgur.com/CqwTiO9.png?1)


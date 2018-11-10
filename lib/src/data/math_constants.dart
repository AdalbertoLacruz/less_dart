// source: less/math-constants.js 3.5.3 20180708

// How to process math

/// Eagerly try to solve all operations
const int MATH_ALWAYS = 0;

/// Require parens for division "/"
const int MATH_PARENS_DIVISION = 1;

/// Require parens for all operations. Same as strict.
const int MATH_PARENS = 2;

/// Legacy strict behavior (super-strict)
const int MATH_STRICT_LEGACY = 3;

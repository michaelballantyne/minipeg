## minipeg: A small Parsing Expression Grammars implementation

[Parsing Expression Grammars](https://bford.info/pub/lang/peg.pdf) (PEGs) are a simple alternative to Context Free Grammars for describing and parsing syntax. This package implements PEGs as a hosted DSL in Racket. Parser specifications with `minipeg` easily mix with Racket expressions that construct abstract syntax or perform other semantic actions.

Here's what a parser for a simple language of binary expressions over natural number literals looks like in the DSL:

```
#lang racket

(require minipeg)

(define-peg digit (char-pred char-numeric?))
(define-peg num (alt (seq digit num)
                     eps))
(define-peg op (alt #\+ #\-))
 
(struct binop [op n1 n2] #:transparent)
(define-peg arith-expr
  (=> (seq (: n1 num) (: o op) (: n2 num))
      (binop o (string->number n1) (string->number n2))))
 

> (peg-parse arith-expr "1+2")
(binop "+" 1 2)
```

Left-recursive nonterminal specifications in PEGs are undesirable because theyy lead to diverging parses. The DSL implementation includes a check that identifies this situation and raises a compile-time error.


## Installing and running

Check out this Git repository, change directory into it, and run:


```
raco pkg install
```

Then import as

```
(require minipeg)
```

Once installed, you can access the documentation via:

```
raco docs minipeg
```

Finally, you can run the tests with:

```
raco test -p minipeg
```

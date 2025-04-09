#lang scribble/manual

@(require scribble/example
          (for-syntax racket/base)
          (for-label racket minipeg))

@; Create an evaluator to use for examples blocks with the DSL required.
@(define eval (make-base-eval '(require racket minipeg)))

@; A helper for creating references to forms defined in a binding space.
@(define-syntax (racket/space stx)
   (syntax-case stx ()
     [(_ id space)
      #'(racket #,((make-interned-syntax-introducer (syntax-e #'space)) #'id))]))

@title{minipeg: A small Parsing Expression Grammars implementation}
@author+email["Michael Ballantyne" "michael.ballantyne@gmail.com"]

@defmodule[minipeg]


@link["https://bford.info/pub/lang/peg.pdf"]{Parsing Expression Grammars} (PEGs) are a simple alternative to Context Free Grammars for describing and parsing syntax. This package implements PEGs as a hosted DSL in Racket. Parser specifications with @tt{minipeg} easily mix with Racket expressions that construct abstract syntax or perform other semantic actions.


@defform[(define-peg nt-name peg)]{
Defines a @deftech{PEG nonterminal}, uses of which will parse with the given @tech{PEG expression}.
}

@defform[(peg-parse peg expr)]{
Parses the string produced by @racket[expr] using the given @tech{PEG expression}. Returns the result of a @racket/space[=> peg] semantic action, or the matched string for a successful parse without a semantic action, or @racket[#f] indicating a parse failure.
}

@examples[#:eval eval #:label #f
(eval:no-prompt
  (define-peg digit (char-pred char-numeric?))
  (define-peg num (alt (seq digit num)
                       eps))
  (define-peg op (alt #\+ #\-))

  (struct binop [op n1 n2] #:transparent)
  (define-peg arith-expr
    (=> (seq (: n1 num) (: o op) (: n2 num))
        (binop o (string->number n1) (string->number n2)))))
(peg-parse arith-expr "1+2")
]


@defform[(define-peg-macro name transformer-expr)]{
Defines a macro that will expand in @tech{PEG expression} positions.
}

For example, it is possible to define the @racket/space[? peg] operator by expansion to @racket/space[alt peg] and @racket/space[eps peg].

@examples[#:eval eval #:label #f
(eval:no-prompt
  (define-peg-macro my-?
    (syntax-rules ()
      [(_ p) (alt p eps)])))
]

@section{PEG expressions}

@(define peg-expr-syntax "peg expression syntax")

A @deftech{PEG expression} is a reference to an @tech{PEG nonterminal} or one of the @racket/space[eps peg], @racket/space[char-pred peg], @racket/space[alt peg], @racket/space[* peg], @racket/space[? peg], @racket/space[=> peg], or @racket/space[: peg] forms.

@defidform[#:kind peg-expr-syntax
           eps]{
A parser that always succeeds without consuming any of the input string.
}

@defform[#:kind peg-expr-syntax
         (char-pred expr)
         #:contracts ([expr (-> char? boolean?)])]{
A parser that consumes one character of the input if it matches the given predicate.
}

@defform[#:kind peg-expr-syntax
         (seq peg ...)]{
Match all of the @racket[peg]s in sequence.
}

@defform[#:kind peg-expr-syntax
         (alt peg ...)]{
Matches if any of the @racket[peg]s match. They are tried in-order, and parsing commits to the first successful one.
}

@defform[#:kind peg-expr-syntax
         (* peg)]{
Match zero or more repetitions.
}

@defform[#:kind peg-expr-syntax
         (? peg)]{
Match zero or one repetition.
}

@defform[#:kind peg-expr-syntax
         (=> peg expr)]{
Parse with the @racket[peg]. If it succeeds, parse variables bound by @racket/space[: peg] forms within are in scope for the @racket[expr]. The value produced by the @racket[expr] is the semantic value of the parse.
}

@defform[#:kind peg-expr-syntax
         (: parse-var peg)]{
Parse with the @racket[peg] and bind the semantic value to the parse variable. When there is no semantic value, the parse variable receives the string that was parsed.
}
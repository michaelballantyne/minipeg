#lang racket

(require "../main.rkt" rackunit)

;; Because the DSL implementation uses a binding space for
;; bindings of PEG operators such as `*`, we can use the
;; same-named forms from Racket without trouble.

(define-peg digit (char-pred char-numeric?))
(define-peg num (seq digit (* digit)))
(define-peg op (alt #\* #\/))

(struct binop [op n1 n2] #:transparent)
(define-peg arith-expr
  (=> (seq (: n1 num) (: o op) (: n2 num))
      (let ([nv1 (string->number n1)]
            [nv2 (string->number n2)])
        (match o
          ["*" (* nv1 nv2)]
          ["/" (/ nv1 nv2)]))))

(check-equal?
 (peg-parse arith-expr "2*3")
 6)


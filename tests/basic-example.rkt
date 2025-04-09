#lang racket

(require "../main.rkt" rackunit)

(define-peg digit (char-pred char-numeric?))
(define-peg num (alt (seq digit num)
                     eps))
(define-peg op (alt #\+ #\-))

(struct binop [op n1 n2] #:transparent)
(define-peg arith-expr
  (=> (seq (: n1 num) (: o op) (: n2 num))
      (binop o (string->number n1) (string->number n2))))

(check-equal?
 (peg-parse arith-expr "1+2")
 (binop "+" 1 2))


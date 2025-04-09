#lang racket

(require "../main.rkt" rackunit)

(define-peg digit (char-pred char-numeric?))
(define-peg num (alt (seq digit num)
                     digit))
(define-peg op (alt #\+ #\-))

(check-exn
 #rx"n: undefined; cannot use before initialization"
 (lambda ()
   (define-peg signed-num3 (=> (seq (: o (=> (: o2 op)
                                             (if (equal? o2 "-")
                                                 (- (string->number n))
                                                 (string->number n))))
                                    (: n num))
                               o))
  
   (peg-parse signed-num3 "-5")))
  







 
#lang racket

(require "../main.rkt"
         syntax/macro-testing
         rackunit)


(define-peg digit (char-pred char-numeric?))
(define-peg maybe-digit (alt (char-pred char-numeric?) eps))
(define-peg num1 (seq digit (* digit)))

(check-equal?
 (peg-parse num1 "123")
 "123")

;; Right recursion is okay
(define-peg num2 (alt (seq digit num2)
                      digit))
(check-equal?
 (peg-parse num2 "123")
 "123")

;; Left recursion raises a static error

(check-exn
 #rx"num3: left recursion!"
 (lambda ()
   (convert-compile-time-error
    ;; Left recursion
    (let ()
      (define-peg num3 (alt (seq num3 digit)
                            digit))
      (peg-parse num3 "123")))))

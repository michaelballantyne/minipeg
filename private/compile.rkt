#lang racket

(provide compile-peg)

(require (for-template
          racket/base
          racket/undefined
          (prefix-in rt: "runtime.rkt"))
         syntax/parse)

;; PegSyntax -> RacketSyntax
;; The generated Racket expression is a Parser
;; which is a (-> (List Character) ParseResult).
;;
;; Example:
#; (alt2 (seq2 digit num)
         eps)
;; =>
#; (rt:alt2 (rt:seq2 digit num)
            rt:eps)
;;
;; Example:
#;(=> (seq2 (: n1 num) (seq2 (: o op) (: n2 num)))
    (binop o (string->number n1) (string->number n2)))
;; =>
#;(let ([n1 undefined] [o undefined] [n2 undefined])
  (rt:=> (rt:seq2 (rt:: num (lambda (v) (set! n1 v)))
                  (rt:seq2 (rt:: op (lambda (v) (set! o v)))
                           (rt:: n2 (lambda (v) (set! n2 v)))))
         (lambda () (binop o (string->number n1) (string->number n2)))))

(define (compile-peg peg)
  (syntax-parse peg
    #:datum-literals (eps char-pred alt2 seq2 * => :)
    [eps #'rt:eps]
    [nt:id #'nt]
    [c:char #'(rt:char c)]
    [(char-pred e) #'(rt:char-pred e)]
    [(alt2 p1 p2)
     (define/syntax-parse p1^ (compile-peg #'p1))
     (define/syntax-parse p2^ (compile-peg #'p2))
     #'(rt:alt2 p1^ p2^)]
    [(alt2 p1 p2) #`(rt:alt2 #,(compile-peg #'p1) #,(compile-peg #'p2))]
    [(seq2 p1 p2) #`(rt:seq2 #,(compile-peg #'p1) #,(compile-peg #'p2))]
    [(* p) #`(rt:p* #,(compile-peg #'p))]
    [(=> p e)
     (define/syntax-parse (x ...) (peg-bound-vars #'p))
     #`(let ([x undefined] ...)
         (rt:=>
          #,(compile-peg #'p)
          (lambda () e)))]
    [(: name p)
     #`(rt:: #,(compile-peg #'p) (lambda (val) (set! name val)))]))


;; PegSyntax -> (ListOf Identifier)
;; Find all the names bound by `:` patterns that should be visible in a => semantic
;; action surrounding this PEG. Looks within sequences and `*`. Assumes that the
;; bindings are unique, which is guaranteed if syntax passes the spec.
(define (peg-bound-vars p)
  (syntax-parse p
    #:datum-literals (: seq2 *)
    [(: var peg)
     (list #'var)]
    [(seq2 p1 p2)
     (append (peg-bound-vars #'p1) (peg-bound-vars #'p2))]
    [(* p)
     (peg-bound-vars #'p)]))


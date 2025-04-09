#lang racket

(provide define-peg
         peg-parse
         define-peg-macro
         (for-space peg : * eps char-pred => ? seq alt))

(require syntax-spec-v3
         (for-syntax syntax/parse)
         (prefix-in rt: "private/runtime.rkt")
         racket/undefined
         "private/left-recursion-check.rkt"
         (for-syntax "private/compile.rkt"))

(begin-for-syntax
  (define (peg-var-binding-compiler id)
    #`(check-not-undefined #,id #'#,id)))

(define (check-not-undefined val id)
  (when (eq? val undefined)
    (raise-syntax-error #f "undefined; cannot use before initialization" id))
  val)

(syntax-spec
  (binding-class peg-var #:reference-compiler peg-var-binding-compiler)
  (binding-class peg-nt)
  (extension-class peg-macro #:binding-space peg)

  (nonterminal peg   
    ps:peg-seq
    #:binding (scope (import ps)))

  (nonterminal/exporting peg-seq
    #:allow-extension peg-macro
    #:binding-space peg
    
    (: v:peg-var p:peg)
    #:binding (export v)
    
    (seq2 ps1:peg-seq ps2:peg-seq)
    #:binding [(re-export ps1) (re-export ps2)]
    
    (* ps:peg-seq)
    #:binding (re-export ps)

    pe:peg-el)
  
  (nonterminal peg-el
    #:allow-extension peg-macro
    #:binding-space peg

    eps
    nt:peg-nt
    c:char
    (char-pred e:racket-expr)
    (alt2 p1:peg p2:peg)
    
    (=> ps:peg-seq a:racket-expr)
    #:binding (scope (import ps) a))

  (host-interface/definitions
    (define-peg nt:peg-nt p:peg)
    #:binding (export nt)
    (check-left-recursion! #'nt #'p)
    #`(define nt (lambda (in) (#,(compile-peg #'p) in))))
  
  (host-interface/expression
    (peg-parse p:peg e:racket-expr)
    #`(rt:peg-parse #,(compile-peg #'p) e)))

(define-syntax-rule
  (define-peg-macro name rhs)
  (define-dsl-syntax name peg-macro rhs))

(define-peg-macro ?
  (lambda (stx)
    (syntax-parse stx
      [(_ p)
       #'(alt2 p eps)])))

(define-peg-macro seq
  (lambda (stx)
    (syntax-parse stx
      [(_ p) #'p]
      [(_ p p* ...)
       #'(seq2 p (seq p* ...))])))

(define-peg-macro alt
  (lambda (stx)
    (syntax-parse stx
      [(_ p) #'p]
      [(_ p p* ...)
       #'(alt2 p (alt p* ...))])))


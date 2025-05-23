#lang racket

(provide (for-syntax check-left-recursion!))

(require syntax-spec-v3 (for-syntax syntax/parse))

(begin-for-syntax
  (define-persistent-symbol-table nullable-nt)
  
  (define (check-left-recursion! ntname peg)
    (define is-nullable (nullable-check?! peg))
    (symbol-table-set! nullable-nt ntname is-nullable))

  (define (nullable-check?! peg)
    (syntax-parse peg
      #:datum-literals (eps char-pred alt2 seq2 * : =>)
      [eps #t]
      [c:char #f]
      [(char-pred _) #f]
      [(alt2 p1 p2)
       (or (nullable-check?! #'p1)
           (nullable-check?! #'p2))]
      [(seq2 p1 p2)
       (and (nullable-check?! #'p1)
            (nullable-check?! #'p2))]
      [(* p) #t]
      [(: var p) (nullable-check?! #'p)]
      [(=> p e) (nullable-check?! #'p)]
      [nt:id
       (if (symbol-table-has-key? nullable-nt #'nt)
           (symbol-table-ref nullable-nt #'nt)
           (raise-syntax-error #f "left recursion!" #'nt))])))
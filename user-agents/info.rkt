#lang info

(define license 'BSD-3-Clause)
(define version "0.1")
(define collection "net")
(define deps
  '("base"
    "user-agents-lib"))
(define build-deps
  '("racket-doc"
    "scribble-lib"))
(define implies
  '("user-agents-lib"))
(define scribblings
  '(("user-agents/manual.scrbl")))

#lang racket/base

(require json
         net/user-agents
         racket/match
         racket/runtime-path
         rackunit)

(define-runtime-path firefox-ua-strings.json
  "firefox-ua-strings.json")
(define-runtime-path pgts-browser-list.json
  "pgts-browser-list.json")

(define-syntax-rule (if-null e d)
  (let ([tmp e])
    (cond
      [(eq? tmp (json-null)) d]
      [(equal? tmp "") d]
      [else tmp])))

(define user-agents-tests
  (test-suite
   "user-agents"

   (test-suite
    "firefox-ua-strings"

    (let ([data (hash-ref (call-with-input-file firefox-ua-strings.json read-json) 'test_cases)])
      (for ([data (in-list data)])
        (match-define
          (hash
           'user_agent_string ua-str
           'family family
           'major major
           'minor minor
           'patch patch)
          data)
        (test-case ua-str
          (define-values (ua _os _dev)
            (parse-user-agent ua-str))
          (check-equal? (ua-family ua) family)
          (check-equal? (ua-major ua) major)
          (check-equal? (ua-minor ua) minor)
          (check-equal? (ua-patch ua) (if-null patch #f))))))

   (test-suite
    "pgts-browser-list"

    (let ([cases (hash-ref (call-with-input-file pgts-browser-list.json read-json) 'test_cases)])
      (for ([data (in-list cases)])
        (match-define
          (hash
           'user_agent_string ua-str
           'family family
           'major major
           'minor minor
           'patch patch)
          data)
        (test-case ua-str
          (define-values (ua _os _dev)
            (parse-user-agent ua-str))
          (check-equal? (ua-family ua) family)
          (check-equal? (ua-major ua) (if-null major #f))
          (let ([minor (if-null minor #f)])
            (check-true
             (if minor
                 (equal? (ua-minor ua) minor)
                 (or (not (ua-minor ua))
                     (equal? (ua-minor ua) "")))))
          (let ([patch (if-null patch #f)])
            (check-true
             (if patch
                 (equal? (ua-patch ua) patch)
                 (or (not (ua-patch ua))
                     (equal? (ua-patch ua) "")))))))))))

(module+ test
  (require rackunit/text-ui)
  (run-tests user-agents-tests))

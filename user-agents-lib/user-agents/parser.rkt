#lang racket/base

(require json
         racket/contract/base
         racket/match
         racket/port
         racket/promise
         racket/runtime-path
         racket/string)

(provide
 (contract-out
  [parse-user-agent (-> string? (values ua? os? dev?))]
  [struct ua
    ([family string?]
     [major (or/c #f string?)]
     [minor (or/c #f string?)]
     [patch (or/c #f string?)])]
  [struct os
    ([family string?]
     [major (or/c #f string?)]
     [minor (or/c #f string?)]
     [patch (or/c #f string?)]
     [patch-minor (or/c #f string?)])]
  [struct dev
    ([family string?]
     [brand (or/c #f string?)]
     [model (or/c #f string?)])]
  [~ua (-> ua? string?)]
  [~os (-> os? string?)]
  [~dev (-> dev? string?)]))

(define-runtime-path parsers.json
  "parsers.json")

(struct ua (family major minor patch) #:transparent)
(struct os (family major minor patch patch-minor) #:transparent)
(struct dev (family brand model) #:transparent)

(struct ua-parser (re fam-rep v1-rep v2-rep v3-rep))
(struct os-parser (re fam-rep v1-rep v2-rep v3-rep v4-rep))
(struct dev-parser (re fam-rep brand-rep model-rep))
(struct parsers (ua os dev))

(define (get-re data)
  (define re-str (hash-ref data 'regex))
  (define flags (hash-ref data 'regex_flag #f))
  (pregexp (if flags (string-append "(?" flags ":" re-str ")") re-str)))

(define the-parsers
  (delay/sync
   (define data
     (call-with-input-file parsers.json
       read-json))
   (define ua-parsers
     (for/list ([d (in-list (hash-ref data 'user_agent_parsers))])
       (define re (get-re d))
       (define fam-rep (hash-ref d 'family_replacement #f))
       (define v1-rep (hash-ref d 'v1_replacement #f))
       (define v2-rep (hash-ref d 'v2_replacement #f))
       (define v3-rep (hash-ref d 'v3_replacement #f))
       (ua-parser re fam-rep v1-rep v2-rep v3-rep)))
   (define os-parsers
     (for/list ([d (in-list (hash-ref data 'os_parsers))])
       (define re (get-re d))
       (define fam-rep (hash-ref d 'os_replacement #f))
       (define v1-rep (hash-ref d 'os_v1_replacement #f))
       (define v2-rep (hash-ref d 'os_v2_replacement #f))
       (define v3-rep (hash-ref d 'os_v3_replacement #f))
       (define v4-rep (hash-ref d 'os_v4_replacement #f))
       (os-parser re fam-rep v1-rep v2-rep v3-rep v4-rep)))
   (define dev-parsers
     (for/list ([d (in-list (hash-ref data 'device_parsers))])
       (define re (get-re d))
       (define fam-rep (hash-ref d 'device_replacement #f))
       (define brand-rep (hash-ref d 'brand_replacement #f))
       (define model-rep (hash-ref d 'model_replacement #f))
       (dev-parser re fam-rep brand-rep model-rep)))
   (parsers ua-parsers os-parsers dev-parsers)))

(define (apply-replacement rep m [idx #f])
  (cond
    [rep
     (string-trim
      (regexp-replace*
       #rx"\\$([0-9]+)" rep
       (lambda (_ s)
         (or (list-ref m (string->number s)) ""))))]
    [(< idx (length m))
     (let ([res (list-ref m idx)])
       (and res (string-trim res)))]
    [else
     #f]))

(define (parse-user-agent ua-str)
  (let ([the-parsers (force the-parsers)])
    (values
     (or (parse-ua the-parsers ua-str) other-ua)
     (or (parse-os the-parsers ua-str) other-os)
     (or (parse-dev the-parsers ua-str) other-dev))))

(define (parse-ua ps ua-str)
  (for*/first ([p (in-list (parsers-ua ps))]
               #:do [(match-define (ua-parser re fam-rep v1-rep v2-rep v3-rep) p)]
               [m (in-value (regexp-match re ua-str))]
               #:when m)
    (ua
     #;family (apply-replacement fam-rep m 1)
     #;major (apply-replacement v1-rep m 2)
     #;minor (apply-replacement v2-rep m 3)
     #;patch (apply-replacement v3-rep m 4))))

(define (parse-os ps ua-str)
  (for*/first ([p (in-list (parsers-os ps))]
               #:do [(match-define (os-parser re fam-rep v1-rep v2-rep v3-rep v4-rep) p)]
               [m (in-value (regexp-match re ua-str))]
               #:when m)
    (os
     #;family (apply-replacement fam-rep m 1)
     #;major (apply-replacement v1-rep m 2)
     #;minor (apply-replacement v2-rep m 3)
     #;patch (apply-replacement v3-rep m 4)
     #;patch-minor (apply-replacement v4-rep m 5))))

(define (parse-dev ps ua-str)
  (for*/first ([p (in-list (parsers-dev ps))]
               #:do [(match-define (dev-parser re fam-rep brand-rep model-rep) p)]
               [m (in-value (regexp-match re ua-str))]
               #:when m)
    (dev
     #;family (apply-replacement fam-rep m 1)
     #;brand (apply-replacement brand-rep m 2)
     #;model (apply-replacement model-rep m 3))))

(define other-ua
  (ua "Other" #f #f #f))
(define other-os
  (os "Other" #f #f #f #f))
(define other-dev
  (dev "Other" #f #f))

(define (~ua the-ua)
  (call-with-output-string
   (lambda (out)
     (match-define (ua family major minor patch) the-ua)
     (display family out)
     (when major
       (display " " out)
       (display major out)
       (when minor
         (display "." out)
         (display minor out)
         (when patch
           (display "." out)
           (display patch out)))))))

(define (~os the-os)
  (call-with-output-string
   (lambda (out)
     (match-define (os family major minor patch patch-minor) the-os)
     (display family out)
     (when major
       (display " " out)
       (display major out)
       (when minor
         (display "." out)
         (display minor out)
         (when patch
           (display "." out)
           (display patch out)
           (when patch-minor
             (display "-" out)
             (display patch-minor out))))))))

(define (~dev the-dev)
  (call-with-output-string
   (lambda (out)
     (match-define (dev family brand _) the-dev)
     (when brand
       (display brand out)
       (display " " out))
     (display family out))))

#lang scribble/manual

@(require scribble/example
          (for-label net/user-agents
                     racket/base
                     racket/contract/base))

@title{User Agents}
@author[(author+email "Bogdan Popa" "bogdan@defn.io")]

@(define uap-core
  (hyperlink "https://github.com/ua-parser/uap-core" "uap-core"))

This package provides a user agent parser based on @|uap-core|.

@section{Reference}
@defmodule[net/user-agents]

@defproc[(parse-user-agent [user-agent string?]) (values ua? os? dev?)]{
  Returns the parsed user agent, operating system and device
  information for the given @racket[user-agent].
}

@defstruct[
  ua
  ([family string?]
   [major (or/c #f string?)]
   [minor (or/c #f string?)]
   [patch (or/c #f string?)])]{

  Represents parsed user agent information.
}

@defstruct[
  os
  ([family string?]
   [major (or/c #f string?)]
   [minor (or/c #f string?)]
   [patch (or/c #f string?)]
   [patch-minor (or/c #f string?)])]{

  Represents parsed operating system information.
}

@defstruct[
  dev
  ([family string?]
   [brand (or/c #f string?)]
   [model (or/c #f string?)])]{

  Represents parsed device information.
}

@deftogether[(
  @defproc[(~ua [some-ua ua?]) string?]
  @defproc[(~os [some-os os?]) string?]
  @defproc[(~dev [some-dev dev?]) string?]
)]{

  These procedures return normalized strings representing the given
  info struct instances.

  @examples[
    (require net/user-agents)
    (define ua-str
      (string-append
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 "
        "(KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36"))
    (define-values (ua os dev)
      (parse-user-agent ua-str))
    (~ua ua)
    (~os os)
    (~dev dev)
  ]
}

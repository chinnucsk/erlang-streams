erlang-streams
==============


An Erlang module for working with streams. Not a new idea, just a new
implementation (inspired by [stream.js](http://streamjs.org/)).


Quick start
-----------

    $ make
    ...
    $ erl -pa ebin
    ...
    1> S = streams:from_list([10, 20, 30]).
    ...
    2> streams:empty(S).
    false
    3> streams:length(S).
    3
    4> streams:head(S).
    10
    5> streams:head(streams:tail(S)).
    20
    6> streams:item(2, S). % 0 based lookup
    30
    7> streams:nth(3, S). % 1 based lookup
    30
    8> streams:take(10, streams:primes()).
    [2,3,5,7,11,13,17,19,23,29]
    9> streams:head(streams:dropuntil(fun (N) -> N > 1000 end, streams:fibs())).
    1597

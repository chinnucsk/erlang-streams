-module(streams).

-export([drop/2, dropuntil/2, dropwhile/2, empty/1, fibs/0, filter/2, from_list/1,
  head/1, item/2, length/1, map/2, new/0, new/1, new/2, nth/2, primes/0, range/0,
  range/1, range/2, range/3, tail/1, take/2, takeuntil/2, takewhile/2, zip/3]).

-compile({no_auto_import, [length/1]}).

-include_lib("eunit/include/eunit.hrl").

new() ->
  {}.

new(Term) ->
  {Term, fun () -> {} end}.

new(Term, Fun) ->
  {Term, Fun}.

from_list([]) ->
  new();
from_list([Head | Tail]) ->
  new(Head, fun () -> from_list(Tail) end).

empty({}) ->
  true;
empty({_, _}) ->
  false.

head({Term, _}) ->
  Term.

tail({_, Fun}) ->
  Fun().

length({}) ->
  0;
length({_, Fun}) ->
  length(Fun(), 1).

length({}, N) ->
  N;
length({_, Fun}, N) ->
  length(Fun(), N + 1).

item(0, {Term, _}) ->
  Term;
item(N, {_, Fun}) ->
  item(N - 1, Fun()).

nth(N, Stream) when N >= 1 ->
  item(N - 1, Stream).

range() ->
  range(1).

range(N) ->
  new(N, fun () -> range(N + 1) end).

range(Lo, Hi) ->
  range(Lo, Hi, 1).

range(Lo, Lo, _) ->
  new(Lo);
range(Lo, Hi, Step) ->
  new(Lo, fun () -> range(Lo + Step, Hi, Step) end).

take(0, _) ->
  [];
take(N, Stream) ->
  take(N, Stream, []).

take(0, _, Acc) ->
  lists:reverse(Acc);
take(N, {Term, Fun}, Acc) ->
  take(N - 1, Fun(), [Term | Acc]).

takeuntil(F, Stream) ->
  takeuntil(F, Stream, []).

takeuntil(F, {Term, Fun}, Acc) ->
  case F(Term) of
    true ->
      lists:reverse(Acc);
    false ->
      takeuntil(F, Fun(), [Term | Acc])
  end.

takewhile(F, Stream) ->
  takeuntil(fun (Term) -> not F(Term) end, Stream).

drop(0, Stream) ->
  Stream;
drop(N, Stream) ->
  drop(N - 1, tail(Stream)).

dropuntil(F, Stream={Term, Fun}) ->
  case F(Term) of
    true ->
      Stream;
    false ->
      dropuntil(F, Fun())
  end.

dropwhile(F, Stream) ->
  dropuntil(fun (Term) -> not F(Term) end, Stream).

zip(_, {}, _) ->
  {};
zip(_, _, {}) ->
  {};
zip(F, A, B) ->
  {F(head(A), head(B)), fun () -> zip(F, tail(A), tail(B)) end}.

map(_, Stream={}) ->
  Stream;
map(F, {Term, Fun}) ->
  {F(Term), fun () -> map(F, Fun()) end}.

filter(_, Stream={}) ->
  Stream;
filter(F, {Term, Fun}) ->
  case F(Term) of
    true ->
      {Term, fun () -> filter(F, Fun()) end};
    false ->
      filter(F, Fun())
  end.

primes() ->
  primes(range(2)).

primes({Term, Fun}) ->
  new(Term, fun () -> primes(filter(fun (N) -> N rem Term =/= 0 end, Fun())) end).

fibs() ->
  new(0, fun () -> new(1, fun () -> zip(fun (X, Y) -> X + Y end, fibs(), tail(fibs())) end) end).

empty_test_() -> [
    ?_assertEqual(true, empty(new()))
  , ?_assertEqual(false, empty(new(1)))
  , ?_assertEqual(false, empty(new(1, fun () -> new(2) end)))
  , ?_assertEqual(false, empty(from_list([1, 2, 3, 4, 5])))
  ].

head_test_() -> [
    ?_assertEqual(1, head(new(1)))
  , ?_assertEqual(1, head(new(1, fun () -> new(2) end)))
  , ?_assertEqual(1, head(from_list([1, 2, 3, 4, 5])))
  ].

tail_test_() -> [
    ?_assertEqual(true, empty(tail(new(1))))
  , ?_assertEqual(2, head(tail(new(1, fun () -> new(2) end))))
  , ?_assertEqual(2, head(tail(from_list([1, 2, 3, 4, 5]))))
  ].

length_test_() -> [
    ?_assertEqual(1, length(new(1)))
  , ?_assertEqual(2, length(new(1, fun () -> new(2) end)))
  , ?_assertEqual(5, length(from_list([1, 2, 3, 4, 5])))
  ].

item_test_() -> [
    ?_assertEqual(1, item(0, new(1)))
  , ?_assertEqual(1, item(0, new(1, fun () -> new(2) end)))
  , ?_assertEqual(2, item(1, new(1, fun () -> new(2) end)))
  , ?_assertEqual(1, item(0, from_list([1, 2, 3, 4, 5])))
  , ?_assertEqual(2, item(1, from_list([1, 2, 3, 4, 5])))
  ].

nth_test_() -> [
    ?_assertEqual(1, nth(1, new(1)))
  , ?_assertEqual(1, nth(1, new(1, fun () -> new(2) end)))
  , ?_assertEqual(2, nth(2, new(1, fun () -> new(2) end)))
  , ?_assertEqual(1, nth(1, from_list([1, 2, 3, 4, 5])))
  , ?_assertEqual(2, nth(2, from_list([1, 2, 3, 4, 5])))
  ].

take_test_() -> [
    ?_assertEqual([1], take(1, new(1)))
  , ?_assertEqual([1, 2], take(2, new(1, fun () -> new(2) end)))
  , ?_assertEqual([1, 2, 3], take(3, from_list([1, 2, 3, 4, 5])))
  , ?_assertEqual([1, 2, 3, 4], takeuntil(fun (N) -> N =:= 5 end, range()))
  , ?_assertEqual([1, 2, 3, 4], takewhile(fun (N) -> N < 5 end, range()))
  ].

drop_test_() -> [
    ?_assertEqual(true, empty(drop(1, new(1))))
  , ?_assertEqual([d, e], take(2, drop(3, from_list([a, b, c, d, e]))))
  , ?_assertEqual([5, 6, 7], take(3, dropuntil(fun (N) -> N =:= 5 end, range())))
  , ?_assertEqual([5, 6, 7], take(3, dropwhile(fun (N) -> N < 5 end, range())))
  ].

zip_test_() ->
  Stream = zip(fun (X, Y) -> {X, Y} end, from_list([1, 2, 3]), from_list([4, 5, 6])), [
    ?_assertEqual(false, empty(Stream))
  , ?_assertEqual(3, length(Stream))
  , ?_assertEqual({1, 4}, head(Stream))
  , ?_assertEqual({1, 4}, item(0, Stream))
  , ?_assertEqual({2, 5}, item(1, Stream))
  , ?_assertEqual({3, 6}, item(2, Stream))
  ].

map_test() ->
  ?assertEqual([1, 4, 9], take(3, map(fun (N) -> N * N end, range()))).

filter_test() ->
  ?assertEqual([2, 4, 6], take(3, filter(fun (N) -> N rem 2 =:= 0 end, range()))).

primes_test() ->
  ?_assertEqual([2, 3, 5, 7, 11, 13, 17, 19, 23, 29], take(10, primes())).

fibs_test() ->
  ?_assertEqual([0, 1, 1, 2, 3, 5, 8, 13, 21, 34], take(10, fibs())).

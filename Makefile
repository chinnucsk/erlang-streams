all:
	@test -d ebin || mkdir ebin
	@erl -make

test: all
	@erl -noshell -pa ebin -s streams test -s init stop

clean:
	@rm -rf ebin/* erl_crash.dump

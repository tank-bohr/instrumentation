-file("lib/instrumentation/demo.ex", 1).

-module('Elixir.Instrumentation.Demo').

-compile([no_auto_import]).

-export(['__info__'/1, hello/0, hello/1]).

-spec '__info__'(attributes |
                 compile |
                 functions |
                 macros |
                 md5 |
                 exports_md5 |
                 module |
                 deprecated |
                 struct) -> any().

'__info__'(module) -> 'Elixir.Instrumentation.Demo';
'__info__'(functions) -> [{hello, 0}, {hello, 1}];
'__info__'(macros) -> [];
'__info__'(struct) -> nil;
'__info__'(exports_md5) ->
    <<"¥\221PÄ\024{\232þ]n\212~\e}\003R">>;
'__info__'(Key = attributes) ->
    erlang:get_module_info('Elixir.Instrumentation.Demo',
                           Key);
'__info__'(Key = compile) ->
    erlang:get_module_info('Elixir.Instrumentation.Demo',
                           Key);
'__info__'(Key = md5) ->
    erlang:get_module_info('Elixir.Instrumentation.Demo',
                           Key);
'__info__'(deprecated) -> [].

hello() -> hello(world).

hello(_name@1) ->
    <<"hello ",
      case _name@1 of
          _@1 when erlang:is_binary(_@1) -> _@1;
          _@1 -> 'Elixir.String.Chars':to_string(_@1)
      end/binary>>.
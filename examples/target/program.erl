-module(program).
-author("Martin Sustek").
-date({2015,11,26}).
-version("1.0").
-export([send_eaop/3]).

send_eaop(TargetName, TargetNode, Msg) ->
    {TargetName, TargetNode} ! Msg
.

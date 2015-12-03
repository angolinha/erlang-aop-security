-module(advices).
-author("Martin Sustek").
-date({2015,11,26}).
-version("1.0").
-export([around_advice/3]).

around_advice(M, F, Args) ->
    node_name_check(M, F, Args, node())
.

node_name_check(M, F, Args, nonode@nohost) ->
    NodeName = list_to_atom(integer_to_list(erlang:phash2({self()}))),
    io:format("<<< Setting Node [NAME] to: ~p~n", [NodeName]),
    net_kernel:start([NodeName, shortnames]),
    alive_check(M, F, Args, is_alive());
node_name_check(M, F, Args, NodeName) ->
    io:format("<<< Setting Node [NAME] exists and is: ~p~n", [NodeName]),
    alive_check(M, F, Args, is_alive())
.

alive_check(M, F, Args, true) ->
    io:format("<<< {Source} Node is [ALIVE], proceeding to cookie check.~n"),
    cookie_check(M, F, Args, erlang:get_cookie());
alive_check(_M, _F, _Args, false) ->
    io:format("<<< {Source} Node is [DOWN], exiting.~n"),
    { source_down, "Failed to send message. Source node is down!~n" }
.

cookie_check(M, F, [TargetName, TargetHost, Msg], nocookie) ->
    NodeCookie = 'b76rtSEPOirgyu34werbfGHekadf',
    io:format("<<< Node Cookie not set. Setting to: ~p~n", [NodeCookie]),
    erlang:set_cookie(node(), NodeCookie),
    ping_node(M, F, [TargetName, TargetHost, Msg], net_adm:ping(TargetHost));
cookie_check(M, F, [TargetName, TargetHost, Msg], Cookie) ->
    NodeCookie = 'b76rtSEPOirgyu34werbfGHekadf',
    io:format("<<< Node Cookie set to: ~p. Overwriting with: ~p~n", [Cookie, NodeCookie]),
    erlang:set_cookie(node(), NodeCookie),
    ping_node(M, F, [TargetName, TargetHost, Msg], net_adm:ping(TargetHost))
.

ping_node(M, F, Args, pong) ->
    io:format("<<< Target Node is [ALIVE], proceeding to message structure check.~n"),
    msg_structure_check(M, F, Args);
ping_node(_M, _F, _Args, pang) ->
    io:format("<<< Target Node is [DOWN], exiting.~n"),
    { target_down, "Failed to send message, target node is down!" }
.

msg_structure_check(M, F, [TargetName, TargetHost, { Tag, Ref, Pid, MsgBody }]) when is_atom(Tag), is_reference(Ref), is_pid(Pid) ->
    io:format("<<< Message is [REFERENCED TUPLE with SENDER PID].~n"),
    erlang:apply(M, F, [TargetName, TargetHost, { Tag, Ref, Pid, MsgBody }]);
msg_structure_check(M, F, [TargetName, TargetHost, { Tag, Ref, MsgBody }]) when is_atom(Tag), is_reference(Ref) ->
    io:format("<<< Message is [TAGGED TUPLE with REFERENCE].~n"),
    erlang:apply(M, F, [TargetName, TargetHost, { Tag, Ref, self(), MsgBody }]);
msg_structure_check(M, F, [TargetName, TargetHost, { Tag, MsgBody }]) when is_atom(Tag) ->
    io:format("<<< Message is [TAGGED TUPLE].~n"),
    MsgHash = erlang:phash2({MsgBody}),
    erlang:apply(M, F, [TargetName, TargetHost, { Tag, MsgHash, self(), MsgBody }]);
msg_structure_check(M, F, [TargetName, TargetHost, { MsgBody }]) ->
    io:format("<<< Message is [PLAIN TUPLE].~n"),
    MsgHash = erlang:phash2({MsgBody}),
    erlang:apply(M, F, [TargetName, TargetHost, { erlaop_msg, MsgHash, self(), MsgBody }]);
msg_structure_check(M, F, [TargetName, TargetHost, Message]) ->
    io:format("<<< Message has [NO STRUCTURE].~n"),
    MsgHash = erlang:phash2({Message}),
    erlang:apply(M, F, [TargetName, TargetHost, { erlaop_msg, MsgHash, self(), Message }])
.

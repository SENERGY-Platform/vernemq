%%%-------------------------------------------------------------------
%% @doc env_api_key_plugin public API
%% @end
%%%-------------------------------------------------------------------

-module(env_api_key_plugin_app).

-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
    env_api_key_plugin_sup:start_link().

stop(_State) ->
    ok.

%% internal functions

-module(parser_tests).

-compile([export_all]).

-include_lib("eunit/include/eunit.hrl").
-include("riak_ql_ddl.hrl").

not_null_white_space_test() ->
    Table_def =
        "CREATE TABLE temperatures ("
        "time TIMESTAMP NOT                NULL, "
        "family VARCHAR NOT NULL, "
        "series VARCHAR NOT NULL, "
        "PRIMARY KEY "
        " ((family, series, quantum(time, 15, 's')), family, series, time))",
    ?assertMatch(
        {ok, #ddl_v1{}},
        riak_ql_parser:parse(riak_ql_lexer:get_tokens(Table_def))
    ).

create_table_white_space_test() ->
    Table_def =
        "CREATE               \tTABLE temperatures ("
        "time TIMESTAMP NOT NULL, "
        "family VARCHAR NOT NULL, "
        "series VARCHAR NOT NULL, "
        "PRIMARY KEY "
        " ((family, series, quantum(time, 15, 's')), family, series, time))",
    ?assertMatch(
        {ok, #ddl_v1{}},
        riak_ql_parser:parse(riak_ql_lexer:get_tokens(Table_def))
    ).

primary_key_white_space_test() ->
    Table_def =
        "CREATE TABLE temperatures ("
        "time TIMESTAMP NOT NULL, "
        "family VARCHAR NOT NULL, "
        "series VARCHAR NOT NULL, "
        "PRIMARY               \t  KEY "
        " ((family, series, quantum(time, 15, 's')), family, series, time))",
    ?assertMatch(
        {ok, #ddl_v1{}},
        riak_ql_parser:parse(riak_ql_lexer:get_tokens(Table_def))
    ).

function_arity_0_test() ->
    ?assertMatch(
        {error, {0, riak_ql_parser, <<_/binary>>}},
        riak_ql_parser:parse(riak_ql_lexer:get_tokens("select f from a WHERE myfun() = a"))
    ).

function_identifier_arity_1_test() ->
    ?assertMatch(
        {error, {0, riak_ql_parser, <<_/binary>>}},
        riak_ql_parser:parse(riak_ql_lexer:get_tokens("select f from a WHERE myfun(a) = a"))
    ).

function_identifier_arity_2_test() ->
    ?assertMatch(
        {error, {0, riak_ql_parser, <<_/binary>>}},
        riak_ql_parser:parse(riak_ql_lexer:get_tokens("select f from a WHERE myfun(a, b) = a"))
    ).

function_val_arity_1_test() ->
    ?assertMatch(
        {error, {0, riak_ql_parser, <<_/binary>>}},
        riak_ql_parser:parse(riak_ql_lexer:get_tokens("select f from a WHERE myfun('a') = a"))
    ).

function_val_arity_2_test() ->
    ?assertMatch(
        {error, {0, riak_ql_parser, <<_/binary>>}},
        riak_ql_parser:parse(riak_ql_lexer:get_tokens("select f from a WHERE myfun('a', 'b') = a"))
    ).

function_val_arity_3_test() ->
    ?assertMatch(
        {error, {0, riak_ql_parser, <<_/binary>>}},
        riak_ql_parser:parse(riak_ql_lexer:get_tokens("select f from a WHERE myfun('a', 'b', 'c') = a"))
    ).

function_val_arity_10_test() ->
    ?assertMatch(
        {error, {0, riak_ql_parser, <<_/binary>>}},
        riak_ql_parser:parse(riak_ql_lexer:get_tokens("select f from a WHERE myfun('a', 'b', 'b', 'b', 'b', 'b', 'b', 'b', 'b', 'b') = a"))
    ).

function_val_and_identifier_mix_1_test() ->
    ?assertMatch(
        {error, {0, riak_ql_parser, <<_/binary>>}},
        riak_ql_parser:parse(riak_ql_lexer:get_tokens("select f from a WHERE myfun('a', 10, b, 3.5) = a"))
    ).

function_val_and_identifier_mix_2_test() ->
    ?assertMatch(
        {error, {0, riak_ql_parser, <<_/binary>>}},
        riak_ql_parser:parse(riak_ql_lexer:get_tokens("select f from a WHERE myfun('a', 10, b, 3.5, true) = a"))
    ).

function_val_and_identifier_mix_3_test() ->
    ?assertMatch(
        {error, {0, riak_ql_parser, <<_/binary>>}},
        riak_ql_parser:parse(riak_ql_lexer:get_tokens("select f from a WHERE myfun('a', 10, b, 3.5, false) = a"))
    ).

function_call_error_message_test() ->
    ?assertMatch(
        {error, {0, riak_ql_parser, <<"Function not supported - 'myfun'.">>}},
        riak_ql_parser:parse(riak_ql_lexer:get_tokens("select f from a WHERE myfun('a') = a"))
    ).

function_as_arg_test() ->
    ?assertMatch(
        {error, {0, riak_ql_parser,
            <<"Function not supported - 'herfun'.">>}},
        riak_ql_parser:parse(riak_ql_lexer:get_tokens("select f from a WHERE myfun(hisfun(herfun(a))) = 'a'"))
    ).

% RTS-645
flubber_test() ->
    ?assertEqual(
        {error, {0, riak_ql_parser,
            <<"Used f as a measure of time in 1f. Only s, m, h and d are allowed.">>}},
        riak_ql_parser:parse(riak_ql_lexer:get_tokens(
            "SELECT * FROM ts_X_subquery "
            "WHERE d > 0 AND d < 1 f = 'f' "
            "AND s='s' AND ts > 0 AND ts < 100"))
    ).

key_fields_must_exist_1_test() ->
    Table_def =
        "CREATE TABLE temperatures ("
        "time TIMESTAMP NOT NULL, "
        "series VARCHAR NOT NULL, "
        "PRIMARY KEY "
        " ((family, series, quantum(time, 15, 's')), family, series, time))",
    ?assertEqual(
        {error, {0, riak_ql_parser, <<"Primary key fields do not exist (family).">>}},
        riak_ql_parser:parse(riak_ql_lexer:get_tokens(Table_def))
    ).

key_fields_must_exist_2_test() ->
    Table_def =
        "CREATE TABLE temperatures ("
        "time TIMESTAMP NOT NULL, "
        "PRIMARY KEY "
        " ((family, series, quantum(time, 15, 's')), family, series, time))",
    ?assertEqual(
        {error, {0, riak_ql_parser, <<"Primary key fields do not exist (family, series).">>}},
        riak_ql_parser:parse(riak_ql_lexer:get_tokens(Table_def))
    ).

key_fields_must_exist_3_test() ->
    Table_def =
        "CREATE TABLE temperatures ("
        "family VARCHAR NOT NULL, "
        "series VARCHAR NOT NULL, "
        "PRIMARY KEY "
        " ((family, series, quantum(time, 15, 's')), family, series, time))",
    ?assertMatch(
        {error, {0, riak_ql_parser, <<"Primary key fields do not exist (time).">>}},
        riak_ql_parser:parse(riak_ql_lexer:get_tokens(Table_def))
    ).

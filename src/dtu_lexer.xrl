
Definitions.

% numbers
Number      = [0-9]
Float       = [0-9]+\.[0-9]+([eE][-+]?[0-9]+)?

% delimiters and operators
Open        = \(
Close       = \)
OpenList    = \[
CloseList   = \]
OpenMap     = \{
CloseMap    = \}
Sep         = ,
Dot         = \.

KwSign		= :
IdSign		= %
VarSign		= \$

Endls       = (\s|\t)*(\r?\n)
Whites      = \s+
Tabs        = \t+

% string stuff
DString      = "(\\\^.|\\.|[^\"])*"
SString      = '(\\\^.|\\.|[^\'])*'
BString      = `(\\\^.|\\.|[^\`])*`

% identifiers
Identifier  = [A-Z\_][a-zA-Z0-9\_\?]*
Atom        = [a-z][a-zA-Z0-9\_\?]*

Symbol		= [\+\-\*/%^&<>=/\?!]+

Rules.

% numbers
{Float}                  : make_token(float,   TokenLine, TokenChars, fun erlang:list_to_float/1).
{Number}+                : make_token(integer, TokenLine, TokenChars, fun erlang:list_to_integer/1).

% delimiters and operators
{Open}                   : make_token(open,        TokenLine, TokenChars).
{Close}                  : make_token(close,       TokenLine, TokenChars).
{OpenList}               : make_token(open_list,   TokenLine, TokenChars).
{CloseList}              : make_token(close_list,  TokenLine, TokenChars).
{OpenMap}                : make_token(open_map,    TokenLine, TokenChars).
{CloseMap}               : make_token(close_map ,  TokenLine, TokenChars).

{Sep}                    : make_token(sep,         TokenLine, TokenChars).
{SemiColon}              : make_token(semicolon,   TokenLine, TokenChars).
{Send}                   : make_token(send_op,     TokenLine, TokenChars).
{Hash}                   : make_token(hash,        TokenLine, TokenChars).
{At}                     : make_token(at,          TokenLine, TokenChars).
{ConsOp}                 : make_token(cons_op,     TokenLine, TokenChars).
{Colon}                  : make_token(colon,       TokenLine, TokenChars).
{Dot}                    : make_token(dot,         TokenLine, TokenChars).

% string stuff
{DString}                : build_string(dstring,  TokenChars, TokenLine, TokenLen).
{SString}                : build_string(sstring, TokenChars, TokenLine, TokenLen).
{BString}                : build_string(bstring, TokenChars, TokenLine, TokenLen).

% identifiers and atoms
{Identifier}             : make_token(upid,  TokenLine, TokenChars).
{Atom}                   : make_token(loid,  TokenLine, TokenChars).
{KwSign}{Identifier}     : make_token(upkw,  TokenLine, tl(TokenChars)).
{KwSign}{Atom}           : make_token(lokw,  TokenLine, tl(TokenChars)).
{VarSign}{Identifier}    : make_token(upvar, TokenLine, tl(TokenChars)).
{VarSign}{Atom}          : make_token(lovar, TokenLine, tl(TokenChars)).

{Symbol}	             : make_token(symbol,  TokenLine, TokenChars).

% spaces, tabs and new lines
{Endls}                  : make_token(nl, TokenLine, endls(TokenChars)).
{Whites}                 : skip_token.
{Tabs}                   : skip_token.

% spaces, tabs and new lines
{Endls}                  : skip_token.
{Whites}                 : skip_token.
{Tabs}                   : skip_token.

Erlang code.

make_token(Name, Line, Chars) when is_list(Chars) ->
    {token, {Name, Line, list_to_atom(Chars)}};
make_token(Name, Line, Chars) ->
    {token, {Name, Line, Chars}}.

make_token(Name, Line, Chars, Fun) ->
    {token, {Name, Line, Fun(Chars)}}.

endls(Chars) ->
    lists:filter(fun (C) -> C == $\n orelse C == $; end, Chars).

build_string(Type, Chars, Line, Len) ->
  String = unescape_string(lists:sublist(Chars, 2, Len - 2), Line),
    {token, {Type, Line, String}}.

unescape_string(String, Line) -> unescape_string(String, Line, []).

unescape_string([], _Line, Output) ->
  lists:reverse(Output);
unescape_string([$\\, Escaped | Rest], Line, Output) ->
  Char = map_escaped_char(Escaped, Line),
  unescape_string(Rest, Line, [Char|Output]);
unescape_string([Char|Rest], Line, Output) ->
  unescape_string(Rest, Line, [Char|Output]).

map_escaped_char(Escaped, Line) ->
  case Escaped of
    $\\ -> $\\;
    $/ -> $/;
    $\" -> $\";
    $\' -> $\';
    $\( -> $(;
    $b -> $\b;
    $d -> $\d;
    $e -> $\e;
    $f -> $\f;
    $n -> $\n;
    $r -> $\r;
    $s -> $\s;
    $t -> $\t;
    $v -> $\v;
    _ -> throw({error, {Line, fn_lexer, ["unrecognized escape sequence: ", [$\\, Escaped]]}})
  end.

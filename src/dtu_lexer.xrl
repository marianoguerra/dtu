
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
Colon       = :
Alt         = \|

KwSign      = :
IdSign      = %
VarSign     = \$
TagSign     = #
AttrSign    = @

Endls       = (\s|\t)*(\r?\n)
Whites      = \s+
Tabs        = \t+

% string stuff
DString     = "(\\\^.|\\.|[^\"])*"
SString     = '(\\\^.|\\.|[^\'])*'
BString     = `(\\\^.|\\.|[^\`])*`

% identifiers
UIdent      = [A-Z\_][a-zA-Z0-9\_\-\?\.\@]*
LIdent      = [a-z][a-zA-Z0-9\_\-\?\.\@]*

Symbol        = [\+\-\*/%^&<>=/\?!]+
SymbolWithAlt = [\.\|\+\-\*/%^&<>=/\?!][\.\|\+\-\*/%^&<>=/\?!]+

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
{Hash}                   : make_token(hash,        TokenLine, TokenChars).
{Colon}                  : make_token(colon,       TokenLine, TokenChars).
{Colon}{Colon}           : make_token(anno,        TokenLine, TokenChars).
{Alt}                    : make_token(alt,         TokenLine, TokenChars).

% string stuff
{DString}                : build_string(dstr, TokenChars, TokenLine, TokenLen).
{SString}                : build_string(sstr, TokenChars, TokenLine, TokenLen).
{BString}                : build_string(bstr, TokenChars, TokenLine, TokenLen).

% identifiers and atoms
{UIdent}            : make_token(upid,  TokenLine, TokenChars).
{LIdent}            : make_token(loid,  TokenLine, TokenChars).
{LIdent}/{LIdent}   : make_token(qloid, TokenLine, TokenChars).
{UIdent}/{UIdent}   : make_token(qupid, TokenLine, TokenChars).
{KwSign}{UIdent}    : make_token(upkw,  TokenLine, tl(TokenChars)).
{KwSign}{LIdent}    : make_token(lokw,  TokenLine, tl(TokenChars)).
{VarSign}{UIdent}   : make_token(upvar, TokenLine, tl(TokenChars)).
{VarSign}{LIdent}   : make_token(lovar, TokenLine, tl(TokenChars)).

{TagSign}{UIdent}   : make_token(uptag, TokenLine, tl(TokenChars)).
{TagSign}{LIdent}   : make_token(lotag, TokenLine, tl(TokenChars)).

{AttrSign}{UIdent}  : make_token(upattr, TokenLine, tl(TokenChars)).
{AttrSign}{LIdent}  : make_token(loattr, TokenLine, tl(TokenChars)).

{KwSign}{DString}   : make_str_token(rkw, TokenLine, get_string_content(tl(TokenChars), TokenLine, TokenLen - 1)).
{VarSign}{DString}  : make_str_token(rvar, TokenLine, get_string_content(tl(TokenChars), TokenLine, TokenLen - 1)).
{IdSign}{DString}   : make_str_token(rid, TokenLine, get_string_content(tl(TokenChars), TokenLine, TokenLen - 1)).
{TagSign}{DString}  : make_str_token(rtag, TokenLine, get_string_content(tl(TokenChars), TokenLine, TokenLen - 1)).
{AttrSign}{DString} : make_str_token(rattr, TokenLine, get_string_content(tl(TokenChars), TokenLine, TokenLen - 1)).

{Symbol}	        : make_token(symbol,  TokenLine, TokenChars).
{SymbolWithAlt}	    : make_token(symbol,  TokenLine, TokenChars).

% below symbol so that symbols like ellipsis match before dot
{Dot}                    : make_token(dot,         TokenLine, TokenChars).

% spaces, tabs and new lines
%{Endls}                  : make_token(nl, TokenLine, endls(TokenChars)).
{Endls}                  : skip_token.
{Whites}                 : skip_token.
{Tabs}                   : skip_token.

% spaces, tabs and new lines
{Endls}                  : skip_token.
{Whites}                 : skip_token.
{Tabs}                   : skip_token.

Erlang code.

make_token(Name, Line, Chars) when is_list(Chars) ->
    {token, {Name, Line, list_to_binary(Chars)}};
make_token(Name, Line, Chars) ->
    {token, {Name, Line, Chars}}.

make_token(Name, Line, Chars, Fun) ->
    {token, {Name, Line, Fun(Chars)}}.

make_str_token(Name, Line, Chars) ->
    {token, {Name, Line, list_to_binary(Chars)}}.

%endls(Chars) ->
%    lists:filter(fun (C) -> C == $\n orelse C == $; end, Chars).

build_string(Type, Chars, Line, Len) ->
  String = get_string_content(Chars, Line, Len),
  {token, {Type, Line, list_to_binary(String)}}.

get_string_content(Chars, Line, Len) ->
    unescape_string(lists:sublist(Chars, 2, Len - 2), Line).

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

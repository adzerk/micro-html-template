/* lexical grammar */
%lex

%x STRING
%x MACRO
%x REGEXP
%x RAW

%%
<INITIAL>"{{"                                           { this.begin("MACRO"); return "{{"; }
<INITIAL>"{%"\s*"raw"\s*"%}"                            { this.begin("RAW"); return "STARTRAW"; }
<RAW>"{%"\s*"endraw"\s*"%}"                             { this.popState(); return "ENDRAW"; }
<RAW>.                                                  { return "RAWCHAR"; }
<INITIAL>[^{]+                                          { return "LITERAL"; }
<MACRO>\s+                                              { /* skip whitespace */ }
<MACRO>"r/"                                             { this.begin("REGEXP"); return "r/"; }
<MACRO>[-]?(?:0|[1-9]\d*)(?:\.\d+)?(?:[eE][+-]?\d+)?    { return "NUMBER"; }
<MACRO>[A-Za-z_$]([A-Za-z0-9_$]+)*                      { return "IDENTIFIER"; }
<MACRO>'"'                                              { this.begin("STRING"); return '"'; }
<MACRO>"|"                                              { return "|"; }
<MACRO>"."                                              { return "."; }
<MACRO>","                                              { return ","; }
<MACRO>"["                                              { return "["; }
<MACRO>"]"                                              { return "]"; }
<MACRO>"("                                              { return "("; }
<MACRO>")"                                              { return ")"; }
<MACRO>"}}"                                             { this.popState(); return "}}"; }
<REGEXP>"\\\\"                                          { return "REGEXPCHAR"; }
<REGEXP>"\\/"                                           { return "REGEXPCHAR"; }
<REGEXP>[^/\n]                                          { return "REGEXPCHAR"; }
<REGEXP>"/"[gimuy]*                                     { this.popState(); return "/"; }
<STRING>"\\\\"                                          { return "STRINGCHAR"; }
<STRING>'\\"'                                           { return "STRINGCHAR"; }
<STRING>[^""\n]                                         { return "STRINGCHAR"; }
<STRING>'"'                                             { this.popState(); return '"'; }
<<EOF>>                                                 { return "EOF"; }

/lex

%start main

%% /* language grammar */

main
  : template EOF
    %{ return $1.join("+"); %}
  ;

template
  : templatepart template
    %{ $$ = [$1].concat($2); %}
  | templatepart
    %{ $$ = [$1]; %}
  ;

templatepart
  : LITERAL
    %{ $$ = JSON.stringify($1); %}
  | raw
    %{ $$ = $1; %}
  | macro
    %{ $$ = $1; %}
  ;

raw
  : STARTRAW rawchars ENDRAW
    %{ $$ = JSON.stringify($2); %}
  ;

rawchars
  : RAWCHAR rawchars
    %{ $$ = $1 + $2; %}
  | RAWCHAR
    %{ $$ = $1; %}
  ;

macro
  : "{{" macroexpr "}}"
    %{
      $$ = "_r[_esc]((" + (function emit(xs) {
        if (Object.prototype.toString.call(xs) !== '[object Array]') {
          return xs;
        } else {
          var func = xs.shift();
          var args = xs.length > 0
            ? "(" + xs.map(emit).join(',') + ")"
            : "";
          return func + args;
        }
      })($2) + ")||'')";
    %}
  ;

macroexpr
  : value filters
    %{
      $2[0].splice(1,0,$1);
      $$ = $2.reduce((xs,x) => {
        if (xs) x.splice(1,0,xs);
        return x;
      });
    %}
  | value
    %{ $$ = [$1]; %}
  ;

filters
  : "|" filter filters
    %{ $$ = [$2].concat($3); %}
  | "|" filter
    %{ $$ = [$2]; %}
  ;

filter
  : IDENTIFIER "(" filterargs ")"
    %{ $$ = ["(_r." + $1 + "||_r.id)"].concat($3); %}
  | IDENTIFIER "(" ")"
    %{ $$ = ["(_r." + $1 + "||_r.id)"]; %}
  | IDENTIFIER
    %{ $$ = ["(_r." + $1 + "||_r.id)"]; %}
  ;

filterargs
  : value "," filterargs
    %{ $$ = [$1].concat($3); %}
  | value
    %{ $$ = [$1]; %}
  ;

value
  : variable
    %{ $$ = $1; %}
  | string
    %{ $$ = $1; %}
  | NUMBER
    %{ $$ = $1; %}
  | regexp
    %{ $$ = $1; %}
  ;

variable
  : variable "." IDENTIFIER
    %{ $$ = "(" + $1 + "||{})" + $2 + $3; %}
  | variable "[" string "]"
    %{ $$ = "(" + $1 + "||{})" + $2 + $3 + $4; %}
  | IDENTIFIER
    %{ $$ = "_env." + $1; %}
  ;

regexp
  : "r/" "/"
    %{ $$ = "(/" + $2 + ")"; }
  | "r/" regexpchars "/"
    %{ $$ = "(/" + $2 + $3 + ")"; }
  ;

regexpchars
  : REGEXPCHAR regexpchars
    %{ $$ = $1 + $2; }
  | REGEXPCHAR
    %{ $$ = $1; }
  ;

string
  : '"' '"'
    %{ $$ = JSON.stringify(""); }
  | '"' stringchars '"'
    %{ $$ = JSON.stringify($2); }
  ;

stringchars
  : STRINGCHAR stringchars
    %{ $$ = $1 + $2; }
  | STRINGCHAR
    %{ $$ = $1; }
  ;

%%

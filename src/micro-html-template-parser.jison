/* lexical grammar */
%lex

%x STRING
%x MACRO

%%
/*
 * Note: Doubled quotes are used in regexes below (eg. [^""\\\0-\x1F\x7F]).
 *       This weirdness helps to avoid syntax highlighting issues in Vim.
 */
<INITIAL>"{{"([{][{])?                                  { if (yytext == "{{") this.begin("MACRO"); return yytext; }
<INITIAL>[{]?[^{]+                                      { return "LITERAL"; }
<MACRO>\s+                                              { /* skip whitespace */ }
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
<STRING>\\([""\\\/bfnrt]|u[a-fA-F0-9]{4})               { return "STRINGCHAR"; }
<STRING>[^""\\\0-\x1F\x7F]                              { return "STRINGCHAR"; }
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
  | "{{{{"
    %{ $$ = JSON.stringify("{{"); %}
  | macro
    %{ $$ = $1; %}
  ;

macro
  : "{{" macroexpr "}}"
    %{
      emit = function(xs) {
        if (Object.prototype.toString.call(xs) !== '[object Array]') {
          return xs;
        } else if (Object.prototype.toString.call(xs[0]) == '[object Array]') {
          var meth = xs.shift()[0];
          var args = xs.map(emit);
          var obj  = args.shift();
          return "h.m(" + ["(" + obj + ")", JSON.stringify(meth)].concat(args).join(",") + ")";
        } else {
          var func = xs.shift();
          var args = xs.length > 0
            ? "(" + xs.map(emit).join(",") + ")"
            : "";
          return func + args;
        }
      };
      if ($2[0] == "(r.raw||r.id)") {
        esc = "id";
        src = $2[1];
      } else {
        esc = yy.escape;
        src = $2;
      }
      $$ = "r." + esc + "((" + emit(src) + ")||\"\")";
    %}
  ;

macroexpr
  : macroStart filters
    %{
      $2[0].splice(1,0,$1);
      prependArgs = function(xs, x) {
        if (xs) x.splice(1,0,xs);
        return x;
      };
      $$ = $2.reduce(prependArgs);
    %}
  | macroStart
    %{ $$ = $1; %}
  ;

macroStart
  : value
    %{ $$ = [$1]; %}
  | filterwithparens
    %{ $$ = $1; %}
  ;

filters
  : "|" filterwithoutparens filters
    %{ $$ = [$2].concat($3); %}
  | "|" filterwithparens filters
    %{ $$ = [$2].concat($3); %}
  | "|" methodinvocation filters
    %{ $$ = [$2].concat($3); %}
  | "|" filterwithoutparens
    %{ $$ = [$2]; %}
  | "|" filterwithparens
    %{ $$ = [$2]; %}
  | "|" methodinvocation
    %{ $$ = [$2]; %}
  ;

methodinvocation
  : "." IDENTIFIER "(" filterargs ")"
    %{ $$ = [[$2]].concat($4); %}
  | "." IDENTIFIER "(" ")"
    %{ $$ = [[$2]]; %}
  | "." IDENTIFIER
    %{ $$ = [[$2]]; %}
  ;

filterwithparens
  : IDENTIFIER "(" filterargs ")"
    %{ $$ = ["(r." + $1 + "||r.id)"].concat($3); %}
  | IDENTIFIER "(" ")"
    %{ $$ = ["(r." + $1 + "||r.id)"]; %}
  ;

filterwithoutparens
  : IDENTIFIER
    %{ $$ = ["(r." + $1 + "||r.id)"]; %}
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
  ;

variable
  : variable "." IDENTIFIER
    %{ $$ = "(" + $1 + "||{})" + $2 + $3; %}
  | variable "[" string "]"
    %{ $$ = "(" + $1 + "||{})" + $2 + $3 + $4; %}
  | IDENTIFIER
    %{ $$ = "e." + $1; %}
  ;

string
  : '"' '"'
    %{ $$ = $1 + $2; }
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

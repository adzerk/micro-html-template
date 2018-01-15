assert            = require('chai').assert
compile           = require('../').compile
version           = require('../package.json').version
runtime           = require('secure-filters')
{filters, render} = require('../dist/micro-html-template-runtime.min.js')

filters.upper = (val) -> val.toUpperCase()
filters.wrap  = (val, prefix, suffix) -> prefix + val + suffix

env =
  id     : ">>id<<"
  style  : ">>\"'wow'\"<<"
  uri    : "foo=bar&baz=baf"
  html   : "<a href='#'>"
  script : "foop'\"barp //]]></script>"

evaluate = (template, env) ->
  render(compile(template), env)

describe "version #{version}", ->

  describe "with no macros or macros in unsafe contexts", ->
    tpl = [
      "<h1 id='123'>hi there</h1>"
      "<div>hello {not_a_macro}</div>"
      "<h1 {{macro_in_attr_name}}='123'>hi there</h1>"
      "<style>{{macro_in_style_tag}}</style>"
      "<script>var x = '{{macro_in_script_tag}}'</script>"
      "<h1 style='{{macro_in_style_attr_val}}'>hi there</h1>"
      "<h1 onclick='{{macro_in_onstar_attr_val}}'>hi there</h1>"
    ]

    it "should be the same as the input", ->
      assert.equal(evaluate(t, env), t) for t in tpl

  describe "with macro delimiter escaped", ->
    tpl = "<div>hello {{{{not_a_macro}}</div>"
    ret = "<div>hello {{not_a_macro}}</div>"

    it "should properly emit the escaped delimiter", ->
      assert.equal(evaluate(tpl, env), ret)

  describe "with macro in attribute value", ->
    tpl  = "<h1 id='{{id}}'>hi there</h1>"
    ret1 = "<h1 id='#{runtime.html(env.id)}'>hi there</h1>"
    ret2 = "<h1 id=''>hi there</h1>"

    it "should be expanded and html escaped", ->
      assert.equal(evaluate(tpl, env), ret1)

    it "should expand undefined to ''", ->
      assert.equal(evaluate(tpl, {}), ret2)

  describe "with macro in uri type attribute value", ->
    tpl  = "<script src='https://example.com?x={{uri}}'></script>"
    ret1 = "<script src='https://example.com?x=#{runtime.uri(env.uri)}'></script>"
    ret2 = "<script src='https://example.com?x='></script>"

    it "should be expanded and uri escaped", ->
      assert.equal(evaluate(tpl, env), ret1)

    it "should expand undefined to ''", ->
      assert.equal(evaluate(tpl, {}), ret2)

  describe "with macro in div tag", ->
    tpl  = "<div>{{html}}</div>"
    ret1 = "<div>#{runtime.html(env.html)}</div>"
    ret2 = "<div></div>"

    it "should be expanded and html escaped", ->
      assert.equal(evaluate(tpl, env), ret1)

    it "should expand undefined to ''", ->
      assert.equal(evaluate(tpl, {}), ret2)

  describe "with multiple tags", ->
    tpl = """
      <script src='https://example.com?x={{uri}}'></script>
      <div>{{html}}</div>
    """
    ret1 = """
      <script src='https://example.com?x=#{runtime.uri(env.uri)}'></script>
      <div>#{runtime.html(env.html)}</div>
    """
    ret2 = """
      <script src='https://example.com?x='></script>
      <div></div>
    """

    it "should be each expanded and escaped properly", ->
      assert.equal(evaluate(tpl, env), ret1)

    it "should expand undefined to ''", ->
      assert.equal(evaluate(tpl, {}), ret2)

  describe "with nested tags", ->
    tpl = """
      <div>
        {{html}}
        <script src='https://example.com?x={{uri}}'></script>
      </div>
    """
    ret1 = """
      <div>
        #{runtime.html(env.html)}
        <script src='https://example.com?x=#{runtime.uri(env.uri)}'></script>
      </div>
    """
    # Whitespace below is significant:
    ret2 = """
      <div>
        
        <script src='https://example.com?x='></script>
      </div>
    """

    it "should be expanded and escaped properly", ->
      assert.equal(evaluate(tpl, env), ret1)

    it "should expand undefined to ''", ->
      assert.equal(evaluate(tpl, {}), ret2)

  describe "with HTML comments", ->
    tpl = """
      <!-- This is a comment. -->
      <script src='https://example.com?x={{uri}}'></script>
    """
    # Whitespace below is significant:
    ret = """
      
      <script src='https://example.com?x=#{runtime.uri(env.uri)}'></script>
    """

    it "should remove the comment and render the rest", ->
      assert.equal(evaluate(tpl, env), ret)

  describe "with boolean attribute", ->
    tpl  = "<h1 id='{{id}}' data-foo>hi there</h1>"
    ret1 = "<h1 id='#{runtime.html(env.id)}' data-foo=''>hi there</h1>"

    it "should be expanded and html escaped", ->
      assert.equal(evaluate(tpl, env), ret1)

  describe "with attribute value containing single quotes", ->
    tpl  = "<img onload=\"console.log('foop')\" src=\"#\">"
    ret1 = "<img onload='console.log(&#39;foop&#39;)' src='#'>"

    it "should be expanded and html escaped", ->
      assert.equal(evaluate(tpl, env), ret1)

  describe "with macro containing string literals and numbers", ->
    tpl  = '<div>{{"foop\\n"}} {{1956}} {{-1.5}} {{1.2e4}}</div>'
    ret1 = '<div>foop&#92;n 1956 -1.5 12000</div>'

    it "should be expanded and html escaped", ->
      assert.equal(evaluate(tpl, env), ret1)

  describe "with macro using custom filter", ->
    tpl  = '<div>{{"foop" | upper}}</div>'
    ret1 = '<div>FOOP</div>'

    it "should be expanded and html escaped", ->
      assert.equal(evaluate(tpl, env), ret1)

  describe "with macro using a method invocation filter without parens", ->
    tpl  = '<div>{{"foop" | .toUpperCase}}</div>'
    ret1 = '<div>FOOP</div>'

    it "should be expanded and html escaped", ->
      assert.equal(evaluate(tpl, env), ret1)

  describe "with macro using a method invocation filter with parens", ->
    tpl  = '<div>{{"foop" | .toUpperCase()}}</div>'
    ret1 = '<div>FOOP</div>'

    it "should be expanded and html escaped", ->
      assert.equal(evaluate(tpl, env), ret1)

  describe "with macro using chained method invocation filters", ->
    tpl  = '<div>{{"foop" | .toUpperCase() | .substr(2)}}</div>'
    ret1 = '<div>OP</div>'

    it "should be expanded and html escaped", ->
      assert.equal(evaluate(tpl, env), ret1)

  describe "with macro using custom filter without initial val", ->
    tpl  = '<div>{{upper("foop")}}</div>'
    ret1 = '<div>FOOP</div>'

    it "should be expanded and html escaped", ->
      assert.equal(evaluate(tpl, env), ret1)

  describe "with macro using composition of custom filters", ->
    tpl  = '<div>{{"foop" | upper | wrap("[", "]")}}</div>'
    ret1 = '<div>&#91;FOOP&#93;</div>'

    it "should be expanded and html escaped", ->
      assert.equal(evaluate(tpl, env), ret1)

  describe "with macro using composition of custom filters without initial val", ->
    tpl  = '<div>{{upper("foop") | wrap("[", "]")}}</div>'
    ret1 = '<div>&#91;FOOP&#93;</div>'

    it "should be expanded and html escaped", ->
      assert.equal(evaluate(tpl, env), ret1)

  describe "with macro using the raw filter", ->
    tpl  = '<div>{{"[foop]" | raw}}</div>'
    ret1 = '<div>[foop]</div>'

    it "should be expanded and not escaped", ->
      assert.equal(evaluate(tpl, env), ret1)

  describe "with macro using the raw filter applied to html filter in a URI type attribute value", ->
    tpl  = "<img src='{{\"http://example.com?foo=<bar>\" | html | raw}}'>"
    ret1 = '<img src=\'http&#58;&#47;&#47;example.com&#63;foo&#61;&lt;bar&gt;\'>'

    it "should be expanded and html escaped but not uri escaped", ->
      assert.equal(evaluate(tpl, env), ret1)

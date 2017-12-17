assert   = require('chai').assert
compile  = require('../').compile
version  = require('../package.json').version
runtime  = require('secure-filters')

expand = (compiledTemplate) ->
  fn = new Function('r', 'e', "return #{compiledTemplate};")
  (env) -> fn(runtime, env)

env =
  id     : ">>id<<"
  style  : ">>\"'wow'\"<<"
  uri    : "foo=bar&baz=baf"
  html   : "<a href='#'>"
  script : "foop'\"barp //]]></script>"

evaluate = (template, env) ->
  expand(compile(template))(env)

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

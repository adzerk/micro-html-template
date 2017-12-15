assert   = require('chai').assert
compiler = require('../')
parser   = compiler.parser
version  = require('../package.json').version
runtime  = require('secure-filters')

compile = (template) ->
  compiler.parse(template)

expand = (compiledTemplate) ->
  fn = new Function('_r', '_env', "return #{compiledTemplate}")
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

  describe "with no macros", ->
    tpl = "<h1 id='123'>hi there</h1>"

    it "should be the same as the input", ->
      assert.equal(evaluate(tpl, env), tpl)

  describe "with macro in attribute name", ->
    tpl = "<h1 {{id}}='123'>hi there</h1>"

    it "should be the same as the input", ->
      assert.equal(evaluate(tpl, env), tpl)

  describe "with macro in attribute value", ->
    tpl  = "<h1 id='{{id}}'>hi there</h1>"
    ret1 = "<h1 id='#{runtime.html(env.id)}'>hi there</h1>"
    ret2 = "<h1 id=''>hi there</h1>"

    it "should be expanded and html escaped", ->
      assert.equal(evaluate(tpl, env), ret1)

    it "should expand undefined to ''", ->
      assert.equal(evaluate(tpl, {}), ret2)

  describe "with macro in style attribute value", ->
    tpl = "<h1 style='{{style}}'>hi there</h1>"
    ret = "<h1 style='#{runtime.style(env.style)}'>hi there</h1>"

    it "should be expanded and style escaped", ->
      assert.equal(evaluate(tpl, env), ret)

  describe "with macro in uri type attribute value", ->
    tpl = "<script src='https://example.com?x={{uri}}'></script>"
    ret = "<script src='https://example.com?x=#{runtime.uri(env.uri)}'></script>"

    it "should be expanded and uri escaped", ->
      assert.equal(evaluate(tpl, env), ret)

  describe "with macro in style tag", ->
    tpl = "<style>{{style}}</style>"
    ret = "<style>#{runtime.css(env.style)}</style>"

    it "should be expanded and css escaped", ->
      assert.equal(evaluate(tpl, env), ret)

  describe "with macro in script tag", ->
    tpl = "<script>var x = '{{script}}'</script>"
    ret = "<script>var x = '#{runtime.js(env.script)}'</script>"

    it "should be expanded and js escaped", ->
      assert.equal(evaluate(tpl, env), ret)

  describe "with macro in div tag", ->
    tpl = "<div>{{html}}</div>"
    ret = "<div>#{runtime.html(env.html)}</div>"

    it "should be expanded and html escaped", ->
      assert.equal(evaluate(tpl, env), ret)

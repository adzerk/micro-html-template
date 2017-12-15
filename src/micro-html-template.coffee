html   = require 'parse5'
macro  = require './micro-html-template-parser'

voidElements = [
  "area"
  "base"
  "br"
  "col"
  "command"
  "embed"
  "hr"
  "img"
  "input"
  "keygen"
  "link"
  "menuitem"
  "meta"
  "param"
  "source"
  "track"
  "wbr"
]

uriAttrs =
  applet:     { archive: 1, archive: 1, codebase: 1 }
  audio:      { src: 1 }
  blockquote: { cite: 1 }
  body:       { background: 1 }
  button:     { formaction: 1 }
  command:    { icon: 1 }
  del:        { cite: 1 }
  embed:      { src: 1 }
  form:       { action: 1 }
  frame:      { longdesc: 1, src: 1 }
  head:       { profile: 1 }
  html:       { manifest: 1 }
  iframe:     { longdesc: 1, src: 1 }
  img:        { longdesc: 1, srcset: 1, src: 1, usemap: 1 }
  input:      { formaction: 1, src: 1, usemap: 1 }
  ins:        { cite: 1 }
  meta:       { content: 1 }
  object:     { archive: 1, classid: 1, codebase: 1, data: 1, usemap: 1 }
  q:          { cite: 1 }
  script:     { src: 1 }
  source:     { srcset: 1, src: 1 }
  track:      { src: 1 }
  video:      { poster: 1, src: 1 }

parse = (htmlStr) ->
  unparse(expandMacros(html.parseFragment(htmlStr)))

unparse = (node) ->
  buf = []
  js  = (x) -> buf.push(x)
  str = (x) -> buf.push(JSON.stringify(x))

  if node.nodeName is '#text'
    js(node.value)
  else
    if node.nodeName[0] isnt '#'
      str("<#{node.nodeName}")
      for {name, value} in (node.attrs || {})
        str(" #{name}='")
        js(value)
        str("'")
      str(">")
    js((unparse(n) for n in (node.childNodes || [])).filter((x) -> x).join('+'))
    if node.nodeName[0] isnt '#'
      if voidElements.indexOf(node.nodeName) < 0
        str("</#{node.nodeName}>")
  buf.filter((x) -> x).join('+')

expandMacros = (node) ->
  emit = (src, name) -> "(function(_esc){ return #{src}; })(#{JSON.stringify(name)})"
  if node.nodeName is '#text'
    esc = switch node.parentNode.nodeName
      when 'script' then 'js'
      when 'style' then 'css'
      else 'html'
    node.value = emit(macro.parse(node.value), esc)
  else
    if node.attrs
      attrs = []
      for {name, value} in node.attrs
        esc = if /^on/i.test(name)
          'jsAttr'
        else if name is 'style'
          'style'
        else if name is 'href' or uriAttrs[node.nodeName]?[name]
          'uri'
        else
          'html'
        attrs.push({name, value: emit(macro.parse(value), esc)})
      node.attrs = attrs
    expandMacros(n) for n in (node.childNodes || [])
  node

module.exports = { parse }

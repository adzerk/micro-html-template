parseFragment = require('parse5').parseFragment
macro         = require './micro-html-template-parser'

nodeType =
  '#document'           : 'container'
  '#document-fragment'  : 'container'
  '#documentType'       : 'container'
  '#comment'            : 'ignore'
  '#text'               : 'text'
  area                  : 'void'
  base                  : 'void'
  br                    : 'void'
  col                   : 'void'
  command               : 'void'
  embed                 : 'void'
  hr                    : 'void'
  img                   : 'void'
  input                 : 'void'
  keygen                : 'void'
  link                  : 'void'
  menuitem              : 'void'
  meta                  : 'void'
  param                 : 'void'
  source                : 'void'
  track                 : 'void'
  wbr                   : 'void'

nodeContext =
  script      : 'RAW'
  style       : 'RAW'

attrType =
  applet      : {archive: 'uri', codebase: 'uri'}
  audio       : {src: 'uri'}
  blockquote  : {cite: 'uri'}
  body        : {background: 'uri'}
  button      : {formaction: 'uri'}
  command     : {icon: 'uri'}
  del         : {cite: 'uri'}
  embed       : {src: 'uri'}
  form        : {action: 'uri'}
  frame       : {longdesc: 'uri', src: 'uri'}
  head        : {profile: 'uri'}
  html        : {manifest: 'uri'}
  iframe      : {longdesc: 'uri', src: 'uri'}
  img         : {longdesc: 'uri', srcset: 'uri', src: 'uri', usemap: 'uri'}
  input       : {formaction: 'uri', src: 'uri', usemap: 'uri'}
  ins         : {cite: 'uri'}
  meta        : {content: 'uri'}
  object      : {archive: 'uri', classid: 'uri', codebase: 'uri', data: 'uri', usemap: 'uri'}
  q           : {cite: 'uri'}
  script      : {src: 'uri'}
  source      : {srcset: 'uri', src: 'uri'}
  track       : {src: 'uri'}
  video       : {poster: 'uri', src: 'uri'}

nodeInfo = (node) ->
  t = nodeType[node.nodeName] || 'element'
  hasOpenTag  : t is 'element' or t is 'void'
  hasChildren : t is 'element' or t is 'container'
  hasText     : t is 'text'
  hasCloseTag : t is 'element'
  escape      : nodeContext[node.parentNode?.nodeName] || 'html'

attrInfo = (node, name) ->
  escape: attrType[node.nodeName]?[name] \
    or (name is 'style' and 'RAW') \
    or (/^on/i.test(name) and 'RAW') \
    or 'html'

compile = (htmlFragment) ->
  unparseFragment(compileMacros(parseFragment(htmlFragment)))

unparseFragment = (node) ->
  buf = []
  tag = nodeInfo(node)
  js  = (x) -> if x then buf.push(x)
  str = (x) -> if x then buf.push(JSON.stringify(x))

  if tag.hasOpenTag
    str("<#{node.nodeName}")
    for {name, value} in (node.attrs || {})
      str(" #{name}='")
      js(value)
      str("'")
    str(">")

  if tag.hasText
    js(node.value)
  else if tag.hasChildren
    js(unparseFragment(n)) for n in (node.childNodes || [])

  if tag.hasCloseTag
    str("</#{node.nodeName}>")

  buf.join('+')

compileMacros = (node) ->
  tag  = nodeInfo(node)
  emit = (src, name) ->
    if not src or name is 'RAW'
      JSON.stringify(src)
    else
      p = new macro.Parser
      p.yy = {escape: name}
      p.parse(src)

  if tag.hasText
    node.value = emit(node.value, tag.escape)
  else if tag.hasOpenTag
    attrs = []
    for {name, value} in node.attrs
      attrs.push({name, value: emit(value, attrInfo(node, name).escape)})
    node.attrs = attrs

  if tag.hasChildren
    compileMacros(n) for n in node.childNodes

  node

module.exports = { compile }

# Resources:
#
# [1]: https://www.owasp.org/index.php/XSS_Filter_Evasion_Cheat_Sheet

# micro-html-template

Template system based roughly on [Jinja2][jinja], designed with a focus on
security, simplicity, rendering speed, and minimal clientside footprint.

Features:

* **Small feature set** &mdash; focused on simple value replacement and filters.
* **Small runtime** &mdash; the JavaScript needed to render compiled templates
  in the client is about 1.1KB, uncompressed.
* **Small precompiled size** &mdash; compiled templates are approximately the
  same size as the templates themselves.
* **Contextual escaping** &mdash; [anti-XSS escaping policies][owasp-xss] are
  applied automatically based on the HTML context.

Non-Features:

* **Compiling templates in the client** &mdash; templates must be precompiled
  in nodejs.
* **Complex template programming** &mdash; no support for loops, conditionals,
  tags, inheritance, etc.
* **Protection against malicious templates** &mdash; it is assumed that templates
  are created by trusted users only.

## Usage

Compile and render a template in nodejs:

```javascript
// Compile
var compile     = require('micro-html-template').compile;
var precompiled = compile("<img src='https://example.com?myname={{user.name}}'>");

// Render
var render      = require('micro-html-template-runtime').render;
var env         = {user: {name: 'Jar Jar B.'}};
var htmlContent = render(precompiled, env);
```

Render the template in the client:

```html
<div id='template1'></div>
<script src='dist/micro-html-template-runtime.min.js'></script>
<script>
  var precompiled = '...'; // precompiled template string from nodejs
  var env         = {user: {name: 'Jar Jar B.'}};
  var htmlContent = microHtmlTemplate.render(precompiled, env);
  document.getElementById('template1').innerHTML = htmlContent;
</script>
```

The result:

```html
<div id='template1'>
  <img src='https://example.com?myname=Jar%20Jar%20B.'>
</div>
```

See the [tests][tests] for more examples.

## Templates

This libarary is designed for applications where templates are created only by
trusted users, but data used to render the templates is untrusted. Template
data will be automatically protected against XSS by a combination of HTML and
URI component escaping, depending on the context.

**Templates must be valid HTML** &mdash; macros may only appear in:
* text nodes
* quoted attribute values

**Macros in unsafe contexts are ignored** &mdash; macros may not appear in:
* `<script>` tags
* `<style>` tags
* `style` attribute values
* `on*` event attribute values

Ok:

```jinja
<!-- Text nodes are safe contexts (except in 'style' and 'script' tags). -->
<div>Hello, {{user.name}}!</div>
```

```jinja
<!-- Quoted attribute values are safe contexts (except for 'style' and 'on*'). -->
<img height='{{height}}px'>
```

Unsafe:

```jinja
<!-- Template is not valid HTML. (Behavior is undefined.) -->
<{{tag.name}} src='http://example.com'>
```

```jinja
<!-- Macro in script tag (passed through verbatim). -->
<script>var x = {{foo.x}};</script>
```

```jinja
<!-- Macro in style tag (passed through verbatim). -->
<style>html {background:{{colors.foo}};}</style>
```

```jinja
<!-- Macro in style attribute (passed through verbatim). -->
<div style='background:{{colors.foo}};'>hello world</div>
```

```jinja
<!-- Macro in on* attribute (passed through verbatim). -->
<div onclick='alert("hello {{user.name}}")'>hello world</div>
```

## Contextual Escaping

The results of all macro replacements are automatically HTML escaped. However,
certain attributes are interpreted as URIs by the browser (the `src` attribute
of an `<iframe>`, for example). Macro replacements in these attributes are URI
encoded (eg. `encodeURIComponent()`) and then HTML escaped.

```jinja
<!-- Replacements in text nodes are just HTML escaped. -->
<div>hello {{user.name}}</div>
```

```jinja
<!-- Replacements in regular attributes are just HTML escaped. -->
<img data-foo='https://example.com?myname={{user.name}}'>
```

```jinja
<!-- Replacements in URI type attributes are both URI encoded and HTML escaped. -->
<img src='https://example.com?myname={{user.name}}'>
```

## Raw Mode

Automatic contextual escaping can be disabled for individual macros: see [Filters](#filters) below.

## Values

The values used in macro expansion are provided as literals or via the `env`
object (passed as an argument to `render`).

```jinja
<!-- JSON string and number literals are values that can be used in macros. -->
<ul>
  <li>i = {{"√-͞1"}}</li>
  <li>? = {{42}}</li>
  <li>π = {{3.14}}</li>
  <li>ħ = {{6.58e-16}}</li>
</ul>
```

```jinja
<!-- Variable names refer to properties of the env object. -->
<div>hello {{name}}</div>
```

```jinja
<!-- Use the dot operator to access nested values. -->
<div>hello {{user.name}}</div>
```

```jinja
<!-- Square brackets work, too. -->
<div>hello {{user["name"]}}</div>
```

```jinja
<!-- Variables can be used inside the square brackets. -->
<div>hello {{user[prop]}}</div>
```

```jinja
<!-- Square brackets are also used for array access. -->
<div>hello {{users[0].name}}</div>
```

## Filters

Filters are functions that are applied to the replacement text. Filters are
expressed as a pipeline:

```jinja
<img src='https://example.com?q={{query | filter1 | filter2}}'>
```

Filters beginning with a `.` character denote method invocation:

```jinja
<img src='https://example.com?q={{query | .toUpperCase}}'>
```

Filters and methods may take arguments:

```jinja
<img src='https://example.com?q={{query | doit("foo", bar.baz) | .substr(42)}}'>
```

The following built-in filters are included:

* `id` &mdash; The identity filter, does nothing.
* `uri` &mdash; Escapes input for URI component context.
* `html` &mdash; Escapes input for HTML context.
* `raw` &mdash; Applied at the end of the pipeline this filter disables auto-escaping.

Note that the `uri` and `html` filters are automatically applied as needed to
prevent XSS. However, it may sometimes make sense to use them in macros, for
instance to escape URI components in an attribute that is not automatically
interpreted by the browser as a URI type:

```jinja
<!-- The 'data-myurl' attribute normally would not be considered a URI context
     so URI component escaping must be specified by adding the uri filter. -->
<div data-myurl='https://example.com?q={{query | uri}}'></div>
```

Or if you need to double-escape a URI component for some reason:

```jinja
<!-- The 'href' attribute is already a URI type, so this will be double-escaped. -->
<a href='https://example.com?q={{query | uri}}'>Query</a>
```

Or when using the `raw` filter on trusted data:

```jinja
<!-- Without "raw" the macro would be URI component escaped, which we don't want.
     Using the "html" filter preserves the HTML escaping, though, which we do want. -->
<img src='{{impressionUrl | html | raw}}'>
```

## Custom Filters

Filters can be added to the runtime in nodejs:

```javascript
runtime = require('micro-html-template-runtime');

runtime.filters.uppercase = function(val) {
  return val.toUpperCase();
};
```

or in the client:

```html
<script>
  microHtmlTemplate.filters.uppercase = function(val) {
    return val.toUpperCase();
  };
</script>
```

Filters may accept additional arguments:

```html
<script>
  microHtmlTemplate.filters.wrap = function(val, start, end) {
    return start + val + end;
  };
</script>
```

Pass the additional arguments to the filter in the template:

```jinja
<img src='https://example.com?q={{query | wrap("[", "]")}}'>
```

## Escaping Macro Delimiters

To include the macro start delimiter `{{` itself in a template it must be
escaped by preceeding it with another start delimiter, like this: `{{{{`.

```jinja
<!-- Start delimiter escaped with '{{{{'. -->
<div>{{{{user.name}} = '{{user.name}}'</div>
```

```jinja
<!-- The rendered template. -->
<div>{{user.name}} = 'Jar Jar B.'</div>
```

## Hacking

```bash
# Install dependencies.
npm install
```

```bash
# Compile parser, minify runtime, etc.
make
```

```bash
# Run tests.
make test
```

## License

Copyright © 2017 Adzerk, Inc.
Distributed under the [Apache License, Version 2.0][apache].

[apache]: https://www.apache.org/licenses/LICENSE-2.0
[jinja]: http://jinja.pocoo.org/docs/2.10/
[tests]: test/micro-html-template.tests.coffee
[owasp-xss]: https://www.owasp.org/index.php/XSS_Filter_Evasion_Cheat_Sheet

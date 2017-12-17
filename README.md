# micro-html-template

Template system based roughly on [Jinja2][jinja], designed with a focus on
security, simplicity, rendering speed, and minimal clientside footprint.

Features:

* **Small feature set** &mdash; focused on simple value replacement and filters.
* **Small runtime** &mdash; minimize the amount of JavaScript needed
  to render precompiled templates in the client.
* **Small precompiled size** &mdash; minimize the size of the JavaScript
  generated for precompiled templates.
* **Contextual escaping** &mdash; anti-XSS escaping policies are applied
  automatically based on the HTML context.

Non-Features:

* **Compiling templates in the client** &mdash; templates must be precompiled
  in nodejs.
* **Complex template programming** &mdash; no support for loops, conditionals,
  tags, inheritance, etc.

## Usage

Compile and render a template in nodejs:

```javascript
// Compile
var compile     = require('micro-html-template').compile;
var precompiled = compile("<img src='https://example.com?myname={{user.name}}'>");

// Render
var render      = require('micro-html-template-runtime').render;
var htmlContent = render(precompiled, {user: {name: 'Jar Jar B.'}});
```

Render the template in the client:

```html
<div id='template1'></div>
<script src='dist/micro-html-template-runtime.min.js'></script>
<script>
  var precompiled = '...'; // precompiled template string from nodejs
  var htmlContent = MicroHtmlTemplate.render(precompiled, {user: {name: 'Jar Jar B.'}});
  document.getElementById('template1').innerHTML = htmlContent;
</script>
```

The result:

```html
<div id='template1'>
  <img src='https://example.com?myname=Jar%20Jar%20B.'>
</div>
```

### Templates

This libarary is designed for applications where templates are created only by
trusted users, but data used to render the templates is untrusted. Template
data will be automatically escaped to protect against XSS, but this can only
be done in certain safe HTML contexts:

```jinja
<!-- Text nodes are safe contexts, except in 'style' and 'script' tags. -->
<div>Hello, {{user.name}}!</div>
```

```jinja
<!-- Quoted attribute values are safe contexts, except for 'style' and 'on*' attributes. -->
<img height='{{height}}px'>
```

```jinja
<!-- Additionally, replacements in URI type attributes are automatically URI encoded. -->
<img src='https://example.com?myname={{user.name}}'>
```

Comment nodes are removed by the template compiler. Other unsafe contexts are
passed through verbatim (ie. curly braces and all). However, note that macros
in unsafe contexts can obscure the HTML structure and can produce unsafe
templates:

```jinja
<!-- Macro is in an unsafe context! -->
<{{tag.name}} src='http://example.com'>
```

The result:

```jinja
<!-- Assuming tag.name = 'img id="image1"'. -->
<img id&#61;&quot;image1&quot; src='http://example.com'>
```

This is because the HTML parser parses `<{{tag.name}} src='http://example.com'>`
as a text node (curly braces are not allowed in HTML tag names), which is then
considered a safe context in which to expand macros. The template creator must
be trusted not to do such things.

### Values

The values used in macro expansion are provided via the `env` argument to the
`render` function.

```jinja
<!-- String literals and numbers are values. -->
<div>{{"Urho Kekkonen"}} was {{"President"}} of {{"Finland"}}.</div>
```

```jinja
<!-- Dot operator denotes object property access. -->
<div>{{user.name}} was {{user.office}} of {{user.geo.country}}.</div>
```

```jinja
<!-- Square brackets work, too. -->
<div>{{user["name"]}} was {{user["office"]}} of {{user["geo"]["country"]}}.</div>
```

```jinja
<!-- Variables can be used inside the square brackts. -->
<div>{{user[prop]}} was {{user.office}} of {{user.geo.country}}.</div>
```

```jinja
<!-- Square brackets are used for array access, as usual. -->
<div>{{user.name}} was {{user.previous[0]}} of {{user.geo.country}}.</div>
```

### Filters

Filters are functions that are applied to the replacement text. Filters are
expressed as a pipeline:

```jinja
<img src='https://example.com?q={{query | filter1 | filter2}}'>
```

The following built-in filters are included:

* `id` &mdash; The identity filter, does nothing.
* `uri` &mdash; Escapes input for URI component context.
* `html` &mdash; Escapes input for HTML context.

Note that these filters are automatically applied as needed to prevent XSS.
However, it may sometimes make sense to use them in macros, for instance to
escape URI components in an attribute that is not specified as a URI type:

```jinja
<!-- The 'data-myurl' attribute will be interpreted as a URI by some JavaScript, perhaps. -->
<div data-myurl='https://example.com?q={{query | uri}}'></div>
```

Or if you need to double-escape the URI for some reason:

```jinja
<!-- The 'href' attribute is already a URI type, so this will be double-escaped. -->
<a href='https://example.com?q={{query | uri}}'>Query</a>
```

#### Custom Filters

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
  MicroHtmlTemplate.filters.uppercase = function(val) {
    return val.toUpperCase();
  };
</script>
```

Filters may accept additional arguments:

```html
<script>
  MicroHtmlTemplate.filters.wrap = function(val, start, end) {
    return start + val + end;
  };
</script>
```

Pass the additional arguments to the filter in the template:

```jinja
<img src='https://example.com?q={{query | wrap("[", "]")}}'>
```

### Escaping Macro Delimiters

To include the macro start delimiter `{{` itself in a template it must be
escaped by preceeding it with another start delimiter, like this: `{{{{`.

```jinja
<!-- Start delimiter escaped with '{{{{'. -->
<div>Hello {{{{name}}!</div>
```

```jinja
<!-- The rendered template. -->
<div>Hello {{name}}!</div>
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

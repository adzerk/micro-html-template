(function(root) {
'use strict';

var QUOT = /\x22/g;
var APOS = /\x27/g;
var AST = /\*/g;
var TILDE = /~/g;
var BANG = /!/g;
var LPAREN = /\(/g;
var RPAREN = /\)/g;
var HTML_CONTROL = /[\x00-\x08\x0B\x0C\x0E-\x1F\x7F-\x9F]/g;
var HTML_NOT_WHITELISTED = /[^\t\n\v\f\r ,\.0-9A-Z_a-z\-\u00A0-\uFFFF]/g;

var MicroHtmlTemplate = {
  filters: {
    id: function(val) {
      return val;
    },
    html: function(val) {
      var str = String(val);
      str = str.replace(HTML_CONTROL, ' ');
      return str.replace(HTML_NOT_WHITELISTED, function(match) {
        var code = match.charCodeAt(0);
        switch(code) {
          case 0x22:
            return '&quot;';
          case 0x26:
            return '&amp;';
          case 0x3C:
            return '&lt;';
          case 0x3E:
            return '&gt;';

          default:
            if (code < 100) {
              var dec = code.toString(10);
              return '&#'+dec+';';
            } else {
              var hex = code.toString(16).toUpperCase();
              return '&#x'+hex+';';
            }
        }
      });
    },
    uri: function(val) {
      var encode = encodeURIComponent(String(val));
      return encode
        .replace(BANG, '%21')
        .replace(QUOT, '%27')
        .replace(APOS, '%27')
        .replace(LPAREN, '%28')
        .replace(RPAREN, '%29')
        .replace(AST, '%2A')
        .replace(TILDE, '%7E');
    }
  },
  render: function(compiledTemplate, env) {
    var fn = new Function('r', 'e', 'return ' + compiledTemplate);
    return fn(MicroHtmlTemplate.filters, env);
  }
}

if (typeof define !== 'undefined' && define.amd) {
  define([], function () { return MicroHtmlTemplate });
} else if (typeof module !== 'undefined' && module.exports) {
  module.exports = MicroHtmlTemplate;
} else {
  root.MicroHtmlTemplate = MicroHtmlTemplate;
}

}(this));

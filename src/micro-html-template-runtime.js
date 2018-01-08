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

var microHtmlTemplate = {
  filters: {
    id: function(val) {
      return val;
    },
    /* The 'html' and 'uri' functions defined below are based on previous work,
    * available here: https://github.com/salesforce/secure-filters. This source
    * code must include the following, which applies to those functions only.
    *
    * Copyright (c) 2014, Salesforce.com, Inc.
    * All rights reserved.
    *
    * Redistribution and use in source and binary forms, with or without
    * modification, are permitted provided that the following conditions are met:
    *
    *   Redistributions of source code must retain the above copyright notice,
    *   this list of conditions and the following disclaimer.
    *
    *   Redistributions in binary form must reproduce the above copyright notice,
    *   this list of conditions and the following disclaimer in the documentation
    *   and/or other materials provided with the distribution.
    *
    *   Neither the name of Salesforce.com, nor the names of its contributors may
    *   be used to endorse or promote products derived from this software without
    *   specific prior written permission.
    *
    * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
    * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
    * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
    * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
    * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
    * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
    * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
    * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
    * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
    * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
    * POSSIBILITY OF SUCH DAMAGE.
    */
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
    return fn(microHtmlTemplate.filters, env);
  }
}

if (typeof define !== 'undefined' && define.amd) {
  define([], function () { return microHtmlTemplate });
} else if (typeof module !== 'undefined' && module.exports) {
  module.exports = microHtmlTemplate;
} else {
  root.microHtmlTemplate = microHtmlTemplate;
}

}(this));

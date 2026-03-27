// MarkdownEditor/Resources/markdown-preview.js

(function() {
    'use strict';

    // Initialize markdown-it parser (window.markdownit is injected by WKUserScript from markdown-it.min.js)
    var md = window.markdownit({
        html: false,
        linkify: false,
        typographer: false
    });

    // Enable table support if markdown-it-table plugin is loaded
    if (window.markdownItTable) {
        md.use(window.markdownItTable.default || window.markdownItTable);
    }

    // Initialize highlight.js if loaded (highlight.min.js injected by WKUserScript)
    if (window.hljs) {
        md.set({
            highlight: function(str, lang) {
                if (lang && window.hljs.getLanguage(lang)) {
                    try {
                        return '<pre><code class="hljs language-' + lang + '">' +
                               window.hljs.highlight(str, { language: lang }).value +
                               '</code></pre>';
                    } catch (e) { /* fall through */ }
                }
                return '<pre><code class="hljs">' +
                       window.hljs.highlightAuto(str).value +
                       '</code></pre>';
            }
        });
    }

    /**
     * Renders a markdown string into the #content div.
     * Called by Swift via WKWebView.evaluateJavaScript or inline script.
     * @param {string} markdownText
     */
    window.renderMarkdown = function(markdownText) {
        var html = md.render(markdownText || '');
        var el = document.getElementById('content');
        if (el) {
            el.innerHTML = html;
        }
    };
})();

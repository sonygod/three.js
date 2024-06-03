import js.html.Document;
import js.html.Window;
import js.html.URL;

class Page {
    static function main() {
        if (!window.frameElement && window.location.protocol != 'file:') {
            // navigates to docs home if direct access
            var url = new URL(window.location.href);

            // hash route, e.g. #api/en/audio/Audio.filter
            url.hash = url.pathname.replace(/\/docs\/(.*?)(?:\.html)?$/, '$1') + url.hash.replace('#', '.');

            // docs home, e.g. https://mrdoob.github.io/three.js/docs/
            url.pathname = url.pathname.replace(/(\/docs\/).*$/, '$1');

            window.location.replace(url);
        } else {
            document.addEventListener('DOMContentLoaded', onDocumentLoad, { once: true });
        }
    }

    static function onDocumentLoad() {
        var path:String, localizedPath:String;
        var pathname = window.location.pathname;
        var section = ~/\/(manual|api|examples)\//.exec(pathname)[1].toString().split('.html')[0];
        var name = ~/[\-A-Za-z0-9]+\.html/.exec(pathname).toString().split('.html')[0];

        switch (section) {
            case 'api':
                localizedPath = ~/\/api\/[A-Za-z0-9\/]+/.exec(pathname).toString().slice(5);
                path = localizedPath.replace(~/^[A-Za-z0-9-]+\//, '');
                break;
            case 'examples':
                path = localizedPath = ~/\/examples\/[A-Za-z0-9\/]+/.exec(pathname).toString().slice(10);
                break;
            case 'manual':
                name = name.replace(/\-/g, ' ');
                path = pathname.replace(/\ /g, '-');
                path = localizedPath = ~/\/manual\/[-A-Za-z0-9\/]+/.exec(path).toString().slice(8);
                break;
        }

        var text = document.body.innerHTML;

        text = text.replace(/\[name\]/gi, name);
        text = text.replace(/\[path\]/gi, path);
        // ... (rest of text replacements)

        document.body.innerHTML = text;

        if (window.parent.getPageURL) {
            var links = document.querySelectorAll('.links');
            for (var i = 0; i < links.length; i++) {
                var pageURL = window.parent.getPageURL(links[i].dataset.fragment);
                if (pageURL) {
                    links[i].href = './index.html#' + pageURL;
                }
            }
        }

        document.body.addEventListener('click', function(event) {
            var element = event.target;
            if (element.classList.contains('links') && event.button === 0 && !event.shiftKey && !event.ctrlKey && !event.metaKey && !event.altKey) {
                window.parent.setUrlFragment(element.dataset.fragment);
                event.preventDefault();
            }
        });

        // handle code snippets formatting
        function dedent(text:String) {
            // ignores singleline text
            var lines:Array<String> = text.split('\n');
            if (lines.length <= 1) return text;

            // ignores blank text
            var nonBlankLine = lines.filter(function(l) return l.trim() != '';
            if (nonBlankLine == null) return text;

            // strips indents if any
            var m = nonBlankLine.match(/^([\t ]+)/);
            if (m != null) {
                text = lines.map(function(l) return l.startsWith(m[1]) ? l.substring(m[1].length) : l).join('\n');
            }

            // strips leading and trailing whitespaces finally
            return text.trim();
        }

        var elements:Array<HTMLElement> = document.getElementsByTagName('code');

        for (var i = 0; i < elements.length; i++) {
            var element:HTMLElement = elements[i];

            element.textContent = dedent(element.textContent);
        }

        // Edit button
        var button:HTMLElement = document.createElement('div');
        button.id = 'button';
        button.innerHTML = '<img src="../files/ic_mode_edit_black_24dp.svg">';
        button.addEventListener('click', function() {
            window.open('https://github.com/mrdoob/three.js/blob/dev/docs/' + section + '/' + localizedPath + '.html');
        }, false);

        document.body.appendChild(button);

        // Syntax highlighting
        var styleBase:HTMLLinkElement = document.createElement('link');
        styleBase.href = pathname.substring(0, pathname.indexOf('docs') + 4) + '/prettify/prettify.css';
        styleBase.rel = 'stylesheet';

        var styleCustom:HTMLLinkElement = document.createElement('link');
        styleCustom.href = pathname.substring(0, pathname.indexOf('docs') + 4) + '/prettify/threejs.css';
        styleCustom.rel = 'stylesheet';

        document.head.appendChild(styleBase);
        document.head.appendChild(styleCustom);

        var prettify:HTMLScriptElement = document.createElement('script');
        prettify.src = pathname.substring(0, pathname.indexOf('docs') + 4) + '/prettify/prettify.js';

        prettify.onload = function() {
            var elements:Array<HTMLElement> = document.getElementsByTagName('code');

            for (var i = 0; i < elements.length; i++) {
                var e:HTMLElement = elements[i];
                e.className += ' prettyprint';
                e.setAttribute('translate', 'no');
            }

            prettyPrint(); // eslint-disable-line no-undef
        };

        document.head.appendChild(prettify);
    }
}
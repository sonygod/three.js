import js.Browser;
import js.html.URL;
import js.html.Window;
import js.html.Document;
import js.html.Element;
import js.html.HTMLElement;

class Page {
    public function new() {
        if (!Browser.window.frameElement && Browser.window.location.protocol != "file:") {
            var url = new URL(Browser.window.location.href);
            url.hash = url.pathname.replaceAll(/\/docs\/(.*?)(?:\.html)?$/, '$1') + url.hash.replaceAll('#', '.');
            url.pathname = url.pathname.replaceAll(/\/docs\/.*$/, '/docs/');
            Browser.window.location.replace(url);
        } else {
            Browser.document.addEventListener('DOMContentLoaded', onDocumentLoad, { once: true });
        }
    }

    private function onDocumentLoad(_: Event): Void {
        var path: String;
        var localizedPath: String;
        var pathname = Browser.window.location.pathname;
        var section = pathname.match(/\/(manual|api|examples)\//)[1].split('.html')[0];
        var name = pathname.match(/[\-A-Za-z0-9]+\.html/)[0].split('.html')[0];

        switch (section) {
            case 'api':
                localizedPath = pathname.match(/\/api\/[A-Za-z0-9\/]+/)[0].slice(5);
                path = localizedPath.replace(/^[A-Za-z0-9-]+\//, '');
                break;
            case 'examples':
                path = localizedPath = pathname.match(/\/examples\/[A-Za-z0-9\/]+/)[0].slice(10);
                break;
            case 'manual':
                name = name.replaceAll(/\-/g, ' ');
                path = pathname.replaceAll(/\ /g, '-');
                path = localizedPath = pathname.match(/\/manual\/[-A-Za-z0-9\/]+/)[0].slice(8);
                break;
        }

        var text = Browser.document.body.innerHTML;
        text = text.replaceAll(/\[name\]/gi, name);
        text = text.replaceAll(/\[path\]/gi, path);
        text = text.replaceAll(/\[page:([\w\.]+)\]/gi, '[page:$1 $1]');
        text = text.replaceAll(/\[page:\.([\w\.]+) ([\w\.\s]+)\]/gi, `[page:${name}.$1 $2]`);
        text = text.replaceAll(/\[page:([\w\.]+) ([\w\.\s]+)\]/gi, `<a class='links' data-fragment='$1' title='$1'>$2</a>`);
        text = text.replaceAll(/\[(member|property|method|param):([\w]+)\]/gi, '[$1:$2 $2]');
        text = text.replaceAll(/\[(?:member|property|method):([\w]+) ([\w\.\s]+)\]\s*(\([\s\S]*?\))?/gi, `<a class='permalink links' data-fragment='${name}.$2' target='_parent' title='${name}.$2'>#</a> .<a class='links' data-fragment='${name}.$2' id='$2'>$2</a> $3 : <a class='param links' data-fragment='$1'>$1</a>`);
        text = text.replaceAll(/\[param:([\w\.]+) ([\w\.\s]+)\]/gi, '$2 : <a class=\'param links\' data-fragment=\'$1\'>$1</a>');
        text = text.replaceAll(/\[link:([\w\:\/\.\-\_\(\)\?\#\=\!\~]+)\]/gi, '<a href="$1" target="_blank">$1</a>');
        text = text.replaceAll(/\[link:([\w:/.\-_()?#=!~]+) ([\w\p{L}:/.\-_'\s]+)\]/giu, '<a href="$1" target="_blank">$2</a>');
        text = text.replaceAll(/\*([\u4e00-\u9fa5\w\d\-\(\"\（\“][\u4e00-\u9fa5\w\d\ \/\+\-\(\)\=\,\.\（\）\，\。"]*[\u4e00-\u9fa5\w\d\"\)\”\）]|\w)\*/gi, '<strong>$1</strong>');
        text = text.replaceAll(/\`(.*?)\`/gs, '<code class="inline">$1</code>');
        text = text.replaceAll(/\[example:([\w\_]+)\]/gi, '[example:$1 $1]');
        text = text.replaceAll(/\[example:([\w\_]+) ([\w\:\/\.\-\_ \s]+)\]/gi, '<a href="../examples/#$1" target="_blank">$2</a>');
        text = text.replaceAll(/\<a class=\'param links\' data-fragment=\'\w+\'>(undefined|null|this|Boolean|Object|Array|Number|String|Integer|Float|TypedArray|ArrayBuffer)<\/a>/gi, '<span class="param">$1</span>');
        Browser.document.body.innerHTML = text;

        if (Browser.window.parent.getPageURL != null) {
            var links = Browser.document.querySelectorAll('.links');
            for (var i in 0...links.length) {
                var pageURL = Browser.window.parent.getPageURL(links[i].dataset.fragment);
                if (pageURL != null) {
                    links[i].href = './index.html#' + pageURL;
                }
            }
        }

        Browser.document.body.addEventListener('click', (event: Event) => {
            var element = event.target;
            if (element.classList.contains('links') && event.button == 0 && !event.shiftKey && !event.ctrlKey && !event.metaKey && !event.altKey) {
                Browser.window.parent.setUrlFragment(element.dataset.fragment);
                event.preventDefault();
            }
        });

        var elements = Browser.document.getElementsByTagName('code');
        for (var i in 0...elements.length) {
            var element = elements[i];
            element.textContent = dedent(element.textContent);
        }

        var button = Browser.document.createElement('div');
        button.id = 'button';
        button.innerHTML = '<img src="../files/ic_mode_edit_black_24dp.svg">';
        button.addEventListener('click', () => {
            Browser.window.open('https://github.com/mrdoob/three.js/blob/dev/docs/' + section + '/' + localizedPath + '.html');
        }, false);
        Browser.document.body.appendChild(button);

        var styleBase = Browser.document.createElement('link');
        styleBase.href = pathname.substring(0, pathname.indexOf('docs') + 4) + '/prettify/prettify.css';
        styleBase.rel = 'stylesheet';

        var styleCustom = Browser.document.createElement('link');
        styleCustom.href = pathname.substring(0, pathname.indexOf('docs') + 4) + '/prettify/threejs.css';
        styleCustom.rel = 'stylesheet';

        Browser.document.head.appendChild(styleBase);
        Browser.document.head.appendChild(styleCustom);

        var prettify = Browser.document.createElement('script');
        prettify.src = pathname.substring(0, pathname.indexOf('docs') + 4) + '/prettify/prettify.js';

        prettify.onload = () => {
            var elements = Browser.document.getElementsByTagName('code');
            for (var i in 0...elements.length) {
                var e = elements[i];
                e.className += ' prettyprint';
                e.setAttribute('translate', 'no');
            }
            js.Browser.window.prettyPrint();
        };

        Browser.document.head.appendChild(prettify);
    }

    private function dedent(text: String): String {
        var lines = text.split('\n');
        if (lines.length <= 1) return text;
        var nonBlankLine = lines.filter(l => l.trim() != '')[0];
        if (nonBlankLine == null) return text;
        var m = nonBlankLine.match(/^([\t ]+)/);
        if (m != null) text = lines.map(l => l.startsWith(m[1]) ? l.substring(m[1].length) : l).join('\n');
        return text.trim();
    }

    private function replaceAll(this: String, search: String, replacement: String): String {
        return this.split(search).join(replacement);
    }
}
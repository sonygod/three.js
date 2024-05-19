import js.Browser;
import js.html.Document;
import js.html.Element;
import js.html.Event;
import js.html.URL;
import js.html.URLSearchParams;
import js.html.window.Window;

class Page {
  static function main() {
    if (!Browser.window.frameElement && Browser.window.location.protocol != 'file:') {
      // navigates to docs home if direct access, e.g.
      //   https://mrdoob.github.io/three.js/docs/api/en/audio/Audio.html#filter
      // -> https://mrdoob.github.io/three.js/docs/#api/en/audio/Audio.filter
      var url = new URL(Browser.window.location.href);

      // hash route, e.g. #api/en/audio/Audio.filter
      url.hash = url.pathname.replace ~/\/docs\/(.*?)(?:\.html)?$/g, '$1' + url.hash.replace ~/#/, '.';

      // docs home, e.g. https://mrdoob.github.io/three.js/docs/
      url.pathname = url.pathname.replace ~/\/(docs\/).*$/g, '$1';

      Browser.window.location.replace(url);
    } else {
      Browser.document.addEventListener('DOMContentLoaded', onDocumentLoad, { once: true });
    }
  }

  static function onDocumentLoad() {
    var path:String, localizedPath:String;
    var pathname = Browser.window.location.pathname;
    var section = ~/\/(manual|api|examples)\/.exec(pathname)[1].toString().split('.')[0];
    var name = ~/[\-A-Za-z0-9]+\.html/.exec(pathname).toString().split('.')[0];

    switch (section) {
      case 'api':
        localizedPath = ~/\/api\/[A-Za-z0-9\/]+/.exec(pathname).toString().slice(5);

        // Remove localized part of the path (e.g. 'en/' or 'es-MX/'):
        path = localizedPath.replace ~/^[A-Za-z0-9-]+\/, '';

        break;

      case 'examples':
        path = localizedPath = ~/\/examples\/[A-Za-z0-9\/]+/.exec(pathname).toString().slice(10);
        break;

      case 'manual':
        name = name.replace ~/-/g, ' ';

        path = pathname.replace ~/ /g, '-';
        path = localizedPath = ~/\/manual\/[-A-Za-z0-9\/]+/.exec(path).toString().slice(8);
        break;
    }

    var text = Browser.document.body.innerHTML;

    text = text.replace ~/\[name\]/gi, name;
    text = text.replace ~/\[path\]/gi, path;
    text = text.replace ~/\[page:([\w\.]+)\]/gi, '[page:$1 $1]'; // [page:name] to [page:name title]
    text = text.replace ~/\[page:\.([\w\.]+) ([\w\.\s]+)\]/gi, '[page:${name}.$1 $2]'; // [page:.member title] to [page:name.member title]
    text = text.replace ~/\[page:([\w\.]+) ([\w\.\s]+)\]/gi, '<a class=\'links\' data-fragment=\'$1\' title=\'$1\'>$2</a>'; // [page:name title]
    // text = text.replace ~/\[member:.([\w]+) ([\w\.\s]+)\]/gi, "<a onclick=\"window.parent.setUrlFragment('" + name + ".$1')\" title=\"$1\">$2</a>";

    text = text.replace ~/\[member:([\w]+)\]/gi, '[$1:$2 $2]'; // [member:name] to [member:name title]
    text = text.replace ~/\[member:([\w]+) ([\w\.\s]+)\]/gi, '<a class=\'permalink links\' data-fragment=\'${name}.$2\' target=\'_parent\' title=\'${name}.$2\'>#</a> .<a class=\'links\' data-fragment=\'${name}.$2\' id=\'$2\'>$2</a> $3 : <a class=\'param links\' data-fragment=\'$1\'">$1</a>';
    text = text.replace ~/\[param:([\w\.]+) ([\w\.\s]+)\]/gi, '$2 : <a class=\'param links\' data-fragment=\'$1\'>$1</a>'; // [param:name title]

    text = text.replace ~/\[link:([\w\:\/\.\-_?\#=\!~]+)\]/gi, '<a href="$1" target="_blank">$1</a>'; // [link:url]
    text = text.replace ~/\[link:([\w:\/.\-_?\#=\!~]+) ([\w\p{L}:\/.\-_'\s]+)\]/giu, '<a href="$1" target="_blank">$2</a>'; // [link:url title]
    text = text.replace ~/*([\u4e00-\u9fa5\w\d\-\(\"\（“][\u4e00-\u9fa5\w\d \/\+\-\(\)\=\,\.\（\）\，\。"]*[\u4e00-\u9fa5\w\d\"\)\”）]|\w)*/gi, '<strong>$1</strong>'; // *text*
    text = text.replace ~/`(.*?)`/gs, '<code class="inline">$1</code>'; // `code`

    text = text.replace ~/\[example:([\w\_]+)\]/gi, '[example:$1 $1]'; // [example:name] to [example:name title]
    text = text.replace ~/\[example:([\w\_]+) ([\w\:\/.\-_ \s]+)\]/gi, '<a href="../examples/#$1" target="_blank">$2</a>'; // [example:name title]

    text = text.replace ~/<a class=\'param links\' data-fragment=\'\w+\'>(undefined|null|this|Boolean|Object|Array|Number|String|Integer|Float|TypedArray|ArrayBuffer)<\/a>/gi, '<span class="param">$1</span>'; // remove links to primitive types

    Browser.document.body.innerHTML = text;

    if (Browser.window.parent.getPageURL != null) {
      var links = Browser.document.querySelectorAll('.links');
      for (i in 0...links.length) {
        var pageURL = Browser.window.parent.getPageURL(links[i].dataset.fragment);
        if (pageURL != null) {
          links[i].href = './index.html#' + pageURL;
        }
      }
    }

    Browser.document.body.addEventListener('click', function(event) {
      var element = event.target;
      if (element.classList.contains('links') && event.button == 0 && !event.shiftKey && !event.ctrlKey && !event.metaKey && !event.altKey) {
        Browser.window.parent.setUrlFragment(element.dataset.fragment);
        event.preventDefault();
      }
    });

    // handle code snippets formatting

    function dedent(text:String):String {
      // ignores singleline text
      var lines = text.split('\n');
      if (lines.length <= 1) return text;

      // ignores blank text
      var nonBlankLine = lines.filter(l -> l.trim() != '').shift();
      if (nonBlankLine == null) return text;

      // strips indents if any
      var m = nonBlankLine.match ~/^([\t ]+)/;
      if (m != null) text = lines.map(l -> l.startsWith(m[1]) ? l.substring(m[1].length) : l).join('\n');

      // strips leading and trailing whitespaces finally
      return text.trim();
    }

    var elements = Browser.document.getElementsByTagName('code');

    for (i in 0...elements.length) {
      var element = elements[i];
      element.textContent = dedent(element.textContent);
    }

    // Edit button

    var button = Browser.document.createElement('div');
    button.id = 'button';
    button.innerHTML = '<img src="../files/ic_mode_edit_black_24dp.svg">';
    button.addEventListener('click', function() {
      Browser.window.open('https://github.com/mrdoob/three.js/blob/dev/docs/' + section + '/' + localizedPath + '.html');
    }, false);

    Browser.document.body.appendChild(button);

    // Syntax highlighting

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

    prettify.onload = function() {
      var elements = Browser.document.getElementsByTagName('code');

      for (i in 0...elements.length) {
        var e = elements[i];
        e.className += ' prettyprint';
        e.setAttribute('translate', 'no');
      }

      prettyPrint(); // eslint-disable-line no-undef
    };

    Browser.document.head.appendChild(prettify);
  }
}
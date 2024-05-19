package three.js.manual.resources;

import js.html.Window;
import js.html.Document;
import js.html.NodeList;
import js.html.AnchorElement;
import js.html.Event;
import js.html.XMLHttpRequest;
import js.Browser;

class Lesson {
    public function new() {}

    public static function main():Void {
        if (Browser.window.frameElement != null) {
            // in iframe
            var anchors:NodeList<AnchorElement> = Browser.document.querySelectorAll('a');
            for (anchor in anchors) {
                anchor.addEventListener('click', function(event:Event) {
                    // opening a new tab?
                    if (anchor.target == '_blank') {
                        return;
                    }

                    // change changing hashes?
                    if (anchor.origin != Browser.window.location.origin || anchor.pathname != Browser.window.location.pathname) {
                        event.preventDefault();
                    }

                    Browser.window.parent.setUrl(anchor.href);
                });
            }
            Browser.window.parent.setTitle(Browser.document.title);
        } else {
            if (Browser.window.location.protocol != 'file:') {
                var re:EReg = ~/^(.*?\/manual\/)(.*?)$/;
                var baseURL:String = re.replace(Browser.window.location.href, '$1');
                var articlePath:String = re.replace(Browser.window.location.href, '$2');
                var href:String = baseURL + '#' + articlePath.replace('.html', '');
                Browser.window.location.replace(href);
            }
        }

        if (Browser.window.prettyPrint != null) {
            Browser.window.prettyPrint();
        }

        // help translation services translate comments.
        var comments:NodeList<Element> = Browser.document.querySelectorAll('span[class=com]');
        for (comment in comments) {
            comment.classList.add('translate');
            comment.classList.add('yestranslate');
            comment.setAttribute('translate', 'yes');
        }

        if (Browser.window.threejsLessonUtils != null) {
            Browser.window.threejsLessonUtils.afterPrettify();
        }
    }
}

// ios needs this to allow touch events in an iframe
Browser.window.addEventListener('touchstart', null);
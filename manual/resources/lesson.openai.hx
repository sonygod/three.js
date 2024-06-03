package three/manual/resources;

import js.html.Document;
import js.html.Element;
import js.html.Event;
import js.html.HTMLAnchorElement;
import js.html.Window;

class Lesson {
    public function new() {
        if (Window.frameElement != null) {
            // in iframe
            for (a in Document.querySelectorAll("a")) {
                a.addEventListener("click", function(e:Event) {
                    if (a.target == "_blank") {
                        return;
                    }
                    if (a.origin != Window.location.origin || a.pathname != Window.location.pathname) {
                        e.preventDefault();
                    }
                    Window.parent.setUrl(a.href);
                });
            }
            Window.parent.setTitle(Document.title);
        } else {
            if (Window.location.protocol != "file:") {
                var re = ~/^(.*?)\/manual\/(.*?)$/;
                var match = re.match(Window.location.href);
                var baseURL = match.group(1);
                var articlePath = match.group(2);
                var href = baseURL + "#" + articlePath.replace(".html", "");
                Window.location.replace(href);
            }
        }
    }

    public static function main() {
        new Lesson();
        if (Window.prettyPrint != null) {
            Window.prettyPrint();
        }
        for (elem in Document.querySelectorAll("span.com")) {
            elem.classList.add("translate", "yestranslate");
            elem.setAttribute("translate", "yes");
        }
        if (Window.threejsLessonUtils != null) {
            Window.threejsLessonUtils.afterPrettify();
        }
        Window.addEventListener("touchstart", null);
    }
}
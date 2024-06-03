// Licensed under a BSD license. See license.html for license

class Lesson {

    public function new() {

        if (js.Browser.window.frameElement != null) {

            // in iframe
            var links = js.Browser.document.querySelectorAll('a');
            for (link in links) {
                var a = link;

                a.addEventListener('click', function(e: Event) {

                    // opening a new tab?
                    if (a.target == '_blank') {

                        return;

                    }

                    // change changing hashes?
                    if (a.origin != js.Browser.window.location.origin || a.pathname != js.Browser.window.location.pathname) {

                        e.preventDefault();

                    }

                    js.Browser.window.parent.setUrl(a.href);

                });
            }

            js.Browser.window.parent.setTitle(js.Browser.document.title);

        } else {

            if (js.Browser.window.location.protocol != 'file:') {

                var re = new EReg("^(.*?/manual/)(.*?)$");
                var matches = re.matched(js.Browser.window.location.href);
                var baseURL = matches[1];
                var articlePath = matches[2];
                var href = baseURL + '#' + articlePath.replace('.html', '');
                js.Browser.window.location.replace(href);

            }

        }

        if (js.Browser.window.prettyPrint != null) {

            js.Browser.window.prettyPrint();

        }

        // help translation services translate comments.
        var comments = js.Browser.document.querySelectorAll('span[class=com]');
        for (comment in comments) {
            var elem = comment;

            elem.classList.add('translate', 'yestranslate');
            elem.setAttribute('translate', 'yes');

        }

        if (js.Browser.window.threejsLessonUtils != null) {

            js.Browser.window.threejsLessonUtils.afterPrettify();

        }

    }

}

// ios needs this to allow touch events in an iframe
js.Browser.window.addEventListener('touchstart', {});

new Lesson();
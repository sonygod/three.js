import js.Browser;
import js.html.Window;
import js.html.Document;
import js.html.Element;
import js.html.NodeList;
import js.html.AnchorElement;
import js.html.Event;
import js.html.Location;

class Main {

	static function main() {

		if (Browser.window.frameElement != null) {

			// in iframe
			var links:NodeList<Element> = Document.window.querySelectorAll('a');
			links.forEach(function(a:AnchorElement) {

				// we have to send all links to the parent
				// otherwise we'll end up with 3rd party
				// sites under the frame.
				a.addEventListener('click', function(e:Event) {

					// opening a new tab?
					if (a.target == '_blank') {

						return;

					}

					// change changing hashes?
					if (a.origin != Browser.window.location.origin || a.pathname != Browser.window.location.pathname) {

						e.preventDefault();

					}

					Browser.window.parent.setUrl(a.href);

				});

			});
			Browser.window.parent.setTitle(Document.window.title);

		} else {

			if (Browser.window.location.protocol != 'file:') {

				var re:EReg = new EReg('^(.*?\/manual\/)(.*?)$', '');
				var [_, baseURL, articlePath] = re.exec(Browser.window.location.href);
				var href:String = '$baseURL#$articlePath.replace('.html', '');
				Browser.window.location.replace(href);

			}

		}

		if (Browser.window.prettyPrint != null) {

			Browser.window.prettyPrint();

		}

		// help translation services translate comments.
		var elems:NodeList<Element> = Document.window.querySelectorAll('span[class=com]');
		elems.forEach(function(elem:Element) {

			elem.classList.add('translate', 'yestranslate');
			elem.setAttribute('translate', 'yes');

		});

		if (Browser.window.threejsLessonUtils != null) {

			Browser.window.threejsLessonUtils.afterPrettify();

		}

	}

}

// ios needs this to allow touch events in an iframe
Browser.window.addEventListener('touchstart', {});
import js.Browser;
import js.html.Document;
import js.html.Element;
import js.html.HTMLAnchorElement;
import js.html.HTMLElement;
import js.html.HTMLImageElement;
import js.html.HTMLLinkElement;
import js.html.HTMLScriptElement;
import js.Lib;

class Script {
	static function main() {
		if (Browser.window.frameElement == null && Browser.window.location.protocol != "file:") {
			// navigates to docs home if direct access, e.g.
			//   https://mrdoob.github.io/three.js/docs/api/en/audio/Audio.html#filter
			// ->https://mrdoob.github.io/three.js/docs/#api/en/audio/Audio.filter
			var url = new js.lib.URL(Browser.window.location.href);
			// hash route, e.g. #api/en/audio/Audio.filter
			url.hash = ~/\/docs\/(.*?)(?:\.html)?$/g.replace(url.pathname, '$1') + ~/#(.*)/g.replace(url.hash, '.$1');
			// docs home, e.g. https://mrdoob.github.io/three.js/docs/
			url.pathname = ~/(\/docs\/).*/g.replace(url.pathname, '$1');
			Browser.window.location.replace(url.toString());
		} else {
			Browser.document.addEventListener("DOMContentLoaded", onDocumentLoad, {once: true});
		}
	}

	static function onDocumentLoad(event:Dynamic) {
		var path:String = null;
		var localizedPath:String = null;
		var pathname = Browser.window.location.pathname;
		var section = ~/.*\/(manual|api|examples)\/.*/g.replace(pathname, '$1');
		var name = ~/.*\/[\-A-Za-z0-9]+\.html/g.replace(pathname, '$1').split(".html")[0];

		switch (section) {
			case "api":
				localizedPath = ~/.*(\/api\/[A-Za-z0-9\/]+\/).*/g.replace(pathname, '$1');
				// Remove localized part of the path (e.g. 'en/' or 'es-MX/'):
				path = ~ /^[A-Za-z0-9-]+\//g.replace(localizedPath, '');
			case "examples":
				localizedPath = path = ~/.*(\/examples\/[A-Za-z0-9\/]+\/).*/g.replace(pathname, '$1');
			case "manual":
				name = ~/\-/g.replace(name, ' ');
				path = ~/\ /g.replace(pathname, '-');
				localizedPath = path = ~/.*(\/manual\/[-A-Za-z0-9\/]+\/).*/g.replace(path, '$1');
			case _:
		}

		var text = Browser.document.body.innerHTML;
		text = ~/\[name\]/gi.replace(text, name);
		text = ~/\[path\]/gi.replace(text, path);
		text = ~/(\[page:)(([\w\.]+)\])/gi.replace(text, '$1$3 $3]'); // [page:name] to [page:name title]
		text = ~/(\[page:\.)([\w\.]+) ([\w\.\s]+)(\])/gi.replace(text, '$1$2$3 $3$4'); // [page:.member title] to [page:name.member title]
		text = ~/(\[page:)([\w\.]+) ([\w\.\s]+)(\])/gi.replace(text, '<a class="links" data-fragment="$2" title="$2">$3</a>'); // [page:name title]
		// text = text.replace( /\[member:.([\w]+) ([\w\.\s]+)\]/gi, "<a onclick=\"window.parent.setUrlFragment('" + name + ".$1')\" title=\"$1\">$2</a>" );
		text = ~/(\[(member|property|method|param):)(([\w]+)\])/gi.replace(text, '$1$4 $4]'); // [member:name] to [member:name title]

		text = ~/(\[(?:member|property|method):)([\w]+) (([\w\.\s]+)\])\s*(\(([\s\S]*?)\))?/gi.replace(text, '<a class="permalink links" data-fragment="${name}.$2" target="_parent" title="${name}.$2">#</a> .<a class="links" data-fragment="${name}.$2" id="$2">$3</a> $4 : <a class="param links" data-fragment="$2">$2</a>');

		text = ~/(\[param:)([\w\.]+) ([\w\.\s]+)(\])/gi.replace(text, '$2 : <a class="param links" data-fragment="$2">$2</a>'); // [param:name title]
		text = ~/(\[link:)([\w\:\/\.\-\_\(\)\?\#\=\!\~]+)(\])/gi.replace(text, '<a href="$2" target="_blank">$2</a>'); // [link:url]
		text = ~/(\[link:)([\w:/.\-_()?#=!~]+) ([\w\p{L}:/.\-_\s]+)(\])/giu.replace(text, '<a href="$2" target="_blank">$3</a>'); // [link:url title]
		text = ~/\*([\u4e00-\u9fa5\w\d\-\(\"\（\“][\u4e00-\u9fa5\w\d\ \/\+\-\(\)\=\,\.\（\）\，\。"]*[\u4e00-\u9fa5\w\d\"\)\”\）]|\w)\*/gi.replace(text, '<strong>$1</strong>'); // *text*
		text = ~/\`(.*?)\`/gs.replace(text, '<code class="inline">$1</code>'); // `code`
		text = ~/(\[example:)([\w\_]+)(\])/gi.replace(text, '$1$2 $2]'); // [example:name] to [example:name title]
		text = ~/(\[example:)([\w\_]+) ([\w\:\/\.\-\_ \s]+)(\])/gi.replace(text, '<a href="../examples/#$2" target="_blank">$3</a>'); // [example:name title]
		text = ~/<a class=\'param links\' data-fragment=\'\w+\'>(undefined|null|this|Boolean|Object|Array|Number|String|Integer|Float|TypedArray|ArrayBuffer)<\/a>/gi
			.replace(text, '<span class="param">$1</span>'); // remove links to primitive types
		Browser.document.body.innerHTML = text;

		if ((Browser.window : Dynamic).parent.getPageURL != null) {
			var links:HTMLCollection<HTMLAnchorElement> = Browser.document.querySelectorAll(".links");
			for (i in 0...links.length) {
				var pageURL:String = (Browser.window : Dynamic).parent.getPageURL(links[i].dataset.fragment);
				if (pageURL != null) {
					links[i].href = './index.html#' + pageURL;
				}
			}
		}

		Browser.document.body.addEventListener("click", function(event:Dynamic) {
			var element:HTMLAnchorElement = event.target;
			if (element.classList.contains("links") && event.button == 0 && !event.shiftKey && !event.ctrlKey && !event.metaKey && !event.altKey) {
				(Browser.window : Dynamic).parent.setUrlFragment(element.dataset.fragment);
				event.preventDefault();
			}
		});

		// handle code snippets formatting
		function dedent(text:String):String {
			// ignores singleline text
			var lines = text.split("\n");
			if (lines.length <= 1)
				return text;

			// ignores blank text
			var nonBlankLine = null;
			for (l in lines) {
				if (l.trim() != "") {
					nonBlankLine = l;
					break;
				}
			}
			if (nonBlankLine == null)
				return text;

			// strips indents if any
			var m = ~/^([\t ]+)/g.exec(nonBlankLine);
			if (m != null) {
				var newLines = [];
				for (l in lines) {
					if (StringTools.startsWith(l, m[1])) {
						newLines.push(l.substring(m[1].length));
					} else {
						newLines.push(l);
					}
				}
				text = newLines.join("\n");
			}

			// strips leading and trailing whitespaces finally
			return text.trim();
		}
		var elements:HTMLCollection<HTMLElement> = Browser.document.getElementsByTagName("code");
		for (i in 0...elements.length) {
			var element:HTMLElement = elements[i];
			element.textContent = dedent(element.textContent);
		}

		// Edit button
		var button:HTMLDivElement = cast Browser.document.createElement("div");
		button.id = "button";
		button.innerHTML = '<img src="../files/ic_mode_edit_black_24dp.svg">';
		button.addEventListener("click", function(event) {
			Browser.window.open('https://github.com/mrdoob/three.js/blob/dev/docs/' + section + '/' + localizedPath + '.html');
		},
			false);
		Browser.document.body.appendChild(button);

		// Syntax highlighting
		var styleBase:HTMLLinkElement = cast Browser.document.createElement("link");
		styleBase.href = pathname.substring(0, pathname.indexOf("docs") + 4) + '/prettify/prettify.css';
		styleBase.rel = "stylesheet";
		var styleCustom = cast Browser.document.createElement("link");
		styleCustom.href = pathname.substring(0, pathname.indexOf("docs") + 4) + '/prettify/threejs.css';
		styleCustom.rel = "stylesheet";
		Browser.document.head.appendChild(styleBase);
		Browser.document.head.appendChild(styleCustom);

		var prettify:HTMLScriptElement = cast Browser.document.createElement("script");
		prettify.src = pathname.substring(0, pathname.indexOf("docs") + 4) + '/prettify/prettify.js';
		prettify.onload = function(_) {
			var elements:HTMLCollection<HTMLElement> = Browser.document.getElementsByTagName("code");
			for (i in 0...elements.length) {
				var e = elements[i];
				e.className += ' prettyprint';
				e.setAttribute("translate", "no");
			}
			(Browser.window : Dynamic).prettyPrint();
		};
		Browser.document.head.appendChild(prettify);
	}
}
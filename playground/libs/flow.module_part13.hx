package three.js.playground.libs;

import js.Browser;
import js.html.Document;
import js.html.EventTarget;
import js.html.Element;
import js.html.Timeout;

class Tips extends EventTarget {

	var dom:Element;
	var time:Int;
	var duration:Int;

	public function new() {
		super();
		dom = Browser.document.createElement('f-tips');
		time = 0;
		duration = 3000;
	}

	public function message(str:String):Tips {
		return tip(str);
	}

	public function error(str:String):Tips {
		return tip(str, 'error');
	}

	public function tip(html:String, ?className:String = ''):Tips {
		var dom = Browser.document.createElement('f-tip');
		dom.className = className;
		dom.innerHTML = html;
		this.dom.prepend(dom);
		// NOTE: requestAnimationFrame is not available in Haxe, you might need to use a timer instead
		//requestAnimationFrame(() -> dom.style.opacity = 1);
		time = Math.min(time + duration, duration);
		var timeoutId:Timeout = setTimeout(() -> {
			time = Math.max(time - duration, 0);
			dom.style.opacity = 0;
			setTimeout(() -> dom.remove(), 250);
		}, time);
		return this;
	}
}
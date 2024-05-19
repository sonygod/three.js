import js.html.Document;
import js.html.Event;
import js.html.InputElement;
import js.html.Element;
import js.html.EventListener;

class Search extends Menu {
	
	var events: { submit:Array<Void->Void>, filter:Array<Void->Void> };
	var tags:WeakMap<Button, String>;
	var inputDOM:InputElement;
	var filtered:Array<{ button:Button, score:Float }>;
	var currentFiltered:{ button:Button, score:Float };
	var value:String;
	var forceAutoComplete:Bool;
	var filteredIndex:Int;

	public function new() {
		super("search");
		events = { submit:[], filter:[] };
		tags = new WeakMap();
		
		inputDOM = cast Document.createElement("input");
		inputDOM.placeholder = "Type here";
		
		var filterNeedUpdate = true;
		
		inputDOM.addEventListener("focusout", function(_) {
			filterNeedUpdate = true;
			setValue("");
		});
		
		inputDOM.onkeydown = function(e) {
			var key = e.key;
			if (key == "ArrowUp") {
				var index = filteredIndex;
				if (forceAutoComplete) {
					filteredIndex = index != null ? (index + 1) % (filtered.length) : 0;
				} else {
					filteredIndex = index != null ? Math.min(index + 1, filtered.length - 1) : 0;
				}
				e.preventDefault();
				filterNeedUpdate = false;
			} else if (key == "ArrowDown") {
				var index = filteredIndex;
				if (forceAutoComplete) {
					filteredIndex = index - 1;
					if (filteredIndex == null) filteredIndex = filtered.length - 1;
				} else {
					filteredIndex = index != null ? index - 1 : null;
				}
				e.preventDefault();
				filterNeedUpdate = false;
			} else if (key == "Enter") {
				value = currentFiltered != null ? currentFiltered.button.getValue() : inputDOM.value;
				submit();
				e.preventDefault();
				filterNeedUpdate = false;
			} else {
				filterNeedUpdate = true;
			}
		};
		
		inputDOM.onkeyup = function() {
			if (filterNeedUpdate) {
				dispatchEvent(new Event("filter"));
				filterNeedUpdate = false;
			}
			filter(inputDOM.value);
		};
		
		filtered = [];
		currentFiltered = null;
		value = "";
		forceAutoComplete = false;
		
		dom.append(inputDOM);
		inputDOM = inputDOM;
		
		addEventListener("filter", function() {
			dispatchEventList(events.filter, this);
		});
		addEventListener("submit", function() {
			dispatchEventList(events.submit, this);
		});
	}
	
	public function submit():Void {
		dispatchEvent(new Event("submit"));
		return setValue("");
	}
	
	public function setValue(value:String):Search {
		inputDOM.value = value;
		filter(value);
		return this;
	}
	
	public function getValue():String {
		return value;
	}
	
	public function onFilter(callback:Void->Void):Search {
		events.filter.push(callback);
		return this;
	}
	
	public function onSubmit(callback:Void->Void):Search {
		events.submit.push(callback);
		return this;
	}
	
	public function getFilterByButton(button:Button):{ button:Button, score:Float } {
		for (filter in filtered) {
			if (filter.button == button) {
				return filter;
			}
		}
		return null;
	}
	
	public function add(button:Button):Search {
		super.add(button);
		var onDown = function() {
			var filter = getFilterByButton(button);
			filteredIndex = filtered.indexOf(filter);
			value = button.getValue();
			submit();
		};
		button.dom.addEventListener("mousedown", onDown);
		button.dom.addEventListener("touchstart", onDown);
		domButtons.get(button).remove();
		return this;
	}
	
	public function set_filteredIndex(index:Int):Void {
		if (currentFiltered != null) {
			var buttonDOM = domButtons.get(currentFiltered.button);
			buttonDOM.classList.remove("active");
			currentFiltered = null;
		}
		var filteredItem = filtered[index];
		if (filteredItem != null) {
			var buttonDOM = domButtons.get(filteredItem.button);
			buttonDOM.classList.add("active");
			currentFiltered = filteredItem;
		}
		updateFilter();
	}
	
	public function get_filteredIndex():Int {
		return currentFiltered != null ? filtered.indexOf(currentFiltered) : null;
	}
	
	public function setTag(button:Button, tags:String):Void {
		tags.set(button, tags);
	}
	
	public function filter(text:String):Void {
		text = filterString(text);
		var tags = this.tags;
		var filtered = [];
		for (button in buttons) {
			var buttonDOM = domButtons.get(button);
			buttonDOM.remove();
			var buttonTags = tags.has(button) ? " " + tags.get(button) : "";
			var label = filterString(button.getValue() + buttonTags);
			if (text != null && label.indexOf(text) != -1) {
				var score = text.length / label.length;
				filtered.push({ button: button, score: score });
			}
		}
		filtered.sort(function(a, b) return b.score - a.score);
		this.filtered = filtered;
		filteredIndex = forceAutoComplete ? 0 : null;
	}
	
	public function updateFilter():Void {
		var filteredIndex = Math.min(filteredIndex, filteredIndex - 3);
		for (i in 0...filtered.length) {
			var button = filtered[i].button;
			var buttonDOM = domButtons.get(button);
			buttonDOM.remove();
			if (i >= filteredIndex) {
				listDOM.append(buttonDOM);
			}
		}
	}
}
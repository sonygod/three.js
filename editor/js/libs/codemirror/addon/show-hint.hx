package libs.codemirror.addon.showhint;

import js.html.DOMRect;
import codemirror.CodeMirror;

class ShowHint {
  static var HINT_ELEMENT_CLASS:String = "CodeMirror-hint";
  static var ACTIVE_HINT_ELEMENT_CLASS:String = "CodeMirror-hint-active";

  static function showHint(cm:CodeMirror, getHints:Dynamic, options:Dynamic) {
    if (getHints == null) return cm.showHint(options);
    if (options != null && options.async) getHints.async = true;
    var newOpts = {hint: getHints};
    if (options != null) for (prop in options) newOpts[prop] = options[prop];
    return cm.showHint(newOpts);
  }

  static function defineExtension(cm:CodeMirror) {
    cm.defineExtension("showHint", function(options:Dynamic) {
      options = parseOptions(this, this.getCursor("start"), options);
      var selections = this.listSelections();
      if (selections.length > 1) return;
      if (this.somethingSelected() && !options.hint.supportsSelection) return;
      if (this.state.completionActive != null) this.state.completionActive.close();
      var completion = this.state.completionActive = new Completion(this, options);
      if (completion.options.hint == null) return;
      CodeMirror.signal(this, "startCompletion", this);
      completion.update(true);
    });

    cm.defineExtension("closeHint", function() {
      if (this.state.completionActive != null) this.state.completionActive.close();
    });
  }

  static function parseOptions(cm:CodeMirror, pos:Dynamic, options:Dynamic) {
    var editor = cm.getOption("hintOptions");
    var out = {};
    for (prop in defaultOptions) out[prop] = defaultOptions[prop];
    if (editor != null) for (prop in editor) if (editor[prop] != null) out[prop] = editor[prop];
    if (options != null) for (prop in options) if (options[prop] != null) out[prop] = options[prop];
    if (out.hint != null && out.hint.resolve != null) out.hint = out.hint.resolve(cm, pos);
    return out;
  }

  static function getText(completion:Dynamic) {
    if (Std.is(completion, String)) return completion;
    else return completion.text;
  }

  static function buildKeyMap(completion:Dynamic, handle:Dynamic) {
    var baseMap = {
      Up: function() { handle.moveFocus(-1); },
      Down: function() { handle.moveFocus(1); },
      PageUp: function() { handle.moveFocus(-handle.menuSize() + 1, true); },
      PageDown: function() { handle.moveFocus(handle.menuSize() - 1, true); },
      Home: function() { handle.setFocus(0); },
      End: function() { handle.setFocus(handle.length - 1); },
      Enter: handle.pick,
      Tab: handle.pick,
      Esc: handle.close
    };

    var mac = ~/Mac/.test(js.Browser.navigator.platform);

    if (mac) {
      baseMap["Ctrl-P"] = function() { handle.moveFocus(-1); };
      baseMap["Ctrl-N"] = function() { handle.moveFocus(1); };
    }

    var ourMap = completion.options.customKeys != null ? {} : baseMap;
    function addBinding(key:String, val:Dynamic) {
      var bound:Dynamic;
      if (Std.is(val, String))
        bound = baseMap[val];
      else
        bound = val;
      ourMap[key] = bound;
    }
    if (completion.options.customKeys != null) for (key in completion.options.customKeys) addBinding(key, completion.options.customKeys[key]);
    if (completion.options.extraKeys != null) for (key in completion.options.extraKeys) addBinding(key, completion.options.extraKeys[key]);
    return ourMap;
  }

  static function getHintElement(hintsElement:js.html.Element, el:js.html.Element) {
    while (el != null && el != hintsElement) {
      if (el.nodeName.toUpperCase() == "LI" && el.parentNode == hintsElement) return el;
      el = el.parentNode;
    }
    return null;
  }

  static function Completion(cm:CodeMirror, options:Dynamic) {
    this.cm = cm;
    this.options = options;
    this.widget = null;
    this.debounce = 0;
    this.tick = 0;
    this.startPos = cm.getCursor("start");
    this.startLen = cm.getLine(this.startPos.line).length - cm.getSelection().length;

    if (options.updateOnCursorActivity) {
      var self = this;
      cm.on("cursorActivity", self.activityFunc = function() { self.cursorActivity(); });
    }
  }

  static function requestAnimationFrame(fn:Dynamic) {
    return untyped __js__("window.requestAnimationFrame")(fn);
  }

  static function cancelAnimationFrame(token:Dynamic) {
    return untyped __js__("window.cancelAnimationFrame")(token);
  }

  static function Widget(completion:Completion, data:Dynamic) {
    this.id = "cm-complete-" + Std.random(1e6);
    this.completion = completion;
    this.data = data;
    this.picked = false;
    var widget = this, cm = completion.cm;
    var ownerDocument = cm.getInputField().ownerDocument;
    var parentWindow = ownerDocument.defaultView || ownerDocument.parentWindow;

    var hints = this.hints = ownerDocument.createElement("ul");
    hints.setAttribute("role", "listbox");
    hints.setAttribute("aria-expanded", "true");
    hints.id = this.id;
    var theme = completion.cm.getOption("theme");
    hints.className = "CodeMirror-hints " + theme;
    this.selectedHint = data.selectedHint || 0;

    var completions = data.list;
    for (i in 0...completions.length) {
      var elt = hints.appendChild(ownerDocument.createElement("li"));
      var cur = completions[i];
      var className = HINT_ELEMENT_CLASS + (i != this.selectedHint ? "" : " " + ACTIVE_HINT_ELEMENT_CLASS);
      if (cur.className != null) className = cur.className + " " + className;
      elt.className = className;
      if (i == this.selectedHint) elt.setAttribute("aria-selected", "true");
      elt.id = this.id + "-" + i;
      elt.setAttribute("role", "option");
      if (cur.render != null) cur.render(elt, data, cur);
      else elt.appendChild(ownerDocument.createTextNode(cur.displayText || getText(cur)));
      elt.hintId = i;
    }

    var container = completion.options.container || ownerDocument.body;
    var pos = cm.cursorCoords(completion.options.alignWithWord ? data.from : null);
    var left = pos.left, top = pos.bottom, below = true;
    var offsetLeft = 0, offsetTop = 0;
    if (container != ownerDocument.body) {
      var isContainerPositioned = ["absolute", "relative", "fixed"].indexOf(parentWindow.getComputedStyle(container).position) != -1;
      var offsetParent = isContainerPositioned ? container : container.offsetParent;
      var offsetParentPosition = offsetParent.getBoundingClientRect();
      var bodyPosition = ownerDocument.body.getBoundingClientRect();
      offsetLeft = offsetParentPosition.left - bodyPosition.left - offsetParent.scrollLeft;
      offsetTop = offsetParentPosition.top - bodyPosition.top - offsetParent.scrollTop;
    }
    hints.style.left = (left - offsetLeft) + "px";
    hints.style.top = (top - offsetTop) + "px";

    var winW = parentWindow.innerWidth || Math.max(ownerDocument.body.offsetWidth, ownerDocument.documentElement.offsetWidth);
    var winH = parentWindow.innerHeight || Math.max(ownerDocument.body.offsetHeight, ownerDocument.documentElement.offsetHeight);
    container.appendChild(hints);
    cm.getInputField().setAttribute("aria-autocomplete", "list");
    cm.getInputField().setAttribute("aria-owns", this.id);
    cm.getInputField().setAttribute("aria-activedescendant", this.id + "-" + this.selectedHint);

    var box = completion.options.moveOnOverlap ? hints.getBoundingClientRect() : new DOMRect();
    var scrolls = completion.options.paddingForScrollbar ? hints.scrollHeight > hints.clientHeight + 1 : false;

    var startScroll;
    haxe.Timer.delay(function() {
      startScroll = cm.getScrollInfo();
    }, 0);

    var overlapY = box.bottom - winH;
    if (overlapY > 0) {
      var height = box.bottom - box.top, curTop = pos.top - (pos.bottom - box.top);
      if (curTop - height > 0) {
        hints.style.top = (top = pos.top - height - offsetTop) + "px";
        below = false;
      } else if (height > winH) {
        hints.style.height = (winH - 5) + "px";
        hints.style.top = (top = pos.bottom - box.top - offsetTop) + "px";
        var cursor = cm.getCursor();
        if (data.from.ch != cursor.ch) {
          pos = cm.cursorCoords(cursor);
          hints.style.left = (left = pos.left - offsetLeft) + "px";
          box = hints.getBoundingClientRect();
        }
      }
    }
    var overlapX = box.right - winW;
    if (scrolls) overlapX += cm.display.nativeBarWidth;
    if (overlapX > 0) {
      if (box.right - box.left > winW) {
        hints.style.width = (winW - 5) + "px";
        overlapX -= (box.right - box.left) - winW;
      }
      hints.style.left = (left = pos.left - overlapX - offsetLeft) + "px";
    }
    if (scrolls) for (node in hints.childNodes) node.style.paddingRight = cm.display.nativeBarWidth + "px";

    cm.addKeyMap(this.keyMap = buildKeyMap(completion, {
      moveFocus: function(n:Int) { widget.changeActive(widget.selectedHint + n); },
      setFocus: function(n:Int) { widget.changeActive(n); },
      menuSize: function() { return widget.screenAmount(); },
      length: completions.length,
      close: function() { completion.close(); },
      pick: function() { widget.pick(); },
      data: data
    }));

    if (completion.options.closeOnUnfocus) {
      var closingOnBlur;
      cm.on("blur", this.onBlur = function() { closingOnBlur = haxe.Timer.delay(function() { completion.close(); }, 100); });
      cm.on("focus", this.onFocus = function() { haxe.Timer.delay(function() { closingOnBlur = null; }, 0); });
    }

    cm.on("scroll", this.onScroll = function() {
      var curScroll = cm.getScrollInfo(), editor = cm.getWrapperElement().getBoundingClientRect();
      if (startScroll == null) startScroll = cm.getScrollInfo();
      var newTop = top + startScroll.top - curScroll.top;
      var point = newTop - (parentWindow.pageYOffset || (ownerDocument.documentElement || ownerDocument.body).scrollTop);
      if (!below) point += hints.offsetHeight;
      if (point <= editor.top || point >= editor.bottom) return completion.close();
      hints.style.top = newTop + "px";
      hints.style.left = (left + startScroll.left - curScroll.left) + "px";
    });

    untyped __js__("CodeMirror.on")(hints, "dblclick", function(e) {
      var t = getHintElement(hints, e.target || e.srcElement);
      if (t && t.hintId != null) widget.changeActive(t.hintId); widget.pick();
    });

    untyped __js__("CodeMirror.on")(hints, "click", function(e) {
      var t = getHintElement(hints, e.target || e.srcElement);
      if (t && t.hintId != null) {
        widget.changeActive(t.hintId);
        if (completion.options.completeOnSingleClick) widget.pick();
      }
    });

    untyped __js__("CodeMirror.on")(hints, "mousedown", function() {
      haxe.Timer.delay(function() { cm.focus(); }, 20);
    });

    this.scrollToActive();
    untyped __js__("CodeMirror.signal")(data, "select", completions[this.selectedHint], hints.childNodes[this.selectedHint]);
  }

  static function applicableHelpers(cm:CodeMirror, helpers:Array<Dynamic>) {
    if (cm.somethingSelected()) return helpers;
    var result = [];
    for (helper in helpers) if (helper.supportsSelection) result.push(helper);
    return result;
  }

  static function fetchHints(hint:Dynamic, cm:CodeMirror, options:Dynamic, callback:Dynamic) {
    if (hint.async) {
      hint(cm, callback, options);
    } else {
      var result = hint(cm, options);
      if (result != null && result.then != null) result.then(callback);
      else callback(result);
    }
  }

  static function resolveAutoHints(cm:CodeMirror, pos:Dynamic) {
    var helpers = cm.getHelpers(pos, "hint"), words;
    if (helpers.length > 0) {
      var resolved = function(cm:CodeMirror, callback:Dynamic, options:Dynamic) {
        var app = applicableHelpers(cm, helpers);
        function run(i:Int) {
          if (i == app.length) callback(null);
          else fetchHints(app[i], cm, options, function(result:Dynamic) {
            if (result != null && result.list.length > 0) callback(result);
            else run(i + 1);
          });
        }
        run(0);
      }
      resolved.async = true;
      resolved.supportsSelection = true;
      return resolved;
    } else if (words = cm.getHelper(cm.getCursor(), "hintWords")) {
      return function(cm:CodeMirror) return CodeMirror.hint.fromList(cm, {words: words});
    } else if (CodeMirror.hint.anyword != null) {
      return function(cm:CodeMirror, options:Dynamic) return CodeMirror.hint.anyword(cm, options);
    } else {
      return function() {};
    }
  }

  static function registerHelper(type:String, id:String, fn:Dynamic) {
    CodeMirror.registerHelper(type, id, fn);
  }
}
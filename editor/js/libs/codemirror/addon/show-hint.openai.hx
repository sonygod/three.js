package three.js.editor.js;

import js.html.DOMRect;
import js.Browser;
import js.html.Document;
import js.html.Window;
import js.html.Element;
import js.html.Event;
import js.html.NodeList;
import js.html.KeyboardEvent;

class Completion {
  public var cm:CodeMirror;
  public var options:Dynamic;
  public var widget:Widget;
  public var debounce:Int;
  public var tick:Int;
  public var startPos:CursorCoords;
  public var startLen:Int;
  public var activityFunc:Event->Void;

  public function new(cm:CodeMirror, options:Dynamic) {
    this.cm = cm;
    this.options = options;
    this.widget = null;
    this.debounce = 0;
    this.tick = 0;
    this.startPos = cm.getCursor("start");
    this.startLen = cm.getLine(this.startPos.line).length - cm.getSelection().length;

    if (options.updateOnCursorActivity) {
      activityFunc = function() {
        cursorActivity();
      };
      cm.on("cursorActivity", activityFunc);
    }
  }

  public function close() {
    if (!active()) return;
    cm.state.completionActive = null;
    tick = null;
    if (options.updateOnCursorActivity) {
      cm.off("cursorActivity", activityFunc);
    }

    if (widget != null && data != null) {
      CodeMirror.signal(data, "close");
    }
    if (widget != null) {
      widget.close();
    }
    CodeMirror.signal(cm, "endCompletion", cm);
  }

  public function active() {
    return cm.state.completionActive == this;
  }

  public function pick(data:Dynamic, i:Int) {
    var completion = data.list[i];
    cm.operation(function() {
      if (completion.hint != null) {
        completion.hint(cm, data, completion);
      } else {
        cm.replaceRange(getText(completion), completion.from, completion.to, "complete");
      }
      CodeMirror.signal(data, "pick", completion);
      cm.scrollIntoView();
    });
    if (options.closeOnPick) {
      close();
    }
  }

  public function cursorActivity() {
    if (debounce != 0) {
      Browser.window.clearTimeout(debounce);
      debounce = 0;
    }

    var identStart = startPos;
    if (data != null) {
      identStart = data.from;
    }

    var pos = cm.getCursor();
    var line = cm.getLine(pos.line);
    if (pos.line != startPos.line || line.length - pos.ch != startLen - startPos.ch || pos.ch < identStart.ch || cm.somethingSelected() || (!pos.ch || options.closeCharacters.test(line.charAt(pos.ch - 1)))) {
      close();
    } else {
      debounce = Browser.window.requestAnimationFrame(update);
      if (widget != null) widget.disable();
    }
  }

  public function update(first:Bool = false) {
    if (tick == null) return;
    var myTick = ++tick;
    fetchHints(options.hint, cm, options, function(data:Dynamic) {
      if (tick == myTick) finishUpdate(data, first);
    });
  }

  public function finishUpdate(data:Dynamic, first:Bool) {
    if (data != null) CodeMirror.signal(data, "update");

    var picked = (widget != null && widget.picked) || (first && options.completeSingle);
    if (widget != null) widget.close();

    this.data = data;

    if (data != null && data.list.length > 0) {
      if (picked && data.list.length == 1) {
        pick(data, 0);
      } else {
        widget = new Widget(this, data);
        CodeMirror.signal(data, "shown");
      }
    }
  }
}

class Widget {
  public var id:String;
  public var completion:Completion;
  public var data:Dynamic;
  public var picked:Bool;
  public var hints:Element;
  public var keyMap:Dynamic;
  public var onFocus:Void->Void;
  public var onBlur:Void->Void;
  public var onScroll:Void->Void;

  public function new(completion:Completion, data:Dynamic) {
    this.id = "cm-complete-" + Std.random(1000000);
    this.completion = completion;
    this.data = data;
    this.picked = false;
    var widget = this;
    var cm = completion.cm;
    var ownerDocument = cm.getInputField().ownerDocument;
    var parentWindow = ownerDocument.defaultView || ownerDocument.parentWindow;

    var hints = ownerDocument.createElement("ul");
    hints.setAttribute("role", "listbox");
    hints.setAttribute("aria-expanded", "true");
    hints.id = this.id;
    var theme = cm.options.theme;
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

    var container = options.container || ownerDocument.body;
    var pos = cm.cursorCoords(options.alignWithWord ? data.from : null);
    var left = pos.left;
    var top = pos.bottom;
    var below = true;
    var offsetLeft = 0;
    var offsetTop = 0;
    if (container != ownerDocument.body) {
      var isContainerPositioned = ['absolute', 'relative', 'fixed'].indexOf(parentWindow.getComputedStyle(container).position) != -1;
      var offsetParent = isContainerPositioned ? container : container.offsetParent;
      var offsetParentPosition = offsetParent.getBoundingClientRect();
      var bodyPosition = ownerDocument.body.getBoundingClientRect();
      offsetLeft = (offsetParentPosition.left - bodyPosition.left - offsetParent.scrollLeft);
      offsetTop = (offsetParentPosition.top - bodyPosition.top - offsetParent.scrollTop);
    }
    hints.style.left = (left - offsetLeft) + "px";
    hints.style.top = (top - offsetTop) + "px";

    var winW = parentWindow.innerWidth || Math.max(ownerDocument.body.offsetWidth, ownerDocument.documentElement.offsetWidth);
    var winH = parentWindow.innerHeight || Math.max(ownerDocument.body.offsetHeight, ownerDocument.documentElement.offsetHeight);

    container.appendChild(hints);
    cm.getInputField().setAttribute("aria-autocomplete", "list");
    cm.getInputField().setAttribute("aria-owns", this.id);
    cm.getInputField().setAttribute("aria-activedescendant", this.id + "-" + this.selectedHint);

    var box = hints.getBoundingClientRect();
    var scrolls = options.paddingForScrollbar ? hints.scrollHeight > hints.clientHeight + 1 : false;

    var startScroll;
    Browser.window.setTimeout(function() {
      startScroll = cm.getScrollInfo();
    }, 0);

    var overlapY = box.bottom - winH;
    if (overlapY > 0) {
      var height = box.bottom - box.top;
      var curTop = pos.top - (pos.bottom - box.top);
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
    if (scrolls) for (node in hints.childNodes) {
      node.style.paddingRight = cm.display.nativeBarWidth + "px";
    }

    cm.addKeyMap(keyMap = buildKeyMap(completion, {
      moveFocus: function(n:Int) {
        widget.changeActive(widget.selectedHint + n);
      },
      setFocus: function(n:Int) {
        widget.changeActive(n);
      },
      menuSize: function() {
        return widget.screenAmount();
      },
      length: data.list.length,
      close: function() {
        completion.close();
      },
      pick: function() {
        widget.pick();
      },
      data: data
    }));

    if (options.closeOnUnfocus) {
      var closingOnBlur;
      cm.on("blur", onBlur = function() {
        closingOnBlur = Browser.window.setTimeout(function() {
          completion.close();
        }, 100);
      });
      cm.on("focus", onFocus = function() {
        Browser.window.clearTimeout(closingOnBlur);
      });
    }

    cm.on("scroll", onScroll = function() {
      var curScroll = cm.getScrollInfo();
      var editor = cm.getWrapperElement().getBoundingClientRect();
      if (!startScroll) startScroll = cm.getScrollInfo();
      var newTop = top + startScroll.top - curScroll.top;
      var point = newTop - (parentWindow.pageYOffset || (ownerDocument.documentElement.scrollTop || ownerDocument.body.scrollTop));
      if (!below) point += hints.offsetHeight;
      if (point <= editor.top || point >= editor.bottom) return completion.close();
      hints.style.top = newTop + "px";
      hints.style.left = (left + startScroll.left - curScroll.left) + "px";
    });

    CodeMirror.on(hints, "dblclick", function(e:Event) {
      var t = getHintElement(hints, e.target);
      if (t != null && t.hintId != null) {
        widget.changeActive(t.hintId);
        widget.pick();
      }
    });

    CodeMirror.on(hints, "click", function(e:Event) {
      var t = getHintElement(hints, e.target);
      if (t != null && t.hintId != null) {
        widget.changeActive(t.hintId);
        if (options.completeOnSingleClick) widget.pick();
      }
    });

    CodeMirror.on(hints, "mousedown", function() {
      Browser.window.setTimeout(function() {
        cm.focus();
      }, 20);
    });
  }

  public function close() {
    if (completion.widget != this) return;
    completion.widget = null;
    if (hints.parentNode != null) hints.parentNode.removeChild(hints);
    completion.cm.removeKeyMap(keyMap);
    var input = completion.cm.getInputField();
    input.removeAttribute("aria-activedescendant");
    input.removeAttribute("aria-owns");

    var cm = completion.cm;
    if (options.closeOnUnfocus) {
      cm.off("blur", onBlur);
      cm.off("focus", onFocus);
    }
    cm.off("scroll", onScroll);
  }

  public function disable() {
    completion.cm.removeKeyMap(keyMap);
    var widget = this;
    keyMap = {
      Enter: function() {
        widget.picked = true;
      }
    };
    completion.cm.addKeyMap(keyMap);
  }

  public function pick() {
    completion.pick(data, selectedHint);
  }

  public function changeActive(i:Int, avoidWrap:Bool = false) {
    if (i >= data.list.length)
      i = avoidWrap ? data.list.length - 1 : 0;
    else if (i < 0)
      i = avoidWrap ? 0 : data.list.length - 1;
    if (selectedHint == i) return;
    var node = hints.childNodes[selectedHint];
    if (node != null) {
      node.className = node.className.replace(" " + ACTIVE_HINT_ELEMENT_CLASS, "");
      node.removeAttribute("aria-selected");
    }
    node = hints.childNodes[selectedHint = i];
    node.className += " " + ACTIVE_HINT_ELEMENT_CLASS;
    node.setAttribute("aria-selected", "true");
    completion.cm.getInputField().setAttribute("aria-activedescendant", node.id);
    scrollToActive();
    CodeMirror.signal(data, "select", data.list[selectedHint], node);
  }

  public function scrollToActive() {
    var selectedHintRange = getSelectedHintRange();
    var node1 = hints.childNodes[selectedHintRange.from];
    var node2 = hints.childNodes[selectedHintRange.to];
    var firstNode = hints.firstChild;
    if (node1.offsetTop < hints.scrollTop)
      hints.scrollTop = node1.offsetTop - firstNode.offsetTop;
    else if (node2.offsetTop + node2.offsetHeight > hints.scrollTop + hints.clientHeight)
      hints.scrollTop = node2.offsetTop + node2.offsetHeight - hints.clientHeight + firstNode.offsetTop;
  }

  public function screenAmount() {
    return Math.floor(hints.clientHeight / hints.firstChild.offsetHeight) || 1;
  }

  public function getSelectedHintRange() {
    var margin = options.scrollMargin || 0;
    return {
      from: Math.max(0, selectedHint - margin),
      to: Math.min(data.list.length - 1, selectedHint + margin)
    };
  }
}

// ...
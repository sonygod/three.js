import js.Browser.window;
import js.html.Element;
import js.html.Node;
import js.html.HTMLCollection;
import js.html.HTMLElement;
import js.html.HTMLDivElement;
import js.html.HTMLUListElement;
import js.html.HTMLLIElement;
import js.html.HTMLInputElement;

class Completion {
    var cm: CodeMirror;
    var options: CompletionOptions;
    var widget: CompletionWidget;
    var debounce: Int;
    var tick: Int;
    var startPos: Position;
    var startLen: Int;

    public function new(cm: CodeMirror, options: CompletionOptions) {
        this.cm = cm;
        this.options = options;
        this.widget = null;
        this.debounce = 0;
        this.tick = 0;
        this.startPos = cm.getCursor("start");
        this.startLen = cm.getLine(this.startPos.line).length - cm.getSelection().length;

        if (this.options.updateOnCursorActivity) {
            var self = this;
            cm.on("cursorActivity", this.activityFunc = function() { self.cursorActivity(); });
        }
    }

    public function close() {
        if (!this.active()) return;
        this.cm.state.completionActive = null;
        this.tick = null;
        if (this.options.updateOnCursorActivity) {
            this.cm.off("cursorActivity", this.activityFunc);
        }

        if (this.widget != null && this.data != null) CodeMirror.signal(this.data, "close");
        if (this.widget != null) this.widget.close();
        CodeMirror.signal(this.cm, "endCompletion", this.cm);
    }

    public function active(): Bool {
        return this.cm.state.completionActive == this;
    }

    public function pick(data: CompletionData, i: Int) {
        var completion = data.list[i];
        this.cm.operation(function() {
            if (completion.hint != null)
                completion.hint(self.cm, data, completion);
            else
                self.cm.replaceRange(getText(completion), completion.from or data.from, completion.to or data.to, "complete");
            CodeMirror.signal(data, "pick", completion);
            self.cm.scrollIntoView();
        });
        if (this.options.closeOnPick) {
            this.close();
        }
    }

    public function cursorActivity() {
        if (this.debounce != 0) {
            cancelAnimationFrame(this.debounce);
            this.debounce = 0;
        }

        var identStart = this.startPos;
        if (this.data != null) {
            identStart = this.data.from;
        }

        var pos = this.cm.getCursor();
        var line = this.cm.getLine(pos.line);
        if (pos.line != this.startPos.line || line.length - pos.ch != this.startLen - this.startPos.ch ||
            pos.ch < identStart.ch || this.cm.somethingSelected() ||
            (!pos.ch || this.options.closeCharacters.match(line.charAt(pos.ch - 1)))) {
            this.close();
        } else {
            var self = this;
            this.debounce = requestAnimationFrame(function() { self.update(); });
            if (this.widget != null) this.widget.disable();
        }
    }

    public function update(first: Bool) {
        if (this.tick == null) return;
        var self = this;
        var myTick = ++this.tick;
        fetchHints(this.options.hint, this.cm, this.options, function(data) {
            if (self.tick == myTick) self.finishUpdate(data, first);
        });
    }

    public function finishUpdate(data: CompletionData, first: Bool) {
        if (this.data != null) CodeMirror.signal(this.data, "update");

        var picked = (this.widget != null && this.widget.picked) || (first && this.options.completeSingle);
        if (this.widget != null) this.widget.close();

        this.data = data;

        if (data != null && data.list.length > 0) {
            if (picked && data.list.length == 1) {
                this.pick(data, 0);
            } else {
                this.widget = new CompletionWidget(this, data);
                CodeMirror.signal(data, "shown");
            }
        }
    }
}

class CompletionWidget {
    var id: String;
    var completion: Completion;
    var data: CompletionData;
    var picked: Bool;
    var hints: HTMLUListElement;
    var selectedHint: Int;
    var cm: CodeMirror;

    public function new(completion: Completion, data: CompletionData) {
        this.id = "cm-complete-" + Std.random(1e6);
        this.completion = completion;
        this.data = data;
        this.picked = false;
        var widget = this;
        var cm = completion.cm;
        var ownerDocument = cm.getInputField().ownerDocument;
        var parentWindow = ownerDocument.defaultView or ownerDocument.parentWindow;

        var hints = this.hints = ownerDocument.createElement("ul");
        hints.setAttribute("role", "listbox");
        hints.setAttribute("aria-expanded", "true");
        hints.id = this.id;
        var theme = completion.cm.options.theme;
        hints.className = "CodeMirror-hints " + theme;
        this.selectedHint = data.selectedHint or 0;

        var completions = data.list;
        for (i in 0...completions.length) {
            var elt = hints.appendChild(ownerDocument.createElement("li"));
            var cur = completions[i];
            var className = HINT_ELEMENT_CLASS;
            if (i != this.selectedHint) {
                className += " " + ACTIVE_HINT_ELEMENT_CLASS;
            }
            if (cur.className != null) {
                className += " " + cur.className;
            }
            elt.className = className;
            if (i == this.selectedHint) {
                elt.setAttribute("aria-selected", "true");
            }
            elt.id = this.id + "-" + i;
            elt.setAttribute("role", "option");
            if (cur.render != null) {
                cur.render(elt, data, cur);
            } else {
                elt.appendChild(ownerDocument.createTextNode(cur.displayText or getText(cur)));
            }
            elt.hintId = i;
        }

        var container = completion.options.container or ownerDocument.body;
        var pos = cm.cursorCoords(completion.options.alignWithWord ? data.from : null);
        var left = pos.left;
        var top = pos.bottom;
        var below = true;
        var offsetLeft = 0;
        var offsetTop = 0;
        if (container != ownerDocument.body) {
            var isContainerPositioned = ["absolute", "relative", "fixed"].contains(parentWindow.getComputedStyle(container).position);
            var offsetParent = isContainerPositioned ? container : container.offsetParent;
            var offsetParentPosition = offsetParent.getBoundingClientRect();
            var bodyPosition = ownerDocument.body.getBoundingClientRect();
            offsetLeft = (offsetParentPosition.left - bodyPosition.left - offsetParent.scrollLeft);
            offsetTop = (offsetParentPosition.top - bodyPosition.top - offsetParent.scrollTop);
        }
        hints.style.left = (left - offsetLeft) + "px";
        hints.style.top = (top - offsetTop) + "px";

        var winW = parentWindow.innerWidth or Math.max(ownerDocument.body.offsetWidth, ownerDocument.documentElement.offsetWidth);
        var winH = parentWindow.innerHeight or Math.max(ownerDocument.body.offsetHeight, ownerDocument.documentElement.offsetHeight);
        container.appendChild(hints);
        cm.getInputField().setAttribute("aria-autocomplete", "list");
        cm.getInputField().setAttribute("aria-owns", this.id);
        cm.getInputField().setAttribute("aria-activedescendant", this.id + "-" + this.selectedHint);

        var box = completion.options.moveOnOverlap ? hints.getBoundingClientRect() : new DOMRect();
        var scrolls = completion.options.paddingForScrollbar ? hints.scrollHeight > hints.clientHeight + 1 : false;

        var startScroll;
        setTimeout(function() { startScroll = cm.getScrollInfo(); });

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
        if (scrolls) {
            for (node in hints.children) {
                node.style.paddingRight = cm.display.nativeBarWidth + "px";
            }
        }

        cm.addKeyMap(this.keyMap = buildKeyMap(completion, {
            moveFocus: function(n: Int, avoidWrap: Bool) { widget.changeActive(widget.selectedHint + n, avoidWrap); },
            setFocus: function(n: Int) { widget.changeActive(n); },
            menuSize: function() { return widget.screenAmount(); },
            length: completions.length,
            close: function() { completion.close(); },
            pick: function() { widget.pick(); },
            data: data
        }));

        if (completion.options.closeOnUnfocus) {
            var closingOnBlur;
            cm.on("blur", this.onBlur = function() { closingOnBlur = setTimeout(function() { completion.close(); }, 100); });
            cm.on("focus", this.onFocus = function() { clearTimeout(closingOnBlur); });
        }

        cm.on("scroll", this.onScroll = function() {
            var curScroll = cm.getScrollInfo();
            var editor = cm.getWrapperElement().getBoundingClientRect();
            if (!startScroll) startScroll = cm.getScrollInfo();
            var newTop = top + startScroll.top - curScroll.top;
            var point = newTop - (parentWindow.pageYOffset or (ownerDocument.documentElement or ownerDocument.body).scrollTop);
            if (!below) point += hints.offsetHeight;
            if (point <= editor.top || point >= editor.bottom) return completion.close();
            hints.style.top = newTop + "px";
            hints.style.left = (left + startScroll.left - curScroll.left) + "px";
        });

        CodeMirror.on(hints, "dblclick", function(e: Event) {
            var t = getHintElement(hints, e.target or e.srcElement);
            if (t != null && t.hintId != null) {
                widget.changeActive(t.hintId);
                widget.pick();
            }
        });

        CodeMirror.on(hints, "click", function(e: Event) {
            var t = getHintElement(hints, e.target or e.srcElement);
            if (t != null && t.hintId != null) {
                widget.changeActive(t.hintId);
                if (completion.options.completeOnSingleClick) widget.pick();
            }
        });

        CodeMirror.on(hints, "mousedown", function() {
            setTimeout(function(){cm.focus();}, 20);
        });

        var selectedHintRange = this.getSelectedHintRange();
        if (selectedHintRange.from != 0 || selectedHintRange.to != 0) {
            this.scrollToActive();
        }

        CodeMirror.signal(data, "select", completions[this.selectedHint], hints.children[this.selectedHint]);
    }

    public function close() {
        if (this.completion.widget != this) return;
        this.completion.widget = null;
        if (this.hints.parentNode != null) this.hints.parentNode.removeChild(this.hints);
        this.completion.cm.removeKeyMap(this.keyMap);
        var input = this.completion.cm.getInputField();
        input.removeAttribute("aria-activedescendant");
        input.removeAttribute("aria-owns");

        var cm = this.completion.cm;
        if (this.completion.options.closeOnUnfocus) {
            cm.off("blur", this.onBlur);
            cm.off("focus", this.onFocus);
        }
        cm.off("scroll", this.onScroll);
    }

    public function disable() {
        this.completion.cm.removeKeyMap(this.keyMap);
        var widget = this;
        this.keyMap = {
            Enter: function() { widget.picked = true; }
        };
        this.completion.cm.addKeyMap(this.keyMap);
    }

    public function pick() {
        this.completion.pick(this.data, this.selectedHint);
    }

    public function changeActive(i: Int, avoidWrap: Bool) {
        if (i >= this.data.list.length) {
            i = avoidWrap ? this.data.list.length - 1 : 0;
        } else if (i < 0) {
            i = avoidWrap ? 0 : this.data.list.length - 1;
        }
        if (this.selectedHint == i) return;
        var node = this.hints.children[this.selectedHint];
        if (node != null) {
            node.className = node.className.replace(" " + ACTIVE_HINT_ELEMENT_CLASS, "");
            node.removeAttribute("aria-selected");
        }
        node = this.hints.children[this.selectedHint = i];
        node.className += " " + ACTIVE_HINT_ELEMENT_CLASS;
        node.setAttribute("aria-selected", "true");
        this.completion.cm.getInputField().setAttribute("aria-activedescendant", node.id);
        this.scrollToActive();
        CodeMirror.signal(this.data, "select", this.data.list[this.selectedHint], node);
    }

    public function scrollToActive() {
        var selectedHintRange = this.getSelectedHintRange();
        var node1 = this.hints.children[selectedHintRange.from];
        var node2 = this.hints.children[selectedHintRange.to];
        var firstNode = this.hints.firstChild;
        if (node1.offsetTop < this.hints.scrollTop) {
            this.hints.scrollTop = node1.offsetTop - firstNode.offsetTop;
        } else if (node2.offsetTop + node2.offsetHeight > this.hints.scrollTop + this.hints.clientHeight) {
            this.hints.scrollTop = node2.offsetTop + node2.offsetHeight - this.hints.clientHeight + firstNode.offsetTop;
        }
    }

    public function screenAmount(): Int {
        return Math.floor(this.hints.clientHeight / this.hints.firstChild.offsetHeight) or 1;
    }

    public function getSelectedHintRange(): {from: Int, to: Int} {
        var margin = this.completion.options.scrollMargin or 0;
        return {
            from: Math.max(0, this.selectedHint - margin),
            to: Math.min(this.data.list.length - 1, this.selectedHint + margin)
        };
    }
}

class CompletionData {
    var list: Array<Completion>;
    var from: Position;
    var to: Position;
    var selectedHint: Int;
}

class CompletionOptions {
    var hint: CompletionHint;
    var completeSingle: Bool;
    var alignWithWord: Bool;
    var closeCharacters: EReg;
    var closeOnPick: Bool;
    var closeOnUnfocus: Bool;
    var updateOnCursorActivity: Bool;
    var completeOnSingleClick: Bool;
    var container: HTMLElement;
    var customKeys: CompletionCustomKeys;
    var extraKeys: CompletionExtraKeys;
    var paddingForScrollbar: Bool;
    var moveOnOverlap: Bool;
}

class CompletionHint {
    var async: Bool;
    var supportsSelection: Bool;

    public function resolve(cm: CodeMirror, pos: Position): CompletionHint;
}

typedef CompletionCustomKeys = { [key: String]: CompletionKeyBinding };
typedef CompletionExtraKeys = { [key: String]: CompletionKeyBinding };
typedef CompletionKeyBinding = Function | String;

class CodeMirror {
    public static function showHint(cm: CodeMirror, getHints: CompletionHint, options: CompletionOptions) {
        if (getHints == null) return cm
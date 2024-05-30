import js.html.HTMLElement;
import js.html.Element;
import js.html.Event;
import js.html.Window;

class CodeMirror {
    public static function openDialog(template:String, callback:Dynamic, ?options:Dynamic):Void {
        var cm = std.Type.enumParameters(this)[0];
        closeNotification(cm, null);

        var dialog = dialogDiv(cm, template, options?.bottom);
        var closed = false;
        var me = cm;
        function close(newVal:Dynamic):Void {
            if (std.is(newVal, String)) {
                inp.value = newVal;
            } else {
                if (closed) return;
                closed = true;
                js.Browser.removeClass(dialog.parentNode, 'dialog-opened');
                dialog.parentNode.removeChild(dialog);
                me.focus();

                if (options?.onClose != null) options.onClose(dialog);
            }
        }

        var inp:HTMLElement = dialog.getElementsByTagName("input")[0];
        var button:HTMLElement;
        if (inp != null) {
            inp.focus();

            if (options?.value != null) {
                inp.value = options.value;
                if (options?.selectValueOnOpen != false) {
                    inp.select();
                }
            }

            if (options?.onInput != null) {
                inp.onInput = function(e:Event) { options.onInput(e, inp.value, close); };
            }
            if (options?.onKeyUp != null) {
                inp.onKeyUp = function(e:Event) { options.onKeyUp(e, inp.value, close); };
            }

            inp.onKeyDown = function(e:Event) {
                if (options?.onKeyDown != null && options.onKeyDown(e, inp.value, close)) {
                    return;
                }
                if (e.keyCode == 27 || (options.closeOnEnter != false && e.keyCode == 13)) {
                    inp.blur();
                    e.stopPropagation();
                    close();
                }
                if (e.keyCode == 13) {
                    callback(inp.value, e);
                }
            };

            if (options?.closeOnBlur != false) {
                dialog.onFocusOut = function(evt:Event) {
                    if (evt.relatedTarget != null) close();
                };
            }
        } else if (button = dialog.getElementsByTagName("button")[0] as HTMLElement) {
            button.onClick = function(e:Event) {
                close();
                me.focus();
            };

            if (options?.closeOnBlur != false) {
                button.onBlur = close;
            }

            button.focus();
        }
        return close;
    }

    public static function openConfirm(template:String, callbacks:Array<Dynamic>, ?options:Dynamic):Void {
        var cm = std.Type.enumParameters(this)[0];
        closeNotification(cm, null);
        var dialog = dialogDiv(cm, template, options?.bottom);
        var buttons = dialog.getElementsByTagName("button");
        var closed = false;
        var me = cm;
        var blurring = 1;
        function close():Void {
            if (closed) return;
            closed = true;
            js.Browser.removeClass(dialog.parentNode, 'dialog-opened');
            dialog.parentNode.removeChild(dialog);
            me.focus();
        }
        buttons[0].focus();
        for (i in 0...buttons.length) {
            var b = buttons[i] as HTMLElement;
            (function(callback:Dynamic) {
                b.onClick = function(e:Event) {
                    e.preventDefault();
                    close();
                    if (callback != null) callback(me);
                };
            })(callbacks[i]);
            b.onBlur = function() {
                --blurring;
                js.Browser.setTimeout(function() { if (blurring <= 0) close(); }, 200);
            };
            b.onFocus = function() { ++blurring; };
        }
    }

    public static function openNotification(template:String, ?options:Dynamic):Void -> Void {
        var cm = std.Type.enumParameters(this)[0];
        closeNotification(cm, close);
        var dialog = dialogDiv(cm, template, options?.bottom);
        var closed = false;
        var doneTimer:Int;
        var duration = if (options != null && options.duration != null) options.duration else 5000;

        function close():Void {
            if (closed) return;
            closed = true;
            js.Browser.clearTimeout(doneTimer);
            js.Browser.removeClass(dialog.parentNode, 'dialog-opened');
            dialog.parentNode.removeChild(dialog);
        }

        dialog.onClick = function(e:Event) {
            e.preventDefault();
            close();
        };

        if (duration > 0) {
            doneTimer = js.Browser.setTimeout(close, duration);
        }

        return close;
    }

    public static function dialogDiv(cm:CodeMirror, template:Dynamic, ?bottom:Bool):HTMLElement {
        var wrap = cm.getWrapperElement();
        var dialog = wrap.appendChild(Element.create("div"));
        if (bottom) {
            dialog.className = "CodeMirror-dialog CodeMirror-dialog-bottom";
        } else {
            dialog.className = "CodeMirror-dialog CodeMirror-dialog-top";
        }

        if (std.is(template, String)) {
            dialog.innerHTML = template;
        } else {
            dialog.appendChild(template);
        }
        js.Browser.addClass(wrap, 'dialog-opened');
        return dialog;
    }

    public static function closeNotification(cm:CodeMirror, ?newVal:Dynamic):Void {
        if (cm.state.currentNotificationClose != null) {
            cm.state.currentNotificationClose();
        }
        cm.state.currentNotificationClose = newVal;
    }
}
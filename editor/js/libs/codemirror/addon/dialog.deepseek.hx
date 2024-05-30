// CodeMirror, copyright (c) by Marijn Haverbeke and others
// Distributed under an MIT license: https://codemirror.net/LICENSE

// Open simple dialogs on top of an editor. Relies on dialog.css.

class CodeMirror {
    static var getWrapperElement():Dynamic;
    static var addClass(element:Dynamic, className:String):Void;
    static var rmClass(element:Dynamic, className:String):Void;
    static var on(element:Dynamic, event:String, handler:Dynamic):Void;
    static var e_stop(event:Dynamic):Void;
    static var e_preventDefault(event:Dynamic):Void;
    static var defineExtension(name:String, extension:Dynamic):Void;
}

class Dialog {
    static function dialogDiv(cm:CodeMirror, template:Dynamic, bottom:Bool):Dynamic {
        var wrap = cm.getWrapperElement();
        var dialog;
        dialog = wrap.appendChild(document.createElement("div"));
        if (bottom)
            dialog.className = "CodeMirror-dialog CodeMirror-dialog-bottom";
        else
            dialog.className = "CodeMirror-dialog CodeMirror-dialog-top";

        if (typeof template == "string") {
            dialog.innerHTML = template;
        } else { // Assuming it's a detached DOM element.
            dialog.appendChild(template);
        }
        CodeMirror.addClass(wrap, 'dialog-opened');
        return dialog;
    }

    static function closeNotification(cm:CodeMirror, newVal:Dynamic):Void {
        if (cm.state.currentNotificationClose)
            cm.state.currentNotificationClose();
        cm.state.currentNotificationClose = newVal;
    }

    static function openDialog(cm:CodeMirror, template:Dynamic, callback:Dynamic, options:Dynamic):Dynamic {
        if (!options) options = {};

        closeNotification(cm, null);

        var dialog = dialogDiv(cm, template, options.bottom);
        var closed = false, me = cm;
        function close(newVal:Dynamic):Void {
            if (typeof newVal == 'string') {
                inp.value = newVal;
            } else {
                if (closed) return;
                closed = true;
                CodeMirror.rmClass(dialog.parentNode, 'dialog-opened');
                dialog.parentNode.removeChild(dialog);
                me.focus();

                if (options.onClose) options.onClose(dialog);
            }
        }

        var inp = dialog.getElementsByTagName("input")[0], button;
        if (inp) {
            inp.focus();

            if (options.value) {
                inp.value = options.value;
                if (options.selectValueOnOpen !== false) {
                    inp.select();
                }
            }

            if (options.onInput)
                CodeMirror.on(inp, "input", function(e) { options.onInput(e, inp.value, close);});
            if (options.onKeyUp)
                CodeMirror.on(inp, "keyup", function(e) {options.onKeyUp(e, inp.value, close);});

            CodeMirror.on(inp, "keydown", function(e) {
                if (options && options.onKeyDown && options.onKeyDown(e, inp.value, close)) { return; }
                if (e.keyCode == 27 || (options.closeOnEnter !== false && e.keyCode == 13)) {
                    inp.blur();
                    CodeMirror.e_stop(e);
                    close();
                }
                if (e.keyCode == 13) callback(inp.value, e);
            });

            if (options.closeOnBlur !== false) CodeMirror.on(dialog, "focusout", function (evt) {
                if (evt.relatedTarget !== null) close();
            });
        } else if (button = dialog.getElementsByTagName("button")[0]) {
            CodeMirror.on(button, "click", function() {
                close();
                me.focus();
            });

            if (options.closeOnBlur !== false) CodeMirror.on(button, "blur", close);

            button.focus();
        }
        return close;
    }

    static function openConfirm(cm:CodeMirror, template:Dynamic, callbacks:Dynamic, options:Dynamic):Void {
        closeNotification(cm, null);
        var dialog = dialogDiv(cm, template, options && options.bottom);
        var buttons = dialog.getElementsByTagName("button");
        var closed = false, me = cm, blurring = 1;
        function close():Void {
            if (closed) return;
            closed = true;
            CodeMirror.rmClass(dialog.parentNode, 'dialog-opened');
            dialog.parentNode.removeChild(dialog);
            me.focus();
        }
        buttons[0].focus();
        for (i in 0...buttons.length) {
            var b = buttons[i];
            (function(callback) {
                CodeMirror.on(b, "click", function(e) {
                    CodeMirror.e_preventDefault(e);
                    close();
                    if (callback) callback(me);
                });
            })(callbacks[i]);
            CodeMirror.on(b, "blur", function() {
                --blurring;
                setTimeout(function() { if (blurring <= 0) close(); }, 200);
            });
            CodeMirror.on(b, "focus", function() { ++blurring; });
        }
    }

    static function openNotification(cm:CodeMirror, template:Dynamic, options:Dynamic):Dynamic {
        closeNotification(cm, close);
        var dialog = dialogDiv(cm, template, options && options.bottom);
        var closed = false, doneTimer;
        var duration = options && typeof options.duration !== "undefined" ? options.duration : 5000;

        function close():Void {
            if (closed) return;
            closed = true;
            clearTimeout(doneTimer);
            CodeMirror.rmClass(dialog.parentNode, 'dialog-opened');
            dialog.parentNode.removeChild(dialog);
        }

        CodeMirror.on(dialog, 'click', function(e) {
            CodeMirror.e_preventDefault(e);
            close();
        });

        if (duration)
            doneTimer = setTimeout(close, duration);

        return close;
    }
}

CodeMirror.defineExtension("openDialog", Dialog.openDialog);
CodeMirror.defineExtension("openConfirm", Dialog.openConfirm);
CodeMirror.defineExtension("openNotification", Dialog.openNotification);
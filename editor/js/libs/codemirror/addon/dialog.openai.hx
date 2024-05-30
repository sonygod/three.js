package three.js.editor.js.libs.codemirror.addon;

import js.html.Element;
import js.html.Document;
import codemirror.CodeMirror;

class Dialog {
  static function dialogDiv(cm:CodeMirror, template:Any, bottom:Bool):Element {
    var wrap = cm.getWrapperElement();
    var dialog = wrap.appendChild(Document.createElement("div"));
    if (bottom)
      dialog.className = "CodeMirror-dialog CodeMirror-dialog-bottom";
    else
      dialog.className = "CodeMirror-dialog CodeMirror-dialog-top";

    if (Std.is(template, String))
      dialog.innerHTML = template;
    else
      dialog.appendChild(template);

    CodeMirror.addClass(wrap, 'dialog-opened');
    return dialog;
  }

  static function closeNotification(cm:CodeMirror, newVal:Any) {
    if (cm.state.currentNotificationClose != null)
      cm.state.currentNotificationClose();
    cm.state.currentNotificationClose = newVal;
  }

  static function openDialog(cm:CodeMirror, template:Any, callback:Any, ?options:Any):Void {
    closeNotification(cm, null);

    var dialog = dialogDiv(cm, template, options.bottom);
    var closed = false, me = cm;
    function close(newVal:Any) {
      if (Std.is(newVal, String)) {
        var inp = dialog.getElementsByTagName("input")[0];
        inp.value = newVal;
      } else {
        if (closed) return;
        closed = true;
        CodeMirror.rmClass(dialog.parentNode, 'dialog-opened');
        dialog.parentNode.removeChild(dialog);
        me.focus();

        if (options.onClose != null) options.onClose(dialog);
      }
    }

    var inp = dialog.getElementsByTagName("input")[0];
    if (inp != null) {
      inp.focus();

      if (options.value != null) {
        inp.value = options.value;
        if (options.selectValueOnOpen != false) {
          inp.select();
        }
      }

      if (options.onInput != null)
        CodeMirror.on(inp, "input", function(e) { options.onInput(e, inp.value, close);});
      if (options.onKeyUp != null)
        CodeMirror.on(inp, "keyup", function(e) {options.onKeyUp(e, inp.value, close);});

      CodeMirror.on(inp, "keydown", function(e) {
        if (options != null && options.onKeyDown != null && options.onKeyDown(e, inp.value, close)) { return; }
        if (e.keyCode == 27 || (options.closeOnEnter != false && e.keyCode == 13)) {
          inp.blur();
          CodeMirror.e_stop(e);
          close();
        }
        if (e.keyCode == 13) callback(inp.value, e);
      });

      if (options.closeOnBlur != false) CodeMirror.on(dialog, "focusout", function (evt) {
        if (evt.relatedTarget != null) close();
      });
    } else {
      var button = dialog.getElementsByTagName("button")[0];
      CodeMirror.on(button, "click", function() {
        close();
        me.focus();
      });

      if (options.closeOnBlur != false) CodeMirror.on(button, "blur", close);

      button.focus();
    }
  }

  static function openConfirm(cm:CodeMirror, template:Any, callbacks:Array<Any>, ?options:Any):Void {
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
          if (callback != null) callback(me);
        });
      })(callbacks[i]);
      CodeMirror.on(b, "blur", function() {
        --blurring;
        haxe.Timer.delay(function() { if (blurring <= 0) close(); }, 200);
      });
      CodeMirror.on(b, "focus", function() { ++blurring; });
    }
  }

  static function openNotification(cm:CodeMirror, template:Any, ?options:Any):Void {
    closeNotification(cm, close);
    var dialog = dialogDiv(cm, template, options && options.bottom);
    var closed = false, doneTimer:Any;
    var duration = options != null && options.duration != null ? options.duration : 5000;

    function close():Void {
      if (closed) return;
      closed = true;
      if (doneTimer != null) clearTimeout(doneTimer);
      CodeMirror.rmClass(dialog.parentNode, 'dialog-opened');
      dialog.parentNode.removeChild(dialog);
    }

    CodeMirror.on(dialog, 'click', function(e) {
      CodeMirror.e_preventDefault(e);
      close();
    });

    if (duration != null)
      doneTimer = haxe.Timer.delay(close, duration);
  }
}
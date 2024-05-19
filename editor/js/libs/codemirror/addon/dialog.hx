package three.js.editor.js.libs.codemirror.addon;

import js.html.DOMElement;
import js.html.Document;
import js.html.Element;
import js.Browser;

class Dialog {
  static function dialogDiv(cm:Dynamic, template:Dynamic, bottom:Bool):Element {
    var wrap:Element = cm.getWrapperElement();
    var dialog:Element = document.createDivElement();
    if (bottom) {
      dialog.className = "CodeMirror-dialog CodeMirror-dialog-bottom";
    } else {
      dialog.className = "CodeMirror-dialog CodeMirror-dialog-top";
    }
    if (Std.is(template, String)) {
      dialog.innerHTML = template;
    } else { // Assuming it's a detached DOM element.
      dialog.appendChild(template);
    }
    Browser.document.body.className += ' dialog-opened';
    return dialog;
  }

  static function closeNotification(cm:Dynamic, newVal:Dynamic) {
    if (cm.state.currentNotificationClose != null) {
      cm.state.currentNotificationClose();
    }
    cm.state.currentNotificationClose = newVal;
  }

  static function openDialog(cm:Dynamic, template:Dynamic, callback:Dynamic, ?options:Dynamic) {
    if (options == null) options = {};
    closeNotification(cm, null);
    var dialog:Element = dialogDiv(cm, template, options.bottom);
    var closed:Bool = false;
    var me:Dynamic = cm;
    function close(?newVal:Dynamic) {
      if (Std.is(newVal, String)) {
        inp.value = newVal;
      } else {
        if (closed) return;
        closed = true;
        Browser.document.body.className -= ' dialog-opened';
        dialog.parentNode.removeChild(dialog);
        me.focus();
        if (options.onClose != null) options.onClose(dialog);
      }
    }
    var inp:Element = dialog.getElementsByTagName("input")[0];
    if (inp != null) {
      inp.focus();
      if (options.value != null) {
        inp.value = options.value;
        if (options.selectValueOnOpen == null || options.selectValueOnOpen) {
          inp.select();
        }
      }
      if (options.onInput != null)
        Browser.document.addEventListener("input", function(e) {
          options.onInput(e, inp.value, close);
        });
      if (options.onKeyUp != null)
        Browser.document.addEventListener("keyup", function(e) {
          options.onKeyUp(e, inp.value, close);
        });
      Browser.document.addEventListener("keydown", function(e) {
        if (options.onKeyDown != null && options.onKeyDown(e, inp.value, close)) return;
        if (e.keyCode == 27 || (options.closeOnEnter == null || options.closeOnEnter && e.keyCode == 13)) {
          inp.blur();
          Browser.document.addEventListener("keydown", function(e) {
            e.preventDefault();
          });
          close();
        }
        if (e.keyCode == 13) callback(inp.value, e);
      });
      if (options.closeOnBlur != null && !options.closeOnBlur) {
        Browser.document.addEventListener("focusout", function(evt) {
          if (evt.relatedTarget == null) close();
        });
      }
    } else {
      var button:Element = dialog.getElementsByTagName("button")[0];
      Browser.document.addEventListener("click", function() {
        close();
        me.focus();
      });
      if (options.closeOnBlur != null && !options.closeOnBlur) {
        Browser.document.addEventListener("blur", close);
      }
      button.focus();
    }
    return close;
  }

  static function openConfirm(cm:Dynamic, template:Dynamic, callbacks:Array<Dynamic>, ?options:Dynamic) {
    closeNotification(cm, null);
    var dialog:Element = dialogDiv(cm, template, options != null && options.bottom);
    var buttons:Array<Element> = dialog.getElementsByTagName("button");
    var closed:Bool = false;
    var me:Dynamic = cm;
    var blurring:Int = 1;
    function close() {
      if (closed) return;
      closed = true;
      Browser.document.body.className -= ' dialog-opened';
      dialog.parentNode.removeChild(dialog);
      me.focus();
    }
    buttons[0].focus();
    for (i in 0...buttons.length) {
      var b:Element = buttons[i];
      (function(callback:Dynamic) {
        Browser.document.addEventListener("click", function(e) {
          Browser.document.addEventListener("click", function(e) {
            e.preventDefault();
          });
          close();
          if (callback != null) callback(me);
        });
      })(callbacks[i]);
      Browser.document.addEventListener("blur", function() {
        --blurring;
        Browser.window.setTimeout(function() {
          if (blurring <= 0) close();
        }, 200);
      });
      Browser.document.addEventListener("focus", function() {
        ++blurring;
      });
    }
  }

  static function openNotification(cm:Dynamic, template:Dynamic, ?options:Dynamic) {
    closeNotification(cm, close);
    var dialog:Element = dialogDiv(cm, template, options != null && options.bottom);
    var closed:Bool = false;
    var doneTimer:Dynamic;
    var duration:Int = if (options != null && options.duration != null) options.duration else 5000;

    function close() {
      if (closed) return;
      closed = true;
      clearTimeout(doneTimer);
      Browser.document.body.className -= ' dialog-opened';
      dialog.parentNode.removeChild(dialog);
    }

    Browser.document.addEventListener("click", function(e) {
      Browser.document.addEventListener("click", function(e) {
        e.preventDefault();
      });
      close();
    });

    if (duration != 0) {
      doneTimer = Browser.window.setTimeout(close, duration);
    }
    return close;
  }
}
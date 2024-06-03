package;

import codemirror.CodeMirror;
import codemirror.CodeMirrorExtension;
import codemirror.dom;

class Dialog {
  public static function dialogDiv(cm:CodeMirror, template:String, bottom:Bool):HtmlElement {
    var wrap = cm.getWrapperElement();
    var dialog:HtmlElement = wrap.appendChild(dom.createElement("div"));
    if (bottom) {
      dialog.className = "CodeMirror-dialog CodeMirror-dialog-bottom";
    } else {
      dialog.className = "CodeMirror-dialog CodeMirror-dialog-top";
    }
    dialog.innerHTML = template;
    dom.addClass(wrap, 'dialog-opened');
    return dialog;
  }

  public static function closeNotification(cm:CodeMirror, newVal:Dynamic):Void {
    if (cm.state.currentNotificationClose != null) {
      cm.state.currentNotificationClose();
    }
    cm.state.currentNotificationClose = newVal;
  }

  public static function openDialog(cm:CodeMirror, template:String, callback:Dynamic, options:Dynamic):Dynamic {
    if (options == null) {
      options = {};
    }
    closeNotification(cm, null);
    var dialog = dialogDiv(cm, template, options.bottom);
    var closed = false;
    var me = cm;
    var close = function(newVal:Dynamic) {
      if (typeof newVal == 'string') {
        (dialog.getElementsByTagName("input")[0] as HtmlInputElement).value = newVal;
      } else {
        if (closed) {
          return;
        }
        closed = true;
        dom.rmClass(dialog.parentNode, 'dialog-opened');
        dialog.parentNode.removeChild(dialog);
        me.focus();
        if (options.onClose != null) {
          options.onClose(dialog);
        }
      }
    };
    var inp = dialog.getElementsByTagName("input")[0];
    var button:HtmlElement;
    if (inp != null) {
      inp.focus();
      if (options.value != null) {
        inp.value = options.value;
        if (options.selectValueOnOpen != false) {
          inp.select();
        }
      }
      if (options.onInput != null) {
        dom.on(inp, "input", function(e:Dynamic) {
          options.onInput(e, inp.value, close);
        });
      }
      if (options.onKeyUp != null) {
        dom.on(inp, "keyup", function(e:Dynamic) {
          options.onKeyUp(e, inp.value, close);
        });
      }
      dom.on(inp, "keydown", function(e:Dynamic) {
        if (options != null && options.onKeyDown != null && options.onKeyDown(e, inp.value, close)) {
          return;
        }
        if (e.keyCode == 27 || (options.closeOnEnter != false && e.keyCode == 13)) {
          inp.blur();
          dom.e_stop(e);
          close();
        }
        if (e.keyCode == 13) {
          callback(inp.value, e);
        }
      });
      if (options.closeOnBlur != false) {
        dom.on(dialog, "focusout", function(evt:Dynamic) {
          if (evt.relatedTarget != null) {
            close();
          }
        });
      }
    } else if (button = dialog.getElementsByTagName("button")[0]) {
      dom.on(button, "click", function() {
        close();
        me.focus();
      });
      if (options.closeOnBlur != false) {
        dom.on(button, "blur", close);
      }
      button.focus();
    }
    return close;
  }

  public static function openConfirm(cm:CodeMirror, template:String, callbacks:Array<Dynamic>, options:Dynamic):Void {
    closeNotification(cm, null);
    var dialog = dialogDiv(cm, template, options != null && options.bottom);
    var buttons = dialog.getElementsByTagName("button");
    var closed = false;
    var me = cm;
    var blurring = 1;
    var close = function() {
      if (closed) {
        return;
      }
      closed = true;
      dom.rmClass(dialog.parentNode, 'dialog-opened');
      dialog.parentNode.removeChild(dialog);
      me.focus();
    };
    buttons[0].focus();
    for (var i = 0; i < buttons.length; ++i) {
      var b = buttons[i];
      (function(callback:Dynamic) {
        dom.on(b, "click", function(e:Dynamic) {
          dom.e_preventDefault(e);
          close();
          if (callback != null) {
            callback(me);
          }
        });
      })(callbacks[i]);
      dom.on(b, "blur", function() {
        --blurring;
        setTimeout(function() {
          if (blurring <= 0) {
            close();
          }
        }, 200);
      });
      dom.on(b, "focus", function() {
        ++blurring;
      });
    }
  }

  public static function openNotification(cm:CodeMirror, template:String, options:Dynamic):Dynamic {
    closeNotification(cm, close);
    var dialog = dialogDiv(cm, template, options != null && options.bottom);
    var closed = false;
    var doneTimer:Dynamic;
    var duration = options != null && typeof options.duration != "undefined" ? options.duration : 5000;
    var close = function() {
      if (closed) {
        return;
      }
      closed = true;
      clearTimeout(doneTimer);
      dom.rmClass(dialog.parentNode, 'dialog-opened');
      dialog.parentNode.removeChild(dialog);
    };
    dom.on(dialog, 'click', function(e:Dynamic) {
      dom.e_preventDefault(e);
      close();
    });
    if (duration != null) {
      doneTimer = setTimeout(close, duration);
    }
    return close;
  }
}

class DialogExtension extends CodeMirrorExtension {
  public function new() {
    super();
    this.addExtension("openDialog", Dialog.openDialog);
    this.addExtension("openConfirm", Dialog.openConfirm);
    this.addExtension("openNotification", Dialog.openNotification);
  }
}
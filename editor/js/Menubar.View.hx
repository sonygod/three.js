package three.js.editor.js;

import ui.UIPanel;
import ui.UIRow;

class MenubarView {
  private var editor:Dynamic;
  private var signals:Dynamic;
  private var strings:Dynamic;
  private var container:UIPanel;

  public function new(editor:Dynamic) {
    this.editor = editor;
    signals = editor.signals;
    strings = editor.strings;

    container = new UIPanel();
    container.addClass('menu');

    var title:UIPanel = new UIPanel();
    title.addClass('title');
    title.text = strings.getKey('menubar/view');
    container.add(title);

    var options:UIPanel = new UIPanel();
    options.addClass('options');
    container.add(options);

    // Fullscreen
    var option:UIRow = new UIRow();
    option.addClass('option');
    option.text = strings.getKey('menubar/view/fullscreen');
    option.onClick = function() {
      if (Browser.document.fullscreenElement == null) {
        Browser.document.documentElement.requestFullscreen();
      } else if (Browser.document.exitFullscreen != null) {
        Browser.document.exitFullscreen();
      }

      // Safari
      if (Browser.document.webkitFullscreenElement == null) {
        Browser.document.documentElement.webkitRequestFullscreen();
      } else if (Browser.document.webkitExitFullscreen != null) {
        Browser.document.webkitExitFullscreen();
      }
    };
    options.add(option);

    // XR (Work in progress)
    if (Reflect.hasField(Browser.navigator, 'xr')) {
      if (Reflect.hasField(Browser.navigator.xr, 'offerSession')) {
        signals.offerXR.dispatch('immersive-ar');
      } else {
        Browser.navigator.xr.isSessionSupported('immersive-ar').then(function(supported:Bool) {
          if (supported) {
            var option:UIRow = new UIRow();
            option.addClass('option');
            option.text = 'AR';
            option.onClick = function() {
              signals.enterXR.dispatch('immersive-ar');
            };
            options.add(option);
          } else {
            Browser.navigator.xr.isSessionSupported('immersive-vr').then(function(supported:Bool) {
              if (supported) {
                var option:UIRow = new UIRow();
                option.addClass('option');
                option.text = 'VR';
                option.onClick = function() {
                  signals.enterXR.dispatch('immersive-vr');
                };
                options.add(option);
              }
            });
          }
        });
      }
    }
  }

  public function getContainer():UIPanel {
    return container;
  }
}
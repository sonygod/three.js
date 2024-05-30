package three.js.editor.js;

import ui.UIPanel;
import ui.UIRow;

class MenubarView {
    private var editor:Editor;

    public function new(editor:Editor) {
        this.editor = editor;
        var signals = editor.signals;
        var strings = editor.strings;

        var container = new UIPanel();
        container.addClass('menu');

        var title = new UIPanel();
        title.addClass('title');
        title.text(strings.getKey('menubar/view'));
        container.add(title);

        var options = new UIPanel();
        options.addClass('options');
        container.add(options);

        // Fullscreen

        var option = new UIRow();
        option.addClass('option');
        option.text(strings.getKey('menubar/view/fullscreen'));
        option.onClick(function() {
            if (js.Browser.document.fullscreenElement == null) {
                js.Browser.document.documentElement.requestFullscreen();
            } else if (js.Browser.document.exitFullscreen != null) {
                js.Browser.document.exitFullscreen();
            }
            // Safari
            if (js.Browser.document.webkitFullscreenElement == null) {
                js.Browser.document.documentElement.webkitRequestFullscreen();
            } else if (js.Browser.document.webkitExitFullscreen != null) {
                js.Browser.document.webkitExitFullscreen();
            }
        });
        options.add(option);

        // XR (Work in progress)

        if (js.Browser.navigator.xr != null) {
            if (js.Browser.navigator.xr.offerSession != null) {
                signals.offerXR.dispatch('immersive-ar');
            } else {
                js.Browser.navigator.xr.isSessionSupported('immersive-ar').then(function(supported) {
                    if (supported) {
                        var option = new UIRow();
                        option.addClass('option');
                        option.text('AR');
                        option.onClick(function() {
                            signals.enterXR.dispatch('immersive-ar');
                        });
                        options.add(option);
                    } else {
                        js.Browser.navigator.xr.isSessionSupported('immersive-vr').then(function(supported) {
                            if (supported) {
                                var option = new UIRow();
                                option.addClass('option');
                                option.text('VR');
                                option.onClick(function() {
                                    signals.enterXR.dispatch('immersive-vr');
                                });
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
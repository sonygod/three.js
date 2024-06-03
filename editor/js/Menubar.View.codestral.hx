import ui.UIPanel;
import ui.UIRow;
import Signals;
import Strings;

class MenubarView {

    public function new(editor:Editor) {

        var signals:Signals = editor.signals;
        var strings:Strings = editor.strings;

        var container:UIPanel = new UIPanel();
        container.setClass('menu');

        var title:UIPanel = new UIPanel();
        title.setClass('title');
        title.setTextContent(strings.getKey('menubar/view'));
        container.add(title);

        var options:UIPanel = new UIPanel();
        options.setClass('options');
        container.add(options);

        // Fullscreen

        var option:UIRow = new UIRow();
        option.setClass('option');
        option.setTextContent(strings.getKey('menubar/view/fullscreen'));
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

        if (js.Browser.window.hasOwnProperty('xr')) {

            if (js.Browser.window.navigator.xr.hasOwnProperty('offerSession')) {

                signals.offerXR.dispatch('immersive-ar');

            } else {

                js.Browser.window.navigator.xr.isSessionSupported('immersive-ar')
                    .then(function(supported:Bool) {

                        if (supported) {

                            var option:UIRow = new UIRow();
                            option.setClass('option');
                            option.setTextContent('AR');
                            option.onClick(function() {

                                signals.enterXR.dispatch('immersive-ar');

                            });
                            options.add(option);

                        } else {

                            js.Browser.window.navigator.xr.isSessionSupported('immersive-vr')
                                .then(function(supported:Bool) {

                                    if (supported) {

                                        var option:UIRow = new UIRow();
                                        option.setClass('option');
                                        option.setTextContent('VR');
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

        return container;

    }

}
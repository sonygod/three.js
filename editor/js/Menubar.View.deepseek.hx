import three.js.editor.js.libs.ui.UIPanel;
import three.js.editor.js.libs.ui.UIRow;

class MenubarView {

    public function new(editor:Dynamic) {

        var signals = editor.signals;
        var strings = editor.strings;

        var container = new UIPanel();
        container.setClass('menu');

        var title = new UIPanel();
        title.setClass('title');
        title.setTextContent(strings.getKey('menubar/view'));
        container.add(title);

        var options = new UIPanel();
        options.setClass('options');
        container.add(options);

        // Fullscreen

        var option = new UIRow();
        option.setClass('option');
        option.setTextContent(strings.getKey('menubar/view/fullscreen'));
        option.onClick(function () {

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

        if ('xr' in js.Browser.navigator) {

            if ('offerSession' in js.Browser.navigator.xr) {

                signals.offerXR.dispatch('immersive-ar');

            } else {

                js.Browser.navigator.xr.isSessionSupported('immersive-ar')
                    .then(function (supported) {

                        if (supported) {

                            var option = new UIRow();
                            option.setClass('option');
                            option.setTextContent('AR');
                            option.onClick(function () {

                                signals.enterXR.dispatch('immersive-ar');

                            });
                            options.add(option);

                        } else {

                            js.Browser.navigator.xr.isSessionSupported('immersive-vr')
                                .then(function (supported) {

                                    if (supported) {

                                        var option = new UIRow();
                                        option.setClass('option');
                                        option.setTextContent('VR');
                                        option.onClick(function () {

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
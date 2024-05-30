import js.Browser.Document;
import js.Browser.Navigator;
import js.Browser.NavigatorXR;
import js.Browser.Window;

class MenubarView {
    static function new(editor:Editor) {
        var signals = editor.signals;
        var strings = editor.strings;
        var container = UIPanel.create().setClass('menu');
        var title = UIPanel.create().setClass('title');
        title.html = strings.getKey('menubar/view');
        container.add(title);
        var options = UIPanel.create().setClass('options');
        container.add(options);
        var option = UIRow.create().setClass('option');
        option.html = strings.getKey('menubar/view/fullscreen');
        option.onClick(function() {
            if (Document.fullscreenElement() == null) {
                Document.documentElement().requestFullscreen();
            } else if (Document.exitFullscreen() != null) {
                Document.exitFullscreen();
            }
            if (Document.webkitFullscreenElement() == null) {
                Document.documentElement().webkitRequestFullscreen();
            } else if (Document.webkitExitFullscreen() != null) {
                Document.webkitExitFullscreen();
            }
        });
        options.add(option);
        if (Reflect.field(Navigator, 'xr') != null) {
            var offerSession = Reflect.field(Navigator.xr(), 'offerSession');
            if (offerSession != null) {
                signals.offerXR.dispatch('immersive-ar');
            } else {
                var supported = Reflect.callMethod(Navigator.xr(), 'isSessionSupported', ['immersive-ar']);
                if (supported) {
                    var option1 = UIRow.create().setClass('option');
                    option1.html = 'AR';
                    option1.onClick(function() {
                        signals.enterXR.dispatch('immersive-ar');
                    });
                    options.add(option1);
                } else {
                    var supported1 = Reflect.callMethod(Navigator.xr(), 'isSessionSupported', ['immersive-vr']);
                    if (supported1) {
                        var option2 = UIRow.create().setClass('option');
                        option2.html = 'VR';
                        option2.onClick(function() {
                            signals.enterXR.dispatch('immersive-vr');
                        });
                        options.add(option2);
                    }
                }
            }
        }
        return container;
    }
}

class UIPanel {
    static function create() {
        return new UIPanel();
    }
    function setClass(className:String) {
        this.className = className;
    }
    function add(row:UIRow) {
        this.appendChild(row);
    }
}

class UIRow {
    static function create() {
        return new UIRow();
    }
    function setClass(className:String) {
        this.className = className;
    }
    function setTextContent(text:String) {
        this.textContent = text;
    }
    function onClick(callback:Void->Void) {
        this.addEventListener('click', function(_) {
            callback();
        });
    }
}
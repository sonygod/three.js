import js.html.Document;
import js.html.HTMLElement;
import js.html.ImageElement;

class Toolbar {
    function new(editor:Editor) {
        var signals = editor.signals;
        var strings = editor.strings;
        var container = new UIPanel();
        container.setId('toolbar');

        // translate / rotate / scale
        var translateIcon = Document.createImageElement();
        translateIcon.title = strings.getKey('toolbar/translate');
        translateIcon.src = 'images/translate.svg';

        var translate = new UIButton();
        translate.dom.className = 'Button selected';
        translate.dom.appendChild(translateIcon);
        translate.onClick(function() {
            signals.transformModeChanged.dispatch('translate');
        });
        container.add(translate);

        var rotateIcon = Document.createImageElement();
        rotateIcon.title = strings.getKey('toolbar/rotate');
        rotateIcon.src = 'images/rotate.svg';

        var rotate = new UIButton();
        rotate.dom.appendChild(rotateIcon);
        rotate.onClick(function() {
            signals.transformModeChanged.dispatch('rotate');
        });
        container.add(rotate);

        var scaleIcon = Document.createImageElement();
        scaleIcon.title = strings.getKey('toolbar/scale');
        scaleIcon.src = 'images/scale.svg';

        var scale = new UIButton();
        scale.dom.appendChild(scaleIcon);
        scale.onClick(function() {
            signals.transformModeChanged.dispatch('scale');
        });
        container.add(scale);

        var local = new UICheckbox(false);
        local.dom.title = strings.getKey('toolbar/local');
        local.onChange(function() {
            signals.spaceChanged.dispatch(local.getValue() ? 'local' : 'world');
        });
        container.add(local);

        // update UI on transform mode change
        signals.transformModeChanged.add(function(mode:String) {
            translate.dom.classList.remove('selected');
            rotate.dom.classList.remove('selected');
            scale.dom.classList.remove('selected');

            switch(mode) {
                case 'translate':
                    translate.dom.classList.add('selected');
                    break;
                case 'rotate':
                    rotate.dom.classList.add('selected');
                    break;
                case 'scale':
                    scale.dom.classList.add('selected');
                    break;
            }
        });

        return container;
    }
}

class UIPanel {
    public function setId(id:String) {
        // implementation
    }

    public function add(element:UIButton) {
        // implementation
    }
}

class UIButton {
    public var dom:HTMLElement;

    public function new() {
        // implementation
    }

    public function onClick(callback:Void->Void) {
        // implementation
    }

    public function appendChild(element:ImageElement) {
        // implementation
    }
}

class UICheckbox {
    public var dom:HTMLElement;

    public function new(value:Bool) {
        // implementation
    }

    public function getValue():Bool {
        // implementation
    }

    public function onChange(callback:Void->Void) {
        // implementation
    }
}

class Editor {
    public var signals:Signals;
    public var strings:Strings;
}

class Signals {
    public var transformModeChanged:TransformModeChangedSignal;
    public var spaceChanged:SpaceChangedSignal;
}

class TransformModeChangedSignal {
    public function dispatch(mode:String) {
        // implementation
    }

    public function add(callback:String->Void) {
        // implementation
    }
}

class SpaceChangedSignal {
    public function dispatch(space:String) {
        // implementation
    }
}

class Strings {
    public function getKey(key:String):String {
        // implementation
    }
}
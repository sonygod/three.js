package three.js.editor.js;

import ui.UIPanel;
import ui.UIButton;
import ui.UICheckbox;

class Toolbar {
    public function new(editor:Editor) {
        var signals = editor.signals;
        var strings = editor.strings;

        var container = new UIPanel();
        container.setId('toolbar');

        // translate / rotate / scale

        var translateIcon = js.Browser.document.createElement('img');
        translateIcon.title = strings.getKey('toolbar/translate');
        translateIcon.src = 'images/translate.svg';

        var translate = new UIButton();
        translate.dom.className = 'Button selected';
        translate.dom.appendChild(translateIcon);
        translate.onClick(function() {
            signals.transformModeChanged.dispatch('translate');
        });
        container.add(translate);

        var rotateIcon = js.Browser.document.createElement('img');
        rotateIcon.title = strings.getKey('toolbar/rotate');
        rotateIcon.src = 'images/rotate.svg';

        var rotate = new UIButton();
        rotate.dom.appendChild(rotateIcon);
        rotate.onClick(function() {
            signals.transformModeChanged.dispatch('rotate');
        });
        container.add(rotate);

        var scaleIcon = js.Browser.document.createElement('img');
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

        //

        signals.transformModeChanged.add(function(mode:String) {
            translate.dom.classList.remove('selected');
            rotate.dom.classList.remove('selected');
            scale.dom.classList.remove('selected');

            switch (mode) {
                case 'translate': translate.dom.classList.add('selected'); break;
                case 'rotate': rotate.dom.classList.add('selected'); break;
                case 'scale': scale.dom.classList.add('selected'); break;
            }
        });

        return container;
    }
}
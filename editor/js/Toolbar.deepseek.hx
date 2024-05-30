import js.Lib;
import js.Browser.document;
import js.html.ImageElement;
import js.html.HTMLElement;

class Toolbar {

    public function new(editor:Dynamic) {

        var signals = editor.signals;
        var strings = editor.strings;

        var container = new js.Lib.UIPanel();
        container.setId('toolbar');

        // translate / rotate / scale

        var translateIcon = cast(document.createElement('img'), ImageElement);
        translateIcon.title = strings.getKey('toolbar/translate');
        translateIcon.src = 'images/translate.svg';

        var translate = new js.Lib.UIButton();
        translate.dom.className = 'Button selected';
        translate.dom.appendChild(translateIcon);
        translate.onClick(function () {

            signals.transformModeChanged.dispatch('translate');

        });
        container.add(translate);

        var rotateIcon = cast(document.createElement('img'), ImageElement);
        rotateIcon.title = strings.getKey('toolbar/rotate');
        rotateIcon.src = 'images/rotate.svg';

        var rotate = new js.Lib.UIButton();
        rotate.dom.appendChild(rotateIcon);
        rotate.onClick(function () {

            signals.transformModeChanged.dispatch('rotate');

        });
        container.add(rotate);

        var scaleIcon = cast(document.createElement('img'), ImageElement);
        scaleIcon.title = strings.getKey('toolbar/scale');
        scaleIcon.src = 'images/scale.svg';

        var scale = new js.Lib.UIButton();
        scale.dom.appendChild(scaleIcon);
        scale.onClick(function () {

            signals.transformModeChanged.dispatch('scale');

        });
        container.add(scale);

        var local = new js.Lib.UICheckbox(false);
        local.dom.title = strings.getKey('toolbar/local');
        local.onChange(function () {

            signals.spaceChanged.dispatch(this.getValue() === true ? 'local' : 'world');

        });
        container.add(local);

        //

        signals.transformModeChanged.add(function (mode) {

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
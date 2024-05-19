package three.js.editor.js;

import js.ui UIBreak;
import js.ui UIButton;
import js.ui UIDiv;
import js.ui UIText;
import js.ui UINumber;
import js.ui UIRow;

class SidebarObjectAnimation {
    private var editor:Editor;
    private var strings:Strings;
    private var signals:Signals;
    private var mixer:Mixer;
    private var animationsList:UIDiv;

    public function new(editor:Editor) {
        this.editor = editor;
        strings = editor.strings;
        signals = editor.signals;
        mixer = editor.mixer;

        // ...

        var container = new UIDiv();
        container.setMarginTop('20px');
        container.setDisplay('none');

        container.add(new UIText(strings.getKey('sidebar/animations')).setTextTransform('uppercase'));
        container.add(new UIBreak());
        container.add(new UIBreak());

        animationsList = new UIDiv();
        container.add(animationsList);

        var mixerTimeScaleRow = new UIRow();
        var mixerTimeScaleNumber = new UINumber(1).setWidth('60px').setRange(-10, 10);
        mixerTimeScaleNumber.onChange(function() {
            mixer.timeScale = mixerTimeScaleNumber.getValue();
        });

        mixerTimeScaleRow.add(new UIText(strings.getKey('sidebar/animations/timescale')).setClass('Label'));
        mixerTimeScaleRow.add(mixerTimeScaleNumber);

        container.add(mixerTimeScaleRow);

        signals.objectSelected.add(function(object) {
            if (object != null && object.animations.length > 0) {
                animationsList.clear();

                for (animation in object.animations) {
                    animationsList.add(new Animation(animation, object));
                }

                container.setDisplay('');
            } else {
                container.setDisplay('none');
            }
        });

        signals.objectRemoved.add(function(object) {
            if (object != null && object.animations.length > 0) {
                mixer.uncacheRoot(object);
            }
        });
    }

    private function getButtonText(action) {
        return action.isRunning() ? strings.getKey('sidebar/animations/stop') : strings.getKey('sidebar/animations/play');
    }

    private function Animation(animation, object) {
        var action = mixer.clipAction(animation, object);

        var container = new UIRow();

        var name = new UIText(animation.name).setWidth('200px');
        container.add(name);

        var button = new UIButton(getButtonText(action));
        button.onClick(function() {
            action.isRunning() ? action.stop() : action.play();
            button.setTextContent(getButtonText(action));
        });

        container.add(button);

        return container;
    }
}
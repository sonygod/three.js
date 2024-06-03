import js.ui.libs.UIBreak;
import js.ui.libs.UIButton;
import js.ui.libs.UIDiv;
import js.ui.libs.UIText;
import js.ui.libs.UINumber;
import js.ui.libs.UIRow;

class SidebarObjectAnimation {
    private var editor: Editor;
    private var strings: Strings;
    private var signals: Signals;
    private var mixer: Mixer;
    private var container: UIDiv;
    private var animationsList: UIDiv;
    private var mixerTimeScaleNumber: UINumber;

    public function new(editor: Editor) {
        this.editor = editor;
        this.strings = editor.strings;
        this.signals = editor.signals;
        this.mixer = editor.mixer;

        setupUI();
        setupSignals();
    }

    private function getButtonText(action: Action): String {
        return action.isRunning()
            ? strings.getKey('sidebar/animations/stop')
            : strings.getKey('sidebar/animations/play');
    }

    private function Animation(animation: AnimationClip, object: Object3D): UIRow {
        var action = mixer.clipAction(animation, object);

        var container = new UIRow();

        var name = new UIText(animation.name).setWidth('200px');
        container.add(name);

        var button = new UIButton(getButtonText(action));
        button.onClick(function() {
            if (action.isRunning()) action.stop(); else action.play();
            button.setTextContent(getButtonText(action));
        });

        container.add(button);

        return container;
    }

    private function setupUI(): Void {
        container = new UIDiv();
        container.setMarginTop('20px');
        container.setDisplay('none');

        container.add(new UIText(strings.getKey('sidebar/animations')).setTextTransform('uppercase'));
        container.add(new UIBreak());
        container.add(new UIBreak());

        animationsList = new UIDiv();
        container.add(animationsList);

        var mixerTimeScaleRow = new UIRow();
        mixerTimeScaleNumber = new UINumber(1).setWidth('60px').setRange(-10, 10);
        mixerTimeScaleNumber.onChange(() => mixer.timeScale = mixerTimeScaleNumber.getValue());

        mixerTimeScaleRow.add(new UIText(strings.getKey('sidebar/animations/timescale')).setClass('Label'));
        mixerTimeScaleRow.add(mixerTimeScaleNumber);

        container.add(mixerTimeScaleRow);
    }

    private function setupSignals(): Void {
        signals.objectSelected.add(function(object) {
            if (object !== null && object.animations.length > 0) {
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
            if (object !== null && object.animations.length > 0) {
                mixer.uncacheRoot(object);
            }
        });
    }

    public function getContainer(): UIDiv {
        return container;
    }
}
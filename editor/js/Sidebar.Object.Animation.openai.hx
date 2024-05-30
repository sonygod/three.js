package three.js.editor.js;

import js.html.Element;
import ui.UIBreak;
import ui.UIButton;
import ui.UIDiv;
import ui.UIText;
import ui.UINumber;
import ui.UIRow;

class SidebarObjectAnimation {
  private var editor:SidebarEditor;
  private var strings:Strings;
  private var signals:Signals;
  private var mixer:Mixer;

  public function new(editor:SidebarEditor) {
    this.editor = editor;
    this.strings = editor.strings;
    this.signals = editor.signals;
    this.mixer = editor.mixer;

    init();
  }

  private function init():Void {
    var container = new UIDiv();
    container.setMarginTop('20px');
    container.setDisplay('none');

    container.add(new UIText(strings.getKey('sidebar/animations')).setTextTransform('uppercase'));
    container.add(new UIBreak());
    container.add(new UIBreak());

    var animationsList = new UIDiv();
    container.add(animationsList);

    var mixerTimeScaleRow = new UIRow();
    var mixerTimeScaleNumber = new UINumber(1);
    mixerTimeScaleNumber.setWidth('60px');
    mixerTimeScaleNumber.setRange(-10, 10);
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

  private function getButtonText(action:Action):String {
    return action.isRunning() ? strings.getKey('sidebar/animations/stop') : strings.getKey('sidebar/animations/play');
  }

  private function Animation(animation:Animation, object:Object3D):Element {
    var action = mixer.clipAction(animation, object);

    var container = new UIRow();

    var name = new UIText(animation.name);
    name.setWidth('200px');
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
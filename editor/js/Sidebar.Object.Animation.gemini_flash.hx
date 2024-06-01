import ui.UIBreak;
import ui.UIButton;
import ui.UIDiv;
import ui.UIText;
import ui.UINumber;
import ui.UIRow;

class SidebarObjectAnimation {

	public function new(editor:Dynamic) {

		var strings = editor.strings;
		var signals = editor.signals;
		var mixer = editor.mixer;

		function getButtonText(action:Dynamic):String {
			return (action.isRunning() ? strings.getKey('sidebar/animations/stop') : strings.getKey('sidebar/animations/play'));
		}

		class Animation {
			public function new(animation:Dynamic, object:Dynamic) {
				var action = mixer.clipAction(animation, object);

				var container = new UIRow();

				var name = new UIText(animation.name).setWidth('200px');
				container.add(name);

				var button = new UIButton(getButtonText(action));
				button.onClick(function() {
					if (action.isRunning()) {
						action.stop();
					} else {
						action.play();
					}
					button.setTextContent(getButtonText(action));
				});

				container.add(button);

				this.element = container;
			}

			public var element(default, null):Dynamic;
		}

		signals.objectSelected.add(function(object:Dynamic) {
			if (object != null && object.animations.length > 0) {
				animationsList.clear();

				for (animation in object.animations) {
					animationsList.add(new Animation(animation, object).element);
				}

				container.setDisplay('');
			} else {
				container.setDisplay('none');
			}
		});

		signals.objectRemoved.add(function(object:Dynamic) {
			if (object != null && object.animations.length > 0) {
				mixer.uncacheRoot(object);
			}
		});

		var container = new UIDiv();
		container.setMarginTop('20px');
		container.setDisplay('none');

		container.add(new UIText(strings.getKey('sidebar/animations')).setTextTransform('uppercase'));
		container.add(new UIBreak());
		container.add(new UIBreak());

		var animationsList = new UIDiv();
		container.add(animationsList);

		var mixerTimeScaleRow = new UIRow();
		var mixerTimeScaleNumber = new UINumber(1).setWidth('60px').setRange(-10, 10);
		mixerTimeScaleNumber.onChange(function() {
			mixer.timeScale = mixerTimeScaleNumber.getValue();
		});

		mixerTimeScaleRow.add(new UIText(strings.getKey('sidebar/animations/timescale')).setClass('Label'));
		mixerTimeScaleRow.add(mixerTimeScaleNumber);

		container.add(mixerTimeScaleRow);

		this.element = container;
	}

	public var element(default, null):Dynamic;
}
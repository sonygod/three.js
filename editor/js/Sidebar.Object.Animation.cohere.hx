import js.Browser.window;

class SidebarObjectAnimation {
    function new(editor:Editor) {
        var strings = editor.strings;
        var signals = editor.signals;
        var mixer = editor.mixer;

        function getButtonText(action:Dynamic) -> String {
            if (action.isRunning()) {
                return strings.getKey('sidebar/animations/stop');
            } else {
                return strings.getKey('sidebar/animations/play');
            }
        }

        class Animation {
            var action:Dynamic;
            var container:UIRow;

            function new(animation:Dynamic, object:Dynamic) {
                action = mixer.clipAction(animation, object);
                container = UIRow_();

                var name = UIText_animation.name;
                name.setWidth('200px');
                container.add(name);

                var button = UIButton_getButtonText(action);
                button.onClick(function() {
                    if (action.isRunning()) {
                        action.stop();
                    } else {
                        action.play();
                    }
                    button.setTextContent(getButtonText(action));
                });

                container.add(button);
            }
        }

        signals.objectSelected.add(function(object:Dynamic) {
            if (object != null && object.animations.length > 0) {
                animationsList.clear();
                var animations = object.animations;
                for (animation in animations) {
                    animationsList.add(Animation(animation, object));
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

        var container = UIDiv_();
        container.setMarginTop('20px');
        container.setDisplay('none');

        container.add(UIText_(strings.getKey('sidebar/animations')).setTextTransform('uppercase'));
        container.add(UIBreak_());
        container.add(UIBreak_());

        var animationsList = UIDiv_();
        container.add(animationsList);

        var mixerTimeScaleRow = UIRow_();
        var mixerTimeScaleNumber = UINumber_1;
        mixerTimeScaleNumber.setWidth('60px');
        mixerTimeScaleNumber.setRange(-10, 10);
        mixerTimeScaleNumber.onChange(function() {
            mixer.timeScale = mixerTimeScaleNumber.getValue();
        });

        mixerTimeScaleRow.add(UIText_(strings.getKey('sidebar/animations/timescale')).setClass('Label'));
        mixerTimeScaleRow.add(mixerTimeScaleNumber);

        container.add(mixerTimeScaleRow);
    }
}

class UIBreak_ extends UIBreak {
    function new() {
        super();
    }
}

class UIButton_ extends UIButton {
    function new(label:String) {
        super(label);
    }
}

class UIText_ extends UIText {
    function new(text:String) {
        super(text);
    }
}

class UINumber_ extends UINumber {
    function new(value:Float) {
        super(value);
    }
}

class UIRow_ extends UIRow {
    function new() {
        super();
    }
}

class UIDiv_ extends UIDiv {
    function new() {
        super();
    }
}
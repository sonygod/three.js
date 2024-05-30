import js.Browser.document;
import js.Browser.window;
import js.Browser.UIEvent;
import js.Browser.Event;
import js.Browser.alert;
import js.Browser.confirm;

import three.js.editor.js.libs.ui.UIButton;
import three.js.editor.js.libs.ui.UIPanel;
import three.js.editor.js.libs.ui.UIBreak;
import three.js.editor.js.libs.ui.UIText;
import three.js.editor.js.libs.ui.three.UIBoolean;
import three.js.editor.js.libs.ui.three.UIOutliner;

class SidebarSettingsHistory {

    public function new(editor:Dynamic) {

        var strings = editor.strings;
        var signals = editor.signals;
        var config = editor.config;
        var history = editor.history;

        var container = new UIPanel();

        container.add(new UIText(strings.getKey('sidebar/history').toUpperCase()));

        var persistent = new UIBoolean(config.getKey('settings/history'), strings.getKey('sidebar/history/persistent'));
        persistent.setPosition('absolute').setRight('8px');
        persistent.onChange(function () {

            var value = this.getValue();

            config.setKey('settings/history', value);

            if (value) {

                alert(strings.getKey('prompt/history/preserve'));

                var lastUndoCmd = history.undos[history.undos.length - 1];
                var lastUndoId = (lastUndoCmd !== undefined) ? lastUndoCmd.id : 0;
                editor.history.enableSerialization(lastUndoId);

            } else {

                signals.historyChanged.dispatch();

            }

        });
        container.add(persistent);

        container.add(new UIBreak(), new UIBreak());

        var ignoreObjectSelectedSignal = false;

        var outliner = new UIOutliner(editor);
        outliner.onChange(function () {

            ignoreObjectSelectedSignal = true;

            editor.history.goToState(parseInt(outliner.getValue()));

            ignoreObjectSelectedSignal = false;

        });
        container.add(outliner);

        container.add(new UIBreak());

        var option = new UIButton(strings.getKey('sidebar/history/clear'));
        option.onClick(function () {

            if (confirm(strings.getKey('prompt/history/clear'))) {

                editor.history.clear();

            }

        });
        container.add(option);

        var refreshUI = function () {

            var options = [];

            function buildOption(object:Dynamic) {

                var option = document.createElement('div');
                option.value = object.id;

                return option;

            }

            (function addObjects(objects:Array<Dynamic>) {

                for (i in objects) {

                    var object = objects[i];

                    var option = buildOption(object);
                    option.innerHTML = '&nbsp;' + object.name;

                    options.push(option);

                }

            })(history.undos);


            (function addObjects(objects:Array<Dynamic>) {

                for (i in objects) {

                    var object = objects[i];

                    var option = buildOption(object);
                    option.innerHTML = '&nbsp;' + object.name;
                    option.style.opacity = 0.3;

                    options.push(option);

                }

            })(history.redos);

            outliner.setOptions(options);

        };

        refreshUI();

        signals.editorCleared.add(refreshUI);

        signals.historyChanged.add(refreshUI);
        signals.historyChanged.add(function (cmd:Dynamic) {

            if (ignoreObjectSelectedSignal === true) return;

            outliner.setValue(cmd !== undefined ? cmd.id : null);

        });


        return container;

    }

}
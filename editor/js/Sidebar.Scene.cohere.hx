import js.html.document.Document;
import js.html.dom.HTMLElement;
import js.html.dom.HTMLDivElement;
import js.html.dom.HTMLSelectElement;
import js.html.dom.HTMLInputElement;
import js.html.dom.HTMLUListElement;
import js.html.dom.HTMLLIElement;
import js.html.event.Event;
import js.html.event.UIEvent;
import js.html.event.MouseEvent;
import js.html.window.Window;

import js.three.Object3D;
import js.three.Scene;
import js.three.Camera;
import js.three.Light;
import js.three.Mesh;
import js.three.Line;
import js.three.Points;
import js.three.Geometry;
import js.three.Material;

class SidebarScene {
    public function new(editor:Editor) {
        var signals = editor.signals;
        var strings = editor.strings;

        var container = new UIPanel();
        container.setBorderTop('0');
        container.setPaddingTop('20px');

        // outliner

        var nodeStates = new WeakMap<Object3D,Bool>();

        function buildOption(object:Object3D, draggable:Bool):HTMLLIElement {
            var option = cast document.createElement('li');
            option.draggable = draggable;
            option.innerHTML = buildHTML(object);
            option.value = Std.string(object.id);

            // opener

            if (nodeStates.has(object)) {
                var state = nodeStates.get(object);

                var opener = cast document.createElement('span');
                opener.classList.add('opener');

                if (object.children.length > 0) {
                    if (state) {
                        opener.classList.add('open');
                    } else {
                        opener.classList.add('closed');
                    }
                }

                opener.addEventListener('click', function(ev:Event) {
                    nodeStates.set(object, !nodeStates.get(object)); // toggle
                    refreshUI();
                });

                option.insertBefore(opener, option.firstChild);
            }

            return option;
        }

        function getMaterialName(material:Material):String {
            if (material is Array<Material>) {
                var names = [];
                for (material in material) {
                    names.push(material.name);
                }
                return names.join(',');
            }
            return material.name;
        }

        function escapeHTML(html:String):String {
            return html
                .split('&').join('&amp;')
                .split('"').join('&quot;')
                .split('\'').join('&#39;')
                .split('<').join('&lt;')
                .split('>').join('&gt;');
        }

        function getObjectType(object:Object3D):String {
            if (object is Scene) return 'Scene';
            if (object is Camera) return 'Camera';
            if (object is Light) return 'Light';
            if (object is Mesh) return 'Mesh';
            if (object is Line) return 'Line';
            if (object is Points) return 'Points';

            return 'Object3D';
        }

        function buildHTML(object:Object3D):String {
            var html = '<span class="type ${getObjectType(object)}"></span> ${escapeHTML(object.name)}';

            if (object is Mesh) {
                var geometry = object.geometry as Geometry;
                var material = object.material as Material;

                html += ` <span class="type Geometry"></span> ${escapeHTML(geometry.name)}`;
                html += ` <span class="type Material"></span> ${escapeHTML(getMaterialName(material))}`;
            }

            html += getScript(object.uuid);

            return html;
        }

        function getScript(uuid:String):String {
            if (editor.scripts.exists(uuid)) {
                if (editor.scripts.get(uuid).length == 0) {
                    return '';
                }
                return ' <span class="type Script"></span>';
            }
            return '';
        }

        var ignoreObjectSelectedSignal = false;

        var outliner = new UIOutliner(editor);
        outliner.setId('outliner');
        outliner.onChange(function() {
            ignoreObjectSelectedSignal = true;

            editor.selectById(Std.parseInt(outliner.getValue()));

            ignoreObjectSelectedSignal = false;
        });
        outliner.onDblClick(function() {
            editor.focusById(Std.parseInt(outliner.getValue()));
        });
        container.add(outliner);
        container.add(new UIBreak());

        // background

        var backgroundRow = new UIRow();

        var backgroundType = new UISelect();
        backgroundType.setOptions([
            {'None': ''},
            {'Color': 'Color'},
            {'Texture': 'Texture'},
            {'Equirectangular': 'Equirect'}
        ]);
        backgroundType.setWidth('150px');
        backgroundType.onChange(function() {
            onBackgroundChanged();
            refreshBackgroundUI();
        });

        backgroundRow.add(new UIText(strings.getKey('sidebar/scene/background')).setClass('Label'));
        backgroundRow.add(backgroundType);

        var backgroundColor = new UIColor();
        backgroundColor.setValue('#000000');
        backgroundColor.setMarginLeft('8px');
        backgroundColor.onInput(onBackgroundChanged);
        backgroundRow.add(backgroundColor);

        var backgroundTexture = new UITexture(editor);
        backgroundTexture.setMarginLeft('8px');
        backgroundTexture.onChange(onBackgroundChanged);
        backgroundTexture.setDisplay('none');
        backgroundRow.add(backgroundTexture);

        var backgroundEquirectangularTexture = new UITexture(editor);
        backgroundEquirectangularTexture.setMarginLeft('8px');
        backgroundEquirectangularTexture.onChange(onBackgroundChanged);
        backgroundEquirectangularTexture.setDisplay('none');
        backgroundRow.add(backgroundEquirectangularTexture);

        container.add(backgroundRow);

        var backgroundEquirectRow = new UIRow();
        backgroundEquirectRow.setDisplay('none');
        backgroundEquirectRow.setMarginLeft('120px');

        var backgroundBlurriness = new UINumber(0);
        backgroundBlurriness.setWidth('40px');
        backgroundBlurriness.setRange(0, 1);
        backgroundBlurriness.onChange(onBackgroundChanged);
        backgroundEquirectRow.add(backgroundBlurriness);

        var backgroundIntensity = new UINumber(1);
        backgroundIntensity.setWidth('40px');
        backgroundIntensity.setRange(0, Std.PosInfinity);
        backgroundIntensity.onChange(onBackgroundChanged);
        backgroundEquirectRow.add(backgroundIntensity);

        var backgroundRotation = new UINumber(0);
        backgroundRotation.setWidth('40px');
        backgroundRotation.setRange(-180, 180);
        backgroundRotation.setStep(10);
        backgroundRotation.setUnit('°');
        backgroundRotation.onChange(onBackgroundChanged);
        backgroundEquirectRow.add(backgroundRotation);

        container.add(backgroundEquirectRow);

        function onBackgroundChanged() {
            signals.sceneBackgroundChanged.dispatch(
                backgroundType.getValue(),
                backgroundColor.getHexValue(),
                backgroundTexture.getValue(),
                backgroundEquirectangularTexture.getValue(),
                backgroundBlurriness.getValue(),
                backgroundIntensity.getValue(),
                backgroundRotation.getValue()
            );
        }

        function refreshBackgroundUI() {
            var type = backgroundType.getValue();

            backgroundType.setWidth(type == 'None' ? '150px' : '110px');
            backgroundColor.setDisplay(type == 'Color' ? '' : 'none');
            backgroundTexture.setDisplay(type == 'Texture' ? '' : 'none');
            backgroundEquirectangularTexture.setDisplay(type == 'Equirectangular' ? '' : 'none');
            backgroundEquirectRow.setDisplay(type == 'Equirectangular' ? '' : 'none');
        }

        // environment

        var environmentRow = new UIRow();

        var environmentType = new UISelect();
        environmentType.setOptions([
            {'None': ''},
            {'Background': 'Background'},
            {'Equirectangular': 'Equirect'},
            {'ModelViewer': 'ModelViewer'}
        ]);
        environmentType.setValue('None');
        environmentType.setWidth('150px');
        environmentType.onChange(function() {
            onEnvironmentChanged();
            refreshEnvironmentUI();
        });

        environmentRow.add(new UIText(strings.getKey('sidebar/scene/environment')).setClass('Label'));
        environmentRow.add(environmentType);

        var environmentEquirectangularTexture = new UITexture(editor);
        environmentEquirectangularTexture.setMarginLeft('8px');
        environmentEquirectangularTexture.onChange(onEnvironmentChanged);
        environmentEquirectangularTexture.setDisplay('none');
        environmentRow.add(environmentEquirectangularTexture);

        container.add(environmentRow);

        function onEnvironmentChanged() {
            signals.sceneEnvironmentChanged.dispatch(
                environmentType.getValue(),
                environmentEquirectangularTexture.getValue()
            );
        }

        function refreshEnvironmentUI() {
            var type = environmentType.getValue();

            environmentType.setWidth(type != 'Equirectangular' ? '150px' : '110px');
            environmentEquirectangularTexture.setDisplay(type == 'Equirectangular' ? '' : 'none');
        }

        // fog

        function onFogChanged() {
            signals.sceneFogChanged.dispatch(
                fogType.getValue(),
                fogColor.getHexValue(),
                fogNear.getValue(),
                fogFar.getValue(),
                fogDensity.getValue()
            );
        }

        function onFogSettingsChanged() {
            signals.sceneFogSettingsChanged.dispatch(
                fogType.getValue(),
                fogColor.getHexValue(),
                fogNear.getValue(),
                fogFar.getValue(),
                fogDensity.getValue()
            );
        }

        var fogTypeRow = new UIRow();
        var fogType = new UISelect();
        fogType.setOptions([
            {'None': ''},
            {'Fog': 'Linear'},
            {'FogExp2': 'Exponential'}
        ]);
        fogType.setWidth('150px');
        fogType.onChange(function() {
            onFogChanged();
            refreshFogUI();
        });

        fogTypeRow.add(new UIText(strings.getKey('sidebar/scene/fog')).setClass('Label'));
        fogTypeRow.add(fogType);

        container.add(fogTypeRow);

        // fog color

        var fogPropertiesRow = new UIRow();
        fogPropertiesRow.setDisplay('none');
        fogPropertiesRow.setMarginLeft('120px');
        container.add(fogPropertiesRow);

        var fogColor = new UIColor();
        fogColor.setValue('#aaaaaa');
        fogColor.onInput(onFogSettingsChanged);
        fogPropertiesRow.add(fgColor);

        // fog near

        var fogNear = new UINumber(0.1);
        fogNear.setWidth('40px');
        fogNear.setRange(0, Std.PosInfinity);
        fogNear.onChange(onFogSettingsChanged);
        fogPropertiesRow.add(fogNear);

        // fog far

        var fogFar = new UINumber(50);
        fogFar.setWidth('40px');
        fogFar.setRange(0, Std.PosInfinity);
        fogFar.onChange(onFogSettingsChanged);
        fogPropertiesRow.add(fogFar);

        // fog density

        var fogDensity = new UINumber(0.05);
        fogDensity.setWidth('40px');
        fogDensity.setRange(0, 0.1);
        fogDensity.setStep(0.001);
        fogDensity.setPrecision(3);
        fogDensity.onChange(onFogSettingsChanged);
        fogPropertiesRow.add(fogDensity);

        //

        function refreshUI() {
            var camera = editor.camera;
            var scene = editor.scene;

            var options = [];

            options.push(buildOption(camera, false));
            options.push(buildOption(scene, false));

            function addObjects(objects:Array<Object3D>, pad:Int) {
                for (object in objects) {
                    if (!nodeStates.has(object)) {
                        nodeStates.set(object, false);
                    }

                    var option = buildOption(object, true);
                    option.style.paddingLeft = (pad * 18) + 'px';
                    options.push(option);

                    if (nodeStates.get(object)) {
                        addObjects(object.children, pad + 1);
                    }
                }
            }

            addObjects(scene.children, 0);

            outliner.setOptions(options);

            if (editor.selected != null) {
                outliner.setValue(Std.string(editor.selected.id));
            }

            if (scene.background != null) {
                if (scene.background.isColor) {
                    backgroundType.setValue('Color');
                    backgroundColor.setHexValue(scene.background.getHex());
                } else if (scene.background.isTexture) {
                    if (scene.background.mapping == js.three.EquirectangularReflectionMapping) {
                        backgroundType.setValue('Equirectangular');
                        backgroundEquirectangularTexture.setValue(scene.background);
                        backgroundBlurriness.setValue(scene.backgroundBlurriness);
                        backgroundIntensity.setValue(scene.backgroundIntensity);
                    } else {
                        backgroundType.setValue('Texture');
                        backgroundTexture.setValue(scene.background);
                    }
                }
            } else {
                backgroundType.setValue('None');
                backgroundTexture.setValue(null);
                backgroundEquirectangularTexture.setValue(null);
            }

            if (scene.environment != null) {
                if (scene.background != null && scene.background.isTexture && scene.background.uuid == scene.environment.uuid) {
                    environmentType.setValue('Background');
                } else if (scene.environment.mapping == js.three.EquirectangularReflectionMapping) {
                    environmentType.setValue('Equirectangular');
                    environmentEquirectangularTexture.setValue(scene.environment);
                } else if (scene.environment.isRenderTargetTexture) {
                    environmentType.setValue('ModelViewer');
                }
            } else {
                environmentType.setValue('None');
                environmentEquirectangularTexture.setValue(null);
            }

            if (scene.fog != null) {
                fogColor.setHexValue(scene.fog.color.getHex());

                if (scene.fog.isFog) {
                    fogType.setValue('Fog');
                    fogNear.setValue(scene.fog.near);
                    fogFar.setValue(scene.fog.far);
                } else if (scene.fog.isFogExp2) {
                    fogType.setValue('FogExp2');
                    fogDensity.setValue(scene.fog.density);
                }
            } else {
                fogType.setValue('None');
            }

            refreshBackgroundUI();
            refreshEnvironmentUI();
            refreshFogUI();
        }

        function refreshFogUI() {
            var type = fogType.getValue();

            fogPropertiesRow.setDisplay(type == 'None' ? 'none' : '');
            fogNear.setDisplay(type == 'Fog' ? '' : 'none');
            fogFar.setDisplay(type == 'Fog' ? '' : 'none');
            fogDensity.setDisplay(type == 'FogExp2' ? '' : 'none');
        }

        refreshUI();

        // events

        signals.editorCleared.add(refreshUI);

        signals.sceneGraphChanged.add(refreshUI);

        signals.refreshSidebarEnvironment.add(refreshUI);

        signals.objectChanged.add(function(object:Object3D) {
            var options = outliner.options;

            for (option in options) {
                if (option.value == Std.string(object.id)) {
                    var openerElement = option.querySelector(':scope > .opener');

                    var openerHTML = openerElement ? openerElement.outerHTML : '';

                    option.innerHTML = openerHTML + buildHTML(object);

                    return;
                }
            }
        });

        signals.scriptAdded.add(function() {
            if (editor.selected != null) {
                signals.objectChanged.dispatch(editor.selected);
            }
        });

        signals.scriptRemoved.add(function() {
            if (editor.selected != null) {
                signals.objectChanged.dispatch(editor.selected);
            }
        });

        signals.objectSelected.add(function(object:Object3D) {
            if (ignoreObjectSelectedSignal) {
                return;
            }

            if (object != null && object.parent != null) {
                var needsRefresh = false;
                var parent = object.parent;

                while (parent != editor.scene) {
                    if (!nodeStates.get(parent)) {
                        nodeStates.set(parent, true);
                        needsRefresh = true;
                    }

                    parent = parent.parent;
                }

                if (needsRefresh) {
                    refreshUI();
                }

                outliner.setValue(Std.string(object.id));
            } else {
                outliner.setValue(null);
            }
        });

        signals.sceneBackgroundChanged.add(function() {
            if (environmentType.getValue() == 'Background') {
                onEnvironmentChanged();
                refreshEnvironmentUI();
            }
        });

        return container;
    }
}

class Editor {
    public var signals:EditorSignals;
    public var strings:StringMap<String>;
    public var camera:Camera;
    public var scene:Scene;
    public var selected:Object3D;
    public var scripts:StringMap<Array<String>>;
}

class EditorSignals {
    public var editorCleared:Signal;
    public var sceneGraphChanged:Signal;
    public var refreshSidebarEnvironment:Signal;
    public var objectChanged:Signal;
    public var scriptAdded:Signal;
    public var scriptRemoved:Signal;
    public var objectSelected:Signal;
    public var sceneBackgroundChanged:Signal;
    public var sceneEnvironmentChanged:Signal;
    public var sceneFogChanged:Signal;
    public var sceneFogSettingsChanged:Signal;
}

class Signal {
    public function dispatch(...args):Void;
class Signal {
    public function dispatch(...args):Void;
    public function add(listener:Dynamic):Void;
}

class UIElement {
    public function new();
    public function add(element:UIElement):Void;
    public function setDisplay(display:String):Void;
    public function setMarginLeft(margin:String):Void;
}

class UIPanel extends UIElement {
    public function setBorderTop(border:String):Void;
    public function setPaddingTop(padding:String):Void;
}

class UIRow extends UIElement {
    public function add(element:UIElement):Void;
}

class UISelect extends UIElement {
    public function setOptions(options:Dynamic):Void;
    public function setWidth(width:String):Void;
    public function getValue():String;
    public function setValue(value:String):Void;
    public function onChange(callback:Dynamic):Void;
}

class UIColor extends UIElement {
    public function setValue(value:String):Void;
    public function getHexValue():Int;
    public function setHexValue(hex:Int):Void;
    public function onInput(callback:Dynamic):Void;
}

class UITexture extends UIElement {
    public function new(editor:Editor);
    public function getValue():Material;
    public function setValue(material:Material):Void;
    public function onChange(callback:Dynamic):Void;
}

class UIText extends UIElement {
    public function new(text:String);
    public function setClass(className:String):Void;
}

class UIBreak extends UIElement {
}

class UIOutliner extends UIElement {
    public function new(editor:Editor);
    public function getId():String;
    public function setId(id:String):Void;
    public function getValue():String;
    public function setValue(value:String):Void;
    public function onChange(callback:Dynamic):Void;
    public function onDblClick(callback:Dynamic):Void;
    public function setOptions(options:Array<HTMLElement>):Void;
}

class UINumber extends UIElement {
    public function new(value:Float);
    public function setWidth(width:String):Void;
    public function setRange(min:Float, max:Float):Void;
    public function setStep(step:Float):Void;
    public function setNudge(nudge:Float):Void;
    public function setUnit(unit:String):Void;
    public function setPrecision(precision:Int):Void;
    public function getValue():Float;
    public function setValue(value:Float):Void;
    public function onChange(callback:Dynamic):Void;
}
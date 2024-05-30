package three.js.editor.js;

import three.js.*;

import ui.UIPanel;
import ui.UIBreak;
import ui.UIRow;
import ui.UIColor;
import ui.UISelect;
import ui.UIText;
import ui.UINumber;
import ui.three.UIOutliner;
import ui.three.UITexture;

class SidebarScene {

    private var editor:Editor;
    private var signals:Signals;
    private var strings:Strings;
    private var nodeStates:WeakMap<Object, Bool>;

    public function new(editor:Editor) {
        this.editor = editor;
        this.signals = editor.signals;
        this.strings = editor.strings;

        var container:UIPanel = new UIPanel();
        container.setBorderTop("0");
        container.setPaddingTop("20px");

        // outliner

        nodeStates = new WeakMap();

        function buildOption(object:Object, draggable:Bool):Dynamic {
            var option = document.createElement("div");
            option.draggable = draggable;
            option.innerHTML = buildHTML(object);
            option.value = object.id;

            // opener

            if (nodeStates.has(object)) {
                var state:Bool = nodeStates.get(object);

                var opener:HTMLElement = document.createElement("span");
                opener.classList.add("opener");

                if (object.children.length > 0) {
                    opener.classList.add(state ? "open" : "closed");
                }

                opener.addEventListener("click", function() {
                    nodeStates.set(object, !nodeStates.get(object)); // toggle
                    refreshUI();
                });

                option.insertBefore(opener, option.firstChild);
            }

            return option;
        }

        function getMaterialName(material:Material):String {
            if (Std.isOfType(material, Array<Material>)) {
                var array:Array<String> = [];
                for (i in 0...material.length) {
                    array.push(material[i].name);
                }
                return array.join(",");
            } else {
                return material.name;
            }
        }

        function escapeHTML(html:String):String {
            return html
                .replace(/&/g, "&amp;")
                .replace(/"/g, "&quot;")
                .replace(/'/g, "&#39;")
                .replace(/</g, "&lt;")
                .replace(/>/g, "&gt;");
        }

        function getObjectType(object:Object):String {
            if (object.isScene) return "Scene";
            if (object.isCamera) return "Camera";
            if (object.isLight) return "Light";
            if (object.isMesh) return "Mesh";
            if (object.isLine) return "Line";
            if (object.isPoints) return "Points";
            return "Object3D";
        }

        function buildHTML(object:Object):String {
            var html:String = "<span class=\"type " + getObjectType(object) + "\">" + escapeHTML(object.name);

            if (object.isMesh) {
                var geometry:Geometry = object.geometry;
                var material:Material = object.material;

                html += " <span class=\"type Geometry\">" + escapeHTML(geometry.name) + "</span>";
                html += " <span class=\"type Material\">" + escapeHTML(getMaterialName(material)) + "</span>";
            }

            html += getScript(object.uuid);

            return html;
        }

        function getScript(uuid:String):String {
            if (editor.scripts[uuid] == null) return "";
            if (editor.scripts[uuid].length == 0) return "";
            return " <span class=\"type Script\"></span>";
        }

        var ignoreObjectSelectedSignal:Bool = false;

        var outliner:UIOutliner = new UIOutliner(editor);
        outliner.setId("outliner");
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

        var backgroundRow:UIRow = new UIRow();

        var backgroundType:UISelect = new UISelect().setOptions({
            "None": "",
            "Color": "Color",
            "Texture": "Texture",
            "Equirectangular": "Equirect"
        }).setWidth("150px");
        backgroundType.onChange(function() {
            onBackgroundChanged();
            refreshBackgroundUI();
        });

        backgroundRow.add(new UIText(strings.getKey("sidebar/scene/background")).setClass("Label"));
        backgroundRow.add(backgroundType);

        var backgroundColor:UIColor = new UIColor().setValue("#000000").setMarginLeft("8px").onInput(onBackgroundChanged);
        backgroundRow.add(backgroundColor);

        var backgroundTexture:UITexture = new UITexture(editor).setMarginLeft("8px").onChange(onBackgroundChanged);
        backgroundTexture.setDisplay("none");
        backgroundRow.add(backgroundTexture);

        var backgroundEquirectangularTexture:UITexture = new UITexture(editor).setMarginLeft("8px").onChange(onBackgroundChanged);
        backgroundEquirectangularTexture.setDisplay("none");
        backgroundRow.add(backgroundEquirectangularTexture);

        container.add(backgroundRow);

        var backgroundEquirectRow:UIRow = new UIRow();
        backgroundEquirectRow.setDisplay("none");
        backgroundEquirectRow.setMarginLeft("120px");
        container.add(backgroundEquirectRow);

        var backgroundBlurriness:UINumber = new UINumber(0).setWidth("40px").setRange(0, 1).onChange(onBackgroundChanged);
        backgroundEquirectRow.add(backgroundBlurriness);

        var backgroundIntensity:UINumber = new UINumber(1).setWidth("40px").setRange(0, Math.POSITIVE_INFINITY).onChange(onBackgroundChanged);
        backgroundEquirectRow.add(backgroundIntensity);

        var backgroundRotation:UINumber = new UINumber(0).setWidth("40px").setRange(-180, 180).setStep(10).setNudge(0.1).setUnit("°").onChange(onBackgroundChanged);
        backgroundEquirectRow.add(backgroundRotation);

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
            var type:String = backgroundType.getValue();

            backgroundType.setWidth(type == "None" ? "150px" : "110px");
            backgroundColor.setDisplay(type == "Color" ? "" : "none");
            backgroundTexture.setDisplay(type == "Texture" ? "" : "none");
            backgroundEquirectangularTexture.setDisplay(type == "Equirectangular" ? "" : "none");
            backgroundEquirectRow.setDisplay(type == "Equirectangular" ? "" : "none");
        }

        // environment

        var environmentRow:UIRow = new UIRow();

        var environmentType:UISelect = new UISelect().setOptions({
            "None": "",
            "Background": "Background",
            "Equirectangular": "Equirect",
            "ModelViewer": "ModelViewer"
        }).setWidth("150px");
        environmentType.onChange(function() {
            onEnvironmentChanged();
            refreshEnvironmentUI();
        });

        environmentRow.add(new UIText(strings.getKey("sidebar/scene/environment")).setClass("Label"));
        environmentRow.add(environmentType);

        var environmentEquirectangularTexture:UITexture = new UITexture(editor).setMarginLeft("8px").onChange(onEnvironmentChanged);
        environmentEquirectangularTexture.setDisplay("none");
        environmentRow.add(environmentEquirectangularTexture);

        container.add(environmentRow);

        function onEnvironmentChanged() {
            signals.sceneEnvironmentChanged.dispatch(
                environmentType.getValue(),
                environmentEquirectangularTexture.getValue()
            );
        }

        function refreshEnvironmentUI() {
            var type:String = environmentType.getValue();

            environmentType.setWidth(type != "Equirectangular" ? "150px" : "110px");
            environmentEquirectangularTexture.setDisplay(type == "Equirectangular" ? "" : "none");
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

        var fogTypeRow:UIRow = new UIRow();
        var fogType:UISelect = new UISelect().setOptions({
            "None": "",
            "Fog": "Linear",
            "FogExp2": "Exponential"
        }).setWidth("150px");
        fogType.onChange(function() {
            onFogChanged();
            refreshFogUI();
        });

        fogTypeRow.add(new UIText(strings.getKey("sidebar/scene/fog")).setClass("Label"));
        fogTypeRow.add(fogType);

        container.add(fogTypeRow);

        // fog color

        var fogPropertiesRow:UIRow = new UIRow();
        fogPropertiesRow.setDisplay("none");
        fogPropertiesRow.setMarginLeft("120px");
        container.add(fogPropertiesRow);

        var fogColor:UIColor = new UIColor().setValue("#aaaaaa");
        fogColor.onInput(onFogSettingsChanged);
        fogPropertiesRow.add(fogColor);

        // fog near

        var fogNear:UINumber = new UINumber(0.1).setWidth("40px").setRange(0, Math.POSITIVE_INFINITY).onChange(onFogSettingsChanged);
        fogPropertiesRow.add(fogNear);

        // fog far

        var fogFar:UINumber = new UINumber(50).setWidth("40px").setRange(0, Math.POSITIVE_INFINITY).onChange(onFogSettingsChanged);
        fogPropertiesRow.add(fogFar);

        // fog density

        var fogDensity:UINumber = new UINumber(0.05).setWidth("40px").setRange(0, 0.1).setStep(0.001).setPrecision(3).onChange(onFogSettingsChanged);
        fogPropertiesRow.add(fogDensity);

        function refreshUI() {
            var camera:Camera = editor.camera;
            var scene:Scene = editor.scene;

            var options:Array<Dynamic> = [];

            options.push(buildOption(camera, false));
            options.push(buildOption(scene, false));

            (function addObjects(objects:Array<Object>, pad:Int) {
                for (i in 0...objects.length) {
                    var object:Object = objects[i];

                    if (!nodeStates.exists(object)) {
                        nodeStates.set(object, false);
                    }

                    var option:Dynamic = buildOption(object, true);
                    option.style.paddingLeft = (pad * 18) + "px";
                    options.push(option);

                    if (nodeStates.get(object) == true) {
                        addObjects(object.children, pad + 1);
                    }
                }
            })(scene.children, 0);

            outliner.setOptions(options);

            if (editor.selected != null) {
                outliner.setValue(editor.selected.id);
            }

            if (scene.background != null) {
                if (scene.background.isColor) {
                    backgroundType.setValue("Color");
                    backgroundColor.setHexValue(scene.background.getHex());
                } else if (scene.background.isTexture) {
                    if (scene.background.mapping == THREE.EquirectangularReflectionMapping) {
                        backgroundType.setValue("Equirectangular");
                        backgroundEquirectangularTexture.setValue(scene.background);
                        backgroundBlurriness.setValue(scene.backgroundBlurriness);
                        backgroundIntensity.setValue(scene.backgroundIntensity);
                    } else {
                        backgroundType.setValue("Texture");
                        backgroundTexture.setValue(scene.background);
                    }
                }
            } else {
                backgroundType.setValue("None");
                backgroundTexture.setValue(null);
                backgroundEquirectangularTexture.setValue(null);
            }

            if (scene.environment != null) {
                if (scene.background != null && scene.background.isTexture && scene.background.uuid == scene.environment.uuid) {
                    environmentType.setValue("Background");
                } else if (scene.environment.mapping == THREE.EquirectangularReflectionMapping) {
                    environmentType.setValue("Equirectangular");
                    environmentEquirectangularTexture.setValue(scene.environment);
                } else if (scene.environment.isRenderTargetTexture) {
                    environmentType.setValue("ModelViewer");
                }
            } else {
                environmentType.setValue("None");
                environmentEquirectangularTexture.setValue(null);
            }

            if (scene.fog != null) {
                fogColor.setHexValue(scene.fog.color.getHex());
                if (scene.fog.isFog) {
                    fogType.setValue("Fog");
                    fogNear.setValue(scene.fog.near);
                    fogFar.setValue(scene.fog.far);
                } else if (scene.fog.isFogExp2) {
                    fogType.setValue("FogExp2");
                    fogDensity.setValue(scene.fog.density);
                }
            } else {
                fogType.setValue("None");
            }

            refreshBackgroundUI();
            refreshEnvironmentUI();
            refreshFogUI();
        }

        function refreshFogUI() {
            var type:String = fogType.getValue();

            fogPropertiesRow.setDisplay(type == "None" ? "none" : "");
            fogNear.setDisplay(type == "Fog" ? "" : "none");
            fogFar.setDisplay(type == "Fog" ? "" : "none");
            fogDensity.setDisplay(type == "FogExp2" ? "" : "none");
        }

        refreshUI();

        signals.editorCleared.add(refreshUI);
        signals.sceneGraphChanged.add(refreshUI);
        signals.refreshSidebarEnvironment.add(refreshUI);

        signals.objectChanged.add(function(object:Object) {
            var options:Array<Dynamic> = outliner.options;

            for (i in 0...options.length) {
                var option:Dynamic = options[i];

                if (option.value == object.id) {
                    var openerElement:HTMLElement = option.querySelector(":scope > .opener");
                    var openerHTML:String = openerElement ? openerElement.outerHTML : "";

                    option.innerHTML = openerHTML + buildHTML(object);

                    return;
                }
            }
        });

        signals.scriptAdded.add(function() {
            if (editor.selected != null) signals.objectChanged.dispatch(editor.selected);
        });

        signals.scriptRemoved.add(function() {
            if (editor.selected != null) signals.objectChanged.dispatch(editor.selected);
        });

        signals.objectSelected.add(function(object:Object) {
            if (ignoreObjectSelectedSignal) return;

            if (object != null && object.parent != null) {
                var needsRefresh:Bool = false;
                var parent:Object = object.parent;

                while (parent != editor.scene) {
                    if (!nodeStates.exists(parent)) {
                        nodeStates.set(parent, true);
                        needsRefresh = true;
                    }

                    parent = parent.parent;
                }

                if (needsRefresh) refreshUI();

                outliner.setValue(object.id);
            } else {
                outliner.setValue(null);
            }
        });

        signals.sceneBackgroundChanged.add(function() {
            if (environmentType.getValue() == "Background") {
                onEnvironmentChanged();
                refreshEnvironmentUI();
            }
        });

        return container;
    }
}
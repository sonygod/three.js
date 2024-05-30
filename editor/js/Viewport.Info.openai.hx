package three.js.editor.js;

import ui.UIService;
import ui.UIText;
import ui.UIPanel;
import ui.UIBreak;

class ViewportInfo {
    public var container:UIPanel;

    public function new(editor:Editor) {
        var strings:Strings = editor.strings;
        var signals:Signals = editor.signals;

        container = new UIPanel();
        container.id = 'info';
        container.position = 'absolute';
        container.left = '10px';
        container.bottom = '20px';
        container.fontSize = '12px';
        container.color = '#fff';
        container.textTransform = 'lowercase';

        var objectsText = new UIText('0');
        objectsText.textAlign = 'right';
        objectsText.width = '60px';
        objectsText.marginRight = '6px';

        var verticesText = new UIText('0');
        verticesText.textAlign = 'right';
        verticesText.width = '60px';
        verticesText.marginRight = '6px';

        var trianglesText = new UIText('0');
        trianglesText.textAlign = 'right';
        trianglesText.width = '60px';
        trianglesText.marginRight = '6px';

        var frametimeText = new UIText('0');
        frametimeText.textAlign = 'right';
        frametimeText.width = '60px';
        frametimeText.marginRight = '6px';

        var objectsUnitText = new UIText(strings.getKey('viewport/info/objects'));
        var verticesUnitText = new UIText(strings.getKey('viewport/info/vertices'));
        var trianglesUnitText = new UIText(strings.getKey('viewport/info/triangles'));

        container.addChild(objectsText);
        container.addChild(objectsUnitText);
        container.addChild(new UIBreak());

        container.addChild(verticesText);
        container.addChild(verticesUnitText);
        container.addChild(new UIBreak());

        container.addChild(trianglesText);
        container.addChild(trianglesUnitText);
        container.addChild(new UIBreak());

        container.addChild(frametimeText);
        container.addChild(new UIText(strings.getKey('viewport/info/rendertime')));
        container.addChild(new UIBreak());

        signals.objectAdded.add(update);
        signals.objectRemoved.add(update);
        signals.geometryChanged.add(update);
        signals.sceneRendered.add(updateFrametime);
    }

    private function update() {
        var scene:Scene = editor.scene;
        var objects = 0;
        var vertices = 0;
        var triangles = 0;

        for (i in 0...scene.children.length) {
            var object:Object3D = scene.children[i];
            object.traverseVisible(function(object:Object3D) {
                objects++;

                if (object.isMesh || object.isPoints) {
                    var geometry:Geometry = object.geometry;
                    vertices += geometry.attributes.position.count;

                    if (object.isMesh) {
                        if (geometry.index != null) {
                            triangles += geometry.index.count / 3;
                        } else {
                            triangles += geometry.attributes.position.count / 3;
                        }
                    }
                }
            });
        }

        objectsText.setValue(editor.utils.formatNumber(objects));
        verticesText.setValue(editor.utils.formatNumber(vertices));
        trianglesText.setValue(editor.utils.formatNumber(triangles));

        var pluralRules:IntlPluralRules = new IntlPluralRules(editor.config.getKey('language'));
        var objectsStringKey:String = (pluralRules.select(objects) == 'one') ? 'viewport/info/oneObject' : 'viewport/info/objects';
        objectsUnitText.setValue(strings.getKey(objectsStringKey));

        var verticesStringKey:String = (pluralRules.select(vertices) == 'one') ? 'viewport/info/oneVertex' : 'viewport/info/vertices';
        verticesUnitText.setValue(strings.getKey(verticesStringKey));

        var trianglesStringKey:String = (pluralRules.select(triangles) == 'one') ? 'viewport/info/oneTriangle' : 'viewport/info/triangles';
        trianglesUnitText.setValue(strings.getKey(trianglesStringKey));
    }

    private function updateFrametime(frametime:Float) {
        frametimeText.setValue(Std.string(frametime));
    }
}
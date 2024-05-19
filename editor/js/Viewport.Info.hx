package three.js.editor.js;

import ui.UIPanel;
import ui.UIText;
import ui.UIBreak;

class ViewportInfo {
    private var editor:Dynamic;
    private var signals:Dynamic;
    private var strings:Dynamic;

    public function new(editor:Dynamic) {
        this.editor = editor;
        this.signals = editor.signals;
        this.strings = editor.strings;

        var container = new UIPanel();
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

        container.add(objectsText);
        container.add(objectsUnitText);
        container.add(new UIBreak());

        container.add(verticesText);
        container.add(verticesUnitText);
        container.add(new UIBreak());

        container.add(trianglesText);
        container.add(trianglesUnitText);
        container.add(new UIBreak());

        container.add(frametimeText);
        container.add(new UIText(strings.getKey('viewport/info/rendertime')));
        container.add(new UIBreak());

        signals.objectAdded.add(update);
        signals.objectRemoved.add(update);
        signals.geometryChanged.add(update);
        signals.sceneRendered.add(updateFrametime);
    }

    private function update():Void {
        var scene = editor.scene;

        var objects:Int = 0;
        var vertices:Int = 0;
        var triangles:Int = 0;

        for (i in 0...scene.children.length) {
            var object = scene.children[i];
            object.traverseVisible(function(object:Dynamic) {
                objects++;

                if (object.isMesh || object.isPoints) {
                    var geometry = object.geometry;
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

        var pluralRules = new Intl.PluralRules(editor.config.getKey('language'));

        var objectsStringKey:String = (pluralRules.select(objects) == 'one') ? 'viewport/info/oneObject' : 'viewport/info/objects';
        objectsUnitText.setValue(strings.getKey(objectsStringKey));

        var verticesStringKey:String = (pluralRules.select(vertices) == 'one') ? 'viewport/info/oneVertex' : 'viewport/info/vertices';
        verticesUnitText.setValue(strings.getKey(verticesStringKey));

        var trianglesStringKey:String = (pluralRules.select(triangles) == 'one') ? 'viewport/info/oneTriangle' : 'viewport/info/triangles';
        trianglesUnitText.setValue(strings.getKey(trianglesStringKey));
    }

    private function updateFrametime(frametime:Float):Void {
        frametimeText.setValue(Std.string(frametime.toFixed(2)));
    }
}
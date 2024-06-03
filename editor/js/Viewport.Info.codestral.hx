import ui.UIPanel;
import ui.UIBreak;
import ui.UIText;

class ViewportInfo {

    public function new(editor:Editor) {

        var signals:Signals = editor.signals;
        var strings:Strings = editor.strings;

        var container:UIPanel = new UIPanel();
        container.setId('info');
        container.setPosition('absolute');
        container.setLeft('10px');
        container.setBottom('20px');
        container.setFontSize('12px');
        container.setColor('#fff');
        container.setTextTransform('lowercase');

        var objectsText:UIText = new UIText('0').setTextAlign('right').setWidth('60px').setMarginRight('6px');
        var verticesText:UIText = new UIText('0').setTextAlign('right').setWidth('60px').setMarginRight('6px');
        var trianglesText:UIText = new UIText('0').setTextAlign('right').setWidth('60px').setMarginRight('6px');
        var frametimeText:UIText = new UIText('0').setTextAlign('right').setWidth('60px').setMarginRight('6px');

        var objectsUnitText:UIText = new UIText(strings.getKey('viewport/info/objects'));
        var verticesUnitText:UIText = new UIText(strings.getKey('viewport/info/vertices'));
        var trianglesUnitText:UIText = new UIText(strings.getKey('viewport/info/triangles'));

        container.add(objectsText, objectsUnitText, new UIBreak());
        container.add(verticesText, verticesUnitText, new UIBreak());
        container.add(trianglesText, trianglesUnitText, new UIBreak());
        container.add(frametimeText, new UIText(strings.getKey('viewport/info/rendertime')), new UIBreak());

        signals.objectAdded.add(() -> update());
        signals.objectRemoved.add(() -> update());
        signals.geometryChanged.add(() -> update());
        signals.sceneRendered.add(updateFrametime);

        function update():Void {

            var scene = editor.scene;

            var objects:Int = 0;
            var vertices:Int = 0;
            var triangles:Int = 0;

            for (var i:Int = 0; i < scene.children.length; i ++) {

                var object = scene.children[i];

                object.traverseVisible(function (object) {

                    objects ++;

                    if (Std.is(object, Mesh) || Std.is(object, Points)) {

                        var geometry = object.geometry;

                        vertices += geometry.attributes.position.count;

                        if (Std.is(object, Mesh)) {

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

            // Haxe does not have a direct equivalent to JavaScript's Intl.PluralRules
            // You might need to use a library or custom implementation
            // The following lines are just placeholders

            // var pluralRules = new Intl.PluralRules(editor.config.getKey('language'));

            // var objectsStringKey = (pluralRules.select(objects) == 'one') ? 'viewport/info/oneObject' : 'viewport/info/objects';
            // objectsUnitText.setValue(strings.getKey(objectsStringKey));

            // var verticesStringKey = (pluralRules.select(vertices) == 'one') ? 'viewport/info/oneVertex' : 'viewport/info/vertices';
            // verticesUnitText.setValue(strings.getKey(verticesStringKey));

            // var trianglesStringKey = (pluralRules.select(triangles) == 'one') ? 'viewport/info/oneTriangle' : 'viewport/info/triangles';
            // trianglesUnitText.setValue(strings.getKey(trianglesStringKey));

        }

        function updateFrametime(frametime:Float):Void {

            frametimeText.setValue(frametime.toString());

        }

        return container;

    }

}
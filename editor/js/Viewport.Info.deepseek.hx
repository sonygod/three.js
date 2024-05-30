import three.js.editor.js.libs.ui.UIPanel;
import three.js.editor.js.libs.ui.UIBreak;
import three.js.editor.js.libs.ui.UIText;

class ViewportInfo {

    public function new(editor:Dynamic) {

        var signals = editor.signals;
        var strings = editor.strings;

        var container = new UIPanel();
        container.setId('info');
        container.setPosition('absolute');
        container.setLeft('10px');
        container.setBottom('20px');
        container.setFontSize('12px');
        container.setColor('#fff');
        container.setTextTransform('lowercase');

        var objectsText = new UIText('0').setTextAlign('right').setWidth('60px').setMarginRight('6px');
        var verticesText = new UIText('0').setTextAlign('right').setWidth('60px').setMarginRight('6px');
        var trianglesText = new UIText('0').setTextAlign('right').setWidth('60px').setMarginRight('6px');
        var frametimeText = new UIText('0').setTextAlign('right').setWidth('60px').setMarginRight('6px');

        var objectsUnitText = new UIText(strings.getKey('viewport/info/objects'));
        var verticesUnitText = new UIText(strings.getKey('viewport/info/vertices'));
        var trianglesUnitText = new UIText(strings.getKey('viewport/info/triangles'));

        container.add(objectsText, objectsUnitText, new UIBreak());
        container.add(verticesText, verticesUnitText, new UIBreak());
        container.add(trianglesText, trianglesUnitText, new UIBreak());
        container.add(frametimeText, new UIText(strings.getKey('viewport/info/rendertime')), new UIBreak());

        signals.objectAdded.add(update);
        signals.objectRemoved.add(update);
        signals.geometryChanged.add(update);
        signals.sceneRendered.add(updateFrametime);

        function update() {

            var scene = editor.scene;

            var objects = 0, vertices = 0, triangles = 0;

            for (i in 0...scene.children.length) {

                var object = scene.children[i];

                object.traverseVisible(function (object) {

                    objects ++;

                    if (object.isMesh || object.isPoints) {

                        var geometry = object.geometry;

                        vertices += geometry.attributes.position.count;

                        if (object.isMesh) {

                            if (geometry.index !== null) {

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

            var objectsStringKey = (pluralRules.select(objects) === 'one') ? 'viewport/info/oneObject' : 'viewport/info/objects';
            objectsUnitText.setValue(strings.getKey(objectsStringKey));

            var verticesStringKey = (pluralRules.select(vertices) === 'one') ? 'viewport/info/oneVertex' : 'viewport/info/vertices';
            verticesUnitText.setValue(strings.getKey(verticesStringKey));

            var trianglesStringKey = (pluralRules.select(triangles) === 'one') ? 'viewport/info/oneTriangle' : 'viewport/info/triangles';
            trianglesUnitText.setValue(strings.getKey(trianglesStringKey));

        }

        function updateFrametime(frametime) {

            frametimeText.setValue(Number(frametime).toFixed(2));

        }

        return container;

    }

}
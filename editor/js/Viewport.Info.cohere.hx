import js.Browser.window;

class ViewportInfo {
    public function new(editor:Editor) {
        var signals = editor.signals;
        var strings = editor.strings;
        var container = UIPanel_Impl::create();
        container.setId("info");
        container.setPosition("absolute");
        container.setLeft("10px");
        container.setBottom("20px");
        container.setFontSize("12px");
        container.setColor("#fff");
        container.setTextTransform("lowercase");
        var objectsText = UIText_Impl::create();
        objectsText.setTextAlign("right");
        objectsText.setWidth("60px");
        objectsText.setMarginRight("6px");
        var verticesText = UIText_Impl::create();
        verticesText.setTextAlign("right");
        verticesText.setWidth("60px");
        verticesText.setMarginRight("6px");
        var trianglesText = UIText_Impl::create();
        trianglesText.setTextAlign("right");
        trianglesText.setWidth("60px");
        trianglesText.setMarginRight("6px");
        var frametimeText = UIText_Impl::create();
        frametimeText.setTextAlign("right");
        frametimeText.setWidth("60px");
        frametimeText.setMarginRight("6px");
        var objectsUnitText = UIText_Impl::create();
        objectsUnitText.setValue(strings.getKey("viewport/info/objects"));
        var verticesUnitText = UIText_Impl::create();
        verticesUnitText.setValue(strings.getKey("viewport/info/vertices"));
        var trianglesUnitText = UIText_Impl::create();
        trianglesUnitText.setValue(strings.getKey("viewport/info/triangles"));
        container.add(objectsText);
        container.add(objectsUnitText);
        container.add(UIBreak_Impl::create());
        container.add(verticesText);
        container.add(verticesUnitText);
        container.add(UIBreak_Impl::create());
        container.add(trianglesText);
        container.add(trianglesUnitText);
        container.add(UIBreak_Impl::create());
        container.add(frametimeText);
        var frametimeUnitText = UIText_Impl::create();
        frametimeUnitText.setValue(strings.getKey("viewport/info/rendertime"));
        container.add(frametimeUnitText);
        container.add(UIBreak_Impl::create());
        signals.objectAdded.add(update);
        signals.objectRemoved.add(update);
        signals.geometryChanged.add(update);
        signals.sceneRendered.add($bind(updateFrametime, frametimeText));
        function update() {
            var scene = editor.scene;
            var objects:Int = 0;
            var vertices:Int = 0;
            var triangles:Int = 0;
            var i:Int;
            for (i = 0; i < scene.children.length; i++) {
                var object = scene.children[i] as Object3D;
                object.traverseVisible(function (object:Object3D) {
                    objects++;
                    if (Std.is(object, Mesh) || Std.is(object, Points)) {
                        var geometry = object.geometry as Geometry;
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
            objectsText.setValue(Std.string(editor.utils.formatNumber(objects)));
            verticesText.setValue(Std.string(editor.utils.formatNumber(vertices)));
            trianglesText.setValue(Std.string(editor.utils.formatNumber(triangles)));
            var pluralRules = Intl.PluralRules.create(window.navigator.language);
            var objectsStringKey = if (pluralRules.select(objects) == "one") "viewport/info/oneObject" else "viewport/info/objects";
            objectsUnitText.setValue(strings.getKey(objectsStringKey));
            var verticesStringKey = if (pluralRules.select(vertices) == "one") "viewport/info/oneVertex" else "viewport/info/vertices";
            verticesUnitText.setValue(strings.getKey(verticesStringKey));
            var trianglesStringKey = if (pluralRules.select(triangles) == "one") "viewport/info/oneTriangle" else "viewport/info/triangles";
            trianglesUnitText.setValue(strings.getKey(trianglesStringKey));
        }
        function updateFrametime(frametime:Float) {
            frametimeText.setValue(Std.string(frametime.toFixed(2)));
        }
    }
}
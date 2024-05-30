import js.Browser.window;
import js.html.Text;
import js.html.Div;
import js.html.Span;
import js.html.Br;
import js.html.Input;

class SidebarGeometryBufferGeometry {
    public function new(editor:Editor) {
        var strings = editor.strings;
        var signals = editor.signals;
        var container = window.document.createElement('div');

        function update(object:Dynamic) {
            if (object == null) return; // objectSelected.dispatch( null )
            if (object == undefined) return;

            var geometry = object.geometry;

            if (geometry != null) {
                container.innerHTML = '';
                container.style.display = 'block';

                // attributes

                var attributesRow = window.document.createElement('div');

                var textAttributes = Text('' + strings.getKey('sidebar/geometry/buffer_geometry/attributes'));
                attributesRow.appendChild(textAttributes);

                var containerAttributes = Span();
                containerAttributes.style.display = 'inline-block';
                containerAttributes.style.verticalAlign = 'middle';
                containerAttributes.style.width = '160px';
                attributesRow.appendChild(containerAttributes);

                var index = geometry.index;

                if (index != null) {
                    containerAttributes.appendChild(Text('' + strings.getKey('sidebar/geometry/buffer_geometry/index')));
                    containerAttributes.appendChild(Text('' + editor.utils.formatNumber(index.count)));
                    containerAttributes.appendChild(Br());
                }

                var attributes = geometry.attributes;

                for (name in attributes) {
                    var attribute = attributes[name];

                    containerAttributes.appendChild(Text('' + name));
                    containerAttributes.appendChild(Text('' + editor.utils.formatNumber(attribute.count) + ' (' + attribute.itemSize + ')'));
                    containerAttributes.appendChild(Br());
                }

                container.appendChild(attributesRow);

                // morph targets

                var morphAttributes = geometry.morphAttributes;
                var hasMorphTargets = morphAttributes.keys().length > 0;

                if (hasMorphTargets) {
                    // morph attributes

                    var rowMorphAttributes = window.document.createElement('div');

                    var textMorphAttributes = Text('' + strings.getKey('sidebar/geometry/buffer_geometry/morphAttributes'));
                    rowMorphAttributes.appendChild(textMorphAttributes);

                    var containerMorphAttributes = Span();
                    containerMorphAttributes.style.display = 'inline-block';
                    containerMorphAttributes.style.verticalAlign = 'middle';
                    containerMorphAttributes.style.width = '160px';
                    rowMorphAttributes.appendChild(containerMorphAttributes);

                    for (name in morphAttributes) {
                        var morphTargets = morphAttributes[name];

                        containerMorphAttributes.appendChild(Text('' + name));
                        containerMorphAttributes.appendChild(Text('' + editor.utils.formatNumber(morphTargets.length)));
                        containerMorphAttributes.appendChild(Br());
                    }

                    container.appendChild(rowMorphAttributes);

                    // morph relative

                    var rowMorphRelative = window.document.createElement('div');

                    var textMorphRelative = Text('' + strings.getKey('sidebar/geometry/buffer_geometry/morphRelative'));
                    rowMorphRelative.appendChild(textMorphRelative);

                    var checkboxMorphRelative = Input('checkbox');
                    checkboxMorphRelative.checked = geometry.morphTargetsRelative;
                    checkboxMorphRelative.disabled = true;
                    rowMorphRelative.appendChild(checkboxMorphRelative);

                    container.appendChild(rowMorphRelative);
                }

            } else {
                container.style.display = 'none';
            }
        }

        signals.objectSelected.add($bind(update));
        signals.geometryChanged.add($bind(update));

        return container;
    }
}

class Editor {
    public var strings:Dynamic;
    public var signals:Dynamic;
    public var utils:Dynamic;
}
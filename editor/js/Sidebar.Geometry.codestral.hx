import js.Browser;
import js.html.HtmlElement;
import js.html.InputElement;
import js.html.ButtonElement;
import js.html.Text;
import js.html.document;
import three.THREE;
import ui.UIPanel;
import ui.UIRow;
import ui.UIText;
import ui.UIInput;
import ui.UIButton;
import ui.UISpan;
import SetGeometryValueCommand;
import SidebarGeometryBufferGeometry;
import SidebarGeometryModifiers;
import VertexNormalsHelper;

class SidebarGeometry {
    var strings:Dynamic;
    var signals:Dynamic;
    var container:UIPanel;
    var currentGeometryType:String;

    public function new(editor:Dynamic) {
        this.strings = editor.strings;
        this.signals = editor.signals;

        this.container = new UIPanel();
        this.container.setBorderTop('0');
        this.container.setDisplay('none');
        this.container.setPaddingTop('20px');

        this.currentGeometryType = null;

        var geometryTypeRow = new UIRow();
        var geometryType = new UIText();

        geometryTypeRow.add(new UIText(this.strings.getKey('sidebar/geometry/type')).setClass('Label'));
        geometryTypeRow.add(geometryType);

        this.container.add(geometryTypeRow);

        var geometryUUIDRow = new UIRow();
        var geometryUUID = new UIInput().setWidth('102px').setFontSize('12px').setDisabled(true);
        var geometryUUIDRenew = new UIButton(this.strings.getKey('sidebar/geometry/new')).setMarginLeft('7px');
        geometryUUIDRenew.onClick(function(_) {
            geometryUUID.setValue(THREE.MathUtils.generateUUID());
            editor.execute(new SetGeometryValueCommand(editor, editor.selected, 'uuid', geometryUUID.getValue()));
        });

        geometryUUIDRow.add(new UIText(this.strings.getKey('sidebar/geometry/uuid')).setClass('Label'));
        geometryUUIDRow.add(geometryUUID);
        geometryUUIDRow.add(geometryUUIDRenew);

        this.container.add(geometryUUIDRow);

        var geometryNameRow = new UIRow();
        var geometryName = new UIInput().setWidth('150px').setFontSize('12px');
        geometryName.onChange(function(_) {
            editor.execute(new SetGeometryValueCommand(editor, editor.selected, 'name', geometryName.getValue()));
        });

        geometryNameRow.add(new UIText(this.strings.getKey('sidebar/geometry/name')).setClass('Label'));
        geometryNameRow.add(geometryName);

        this.container.add(geometryNameRow);

        var parameters = new UISpan();
        this.container.add(parameters);

        this.container.add(new SidebarGeometryBufferGeometry(editor));

        var geometryBoundingBox = new UIText().setFontSize('12px');

        var geometryBoundingBoxRow = new UIRow();
        geometryBoundingBoxRow.add(new UIText(this.strings.getKey('sidebar/geometry/bounds')).setClass('Label'));
        geometryBoundingBoxRow.add(geometryBoundingBox);
        this.container.add(geometryBoundingBoxRow);

        var helpersRow = new UIRow().setMarginLeft('120px');
        this.container.add(helpersRow);

        var vertexNormalsButton = new UIButton(this.strings.getKey('sidebar/geometry/show_vertex_normals'));
        vertexNormalsButton.onClick(function(_) {
            var object = editor.selected;

            if (Std.is(editor.helpers, object.id) == null) {
                editor.addHelper(object, new VertexNormalsHelper(object));
            } else {
                editor.removeHelper(object);
            }

            signals.sceneGraphChanged.dispatch();
        });
        helpersRow.add(vertexNormalsButton);

        var exportJson = new UIButton(this.strings.getKey('sidebar/geometry/export'));
        exportJson.setMarginLeft('120px');
        exportJson.onClick(function(_) {
            var object = editor.selected;
            var geometry = object.geometry;

            var output = geometry.toJSON();

            try {
                output = JSON.stringify(output, null, '\t');
                output = output.replace(new EReg('[\n\t]+([\d\.e\-\[\]]+)', 'g'), '$1');
            } catch (e:Dynamic) {
                output = JSON.stringify(output);
            }

            editor.utils.save(new js.html.Blob([output]), geometryName.getValue() != '' ? geometryName.getValue() : 'geometry' + '.json');
        });
        this.container.add(exportJson);

        this.signals.objectSelected.add(function(_) {
            currentGeometryType = null;
            build();
        });

        this.signals.geometryChanged.add(build);

        function build() {
            var object = editor.selected;

            if (object != null && object.geometry != null) {
                var geometry = object.geometry;

                container.setDisplay('block');

                geometryType.setValue(geometry.type);

                geometryUUID.setValue(geometry.uuid);
                geometryName.setValue(geometry.name);

                if (currentGeometryType != geometry.type) {
                    parameters.clear();

                    if (geometry.type == 'BufferGeometry') {
                        parameters.add(new SidebarGeometryModifiers(editor, object));
                    } else {
                        // Note: This part requires dynamic import which is not supported in Haxe.
                        // You may need to refactor your code to avoid dynamic import.
                    }

                    currentGeometryType = geometry.type;
                }

                if (geometry.boundingBox == null) geometry.computeBoundingBox();

                var boundingBox = geometry.boundingBox;
                var x = Math.floor((boundingBox.max.x - boundingBox.min.x) * 1000) / 1000;
                var y = Math.floor((boundingBox.max.y - boundingBox.min.y) * 1000) / 1000;
                var z = Math.floor((boundingBox.max.z - boundingBox.min.z) * 1000) / 1000;

                geometryBoundingBox.setInnerHTML(x + '<br/>' + y + '<br/>' + z);

                helpersRow.setDisplay(geometry.hasAttribute('normal') ? '' : 'none');
            } else {
                container.setDisplay('none');
            }
        }
    }
}
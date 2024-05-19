package three.js.editor.js;

import js.three.*;

import ui.UIPanel;
import ui.UIRow;
import ui.UIText;
import ui.UIInput;
import ui.UIButton;
import ui.UISpan;

import commands.SetGeometryValueCommand;

import SidebarGeometryBufferGeometry;
import SidebarGeometryModifiers;

import three.addons.helpers.VertexNormalsHelper;

class SidebarGeometry {
    public var container:UIPanel;
    public var strings:Dynamic;
    public var signals:Dynamic;
    public var editor:Dynamic;
    public var currentGeometryType:String;

    public function new(editor:Dynamic) {
        strings = editor.strings;
        signals = editor.signals;
        container = new UIPanel();
        container.setBorderTop('0');
        container.setDisplay('none');
        container.setPaddingTop('20px');

        // type
        var geometryTypeRow:UIRow = new UIRow();
        var geometryType:UIText = new UIText();
        geometryTypeRow.add(new UIText(strings.getKey('sidebar/geometry/type')).setClass('Label'));
        geometryTypeRow.add(geometryType);
        container.add(geometryTypeRow);

        // uuid
        var geometryUUIDRow:UIRow = new UIRow();
        var geometryUUID:UIInput = new UIInput().setWidth('102px').setFontSize('12px').setDisabled(true);
        var geometryUUIDRenew:UIButton = new UIButton(strings.getKey('sidebar/geometry/new')).setMarginLeft('7px');
        geometryUUIDRenew.onClick(function() {
            geometryUUID.setValue(THREE.MathUtils.generateUUID());
            editor.execute(new SetGeometryValueCommand(editor, editor.selected, 'uuid', geometryUUID.getValue()));
        });
        geometryUUIDRow.add(new UIText(strings.getKey('sidebar/geometry/uuid')).setClass('Label'));
        geometryUUIDRow.add(geometryUUID);
        geometryUUIDRow.add(geometryUUIDRenew);
        container.add(geometryUUIDRow);

        // name
        var geometryNameRow:UIRow = new UIRow();
        var geometryName:UIInput = new UIInput().setWidth('150px').setFontSize('12px').onChange(function() {
            editor.execute(new SetGeometryValueCommand(editor, editor.selected, 'name', geometryName.getValue()));
        });
        geometryNameRow.add(new UIText(strings.getKey('sidebar/geometry/name')).setClass('Label'));
        geometryNameRow.add(geometryName);
        container.add(geometryNameRow);

        // parameters
        var parameters:UISpan = new UISpan();
        container.add(parameters);

        // buffergeometry
        container.add(new SidebarGeometryBufferGeometry(editor));

        // Size
        var geometryBoundingBox:UIText = new UIText().setFontSize('12px');
        var geometryBoundingBoxRow:UIRow = new UIRow();
        geometryBoundingBoxRow.add(new UIText(strings.getKey('sidebar/geometry/bounds')).setClass('Label'));
        geometryBoundingBoxRow.add(geometryBoundingBox);
        container.add(geometryBoundingBoxRow);

        // Helpers
        var helpersRow:UIRow = new UIRow().setMarginLeft('120px');
        container.add(helpersRow);

        var vertexNormalsButton:UIButton = new UIButton(strings.getKey('sidebar/geometry/show_vertex_normals'));
        vertexNormalsButton.onClick(function() {
            var object:Dynamic = editor.selected;
            if (editor.helpers[object.id] === undefined) {
                editor.addHelper(object, new VertexNormalsHelper(object));
            } else {
                editor.removeHelper(object);
            }
            signals.sceneGraphChanged.dispatch();
        });
        helpersRow.add(vertexNormalsButton);

        // Export JSON
        var exportJson:UIButton = new UIButton(strings.getKey('sidebar/geometry/export'));
        exportJson.setMarginLeft('120px');
        exportJson.onClick(function() {
            var object:Dynamic = editor.selected;
            var geometry:Dynamic = object.geometry;
            var output:Dynamic = geometry.toJSON();
            try {
                output = haxe.Json.stringify(output, null, '\t');
                output = output.replace ~/[\n\t]+([\d\.e\-\[\]]+)/g, '$1';
            } catch (e:Dynamic) {
                output = haxe.Json.stringify(output);
            }
            editor.utils.save(new Blob([output]), geometryName.getValue() != null ? geometryName.getValue() : 'geometry' + '.json');
        });
        container.add(exportJson);

        async function build() {
            var object:Dynamic = editor.selected;
            if (object && object.geometry) {
                var geometry:Dynamic = object.geometry;
                container.setDisplay('block');
                geometryType.setValue(geometry.type);
                geometryUUID.setValue(geometry.uuid);
                geometryName.setValue(geometry.name);
                if (currentGeometryType !== geometry.type) {
                    parameters.clear();
                    if (geometry.type === 'BufferGeometry') {
                        parameters.add(new SidebarGeometryModifiers(editor, object));
                    } else {
                        var GeometryParametersPanel:Dynamic = JS.require('./Sidebar.Geometry.${geometry.type}.js');
                        parameters.add(new GeometryParametersPanel(editor, object));
                    }
                    currentGeometryType = geometry.type;
                }
                if (geometry.boundingBox === null) geometry.computeBoundingBox();
                var boundingBox:Dynamic = geometry.boundingBox;
                var x:Float = Math.floor((boundingBox.max.x - boundingBox.min.x) * 1000) / 1000;
                var y:Float = Math.floor((boundingBox.max.y - boundingBox.min.y) * 1000) / 1000;
                var z:Float = Math.floor((boundingBox.max.z - boundingBox.min.z) * 1000) / 1000;
                geometryBoundingBox.setInnerHTML('${x}<br/>${y}<br/>${z}');
                helpersRow.setDisplay(geometry.hasAttribute('normal') ? '' : 'none');
            } else {
                container.setDisplay('none');
            }
        }

        signals.objectSelected.add(function() {
            currentGeometryType = null;
            build();
        });

        signals.geometryChanged.add(build);
    }
}
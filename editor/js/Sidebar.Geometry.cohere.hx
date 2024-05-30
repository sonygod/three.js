import js.three.Addons.Helpers.VertexNormalsHelper;
import js.three.MathUtils;
import js.three.Object3D;
import js.three.Vector3;
import js.three.addons.core.Geometry;
import js.three.addons.extras.BufferGeometry;

import js.ui.UIPanel;
import js.ui.UIRow;
import js.ui.UIText;
import js.ui.UIInput;
import js.ui.UIButton;
import js.ui.UISpan;

class SidebarGeometry {
    public var container:UIPanel;
    public var geometryType:UIText;
    public var geometryUUID:UIInput;
    public var geometryName:UIInput;
    public var parameters:UISpan;
    public var geometryBoundingBox:UIText;
    public var helpersRow:UIRow;
    public var vertexNormalsButton:UIButton;
    public var exportJson:UIButton;
    public var editor:Editor;
    public var currentGeometryType:String;
    public var geometryUUIDRenew:UIButton;
    public var signals:EditorSignals;
    public var strings:EditorStrings;

    public function new(editor:Editor) {
        this.editor = editor;
        this.signals = editor.signals;
        this.strings = editor.strings;
        this.container = new UIPanel();
        this.container.setBorderTop('0');
        this.container.setDisplay('none');
        this.container.setPaddingTop('20px');
        this.currentGeometryType = null;
        this.build();
        this.signals.objectSelected.add($bind(this, this.build));
        this.signals.geometryChanged.add($bind(this, this.build));
    }

    public function build():Void {
        var object = this.editor.selected;
        if (object != null && object.geometry != null) {
            this.container.setDisplay('block');
            var geometry = object.geometry;
            this.geometryType.setValue(geometry.type);
            this.geometryUUID.setValue(geometry.uuid);
            this.geometryName.setValue(geometry.name);
            if (this.currentGeometryType != geometry.type) {
                this.parameters.clear();
                if (Std.is(geometry, BufferGeometry)) {
                    this.parameters.add(new SidebarGeometryModifiers(this.editor, object));
                } else {
                    var geometryParametersPanel = Type.resolveClass('Sidebar.Geometry.' + geometry.type + '.GeometryParametersPanel');
                    this.parameters.add(Reflect.newInstance(geometryParametersPanel, [this.editor, object]));
                }
                this.currentGeometryType = geometry.type;
            }
            if (geometry.boundingBox == null) {
                geometry.computeBoundingBox();
            }
            var boundingBox = geometry.boundingBox;
            var x = Std.int(Std.floor((boundingBox.max.x - boundingBox.min.x) * 1000)) / 1000;
            var y = Std.int(Std.floor((boundingBox.max.y - boundingBox.min.y) * 1000)) / 1000;
            var z = Std.int(Std.floor((boundingBox.max.z - boundingBox.min.z) * 1000)) / 1000;
            this.geometryBoundingBox.setInnerHTML($'{x}<br/>${y}<br/>${z}');
            this.helpersRow.setDisplay(geometry.hasAttribute('normal') ? '' : 'none');
        } else {
            this.container.setDisplay('none');
        }
    }
}

class SidebarGeometryModifiers {
    // ...
}
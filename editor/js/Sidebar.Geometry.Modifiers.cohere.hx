import js.Browser.window;
import js.three.BufferGeometry;
import js.three.BufferGeometryUtils_computeMikkTSpaceTangents;
import js.three.Geometry;
import js.three.Object3D;
import js.three.Signal;
import js.three.UIButton;
import js.three.UIDiv;
import js.three.UIRow;

class SidebarGeometryModifiers {
    public var container:UIDiv;
    public var computeVertexNormalsButton:UIButton;
    public var computeVertexTangentsButton:UIButton;
    public var centerButton:UIButton;
    public var computeVertexNormalsRow:UIRow;
    public var computeVertexTangentsRow:UIRow;
    public var centerRow:UIRow;
    public var geometry:Geometry;
    public var object:Object3D;
    public var editor:any;

    public function new(editor:any, object:Object3D) {
        this.editor = editor;
        this.object = object;
        this.geometry = object.geometry as Geometry;
        this.container = new UIDiv();
        this.container.setMarginLeft('120px');

        this.computeVertexNormalsButton = new UIButton(editor.strings.getKey('sidebar/geometry/compute_vertex_normals'));
        this.computeVertexNormalsButton.onClick(this.computeVertexNormals_onClick);

        this.computeVertexNormalsRow = new UIRow();
        this.computeVertexNormalsRow.add(this.computeVertexNormalsButton);
        this.container.add(this.computeVertexNormalsRow);

        if (this.geometry.hasAttribute('position') && this.geometry.hasAttribute('normal') && this.geometry.hasAttribute('uv')) {
            this.computeVertexTangentsButton = new UIButton(editor.strings.getKey('sidebar/geometry/compute_vertex_tangents'));
            this.computeVertexTangentsButton.onClick(this.computeVertexTangents_onClick);

            this.computeVertexTangentsRow = new UIRow();
            this.computeVertexTangentsRow.add(this.computeVertexTangentsButton);
            this.container.add(this.computeVertexTangentsRow);
        }

        this.centerButton = new UIButton(editor.strings.getKey('sidebar/geometry/center'));
        this.centerButton.onClick(this.center_onClick);

        this.centerRow = new UIRow();
        this.centerRow.add(this.centerButton);
        this.container.add(this.centerRow);
    }

    private function computeVertexNormals_onClick():Void {
        this.geometry.computeVertexNormals();
        this.editor.signals.geometryChanged.dispatch(this.object);
    }

    private async function computeVertexTangents_onClick():Void {
        var mikkTSpace = window.MikkTSpace;
        await mikkTSpace.ready;
        BufferGeometryUtils_computeMikkTSpaceTangents(this.geometry, mikkTSpace);
        this.editor.signals.geometryChanged.dispatch(this.object);
    }

    private function center_onClick():Void {
        this.geometry.center();
        this.editor.signals.geometryChanged.dispatch(this.object);
    }
}

class Signal {
    public function dispatch(object:Object3D):Void {
        // Abstract class
    }
}

class Strings {
    public function getKey(key:String):String {
        return '';
    }
}
import js.Browser.document;
import js.html.UIEvent;
import js.html.HTMLDivElement;
import js.html.HTMLInputElement;
import js.html.LabelElement;
import three.THREE;
import ui.UIDiv;
import ui.UIRow;
import ui.UIText;
import ui.UIInteger;
import ui.UINumber;
import commands.SetGeometryCommand;

class GeometryParametersPanel {
    private var editor:Editor;
    private var object:Object3D;
    private var strings:Strings;
    private var container:UIDiv;
    private var geometry:SphereGeometry;
    private var parameters:Dynamic;
    private var radius:UINumber;
    private var widthSegments:UIInteger;
    private var heightSegments:UIInteger;
    private var phiStart:UINumber;
    private var phiLength:UINumber;
    private var thetaStart:UINumber;
    private var thetaLength:UINumber;

    public function new(editor:Editor, object:Object3D) {
        this.editor = editor;
        this.object = object;
        this.strings = editor.strings;
        this.container = new UIDiv();
        this.geometry = object.geometry;
        this.parameters = this.geometry.parameters;

        // radius
        var radiusRow = new UIRow();
        this.radius = new UINumber(this.parameters.radius).onChange(this.update.bind(this));
        radiusRow.add(new UIText(this.strings.getKey('sidebar/geometry/sphere_geometry/radius')).setClass('Label'));
        radiusRow.add(this.radius);
        this.container.add(radiusRow);

        // widthSegments
        var widthSegmentsRow = new UIRow();
        this.widthSegments = new UIInteger(this.parameters.widthSegments).setRange(1, Float.POSITIVE_INFINITY).onChange(this.update.bind(this));
        widthSegmentsRow.add(new UIText(this.strings.getKey('sidebar/geometry/sphere_geometry/widthsegments')).setClass('Label'));
        widthSegmentsRow.add(this.widthSegments);
        this.container.add(widthSegmentsRow);

        // heightSegments
        var heightSegmentsRow = new UIRow();
        this.heightSegments = new UIInteger(this.parameters.heightSegments).setRange(1, Float.POSITIVE_INFINITY).onChange(this.update.bind(this));
        heightSegmentsRow.add(new UIText(this.strings.getKey('sidebar/geometry/sphere_geometry/heightsegments')).setClass('Label'));
        heightSegmentsRow.add(this.heightSegments);
        this.container.add(heightSegmentsRow);

        // phiStart
        var phiStartRow = new UIRow();
        this.phiStart = new UINumber(this.parameters.phiStart * THREE.MathUtils.RAD2DEG).setStep(10).onChange(this.update.bind(this));
        phiStartRow.add(new UIText(this.strings.getKey('sidebar/geometry/sphere_geometry/phistart')).setClass('Label'));
        phiStartRow.add(this.phiStart);
        this.container.add(phiStartRow);

        // phiLength
        var phiLengthRow = new UIRow();
        this.phiLength = new UINumber(this.parameters.phiLength * THREE.MathUtils.RAD2DEG).setStep(10).onChange(this.update.bind(this));
        phiLengthRow.add(new UIText(this.strings.getKey('sidebar/geometry/sphere_geometry/philength')).setClass('Label'));
        phiLengthRow.add(this.phiLength);
        this.container.add(phiLengthRow);

        // thetaStart
        var thetaStartRow = new UIRow();
        this.thetaStart = new UINumber(this.parameters.thetaStart * THREE.MathUtils.RAD2DEG).setStep(10).onChange(this.update.bind(this));
        thetaStartRow.add(new UIText(this.strings.getKey('sidebar/geometry/sphere_geometry/thetastart')).setClass('Label'));
        thetaStartRow.add(this.thetaStart);
        this.container.add(thetaStartRow);

        // thetaLength
        var thetaLengthRow = new UIRow();
        this.thetaLength = new UINumber(this.parameters.thetaLength * THREE.MathUtils.RAD2DEG).setStep(10).onChange(this.update.bind(this));
        thetaLengthRow.add(new UIText(this.strings.getKey('sidebar/geometry/sphere_geometry/thetalength')).setClass('Label'));
        thetaLengthRow.add(this.thetaLength);
        this.container.add(thetaLengthRow);
    }

    private function update(e:UIEvent):Void {
        this.editor.execute(new SetGeometryCommand(this.editor, this.object, new THREE.SphereGeometry(
            this.radius.getValue(),
            this.widthSegments.getValue(),
            this.heightSegments.getValue(),
            this.phiStart.getValue() * THREE.MathUtils.DEG2RAD,
            this.phiLength.getValue() * THREE.MathUtils.DEG2RAD,
            this.thetaStart.getValue() * THREE.MathUtils.DEG2RAD,
            this.thetaLength.getValue() * THREE.MathUtils.DEG2RAD
        )));
    }

    public function getContainer():UIDiv {
        return this.container;
    }
}
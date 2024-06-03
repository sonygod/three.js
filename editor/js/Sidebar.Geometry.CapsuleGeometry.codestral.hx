import js.html.UIElement;
import js.html.UIInputElement;
import js.html.UIInputNumberElement;
import js.html.UIInputIntegerElement;
import js.html.UIEvent;
import js.html.document;

class GeometryParametersPanel {
    private var editor: dynamic;
    private var object: dynamic;
    private var strings: dynamic;
    private var container: UIDiv;
    private var geometry: dynamic;
    private var parameters: dynamic;
    private var radius: UINumber;
    private var length: UINumber;
    private var capSegments: UINumber;
    private var radialSegments: UIInteger;

    public function new(editor: dynamic, object: dynamic) {
        this.editor = editor;
        this.object = object;
        this.strings = editor.strings;
        this.container = new UIDiv();
        this.geometry = object.geometry;
        this.parameters = geometry.parameters;

        // radius
        var radiusRow = new UIRow();
        this.radius = new UINumber(parameters.radius);
        radius.onChange(update);
        radiusRow.add(new UIText(strings.getKey('sidebar/geometry/capsule_geometry/radius')).setClass('Label'));
        radiusRow.add(radius);
        container.add(radiusRow);

        // length
        var lengthRow = new UIRow();
        this.length = new UINumber(parameters.length);
        length.onChange(update);
        lengthRow.add(new UIText(strings.getKey('sidebar/geometry/capsule_geometry/length')).setClass('Label'));
        lengthRow.add(length);
        container.add(lengthRow);

        // capSegments
        var capSegmentsRow = new UIRow();
        this.capSegments = new UINumber(parameters.capSegments);
        capSegments.onChange(update);
        capSegmentsRow.add(new UIText(strings.getKey('sidebar/geometry/capsule_geometry/capseg')).setClass('Label'));
        capSegmentsRow.add(capSegments);
        container.add(capSegmentsRow);

        // radialSegments
        var radialSegmentsRow = new UIRow();
        this.radialSegments = new UIInteger(parameters.radialSegments);
        radialSegments.setRange(1, Infinity);
        radialSegments.onChange(update);
        radialSegmentsRow.add(new UIText(strings.getKey('sidebar/geometry/capsule_geometry/radialseg')).setClass('Label'));
        radialSegmentsRow.add(radialSegments);
        container.add(radialSegmentsRow);
    }

    private function update(event: UIEvent) {
        // Assuming SetGeometryCommand and CapsuleGeometry are available in Haxe
        editor.execute(new SetGeometryCommand(editor, object, new CapsuleGeometry(
            radius.getValue(),
            length.getValue(),
            capSegments.getValue(),
            radialSegments.getValue()
        )));
    }

    public function getContainer(): UIDiv {
        return this.container;
    }
}
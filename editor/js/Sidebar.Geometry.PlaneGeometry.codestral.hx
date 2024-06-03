import three.THREE;
import ui.UIDiv;
import ui.UIRow;
import ui.UIText;
import ui.UIInteger;
import ui.UINumber;
import commands.SetGeometryCommand;

class GeometryParametersPanel {
    private var editor: dynamic;
    private var object: dynamic;
    private var strings: dynamic;
    private var container: UIDiv;
    private var geometry: dynamic;
    private var parameters: dynamic;
    private var width: UINumber;
    private var height: UINumber;
    private var widthSegments: UIInteger;
    private var heightSegments: UIInteger;

    public function new(editor: dynamic, object: dynamic) {
        this.editor = editor;
        this.object = object;
        this.strings = editor.strings;

        this.container = new UIDiv();

        this.geometry = object.geometry;
        this.parameters = geometry.parameters;

        // width
        var widthRow = new UIRow();
        this.width = new UINumber(parameters.width);
        this.width.onChange(this.update.bind(this));

        widthRow.add(new UIText(strings.getKey('sidebar/geometry/plane_geometry/width')).setClass('Label'));
        widthRow.add(this.width);

        container.add(widthRow);

        // height
        var heightRow = new UIRow();
        this.height = new UINumber(parameters.height);
        this.height.onChange(this.update.bind(this));

        heightRow.add(new UIText(strings.getKey('sidebar/geometry/plane_geometry/height')).setClass('Label'));
        heightRow.add(this.height);

        container.add(heightRow);

        // widthSegments
        var widthSegmentsRow = new UIRow();
        this.widthSegments = new UIInteger(parameters.widthSegments).setRange(1, Int.POSITIVE_INFINITY);
        this.widthSegments.onChange(this.update.bind(this));

        widthSegmentsRow.add(new UIText(strings.getKey('sidebar/geometry/plane_geometry/widthsegments')).setClass('Label'));
        widthSegmentsRow.add(this.widthSegments);

        container.add(widthSegmentsRow);

        // heightSegments
        var heightSegmentsRow = new UIRow();
        this.heightSegments = new UIInteger(parameters.heightSegments).setRange(1, Int.POSITIVE_INFINITY);
        this.heightSegments.onChange(this.update.bind(this));

        heightSegmentsRow.add(new UIText(strings.getKey('sidebar/geometry/plane_geometry/heightsegments')).setClass('Label'));
        heightSegmentsRow.add(this.heightSegments);

        container.add(heightSegmentsRow);
    }

    private function update() {
        editor.execute(new SetGeometryCommand(editor, object, new THREE.PlaneGeometry(
            width.getValue(),
            height.getValue(),
            widthSegments.getValue(),
            heightSegments.getValue()
        )));
    }

    public function getContainer(): UIDiv {
        return this.container;
    }
}
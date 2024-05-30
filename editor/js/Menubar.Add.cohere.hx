import js.three.BoxGeometry;
import js.three.CapsuleGeometry;
import js.three.CatmullRomCurve3;
import js.three.CircleGeometry;
import js.three.CylinderGeometry;
import js.three.DodecahedronGeometry;
import js.three.Geometry;
import js.three.IcosahedronGeometry;
import js.three.LatheGeometry;
import js.three.Light;
import js.three.OctahedronGeometry;
import js.three.PlaneGeometry;
import js.three.RingGeometry;
import js.three.SphereGeometry;
import js.three.Sprite;
import js.three.SpriteMaterial;
import js.three.TetrahedronGeometry;
import js.three.TorusGeometry;
import js.three.TorusKnotGeometry;
import js.three.TubeGeometry;

import js.Browser.window;
import js.html.Element;
import js.html.HTMLElement;
import js.html.HTMLDivElement;
import js.html.HTMLUListElement;

class UIPanel {
    public function new() {
        this.div = window.document.createElement("div");
    }

    public function setClass(className:String) {
        this.div.className = className;
    }

    public function setTextContent(text:String) {
        this.div.textContent = text;
    }

    public function add(element:UIPanel) {
        this.div.appendChild(element.div);
    }

    public function setPosition(position:String) {
        this.div.style.position = position;
    }

    public function setLeft(left:String) {
        this.div.style.left = left;
    }

    public function setTop(top:String) {
        this.div.style.top = top;
    }

    public function setStyle(style:String, value:String) {
        this.div.style[style] = value;
    }

    public function setDisplay(display:String) {
        this.div.style.display = display;
    }

    public var div:HTMLDivElement;
}

class UIRow {
    public function new() {
        this.div = window.document.createElement("div");
    }

    public function setClass(className:String) {
        this.div.className = className;
    }

    public function setTextContent(text:String) {
        this.div.textContent = text;
    }

    public function onClick(f:Void->Void) {
        this.div.onclick = function() f();
    }

    public function onMouseOver(f:Void->Void) {
        this.div.onmouseover = function() f();
    }

    public function onMouseOut(f:Void->Void) {
        this.div.onmouseout = function() f();
    }

    public function add(element:UIPanel) {
        this.div.appendChild(element.div);
    }

    public var div:HTMLDivElement;
}

class UIHorizontalRule {
    public function new() {
        this.hr = window.document.createElement("hr");
    }

    public var hr:HTMLElement;
}

class AddObjectCommand {
    public function new(editor, mesh) {
        this.editor = editor;
        this.mesh = mesh;
    }

    public function execute() {
        // ...
    }

    public var editor;
    public var mesh;
}

class MenubarAdd {
    public function new(editor) {
        this.editor = editor;
        this.container = new UIPanel();
        this.container.setClass("menu");

        this.title = new UIPanel();
        this.title.setClass("title");
        this.title.setTextContent("Add");
        this.container.add(this.title);

        this.options = new UIPanel();
        this.options.setClass("options");
        this.container.add(this.options);

        this.createGroupOption();
        this.createMeshOptions();
        this.createLightOptions();
        this.createCameraOptions();
    }

    private function createGroupOption() {
        var option = new UIRow();
        option.setClass("option");
        option.setTextContent("Group");
        option.onClick(this.createGroup.bind(this));
        this.options.add(option);
    }

    private function createGroup() {
        var mesh = new js.three.Group();
        mesh.name = "Group";
        this.editor.execute(new AddObjectCommand(this.editor, mesh));
    }

    private function createMeshOptions() {
        var meshSubmenuTitle = new UIRow();
        meshSubmenuTitle.setTextContent("Mesh");
        meshSubmenuTitle.setClass("option submenu-title");
        meshSubmenuTitle.onMouseOver(this.showMeshSubmenu.bind(this, meshSubmenuTitle));
        meshSubmenuTitle.onMouseOut(this.hideSubmenu.bind(this));
        this.options.add(meshSubmenuTitle);

        this.meshSubmenu = new UIPanel();
        this.meshSubmenu.setPosition("fixed");
        this.meshSubmenu.setClass("options");
        this.meshSubmenu.setDisplay("none");
        meshSubmenuTitle.add(this.meshSubmenu);

        this.createMeshBoxOption();
        this.createMeshCapsuleOption();
        this.createMeshCircleOption();
        this.createMeshCylinderOption();
        this.createMeshDodecahedronOption();
        this.createMeshIcosahedronOption();
        this.createMeshLatheOption();
        this.createMeshOctahedronOption();
        this.createMeshPlaneOption();
        this.createMeshRingOption();
        this.createMeshSphereOption();
        this.createMeshSpriteOption();
        this.createMeshTetrahedronOption();
        this.createMeshTorusOption();
        this.createMeshTorusKnotOption();
        this.createMeshTubeOption();
    }

    private function createMeshBoxOption() {
        var option = new UIRow();
        option.setClass("option");
        option.setTextContent("Box");
        option.onClick(this.createMeshBox.bind(this));
        this.meshSubmenu.add(option);
    }

    private function createMeshBox() {
        var geometry = new BoxGeometry(1, 1, 1, 1, 1, 1);
        var mesh = new js.three.Mesh(geometry, new js.three.MeshStandardMaterial());
        mesh.name = "Box";
        this.editor.execute(new AddObjectCommand(this.editor, mesh));
    }

    // ... other mesh options ...

    private function showMeshSubmenu(menuItem:UIRow) {
        var rect = menuItem.div.getBoundingClientRect();
        var paddingTop = window.getComputedStyle(menuItem.div).paddingTop;
        this.meshSubmenu.setLeft(Std.string(rect.right) + "px");
        this.meshSubmenu.setTop(Std.string(rect.top - Std.parseFloat(paddingTop)) + "px");
        this.meshSubmenu.setStyle("max-height", ["calc(100vh - " + Std.string(rect.top) + "px)"]);
        this.meshSubmenu.setDisplay("block");
    }

    private function hideSubmenu() {
        this.meshSubmenu.setDisplay("none");
    }

    private function createLightOptions() {
        // Similar to createMeshOptions()
    }

    private function createCameraOptions() {
        // Similar to createMeshOptions()
    }

    public function getContainer():UIPanel {
        return this.container;
    }

    private var editor;
    private var container:UIPanel;
    private var title:UIPanel;
    private var options:UIPanel;
    private var meshSubmenu:UIPanel;
}

class Editor {
    public function execute(command:AddObjectCommand) {
        // ...
    }

    public var camera:js.three.PerspectiveCamera;
    public var strings:Strings;
}

class Strings {
    public function getKey(key:String):String {
        // ...
    }
}
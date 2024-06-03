import js.Browser.document;
import js.Browser.window;
import js.html.Element;
import js.html.HTMLDivElement;
import js.html.Event;
import js.html.HTMLStyleElement;
import js.html.HTMLUListElement;
import js.html.IUIEvent;

import three.THREE;
import three.cameras.OrthographicCamera;
import three.cameras.PerspectiveCamera;
import three.lights.AmbientLight;
import three.lights.DirectionalLight;
import three.lights.HemisphereLight;
import three.lights.PointLight;
import three.lights.SpotLight;
import three.materials.MeshStandardMaterial;
import three.materials.SpriteMaterial;
import three.objects.Group;
import three.objects.Mesh;
import three.objects.Sprite;
import three.core.Object3D;
import three.core.Vector3;
import three.extras.curves.CatmullRomCurve3;
import three.geometries.BoxGeometry;
import three.geometries.CapsuleGeometry;
import three.geometries.CircleGeometry;
import three.geometries.CylinderGeometry;
import three.geometries.DodecahedronGeometry;
import three.geometries.Geometry;
import three.geometries.IcosahedronGeometry;
import three.geometries.LatheGeometry;
import three.geometries.OctahedronGeometry;
import three.geometries.PlaneGeometry;
import three.geometries.RingGeometry;
import three.geometries.SphereGeometry;
import three.geometries.TetrahedronGeometry;
import three.geometries.TorusGeometry;
import three.geometries.TorusKnotGeometry;
import three.geometries.TubeGeometry;

class UIPanel {
    public var dom: HTMLDivElement;

    public function new() {
        this.dom = document.createElement("div");
    }

    public function setClass(className: String): UIPanel {
        this.dom.className = className;
        return this;
    }

    public function setTextContent(text: String): UIPanel {
        this.dom.textContent = text;
        return this;
    }

    public function add(child: UIPanel): UIPanel {
        this.dom.appendChild(child.dom);
        return this;
    }

    public function setPosition(position: String): UIPanel {
        this.dom.style.position = position;
        return this;
    }

    public function setDisplay(display: String): UIPanel {
        this.dom.style.display = display;
        return this;
    }

    public function setLeft(left: String): UIPanel {
        this.dom.style.left = left;
        return this;
    }

    public function setTop(top: String): UIPanel {
        this.dom.style.top = top;
        return this;
    }

    public function setStyle(style: String, value: Array<String>): UIPanel {
        this.dom.style.setProperty(style, value.join(", "));
        return this;
    }
}

class UIRow extends UIPanel {
    public function onClick(callback: Void -> Void): UIRow {
        this.dom.addEventListener("click", (_) -> callback());
        return this;
    }

    public function onMouseOver(callback: Void -> Void): UIRow {
        this.dom.addEventListener("mouseover", (_) -> callback());
        return this;
    }

    public function onMouseOut(callback: Void -> Void): UIRow {
        this.dom.addEventListener("mouseout", (_) -> callback());
        return this;
    }

    public function addClass(className: String): UIRow {
        this.dom.classList.add(className);
        return this;
    }
}

class UIHorizontalRule {
    // Implementation for UIHorizontalRule if needed
}

class AddObjectCommand {
    public function new(editor: Editor, object: Object3D) {
        // Implementation for AddObjectCommand if needed
    }
}

class Editor {
    public var strings: String;
    public var camera: PerspectiveCamera;

    public function execute(command: AddObjectCommand) {
        // Implementation for Editor.execute if needed
    }
}

class MenubarAdd {
    public function new(editor: Editor) {
        var strings = editor.strings;

        var container = new UIPanel();
        container.setClass("menu");

        var title = new UIPanel();
        title.setClass("title");
        title.setTextContent(strings.getKey("menubar/add"));
        container.add(title);

        var options = new UIPanel();
        options.setClass("options");
        container.add(options);

        // Rest of the code...
    }
}
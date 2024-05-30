// lil-gui.hx

class LilGuiController<T> {
    private var parent: LilGui;
    private var object: T;
    private var property: String;
    private var _disabled: Bool;
    private var _hidden: Bool;
    private var initialValue: Dynamic; // Adjust the type based on the actual type
    private var domElement: js.html.Element;
    private var $name: js.html.Element;
    private var $widget: js.html.Element;
    
    public function new(parent: LilGui, object: T, property: String, elementType: String = "div") {
        this.parent = parent;
        this.object = object;
        this.property = property;
        this._disabled = false;
        this._hidden = false;
        this.initialValue = this.getValue();
        this.domElement = js.Browser.document.createElement(elementType);
        // Initialize DOM elements and add event listeners as in JavaScript code
        // Add DOM elements to parent's DOM structure
    }

    private function name(name: String): LilGuiController<T> {
        this._name = name;
        this.$name.innerHTML = name;
        return this;
    }

    // Implement other methods like onChange, onFinishChange, reset, enable, disable, etc.
    // Remember to handle DOM updates and event listeners accordingly
}

class LilGui {
    private var children: Array<LilGuiController<Dynamic>>;
    private var controllers: Array<LilGuiController<Dynamic>>;
    private var $children: js.html.Element;
    // Define other properties and methods as needed

    public function new() {
        this.children = [];
        this.controllers = [];
        this.$children = js.Browser.document.createElement("div");
        // Initialize DOM elements and structure for the GUI
    }

    public function add<T>(object: T, property: String, type: String): LilGuiController<T> {
        var controller = new LilGuiController<T>(this, object, property, type);
        this.controllers.push(controller);
        this.$children.appendChild(controller.domElement);
        return controller;
    }

    // Implement other methods for GUI functionality
}

// Usage example
class Main {
    static function main() {
        var lilGui = new LilGui();
        var object = new MyClass(); // Assuming MyClass is defined elsewhere
        var controller = lilGui.add(object, "propertyName", "number");
        // Add more controllers as needed
    }
}
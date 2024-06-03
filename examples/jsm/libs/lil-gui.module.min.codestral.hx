import js.html.HTMLElement;
import js.html.InputElement;
import js.html.SelectElement;

class Controller {
    public var parent: GUI;
    public var object: Dynamic;
    public var property: String;
    public var _disabled: Bool = false;
    public var _hidden: Bool = false;
    public var initialValue: Dynamic;
    public var domElement: HTMLElement;
    public var $name: HTMLElement;
    public var $widget: HTMLElement;
    public var $disable: HTMLElement;
    // Add other variables as needed

    public function new(parent: GUI, object: Dynamic, property: String, name: String, l: String = "div") {
        this.parent = parent;
        this.object = object;
        this.property = property;
        this.initialValue = this.getValue();
        // Initialize other variables and DOM elements
    }

    // Add other methods as needed

    public function getValue(): Dynamic {
        return Reflect.field(this.object, this.property);
    }

    // Add other methods as needed
}

class BooleanController extends Controller {
    // Implement methods as needed
}

class ColorController extends Controller {
    // Implement methods as needed
}

class FunctionController extends Controller {
    // Implement methods as needed
}

class NumberController extends Controller {
    // Implement methods as needed
}

class OptionController extends Controller {
    // Implement methods as needed
}

class StringController extends Controller {
    // Implement methods as needed
}

class GUI {
    public var parent: GUI;
    public var root: GUI;
    public var children: Array<GUI>;
    public var controllers: Array<Controller>;
    public var folders: Array<GUI>;
    public var _closed: Bool = false;
    public var _hidden: Bool = false;
    public var domElement: HTMLElement;
    public var $title: HTMLElement;
    public var $children: HTMLElement;
    // Add other variables as needed

    public function new(options: Dynamic = null) {
        // Initialize variables and DOM elements
    }

    // Add other methods as needed

    public function add(object: Dynamic, property: String, value: Dynamic, name: String = null, label: String = null): Controller {
        if (Std.is(value, Map)) {
            return new OptionController(this, object, property, value);
        }
        switch (Type.typeof(value)) {
            case TType.TInt:
            case TType.TFloat:
                return new NumberController(this, object, property, value);
            case TType.TBool:
                return new BooleanController(this, object, property);
            case TType.TString:
                return new StringController(this, object, property);
            case TType.TFunction:
                return new FunctionController(this, object, property);
        }
        return null;
    }

    // Add other methods as needed
}
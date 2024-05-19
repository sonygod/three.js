package three.js.playground.libs;

class Link {
    public var inputElement:Dynamic;
    public var outputElement:Dynamic;

    public function new(?inputElement:Dynamic, ?outputElement:Dynamic) {
        this.inputElement = inputElement;
        this.outputElement = outputElement;
    }

    public var lioElement(get, null):Dynamic;

    private function get_lioElement():Dynamic {
        if (Link.InputDirection == 'left') {
            return outputElement;
        } else {
            return inputElement;
        }
    }

    public var rioElement(get, null):Dynamic;

    private function get_rioElement():Dynamic {
        if (Link.InputDirection == 'left') {
            return inputElement;
        } else {
            return outputElement;
        }
    }
}
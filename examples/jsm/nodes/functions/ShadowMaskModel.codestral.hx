// ShadowMaskModel.hx
class ShadowMaskModel extends LightingModel {
    public var shadowNode: Float;

    public function new() {
        super();
        this.shadowNode = Float.create(1).toVar("shadowMask");
    }

    public function direct(options: Dynamic) {
        this.shadowNode.mulAssign(options.shadowMask);
    }

    public function finish(context: Context) {
        diffuseColor.a.mulAssign(this.shadowNode.oneMinus());
        context.outgoingLight.rgb.assign(diffuseColor.rgb);
    }
}

// LightingModel.hx
class LightingModel {
    // define your LightingModel class here
}

// PropertyNode.hx
class PropertyNode {
    public static var diffuseColor: Dynamic;
}

// ShaderNode.hx
class ShaderNode {
    public static function float(value: Float): Float {
        return value;
    }
}

// Context.hx
class Context {
    public var outgoingLight: { rgb: Dynamic };
}

// Please define any missing classes or functions based on your project's context.
import js.html.Canvas;
import js.html.CanvasRenderingContext2D;

class FogExp2 {

    public var isFogExp2:Bool = true;
    public var name:String = "";
    public var color:Color;
    public var density:Float;

    public function new(color:Int, density:Float = 0.00025) {

        this.color = new Color(color);
        this.density = density;

    }

    public function clone():FogExp2 {

        return new FogExp2(this.color.getHex(), this.density);

    }

    public function toJSON():Dynamic {

        return {
            type: "FogExp2",
            name: this.name,
            color: this.color.getHex(),
            density: this.density
        };

    }

}

class Color {

    public function new(color:Int) {
        // You'll need to implement the Color class or use an existing one
    }

    public function getHex():Int {
        // Implementation for getting hex value from color
        return 0;
    }

}
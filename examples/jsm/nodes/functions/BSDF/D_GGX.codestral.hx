// Import the necessary classes or functions if available
// import js.Browser.document;
// import js._Boot.Math;

// Define the D_GGX function
class D_GGX {
    // Define the inputs as properties of the class
    public var alpha: Float;
    public var dotNH: Float;

    // Define the function
    public function new(alpha: Float, dotNH: Float) {
        this.alpha = alpha;
        this.dotNH = dotNH;
    }

    // Implement the calculation
    public function calculate(): Float {
        var a2 = this.alpha * this.alpha;
        var denom = (this.dotNH * this.dotNH) * (1 - a2);
        denom = (1 - denom); // avoid alpha = 0 with dotNH = 1
        return (a2 / (denom * denom)) * (1 / Math.PI);
    }
}

// Create an instance of the D_GGX function and call the calculate method
var dggx = new D_GGX(0.5, 0.8);
var result = dggx.calculate();
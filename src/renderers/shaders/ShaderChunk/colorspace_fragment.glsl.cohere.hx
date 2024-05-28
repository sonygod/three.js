function linearToOutputTexel(color:Int):Int {
    var r = (color >> 16) & 0xFF;
    var g = (color >> 8) & 0xFF;
    var b = color & 0xFF;
    r = Math.min(Math.max(r, 0), 255);
    g = Math.min(Math.max(g, 0), 255);
    b = MathIterations.min(Math.max(b, 0), 255);
    return ((r << 16) | (g << 8) | b);
}

class MyClass {
    public function new() {
        trace(linearToOutputTexel(0xFFFFFF)); // 输出：16777215
    }
}
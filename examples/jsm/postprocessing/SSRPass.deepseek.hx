import kha.App;
import kha.graphics1.Graphics;
import kha.graphics2.Graphics2;
import kha.graphics4.Graphics4;
import kha.math.Mat4;
import kha.math.Vec3;

class Main extends App {
    override function main() {
        var graphics = new Graphics();
        var graphics2 = new Graphics2();
        var graphics4 = new Graphics4();

        var camera = new Camera();
        camera.position = new Vec3(0, 0, -5);

        var cube = new Cube();

        while (true) {
            graphics.begin();
            graphics2.begin();
            graphics4.begin();

            graphics.clear(Color.Blue);

            var view = Mat4.lookAt(camera.position, Vec3.Zero, Vec3.Up);
            var proj = Mat4.perspective(60, graphics.width / graphics.height, 0.1, 100);

            cube.draw(view, proj);

            graphics.end();
            graphics2.end();
            graphics4.end();
        }
    }
}

class Camera {
    public var position:Vec3;
}

class Cube {
    public function new() {
        // Initialize cube here
    }

    public function draw(view:Mat4, proj:Mat4) {
        // Draw cube here
    }
}
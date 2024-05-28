import haxe.io.Bytes;

class PolarGridHelper extends LineSegments {
    public function new(radius: F32 = 10, sectors: Int = 16, rings: Int = 8, divisions: Int = 64, color1: Int = 0x444444, color2: Int = 0x888888) {
        let color1 = new Color(color1);
        let color2 = new Color(color2);

        let vertices = [];
        let colors = [];

        // create the sectors
        if (sectors > 1) {
            for (i in 0...sectors) {
                let v = (i / sectors) * (Std.PI * 2);
                let x = Math.sin(v) * radius;
                let z = Math.cos(v) * radius;

                vertices.push(0, 0, 0);
                vertices.push(x, 0, z);

                let color = if (i % 2 == 0) color1 else color2;

                colors.push(color.r, color.g, color.b);
                colors.push(color.r, color.g, color.b);
            }
        }

        // create the rings
        for (i in 0...rings) {
            let color = if (i % 2 == 0) color1 else color2;
            let r = radius - (radius / rings * i);

            for (j in 0...divisions) {
                // first vertex
                let v = (j / divisions) * (Std.PI * 2);
                let x = Math.sin(v) * r;
                let z = Math.cos(v) * r;

                vertices.push(x, 0, z);
                colors.push(color.r, color.g, color.b);

                // second vertex
                v = ((j + 1) / divisions) * (Std.PI * 2);
                x = Math.sin(v) * r;
                z = Math.cos(v) * r;

                vertices.push(x, 0, z);
                colors.push(color.r, color.g, color.b);
            }
        }

        let geometry = new BufferGeometry();
        geometry.setAttribute('position', new Float32BufferAttribute(vertices, 3));
        geometry.setAttribute('color', new Float32BufferAttribute(colors, 3));

        let material = new LineBasicMaterial({vertexColors: true, toneMapped: false});

        super(geometry, material);

        this.type = 'PolarGridHelper';
    }

    public function dispose(): Void {
        geometry.dispose();
        material.dispose();
    }
}

class Color {
    public var r: F32;
    public var g: F32;
    public var b: F32;

    public function new(color: Int) {
        let bytes = Bytes.ofString(Std.string(color));
        r = bytes.get_uint8(0) / 255;
        g = bytes.get_uint8(1) / 255;
        b = bytes.get_uint8(2) / 255;
    }
}
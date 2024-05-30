class FlakesTexture {
    function new(width: Int, height: Int) {
        var canvas = Canvas.create(width, height);
        var context = canvas.getContext2D();
        context.setFillStyle("rgb(127,127,255)");
        context.fillRect(0, 0, width, height);

        for (i in 0...4000) {
            var x = Std.random(width);
            var y = Std.random(height);
            var r = Std.random(3) + 3;

            var nx = Std.random(2) - 1;
            var ny = Std.random(2) - 1;
            var nz = 1.5;

            var l = Math.sqrt(nx * nx + ny * ny + nz * nz);

            nx /= l;
            ny /= l;
            nz /= l;

            context.setFillStyle("rgb(" + Std.string(Math.round(nx * 127 + 127)) + "," + Std.string(Math.round(ny * 127 + 127)) + "," + Std.string(Math.round(nz * 255)) + ")");
            context.beginPath();
            context.arc(x, y, r, 0, Math.PI * 2);
            context.fill();
        }

        return canvas;
    }
}
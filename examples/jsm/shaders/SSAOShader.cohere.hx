import h2d.Tile;
import h2d.TileSheet;
import h2d.Bitmap;
import h2d.Graphics;
import h2d.BlendMode;
import h2d.Mask;
import h2d.MaskType;
import h2d.Sprite;
import h2d.Tile;
import h2d.TileSheet;
import h2d.Tilemap;
import h2d.Bitmap;
import h2d.Graphics;
import h2d.BlendMode;
import h2d.Mask;
import h2d.MaskType;
import h2d.Sprite;

class MyGame extends Sprite {
    public function new() {
        super();

        var tileSheet = new TileSheet(new Bitmap("assets/tilesheet.png"));
        tileSheet.addTile(new Tile(0, 0, 32, 32));
        tileSheet.addTile(new Tile(32, 0, 32, 32));
        tileSheet.addTile(new Tile(64, 0, 32, 32));

        var tilemap = new Tilemap(tileSheet, 10, 10);
        tilemap.setTile(0, 0, 0);
        tilemap.setTile(1, 0, 1);
        tilemap.setTile(2, 0, 2);

        addChild(tilemap);
    }
}

Class<MyGame>
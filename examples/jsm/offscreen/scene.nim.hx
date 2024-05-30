import three.js.examples.jsm.offscreen.scene.Scene;
import three.js.examples.jsm.offscreen.scene.Camera;
import three.js.examples.jsm.offscreen.scene.Renderer;
import three.js.examples.jsm.offscreen.scene.Group;
import three.js.examples.jsm.offscreen.scene.PerspectiveCamera;
import three.js.examples.jsm.offscreen.scene.Fog;
import three.js.examples.jsm.offscreen.scene.Color;
import three.js.examples.jsm.offscreen.scene.ImageBitmapLoader;
import three.js.examples.jsm.offscreen.scene.CanvasTexture;
import three.js.examples.jsm.offscreen.scene.IcosahedronGeometry;
import three.js.examples.jsm.offscreen.scene.MeshMatcapMaterial;
import three.js.examples.jsm.offscreen.scene.Mesh;

class Main {
    static var camera:Camera;
    static var scene:Scene;
    static var renderer:Renderer;
    static var group:Group;

    static function init( canvas:Dynamic, width:Float, height:Float, pixelRatio:Float, path:String ) {
        camera = new PerspectiveCamera( 40, width / height, 1, 1000 );
        camera.position.z = 200;

        scene = new Scene();
        scene.fog = new Fog( 0x444466, 100, 400 );
        scene.background = new Color( 0x444466 );

        group = new Group();
        scene.add( group );

        var loader = new ImageBitmapLoader().setPath( path );
        loader.setOptions( { imageOrientation: 'flipY' } );
        loader.load( 'textures/matcaps/matcap-porcelain-white.jpg', function ( imageBitmap ) {
            var texture = new CanvasTexture( imageBitmap );

            var geometry = new IcosahedronGeometry( 5, 8 );
            var materials = [
                new MeshMatcapMaterial( { color: 0xaa24df, matcap: texture } ),
                new MeshMatcapMaterial( { color: 0x605d90, matcap: texture } ),
                new MeshMatcapMaterial( { color: 0xe04a3f, matcap: texture } ),
                new MeshMatcapMaterial( { color: 0xe30456, matcap: texture } )
            ];

            for ( i in 0...100 ) {
                var material = materials[ i % materials.length ];
                var mesh = new Mesh( geometry, material );
                mesh.position.x = random() * 200 - 100;
                mesh.position.y = random() * 200 - 100;
                mesh.position.z = random() * 200 - 100;
                mesh.scale.setScalar( random() + 1 );
                group.add( mesh );
            }

            renderer = new WebGLRenderer( { antialias: true, canvas: canvas } );
            renderer.setPixelRatio( pixelRatio );
            renderer.setSize( width, height, false );

            animate();
        } );
    }

    static function animate() {
        group.rotation.y = - Date.now() / 4000;
        renderer.render( scene, camera );
        if ( self.requestAnimationFrame ) {
            self.requestAnimationFrame( animate );
        } else {
            // Firefox
        }
    }

    static var seed = 1;
    static function random() {
        var x = Math.sin( seed ++ ) * 10000;
        return x - Math.floor( x );
    }
}
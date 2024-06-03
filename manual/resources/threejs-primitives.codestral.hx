import js.Browser.document;
import js.Browser.window;
import js.html.HTMLDivElement;
import js.html.HTMLPreElement;
import js.html.HTMLSpanElement;
import js.html.InputElement;
import three.core.Color;
import three.core.Geometry;
import three.core.Object3D;
import three.examples.geometries.ParametricGeometry;
import three.geometries.BoxGeometry;
import three.geometries.CircleGeometry;
import three.geometries.ConeGeometry;
import three.geometries.CylinderGeometry;
import three.geometries.DodecahedronGeometry;
import three.geometries.ExtrudeGeometry;
import three.geometries.IcosahedronGeometry;
import three.geometries.LatheGeometry;
import three.geometries.OctahedronGeometry;
import three.geometries.PlaneGeometry;
import three.geometries.PolyhedronGeometry;
import three.geometries.RingGeometry;
import three.geometries.ShapeGeometry;
import three.geometries.SphereGeometry;
import three.geometries.TetrahedronGeometry;
import three.geometries.TextGeometry;
import three.geometries.TorusGeometry;
import three.geometries.TorusKnotGeometry;
import three.geometries.TubeGeometry;
import three.helpers.EdgesGeometry;
import three.helpers.WireframeGeometry;
import three.materials.LineBasicMaterial;
import three.materials.LineMaterial;
import three.materials.Material;
import three.materials.MeshPhongMaterial;
import three.materials.PointsMaterial;
import three.math.Vector2;
import three.math.Vector3;
import three.objects.LineSegments;
import three.objects.Mesh;
import three.objects.Points;
import three.scenes.Scene;
import three.textures.Texture;
import threejsLessonUtils.ThreejsLessonUtils;
import FontLoader from '../../examples/jsm/loaders/FontLoader';

class ThreeJSPrimitives {
    static var darkColors:Dynamic = {
        lines: '#DDD'
    };
    static var lightColors:Dynamic = {
        lines: '#000'
    };
    static var darkMatcher:MediaQueryList = window.matchMedia('(prefers-color-scheme: dark)');
    static var isDarkMode:Bool = darkMatcher.matches;
    static var colors:Dynamic = isDarkMode ? darkColors : lightColors;
    static var fontLoader:FontLoader = new FontLoader();
    static var fontPromise:Promise<Dynamic> = new Promise((resolve, reject) => {
        fontLoader.load('/examples/fonts/helvetiker_regular.typeface.json', resolve);
    });
    static var diagrams:Dynamic = {
        BoxGeometry: {
            ui: {
                width: { type: 'range', min: 1, max: 10, precision: 1 },
                height: { type: 'range', min: 1, max: 10, precision: 1 },
                depth: { type: 'range', min: 1, max: 10, precision: 1 },
                widthSegments: { type: 'range', min: 1, max: 10 },
                heightSegments: { type: 'range', min: 1, max: 10 },
                depthSegments: { type: 'range', min: 1, max: 10 }
            },
            create(width:Float = 8, height:Float = 8, depth:Float = 8):Geometry {
                return new BoxGeometry(width, height, depth);
            },
            create2(width:Float = 8, height:Float = 8, depth:Float = 8, widthSegments:Int = 4, heightSegments:Int = 4, depthSegments:Int = 4):Geometry {
                return new BoxGeometry(width, height, depth, widthSegments, heightSegments, depthSegments);
            }
        },
        // Add the rest of the geometry classes and methods here...
    };

    static function addLink(parent:HTMLDivElement, name:String, href:String = null):HTMLAnchorElement {
        // Implement the function...
    }

    static function addDeepLink(parent:HTMLDivElement, name:String, href:String = null):HTMLAnchorElement {
        // Implement the function...
    }

    static function addElem(parent:HTMLDivElement, type:String, className:String, text:String = null):HTMLElement {
        // Implement the function...
    }

    static function addDiv(parent:HTMLDivElement, className:String):HTMLDivElement {
        // Implement the function...
    }

    static function createPrimitiveDOM(base:HTMLDivElement):Void {
        // Implement the function...
    }

    static function createDiagram(base:HTMLDivElement):Void {
        // Implement the function...
    }

    static async function addGeometry(root:Object3D, info:Dynamic, args:Array<Dynamic> = []):Promise<Void> {
        // Implement the function...
    }

    static async function updateGeometry(root:Object3D, info:Dynamic, params:Dynamic):Promise<Void> {
        // Implement the function...
    }

    static var primitives:Dynamic = {};

    static async function createLiveImage(elem:HTMLElement, info:Dynamic, name:String):Promise<Void> {
        // Implement the function...
    }

    static function getValueElem(commentElem:HTMLSpanElement):HTMLElement {
        // Implement the function...
    }

    static function onAfterPrettify():Void {
        // Implement the function...
    }

    static function main():Void {
        // Implement the main function...
    }
}
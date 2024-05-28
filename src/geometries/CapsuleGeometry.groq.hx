package three.js.src.geometries;

import three.js.src.extras.core.Path;
import three.js.src.geometries.LatheGeometry;

class CapsuleGeometry extends LatheGeometry {
    
    public function new(radius:Float = 1, length:Float = 1, capSegments:Int = 4, radialSegments:Int = 8) {
        var path:Path = new Path();
        path.absarc(0, -length / 2, radius, Math.PI * 1.5, 0);
        path.absarc(0, length / 2, radius, 0, Math.PI * 0.5);
        
        super(path.getPoints(capSegments), radialSegments);
        
        this.type = 'CapsuleGeometry';
        
        this.parameters = {
            radius: radius,
            length: length,
            capSegments: capSegments,
            radialSegments: radialSegments
        };
    }
    
    public static function fromJSON(data:Dynamic):CapsuleGeometry {
        return new CapsuleGeometry(data.radius, data.length, data.capSegments, data.radialSegments);
    }
}

// Export the class
extern class CapsuleGeometry {}
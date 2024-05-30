package three.js.examples.jsm.environments;

import three.js.BoxGeometry;
import three.js.BackSide;
import three.js.Mesh;
import three.js.MeshLambertMaterial;
import three.js.MeshStandardMaterial;
import three.js.PointLight;
import three.js.Scene;

class DebugEnvironment extends Scene {
    public function new() {
        super();
        
        var geometry:BoxGeometry = new BoxGeometry();
        geometry.deleteAttribute('uv');
        var roomMaterial:MeshStandardMaterial = new MeshStandardMaterial({ metalness: 0, side: BackSide });
        var room:Mesh = new Mesh(geometry, roomMaterial);
        room.scale.setScalar(10);
        this.add(room);

        var mainLight:PointLight = new PointLight(0xffffff, 50, 0, 2);
        this.add(mainLight);

        var material1:MeshLambertMaterial = new MeshLambertMaterial({ color: 0xff0000, emissive: 0xffffff, emissiveIntensity: 10 });

        var light1:Mesh = new Mesh(geometry, material1);
        light1.position.set(-5, 2, 0);
        light1.scale.set(0.1, 1, 1);
        this.add(light1);

        var material2:MeshLambertMaterial = new MeshLambertMaterial({ color: 0x00ff00, emissive: 0xffffff, emissiveIntensity: 10 });

        var light2:Mesh = new Mesh(geometry, material2);
        light2.position.set(0, 5, 0);
        light2.scale.set(1, 0.1, 1);
        this.add(light2);

        var material3:MeshLambertMaterial = new MeshLambertMaterial({ color: 0x0000ff, emissive: 0xffffff, emissiveIntensity: 10 });

        var light3:Mesh = new Mesh(geometry, material3);
        light3.position.set(2, 1, 5);
        light3.scale.set(1.5, 2, 0.1);
        this.add(light3);
    }
}
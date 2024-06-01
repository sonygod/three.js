import three.core.Object3D;
import three.cameras.PerspectiveCamera;
import three.cameras.OrthographicCamera;
import three.lights.SpotLight;
import three.lights.PointLight;
import three.lights.HemisphereLight;
import three.lights.DirectionalLight;
import three.lights.AmbientLight;
import three.geometries.TubeGeometry;
import three.geometries.TorusKnotGeometry;
import three.geometries.TorusGeometry;
import three.geometries.TetrahedronGeometry;
import three.geometries.SphereGeometry;
import three.geometries.RingGeometry;
import three.geometries.PlaneGeometry;
import three.geometries.OctahedronGeometry;
import three.geometries.LatheGeometry;
import three.geometries.IcosahedronGeometry;
import three.geometries.DodecahedronGeometry;
import three.geometries.CylinderGeometry;
import three.geometries.CircleGeometry;
import three.geometries.CapsuleGeometry;
import three.geometries.BoxGeometry;
import three.materials.MeshStandardMaterial;
import three.objects.Mesh;
import three.objects.SpriteMaterial;
import three.objects.Sprite;
import three.math.Vector3;
import three.extras.curves.CatmullRomCurve3;
import three.Group;
//import { UIPanel, UIRow, UIHorizontalRule } from './libs/ui.js';
import ui.UIPanel;
import ui.UIRow;
import ui.UIHorizontalRule;

import commands.AddObjectCommand;

class MenubarAdd {

    public function new(editor) {

        //const strings = editor.strings;
        
        var container = new UIPanel();
        container.setClass('menu');

        var title = new UIPanel();
        title.setClass('title');
        title.setTextContent(editor.strings.getKey('menubar/add'));
        container.add(title);

        var options = new UIPanel();
        options.setClass('options');
        container.add(options);

        // Group

        var option = new UIRow();
        option.setClass('option');
        option.setTextContent(editor.strings.getKey('menubar/add/group'));
        option.onClick(function() {

            var mesh = new Group();
            mesh.name = 'Group';

            editor.execute(new AddObjectCommand(editor, cast mesh));

        });
        options.add(option);

        // Mesh

        var meshSubmenu = new UIPanel();
        meshSubmenu.setClass('options');
        //meshSubmenu.setPosition('fixed');
        meshSubmenu.setDisplay('none');

        var meshSubmenuTitle = new UIRow();
        meshSubmenuTitle.setTextContent(editor.strings.getKey('menubar/add/mesh'));
        meshSubmenuTitle.addClass('option');
        meshSubmenuTitle.addClass('submenu-title');
        meshSubmenuTitle.onMouseOver(function() {

            // TODO: Convert getBoundingClientRect from js
            // var { top, right } = meshSubmenuTitle.dom.getBoundingClientRect();
            // const { paddingTop } = getComputedStyle(this.dom);

            // meshSubmenu.setLeft(right + 'px');
            // meshSubmenu.setTop((top - parseFloat(paddingTop)) + 'px');
            // meshSubmenu.setStyle('max-height', ['calc( 100vh - ${top}px )']);
            meshSubmenu.setDisplay('block');

        });
        meshSubmenuTitle.onMouseOut(function() {

            meshSubmenu.setDisplay('none');

        });
        options.add(meshSubmenuTitle);
        meshSubmenuTitle.add(meshSubmenu);

        // Mesh / Box

        option = new UIRow();
        option.setClass('option');
        option.setTextContent(editor.strings.getKey('menubar/add/mesh/box'));
        option.onClick(function() {

            var geometry = new BoxGeometry(1, 1, 1, 1, 1, 1);
            var mesh = new Mesh(geometry, new MeshStandardMaterial());
            mesh.name = 'Box';

            editor.execute(new AddObjectCommand(editor, cast mesh));

        });
        meshSubmenu.add(option);

        // Mesh / Capsule

        option = new UIRow();
        option.setClass('option');
        option.setTextContent(editor.strings.getKey('menubar/add/mesh/capsule'));
        option.onClick(function() {

            var geometry = new CapsuleGeometry(1, 1, 4, 8);
            var material = new MeshStandardMaterial();
            var mesh = new Mesh(geometry, material);
            mesh.name = 'Capsule';

            editor.execute(new AddObjectCommand(editor, cast mesh));

        });
        meshSubmenu.add(option);

        // Mesh / Circle

        option = new UIRow();
        option.setClass('option');
        option.setTextContent(editor.strings.getKey('menubar/add/mesh/circle'));
        option.onClick(function() {

            var geometry = new CircleGeometry(1, 32, 0, Math.PI * 2);
            var mesh = new Mesh(geometry, new MeshStandardMaterial());
            mesh.name = 'Circle';

            editor.execute(new AddObjectCommand(editor, cast mesh));

        });
        meshSubmenu.add(option);

        // Mesh / Cylinder

        option = new UIRow();
        option.setClass('option');
        option.setTextContent(editor.strings.getKey('menubar/add/mesh/cylinder'));
        option.onClick(function() {

            var geometry = new CylinderGeometry(1, 1, 1, 32, 1, false, 0, Math.PI * 2);
            var mesh = new Mesh(geometry, new MeshStandardMaterial());
            mesh.name = 'Cylinder';

            editor.execute(new AddObjectCommand(editor, cast mesh));

        });
        meshSubmenu.add(option);

        // Mesh / Dodecahedron

        option = new UIRow();
        option.setClass('option');
        option.setTextContent(editor.strings.getKey('menubar/add/mesh/dodecahedron'));
        option.onClick(function() {

            var geometry = new DodecahedronGeometry(1, 0);
            var mesh = new Mesh(geometry, new MeshStandardMaterial());
            mesh.name = 'Dodecahedron';

            editor.execute(new AddObjectCommand(editor, cast mesh));

        });
        meshSubmenu.add(option);

        // Mesh / Icosahedron

        option = new UIRow();
        option.setClass('option');
        option.setTextContent(editor.strings.getKey('menubar/add/mesh/icosahedron'));
        option.onClick(function() {

            var geometry = new IcosahedronGeometry(1, 0);
            var mesh = new Mesh(geometry, new MeshStandardMaterial());
            mesh.name = 'Icosahedron';

            editor.execute(new AddObjectCommand(editor, cast mesh));

        });
        meshSubmenu.add(option);

        // Mesh / Lathe

        option = new UIRow();
        option.setClass('option');
        option.setTextContent(editor.strings.getKey('menubar/add/mesh/lathe'));
        option.onClick(function() {

            var geometry = new LatheGeometry();
            var mesh = new Mesh(geometry, new MeshStandardMaterial({side: Three.DoubleSide}));
            mesh.name = 'Lathe';

            editor.execute(new AddObjectCommand(editor, cast mesh));

        });
        meshSubmenu.add(option);

        // Mesh / Octahedron

        option = new UIRow();
        option.setClass('option');
        option.setTextContent(editor.strings.getKey('menubar/add/mesh/octahedron'));
        option.onClick(function() {

            var geometry = new OctahedronGeometry(1, 0);
            var mesh = new Mesh(geometry, new MeshStandardMaterial());
            mesh.name = 'Octahedron';

            editor.execute(new AddObjectCommand(editor, cast mesh));

        });
        meshSubmenu.add(option);

        // Mesh / Plane

        option = new UIRow();
        option.setClass('option');
        option.setTextContent(editor.strings.getKey('menubar/add/mesh/plane'));
        option.onClick(function() {

            var geometry = new PlaneGeometry(1, 1, 1, 1);
            var material = new MeshStandardMaterial();
            var mesh = new Mesh(geometry, material);
            mesh.name = 'Plane';

            editor.execute(new AddObjectCommand(editor, cast mesh));

        });
        meshSubmenu.add(option);

        // Mesh / Ring

        option = new UIRow();
        option.setClass('option');
        option.setTextContent(editor.strings.getKey('menubar/add/mesh/ring'));
        option.onClick(function() {

            var geometry = new RingGeometry(0.5, 1, 32, 1, 0, Math.PI * 2);
            var mesh = new Mesh(geometry, new MeshStandardMaterial());
            mesh.name = 'Ring';

            editor.execute(new AddObjectCommand(editor, cast mesh));

        });
        meshSubmenu.add(option);

        // Mesh / Sphere

        option = new UIRow();
        option.setClass('option');
        option.setTextContent(editor.strings.getKey('menubar/add/mesh/sphere'));
        option.onClick(function() {

            var geometry = new SphereGeometry(1, 32, 16, 0, Math.PI * 2, 0, Math.PI);
            var mesh = new Mesh(geometry, new MeshStandardMaterial());
            mesh.name = 'Sphere';

            editor.execute(new AddObjectCommand(editor, cast mesh));

        });
        meshSubmenu.add(option);

        // Mesh / Sprite

        option = new UIRow();
        option.setClass('option');
        option.setTextContent(editor.strings.getKey('menubar/add/mesh/sprite'));
        option.onClick(function() {

            var sprite = new Sprite(new SpriteMaterial());
            sprite.name = 'Sprite';

            editor.execute(new AddObjectCommand(editor, cast sprite));

        });
        meshSubmenu.add(option);

        // Mesh / Tetrahedron

        option = new UIRow();
        option.setClass('option');
        option.setTextContent(editor.strings.getKey('menubar/add/mesh/tetrahedron'));
        option.onClick(function() {

            var geometry = new TetrahedronGeometry(1, 0);
            var mesh = new Mesh(geometry, new MeshStandardMaterial());
            mesh.name = 'Tetrahedron';

            editor.execute(new AddObjectCommand(editor, cast mesh));

        });
        meshSubmenu.add(option);

        // Mesh / Torus

        option = new UIRow();
        option.setClass('option');
        option.setTextContent(editor.strings.getKey('menubar/add/mesh/torus'));
        option.onClick(function() {

            var geometry = new TorusGeometry(1, 0.4, 12, 48, Math.PI * 2);
            var mesh = new Mesh(geometry, new MeshStandardMaterial());
            mesh.name = 'Torus';

            editor.execute(new AddObjectCommand(editor, cast mesh));

        });
        meshSubmenu.add(option);

        // Mesh / TorusKnot

        option = new UIRow();
        option.setClass('option');
        option.setTextContent(editor.strings.getKey('menubar/add/mesh/torusknot'));
        option.onClick(function() {

            var geometry = new TorusKnotGeometry(1, 0.4, 64, 8, 2, 3);
            var mesh = new Mesh(geometry, new MeshStandardMaterial());
            mesh.name = 'TorusKnot';

            editor.execute(new AddObjectCommand(editor, cast mesh));

        });
        meshSubmenu.add(option);

        // Mesh / Tube

        option = new UIRow();
        option.setClass('option');
        option.setTextContent(editor.strings.getKey('menubar/add/mesh/tube'));
        option.onClick(function() {

            var path = new CatmullRomCurve3(
                [
                    new Vector3(2, 2, -2),
                    new Vector3(2, -2, -0.6666666666666667),
                    new Vector3(-2, -2, 0.6666666666666667),
                    new Vector3(-2, 2, 2)
                ]
            );

            var geometry = new TubeGeometry(path, 64, 1, 8, false);
            var mesh = new Mesh(geometry, new MeshStandardMaterial());
            mesh.name = 'Tube';

            editor.execute(new AddObjectCommand(editor, cast mesh));

        });
        meshSubmenu.add(option);

        // Light

        var lightSubmenu = new UIPanel();
        lightSubmenu.setClass('options');
        //lightSubmenu.setPosition('fixed');
        lightSubmenu.setDisplay('none');

        var lightSubmenuTitle = new UIRow();
        lightSubmenuTitle.setTextContent(editor.strings.getKey('menubar/add/light'));
        lightSubmenuTitle.addClass('option');
        lightSubmenuTitle.addClass('submenu-title');
        lightSubmenuTitle.onMouseOver(function() {

            // const { top, right } = lightSubmenuTitle.dom.getBoundingClientRect();
            // const { paddingTop } = getComputedStyle(this.dom);

            // lightSubmenu.setLeft(right + 'px');
            // lightSubmenu.setTop(top - parseFloat(paddingTop) + 'px');
            // lightSubmenu.setStyle('max-height', ['calc( 100vh - ${top}px )']);
            lightSubmenu.setDisplay('block');

        });
        lightSubmenuTitle.onMouseOut(function() {

            lightSubmenu.setDisplay('none');

        });
        options.add(lightSubmenuTitle);
        lightSubmenuTitle.add(lightSubmenu);


        // Light / Ambient

        option = new UIRow();
        option.setClass('option');
        option.setTextContent(editor.strings.getKey('menubar/add/light/ambient'));
        option.onClick(function() {

            var color = 0x222222;

            var light = new AmbientLight(color);
            light.name = 'AmbientLight';

            editor.execute(new AddObjectCommand(editor, cast light));

        });
        lightSubmenu.add(option);

        // Light / Directional

        option = new UIRow();
        option.setClass('option');
        option.setTextContent(editor.strings.getKey('menubar/add/light/directional'));
        option.onClick(function() {

            var color = 0xffffff;
            var intensity = 1;

            var light = new DirectionalLight(color, intensity);
            light.name = 'DirectionalLight';
            light.target.name = 'DirectionalLight Target';

            light.position.set(5, 10, 7.5);

            editor.execute(new AddObjectCommand(editor, cast light));

        });
        lightSubmenu.add(option);

        // Light / Hemisphere

        option = new UIRow();
        option.setClass('option');
        option.setTextContent(editor.strings.getKey('menubar/add/light/hemisphere'));
        option.onClick(function() {

            var skyColor = 0x00aaff;
            var groundColor = 0xffaa00;
            var intensity = 1;

            var light = new HemisphereLight(skyColor, groundColor, intensity);
            light.name = 'HemisphereLight';

            light.position.set(0, 10, 0);

            editor.execute(new AddObjectCommand(editor, cast light));

        });
        lightSubmenu.add(option);

        // Light / Point

        option = new UIRow();
        option.setClass('option');
        option.setTextContent(editor.strings.getKey('menubar/add/light/point'));
        option.onClick(function() {

            var color = 0xffffff;
            var intensity = 1;
            var distance = 0;

            var light = new PointLight(color, intensity, distance);
            light.name = 'PointLight';

            editor.execute(new AddObjectCommand(editor, cast light));

        });
        lightSubmenu.add(option);

        // Light / Spot

        option = new UIRow();
        option.setClass('option');
        option.setTextContent(editor.strings.getKey('menubar/add/light/spot'));
        option.onClick(function() {

            var color = 0xffffff;
            var intensity = 1;
            var distance = 0;
            var angle = Math.PI * 0.1;
            var penumbra = 0;

            var light = new SpotLight(color, intensity, distance, angle, penumbra);
            light.name = 'SpotLight';
            light.target.name = 'SpotLight Target';

            light.position.set(5, 10, 7.5);

            editor.execute(new AddObjectCommand(editor, cast light));

        });
        lightSubmenu.add(option);

        // Camera

        var cameraSubmenu = new UIPanel();
        cameraSubmenu.setClass('options');
        //cameraSubmenu.setPosition('fixed');
        cameraSubmenu.setDisplay('none');

        var cameraSubmenuTitle = new UIRow();
        cameraSubmenuTitle.setTextContent(editor.strings.getKey('menubar/add/camera'));
        cameraSubmenuTitle.addClass('option');
        cameraSubmenuTitle.addClass('submenu-title');
        cameraSubmenuTitle.onMouseOver(function() {

            // const { top, right } = cameraSubmenuTitle.dom.getBoundingClientRect();
            // const { paddingTop } = getComputedStyle(this.dom);

            // cameraSubmenu.setLeft(right + 'px');
            // cameraSubmenu.setTop(top - parseFloat(paddingTop) + 'px');
            // cameraSubmenu.setStyle('max-height', ['calc( 100vh - ${top}px )']);
            cameraSubmenu.setDisplay('block');

        });
        cameraSubmenuTitle.onMouseOut(function() {

            cameraSubmenu.setDisplay('none');

        });
        options.add(cameraSubmenuTitle);
        cameraSubmenuTitle.add(cameraSubmenu);

        // Camera / Orthographic

        option = new UIRow();
        option.setClass('option');
        option.setTextContent(editor.strings.getKey('menubar/add/camera/orthographic'));
        option.onClick(function() {

            var aspect = editor.camera.aspect;
            var camera = new OrthographicCamera(-aspect, aspect);
            camera.name = 'OrthographicCamera';

            editor.execute(new AddObjectCommand(editor, cast camera));

        });
        cameraSubmenu.add(option);

        // Camera / Perspective

        option = new UIRow();
        option.setClass('option');
        option.setTextContent(editor.strings.getKey('menubar/add/camera/perspective'));
        option.onClick(function() {

            var camera = new PerspectiveCamera();
            camera.name = 'PerspectiveCamera';

            editor.execute(new AddObjectCommand(editor, cast camera));

        });
        cameraSubmenu.add(option);

        return container;

    }

}
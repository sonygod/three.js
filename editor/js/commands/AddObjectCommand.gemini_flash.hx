package ;

import three.core.Object3D;
import three.loaders.ObjectLoader;

class AddObjectCommand extends Command {

    public var object : Object3D;

    public function new( editor : Editor, object : Object3D = null ) {

        super( editor );

        this.type = "AddObjectCommand";

        this.object = object;

        if ( object != null ) {

            this.name = editor.strings.getKey( "command/AddObject" ) + ": " + object.name;

        }

    }

    override public function execute() : Void {

        editor.addObject( object );
        editor.select( object );

    }

    override public function undo() : Void {

        editor.removeObject( object );
        editor.deselect();

    }

    override public function toJSON() : Dynamic {

        var output = super.toJSON();

        Reflect.setField(output, "object", object.toJSON());

        return output;

    }

    override public function fromJSON( json : Dynamic ) : Void {

        super.fromJSON( json );

        this.object = cast editor.objectByUuid( Reflect.field(Reflect.field(json, "object"), "uuid") );

        if ( object == null ) {

            var loader = new ObjectLoader();
            this.object = cast loader.parse( Reflect.field(json, "object") );

        }

    }

}
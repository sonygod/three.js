package three.js.examples.jsm.loaders.lwo;

import haxe.io.BytesInput;
import haxe.io.BytesOutput;

class LWO3Parser {

    public var IFF:IffParser;

    public function new(IFF:IffParser) {
        this.IFF = IFF;
    }

    public function parseBlock():Void {
        IFF.debugger.offset = IFF.reader.position;
        IFF.debugger.closeForms();

        var blockID:String = IFF.reader.getString(4);
        var length:Int = IFF.reader.readInt32();

        IFF.debugger.dataOffset = IFF.reader.position;
        IFF.debugger.length = length;

        switch (blockID) {
            case 'FORM': // form blocks may consist of sub-chunks or sub-forms
                IFF.parseForm(length);
                break;

            // SKIPPED CHUNKS
            // MISC skipped
            case 'ICON': // Thumbnail Icon Image
            case 'VMPA': // Vertex Map Parameter
            case 'BBOX': // bounding box
            // case 'VMMD':
            // case 'VTYP':

            // normal maps can be specified, normally on models imported from other applications. Currently ignored
            case 'NORM':

            // ENVL FORM skipped
            case 'PRE ': // Pre-loop behavior for the keyframe
            case 'POST': // Post-loop behavior for the keyframe
            case 'KEY ':
            case 'SPAN':

            // CLIP FORM skipped
            case 'TIME':
            case 'CLRS':
            case 'CLRA':
            case 'FILT':
            case 'DITH':
            case 'CONT':
            case 'BRIT':
            case 'SATR':
            case 'HUE ':
            case 'GAMM':
            case 'NEGA':
            case 'IFLT':
            case 'PFLT':

            // Image Map Layer skipped
            case 'PROJ':
            case 'AXIS':
            case 'AAST':
            case 'PIXB':
            case 'STCK':

            // Procedural Textures skipped
            case 'VALU':

            // Gradient Textures skipped
            case 'PNAM':
            case 'INAM':
            case 'GRST':
            case 'GREN':
            case 'GRPT':
            case 'FKEY':
            case 'IKEY':

            // Texture Mapping Form skipped
            case 'CSYS':

                // Surface CHUNKs skipped
            case 'OPAQ': // top level 'opacity' checkbox
            case 'CMAP': // clip map

            // Surface node CHUNKS skipped
            // These mainly specify the node editor setup in LW
            case 'NLOC':
            case 'NZOM':
            case 'NVER':
            case 'NSRV':
            case 'NCRD':
            case 'NMOD':
            case 'NSEL':
            case 'NPRW':
            case 'NPLA':
            case 'VERS':
            case 'ENUM':
            case 'TAG ':

            // Car Material CHUNKS
            case 'CGMD':
            case 'CGTY':
            case 'CGST':
            case 'CGEN':
            case 'CGTS':
            case 'CGTE':
            case 'OSMP':
            case 'OMDE':
            case 'OUTR':
            case 'FLAG':

            case 'TRNL':
            case 'SHRP':
            case 'RFOP':
            case 'RSAN':
            case 'TROP':
            case 'RBLR':
            case 'TBLR':
            case 'CLRH':
            case 'CLRF':
            case 'ADTR':
            case 'GLOW':
            case 'LINE':
            case 'ALPH':
            case 'VCOL':
            case 'ENAB':
                IFF.debugger.skipped = true;
                IFF.reader.skip(length);
                break;

            // Texture node chunks (not in spec)
            case 'IPIX': // usePixelBlending
            case 'IMIP': // useMipMaps
            case 'IMOD': // imageBlendingMode
            case 'AMOD': // unknown
            case 'IINV': // imageInvertAlpha
            case 'INCR': // imageInvertColor
            case 'IAXS': // imageAxis ( for non-UV maps)
            case 'IFOT': // imageFallofType
            case 'ITIM': // timing for animated textures
            case 'IWRL':
            case 'IUTI':
            case 'IINX':
            case 'IINY':
            case 'IINZ':
            case 'IREF': // possibly a VX for reused texture nodes
                if (length == 4) IFF.currentNode.set(blockID, IFF.reader.readInt32());
                else IFF.reader.skip(length);
                break;

            case 'OTAG':
                IFF.parseObjectTag();
                break;

            case 'LAYR':
                IFF.parseLayer(length);
                break;

            case 'PNTS':
                IFF.parsePoints(length);
                break;

            case 'VMAP':
                IFF.parseVertexMapping(length);
                break;

            case 'POLS':
                IFF.parsePolygonList(length);
                break;

            case 'TAGS':
                IFF.parseTagStrings(length);
                break;

            case 'PTAG':
                IFF.parsePolygonTagMapping(length);
                break;

            case 'VMAD':
                IFF.parseVertexMapping(length, true);
                break;

            // Misc CHUNKS
            case 'DESC': // Description Line
                IFF.currentForm.description = IFF.reader.getString();
                break;

            case 'TEXT':
            case 'CMNT':
            case 'NCOM':
                IFF.currentForm.comment = IFF.reader.getString();
                break;

            // Envelope Form
            case 'NAME':
                IFF.currentForm.channelName = IFF.reader.getString();
                break;

            // Image Map Layer
            case 'WRAP':
                IFF.currentForm.wrap = { w: IFF.reader.readInt16(), h: IFF.reader.readInt16() };
                break;

            case 'IMAG':
                var index:Int = IFF.reader.getVariableLengthIndex();
                IFF.currentForm.imageIndex = index;
                break;

            // Texture Mapping Form
            case 'OREF':
                IFF.currentForm.referenceObject = IFF.reader.getString();
                break;

            case 'ROID':
                IFF.currentForm.referenceObjectID = IFF.reader.readInt32();
                break;

            // Surface Blocks
            case 'SSHN':
                IFF.currentSurface.surfaceShaderName = IFF.reader.getString();
                break;

            case 'AOVN':
                IFF.currentSurface.surfaceCustomAOVName = IFF.reader.getString();
                break;

            // Nodal Blocks
            case 'NSTA':
                IFF.currentForm.disabled = IFF.reader.readInt16();
                break;

            case 'NRNM':
                IFF.currentForm.realName = IFF.reader.getString();
                break;

            case 'NNME':
                IFF.currentForm.refName = IFF.reader.getString();
                IFF.currentSurface.nodes[IFF.currentForm.refName] = IFF.currentForm;
                break;

            // Nodal Blocks : connections
            case 'INME':
                if (!IFF.currentForm.nodeName) IFF.currentForm.nodeName = [];
                IFF.currentForm.nodeName.push(IFF.reader.getString());
                break;

            case 'IINN':
                if (!IFF.currentForm.inputNodeName) IFF.currentForm.inputNodeName = [];
                IFF.currentForm.inputNodeName.push(IFF.reader.getString());
                break;

            case 'IINM':
                if (!IFF.currentForm.inputName) IFF.currentForm.inputName = [];
                IFF.currentForm.inputName.push(IFF.reader.getString());
                break;

            case 'IONM':
                if (!IFF.currentForm.inputOutputName) IFF.currentForm.inputOutputName = [];
                IFF.currentForm.inputOutputName.push(IFF.reader.getString());
                break;

            case 'FNAM':
                IFF.currentForm.fileName = IFF.reader.getString();
                break;

            case 'CHAN': // NOTE: ENVL Forms may also have CHAN chunk, however ENVL is currently ignored
                if (length == 4) IFF.currentForm.textureChannel = IFF.reader.getIDTag();
                else IFF.reader.skip(length);
                break;

            // LWO2 Spec chunks: these are needed since the SURF FORMs are often in LWO2 format
            case 'SMAN':
                var maxSmoothingAngle:Float = IFF.reader.readFloat32();
                IFF.currentSurface.attributes.smooth = (maxSmoothingAngle < 0) ? false : true;
                break;

            // LWO2: Basic Surface Parameters
            case 'COLR':
                IFF.currentSurface.attributes.Color = { value: IFF.reader.getFloat32Array(3) };
                IFF.reader.skip(2); // VX: envelope
                break;

            case 'LUMI':
                IFF.currentSurface.attributes.Luminosity = { value: IFF.reader.readFloat32() };
                IFF.reader.skip(2);
                break;

            case 'SPEC':
                IFF.currentSurface.attributes.Specular = { value: IFF.reader.readFloat32() };
                IFF.reader.skip(2);
                break;

            case 'DIFF':
                IFF.currentSurface.attributes.Diffuse = { value: IFF.reader.readFloat32() };
                IFF.reader.skip(2);
                break;

            case 'REFL':
                IFF.currentSurface.attributes.Reflection = { value: IFF.reader.readFloat32() };
                IFF.reader.skip(2);
                break;

            case 'GLOS':
                IFF.currentSurface.attributes.Glossiness = { value: IFF.reader.readFloat32() };
                IFF.reader.skip(2);
                break;

            case 'TRAN':
                IFF.currentSurface.attributes.opacity = IFF.reader.readFloat32();
                IFF.reader.skip(2);
                break;

            case 'BUMP':
                IFF.currentSurface.attributes.bumpStrength = IFF.reader.readFloat32();
                IFF.reader.skip(2);
                break;

            case 'SIDE':
                IFF.currentSurface.attributes.side = IFF.reader.readInt16();
                break;

            case 'RIMG':
                IFF.currentSurface.attributes.reflectionMap = IFF.reader.getVariableLengthIndex();
                break;

            case 'RIND':
                IFF.currentSurface.attributes.refractiveIndex = IFF.reader.readFloat32();
                IFF.reader.skip(2);
                break;

            case 'TIMG':
                IFF.currentSurface.attributes.refractionMap = IFF.reader.getVariableLengthIndex();
                break;

            case 'IMAP':
                IFF.currentSurface.attributes.imageMapIndex = IFF.reader.readInt32();
                break;

            case 'IUVI': // uv channel name
                IFF.currentNode.UVChannel = IFF.reader.getString(length);
                break;

            case 'IUTL': // widthWrappingMode: 0 = Reset, 1 = Repeat, 2 = Mirror, 3 = Edge
                IFF.currentNode.widthWrappingMode = IFF.reader.readInt32();
                break;
            case 'IVTL': // heightWrappingMode
                IFF.currentNode.heightWrappingMode = IFF.reader.readInt32();
                break;

            default:
                IFF.parseUnknownCHUNK(blockID, length);

        }

        if (blockID != 'FORM') {

            IFF.debugger.node = 1;
            IFF.debugger.nodeID = blockID;
            IFF.debugger.log();

        }

        if (IFF.reader.position >= IFF.currentFormEnd) {

            IFF.currentForm = IFF.parentForm;

        }

    }

}
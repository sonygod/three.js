import haxe.xml.*;
import js.Browser;
import js.html.HTMLElement;
import js.html.Window;
import js.html.XMLHttpRequest;
import js.Node;
import js.html.Document;
import js.html.HTMLImageElement;
import js.html.HTMLCanvasElement;
import js.html.ImageData;
import js.html.CanvasRenderingContext2D;
import js.html.CanvasGradient;
import js.html.CanvasPattern;
import js.html.CanvasRenderingContext2D.LineCap;
import js.html.CanvasRenderingContext2D.LineJoin;
import js.html.CanvasRenderingContext2D.TextAlign;
import js.html.CanvasRenderingContext2D.TextBaseline;
import js.html.CanvasRenderingContext2D.CompositeOperation;
import js.html.CanvasRenderingContext2D.Repetition;
import js.html.CanvasRenderingContext2D.ImageSmoothingQuality;
import js.html.CanvasRenderingContext2D.Blend;
import js.html.CanvasGradient.Type;
import js.html.CanvasPattern.Repeat;
import js.html.Window.Location;
import js.html.Window.XMLHttpRequest;
import js.html.Window.Image;
import js.html.Window.performance;
import js.html.Window.setTimeout;
import js.html.Window.setInterval;
import js.html.Window.clearInterval;
import js.html.Window.clearTimeout;
import js.html.Window.requestAnimationFrame;
import js.html.Window.cancelAnimationFrame;
import js.html.Window.getComputedStyle;
import js.html.CanvasElement;
import js.html.CanvasRenderingContext2D.ImageInterpolation;
import js.html.WebGLRenderingContext;
import js.html.WebGLProgram;
import js.html.WebGLShader;
import js.html.WebGLActiveInfo;
import js.html.WebGLBuffer;
import js.html.WebGLFramebuffer;
import js.html.WebGLRenderbuffer;
import js.html.WebGLTexture;
import js.html.WebGLUniformLocation;
import js.html.WebGLShaderPrecisionFormat;
import js.html.WebGLVertexAttribArray;
import js.html.WebGLCompressedTexture;
import js.html.WebGLQuery;
import js.html.WebGLSampler;
import js.html.WebGLTransformFeedback;
import js.html.WebGLVertexArrayObject;
import js.html.WebGL2RenderingContext;
import js.html.WebGLRenderingContextBase;
import js.html.WebGLRenderingContextBase.CullFaceMode;
import js.html.WebGLRenderingContextBase.BlendEquationMode;
import js.html.WebGLRenderingContextBase.BlendFuncFactor;
import js.html.WebGLRenderingContextBase.BlendEquationSeparateFactor;
import js.html.WebGLRenderingContextBase.BlendFuncSeparateFactor;
import js.html.WebGLRenderingContextBase.ColorMask;
import js.html.WebGLRenderingContextBase.DepthFunction;
import js.html.WebGLRenderingContextBase.FrontFaceDirection;
import js.html.WebGLRenderingContextBase.ImplementationColorFormat;
import js.html.WebGLRenderingContextBase.ImplementationColorReadFormat;
import js.html.WebGLRenderingContextBase.ImplementationColorRenderableType;
import js.html.WebGLRenderingContextBase.ImplementationShaderType;
import js.html.WebGLRenderingContextBase.ImplementationTextureFormat;
import js.html.WebGLRenderingContextBase.ImplementationTextureUnit;
import js.html.WebGLRenderingContextBase.ImplementationTextureWrapMode;
import js.html.WebGLRenderingContextBase.ImplementationVertexAttributeType;
import js.html.WebGLRenderingContextBase.ImplementationVertexBufferType;
import js.html.WebGLRenderingContextBase.PixelStoreParameter;
import js.html.WebGLRenderingContextBase.ProgramParameter;
import js.html.WebGLRenderingContextBase.RenderbufferParameter;
import js.html.WebGLRenderingContextBase.ShaderParameterType;
import js.html.WebGLRenderingContextBase.ShaderType;
import js.html.WebGLRenderingContextBase.StencilFunction;
import js.html.WebGLRenderingContextBase.StencilOperation;
import js.html.WebGLRenderingContextBase.TexParameter;
import js.html.WebGLRenderingContextBase.TexUnit;
import js.html.WebGLRenderingContextBase.TextureMagFilter;
import js.html.WebGLRenderingContextBase.TextureMinFilter;
import js.html.WebGLRenderingContextBase.TextureWrapMode;
import js.html.WebGLRenderingContextBase.UniformParameterType;
import js.html.WebGLRenderingContextBase.VertexAttribPointerType;
import js.html.WebGLRenderingContextBase.VertexAttribType;
import js.html.WebGLRenderingContextBase.DrawMode;
import js.html.WebGLRenderingContextBase.FramebufferAttachment;
import js.html.WebGLRenderingContextBase.FramebufferStatus;
import js.html.WebGLRenderingContextBase.IndexFormat;
import js.html.WebGLRenderingContextBase.PixelFormat;
import js.html.WebGLRenderingContextBase.PixelType;
import js.html.WebGLRenderingContextBase.ImplementationEnum;
import js.html.WebGLRenderingContextBase.ImplementationSizedFormat;
import js.html.WebGLRenderingContextBase.ImplementationUnsignedType;
import js.html.WebGLRenderingContextBase.ImplementationIntegerType;
import js.html.WebGLRenderingContextBase.ImplementationFormatParameter;
import js.html.WebGLRenderingContextBase.ImplementationRenderbufferFormat;
import js.html.WebGLRenderingContextBase.ImplementationShaderPrecisionFormat;
import js.html.WebGLRenderingContextBase.ImplementationTextureFormat;
import js.html.WebGLRenderingContextBase.ImplementationTextureUnit;
import js.html.WebGLRenderingContextBase.ImplementationTextureWrapMode;
import js.html.WebGLRenderingContextBase.ImplementationVertexAttributeType;
import js.html.WebGLRenderingContextBase.ImplementationVertexBufferType;
import js.html.WebGLRenderingContextBase.ImplementationVertexFormat;
import js.html.WebGLRenderingContextBase.ImplementationVertexPointerType;
import js.html.WebGLRenderingContextBase.ImplementationVertexType;
import js.html.WebGLRenderingContextBase.ImplementationBufferBit;
import js.html.WebGLRenderingContextBase.ImplementationBufferParameter;
import js.html.WebGLRenderingContextBase.ImplementationFramebufferAttachment;
import js.html.WebGLRenderingContextBase.ImplementationFramebufferStatus;
import js.html.WebGLRenderingContextBase.ImplementationRenderbufferParameter;
import js.html.WebGLRenderingContextBase.ImplementationStringName;
import js.html.WebGLRenderingContextBase.ImplementationStringName2;
import js.html.WebGLRenderingContextBase.ImplementationStringName3;
import js.html.WebGLRenderingContextBase.ImplementationStringName4;
import js.html.WebGLRenderingContextBase.ImplementationStringName5;
import js.html.WebGLRenderingContextBase.ImplementationStringName6;
import js.html.WebGLRenderingContextBase.ImplementationStringName7;
import js.html.WebGLRenderingContextBase.ImplementationStringName8;
import js.html.WebGLRenderingContextBase.ImplementationStringName9;
import js.html.WebGLRenderingContextBase.ImplementationStringName10;
import js.html.WebGLRenderingContextBase.ImplementationStringName11;
import js.html.WebGLRenderingContextBase.ImplementationStringName12;
import js.html.WebGLRenderingContextBase.ImplementationStringName13;
import js.html.WebGLRenderingContextBase.ImplementationStringName14;
import js.html.WebGLRenderingContextBase.ImplementationStringName15;
import js.html.WebGLRenderingContextBase.ImplementationStringName16;
import js.html.WebGLRenderingContextBase.ImplementationStringName17;
import js.html.WebGLRenderingContextBase.ImplementationStringName18;
import js.html.WebGLRenderingContextBase.ImplementationStringName19;
import js.html.WebGLRenderingContextBase.ImplementationStringName20;
import js.html.WebGLRenderingContextBase.ImplementationStringName21;
import js.html.WebGLRenderingContextBase.ImplementationStringName22;
import js.html.WebGLRenderingContextBase.ImplementationStringName23;
import js.html.WebGLRenderingContextBase.ImplementationStringName24;
import js.html.WebGLRenderingContextBase.ImplementationStringName25;
import js.html.WebGLRenderingContextBase.ImplementationStringName26;
import js.html.WebGLRenderingContextBase.ImplementationStringName27;
import js.html.WebGLRenderingContextBase.ImplementationStringName28;
import js.html.WebGLRenderingContextBase.ImplementationStringName29;
import js.html.WebGLRenderingContextBase.ImplementationStringName30;
import js.html.WebGLRenderingContextBase.ImplementationStringName31;
import js.html.WebGLRenderingContextBase.ImplementationStringName32;
import js.html.WebGLRenderingContextBase.ImplementationStringName33;
import js.html.WebGLRenderingContextBase.ImplementationStringName34;
import js.html.WebGLRenderingContextBase.ImplementationStringName35;
import js.html.WebGLRenderingContextBase.ImplementationStringName36;
import js.html.WebGLRenderingContextBase.ImplementationStringName37;
import js.html.WebGLRenderingContextBase.ImplementationStringName38;
import js.html.WebGLRenderingContextBase.ImplementationStringName39;
import js.html.WebGLRenderingContextBase.ImplementationStringName40;
import js.html.WebGLRenderingContextBase.ImplementationStringName41;
import js.html.WebGLRenderingContextBase.ImplementationStringName42;
import js.html.WebGLRenderingContextBase.ImplementationStringName43;
import js.html.WebGLRenderingContextBase.ImplementationStringName44;
import js.html.WebGLRenderingContextBase.ImplementationStringName45;
import js.html.WebGLRenderingContextBase.ImplementationStringName46;
import js.html.WebGLRenderingContextBase.ImplementationStringName47;
import js.html.WebGLRenderingContextBase.ImplementationStringName48;
import js.html.WebGLRenderingContextBase.ImplementationStringName49;
import js.html.WebGLRenderingContextBase.ImplementationStringName50;
import js.html.WebGLRenderingContextBase.ImplementationStringName51;
import js.html.WebGLRenderingContextBase.ImplementationStringName52;
import js.html.WebGLRenderingContextBase.ImplementationStringName53;
import js.html.WebGLRenderingContextBase.ImplementationStringName54;
import js.html.WebGLRenderingContextBase.ImplementationStringName55;
import js.html.WebGLRenderingContextBase.ImplementationStringName56;
import js.html.WebGLRenderingContextBase.ImplementationStringName57;
import js.html.WebGLRenderingContextBase.ImplementationStringName58;
import js.html.WebGLRenderingContextBase.ImplementationStringName59;
import js.html.WebGLRenderingContextBase.ImplementationStringName60;
import js.html.WebGLRenderingContextBase.ImplementationStringName61;
import js.html.WebGLRenderingContextBase.ImplementationStringName62;
import js.html.WebGLRenderingContextBase.ImplementationStringName63;
import js.html.WebGLRenderingContextBase.ImplementationStringName64;
import js.html.WebGLRenderingContextBase.ImplementationStringName65;
import js.html.WebGLRenderingContextBase.ImplementationStringName66;
import js.html.WebGLRenderingContextBase.ImplementationStringName67;
import js.html.WebGLRenderingContextBase.ImplementationStringName68;
import js.html.WebGLRenderingContextBase.ImplementationStringName69;
import js.html.WebGLRenderingContextBase.ImplementationStringName70;
import js.html.WebGLRenderingContextBase.ImplementationStringName71;
import js.html.WebGLRenderingContextBase.ImplementationStringName72;
import js.html.WebGLRenderingContextBase.ImplementationStringName73;
import js.html.WebGLRenderingContextBase.ImplementationStringName74;
import js.html.WebGLRenderingContextBase.ImplementationStringName75;
import js.html.WebGLRenderingContextBase.ImplementationStringName76;
import js.html.WebGLRenderingContextBase.ImplementationStringName77;
import js.html.WebGLRenderingContextBase.ImplementationStringName78;
import js.html.WebGLRenderingContextBase.ImplementationStringName79;
import js.html.WebGLRenderingContextBase.ImplementationStringName80;
import js.html.WebGLRenderingContextBase.ImplementationStringName81;
import js.html.WebGLRenderingContextBase.ImplementationStringName82;
import js.html.WebGLRenderingContextBase.ImplementationStringName83;
import js.html.WebGLRenderingContextBase.ImplementationStringName84;
import js.html.WebGLRenderingContextBase.ImplementationStringName85;
import js.html.WebGLRenderingContextBase.ImplementationStringName86;
import js.html.WebGLRenderingContextBase.ImplementationStringName87;
import js.html.WebGLRenderingContextBase.ImplementationStringName88;
import js.html.WebGLRenderingContextBase.ImplementationStringName89;
import js.html.WebGLRenderingContextBase.ImplementationStringName90;
import js.html.WebGLRenderingContextBase.ImplementationStringName91;
import js.html.WebGLRenderingContextBase.ImplementationStringName92;
import js.html.WebGLRenderingContextBase.ImplementationStringName93;
import js.html.WebGLRenderingContextBase.ImplementationStringName94;
import js.html.WebGLRenderingContextBase.ImplementationStringName95;
import js.html.WebGLRenderingContextBase.ImplementationStringName96;
import js.html.WebGLRenderingContextBase.ImplementationStringName97;
import js.html.WebGLRenderingContextBase.ImplementationStringName98;
import js.html.WebGLRenderingContextBase.ImplementationStringName99;
import js.html.WebGLRenderingContextBase.ImplementationStringName100;
import js.html.WebGLRenderingContextBase.ImplementationStringName101;
import js.html.WebGLRenderingContextBase.ImplementationStringName102;
import js.html.WebGLRenderingContextBase.ImplementationStringName103;
import js.html.WebGLRenderingContextBase.ImplementationStringName104;
import js.html.WebGLRenderingContextBase.ImplementationStringName105;
import js.html.WebGLRenderingContextBase.ImplementationStringName106;
import js.html.WebGLRenderingContextBase.ImplementationStringName107;
import js.html.WebGLRenderingContextBase.ImplementationStringName108;
import js.html.WebGLRenderingContextBase.ImplementationStringName109;
import js.html.WebGLRenderingContextBase.ImplementationStringName110;
import js.html.WebGLRenderingContextBase.ImplementationStringName111;
import js.html.WebGLRenderingContextBase.ImplementationStringName112;
import js.html.WebGLRenderingContextBase.ImplementationStringName113;
import js.html.WebGLRenderingContextBase.ImplementationStringName114;
import js.html.WebGLRenderingContextBase.ImplementationStringName115;
import js.html.WebGLRenderingContextBase.ImplementationStringName116;
import js.html.WebGLRenderingContextBase.ImplementationStringName117;
import js.html.WebGLRenderingContextBase.ImplementationStringName118;
import js.html.WebGLRenderingContextBase.ImplementationStringName119;
import js.html.WebGLRenderingContextBase.ImplementationStringName120;
import js.html.WebGLRenderingContextBase.ImplementationStringName121;
import js.html.WebGLRenderingContextBase.ImplementationStringName122;
import js.html.WebGLRenderingContextBase.ImplementationStringName123;
import js.html.WebGLRenderingContextBase.ImplementationStringName124;
import js.html.WebGLRenderingContextBase.ImplementationStringName125;
import js.html.WebGLRenderingContextBase.ImplementationStringName126;
import js.html.WebGLRenderingContextBase.ImplementationStringName127;
import js.html.WebGLRenderingContextBase.ImplementationStringName128;
import js.html.WebGLRenderingContextBase.ImplementationStringName129;
import js.html.WebGLRenderingContextBase.ImplementationStringName130;
import js.html.WebGLRenderingContextBase.ImplementationStringName131;
import js.html.WebGLRenderingContextBase.ImplementationStringName132;
import js.html.WebGLRenderingContextBase.ImplementationStringName133;
import js.html.WebGLRenderingContextBase.ImplementationStringName134;
import js.html.WebGLRenderingContextBase.ImplementationStringName135;
import js.html.WebGLRenderingContextBase.ImplementationStringName136;
import js.html.WebGLRenderingContextBase.ImplementationStringName137;
import js.html.WebGLRenderingContextBase.ImplementationStringName138;
import js.html.WebGLRenderingContextBase.ImplementationStringName139;
import js.html.WebGLRenderingContextBase.ImplementationStringName140;
import js.html.WebGLRenderingContextBase.ImplementationStringName141;
import js.html.WebGLRenderingContextBase.ImplementationStringName142;
import js.html.WebGLRenderingContextBase.ImplementationStringName143;
import js.html.WebGLRenderingContextBase.ImplementationStringName144;
import js.html.WebGLRenderingContextBase.ImplementationStringName145;
import js.html.WebGLRenderingContextBase.ImplementationStringName146;
import js.html.WebGLRenderingContextBase.ImplementationStringName147;
import js.html.WebGLRenderingContextBase.ImplementationStringName148
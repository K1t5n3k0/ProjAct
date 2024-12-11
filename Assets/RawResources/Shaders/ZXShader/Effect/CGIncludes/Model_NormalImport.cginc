CBUFFER_START(UnityPerMaterial)
//Main
sampler2D _MainTex;
float4 _MainTex_ST;

uniform half4 _COLOR;
uniform half  _Saturation;
uniform half _MainRotation;

uniform half4 _AlphaChannel;
uniform half4  _UVOffset;
uniform half4  _UV2Offset;

//Normal
uniform sampler2D _BumpMap;
uniform float4 _BumpMap_ST;

uniform half _BumpRotation; 
uniform half _BumpScale;

uniform float4 _LightDir;
uniform half4 _LightCol;
uniform half4 _Specular;
uniform half _Gloss;
uniform half _SetVertexColor;

//Mask
uniform sampler2D   _MaskTex;
uniform float4      _MaskTex_ST;
uniform half4      _MaskChannel;
uniform half        _MaskRotation;
//Dissolve
uniform sampler2D   _Mask2Tex;
uniform float4      _Mask2Tex_ST;
uniform half      _Mask2Strength;
uniform half       _MaskStrength;

//Noise
uniform sampler2D   _NoiseTex;
uniform float4      _NoiseTex_ST;
uniform half4       _NoiseParam;
CBUFFER_END
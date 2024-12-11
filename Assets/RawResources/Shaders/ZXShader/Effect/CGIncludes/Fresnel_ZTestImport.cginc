CBUFFER_START(UnityPerMaterial)
float4 _ColorIN;
float4 _ColorOut;
float4 _COLOR;
half _EmissiveMult;
half _Fresnel;
half _OpacityMult;
half _AlphaClipValue;

//Mask
uniform sampler2D   _MaskTex;
uniform float4      _MaskTex_ST;
uniform half        _MaskRotation;
uniform half4      _MaskChannel;
uniform half4       _UVOffset;

uniform sampler2D   _Mask2Tex;
uniform float4      _Mask2Tex_ST;
uniform half      _Mask2Strength;

uniform half       _MaskStrength;
CBUFFER_END

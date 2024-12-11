CBUFFER_START(UnityPerMaterial)
    //Main Texture
    uniform fixed4      _COLOR;
    uniform half        _ColorIntensity;
    uniform sampler2D   _MainTex;
    uniform float4      _MainTex_ST;
    uniform float       _UVMaskWidth;
    uniform half        _UVMaskDirection;
    uniform half4       _UVMaskDirection_DirRota;

    uniform fixed       _Saturation;
    uniform fixed       _HueShift;
    uniform fixed4      _AlphaChannel;
    uniform fixed4      _MainTexRepeat;

    uniform half4       _UVOffset;
    uniform half        _SetVertexColor;
    //Rotation
    uniform half        _MainRotation;
    uniform half4        _MainRotation_Rota;
    uniform half        _MaskRotation;
    uniform half4        _MaskRotation_Rota;
    uniform half        _Mask2Rotation;
    uniform half4        _Mask2Rotation_Rota;

    //Mask
    uniform sampler2D   _MaskTex;
    uniform float4      _MaskTex_ST;
    uniform fixed4      _MaskChannel;
    uniform fixed4      _MaskRepeat;
    uniform fixed       _MaskStrength;
    uniform sampler2D   _Mask2Tex;
    uniform float4      _Mask2Tex_ST;
    uniform fixed4      _Mask2Channel;
    uniform fixed4      _Mask2Repeat;
    uniform fixed       _Mask2Strength;

    //Dissolve
    uniform fixed4      _BorderColor;
    uniform fixed       _BorderOffset;
    uniform fixed       _BorderWidth;
    uniform half        _DissolveDirection;
    uniform half4        _DissolveDirection_DirRota;
    uniform fixed       _DissolveWidth;
    uniform fixed4      _DissolveChannel;
    uniform fixed4      _UVOffset2;

    //Noise
    uniform sampler2D   _NoiseTex;
    uniform float4      _NoiseTex_ST;
    uniform half4       _NoiseParam;
    uniform half4       _NoiseCustomRepeat;
    uniform fixed4      _NoiseChannel;
    uniform fixed4      _NoiseRepeat;
    uniform fixed4      _NoiseMix;

    //软粒子
    uniform float       _SoftOverGround;
    uniform float       _UseSoftOver;
    uniform half        _UIEffectAlpha;
    uniform half        _CommonZ;


                
            
CBUFFER_END

    uniform float4      _UIClipRect;
    uniform float4      _ClipRect;
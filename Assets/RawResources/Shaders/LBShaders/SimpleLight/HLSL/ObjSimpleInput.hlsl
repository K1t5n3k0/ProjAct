CBUFFER_START(UnityPerMaterial)
    sampler2D _MainTex;
    float4 _MainTex_ST;

    half4 _Color;
    half _Sat;
    half _Lum;
    half _Cutoff;
    half _Dissolution;
    half _DissolveScale;
    half _DissolvePlane;
    half _Transparent;
    half _VirtualStrength;
CBUFFER_END

    sampler2D _DissolveTex;
    float4 _DissolveTex_ST;

    half _DownDistance;
    half _DissolveWidth;
    half4 _DissolveColor;
#ifndef UNIVERSAL_LIT_INPUT_INCLUDED
#define UNIVERSAL_LIT_INPUT_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
#include "ZXSceneSurfaceInput.hlsl"


CBUFFER_START(UnityPerMaterial)
float4 _BaseMap_ST;
half4 _BaseColor; //主颜色
half4 _EmissionColor; //自发光
half _Cutoff;
half _Smoothness;
half _Metallic;
half _NormalScale;
half _OcclusionStrength;
half _Surface;
half _EnvCubeStrength;
half _EnvCubeRotation;
half4 _SkyColor;
half4 _ZXSnowColor;
float4 _ZXSnowMapParam;
half4      _FlickerColor;
half       _FlickerSpeed;
half       _WorldNoise;
half       _VirtualStrength;
half _FogLowerLimit;
half _FogUpperLimint;
half _SoftOverGround;

half _Sat;
half _Lum;

CBUFFER_END 

TEXTURE2D(_MOE);                SAMPLER(sampler_MOE);
TEXTURE2D(_BaseMap);            SAMPLER(sampler_BaseMap);
TEXTURECUBE(_CubeMap);          SAMPLER(sampler_CubeMap);
TEXTURE2D(_NormalMap);          SAMPLER(sampler_NormalMap);
TEXTURE2D(_MaskMap);            SAMPLER(sampler_MaskMap);

#ifdef _SPECULAR_SETUP
#define SAMPLE_METALLICSPECULAR(uv) SAMPLE_TEXTURE2D(_SpecGlossMap, sampler_SpecGlossMap, uv)
#else
#define SAMPLE_METALLICSPECULAR(uv) SAMPLE_TEXTURE2D(_MOE, sampler_MOE, uv)
#endif

real3 UnpackNormal2PassScale(real2 normalXY, real scale = 1.0)
{
    real3 normal;
    normal.xy = normalXY * 2.0 - 1.0;
    normal.z = max(1.0e-16, sqrt(1.0 - saturate(dot(normal.xy, normal.xy))));

    normal.xy *= scale;
    return normal;
}

inline half3 InitializeStandardLitSurfaceData(float2 uv, out SurfaceData outSurfaceData, half posWorldY = 0)
{
    half4 albedoAlpha = SampleAlbedoAlpha(uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap));
    half3 bump = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, uv);
    half3 moe = SAMPLE_TEXTURE2D(_MOE, sampler_MOE, uv);
    half3 mask = SAMPLE_TEXTURE2D(_MaskMap, sampler_MaskMap, uv);

    //法线 光滑
    outSurfaceData.normalTS = UnpackNormal2PassScale(bump.rg, _NormalScale);
    outSurfaceData.smoothness = bump.b * _Smoothness;

    //颜色
    outSurfaceData.albedo = albedoAlpha.rgb * _BaseColor.rgb;
    outSurfaceData.specular = half3(0.0h, 0.0h, 0.0h);

    // 金属 AO 自发光
    outSurfaceData.metallic = moe.r * _Metallic;
    outSurfaceData.occlusion = lerp(1, moe.g, _OcclusionStrength);

    //透明
    albedoAlpha.a *= mask.g;

    //软粒子
#if defined(_SOFT_OVER)
    albedoAlpha.a *= saturate((posWorldY - _SoftOverGround - ZxPlaneShadowParam.w) * 4.0);
#endif

    half3 emissionMask = moe.b;

#if defined(_EMISSION) | defined(_FLICKER)
    #if defined(_EMISSION_BLEND_ALBEDO)
        emissionMask *= albedoAlpha.rgb;
    #endif

    outSurfaceData.emission = emissionMask * _EmissionColor;
#else
    outSurfaceData.emission = 0;
#endif

    //透明
    outSurfaceData.alpha = Alpha(albedoAlpha.a, _BaseColor, _Cutoff);

    return emissionMask;
}

#endif // UNIVERSAL_INPUT_SURFACE_PBR_INCLUDED

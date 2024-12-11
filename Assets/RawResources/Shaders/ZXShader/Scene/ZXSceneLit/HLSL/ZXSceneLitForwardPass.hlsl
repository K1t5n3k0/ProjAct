#ifndef UNIVERSAL_FORWARD_LIT_PASS_INCLUDED
#define UNIVERSAL_FORWARD_LIT_PASS_INCLUDED

#include "Assets/RawResources/Shaders/ZXShader/Scene/HLSL/ZXLighting.hlsl"

#if defined(_ZX_ENV_SNOW)
    #include "Assets/RawResources/Shaders/ZXShader/Scene/HLSL/ZXEnvSnow.hlsl"
#endif

#if defined(_FLICKER)
    #include "Assets/RawResources/Shaders/ZXShader/Scene/HLSL/ZXPosFlicker.hlsl"
#endif

struct Attributes
{
    float4 positionOS   : POSITION;
    float3 normalOS     : NORMAL;
    float4 tangentOS    : TANGENT;
    float2 texcoord     : TEXCOORD0;
    float2 lightmapUV   : TEXCOORD1;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float2 uv                       : TEXCOORD0;
    DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 1);

#if defined(REQUIRES_WORLD_SPACE_POS_INTERPOLATOR) || defined(_WORLD_CLOUD_ON) || defined(_ZX_ENV_SNOW)|| defined(_SOFT_OVER)
    float3 positionWS               : TEXCOORD2;
#endif

    float3 normalWS                 : TEXCOORD3;
    float4 tangentWS                : TEXCOORD4;    // xyz: tangent, w: sign
    float4 viewDirWS                : TEXCOORD5;

    half4 fogFactorAndMore   : TEXCOORD6; // x: fogFactor, yzw: vertex light

#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
    float4 shadowCoord              : TEXCOORD7;
#endif

    float4 positionCS               : SV_POSITION;

    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

void InitializeInputData(Varyings input, half3 normalTS, out InputData inputData)
{
    inputData = (InputData)0;

#if defined(REQUIRES_WORLD_SPACE_POS_INTERPOLATOR) || defined(_WORLD_CLOUD_ON) || defined(_ZX_ENV_SNOW) || defined(_SOFT_OVER)
    inputData.positionWS = input.positionWS;
#endif

    half3 viewDirWS = SafeNormalize(input.viewDirWS);

    float sgn = input.tangentWS.w;      // should be either +1 or -1
    float3 bitangent = sgn * cross(input.normalWS.xyz, input.tangentWS.xyz);
    inputData.normalWS = TransformTangentToWorld(normalTS, half3x3(input.tangentWS.xyz, bitangent.xyz, input.normalWS.xyz));

    inputData.normalWS = NormalizeNormalPerPixel(inputData.normalWS);
    inputData.viewDirectionWS.xyz = viewDirWS;

#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
    inputData.shadowCoord = input.shadowCoord;
#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
    inputData.shadowCoord = TransformWorldToShadowCoord(inputData.positionWS);
#else
    inputData.shadowCoord = float4(0, 0, 0, 0);
#endif

    inputData.fogCoord = input.fogFactorAndMore.x;
    inputData.bakedGI = SAMPLE_GI(input.lightmapUV, input.vertexSH, inputData.normalWS);
}

///////////////////////////////////////////////////////////////////////////////
//                  Vertex and Fragment functions                            //
///////////////////////////////////////////////////////////////////////////////

// Used in Standard (Physically Based) shader
Varyings LitPassVertex(Attributes input)
{
    Varyings output = (Varyings)0;

    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

    VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);

    // normalWS and tangentWS already normalize.
    // this is required to avoid skewing the direction during interpolation
    // also required for per-vertex lighting and SH evaluation
    VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
    float3 viewDirWS = GetCameraPositionWS() - vertexInput.positionWS;
    half3 vertexLight = VertexLighting(vertexInput.positionWS, normalInput.normalWS);

    //增加高度雾效
#ifdef _VERTICAL_FOG_ON
    half fogFactor = saturate((vertexInput.positionWS.y - ZxPlaneShadowParam.w - _FogLowerLimit) / (_FogUpperLimint - _FogLowerLimit));

#elif _VERTICAL_FOG_MIXED
    half fogFactor = saturate((vertexInput.positionWS.y - ZxPlaneShadowParam.w - _FogLowerLimit) / (_FogUpperLimint - _FogLowerLimit));
    fogFactor = min(fogFactor, ComputeFogFactor(vertexInput.positionCS.z));
#else
    half fogFactor = ComputeFogFactor(vertexInput.positionCS.z);
#endif

    output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);


    // already normalized from normal transform to WS.
    output.normalWS = normalInput.normalWS;
    output.viewDirWS.xyz = viewDirWS;

    real sign = input.tangentOS.w * GetOddNegativeScale();
    output.tangentWS = half4(normalInput.tangentWS.xyz, sign);

    OUTPUT_LIGHTMAP_UV(input.lightmapUV, unity_LightmapST, output.lightmapUV);
    OUTPUT_SH(output.normalWS.xyz, output.vertexSH);

#if defined(_FLICKER)
    output.fogFactorAndMore = half4(fogFactor, GetFlickerFactor(), 0, 0);
#else
    output.fogFactorAndMore = half4(fogFactor, 0, 0, 0);
#endif

#if defined(REQUIRES_WORLD_SPACE_POS_INTERPOLATOR) || defined(_WORLD_CLOUD_ON) || defined(_ZX_ENV_SNOW) || defined(_SOFT_OVER)
    output.positionWS = vertexInput.positionWS;
#endif

#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
    output.shadowCoord = GetShadowCoord(vertexInput);
#endif

    output.positionCS = vertexInput.positionCS;

    return output;
}

// Used in Standard (Physically Based) shader
half4 LitPassFragment(Varyings input) : SV_Target
{
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

    SurfaceData surfaceData;

#if defined(_SOFT_OVER)
    half3 mask = InitializeStandardLitSurfaceData(input.uv, surfaceData, input.positionWS.y);
#else
    half3 mask = InitializeStandardLitSurfaceData(input.uv, surfaceData);
#endif

    InputData inputData;
    InitializeInputData(input, surfaceData.normalTS, inputData);


#if defined(_ZX_ENV_SNOW)
    float3 bitangent = input.tangentWS.w * cross(input.normalWS.xyz, input.tangentWS.xyz);
    ApplyZXEnvSnow(inputData, surfaceData, half3x3(input.tangentWS.xyz, bitangent.xyz, input.normalWS.xyz));
#endif

//呼吸自发光
#if defined(_FLICKER)
    surfaceData.emission = GetFlickerColor(surfaceData.emission, input.fogFactorAndMore.y, mask);
#endif

    half4 color = UniversalFragmentPBR(inputData, surfaceData.albedo, surfaceData.metallic, surfaceData.smoothness, surfaceData.occlusion, surfaceData.emission, surfaceData.alpha,1,1);

    color.rgb = MixFog(color.rgb, inputData.fogCoord);

    color.a = _Surface >= 1 ? color.a : 1.0;


    return color;
}

#endif

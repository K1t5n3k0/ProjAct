#ifndef _ZX_ENV_SNOW_CG_INC_
#define _ZX_ENV_SNOW_CG_INC_

#ifdef _ZX_ENV_SNOW


TEXTURE2D(_ZXSnowMap);            SAMPLER(sampler_ZXSnowMap);

inline void ApplyZXEnvSnow(in InputData inputData, inout SurfaceData surfaceData, in half3x3 M)
{
    //颜色
    half snowBlend = saturate(pow(dot(inputData.normalWS, half3(0, 1, 0)), _ZXSnowMapParam.w) * _ZXSnowMapParam.z);

    half2 snowUV = inputData.positionWS.xz * _ZXSnowMapParam.x;
    half4 snowMap = SAMPLE_TEXTURE2D(_ZXSnowMap, sampler_ZXSnowMap, snowUV);
    half3 snowColor = snowMap.b * _ZXSnowColor * _ZXSnowMapParam.y;

    surfaceData.albedo = lerp(surfaceData.albedo, snowColor, snowBlend);

    //法线
    #if defined(_NORMALMAP)
        half3 snowNormal = UnpackNormal(snowMap);
        snowNormal = mul(snowNormal, M);
        surfaceData.normalTS = lerp(surfaceData.normalTS, snowNormal, snowBlend);
    #endif
    
}

#endif

#endif //_ZX_ENV_SNOW_CG_INC_
CBUFFER_START(UnityPerMaterial)
    float4    _Albedo01_ST, _Albedo02_ST, _Albedo03_ST; 
    float4    _Albedo04_ST, _Albedo05_ST, _Albedo06_ST;

    float4    _BumpSplat1_ST, _BumpSplat2_ST, _BumpSplat3_ST;
    float4    _BumpSplat4_ST, _BumpSplat5_ST, _BumpSplat6_ST;

    half3     _Color1, _Color2, _Color3;
    half3     _Color4, _Color5, _Color6;
    half      _NormalStrength1, _NormalStrength2, _NormalStrength3;
    half      _NormalStrength4, _NormalStrength5, _NormalStrength6;
    half      _SpecStrength1, _SpecStrength2, _SpecStrength3;
    half      _SpecStrength4, _SpecStrength5, _SpecStrength6;

    half3     _SpecularColor;
    half     _Gloss;
    half     _Brightness;
CBUFFER_END 
    Texture2D _SplatMap01, _SplatMap02;
    Texture2D _Albedo01, _Albedo02, _Albedo03;
    Texture2D _Albedo04, _Albedo05, _Albedo06;

    Texture2D _BumpSplat1, _BumpSplat2, _BumpSplat3;
    Texture2D _BumpSplat4, _BumpSplat5, _BumpSplat6;

    SamplerState sampler_SplatMap01;
    SamplerState sampler_Albedo01;
    SamplerState sampler_BumpSplat1;
real3 UnpackNormal2PassScale(real2 normalXY, real scale = 1.0)
{
    real3 normal;
    normal.xy = normalXY * 2.0 - 1.0;
    normal.z = max(1.0e-16, sqrt(1.0 - saturate(dot(normal.xy, normal.xy))));

    // must scale after reconstruction of normal.z which also
    // mirrors UnpackNormalRGB(). This does imply normal is not returned
    // as a unit length vector but doesn't need it since it will get normalized after TBN transformation.
    // If we ever need to blend contributions with built-in shaders for URP
    // then we should consider using UnpackDerivativeNormalAG() instead like
    // HDRP does since derivatives do not use renormalization and unlike tangent space
    // normals allow you to blend, accumulate and scale contributions correctly.
    normal.xy *= scale;
    return normal;
}

half3 MixTerrainNormal(half2 uv, half3 control, half3 control2, half weight, half weight2)
{
    half4 normal1 = _BumpSplat1.Sample(sampler_BumpSplat1, TRANSFORM_TEX(uv, _BumpSplat1));
    half4 normal2 = _BumpSplat2.Sample(sampler_BumpSplat1, TRANSFORM_TEX(uv, _BumpSplat2));
    half4 normal3 = _BumpSplat3.Sample(sampler_BumpSplat1, TRANSFORM_TEX(uv, _BumpSplat3));

    half4 normal4 = _BumpSplat4.Sample(sampler_BumpSplat1, TRANSFORM_TEX(uv, _BumpSplat4));
    half4 normal5 = _BumpSplat5.Sample(sampler_BumpSplat1, TRANSFORM_TEX(uv, _BumpSplat5));
    half4 normal6 = _BumpSplat6.Sample(sampler_BumpSplat1, TRANSFORM_TEX(uv, _BumpSplat6));

    half3 strength1 = half3(_NormalStrength1, _NormalStrength1, 1);
    half3 strength2 = half3(_NormalStrength2, _NormalStrength2, 1);
    half3 strength3 = half3(_NormalStrength3, _NormalStrength3, 1);

    half3 strength4 = half3(_NormalStrength4, _NormalStrength4, 1);
    half3 strength5 = half3(_NormalStrength5, _NormalStrength5, 1);
    half3 strength6 = half3(_NormalStrength6, _NormalStrength6, 1);

    half3 nrm = 0;
    half3 nrm2 = 0;
    nrm += control.r  * UnpackNormal(normal1) * strength1;
    nrm += control.g  * UnpackNormal(normal2) * strength2;
    nrm += control.b  * UnpackNormal(normal3) * strength3;

    nrm2 += control2.r * UnpackNormal(normal4) * strength4;
    nrm2 += control2.g * UnpackNormal(normal5) * strength5;
    nrm2 += control2.b * UnpackNormal(normal6) * strength6;

    nrm = nrm * weight + nrm2 * weight2;

    nrm = normalize(nrm);
    
    return nrm;
}

half MixTerrainSpecStrength(float2 uv, half3 control, half3 control2, half weight, half weight2)
{
    half res = 0;
    half res2 = 0;
    res += _SpecStrength1 * control.r ;
    res += _SpecStrength2 * control.g ;
    res += _SpecStrength3 * control.b ;
    res2 += _SpecStrength4 * control2.r;
    res2 += _SpecStrength5 * control2.g;
    res2 += _SpecStrength6 * control2.b;

    return res * weight + res2 * weight2;
}

void TerrainMixColorPass(float2 uv, out half3 mixedDiffuse, inout half3 mixedNormal, inout half mixedSpecStrength)
{

    //画板
    half3 splat_control = _SplatMap01.Sample(sampler_SplatMap01, uv);
    half3 splat_control2 = _SplatMap02.Sample(sampler_SplatMap01, uv);

    half weight = dot(splat_control, half3(1, 1, 1));
    splat_control /= (weight + 1e-3f);
    // clip(weight == 0.0f ? -1 : 1);

    half weight2 = dot(splat_control2, half3(1, 1, 1));
    splat_control2 /= (weight2 + 1e-3f);

    half3 layer1 = _Albedo01.Sample(sampler_Albedo01, TRANSFORM_TEX(uv, _Albedo01)) * _Color1;
    half3 layer2 = _Albedo02.Sample(sampler_Albedo01, TRANSFORM_TEX(uv, _Albedo02)) * _Color2;
    half3 layer3 = _Albedo03.Sample(sampler_Albedo01, TRANSFORM_TEX(uv, _Albedo03)) * _Color3;
    half3 layer4 = _Albedo04.Sample(sampler_Albedo01, TRANSFORM_TEX(uv, _Albedo04)) * _Color4;
    half3 layer5 = _Albedo05.Sample(sampler_Albedo01, TRANSFORM_TEX(uv, _Albedo05)) * _Color5;
    half3 layer6 = _Albedo06.Sample(sampler_Albedo01, TRANSFORM_TEX(uv, _Albedo06)) * _Color6;

    mixedDiffuse = 0;
    half3 mixedDiffuse2 = 0;


    //颜色图
    mixedDiffuse += splat_control.r * layer1.rgb;
    mixedDiffuse += splat_control.g * layer2.rgb;
    mixedDiffuse += splat_control.b * layer3.rgb;
    
    mixedDiffuse2 += splat_control2.r * layer4.rgb;
    mixedDiffuse2 += splat_control2.g * layer5.rgb;
    mixedDiffuse2 += splat_control2.b * layer6.rgb;

    mixedDiffuse = mixedDiffuse * weight + mixedDiffuse2 * weight2;

#if _SPECULAR_MAP  
    //法线
    half4 normal1 = _BumpSplat1.Sample(sampler_BumpSplat1, TRANSFORM_TEX(uv, _BumpSplat1));
    half4 normal2 = _BumpSplat2.Sample(sampler_BumpSplat1, TRANSFORM_TEX(uv, _BumpSplat2));
    half4 normal3 = _BumpSplat3.Sample(sampler_BumpSplat1, TRANSFORM_TEX(uv, _BumpSplat3));

    half4 normal4 = _BumpSplat4.Sample(sampler_BumpSplat1, TRANSFORM_TEX(uv, _BumpSplat4));
    half4 normal5 = _BumpSplat5.Sample(sampler_BumpSplat1, TRANSFORM_TEX(uv, _BumpSplat5));
    half4 normal6 = _BumpSplat6.Sample(sampler_BumpSplat1, TRANSFORM_TEX(uv, _BumpSplat6));

    half3 strength1 = half3(_NormalStrength1, _NormalStrength1, 1);
    half3 strength2 = half3(_NormalStrength2, _NormalStrength2, 1);
    half3 strength3 = half3(_NormalStrength3, _NormalStrength3, 1);

    half3 strength4 = half3(_NormalStrength4, _NormalStrength4, 1);
    half3 strength5 = half3(_NormalStrength5, _NormalStrength5, 1);
    half3 strength6 = half3(_NormalStrength6, _NormalStrength6, 1);

    half3 nrm = 0;
    half3 nrm2 = 0;
    nrm += splat_control.r  *UnpackNormal2PassScale(normal1.rg, strength1);
    nrm += splat_control.g  *UnpackNormal2PassScale(normal2.rg, strength2);
    nrm += splat_control.b  *UnpackNormal2PassScale(normal3.rg, strength3);

    nrm2 += splat_control2.r *UnpackNormal2PassScale(normal4.rg, strength4);
    nrm2 += splat_control2.g *UnpackNormal2PassScale(normal5.rg, strength5);
    nrm2 += splat_control2.b *UnpackNormal2PassScale(normal6.rg, strength6);
    nrm = nrm * weight  + nrm2*weight2 ;

    mixedNormal = normalize(nrm);

    //高光强度
    half res = 0;
    half res2 = 0;
    res += _SpecStrength1  * splat_control.r *normal1.b ;
    res += _SpecStrength2  * splat_control.g *normal2.b ;
    res += _SpecStrength3  * splat_control.b *normal3.b ;
    res2 += _SpecStrength4 * splat_control.r *normal4.b;
    res2 += _SpecStrength5 * splat_control.g *normal5.b;
    res2 += _SpecStrength6 * splat_control.b *normal6.b;

    mixedSpecStrength = res * weight + res2 * weight2;
#else
    //法线和高光强度
    mixedNormal = MixTerrainNormal(uv, splat_control, splat_control2, weight, weight2);
    mixedSpecStrength = MixTerrainSpecStrength(uv, splat_control, splat_control2, weight, weight2);
#endif
}



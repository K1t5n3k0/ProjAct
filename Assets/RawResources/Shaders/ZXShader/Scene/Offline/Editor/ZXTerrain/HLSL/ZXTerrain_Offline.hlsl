//法线 光滑
half4 MixTerrainNormalAndSmoothness(half2 uvs[6], half3 control, half3 control2, half weight, half weight2)
{
    half4 normal1 = _BumpSplat1.Sample(sampler_BumpSplat1, uvs[0]);
    half4 normal2 = _BumpSplat2.Sample(sampler_BumpSplat1, uvs[1]);
    half4 normal3 = _BumpSplat3.Sample(sampler_BumpSplat1, uvs[2]);

    half4 normal4 = _BumpSplat4.Sample(sampler_BumpSplat1, uvs[3]);
    half4 normal5 = _BumpSplat5.Sample(sampler_BumpSplat1, uvs[4]);
    half4 normal6 = _BumpSplat6.Sample(sampler_BumpSplat1, uvs[5]);

    half3 strength1 = half3(_NormalStrength1, _NormalStrength1, 1);
    half3 strength2 = half3(_NormalStrength2, _NormalStrength2, 1);
    half3 strength3 = half3(_NormalStrength3, _NormalStrength3, 1);

    half3 strength4 = half3(_NormalStrength4, _NormalStrength4, 1);
    half3 strength5 = half3(_NormalStrength5, _NormalStrength5, 1);
    half3 strength6 = half3(_NormalStrength6, _NormalStrength6, 1);

    //光滑
    half  smoothness = 0;
    half  smoothness2 = 0;
    smoothness += normal1.b * _Smoothness1 *  control.r;
    smoothness += normal2.b * _Smoothness2 *  control.g;
    smoothness += normal3.b * _Smoothness3 *  control.b;

    smoothness2 += normal4.b * _Smoothness4 * control2.r;
    smoothness2 += normal5.b * _Smoothness5 * control2.g;
    smoothness2 += normal6.b * _Smoothness6 * control2.b;

    smoothness = smoothness * weight + smoothness2 * weight2;

    //法线
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
    
    return half4(nrm, smoothness);
}

//金属 AO 高光 自发光
half2 MixTerrainMOE(half2 uvs[6], half3 control, half3 control2, half weight, half weight2, out half3 emission)
{
    half4 moe1 = _MOE1.Sample(sampler_MOE1, uvs[0]);
    half4 moe2 = _MOE2.Sample(sampler_MOE1, uvs[1]);
    half4 moe3 = _MOE3.Sample(sampler_MOE1, uvs[2]);

    half4 moe4 = _MOE4.Sample(sampler_MOE1, uvs[3]);
    half4 moe5 = _MOE5.Sample(sampler_MOE1, uvs[4]);
    half4 moe6 = _MOE6.Sample(sampler_MOE1, uvs[5]);

    //金属
    half3  ref = 0;
    half3  ref2 = 0;
    ref.r += moe1.r * _Metallic1 *  control.r;
    ref.r += moe2.r * _Metallic2 *  control.g;
    ref.r += moe3.r * _Metallic3 *  control.b;
    ref2.r += moe4.r * _Metallic4 * control2.r;
    ref2.r += moe5.r * _Metallic5 * control2.g;
    ref2.r += moe6.r * _Metallic6 * control2.b;

    //AO
    ref.g += moe1.g * _OcclusionStrength1 *  control.r;
    ref.g += moe2.g * _OcclusionStrength2 *  control.g;
    ref.g += moe3.g * _OcclusionStrength3 *  control.b;
    ref2.g += moe4.g * _OcclusionStrength4 * control2.r;
    ref2.g += moe5.g * _OcclusionStrength5 * control2.g;
    ref2.g += moe6.g * _OcclusionStrength6 * control2.b;

    //自发光
    emission = 0;
    half3 emission2 = 0;
    emission += moe1.b * _EmissionColor1 *  control.r;
    emission += moe2.b * _EmissionColor2 *  control.g;
    emission += moe3.b * _EmissionColor3 *  control.b;
    emission2 += moe4.b * _EmissionColor4 * control2.r;
    emission2 += moe5.b * _EmissionColor5 * control2.g;
    emission2 += moe6.b * _EmissionColor6 * control2.b;
    emission = emission * weight + emission2 * weight2;

    return ref * weight + ref2 * weight2;
}

//颜色
half3 MixTerrainAlbedo(half2 uvs[6], half3 control, half3 control2, half weight, half weight2)
{
    half3 layer1 = _Albedo01.Sample(sampler_Albedo01, uvs[0]) * _Color1;
    half3 layer2 = _Albedo02.Sample(sampler_Albedo01, uvs[1]) * _Color2;
    half3 layer3 = _Albedo03.Sample(sampler_Albedo01, uvs[2]) * _Color3;
    half3 layer4 = _Albedo04.Sample(sampler_Albedo01, uvs[3]) * _Color4;
    half3 layer5 = _Albedo05.Sample(sampler_Albedo01, uvs[4]) * _Color5;
    half3 layer6 = _Albedo06.Sample(sampler_Albedo01, uvs[5]) * _Color6;

    half3 mixedDiffuse = 0;
    half3 mixedDiffuse2 = 0;

    //颜色图
    mixedDiffuse += control.r * layer1;
    mixedDiffuse += control.g * layer2;
    mixedDiffuse += control.b * layer3;
    
    mixedDiffuse2 += control2.r * layer4;
    mixedDiffuse2 += control2.g * layer5;
    mixedDiffuse2 += control2.b * layer6;

    mixedDiffuse = mixedDiffuse * weight + mixedDiffuse2 * weight2;

    return mixedDiffuse;
}

void TerrainMixColorPass(float2 uv, out half3 mixedDiffuse, inout half4 ns, inout half2 mo, inout half3 emission)
{
    //画板
    half3 splat_control = tex2D(_SplatMap01, uv);
    half3 splat_control2 = tex2D(_SplatMap02, uv);

    half weight = dot(splat_control, half3(1, 1, 1));
    splat_control /= (weight + 1e-3f);

    half weight2 = dot(splat_control2, half3(1, 1, 1));
    splat_control2 /= (weight2 + 1e-3f);

    half2 uvs[6];
    uvs[0] = TRANSFORM_TEX(uv, _Albedo01);
    uvs[1] = TRANSFORM_TEX(uv, _Albedo02);
    uvs[2] = TRANSFORM_TEX(uv, _Albedo03);
    uvs[3] = TRANSFORM_TEX(uv, _Albedo04);
    uvs[4] = TRANSFORM_TEX(uv, _Albedo05);
    uvs[5] = TRANSFORM_TEX(uv, _Albedo06);

    //颜色
    mixedDiffuse = MixTerrainAlbedo(uvs, splat_control, splat_control2, weight, weight2);

    //法线和高光强度
    ns = MixTerrainNormalAndSmoothness(uvs, splat_control, splat_control2, weight, weight2);

    //金属 AO 自发光    
    mo = MixTerrainMOE(uvs, splat_control, splat_control2, weight, weight2, emission);
}



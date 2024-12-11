#ifndef _ZXENV_CLOUD_CG_INCLUDED
#define _ZXENV_CLOUD_CG_INCLUDED

sampler2D   _Cloud_Mask;
float4      _Cloud_Param;
half        _Cloud_Ins;
float2      _Cloud_Center;

half WorldCloudShadow(float3 posWorld)
{
    float2 uv = (posWorld.xz - _Cloud_Center.xy) * _Cloud_Param.xy +  _Time.x * _Cloud_Param.zw;
    half cloud = tex2D(_Cloud_Mask, uv).r;
    return cloud * _Cloud_Ins + 1 - _Cloud_Ins;
}

#endif // _ZXENV_CLOUD_CG_INCLUDED

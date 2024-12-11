#ifndef _ZX_POS_FLICKER_HLSL
#define _ZX_POS_FLICKER_HLSL

#ifdef  _FLICKER

inline half GetFlickerFactor()
{
    half offset = mul(unity_ObjectToWorld, half4(0, 0, 0, 1)).x * _WorldNoise;
    half timeMap = frac(_Time.y * _FlickerSpeed + offset);
    half flickerFactor = 4 * (timeMap - timeMap * abs(timeMap));
    return flickerFactor;
}

inline half3 GetFlickerColor(half3 emissionColor, half flickerFactor, half3 mask = 1)
{
    return lerp(emissionColor, _FlickerColor * mask, flickerFactor);
}
#endif
#endif
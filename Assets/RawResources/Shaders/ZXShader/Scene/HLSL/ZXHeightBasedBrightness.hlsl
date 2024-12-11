#ifndef HEIGHT_BASED_BRIGHTNESS_INCLUDED
#define HEIGHT_BASED_BRIGHTNESS_INCLUDED

inline half GetBrightness(half height)
{
    return 1;//smoothstep(_BrightParam.x, _BrightParam.y, height) * _BrightParam.z + _BrightParam.w;
}

inline half GetSelfBright(half brightness)
{
    return _BrightStrength * brightness + _BrightOffset;
}



#endif // HEIGHT_BASED_BRIGHTNESS_INCLUDED
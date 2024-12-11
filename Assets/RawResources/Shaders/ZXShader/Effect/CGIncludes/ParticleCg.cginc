//旋转
inline half2 Rotate(half2 uv, half angle, half2 offset = 0.5)
{
    half2 CosSin = sin(angle.xx * 0.0174533 + half2(1.5708, 0));
    uv = mul(uv - offset, half2x2(CosSin.x, -CosSin.y, CosSin.y, CosSin.x));
    return uv + offset;
}

//饱和度
inline half3 Staturation(half3 rgb, half staturation)
{
    half gray = dot(rgb, half3(0.3,0.59,0.11));
    rgb = lerp(gray, rgb, staturation);
    return rgb;
}

//软粒子
inline half SoftOverGround(half alpha, half posWorldY, half bottomY)
{
    return alpha * saturate(posWorldY * 4.0 - bottomY);
}
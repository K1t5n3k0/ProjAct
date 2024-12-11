Shader "ZXShader/Effect/Effect_Models"
{
    Properties
    {
        _MainTex ("Main Texture", 2D) = "white" {}
        [Gamma][HDR]_COLOR ("COLOR", Color) = (1, 1, 1, 1)
        [HideInInspector] _UIEffectAlpha("_UIEffectAlpha", Float) = 1
        _Saturation ("饱和度", Range(0, 1)) = 1
        _AlphaChannel ("Alpha Channel", Vector) = (0,0,0,1)
        _MainTexRepeat ("MainTex Repeat", Vector) = (1,1,0,1)

        _UVOffset ("UV 偏移", Vector) = (0,0,0,0)
        [Toggle(USE_MULTIMAINTEX)] _UseMultiMainTex("Use Multi MainTex", Float) = 0

        _MainRotation_Rota ("Main_Rotation_Rota", Vector) = (0,1,0,0)
        _MainRotation ("Main_Rotation", Range(0, 360)) = 0

        _UVMaskWidth ("UVMask Width", float) = 0
        _UVMaskDirection ("UVMask Direction", Range(0, 360)) = 0
        [HideInInspector]_UVMaskDirection_DirRota ("_UVMaskDirection_DirRota", Vector) = (0,1,0,0)

        [Toggle(USE_HUE_SHIFT)] _UseHueShift("使用色相偏移", Float) = 0
        _HueShift("色相偏移", Range(0, 0.1)) = 0

        [HideInInspector][Enum(Zero,0,One,1,Two,2, Dissolve, 3)] __MaskMode ("Mask Mode", Float) = 0
        _MaskTex ("Mask Texture", 2D) = "white" {}
        _MaskChannel ("Mask Channel", Vector) = (1,0,0,0)
        _MaskRepeat ("Mask Repeat", Vector) = (1,1,0,1)
        _MaskStrength ("Mask Strength", Range(-1, 1) ) = 0
        _MaskRotation ("Mask Rotation", Range(0, 360)) = 0
        [HideInInspector]_MaskRotation_Rota ("Mask_Rotation_Rota", Vector) = (0,1,0,0)

        _Mask2Tex ("Mask 2 Texture", 2D) = "white" {}
        _Mask2Channel ("Mask2 Channel", Vector) = (1,0,0,0)
        _Mask2Repeat ("Mask2 Repeat", Vector) = (1,1,0,1)
        _Mask2Strength ("Mask2 Strength", Range(-1, 1) ) = 0
        _Mask2Rotation ("Mask2 Rotation", Range(0, 360)) = 0
        [HideInInspector]_Mask2Rotation_Rota ("Mask_Rotation_Rota", Vector) = (0,1,0,0)

        _UVOffset2 ("UV Offset2", Vector) = (0,0,0,0)
        _DissolveChannel ("Dissolv Channel", Vector) = (1,0,0,0)
        _DissolveWidth ("Dissolve Width", Range(-3, 3)) = 0
        _DissolveDirection ("UV Direction", Range(0, 360)) = 0
        [HideInInspector]_DissolveDirection_DirRota ("_DissolveDirection_DirRota", Vector) = (0,1,0,0)
        _BorderOffset ("BorderOffset", Range(0, 1)) = 0
        [Gamma][HDR]_BorderColor ("Border Color", Color) = (0,0,0,1)
        _BorderWidth ("Border Width", Range(0, 1)) = 0

        [Toggle(USE_NOISE)] _UseNoise("Use Noise", Float) = 0
        _NoiseTex ("Noise", 2D) = "black" {}
        _NoiseParam ("Noise_power", Vector ) = (0,0,0,0)
        _NoiseCustomRepeat ("Noise_power_custom_Repeat", Vector ) = (1,1,0,0)
        _NoiseChannel ("Noise Channel", Vector) = (1,0,0,0)
        _NoiseRepeat ("Noise Repeat", Vector) = (1,1,0,1)
        _NoiseMix ("Noise Mix", Vector) = (1,0,0,0)
        [HideInInspector][Enum(Not, 0,UI,1,UGUI,2,CAVE,3)] __ClipMode ("Clip Mode", Float) = 0

        _SoftOverGround ("_SoftOverGround", Float) = 0
        _SetVertexColor ("SetVertexColor", Float) = 1
        [Toggle(USE_SOFT_OVER)] _UseSoftOver("软粒子", Float) = 0

        _StencilComp ("Stencil Comparison", Float) = 8
        _Stencil ("Stencil ID", Float) = 0
        _StencilOp ("Stencil Operation", Float) = 0
        _StencilWriteMask ("Stencil Write Mask", Float) = 255
        _StencilReadMask ("Stencil Read Mask", Float) = 255
        
        _ColorMask ("Color Mask", Float) = 15

        [Toggle(USE_CUSTOMDATA)] _UseCustomData("使用粒子custom", Float) = 0

        [Enum(None, 0, SplashScreen, 1, ignoreZ, 2)] _UseSplashScreen ("Use Splash Screen", Float) = 0
        _CommonZ("统一缩放", Float) = 1

        [Toggle(UI_MASK_CLIP)] _UIClip("Is Using with UI Clip", Float) = 0

        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("DstBlend", Int) = 1
        [Enum(UnityEngine.Rendering.CullMode)] _CullMode("Cull", Int) = 0
        [Enum(UnityEngine.Rendering.CompareFunction)] _ZTest("ZTest", Int) = 4
        [Enum(Close, 0, Open, 1)] _ZWriteU2("ZWrite", Int) = 0

        [Enum(One, 0, TwoSide, 1)] _RenderMode ("渲染模式", Float) = 0
    }
    SubShader
    {
        Tags {
            "IgnoreProjector"="True"
            "Queue"="Transparent"
            "RenderType"="Transparent"
            "PreviewType"="Plane"
        }
        LOD 100

        Stencil
        {
            Ref [_Stencil]
            Comp [_StencilComp]
            Pass [_StencilOp]
            ReadMask [_StencilReadMask]
            WriteMask [_StencilWriteMask]
        }

        Pass
        {
            Name "TransparentZTest"
            Tags
            { 
                "LightMode" = "UniversalForward" 
            }

            ZWrite [_ZWriteU2]
            ColorMask 0

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "CGIncludes/ModelsImport.cginc"
            
            struct appdata
            {
                float4 vertex: POSITION;
            };
            
            struct v2f
            {
                float4 vertex: SV_POSITION;
            };

            
            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos( v.vertex );

                return o;
            }
            
            half4 frag(v2f i): SV_Target
            {
                return 0;
            }
            ENDCG

        }

        Pass
        {

            Blend SrcAlpha [_DstBlend]
            Cull [_CullMode]
            ZTest [_ZTest]
            ZWrite Off
            ColorMask [_ColorMask]

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma enable_d3d11_debug_symbols

            #pragma shader_feature_local __ USE_HUE_SHIFT
            #pragma shader_feature_local __ USE_SPLASH_SCREEN USE_IGNORE_Z
            #pragma shader_feature_local __ USE_MASK USE_DOUBLE_MASK USE_DISSOLVE
            #pragma shader_feature_local __ USE_MULTIMAINTEX
            #pragma shader_feature_local __ USE_NOISE
            #pragma shader_feature_local __ USE_CUSTOMDATA
            #pragma multi_compile_local __ USE_SOFT_OVER
            #pragma multi_compile_local __  UI_MASK_CLIP UGUI_MASK_CLIP CAVE_LIGHT
            #pragma multi_compile __ _CAVE_LIGHTING_FOG //_WILD_LIGHTING_FOG

            #include "UnityCG.cginc"

            #if defined(CAVE_LIGHT) && (defined(_CAVE_LIGHTING_FOG) || defined(_WILD_LIGHTING_FOG))
                #include "../../GSShaders/GSEnv/Core/LBCaveLightingFog.hlsl"
            #endif

            #if defined(UI_MASK_CLIP) || defined(UGUI_MASK_CLIP)
                #include "UnityUI.cginc"
            #endif

            struct appdata
            {
                float4 vertex : POSITION;
                float4 vertexColor : COLOR;
                float4 texcoord0 : TEXCOORD0;
            #if defined(USE_CUSTOMDATA)
                float4 texcoord1 : TEXCOORD1;
                float4 texcoord2 : TEXCOORD2;
                #if defined(UGUI_MASK_CLIP)
                    float2 UIClipRect1 : TEXCOORD3;
                    float2 UIClipRect2 : TEXCOORD4;
                #endif
            #else
                #if defined(UGUI_MASK_CLIP)
                    float2 UIClipRect1 : TEXCOORD1;
                    float2 UIClipRect2 : TEXCOORD2;
                #endif
            #endif
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 vertexColor : COLOR;
                float4 uv0 : TEXCOORD0;
                float4 uv1 : TEXCOORD1;
                float4 param : TEXCOORD2;   //Custom下(x:mask强度,y:noise强度,z:hueshift)
                float4 posWorld : TEXCOORD3;
                float4 param2 : TEXCOORD4; //Custom下(x:mask强度,y:noise强度,z:hueshift)
            #if defined(UGUI_MASK_CLIP)
                float4 UIClipRect: TEXCOORD5;
            #endif
            };

            #include "CGIncludes/ModelsImport.cginc"
            half4 ZxPlaneShadowParam;

            v2f vert (appdata v)
            {
                v2f o = (v2f)0;

            #if defined(USE_CUSTOMDATA)
                float enhance = v.texcoord1.x + 1.0;
                o.vertexColor = v.vertexColor * _COLOR;
                o.vertexColor.rgb *= enhance;
            #else
				o.vertexColor = v.vertexColor * _COLOR;
			#endif

            #if defined(UI_MASK_CLIP) || defined(UGUI_MASK_CLIP) || defined(CAVE_LIGHT) || defined(USE_DISSOLVE) || defined(USE_SOFT_OVER)
                o.posWorld = mul(unity_ObjectToWorld, v.vertex);

            #endif

            #if defined(USE_SPLASH_SCREEN)
				o.pos = float4(v.texcoord0.xy * 2 - 1, 0, v.vertex.w);
			#elif defined(USE_IGNORE_Z)
				o.pos = UnityObjectToClipPos( half4(0,0,0,1) );
                half3 offset = v.vertex.xyz;
                offset.x *= _ScreenParams.y / _ScreenParams.x;
                o.pos.xyz +=  offset * (-_CommonZ) * o.pos.w;
                
            #else
				o.pos = UnityObjectToClipPos( v.vertex );
			#endif

                o.uv0 = v.texcoord0.xyxy;

            #if defined(USE_CUSTOMDATA)
                o.uv1 = o.uv0 + float4(v.texcoord0.zw, float2(0, 0));
            #else
				o.uv1 = o.uv0;
			#endif
                //o.uv1 = o.uv0 + _UVOffset * _Time.g;

            //主纹理和Mask旋转

            o.uv1 -= 0.5;
            o.uv0.xy -= 0.5;
            //0.0174533=PI/180      1.5708=PI/2     sin(PI/2 + a) = cos(a)
            //float4 CosSin = sin(float4(_MainRotation.xx, _MaskRotation.xx) * 0.0174533 + float4(1.5708, 0, 1.5708, 0));
            o.uv1.xy = mul(o.uv1.xy, float2x2(_MainRotation_Rota.x, -_MainRotation_Rota.y, _MainRotation_Rota.y, _MainRotation_Rota.x));
            o.uv1.zw = mul(o.uv1.zw, float2x2(_MaskRotation_Rota.x, -_MaskRotation_Rota.y, _MaskRotation_Rota.y, _MaskRotation_Rota.x));
            o.uv0.xy = mul(o.uv0.xy, float2x2(_Mask2Rotation_Rota.x, -_Mask2Rotation_Rota.y, _Mask2Rotation_Rota.y, _Mask2Rotation_Rota.x));
            o.uv0.xy +=0.5;
            o.uv1 += 0.5;
            #if defined(USE_DISSOLVE)
                //float2 CosSin1 = sin(_DissolveDirection.xx * 0.0174533 + float2(1.5708, 0));
                o.posWorld.w = dot(o.uv0.xy - 0.5, _DissolveDirection_DirRota.xy) + 0.5;
                o.posWorld.w = saturate(dot(o.uv0.xy - 0.5, _DissolveDirection_DirRota.xy) + 0.5);
            #endif

            #if defined(USE_CUSTOMDATA)
                o.param = float4(v.texcoord1.zw, v.texcoord1.y, v.texcoord2.y);
                o.param2.x = v.texcoord2.x;
			#endif

            #if defined(UGUI_MASK_CLIP)
                o.UIClipRect = float4(v.UIClipRect1, v.UIClipRect2);
            #endif

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                i.uv1 = i.uv1 + _UVOffset * _Time.g;
                float2 uv = i.uv1.xy;

                fixed2 clamp;
                fixed2 uvClamp;
                fixed2 noise = 0;
            #if defined(USE_NOISE)
                #if defined(USE_MULTIMAINTEX)
                    noise = dot(maskColor, _NoiseChannel).xx;
                #else
                    fixed2 noiseUV = TRANSFORM_TEX(i.uv0.zw, _NoiseTex) + _NoiseParam.zw * _Time.g;
                        
                    noise = tex2D(_NoiseTex, noiseUV).xy;
                    clamp = abs(ceil(noiseUV - 1));
                    uvClamp = saturate(1 - clamp + _NoiseRepeat.xy * clamp);
                    noise = noise * uvClamp.x * uvClamp.y;
                #endif
            #endif

            fixed2 noiseParamXY = _NoiseParam.xy;
            #if defined(USE_CUSTOMDATA)
                fixed2 noisePowerParam = lerp(1, i.param2.xx, _NoiseCustomRepeat);
                noiseParamXY.x *= noisePowerParam.x;
                noiseParamXY.y *= noisePowerParam.y;
            #else
                noiseParamXY = _NoiseParam.xy;
            #endif

        #if defined(USE_MASK) || defined(USE_DOUBLE_MASK) || defined(USE_DISSOLVE) || defined(USE_MULTIMAINTEX)
                fixed maskColorNoiseMix = 0;
                #if defined(USE_NOISE)
                    maskColorNoiseMix = dot(fixed4(0, 1, 0, 0), _NoiseMix);
                #endif
                fixed2 maskUV = TRANSFORM_TEX(i.uv1.zw, _MaskTex) + noise * noiseParamXY * maskColorNoiseMix;

                fixed4 maskColor = tex2D(_MaskTex, maskUV);
                clamp = abs(ceil(maskUV - 1));
                uvClamp = saturate(1 - clamp + _MaskRepeat.xy * clamp);
                maskColor = maskColor * uvClamp.x * uvClamp.y;
        #endif
            #if defined(USE_NOISE)
                fixed baseColorNoiseMix = dot(fixed4(1, 0, 0, 0), _NoiseMix);
                #if defined(USE_MULTIMAINTEX)
                    uv = uv + (noise * noiseParamXY + _NoiseParam.zw * _Time.g) * baseColorNoiseMix;
                #else
                    uv = uv + noise * noiseParamXY * baseColorNoiseMix;
                #endif
            #endif  

                //主纹理采样
                uv = TRANSFORM_TEX(uv, _MainTex);
                fixed4 col;
                fixed4 baseCol = tex2D(_MainTex, uv);
                clamp = abs(ceil(uv - 1));
                uvClamp = saturate(1 - clamp + _MainTexRepeat.xy * clamp);
                baseCol = baseCol * uvClamp.x * uvClamp.y;
                col = baseCol;

                //Alpha通道
                col.a = dot(_AlphaChannel, col);

                fixed gray = dot(col.rgb, float3(0.3,0.59,0.11));
                //色相偏移
            #if defined(USE_HUE_SHIFT)
                fixed hueshift;
                #if defined(USE_CUSTOMDATA)
                    hueshift = i.param.w;
                #else
                    hueshift = _HueShift;
                #endif

                fixed3 tempColorR = tex2D(_MainTex, uv + hueshift);
                fixed3 tempColorB = tex2D(_MainTex, uv - hueshift);

                fixed grayR = dot(tempColorR.rgb, float3(0.3,0.59,0.11));
                fixed grayB = dot(tempColorB.rgb, float3(0.3,0.59,0.11));

                fixed3 grayCol = fixed3(grayR, gray, grayB);
                col.rgb = fixed3(tempColorR.r, col.g, tempColorB.b);

                col.rgb = lerp(grayCol, col.rgb, _Saturation);
            #else
                //去色
                col.rgb = lerp(gray, col.rgb, _Saturation);
            #endif

            col = col * i.vertexColor;

            fixed mask = 1;
            fixed mask2 = 1;
            fixed maskStrength = _MaskStrength;

            #if defined(USE_MASK) || defined(USE_DOUBLE_MASK) || defined(USE_DISSOLVE) || defined(USE_MULTIMAINTEX)
                //放在最上面了
                mask = dot(maskColor, _MaskChannel);
                mask = saturate(mask - maskStrength);

                #if defined(USE_DOUBLE_MASK) || defined(USE_DISSOLVE)
                    fixed mask02ColorNoiseMix = 0;
                    #if defined(USE_NOISE)
                        mask02ColorNoiseMix = dot(fixed4(0, 0, 1, 0), _NoiseMix);
                    #endif

                    #if defined(USE_MULTIMAINTEX)
                        mask2 = dot(maskColor, _Mask2Channel);
                    #else
                        fixed2 mask2UV = TRANSFORM_TEX(i.uv0.xy, _Mask2Tex) + i.param.xy + noise * noiseParamXY * mask02ColorNoiseMix + _UVOffset2.xy * _Time.g;
                        fixed4 mask2Color = tex2D(_Mask2Tex, mask2UV);

                        clamp = abs(ceil(mask2UV - 1));
                        uvClamp = saturate(1 - clamp + _Mask2Repeat.xy * clamp);
                        mask2Color = mask2Color * uvClamp.x * uvClamp.y;
                        
                        #if defined(USE_DOUBLE_MASK)
                            mask2 = dot(mask2Color, _Mask2Channel);
                        #endif
                    #endif

                    #if defined(USE_DISSOLVE)
                        #if defined(USE_MULTIMAINTEX)
                            mask2 = dot(maskColor, _DissolveChannel);
                        #else
                            mask2 = dot(mask2Color, _DissolveChannel);
                        #endif
                        //mask2 += (1 - saturate(ceil(i.posWorld.w - _DissolveWidth))) * _DissolveWidth;
                        fixed dissolveWidth;
                        #if defined(USE_CUSTOMDATA)
                            dissolveWidth = i.param.z;
                        #else
                            dissolveWidth = _DissolveWidth;
                        #endif
                        mask2 += (i.posWorld.w * saturate(_DissolveDirection) - dissolveWidth);
                        fixed2 diss = _BorderOffset * fixed2(0.63, -0.63) + fixed2(-0.14, 1.14);
                        fixed2 mix = smoothstep(fixed2(diss.x, diss.y), fixed2(diss.y, diss.x), fixed2(mask2, mask2 - _BorderWidth));
                        col.rgb += _BorderColor.rgb * mix.x * mix.y;
                        mask2 = mix.x;
                        mask2 = saturate(mask2 - saturate(_Mask2Strength));
                    #else
                        mask2 = saturate(mask2 - _Mask2Strength);

                    #endif
                    mask *= mask2;
                #endif
                 
            #else
                mask = 1 - maskStrength; 
            #endif//defined(USE_MASK) || defined(USE_DOUBLE_MASK) || defined(USE_DISSOLVE) || defined(USE_MULTIMAINTEX)

                col.a = saturate(col.a * mask);

                //遮罩计算

                //移动UV的中心点为UV的中心
                fixed middlePointDirect = dot(i.uv0.xy - 0.5, _UVMaskDirection_DirRota.xy) + 0.5;
                col.a = saturate(col.a - saturate(middlePointDirect * saturate(_UVMaskDirection) - _UVMaskWidth));
                
            #if defined(USE_SOFT_OVER)
                col.a *= saturate((i.posWorld.y - _SoftOverGround - ZxPlaneShadowParam.w) * 4.0);
            #endif

            

                return float4(col.rgb, col.a);
            }
            ENDCG
        }
    }
    CustomEditor "Effect_ModelsShaderEditor"
}

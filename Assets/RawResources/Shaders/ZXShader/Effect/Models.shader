Shader "ZXShader/Effect/Models"
{
    Properties
    {
        [HDR]_COLOR ("COLOR", Color) = (1, 1, 1, 1)
        _MainTex ("Main Texture", 2D) = "white" {}
        _Saturation ("饱和度", Range(0, 1)) = 1

        [Toggle(USE_HUE_SHIFT)] _UseHueShift("使用色相偏移", Float) = 0
        _HueShift("色相偏移", Range(0, 0.1)) = 0

        _AlphaChannel ("Alpha Channel", Vector) = (0,0,0,1)

        [Toggle(USE_ROTATION)] _UseRotaion("Use Rotation", Float) = 0
        _MainRotation ("Main_Rotation", Range(0, 360)) = 0

        _UVOffset ("UV 偏移", Vector) = (0,0,0,0)

        [HideInInspector][Enum(Zero,0,One,1,Two,2, Dissolve, 3)] __MaskMode ("Mask Mode", Float) = 0
        _MaskTex ("Mask Texture", 2D) = "white" {}
        _MaskChannel ("Mask Channel", Vector) = (1,0,0,0)
        _MaskRotation ("Mask Rotation", Range(0, 360)) = 0

        _Mask2Tex ("Mask 2 Texture", 2D) = "white" {}
        _MaskStrength ("Mask Strength", Float ) = 0
        _Mask2Strength ("Mask 2 Strength", Float) = 0

        [Toggle(USE_NOISE)] _UseNoise("Use Noise", Float) = 0
        _NoiseTex ("Noise", 2D) = "black" {}
        _NoiseParam ("Noise_power", Vector ) = (0,0,0,0)

        [HDR]_BorderColor ("Border Color", Color) = (0,0,0,1)
        _BorderOffset ("Border Offset", Range(0, 1)) = 0
        _BorderWidth ("Border Width", Range(0, 1)) = 0
        _DissolveDirection ("Dissolve Direction", Range(0, 360)) = 0
        _DissolveWidth ("Dissolve Width", Float) = 0

        [Toggle(USE_SOFT_OVER)] _UseSoftOver("软粒子", Float) = 0
        _SoftOverGround ("软粒子平面", Float ) = 0

        [HideInInspector][Enum(Not, 0,UI,1,UGUI,2,CAVE,3)] __ClipMode ("Clip Mode", Float) = 0

        _StencilComp ("Stencil Comparison", Float) = 8
        _Stencil ("Stencil ID", Float) = 0
        _StencilOp ("Stencil Operation", Float) = 0
        _StencilWriteMask ("Stencil Write Mask", Float) = 255
        _StencilReadMask ("Stencil Read Mask", Float) = 255
        
        _ColorMask ("Color Mask", Float) = 15

        [Enum(None, 0, SplashScreen, 1, ignoreZ, 2)] _useSplashScreen ("Use Splash Screen", Float) = 0
        _CommonZ("统一缩放", Float) = 1

        [Toggle(UI_MASK_CLIP)] _UIClip("Is Using with UI Clip", Float) = 0

        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("DstBlend", Int) = 1
        [Enum(UnityEngine.Rendering.CullMode)] _CullMode("Cull", Int) = 0
        [Enum(UnityEngine.Rendering.CompareFunction)] _ZTest("ZTest", Int) = 4

        [HideInInspector] _UIEffectAlpha("_UIEffectAlpha", Float) = 1
        [Enum(Never, 0, Color, 1, Alpha, 2)]_SetVertexColor ("SetVertexColor", Float) = 1
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

            ZWrite On
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

            #pragma multi_compile_local __ USE_HUE_SHIFT
            #pragma multi_compile_local __ USE_ROTATION
            #pragma multi_compile_local __ USE_SPLASH_SCREEN USE_IGNORE_Z
            #pragma multi_compile_local __ USE_MASK USE_DOUBLE_MASK USE_DISSOLVE
            #pragma multi_compile_local __ USE_NOISE
            #pragma multi_compile_local __ USE_SOFT_OVER
            #pragma multi_compile_local __  UI_MASK_CLIP UGUI_MASK_CLIP CAVE_LIGHT UNITY_UI_CLIP_RECT
            #pragma multi_compile __ _CAVE_LIGHTING_FOG //_WILD_LIGHTING_FOG

            #include "UnityCG.cginc"

            #if defined(CAVE_LIGHT) && (defined(_CAVE_LIGHTING_FOG) || defined(_WILD_LIGHTING_FOG))
                #include "../../GSShaders/GSEnv/Core/LBCaveLightingFog.hlsl"
            #endif

            #if defined(UI_MASK_CLIP) || defined(UGUI_MASK_CLIP) || defined(UNITY_UI_CLIP_RECT)
                #include "UnityUI.cginc"
            #endif

            struct appdata
            {
                float4 vertex : POSITION;
                float4 vertexColor : COLOR;
                float2 texcoord0 : TEXCOORD0;
            #if defined(UGUI_MASK_CLIP)
                float2 UIClipRect1 : TEXCOORD1;
                float2 UIClipRect2 : TEXCOORD2;
            #endif
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 vertexColor : COLOR;
                float4 uv0 : TEXCOORD0;
                float4 uv1 : TEXCOORD1;
            #if defined(USE_SOFT_OVER) || defined(UI_MASK_CLIP) || defined(UGUI_MASK_CLIP) || defined(CAVE_LIGHT) || defined(USE_DISSOLVE) || defined(UNITY_UI_CLIP_RECT)
                float4 posWorld : TEXCOORD2;
            #endif            
            #if defined(UGUI_MASK_CLIP)
                float4 UIClipRect: TEXCOORD3;
            #endif

            #if defined(UNITY_UI_CLIP_RECT)
                float2 vertex: TEXCOORD4;
            #endif
            };

            #include "CGIncludes/ModelsImport.cginc"
            half4 ZxPlaneShadowParam;

            v2f vert (appdata v)
            {
                v2f o = (v2f)0;
                o.vertexColor = v.vertexColor * _COLOR;

				if(_SetVertexColor == 1)
				{
					o.vertexColor.rgb = pow(o.vertexColor.rgb, 0.4545);
				}
				else if(_SetVertexColor == 2)
				{
					o.vertexColor = pow(o.vertexColor, 0.4545);
				}


            #if defined(UNITY_UI_CLIP_RECT)
                o.vertex.xy = v.vertex.xy;
            #endif

            #if defined(USE_SOFT_OVER) || defined(UI_MASK_CLIP) || defined(UGUI_MASK_CLIP) || defined(CAVE_LIGHT) || defined(USE_DISSOLVE)
                o.posWorld = mul(unity_ObjectToWorld, v.vertex);
            #endif

            #if defined(USE_SPLASH_SCREEN)
				o.pos = float4(v.texcoord0 * 2 - 1, 0, v.vertex.w);
			#elif defined(USE_IGNORE_Z)
				o.pos = UnityObjectToClipPos( half4(0,0,0,1) );
                half3 offset = v.vertex.xyz;
                offset.x *= _ScreenParams.y / _ScreenParams.x;
                o.pos.xyz +=  offset * (-_CommonZ) * o.pos.w;
                
            #else
				o.pos = UnityObjectToClipPos( v.vertex );
			#endif

                o.uv0 = v.texcoord0.xyxy;
                o.uv1 = o.uv0 + _UVOffset * _Time.g;
                
            #if defined(USE_NOISE)
                o.uv0.zw = TRANSFORM_TEX((o.uv0.zw + _NoiseParam.zw * _Time.g), _NoiseTex);
            #endif

            #if defined(USE_DISSOLVE)
                float2 CosSin1 = sin(_DissolveDirection.xx * 0.0174533 + float2(1.5708, 0));
                o.posWorld.w = dot(o.uv0.xy - 0.5, float2(CosSin1.x, -CosSin1.y)) + 0.5;
            #endif

                //主纹理和Mask旋转
            #if defined(USE_ROTATION)
                o.uv1 -= 0.5;
                float4 CosSin = sin(float4(_MainRotation.xx, _MaskRotation.xx) * 0.0174533 + float4(1.5708, 0, 1.5708, 0));
                o.uv1.xy = mul(o.uv1.xy, float2x2(CosSin.x, -CosSin.y, CosSin.y, CosSin.x));
                o.uv1.zw = mul(o.uv1.zw, float2x2(CosSin.z, -CosSin.w, CosSin.w, CosSin.z));
                o.uv1 += 0.5;
            #endif

            #if defined(USE_MASK) || defined(USE_DOUBLE_MASK) || defined(USE_DISSOLVE)
                o.uv1.zw = TRANSFORM_TEX((o.uv1.zw), _MaskTex);
            #endif

            #if defined(UGUI_MASK_CLIP)
                o.UIClipRect = float4(v.UIClipRect1, v.UIClipRect2);
            #endif

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 uv = i.uv1.xy;

                //噪声
            #if defined(USE_NOISE)
                fixed2 noise = tex2D(_NoiseTex, i.uv0.zw).xy;
                uv = lerp(uv, noise, _NoiseParam.xy);
            #endif  

                //主纹理采样
                uv =  TRANSFORM_TEX(uv, _MainTex);
                fixed4 col = tex2D(_MainTex, uv);

                //Alpha通道、去色
                col.a = dot(_AlphaChannel, col);
                fixed gray = dot(col.rgb, float3(0.3,0.59,0.11));
                
            #if defined(USE_HUE_SHIFT)
                fixed3 tempColorR = tex2D(_MainTex, uv + _HueShift);
                fixed3 tempColorB = tex2D(_MainTex, uv - _HueShift);

                fixed grayR = dot(tempColorR.rgb, float3(0.3,0.59,0.11));
                fixed grayB = dot(tempColorB.rgb, float3(0.3,0.59,0.11));

                fixed3 grayCol = fixed3(grayR, gray, grayB);
                col.rgb = fixed3(tempColorR.r, col.g, tempColorB.b);

                col.rgb = lerp(grayCol, col.rgb, _Saturation);
            #else
                col.rgb = lerp(gray, col.rgb, _Saturation);
            #endif

                //顶点色，颜色加强
                col *= i.vertexColor;

                // mask
            #if defined(USE_MASK) || defined(USE_DOUBLE_MASK) || defined(USE_DISSOLVE)
                fixed mask = dot(tex2D(_MaskTex, i.uv1.zw), _MaskChannel);
                mask = mask - _MaskStrength;   

                #if defined(USE_DOUBLE_MASK) || defined(USE_DISSOLVE)
                    fixed mask2 = tex2D(_Mask2Tex, TRANSFORM_TEX(i.uv0.xy, _Mask2Tex)).r;
                    mask2 = mask2 - _Mask2Strength;

                    //溶解
                    #if defined(USE_DISSOLVE)
                        mask2 += i.posWorld.w * _DissolveWidth;
                        fixed2 diss = _BorderOffset * fixed2(0.63, -0.63) + fixed2(-0.14, 1.14);
                        fixed2 mix = smoothstep(fixed2(diss.x, diss.y), fixed2(diss.y, diss.x), fixed2(mask2, mask2 - _BorderWidth));
                        col.rgb += _BorderColor.rgb * mix.x * mix.y;
                        mask2 = mix.x;   
                    #endif
                    mask *= mask2;
                #endif
                 
            #else
                fixed mask = 1 - _MaskStrength; 
            #endif
                     
            col.a = saturate(col.a * mask);

                  //软粒子
            #if defined(USE_SOFT_OVER)
                col.a *= saturate((i.posWorld.y - _SoftOverGround - ZxPlaneShadowParam.w) * 4.0);
            #endif

            #if defined(CAVE_LIGHT) && (defined(_CAVE_LIGHTING_FOG) || defined(_WILD_LIGHTING_FOG))
                ApplyLBCaveFogAdd(i.posWorld.xyz, col);
            #endif

            #if defined(UI_MASK_CLIP)
                col.a *= UnityGet2DClipping(i.posWorld.xy, _UIClipRect);
            #endif

            #if defined(UGUI_MASK_CLIP)
                col.a *= UnityGet2DClipping(i.posWorld.xy, i.UIClipRect);
            #endif
            
            #if defined(UNITY_UI_CLIP_RECT)
                col.a *= UnityGet2DClipping(i.vertex.xy, _ClipRect);
            #endif

                col.a *= _UIEffectAlpha;
                
                return col;
            }
            ENDCG
        }
    }
    CustomEditor "ModelsShaderEditor"
}

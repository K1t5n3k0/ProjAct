Shader "ZXShader/Effect/Fresnel_Opaque"
{
    Properties
    {
        [Enum(UnityEngine.Rendering.CullMode)] _CullMode ("裁剪模式", Int) = 2

        [HDR]_COLOR ("主颜色", Color) = (1, 1, 1, 1)
        [HDR]_ColorIN ("内圈颜色", Color) = (1, 1, 1, 1)
        [HDR]_ColorOut ("外圈颜色", Color) = (0.5, 0.5, 0.5, 1)
        
        _EmissiveMult ("漫反射亮度", Float) = 1
        _Fresnel ("菲涅尔强度", Float) = 1
        _AlphaClipValue ("透明度裁剪", Float) = 0

        _UVOffset ("UV 偏移", Vector) = (0, 0, 0, 0)

        _MainTex("颜色贴图", 2D) = "white" {}

        [Space][Toggle(USE_NOISE)]_UseNoise("开启扰乱", Float) = 0
        [HideBy(_UseNoise, 1)]_NoiseTex ("噪声贴图", 2D) = "black" {}
        [HideBy(_UseNoise, 1)]_NoiseParam ("扰乱强度和UV偏移", Vector ) = (0,0,0,0)

        // [Enum(Zero, 0, One, 1, Two, 2)][Keyword(USE_MASK, 1, USE_DOUBLE_MASK, 2)] __MaskMode ("Mask Mode", Float) = 0
        // [HideBy(__MaskMode, 1)]_MaskTex ("遮罩贴图", 2D) = "white" {}

        // [indent_add]
        // [AlphaChannel(__MaskMode, 1)]_MaskChannel ("透明通道", Vector) = (1,0,0,0)
        // _MaskStrength ("遮罩强度", Float ) = 0
        // [HideBy(__MaskMode, 1)]_MaskRotation ("旋转", Range(0, 360)) = 0
        // [indent_sub]

        // [HideBy(__MaskMode, 2)]_Mask2Tex ("溶解贴图", 2D) = "white" {}

        // [indent_add]
        // [HideBy(__MaskMode, 2)]_Mask2Strength ("溶解强度", Float) = 0

    }
    SubShader
    {
        Tags { "IgnoreProjector" = "True" "Queue" = "Geometry" "RenderType" = "Geometry" }

        Pass
        {
            Cull [_CullMode]
            Blend One Zero
            ZWrite On

            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            #pragma multi_compile_local __ USE_MASK USE_DOUBLE_MASK
            #pragma multi_compile_local __ USE_NOISE

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                half2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 posWorld : TEXCOORD0;
                float3 normalDir : TEXCOORD1;
                half4 uv : TEXCOORD2;
            };

            CBUFFER_START(UnityPerMaterial)
                float4 _ColorIN;
                float4 _ColorOut;
                float4 _COLOR;
                half _EmissiveMult;
                half _Fresnel;
                half _OpacityMult;
                half _AlphaClipValue;

                //Mask
                uniform sampler2D   _MainTex;
                uniform float4      _MainTex_ST;

                uniform sampler2D   _NoiseTex;
                uniform float4      _NoiseTex_ST;
                uniform float4      _NoiseParam;

                uniform sampler2D   _MaskTex;
                uniform float4      _MaskTex_ST;
                uniform half        _MaskRotation;
                uniform half4      _MaskChannel;
                uniform half4       _UVOffset;

                uniform sampler2D   _Mask2Tex;
                uniform float4      _Mask2Tex_ST;
                uniform half      _Mask2Strength;
                uniform half       _MaskStrength;

            CBUFFER_END

            v2f vert(a2v v)
            {
                v2f o;

                o.pos = GetVertexPositionInputs(v.vertex).positionCS;
                o.normalDir = TransformObjectToWorldNormal(v.normal);
                o.posWorld = mul(unity_ObjectToWorld, v.vertex);
                o.uv.xy = TRANSFORM_TEX(v.uv.xy, _MainTex);

				//noise
			#if defined(USE_NOISE)
				o.uv.zw = TRANSFORM_TEX(v.uv, _NoiseTex) + _NoiseParam.zw * _Time.g;
			#endif

                // #if defined(USE_MASK) || defined(USE_DOUBLE_MASK)
                //     o.uv = v.texcoord0.xyxy;
                //     o.uv.xy -= 0.5;
                //     half2 cosSin = sin(half2(_MaskRotation.xx) * 0.0174533 + half2(1.5708, 0));
                //     o.uv.xy = mul(o.uv.xy, half2x2(cosSin.x, -cosSin.y, cosSin.y, cosSin.x));

                //     o.uv += 0.5 + _UVOffset * _Time.g;
                //     o.uv.xy = TRANSFORM_TEX(o.uv.xy, _MaskTex);

                //     #if defined(USE_DOUBLE_MASK)
                //         o.uv.zw = TRANSFORM_TEX(o.uv.zw, _Mask2Tex);
                //     #endif
                // #endif
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                //菲涅尔
                half3 normalDirection = normalize(i.normalDir);
                half3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);
                half FresnelPower = pow(1 - max(0, dot(normalDirection, viewDirection)), _Fresnel);

                //透明剔除
                half alpha = FresnelPower * _ColorOut.a + 0.5;
                clip((alpha - _AlphaClipValue) - 0.5);

                half2 uv = i.uv.xy;

                //noise
			#if defined(USE_NOISE)
				half2 noise = tex2D(_NoiseTex, i.uv.zw).xy;
                uv = lerp(uv, noise, _NoiseParam.xy);
			#endif 

                half3 col = tex2D(_MainTex, uv);

                //兰伯特模型(暗部区域不产生菲涅尔)
                Light mainLight = GetMainLight();
                half3 lightDirection = normalize(mainLight.direction.xyz);
                half3 lightColor = mainLight.color.rgb;
                half3 diffuseColor = lerp(_ColorIN.rgb, _ColorOut.rgb, FresnelPower) * _COLOR.rgb * _EmissiveMult;

                half3 finalColor = (saturate(dot(normalDirection, lightDirection)) * lightColor) * diffuseColor ;
                finalColor *= (col + 1);

                //遮罩
                // #if defined(USE_MASK) || defined(USE_DOUBLE_MASK)
                //     half mask = dot(tex2D(_MaskTex, i.uv.xy), _MaskChannel);
                //     mask = mask - _MaskStrength;

                //     #if defined(USE_DOUBLE_MASK)
                //         half mask2 = tex2D(_Mask2Tex, TRANSFORM_TEX(i.uv.zw, _Mask2Tex)).r;
                //         mask2 = mask2 - _Mask2Strength;
                //         mask *= mask2;
                //     #endif
                // #else
                //     half mask = 1 - _MaskStrength;
                // #endif

                return half4(finalColor, 1); //* saturate(mask));
            }
            ENDHLSL
        }

        // Pass
        // {
        //     Name "ShadowCaster"
        //     Tags{"LightMode" = "ShadowCaster"}

        //     ZWrite On
        //     ZTest LEqual
        //     Cull Back

        //     HLSLPROGRAM

        //     #pragma shader_feature _ALPHATEST_ON

        //     #pragma vertex ShadowPassVertex
        //     #pragma fragment ShadowPassFragment

        //     #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        //     #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
        //     #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
            
        //     struct Attributes
        //     {
        //         float4 normalOS : 
        //     }

        //     float4 GetShadowPositionHClip(Attributes input, float3 positionWS)
        //     {
        //         float3 normalWS = TransformObjectToWorldNormal(input.normalOS);
        //         float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, _LightDirection));

        //     #if UNITY_REVERSED_Z
        //         positionCS.z = min(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
        //     #else
        //         positionCS.z = max(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
        //     #endif

        //         return positionCS;
        //     }

        //     Varyings ShadowPassVertex(Attributes input)
        //     {
        //         Varyings output;

        //         float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
                
        //         output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);
        //         output.positionCS = GetShadowPositionHClip(input, positionWS);
                
        //         #if defined(_EXPLORE_ENVIRONMENT)
        //             output.positionWS = positionWS;
        //         #endif
                
        //         return output;
        //     }

        //     half4 ShadowPassFragment(Varyings input) : SV_TARGET
        //     {

        //     #if defined(_EXPLORE_ENVIRONMENT)
        //         half explore = CalculateExploreState(input.positionWS);
        //         CalculateExpolorClip(explore);
        //     #endif
                
        //     #if _ZD_DISSOLVEM || _ZD_DISSOLVEH
        //         half noise = SAMPLE_TEXTURE2D_X(_NoiseTex,sampler_NoiseTex,input.uv).r;
        //         clip(noise - _AlphaCut);
        //     #endif
                
        //         half mask = SAMPLE_TEXTURE2D(_MaskMap, sampler_MaskMap, input.uv).g;
        //         Alpha(mask, _BaseColor, _Cutoff);
        //         return 0;
        //     }

        //     ENDHLSL
        // }
    }
    
    CustomEditor "CustomShaderEditor"
}

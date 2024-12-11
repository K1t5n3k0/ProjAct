Shader "ZXShader/Effect/Fresnel_ZTest"
{
    Properties
    {
        [HDR]_COLOR ("COLOR", Color) = (1,1,1,1)
        [HDR]_ColorIN ("Color IN", Color) = (1,1,1,1)
        [HDR]_ColorOut ("Color Out", Color) = (0.5,0.5,0.5,1)
        
        _EmissiveMult ("Emissive Light", Float ) = 1
        _Fresnel ("Fresnel", Float ) = 1
        _AlphaClipValue ("AlphaClipValue", Float ) = 0

        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("DstBlend", Float) = 10
        [Enum(UnityEngine.Rendering.CullMode)] _CullMode("Cull", Int) = 0

        _UVOffset ("UV 偏移", Vector) = (0,0,0,0)

        [HideInInspector][Enum(Zero,0,One,1,Two,2)] __MaskMode ("Mask Mode", Float) = 0
        _MaskTex ("Mask Texture", 2D) = "white" {}
        _MaskChannel ("Mask Channel", Vector) = (1,0,0,0)
        _MaskRotation ("Mask Rotation", Range(0, 360)) = 0

        _Mask2Tex ("Mask 2 Texture", 2D) = "white" {}
        _MaskStrength ("Mask Strength", Float ) = 0
        _Mask2Strength ("Mask 2 Strength", Float) = 0

        _StencilComp ("Stencil Comparison", Float) = 8
        _Stencil ("Stencil ID", Float) = 0
        _StencilOp ("Stencil Operation", Float) = 0
        _StencilWriteMask ("Stencil Write Mask", Float) = 255
        _StencilReadMask ("Stencil Read Mask", Float) = 255
        
        _ColorMask ("Color Mask", Float) = 15
    }
    SubShader
    {
        Tags 
        {
            "IgnoreProjector"="True"
            "Queue"="Transparent"
            "RenderType"="Transparent"
        }

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
            Tags
            { 
                "LightMode" = "UniversalForward" 
            }

            ZWrite On
            ColorMask 0
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "CGIncludes/Fresnel_ZTestImport.cginc"
            
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
            Tags
            {
                "LightMode" = "LightweightForward"
            }

            Blend SrcAlpha [_DstBlend]
            ZWrite Off
            ColorMask [_ColorMask]

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            #pragma multi_compile_local __ USE_MASK USE_DOUBLE_MASK

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                half2 texcoord0 : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 posWorld : TEXCOORD0;
                float3 normalDir : TEXCOORD1;
                half4 uv : TEXCOORD2;
            };

            #include "CGIncludes/Fresnel_ZTestImport.cginc"

            v2f vert (a2v v)
            {
                v2f o;

                VertexPositionInputs vertexInputs = GetVertexPositionInputs(v.vertex);
                VertexNormalInputs normalInputs = GetVertexNormalInputs(v.normal);

                o.pos = vertexInputs.positionCS;
                o.posWorld = vertexInputs.positionWS;
                o.normalDir = normalInputs.normalWS;

            #if defined(USE_MASK) || defined(USE_DOUBLE_MASK)
                o.uv = v.texcoord0.xyxy;
                o.uv.xy -= 0.5;
                half2 cosSin = sin(half2(_MaskRotation.xx) * 0.0174533 + half2(1.5708, 0));
                o.uv.xy = mul(o.uv.xy, half2x2(cosSin.x, -cosSin.y, cosSin.y, cosSin.x));

                o.uv += 0.5 + _UVOffset * _Time.g;
                o.uv.xy = TRANSFORM_TEX(o.uv.xy, _MaskTex);

            #if defined(USE_DOUBLE_MASK)
                o.uv.zw = TRANSFORM_TEX(o.uv.zw, _Mask2Tex);
            #endif
            #endif
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                //菲涅尔
                half3 normalDirection = normalize(i.normalDir);
                half3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);
                half FresnelPower = pow(1- max(0, dot(normalDirection, viewDirection)), _Fresnel);

                //透明剔除
                half alpha = FresnelPower * _ColorOut.a + 0.5;
                clip ((alpha - _AlphaClipValue) - 0.5);

                //兰伯特模型
                Light light = GetMainLight();
                half3 diffuseColor = lerp(_ColorIN.rgb, _ColorOut.rgb, FresnelPower) * _COLOR.rgb * _EmissiveMult;
                half3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                half3 finalColor = (saturate(dot(normalDirection, light.direction)) * light.color + ambient) * diffuseColor ;

             #if defined(USE_MASK) || defined(USE_DOUBLE_MASK)
                half mask = dot(tex2D(_MaskTex, i.uv.xy), _MaskChannel);
                mask = mask - _MaskStrength;

                #if defined(USE_DOUBLE_MASK)
                    half mask2 = tex2D(_Mask2Tex, TRANSFORM_TEX(i.uv.zw, _Mask2Tex)).r;
                    mask2 = mask2 - _Mask2Strength;
                    mask *= mask2;
                #endif
            #else
                half mask = 1 - _MaskStrength; 
            #endif

                return half4(finalColor,  alpha * _COLOR.a * saturate(mask));
            }
            ENDHLSL
        }

    }
    
    CustomEditor "FresnelShaderEditor"
}

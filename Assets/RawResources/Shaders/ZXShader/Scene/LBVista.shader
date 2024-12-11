Shader "ZXShader/Scene/LBVista"
{
    Properties
    {
        _Color ("Color", Color) = (1, 1, 1, 1)
        _MainTex ("Texture", 2D) = "white" {}

        [Toggle] _Light_Effect("Light Effect", Float) = 0.0

        [KeywordEnum(None, On, Blend)]  _Alpha_Cutoff ("Cutoff", Float) = 0.0
        _Cutoff("Cutoff Alpha", Range(0.0, 1.0)) = 0.5

        [Toggle] _Vertical_Fog("_Vertical Fog", Float) = 0.0
        _LowLine ("Low Line", Float) = 0
        _HighLine ("High Line", Float) = 50

        [Toggle(_SKYBOX_ON)] _SkyBox("SkyBox", Float) = 0.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue" = "Geometry-90"}
        LOD 100

        Pass
        {
            Tags{"LightMode" = "UniversalForward"}

            Blend SrcAlpha OneMinusSrcAlpha
            // ZTest Always

            CGPROGRAM

            #pragma multi_compile _ _LIGHT_EFFECT_ON
            #pragma multi_compile _ _ALPHA_CUTOFF_ON _ALPHA_CUTOFF_BLEND
            #pragma multi_compile _ _VERTICAL_FOG_ON
            #pragma multi_compile _ _SKYBOX_ON

            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"

            half3 LinearToSRGB(half3 c)
            {
                half3 sRGBLo = c * 12.92;
                half3 sRGBHi = (pow(c, half3(1.0/2.4, 1.0/2.4, 1.0/2.4)) * 1.055) - 0.055;
                half3 sRGB   = (c <= 0.0031308) ? sRGBLo : sRGBHi;
                return sRGB;
            }

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;

            #if defined(_VERTICAL_FOG_ON)
                float fogCol: TEXCOORD1;
            #endif
            };

            CBUFFER_START(UnityPerMaterial)
            sampler2D   _MainTex;
            float4      _MainTex_ST;

            half4       _Color;
            half        _Cutoff;

            float       _LowLine;
            float       _HighLine;
            CBUFFER_END 
            
            half4       ZxPlaneShadowParam;
            half4       _MainLightColor;

            v2f vert (appdata v)
            {
                v2f o;

            #if defined(_VERTICAL_FOG_ON)
                float4 posWorld = mul(unity_ObjectToWorld, v.vertex);
                o.vertex = mul(UNITY_MATRIX_VP, posWorld);

                o.fogCol = (posWorld.y - ZxPlaneShadowParam.w - _LowLine) / (_HighLine - _LowLine);
  
            #else
                o.vertex = UnityObjectToClipPos(v.vertex);
            #endif

            #if defined(_SKYBOX_ON)
                //忽视相机裁剪影响 保持天空盒的作用
                #if UNITY_REVERSED_Z
                    o.vertex.z = o.vertex.w * 0.00001f;
                #else
                    o.vertex.z = o.vertex.w * 0.99999f;
                #endif
            #endif

                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);

                _Color.rgb = LinearToSRGB(_Color.rgb);
                
            #if defined(_ALPHA_CUTOFF_ON) || defined(_ALPHA_CUTOFF_BLEND)
                clip (col.a - _Cutoff);
            #endif

                col *= _Color;

            #if defined(_LIGHT_EFFECT_ON)
                col.rgb *= LinearToSRGB(_MainLightColor.rgb);
            #endif

            #if defined(_VERTICAL_FOG_ON)
                col.rgb = lerp((unity_FogColor).rgb, col.rgb, saturate(i.fogCol));
            #endif

            #if !defined(_ALPHA_CUTOFF_BLEND)
                col.a = 1;
            #endif
                

                return col;
            }
            ENDCG
        }
    }
}

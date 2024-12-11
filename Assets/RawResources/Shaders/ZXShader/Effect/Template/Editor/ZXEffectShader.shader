Shader "Hidden/ZXEffectShader"
{
    Properties
    {
        [Popup(AlphaBlend, 10, Additive, 1)] _DstBlend ("混合模式", Int) = 10
        [Popup(LessEqual, 4, Always, 8)] _ZTest("深度测试", Int) = 4
        [Enum(UnityEngine.Rendering.CullMode)] _CullMode("剔除模式", Int) = 0

        _MainTex ("主贴图", 2D) = "white" { }
        [Indent_add]
        [HDR]_MainColor ("颜色", Color) = (1, 1, 1, 1)
    }
    SubShader
    {
        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        //#include "../HLSL/EffectCg.hlsl"

        CBUFFER_START(UnityPerMaterial)
        float4 _MainTex_ST;
        half4 _MainColor;
        CBUFFER_END
        ENDHLSL
        
        Tags 
        {
            "IgnoreProjector"="True"
            "Queue"="Transparent"
            "RenderType"="Transparent"
            "PreviewType"="Plane"
        }

        LOD 100

        Pass
        {
            Blend SrcAlpha [_DstBlend]
            Cull [_CullMode]
            ZTest [_ZTest]
            ZWrite Off

            HLSLPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag
            
            struct appdata
            {
                float4 vertex: POSITION;
                float2 uv: TEXCOORD0;
            };
            
            struct v2f
            {
                float4 vertex: SV_POSITION;
                float2 uv: TEXCOORD0;
            };
            
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            
            v2f vert(appdata v)
            {
                v2f o;
                VertexPositionInputs vertexPos = GetVertexPositionInputs(v.vertex.xyz);
                o.vertex = vertexPos.positionCS;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }
            
            half4 frag(v2f i): SV_Target
            {
                half4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv) * _MainColor;
                return col;
            }
            ENDHLSL            
        }
    }
    CustomEditor "ZXEffectShaderEditor"
}

Shader "ZXShader/Effect/ModelsNoiseMask"
{
    Properties
    {
        [Popup(AlphaBlend, 10, Additive, 1)] _DstBlend ("混合模式", Int) = 10
        [Popup(LessEqual, 4, Always, 8)] _ZTest("深度测试", Int) = 4
        [Enum(UnityEngine.Rendering.CullMode)] _CullMode("裁剪方式", Int) = 0

        [Separator(Main)][BeginVertical]
        _MainTex ("主帖图", 2D) = "white" {}
        [HDR]_COLOR ("颜色", Color) = (1, 1, 1, 1)
        _MainRotation ("旋转", Range(0, 360)) = 0
        _Saturation ("饱和度", Range(0, 1)) = 1
        [AlphaChannel]_AlphaChannel ("透明通道", Vector) = (0,0,0,1)
        [EndVertical]

        [BeginVertical]
        _MaskTex ("遮罩帖图", 2D) = "white" {}
        _MaskRotation ("旋转", Range(0, 360)) = 0
        _MaskStrength ("强度", Float) = 0
        [AlphaChannel]_MaskChannel ("透明通道", Vector) = (1,0,0,0)

        [Space][Space]
        _UVOffset ("UV偏移(XY:Main ZW:Mask)", Vector) = (0,0,0,0)
        [EndVertical]

        [Separator(Noise)][BeginVertical]
        _NoiseTex ("扰动贴图", 2D) = "black" {}
        [Space][Space]
        _NoiseParam ("扰动参数(XY:强度 ZW:偏移)", Vector ) = (0,0,0,0)
        [EndVertical]

        [BeginVertical]
        _NoiseMaskTex ("扰动遮罩", 2D) = "white" {}
        _NoiseMaskRotation ("旋转", Range(0, 360)) = 0
        _NoiseMaskStrength ("强度", Range(0, 1)) = 1
        [AlphaChannel]_NoiseMaskChannel ("透明通道", Vector) = (1,0,0,0)
        _UVOffset2 ("UV偏移(XY:NoiseMask)", Vector) = (0,0,0,0)
        [EndVertical]
        
        [BeginVertical]
        [Enum(Never, 0, Color, 1)]_SetVertexColor ("SetVertexColor", Float) = 1
        [EndVertical]

        [Hide]_StencilComp ("Stencil Comparison", Float) = 8
        [Hide]_Stencil ("Stencil ID", Float) = 0
        [Hide]_StencilOp ("Stencil Operation", Float) = 0
        [Hide]_StencilWriteMask ("Stencil Write Mask", Float) = 255
        [Hide]_StencilReadMask ("Stencil Read Mask", Float) = 255
        [Hide]_ColorMask ("Color Mask", Float) = 15
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
            Tags
            { 
                "LightMode" = "LightweightForward" 
            }

            Blend SrcAlpha [_DstBlend]
            Cull [_CullMode]
            ZTest [_ZTest]
            ZWrite Off
            ColorMask [_ColorMask]

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile_local __ UNITY_UI_CLIP_RECT

            #include "UnityCG.cginc"
            #include "CGIncludes/ParticleCg.cginc"

        #if defined(UNITY_UI_CLIP_RECT)
            #include "UnityUI.cginc"
        #endif

            sampler2D _MainTex;
            sampler2D _MaskTex;
            sampler2D _NoiseTex;
            sampler2D _NoiseMaskTex;

            half4 _MainTex_ST;
            half4 _MaskTex_ST;
            half4 _NoiseTex_ST;
            half4 _NoiseMaskTex_ST;
            half4 _MainTex_TexelSize;
            half4 _COLOR;
            half  _MainRotation;
            half  _MaskRotation;
            half  _NoiseMaskRotation;
            half4 _AlphaChannel;
            half4 _MaskChannel;
            half4 _NoiseMaskChannel;
            float  _MaskStrength;
            float  _NoiseMaskStrength;
            half  _Saturation;
            half4 _UVOffset;
            half4 _UVOffset2;
            half4 _NoiseParam;
            half _SetVertexColor;
            half4 _ClipRect;

            struct appdata
            {
                float4 vertex : POSITION;
                float4 vertexColor : COLOR;
                float2 texcoord0 : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 vertexColor : COLOR;
                float4 uv0 : TEXCOORD0;//Main Mask
                float4 uv1 : TEXCOORD1;//NoiseMask Noise
      
            #if defined(UNITY_UI_CLIP_RECT)
                float2 vertex: TEXCOORD2;
            #endif
            };


            v2f vert (appdata v)
            {
                v2f o = (v2f)0;
                o.vertexColor = v.vertexColor * _COLOR;

				if(_SetVertexColor == 1)
				{
					o.vertexColor.rgb = pow(o.vertexColor.rgb, 0.4545);
				}

            #if defined(UNITY_UI_CLIP_RECT)
                o.vertex.xy = v.vertex.xy;
            #endif

				o.pos = UnityObjectToClipPos( v.vertex );

                o.uv0 = v.texcoord0.xyxy + _UVOffset * _Time.g;
                o.uv1.xy = v.texcoord0 + _UVOffset2.xy * _Time.g;
                o.uv1.zw = v.texcoord0 + _NoiseParam.zw * _Time.g;
                
                o.uv0.xy = Rotate(o.uv0.xy, _MainRotation);
                o.uv0.zw = Rotate(o.uv0.zw, _MaskRotation);
                o.uv1.xy = Rotate(o.uv1.xy, _NoiseMaskRotation);

                o.uv0.zw = TRANSFORM_TEX((o.uv0.zw), _MaskTex);
                o.uv1.xy = TRANSFORM_TEX((o.uv1.xy), _NoiseMaskTex);
                o.uv1.zw = TRANSFORM_TEX((o.uv1.zw), _NoiseTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 uv = i.uv0.xy;

                // NoiseMask
                float noiseMask = dot(tex2D(_NoiseMaskTex, i.uv1.xy), _NoiseMaskChannel);
                half2 noiseStength = _NoiseParam.xy * lerp(1.0, noiseMask, _NoiseMaskStrength);

                //噪声
                fixed2 noise = tex2D(_NoiseTex, i.uv1.zw).xy * 100;
                uv += noise * noiseStength * _MainTex_TexelSize.xy;

                //主纹理采样
                uv =  TRANSFORM_TEX(uv, _MainTex);
                fixed4 col = tex2D(_MainTex, uv);

                //Alpha通道、去色
                col.a = dot(_AlphaChannel, col);
                fixed gray = dot(col.rgb, float3(0.3,0.59,0.11));
                col.rgb = lerp(gray, col.rgb, _Saturation);

                //顶点色，颜色加强
                col *= i.vertexColor;

                fixed mask = dot(tex2D(_MaskTex, i.uv0.zw), _MaskChannel);
                col.a *= max(mask - _MaskStrength, 0);

            #if defined(UNITY_UI_CLIP_RECT)
                col.a *= UnityGet2DClipping(i.vertex.xy, _ClipRect);
            #endif
            
                return col;
            }
            ENDCG
        }
    }
    CustomEditor "CustomShaderEditor"
}

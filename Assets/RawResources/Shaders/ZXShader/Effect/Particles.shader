Shader "ZXShader/Effect/Particles"
{
    Properties
    {
        _MainTex ("Main Texture", 2D) = "white" {}
        _MainRotation ("Main Rotation", Range(0.0, 360.0) ) = 0
        [Toggle] _UseGray("去色", Float) = 0
        [Toggle(USE_RED_AS_ALPHA)] _UseRedasAlpha("去黑底", Float) = 0
        [Toggle] _enhanceMode("颜色增强模式", Float) = 0

        [Toggle(USE_HUE_SHIFT)] _UseHueShift("使用色相偏移", Float) = 0

        [Toggle(USE_MASK)] _UseMask("Use Mask", Float) = 0
        _MaskTex ("Mask Texture", 2D) = "white" {}
        _MaskRotation ("Mask Rotation", Range(0.0, 360.0)  ) = 0

        [Toggle(USE_NOISE)] _UseNoise("Use Noise", Float) = 0
        _NoiseTex ("Noise Texture", 2D) = "white" {}
        [Toggle] _offsetMode("MaskOrNoise Offset", Float) = 0

        [Toggle(USE_SOFT_OVER)] _UseSoftOver("软粒子", Float) = 0
        _SoftOverGround ("软粒子平面", Range(-3.0, 2.0) ) = 0

        [Toggle(UI_MASK_CLIP)] _UIClip("Is Using with UI Clip", Float) = 0
        [Toggle(CAVE_LIGHT)] _CaveLight("Is Used in Cave Scene", Float) = 0

        _StencilComp ("Stencil Comparison", Float) = 8
        _Stencil ("Stencil ID", Float) = 0
        _StencilOp ("Stencil Operation", Float) = 0
        _StencilWriteMask ("Stencil Write Mask", Float) = 255
        _StencilReadMask ("Stencil Read Mask", Float) = 255
        
        _ColorMask ("Color Mask", Float) = 15

	    [Enum(UnityEngine.Rendering.CompareFunction)] _ZTest("ZTest", Int) = 4
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("DstBlend", Int) = 1
        [Enum(UnityEngine.Rendering.CullMode)] _Cull ("Cull", Float) = 0

        [HideInInspector] _UIEffectAlpha("_UIEffectAlpha", Float) = 1
        [Enum(Never, 0, Color, 1, Alpha, 2)]_SetVertexColor ("SetVertexColor", Float) = 1
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
            Blend SrcAlpha [_DstBlend]
            Cull [_Cull]
            ZWrite Off
	        ZTest[_ZTest]
            ColorMask [_ColorMask]

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile_local __ USE_RED_AS_ALPHA

            #pragma multi_compile_local __ USE_MASK
            #pragma multi_compile_local __ USE_NOISE
            #pragma multi_compile_local __ USE_SOFT_OVER

            #pragma multi_compile_local __ USE_HUE_SHIFT

            #pragma multi_compile_local __ UI_MASK_CLIP
            #pragma multi_compile_local __ CAVE_LIGHT
            #pragma multi_compile __ _CAVE_LIGHTING_FOG //_WILD_LIGHTING_FOG
           
            #include "UnityCG.cginc"

            #if defined(CAVE_LIGHT) && (defined(_CAVE_LIGHTING_FOG) || defined(_WILD_LIGHTING_FOG))
                #include "Assets/RawResources/Shaders/GSShaders/GSEnv/Core/LBCaveLightingFog.hlsl"
            #endif

            #if defined(UI_MASK_CLIP)
                #include "UnityUI.cginc"
            #endif

            struct appdata
            {
                float4 vertex : POSITION;
                float4 vertexColor : COLOR;
                float4 texcoord0 : TEXCOORD0;
            #if defined(USE_MASK) || defined(USE_NOISE)
                float4 texcoord1 : TEXCOORD1;
            #else
                float2 texcoord1 : TEXCOORD1;
            #endif
            
                float2 texcoord2 : TEXCOORD2;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 vertexColor : COLOR;
                float4 uv0 : TEXCOORD0;
            #if defined(USE_MASK) || defined(USE_NOISE)
                float4 uv1 : TEXCOORD1;
            #else
                float2 uv1 : TEXCOORD1;
            #endif
            #if defined(USE_SOFT_OVER) || defined(UI_MASK_CLIP) || defined(CAVE_LIGHT)
                float4 posWorld : TEXCOORD3;
            #endif

            #if defined(USE_HUE_SHIFT)
                half _hueShift_Offset : TEXCOORD4;
            #endif
            };

            CBUFFER_START(UnityPerMaterial)
            uniform sampler2D _MainTex;
            uniform float4 _MainTex_ST;
            float _MainRotation;
            float _enhanceMode;
            half _UseGray;
			uniform half _SetVertexColor;

            uniform sampler2D _MaskTex;
            uniform float4 _MaskTex_ST;
            float _MaskRotation;

            uniform sampler2D _NoiseTex;
            uniform float4 _NoiseTex_ST;

            float _offsetMode;

            float _SoftOverGround;
            half _UIEffectAlpha;
            CBUFFER_END 
            float4 _UIClipRect;
            half4 ZxPlaneShadowParam;
            
            v2f vert (appdata v)
            {
                v2f o = (v2f)0;
            #if defined(USE_SOFT_OVER) || defined(UI_MASK_CLIP) || defined(CAVE_LIGHT)
                o.posWorld = mul(unity_ObjectToWorld, v.vertex);
            #endif
                o.pos = UnityObjectToClipPos( v.vertex );

                //顶点色
                o.vertexColor = v.vertexColor;

				if(_SetVertexColor == 1)
				{
					o.vertexColor.rgb = pow(o.vertexColor.rgb, 0.4545);
				}
				else if(_SetVertexColor == 2)
				{
					o.vertexColor = pow(o.vertexColor, 0.4545);
				}

                //颜色加强
                float enhance = v.texcoord1.x + 1.0;
                o.vertexColor.rgb *= enhance;
                o.vertexColor.a *= 1- _enhanceMode + enhance * _enhanceMode;

                //uv
                o.uv0.xy = v.texcoord0.xy;

                //Mask强度  
                o.uv0.z = v.texcoord1.y;

                //主纹理偏移旋转 Mask偏移旋转
            #if defined(USE_MASK) || defined(USE_NOISE)
                o.uv1 = v.texcoord0.xyxy + float4(v.texcoord0.zw, v.texcoord1.zw)- 0.5;
                float4 CosSin = sin(float4(_MainRotation.xx, _MaskRotation.xx) * 0.0174533 + float4(1.5708, 0, 1.5708, 0));
                o.uv1.xy = mul(o.uv1.xy, float2x2(CosSin.x, -CosSin.y, CosSin.y, CosSin.x));
                o.uv1.zw = mul(o.uv1.zw, float2x2(CosSin.z, -CosSin.w, CosSin.w, CosSin.z));
                o.uv1 += 0.5;
            #else
                float2 CosSin = sin(_MainRotation.xx * 0.0174533 + float2(1.5708, 0));
                o.uv1 = mul(v.texcoord0.xy + v.texcoord0.zw - 0.5, float2x2(CosSin.x, -CosSin.y, CosSin.y, CosSin.x)) + 0.5;
            #endif

                //Noise强度
            #if defined(USE_NOISE)
                o.uv0.w = v.texcoord2.x;
                if (_offsetMode > 0.9)
                {
                    o.uv0.xy = o.uv1.zw;
                    o.uv1.zw = v.texcoord0.xy;
                }
            #endif


            #if defined(USE_HUE_SHIFT)
                o._hueShift_Offset = v.texcoord2.y;
            #endif

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //主纹理UV
                float2 uv = i.uv1.xy;

                //噪声
            #if defined(USE_NOISE)
                float2 noise = tex2D(_NoiseTex,TRANSFORM_TEX(i.uv0.xy, _NoiseTex));
                uv = lerp(uv, noise, i.uv0.w);
            #endif    

                //主纹理采样
                fixed4 col = tex2D(_MainTex, TRANSFORM_TEX(uv, _MainTex));

                //去黑底
            #if defined(USE_RED_AS_ALPHA)
                col.a = col.r;
            #endif

                half gray = dot(col.rgb, float3(0.3,0.59,0.11));
                
                //色相偏移
            #if defined(USE_HUE_SHIFT)
                half3 tempColorR = tex2D(_MainTex, TRANSFORM_TEX((uv  + i._hueShift_Offset), _MainTex));
                half3 tempColorB = tex2D(_MainTex, TRANSFORM_TEX((uv  - i._hueShift_Offset), _MainTex));

                half grayR = dot(tempColorR.rgb, float3(0.3,0.59,0.11));
                half grayB = dot(tempColorB.rgb, float3(0.3,0.59,0.11));

                half3 grayCol = half3(grayR, gray, grayB);
                col.rgb = half3(tempColorR.r, col.g, tempColorB.b);

                col.rgb = lerp(col.rgb, grayCol, _UseGray);
            #else
                col.rgb = lerp(col.rgb, gray, _UseGray);
            #endif

                //Mask
            #if defined(USE_MASK)
                float mask = tex2D(_MaskTex,TRANSFORM_TEX(i.uv1.zw, _MaskTex)).r;
                col.a *= saturate(mask - i.uv0.z);
            #endif

                col *= i.vertexColor;

                //软粒子
            #if defined(USE_SOFT_OVER)
                col.a *= saturate((i.posWorld.y - _SoftOverGround - ZxPlaneShadowParam.w) * 4.0);
            #endif

            #if defined(CAVE_LIGHT) && (defined(_CAVE_LIGHTING_FOG) || defined(_WILD_LIGHTING_FOG))
                ApplyLBCaveFogAdd(i.posWorld, col);
            #endif

            #if defined(UI_MASK_CLIP)
                col.a *= UnityGet2DClipping(i.posWorld.xy, _UIClipRect);
            #endif

                col.a *= _UIEffectAlpha;

                return col;
            }
            ENDCG
        }
    }
    CustomEditor "ParticlesShaderEditor"
}

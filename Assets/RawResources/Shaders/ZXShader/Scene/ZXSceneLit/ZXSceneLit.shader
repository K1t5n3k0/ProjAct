
Shader "ZXShader/Scene/ZXSceneLit"
{
    Properties
    {
        [Flod(5)] SurfaceOptions("表面设置", Float) = 1
        [Popup(Front, 2, Back, 1, Both, 0)] _Cull("渲染面数", Float) = 2.0
        [SurfaceType] _Surface ("透明模式", Float) = 0
        [Toggle(_ALPHATEST_ON)] _AlphaClip("开启透明剔除", Float) = 0
        [Indent_add]
        [HideBy(_AlphaClip, 1)] _Cutoff("透明剔除", Range(0.0, 1.0)) = 0.5
        [Indent_sub]

        [ToggleOff(_RECEIVE_SHADOWS_OFF)] _ReceiveShadows("接收阴影", Float) = 1.0

        [Flod(29)] SurfaceInput("表面贴图", Float) = 1
        [BeginVertical]
        [Tex(1)] _BaseMap("主贴图", 2D) = "white" {}
        _BaseColor("颜色", Color) = (1,1,1,1)

        [Tex(1)]_NormalMap("法线(B:光滑度)", 2D) = "bump" {}
        _NormalScale("强度", Float) = 1.0

        [Tex]_MOE("R:金属 G:AO B:自发光", 2D) = "white" {}
        [Tex]_MaskMap("G:透明度", 2D) = "white" {}
        _Metallic("金属度", Range(0.0, 1.0)) = 0
        _Smoothness("光滑度", Range(0.0, 1.0)) = 0.5
        _OcclusionStrength("AO强度", Range(0.0, 1.0)) = 1.0

        _TilingAndOffset("缩放和偏移", Vector) = (1,1, 0,0)
        [EndVertical]

        [BeginVertical]
        [Enum(None, 0, Emission, 1, Flicker, 2)][Keyword(_EMISSION, 1, _FLICKER, 2)] _Emission_ON("自发光模式", Float) = 0
        [Indent_add]
        [HideBy(_Emission_ON, 1)][HDR]_EmissionColor("自发光颜色", Color) = (0, 0, 0)
        [HideBy(_Emission_ON, 1)][Toggle(_EMISSION_BLEND_ALBEDO)] _Emission_Blend_Albedo_ON("混合颜色贴图", Int) = 0
        
        [HideBy(_Emission_ON, 2)][HDR]_FlickerColor("呼吸灯颜色", Color) = (0, 0, 0)
        [HideBy(_Emission_ON, 2)] _FlickerSpeed("呼吸灯速度", Range(0, 5)) = 1
        [HideBy(_Emission_ON, 2)][Toggle] _WorldNoise("世界控制随机化", Int) = 0
        [Indent_sub][EndVertical]

        [BeginVertical]
        [Toggle(_SELF_ENVLIGHT)]_UseSelfEnvLight("开启自身环境光", Float) = 0
        [Indent_add]
        [HideBy(_UseSelfEnvLight, 1)]_SkyColor("环境光颜色", Color) = (0.5, 0.5, 0.5, 1)
        [HideBy(_UseSelfEnvLight, 1)][Tex]_CubeMap("反射贴图", Cube) = "Skybox"{}
        [HideBy(_UseSelfEnvLight, 1)]_EnvCubeRotation("旋转(绕Y轴)", Range(0, 360)) = 0
        [HideBy(_UseSelfEnvLight, 1)]_EnvCubeStrength("反射强度", Range(0.0, 2.0)) = 1.0
        [Indent_sub]
        [EndVertical]

        [BeginVertical]
        [Toggle(_ZX_ENV_SNOW)] _ZXSnow("开启雪面", Float) = 0 
        [HideBy(_ZXSnow, 1)][Tex]_ZXSnowMap ("雪面贴图(RG:法线 B:颜色强度)", 2D) = "bump" { }
        [Indent_add][Indent_add]
        [HideBy(_ZXSnow, 1)]_ZXSnowColor ("雪面颜色", Color) = (1, 1, 1, 1)
        [Indent_sub][Indent_sub]
        [HideBy(_ZXSnow, 1)]_ZXSnowMapParam ("X:缩放 Y:高光强度 Z:雪面强度 W:过渡", Vector) = (0.1, 1, 1, 10)
        [EndVertical]
		
		[BeginVertical]
        [Toggle][Pass(PlaneShadow)] SwitchPass("开关平面阴影Pass", Float) = 0.0
        _VirtualStrength("虚化强度", Float) = 0.0
		[EndVertical]

        [BeginVertical]
        [Toggle(_SOFT_OVER)] _SoftOver_ON("软接触面(地面要先渲染)", Float) = 0
        [HideBy(_SoftOver_ON, 1)] _SoftOverGround ("软粒子平面偏移量", Float ) = 0
        [EndVertical]

        [Flod(4)] Advanced("额外设置", Float) = 0
        [ToggleOff(_SPECULARHIGHLIGHTS_OFF)] _SpecularHighlights("高光开关", Float) = 1.0
        [ToggleOff(_ENVIRONMENTREFLECTIONS_OFF)] _EnvironmentReflections("环境光反射", Float) = 1.0

        [Enum(None, 0, Vertical, 1, Mixed, 2)][Keyword(_VERTICAL_FOG_ON, 1, _VERTICAL_FOG_MIXED, 2)] _Vertical_Fog ("高度雾效", Float) = 0
        [HideBy(_Vertical_Fog, 1)] _FogLowerLimit ("高度雾下限", Float) = 0
        [HideBy(_Vertical_Fog, 1)] _FogUpperLimint ("高度雾上限", Float) = 50

        // Blending state
        [Hide] _BlendMode("__blend", Float) = 0
        [Hide] _SrcBlend("__src", Float) = 1.0
        [Hide] _DstBlend("__dst", Float) = 0.0
        [Hide] _ZWrite("__zw", Float) = 1.0

        // Editmode props
        [Hide] _QueueOffset("Queue offset", Float) = 0.0

        // ObsoleteProperties
        [Hide] _GlossMapScale("Smoothness", Float) = 0.0
        [Hide] _Glossiness("Smoothness", Float) = 0.0
        [Hide] _GlossyReflections("EnvironmentReflections", Float) = 0.0
    }

    SubShader
    {
        // Universal Pipeline tag is required. If Universal render pipeline is not set in the graphics settings
        // this Subshader will fail. One can add a subshader below or fallback to Standard built-in to make this
        // material work with both Universal Render Pipeline and Builtin Unity Pipeline
        Tags{"RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True"}
        LOD 300

        // ------------------------------------------------------------------
        //  Forward pass. Shades all light in a single pass. GI + emission + Fog
        Pass
        {
            // Lightmode matches the ShaderPassName set in UniversalRenderPipeline.cs. SRPDefaultUnlit and passes with
            // no LightMode tag are also rendered by Universal Render Pipeline
            Name "ForwardLit"
            Tags{"LightMode" = "UniversalForward"}

            Blend[_SrcBlend][_DstBlend]
            ZWrite[_ZWrite]
            Cull[_Cull]

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard SRP library
            // All shaders must be compiled with HLSLcc and currently only gles is not using HLSLcc by default
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            // -------------------------------------   
            // Material Keywords
            #pragma shader_feature_local _ _ALPHATEST_ON
            #pragma shader_feature_local _ _EMISSION _FLICKER
            #pragma shader_feature_local _ _EMISSION_BLEND_ALBEDO
            
            #pragma shader_feature_local _SPECULARHIGHLIGHTS_OFF
            #pragma shader_feature_local _ENVIRONMENTREFLECTIONS_OFF
            #pragma shader_feature_local _RECEIVE_SHADOWS_OFF

            // -------------------------------------
            // Universal Pipeline keywords
            #pragma shader_feature _ _MAIN_LIGHT_SHADOWS
            #pragma shader_feature _ _ADDITIONAL_LIGHTS
            #pragma shader_feature _ _MIXED_LIGHTING_SUBTRACTIVE
            #pragma shader_feature _WORLD_CLOUD_OFF _WORLD_CLOUD_ON

            #pragma shader_feature_local _ _ZX_ENV_SNOW
            #pragma shader_feature_local _ _SELF_ENVLIGHT
            #pragma shader_feature_local _ _SOFT_OVER
            // -------------------------------------
            // Unity defined keywords
            // #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma shader_feature _ LIGHTMAP_ON
            #pragma shader_feature _ FOG_LINEAR
            #pragma shader_feature_local _ _VERTICAL_FOG_ON _VERTICAL_FOG_MIXED

            //--------------------------------------
            // GPU Instancing
            //#pragma multi_compile_instancing

            #define _NORMALMAP 1

            #pragma vertex LitPassVertex
            #pragma fragment LitPassFragment

            #include "HLSL\ZXSceneLitInput.hlsl"
            #include "HLSL\ZXSceneLitForwardPass.hlsl"
            ENDHLSL
        }

        Pass
        {
            Name "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}

            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull[_Cull]

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local _ALPHATEST_ON

            //--------------------------------------
            // GPU Instancing
            //#pragma multi_compile_instancing
            // #pragma shader_feature _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            #include "HLSL\ZXSceneLitInput.hlsl"
            #include "HLSL\ZXSceneShadowCasterPass.hlsl"
            ENDHLSL
        }

        Pass
        {
            Name "DepthOnly"
            Tags{"LightMode" = "DepthOnly"}

            ZWrite On
            ColorMask 0
            Cull[_Cull]

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature _ALPHATEST_ON
            // #pragma shader_feature _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            //--------------------------------------
            // GPU Instancing
            //#pragma multi_compile_instancing

            #include "HLSL\ZXSceneLitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"
            ENDHLSL
        }

        // This pass it not used during regular rendering, only for lightmap baking.
        Pass
        {
            Name "Meta"
            Tags{"LightMode" = "Meta"}

            Cull Off

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x

            #pragma vertex UniversalVertexMeta
            #pragma fragment UniversalFragmentMeta

            // #pragma shader_feature _SPECULAR_SETUP
            #pragma shader_feature _EMISSION
            // #pragma shader_feature _METALLICSPECGLOSSMAP
            #pragma shader_feature _ALPHATEST_ON
            // #pragma shader_feature _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            // #pragma shader_feature _SPECGLOSSMAP

            #include "HLSL\ZXSceneLitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitMetaPass.hlsl"

            ENDHLSL
        }

        Pass
        {
            Tags{"LightMode" = "PlaneShadow"}

			Blend SrcAlpha OneMinusSrcAlpha
			ZWrite Off
			Cull Back
			ColorMask RGB
			
		    Offset -1, -1//使阴影在平面之上  

            //模板测试使阴影叠加
			Stencil
			{
				Ref 0			
				Comp Equal			
				WriteMask 255		
				ReadMask 255
				//Pass IncrSat
				Pass Invert
				Fail Keep
				ZFail Keep
			}

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma shader_feature _ _ALPHATEST_ON // _ALPHABLEND_ON _ALPHAPREMULTIPLY_
            #pragma shader_feature __ FOG_OFF FOG_LINEAR //_WILD_LIGHTING_FO
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "HLSL\ZXSceneLitInput.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f 
            {
                //V2F_SHADOW_CASTER;
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;

                float ModelPos : TEXCOORD1;

            #if defined(FOG_LINEAR)
                float3 fogCoord : TEXCOORD2;
            #endif
            };

            v2f vert( appdata v)
            {
                v2f o;

                o.vertex = mul(UNITY_MATRIX_M, v.vertex);
                o.ModelPos.x = step(0, o.vertex.y - ZxPlaneShadowParam.w);

                //平面阴影
                float3 lightDir = normalize(ZxPlaneShadowParam.xyz);
                float dis = (ZxPlaneShadowParam.w - o.vertex.y) / lightDir.y;//标准化后斜边是1 三角形相似
				o.vertex.xyz = o.vertex.xyz + dis * lightDir;//计算按光方向到达的地面位置

                //方法二
                // o.vertex = mul(_World2Ground,o.vertex); // 将物体在世界空间的矩阵转换到地面空间
                // o.vertex.xz = o.vertex.xz - (o.vertex.y / lightDir.y)*lightDir.xz;// 用三角形相似计算沿光源方向投射后的XZ
                // o.vertex.y = 0;// 使阴影保持在接受平面上
                // o.vertex = mul(_Ground2World, o.vertex); // 阴影顶点矩阵返回到世界空间

                //离人物越远的阴影越虚
                float3 center = float3(unity_ObjectToWorld[0].w , ZxPlaneShadowParam.w ,unity_ObjectToWorld[2].w);
                o.ModelPos.x *= 1 - saturate(distance(o.vertex.xyz, center) * _VirtualStrength);

                o.vertex = mul(UNITY_MATRIX_VP, o.vertex);

            #if defined(FOG_LINEAR)
                o.fogCoord = ComputeFogFactor(o.vertex.z);
            #endif

                o.uv = TRANSFORM_TEX(v.uv, _BaseMap);
                
                return o;
            }

            float4 frag( v2f i ) : SV_Target
            {
                half alpha = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv).a * _BaseColor.a;

            #if defined(_ALPHATEST_ON)
                clip (alpha - _Cutoff);
            #endif

                half4 col = ZxObjSimpleShadowColor;

                //低于地面透明度为0 离人物越远的阴影越虚
                col.a *= i.ModelPos.x;

            #if defined(FOG_LINEAR)
               col.xyz = MixFog(col.rgb, i.fogCoord);
            #endif

                return col;
            }
            ENDHLSL
        }
    }
    // //Fallback "Hidden/Universal Render Pipeline/FallbackError"

    CustomEditor "ZXLitShaderEditor"
    // CustomEditor "LitEditor"
}

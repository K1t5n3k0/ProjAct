// Shader targeted for low end devices. Single Pass Forward Rendering.
Shader "ZXShader/Scene/ZXSimple Lit"
{
    // Keep properties of StandardSpecular shader for upgrade reasons.
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

        [Flod(10)] SurfaceInput("表面贴图", Float) = 1
        [Tex(1)] _BaseMap("主贴图", 2D) = "white" {}
        _BaseColor("颜色", Color) = (1,1,1,1)        
        [Tex(1)]_NormalMap("法线(B:光滑度)", 2D) = "bump" {}
        _NormalScale("强度", Float) = 1.0
        [Tex]_MaskMap("R:自发光 G:透明度", 2D) = "white" {}

        _Smoothness("光滑度", Range(0.0, 1.0)) = 0.5
        _SpecColor("高光颜色", Color) = (0.5, 0.5, 0.5, 0.5)
        
        [Space]
        [Toggle(_EMISSION)] _Emission_ON("开启自发光", Float) = 0
        [Indent_add]
        [HideBy(_Emission_ON, 1)][HDR]_EmissionColor("颜色", Color) = (0,0,0)
        [Indent_sub]

        [Flod(2)] Advanced("额外设置", Float) = 0
        [Toggle(_SPECGLOSSMAP)] _SpecularHighlights("高光开关", Float) = 1.0

        [Enum(None, 0, Vertical, 1, Mixed, 2)][Keyword(_VERTICAL_FOG_ON, 1, _VERTICAL_FOG_MIXED, 2)] _Vertical_Fog ("高度雾效", Float) = 0
        [HideBy(_Vertical_Fog, 1)] _FogLowerLimit ("Fog Lower Limit", Float) = 0
        [HideBy(_Vertical_Fog, 1)] _FogUpperLimint ("Fog Upper Limit", Float) = 50

        // Blending state
        [Hide][HideInInspector] _BlendMode("__blend", Float) = 0
        [Hide][HideInInspector] _SrcBlend("__src", Float) = 1.0
        [Hide][HideInInspector] _DstBlend("__dst", Float) = 0.0
        [Hide][HideInInspector] _ZWrite("__zw", Float) = 1.0
        [Hide][HideInInspector] _Cull("__cull", Float) = 2.0

        // Editmode props
        [Hide][HideInInspector] _QueueOffset("Queue offset", Float) = 0.0

        // ObsoleteProperties
        [Hide][HideInInspector] _MainTex("BaseMap", 2D) = "white" {}
        [Hide][HideInInspector] _Color("Base Color", Color) = (1, 1, 1, 1)
        [Hide][HideInInspector] _Shininess("Smoothness", Float) = 0.0
        [Hide][HideInInspector] _GlossinessSource("GlossinessSource", Float) = 0.0
        [Hide][HideInInspector] _SpecSource("SpecularHighlights", Float) = 0.0
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True"}
        LOD 300

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }

            // Use same blending / depth states as Standard shader
            Blend[_SrcBlend][_DstBlend]
            ZWrite[_ZWrite]
            Cull[_Cull]

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            // -------------------------------------
            // Material Keywords
            #pragma multi_compile _ _ALPHATEST_ON
            // #pragma shader_feature _ALPHAPREMULTIPLY_ON
            #pragma shader_feature _ _SPECGLOSSMAP
            // #pragma shader_feature _GLOSSINESS_FROM_BASE_ALPHA
            #pragma multi_compile _ _EMISSION
            #pragma shader_feature _RECEIVE_SHADOWS_OFF

            // -------------------------------------
            // Universal Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            // #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _  _ADDITIONAL_LIGHTS
            // #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            // #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE

            #pragma multi_compile _WORLD_CLOUD_OFF _WORLD_CLOUD_ON

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON
            
            #pragma shader_feature _ FOG_LINEAR
            #pragma shader_feature_local _ _VERTICAL_FOG_ON _VERTICAL_FOG_MIXED

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            #pragma vertex LitPassVertexSimple
            #pragma fragment LitPassFragmentSimple
            #define BUMP_SCALE_NOT_SUPPORTED 1

            #include "HLSL/ZXSimpleLitInput.hlsl"
            #include "HLSL/ZXSimpleLitForwardPass.hlsl"
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
            #pragma shader_feature _ALPHATEST_ON
            // #pragma shader_feature _GLOSSINESS_FROM_BASE_ALPHA

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            #include "HLSL/ZXSimpleLitInput.hlsl"
            #include "../ZXSceneLit/HLSL/ZXSceneShadowCasterPass.hlsl"
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
            // #pragma shader_feature _GLOSSINESS_FROM_BASE_ALPHA

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            #include "HLSL/ZXSimpleLitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"
            ENDHLSL
        }

        // This pass it not used during regular rendering, only for lightmap baking.
        Pass
        {
            Name "Meta"
            Tags{ "LightMode" = "Meta" }

            Cull Off

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x

            #pragma vertex UniversalVertexMeta
            #pragma fragment UniversalFragmentMetaSimple

            #pragma shader_feature _EMISSION
            #pragma shader_feature _SPECGLOSSMAP

            #include "HLSL/ZXSimpleLitInput.hlsl"
            #include "HLSL/ZXSimpleLitMetaPass.hlsl"

            ENDHLSL
        }
    }
    ////Fallback "Hidden/Universal Render Pipeline/FallbackError"
    CustomEditor "ZXLitShaderEditor"
}

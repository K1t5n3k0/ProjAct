Shader "ZXShader/Scene/Flow"
{
    Properties
    {
        [Enum(UnityEngine.Rendering.CullMode)] _CullMode("剔除模式", Int) = 0

        [Separator(Main)]
        [BeginVertical]
        [Tex(1)]_BaseMap ("主贴图", 2D) = "white" { }
        [HDR]_BaseColor ("颜色", Color) = (1, 1, 1, 1)
        
        [Tex(1)]_NormalMap("法线(B:光滑度)", 2D) = "bump" {}
        _NormalScale("强度", Float) = 1.0

        [Indent_add][Indent_add]
        _Tilling("平铺", Float) = 1
        [Indent_sub][Indent_sub]


        [Tex]_FlowMap ("流向图", 2D) = "Black" { }
        [Indent_add][Indent_add]
        _FlowSpeed ("流动速度", Float) = 1
        [HDR]_EmissionColor("自发光颜色", Color) = (0, 0, 0)
        [Indent_sub][Indent_sub]
        [EndVertical]

        [Separator(Lighting)]
        [BeginVertical]
        _SpecularColor ("高光颜色", Color) = (1,1,1,1)
        _Gloss ("高光大小", Range(8, 256)) = 256
        [EndVertical]

        [BeginVertical]
        _SkyColor("环境光颜色", Color) = (0.5, 0.5, 0.5, 1)
        [Tex]_CubeMap("反射贴图", Cube) = "Skybox"{}
        [IntRange]_MipLevel("模糊程度", Range(0, 8)) = 1
        _EnvCubeRotation("旋转(绕Y轴)", Range(0, 360)) = 0
        _EnvCubeStrength("反射强度", Range(0.0, 2.0)) = 1.0
    }
    
    SubShader
    {
        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

        CBUFFER_START(UnityPerMaterial)
        half4  _BaseColor;
        half4  _SpecularColor;
        half4  _EmissionColor;
        half   _FlowSpeed;
        half   _NormalScale;
        half   _Gloss;
        half   _MipLevel;
        half   _EnvCubeStrength;
        half   _EnvCubeRotation;
        half   _Tilling;
        half3  _SkyColor;
        CBUFFER_END

        TEXTURE2D(_BaseMap);            SAMPLER(sampler_BaseMap);
        TEXTURE2D(_NormalMap);          SAMPLER(sampler_NormalMap);
        TEXTURE2D(_FlowMap);            SAMPLER(sampler_FlowMap);
        TEXTURECUBE(_CubeMap);          SAMPLER(sampler_CubeMap);

        ENDHLSL
        
        Tags
        {
            "IgnoreProjector"="True"
            "Queue"="Geometry"
            "RenderType"="Geometry"
            "PreviewType"="Plane"
        }

        LOD 100

        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha
            ZTest LEqual
            Cull [_CullMode]

            HLSLPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag
            
            #pragma multi_compile _ FOG_LINEAR

            struct appdata
            {
                float4 vertex: POSITION;
                float3  normal: NORMAL;
                float4 tangent: TANGENT;
                float2 uv: TEXCOORD0;
            };
            
            struct v2f
            {
                float4 vertex: SV_POSITION;
                float3 uv: TEXCOORD0;//xy:uv z:fog
                float4 TtoW[3]: TEXCOORD1;
            };
            
            v2f vert(appdata v)
            {
                v2f o;
                VertexPositionInputs vertexPos = GetVertexPositionInputs(v.vertex.xyz);
                VertexNormalInputs normalInputs = GetVertexNormalInputs(v.normal, v.tangent);

                half3 worldPos      = vertexPos.positionWS;
                half3 worldNormal   = normalInputs.normalWS;
                half3 worldTangent  = normalInputs.tangentWS;
                half3 worldBinormal = normalInputs.bitangentWS;

                o.TtoW[0] = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
                o.TtoW[1] = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
                o.TtoW[2] = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);

                o.vertex = vertexPos.positionCS;
                o.uv.xy = v.uv;
                o.uv.z  = o.vertex.z;

                return o;
            }
            
            half4 frag(v2f i): SV_Target
            {
                //流向
                half2 flow = SAMPLE_TEXTURE2D(_FlowMap, sampler_FlowMap, i.uv) * (-2) + 1;
                flow *= _Tilling;
                half phase0 = frac(_Time.y * _FlowSpeed + 0.5);
                half phase1 = frac(_Time.y * _FlowSpeed + 1.0);
                half flowLerp = abs(1 - phase0 * 2);

                half2 uv = i.uv.xy * _Tilling;
                half2 uv0 = uv + flow * phase0;
                half2 uv1 = uv + flow * phase1;

                //法线
                half3 bump0 = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, uv0);
                half3 bump1 = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, uv1);
                half3 bump  = lerp(bump0, bump1, flowLerp);
                bump.xy *= _NormalScale;
                bump = normalize(half3(dot(i.TtoW[0].xyz, bump), dot(i.TtoW[1].xyz, bump), dot(i.TtoW[2].xyz, bump)));

                //颜色
                // half4 col = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uv) * _BaseColor;
                half4 col0 = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uv0);
                half4 col1 = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uv1);
                half4 col = lerp(col0, col1, flowLerp) * _BaseColor;

                //光照
                half3 worldPos = half3(i.TtoW[0].w, i.TtoW[1].w, i.TtoW[2].w);
                Light mainLight = GetMainLight();
                half3 L = normalize(mainLight.direction);
                half3 V = normalize(_WorldSpaceCameraPos - worldPos);
                half3 H = normalize(V + L);
                half  LoN = saturate(dot(bump, L));
                half  HoN = max(0, dot(bump, H));
                
                half3 diffuseColor = LoN * col.rgb;
                half3 specularColor = pow(HoN, _Gloss) * _SpecularColor.rgb;

                //环境光
                half3 reflectVector = reflect(-V, bump);
                //环境反射 旋转
                float2 CosSin = sin(_EnvCubeRotation.xx * 0.0174533 + float2(1.5708, 0));
                float2x2 M = float2x2
                (
                    CosSin.x, CosSin.y,
                    -CosSin.y, CosSin.x
                );
                reflectVector.xz = mul(M, reflectVector.xz);

                half4 encodedIrradiance = SAMPLE_TEXTURECUBE_LOD(_CubeMap, sampler_CubeMap, reflectVector, _MipLevel);
                half3 irradiance = encodedIrradiance.rgb * _EnvCubeStrength;
                half3 giColor = irradiance + _SkyColor * col;

                diffuseColor += specularColor + _EmissionColor + giColor;
                diffuseColor = MixFog(diffuseColor, ComputeFogFactor(i.uv.z));

                return half4(diffuseColor, col.a);
            }
            ENDHLSL            
        }
    }
    CustomEditor "CustomShaderEditor"
}

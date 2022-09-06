Shader "Genshin/GanYu_Face" {
    Properties {
        _MainTex ("Base Color", 2D) = "white" {}
        _LightMap     ("Face Shadow Map", 2D) = "white" {}
        _FaceMask ("Face Shadow Mask", 2D) = "white" {}
        _Ramp ("Ramp", 2D) = "white" {}
        _FaceShadowOffset ("Face Shadow Offset", float) = 0
        _FaceShadowPow ("Face Shadow Pow", float) = 2

        [Header(Rim)]
        _OffsetAmount ("Offset Amount", float) = 1
        _RimThreshold ("Rim Threshold", float) = 0.5
        _RimColor ("Rim Color", Color) = (1,1,1,1)

        [Header(Outline)]
        _OutlineWidth ("Outline Width", float) = 1
        _ColorSkin ("Skin Outline Color", Color) = (1,1,1,1)
 
    }
    SubShader {
        Tags { "RenderType"="Opaque" }

        Pass {
            Cull Back
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            sampler2D _MainTex;
            sampler2D _LightMap;
            sampler2D _FaceMask;
            sampler2D _Ramp;
            float _FaceShadowOffset;
            float _FaceShadowPow;

            sampler2D _CameraDepthTexture;
            float _OffsetAmount;
            float _RimThreshold;
            float4 _RimColor;

            float _ShowFeature;

            struct v2f {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 posWS : TEXCOORD1;
            };

            v2f vert (appdata_full v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord;
                o.posWS = mul(unity_ObjectToWorld, v.vertex);
                return o;
            }

            inline float3 ProjectOnPlane (float3 vec, float3 normal) {
                return vec - normal * dot(vec, normal);
            }

            fixed4 frag (v2f i) : SV_Target {
                float3 BaseColor = tex2D(_MainTex, i.uv);
                float3 ShadowCol = tex2D(_Ramp, float2(0.2, 0.85));


                float4 upDir = mul(unity_ObjectToWorld, float4(0,1,0,0));  
                float4 frontDir = mul(unity_ObjectToWorld, float4(0,0,1,0));
                float3 rightDir = cross(upDir, frontDir);
                float3 lightDir = UnityWorldSpaceLightDir(i.posWS);

                float FdotL = dot(normalize(frontDir.xz), normalize(lightDir.xz));
                float RdotL = dot(normalize(rightDir.xz), normalize(lightDir.xz));
                // 切换贴图正反
                float2 FaceMapUV = float2(lerp(i.uv.x, 1-i.uv.x, step(0, RdotL)), i.uv.y);
                float FaceMap = tex2D(_LightMap, FaceMapUV).r;
                // 下面这句话是错的
                //float FaceMap = lerp(LightMapColor.r, 1-LightMapColor.r, step(0, RdotL)) * step(0, FdotL);

                // 调整变化曲线，使得中间大部分变化速度趋于平缓
                FaceMap = pow(FaceMap, _FaceShadowPow);

                // 直接用采样的结果和FdotL比较判断，头发阴影和面部阴影会对不上，需要手动调整偏移
                // 但是直接在LightMap数据上±Offset会导致光照进入边缘时产生阴影跳变
                float sinx = sin(_FaceShadowOffset);
                float cosx = cos(_FaceShadowOffset);
                float2x2 rotationOffset1 = float2x2(cosx, sinx, -sinx, cosx); //顺时针偏移
                float2x2 rotationOffset2 = float2x2(cosx, -sinx, sinx, cosx); //逆时针偏移
                float2 FaceLightDir = lerp(mul(rotationOffset1, lightDir.xz), mul(rotationOffset2, lightDir.xz), step(0, RdotL));
                FdotL = dot(normalize(frontDir.xz), normalize(FaceLightDir));

                //FinalRamp = float4(FaceMap, FaceMap, FaceMap, 1);

                // 边缘光 (有问题)
                float2 posSS = float2(i.vertex.x / _ScreenParams.x, i.vertex.y / _ScreenParams.y);
                float2 offsetPosSS_L = posSS - float2(_OffsetAmount / i.vertex.w / _ScreenParams.x, 0);
                float2 offsetPosSS_R = posSS + float2(_OffsetAmount / i.vertex.w / _ScreenParams.x, 0);
                float offsetDepth_L = Linear01Depth(tex2D(_CameraDepthTexture, offsetPosSS_L));
                float offsetDepth_R = Linear01Depth(tex2D(_CameraDepthTexture, offsetPosSS_R));
                float offsetDepth = max(offsetDepth_L, offsetDepth_R);
                float trueDepth = Linear01Depth(tex2D(_CameraDepthTexture, posSS));
                float depthDiffer = offsetDepth - trueDepth;
                float rimMask = step(_RimThreshold, depthDiffer);
                // float3 rimCol = lerp(0, rimMask * _RimColor * _RimColor.a * i.vColor.r , clamp(pow(1-saturate(dot(vDirWS, lDirWS)), 5), 0, 0.25)); 
                float3 objFront = float3(0,0,1);
                float3 objBack = -objFront;
                float3 vDirWS = normalize(UnityWorldSpaceViewDir(i.posWS));
                float oFdotV = clamp(smoothstep(1 - saturate(dot(objFront.xz, vDirWS.xz)), 0.0, 0.1), 0.2, 1.0);
                float oBdotV = clamp(smoothstep(1 - saturate(dot(objBack.xz, vDirWS.xz)), 0.0, 0.1), 0.2, 1.0);
                float3 rimCol = rimMask * _RimColor * _RimColor.a * min(oBdotV, oFdotV);
            
                float3 finalRGB  = lerp(BaseColor, ShadowCol * BaseColor, step(FaceMap, 1-FdotL)) + rimCol;
                

                // For Demo
                if (_ShowFeature == 1) {
                    return float4(finalRGB, 1);
                }
                if (_ShowFeature == 2) {
                    return float4(0,0,0,0);
                }
                if (_ShowFeature == 3) {
                    return rimMask * float4(0.75, 0.75, 0, 1);
                }



                return float4(finalRGB, 1);
            }
            ENDCG
        }

        Pass {
            Tags {
                "LightMode" = "ForwardBase"
            }

            Cull Front

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            sampler2D _MainTex;
            sampler2D _LightMap;
            float _OutlineWidth;
            float4 _ColorSkin;

            float _ShowFeature;

            struct VertexOutput {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 color : TEXCOORD1;
            };

            VertexOutput vert (appdata_full v) {
                VertexOutput o;
                UNITY_INITIALIZE_OUTPUT(VertexOutput, o);
                float growInt = _ShowFeature == 3 ? 0.0 : 0.0001;
                float4 vertex = float4(v.vertex.xyz + v.tangent.xyz * _OutlineWidth * growInt * saturate(v.color.r), 1);
                o.uv = v.texcoord;
                o.pos = UnityObjectToClipPos(vertex);
                return o;
            }

            float4 frag (VertexOutput i) : SV_TARGET {
                float3 baseCol = tex2D(_MainTex, i.uv);
                float4 T_LightMap = tex2D(_LightMap, i.uv);

                float LayerMask = T_LightMap.a;
                float3 finalRGB = _ColorSkin * baseCol;

                if (_ShowFeature == 1) {
                    return float4(finalRGB, 1);
                }
                if (_ShowFeature == 2) {
                    return float4(0,0.75,0.75,1);
                }
                if (_ShowFeature == 3) {
                    return float4(0,0,0,0);
                }


                return float4(finalRGB, 1);
            }

            ENDCG

        }

        
    }
    Fallback "Diffuse"
}

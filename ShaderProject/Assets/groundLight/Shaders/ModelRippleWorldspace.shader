Shader "UI/WorldRippleWithRotationAndAxis"
{
    Properties
    {
        _MainTex("Base Texture", 2D) = "white" {}         // 基础贴图
        _RippleTex("Ripple Texture", 2D) = "white" {}     // 水波纹贴图
        _RippleSpeed("Ripple Speed", float) = 0.5        // 水波纹UV偏移速度
        _RippleStrength("Ripple Strength", float) = 0.3  // 水波纹叠加强度
        _Rotation("Texture Rotation", Range(0, 360)) = 0 // 贴图旋转角度
        _RippleAxis("Ripple Axis", Vector) = (0, 0, 1)   // 波纹旋转轴 (默认 Z 轴)
    }
    SubShader
    {
        Tags { "Queue" = "Transparent" "RenderType" = "Transparent" } // 透明队列，适用于UI
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert 
            #pragma fragment frag

            #include "UnityCG.cginc"

            // 属性
            sampler2D _MainTex;
            sampler2D _RippleTex;
            float _RippleSpeed;
            float _RippleStrength;
            float _Rotation;
            float3 _RippleAxis;

            // Declare texture transformation properties
            float4 _MainTex_ST;
            float4 _RippleTex_ST;

            struct appdata
            {
                float4 vertex : POSITION;  // 顶点位置
                float3 worldPos : TEXCOORD0; // 世界坐标
                float2 uv : TEXCOORD1;     // 纹理坐标
            };

            struct v2f
            {
                float4 pos : SV_POSITION; // 裁剪空间顶点位置
                float3 worldPos : TEXCOORD0; // 世界坐标
                float2 uv : TEXCOORD1;    // 纹理坐标
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);   // vert.pos -> clip space
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);    // uv -> clip space
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz; // object space -> world space
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed4 baseColor = tex2D(_MainTex, i.uv);

                // calculate the world space position of the ripple
                float3 ripplePos = i.worldPos;

                // calculate the rotation matrix
                float rad = radians(_Rotation); // angle to radian
                float cosTheta = cos(rad);
                float sinTheta = sin(rad);

                float3x3 rotationMatrix = float3x3(
                    cosTheta + _RippleAxis.x * _RippleAxis.x * (1 - cosTheta),
                    _RippleAxis.x * _RippleAxis.y * (1 - cosTheta) - _RippleAxis.z * sinTheta,
                    _RippleAxis.x * _RippleAxis.z * (1 - cosTheta) + _RippleAxis.y * sinTheta,

                    _RippleAxis.y * _RippleAxis.x * (1 - cosTheta) + _RippleAxis.z * sinTheta,
                    cosTheta + _RippleAxis.y * _RippleAxis.y * (1 - cosTheta),
                    _RippleAxis.y * _RippleAxis.z * (1 - cosTheta) - _RippleAxis.x * sinTheta,

                    _RippleAxis.z * _RippleAxis.x * (1 - cosTheta) - _RippleAxis.y * sinTheta,
                    _RippleAxis.z * _RippleAxis.y * (1 - cosTheta) + _RippleAxis.x * sinTheta,
                    cosTheta + _RippleAxis.z * _RippleAxis.z * (1 - cosTheta)
                );

                ripplePos = mul(rotationMatrix, ripplePos); // Application Matrix

                float2 rippleUV = ripplePos.xz; // use the current x and z as UV

                rippleUV.x += _Time.y * _RippleSpeed; 
                rippleUV.y += _Time.y * _RippleSpeed * 0.5;

                fixed4 rippleColor = tex2D(_RippleTex, rippleUV);

                fixed4 finalColor = baseColor;
                finalColor.rgb += rippleColor.r * _RippleStrength * baseColor.a; // 按透明度叠加波纹效果
                finalColor.a = baseColor.a;

                return finalColor;
            }
            ENDCG
        }
    }
    FallBack "Transparent/Diffuse"
}

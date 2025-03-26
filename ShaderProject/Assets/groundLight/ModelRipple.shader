Shader "UI/ModelRipple"
{
    Properties
    {
        _MainTex("Base Texture", 2D) = "white" {}         // 基础贴图
        _RippleTex("Ripple Texture", 2D) = "white" {}     // 水波纹贴图
        _RippleSpeed("Ripple Speed", float) = 0.5        // 水波纹UV偏移速度
        _RippleStrength("Ripple Strength", float) = 0.3  // 水波纹叠加强度
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

            // 屏幕宽高信息（用于UV调整）
            float4 _MainTex_ST;

            struct appdata
            {
                float4 vertex : POSITION; // 顶点位置
                float2 uv : TEXCOORD0;    // 纹理坐标
            };

            struct v2f
            {
                float4 pos : SV_POSITION; // 裁剪空间顶点位置
                float2 uv : TEXCOORD0;    // 纹理坐标
            };

            // 顶点着色器
            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex); // 模型空间到裁剪空间
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);  // UV变换
                return o;
            }

            // 片段着色器
            fixed4 frag(v2f i) : SV_Target
            {
                // 采样基础贴图颜色和透明度
                fixed4 baseColor = tex2D(_MainTex, i.uv);
                
                // 水波纹UV偏移计算
                float2 rippleUV = i.uv;
                rippleUV.x += _Time.y * _RippleSpeed;    // X轴偏移随时间变化
                rippleUV.y += sin(_Time.y) * _RippleSpeed; // Y轴波动模拟

                // 采样水波纹贴图
                fixed4 rippleColor = tex2D(_RippleTex, rippleUV);

                // 根据基础贴图的透明度控制水波纹显示
                fixed4 finalColor = baseColor;
                finalColor.rgb += rippleColor.r * _RippleStrength * baseColor.a; // 按透明度叠加波纹效果
                finalColor.a = baseColor.a; // 保留基础透明度

                return finalColor;
            }
            ENDCG
        }
    }
    FallBack "Transparent/Diffuse"
}

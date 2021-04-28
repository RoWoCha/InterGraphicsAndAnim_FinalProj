Shader "MyShaders/PhongIlluminationShader"
{

	//Information sources:
	//  1) https://www.youtube.com/watch?v=bR8DHcj6Htg
	//  2) https://docs.unity3d.com/Manual/SL-Blend.html
	//  3) https://docs.unity3d.com/Manual/SL-PassTags.html
	//  4) https://janhalozan.com/2017/08/12/phong-shader/
	//  5) https://forum.unity.com/threads/what-is-_maintex_st.24962/
	//  6) https://docs.unity3d.com/Manual/SL-UnityShaderVariables.html
	//  7) https://docs.unity3d.com/Manual/SL-BuiltinFunctions.html

	Properties
	{
		_MainTexture("Texture", 2D) = "white" {}		 // Object's texture
		_Color("Colour", Color) = (1,1,1,1)			     // Object's color

		_Shininess("Shininess", Float) = 0.1		     // Level of shininess from reflection
		_SpecColor("Specular Color", Color) = (1,1,1,1)  // Color of shining
	}

		SubShader
		{
			Tags { "RenderType" = "Opaque" }
			LOD 200

			Pass  // Main pass with ambient light
			{
				//Tags { "LightMode" = "ForwardBase" }

				CGPROGRAM
				#pragma vertex vertexFunc
				#pragma fragment fragmentFunc

				#include "UnityCG.cginc"

				uniform float4 _LightColor0; // Light color (declared in UnityLightingCommon.cginc)

				sampler2D _MainTexture; // Object's texture
				float4 _MainTexture_ST; // Offset and tiling values of texture (for texture scale and offset)

				uniform float4 _Color;
				uniform float4 _SpecColor;
				uniform float _Shininess;

				struct appdata
				{
					float4 pos : POSITION;
					float3 normal : NORMAL;
					float2 uv : TEXCOORD0;
				};

				struct v2f
				{
					float4 pos : POSITION;
					float3 normal : NORMAL;
					float2 uv : TEXCOORD0;
					float4 posWorld : TEXCOORD1;
				};

				v2f vertexFunc(appdata IN)
				{
					v2f OUT;

					OUT.posWorld = mul(unity_ObjectToWorld, IN.pos);  //Current model matrix multiplied by vertex position
					OUT.normal = normalize(mul(float4(IN.normal, 0.0), unity_WorldToObject).xyz);  // Uses inverse of current world matrix
					OUT.pos = UnityObjectToClipPos(IN.pos); // Screen position of vertex
					OUT.uv = TRANSFORM_TEX(IN.uv, _MainTexture);  // TRANSFORM_TEX macro from UnityCG.cginc to make sure texture scale and offset is applied correctly

					return OUT;
				}

				fixed4 fragmentFunc(v2f IN) : COLOR
				{
					float3 normalVec = normalize(IN.normal);
					float3 viewVec = normalize(_WorldSpaceCameraPos - IN.posWorld.xyz);

					float3 lightVec = _WorldSpaceLightPos0.xyz - IN.posWorld.xyz;  // light vec for distance calculation
					float distance = length(lightVec);
					float attenuation = lerp(1.0, 1.0f / pow(distance, 3), _WorldSpaceLightPos0.w);

					//_WorldSpaceLightPos0.w is equal to 0 if directional lights and 1 if other lights
					lightVec = _WorldSpaceLightPos0.xyz - IN.posWorld.xyz * _WorldSpaceLightPos0.w; // actual light vec

					float3 ambientLighting = UNITY_LIGHTMODEL_AMBIENT.rgb * _Color.rgb;
					
					float3 diffuseReflection = attenuation * _LightColor0.rgb * _Color.rgb * max(0.0, dot(normalVec, lightVec));
					
					float3 specularReflection;
					if (dot(IN.normal, lightVec) < 0.0)
					{
						specularReflection = float3(0.0, 0.0, 0.0);
					}
					else
					{
						specularReflection = attenuation * _LightColor0.rgb * _SpecColor.rgb * pow(max(0.0, dot(reflect(-lightVec, normalVec), viewVec)), 1.0f / _Shininess);
					}

					float3 finColor = (ambientLighting + diffuseReflection) * tex2D(_MainTexture, IN.uv) + specularReflection;
					return float4(finColor, 1.0);
				}
				ENDCG
			}

			Pass // Blending passes for additional light sources (doesn't use ambient light)
			{
				Tags { "LightMode" = "ForwardAdd" }
				Blend One One  // Additive Blending

				CGPROGRAM
				#pragma vertex vertexFunc
				#pragma fragment fragmentFunc

				#include "UnityCG.cginc"

				uniform float4 _LightColor0; // Light color (declared in UnityLightingCommon.cginc)

				sampler2D _MainTexture; // Object's texture
				float4 _MainTexture_ST; // Offset and tiling values of texture (for texture scale and offset)

				uniform float4 _Color;
				uniform float4 _SpecColor;
				uniform float _Shininess;

				struct appdata
				{
					float4 pos : POSITION;
					float3 normal : NORMAL;
					float2 uv : TEXCOORD0;
				};

				struct v2f
				{
					float4 pos : POSITION;
					float3 normal : NORMAL;
					float2 uv : TEXCOORD0;
					float4 posWorld : TEXCOORD1;
				};

				v2f vertexFunc(appdata IN)
				{
					v2f OUT;

					OUT.posWorld = mul(unity_ObjectToWorld, IN.pos);  //Current model matrix multiplied by vertex position
					OUT.normal = normalize(mul(float4(IN.normal, 0.0), unity_WorldToObject).xyz);  // Uses inverse of current world matrix
					OUT.pos = UnityObjectToClipPos(IN.pos); // Screen position of vertex
					OUT.uv = TRANSFORM_TEX(IN.uv, _MainTexture);  // TRANSFORM_TEX macro from UnityCG.cginc to make sure texture scale and offset is applied correctly

					return OUT;
				}

				fixed4 fragmentFunc(v2f IN) : COLOR
				{
					float3 normalVec = normalize(IN.normal);
					float3 viewVec = normalize(_WorldSpaceCameraPos - IN.posWorld.xyz);

					float3 lightVec = _WorldSpaceLightPos0.xyz - IN.posWorld.xyz;  // light vec for distance calculation
					float distance = length(lightVec);
					float attenuation = lerp(1.0, 1.0f / pow(distance, 3), _WorldSpaceLightPos0.w);

					//_WorldSpaceLightPos0.w is equal to 0 if directional lights and 1 if other lights
					lightVec = _WorldSpaceLightPos0.xyz - IN.posWorld.xyz * _WorldSpaceLightPos0.w; // actual light vec

					float3 diffuseReflection = attenuation * _LightColor0.rgb * _Color.rgb * max(0.0, dot(normalVec, lightVec));
					
					float3 specularReflection;
					if (dot(IN.normal, lightVec) < 0.0)
					{
						specularReflection = float3(0.0, 0.0, 0.0);
					}
					else
					{
						specularReflection = attenuation * _LightColor0.rgb * _SpecColor.rgb * pow(max(0.0, dot(reflect(-lightVec, normalVec), viewVec)), 1.0f / _Shininess);
					}

					float3 finColor = diffuseReflection * tex2D(_MainTexture, IN.uv) + specularReflection;
					return float4(finColor, 1.0);
				}
				ENDCG
			}
		}
}

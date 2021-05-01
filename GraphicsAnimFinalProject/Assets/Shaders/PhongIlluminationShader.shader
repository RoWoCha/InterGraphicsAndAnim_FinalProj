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
	//  8) https://docs.unity3d.com/Manual/SL-ShaderSemantics.html

	Properties
	{
		_MainTexture("Texture", 2D) = "white" {}		  // Object's texture
		_Color("Colour", Color) = (1,1,1,1)			      // Object's color

		_Shininess("Shininess", Float) = 0.1		      // Level of shininess from reflection
		_SpecularColor("Specular Colour", Color) = (1,1,1,1)  // Color of shining
	}

		SubShader
		{
			Tags {"RenderType" = "Opaque"}

			Pass  // Main pass with ambient light
			{
				Tags { "LightMode" = "ForwardBase" }

				CGPROGRAM
				#pragma vertex vertexFunc
				#pragma fragment fragmentFunc

				#include "UnityCG.cginc"

				uniform float4 _LightColor0; // Light color (declared in UnityLightingCommon.cginc)

				sampler2D _MainTexture; // Object's texture
				float4 _MainTexture_ST; // Offset and tiling values of texture (for texture scale and offset), setup by Unity

				uniform float4 _Color;
				uniform float4 _SpecularColor;
				uniform float _Shininess;

				struct appdata
				{
					float4 vertexPos : POSITION;
					float2 uv : TEXCOORD0;
					float3 normal : NORMAL;
				};

				struct v2f
				{
					float4 pos : POSITION;
					float2 uv : TEXCOORD0;
					float4 posWorld : TEXCOORD1;
					float3 normal : NORMAL;
				};

				// Just to show that you can output structs from shaders, even fragment
				struct fragOutput
				{
					fixed4 color : SV_Target0; //SV_Target is a semantic saying that shader writes color
				};

				v2f vertexFunc(appdata IN)
				{
					v2f OUT;

					OUT.posWorld = mul(unity_ObjectToWorld, IN.vertexPos);  //Current model matrix multiplied by vertex position
					OUT.normal = IN.normal;
					OUT.pos = UnityObjectToClipPos(IN.vertexPos); // Screen position of vertex, function used in Unity instead of multiplying by MVP matrix
					
					// TRANSFORM_TEX macro from UnityCG.cginc to make sure texture scale and offset are applied correctly
					// Equals to (tex.xy * name##_ST.xy + name##_ST.zw)  xy = tilt, zw = offset
					OUT.uv = TRANSFORM_TEX(IN.uv, _MainTexture);

					return OUT;
				}

				//SV_Target because output is fixed4 
				fragOutput fragmentFunc(v2f IN) : SV_Target
				{
					float3 lightVec = _WorldSpaceLightPos0.xyz - IN.posWorld.xyz * _WorldSpaceLightPos0.w;  // light vec for distance calculation
					float distance = length(lightVec);

					float3 normal = normalize(IN.normal);

					float3 viewVec = normalize(_WorldSpaceCameraPos - IN.posWorld.xyz);
					float3 reflectionVec = reflect(-lightVec, normal);

					//_WorldSpaceLightPos0.w is equal to 0 if directional lights and 1 if other lights
					float attenuation = lerp(1.0, 1.0f / pow(distance, 3), _WorldSpaceLightPos0.w);
					
					float3 diffuseColor = max(0.0, dot(normal, lightVec)) * attenuation;
					float3 specularColor;
					if (dot(IN.normal, lightVec) >= 0.0) // if light is coming from opposite direction
						specularColor = attenuation * pow(max(0.0, dot(reflectionVec, viewVec)), 1.0f / _Shininess);
					else
						specularColor = float3(0.0, 0.0, 0.0);

					float3 ambientColor = UNITY_LIGHTMODEL_AMBIENT.rgb * _Color.rgb;

					float4 finColor = float4(((ambientColor + diffuseColor) * tex2D(_MainTexture, IN.uv) + specularColor) * _LightColor0.rgb * _Color.rgb, 1.0);
					
					fragOutput OUT;
					OUT.color = finColor;
					return OUT;
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
				float4 _MainTexture_ST; // Offset and tiling values of texture (for texture scale and offset), setup by Unity

				uniform float4 _Color;
				uniform float4 _SpecularColor;
				uniform float _Shininess;

				struct appdata
				{
					float4 vertexPos : POSITION;
					float2 uv : TEXCOORD0;
					float3 normal : NORMAL;
				};

				struct v2f
				{
					float4 pos : POSITION;
					float2 uv : TEXCOORD0;
					float4 posWorld : TEXCOORD1;
					float3 normal : NORMAL;
				};

				// Just to show that you can output structs from shaders, even fragment
				struct fragOutput
				{
					fixed4 color : SV_Target0; //SV_Target is a semantic saying that shader writes color
				};

				v2f vertexFunc(appdata IN)
				{
					v2f OUT;

					OUT.posWorld = mul(unity_ObjectToWorld, IN.vertexPos);  //Current model matrix multiplied by vertex position
					OUT.normal = IN.normal;
					OUT.pos = UnityObjectToClipPos(IN.vertexPos); // Screen position of vertex, function used in Unity instead of multiplying by MVP matrix
					
					// TRANSFORM_TEX macro from UnityCG.cginc to make sure texture scale and offset are applied correctly
					// Equals to (tex.xy * name##_ST.xy + name##_ST.zw)  xy = tilt, zw = offset
					OUT.uv = TRANSFORM_TEX(IN.uv, _MainTexture);

					return OUT;
				}

				fragOutput fragmentFunc(v2f IN) : SV_Target
				{
					float3 lightVec = _WorldSpaceLightPos0.xyz - IN.posWorld.xyz * _WorldSpaceLightPos0.w;  // light vec for distance calculation
					float distance = length(lightVec);

					float3 normal = normalize(IN.normal);

					float3 viewVec = normalize(_WorldSpaceCameraPos - IN.posWorld.xyz);
					float3 reflectionVec = reflect(-lightVec, normal);

					//_WorldSpaceLightPos0.w is equal to 0 if directional lights and 1 if other lights
					float attenuation = lerp(1.0, 1.0f / pow(distance, 3), _WorldSpaceLightPos0.w);

					float3 diffuseColor = max(0.0, dot(normal, lightVec)) * attenuation;
					float3 specularColor;
					if (dot(IN.normal, lightVec) >= 0.0) // if light is coming from opposite direction
						specularColor = attenuation * pow(max(0.0, dot(reflectionVec, viewVec)), 1.0f / _Shininess);
					else
						specularColor = float3(0.0, 0.0, 0.0);

					float4 finColor = float4((diffuseColor * tex2D(_MainTexture, IN.uv) + specularColor) * _LightColor0.rgb * _Color.rgb, 1.0);

					fragOutput OUT;
					OUT.color = finColor;
					return OUT;
				}
				ENDCG
			}
		}
}

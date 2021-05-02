/// Script: ParallaxOcclusionMapping.shader
/// Brief: Parallax Occlusion Mapping With Phong shader for single light
/// Author: Egor Fesenko
/// Date: 05/01/2021
/// Sources:
///  1) https://habr.com/ru/post/416163/
///  2) https://github.com/RoWoCha/SP21-GPR-300-01/blob/project4_egor/animal3D%20SDK/resource/gl
///  2) https://www.gamedev.net/articles/programming/graphics/a-closer-look-at-parallax-occlusio
///  3) https://catlikecoding.com/unity/tutorials/rendering/part-20/
///  4) https://github.com/hamish-milne/POMUnity
///  5) https://www.youtube.com/watch?v=CpRuYJHGL10ml
///  6) https://docs.unity3d.com/ScriptReference/Mesh-tangents.html
///  7) https://stackoverflow.com/questions/24166446/glsl-tessellation-displacement-mapping

Shader "MyShaders/ParallaxOcclusionMappingWithPhong"
{
	Properties
	{
			_MainTexture("Albido texture", 2D) = "white" {}
			_HeightMap("Height map texture", 2D) = "white" {}
			_Parallax("Height scale", Range(0, 1)) = 0.05
			_ParallaxSamplesMin("Parallax samples minimum", Range(5, 200)) = 5
			_ParallaxSamplesMax("Parallax samples maximum", Range(5, 200)) = 50
			_Shininess("Shininess", Float) = 0.1									// Level of shininess from reflection

	}

	SubShader
	{
		Pass
		{
			Tags {"RenderType" = "Opaque"}

			CGPROGRAM
			#pragma vertex vertexFunc
			#pragma fragment fragmentFunc

			#include "UnityCG.cginc"

			uniform float4 _LightColor0; // Light color (declared in UnityLightingCommon.cginc)

			uniform sampler2D _MainTexture; // Object's texture
			uniform float4 _MainTexture_ST; // Offset and tiling values of texture (for texture scale and offset), setup by Unity

			uniform sampler2D _HeightMap;

			uniform float _Parallax;
			uniform float _ParallaxSamplesMin;
			uniform float _ParallaxSamplesMax;

			uniform float _Shininess;

			struct appdata
			{
				float4 vertexPos: POSITION;
				float2 uv: TEXCOORD0;
				float3 normal: NORMAL;
				float4 tangent  : TANGENT;
			};

			struct v2f
			{
				float4 position: POSITION;
				float2 uv: TEXCOORD0;
				float4 posWorld: TEXCOORD1;
				//float3x3 TBN: ...;				// doesn't work:(
				float3 normalWorld : TEXCOORD2;
				float3 tangentWorld : TEXCOORD3;
				float3 bitangentWorld : TEXCOORD4;
				float3 normal  : NORMAL;
			};

			v2f vertexFunc(appdata IN)
			{
				v2f OUT;

				OUT.posWorld = mul(unity_ObjectToWorld, IN.vertexPos);

				// Tangent Basis Values
				OUT.tangentWorld = normalize(mul(unity_ObjectToWorld, IN.tangent.xyz));
				OUT.normalWorld = mul(IN.normal.xyz, unity_WorldToObject);
				OUT.bitangentWorld = cross(OUT.normalWorld, OUT.tangentWorld) * IN.tangent.w;

				//OUT.TBN = float3x3(worldNormal, worldTangent, worldBitangent);

				OUT.position = UnityObjectToClipPos(IN.vertexPos);
				OUT.uv = IN.uv;
				OUT.normal = IN.normal;

				return OUT;
			}

			float4 fragmentFunc(v2f IN) : SV_TARGET
			{
				float3 normal = normalize(IN.normal);
				float3 viewWorld = normalize(_WorldSpaceCameraPos - IN.posWorld.xyz);

				float3x3 TBN = float3x3(IN.tangentWorld, IN.bitangentWorld, IN.normalWorld);

				// Getting view vector in tangent space
				float3 viewVec_tan = mul(TBN, viewWorld);

				//float3 viewVec_tan = float3(IN.tangentWorld.x, IN.bitangentWorld.x, IN.normalWorld.x) * viewWorld.x +
				//				     float3(IN.tangentWorld.y, IN.bitangentWorld.y, IN.normalWorld.y) * viewWorld.y +
				//				     float3(IN.tangentWorld.z, IN.bitangentWorld.z, IN.normalWorld.z) * viewWorld.z;
				
				//fixed3 viewVec_tan = float3(IN.tangentWorld.x, IN.bitangentWorld.x, IN.normalWorld.x) * IN.viewWorld.x +
				//			    	 float3(IN.tangentWorld.y, IN.bitangentWorld.y, IN.normalWorld.y) * IN.viewWorld.y +
				//			    	 float3(IN.tangentWorld.z, IN.bitangentWorld.z, IN.normalWorld.z) * IN.viewWorld.z;

				float parallaxLimit = length(viewVec_tan.xy) / viewVec_tan.z;
				float2 offsetDirection = normalize(viewVec_tan.xy);
				float2 parallaxOffsetMax = offsetDirection * parallaxLimit * _Parallax;

				int numOfSteps = (lerp(min(_ParallaxSamplesMin, _ParallaxSamplesMax - 1), _ParallaxSamplesMax, abs(dot(float3(0, 0, 1), viewVec_tan))));
				float stepDepth = 1.0 / (float)numOfSteps;
				float2 parallaxOffsetPerStep = stepDepth * parallaxOffsetMax;

				float currentDepth = 1.0;
				float2 dx = ddx(IN.uv.xy);
				float2 dy = ddy(IN.uv.xy);
				float2 currentUV = IN.uv.xy;

				float currentHeightMapValue = tex2D(_HeightMap, currentUV).r;

				// Do until height value from height map is more than depth value (while searching for point's actual height)
				while (currentDepth > currentHeightMapValue)
				{
					// shift texture coordinate towards camera
					currentUV -= parallaxOffsetPerStep;
					// update depth map value using new texture coordinate
					currentHeightMapValue = tex2D(_HeightMap, currentUV, dx, dy).r;
					// get depth of next step
					currentDepth -= stepDepth;
				}

				// texture coordinates before intersection (step back)
				float2 prevUV = currentUV + parallaxOffsetPerStep;

				// get values difference after and before intersection
				float afterDepth = currentHeightMapValue - currentDepth;
				float beforeDepth = tex2D(_HeightMap, prevUV).r - currentDepth + stepDepth;

				// interpolation of texture coordinates
				float t = afterDepth / (afterDepth - beforeDepth);
				float2 finalUV_POM = lerp(currentUV, prevUV, t); // final texcord for POM

				// Phong calculations
				float3 lightVec = _WorldSpaceLightPos0.xyz - IN.posWorld.xyz * _WorldSpaceLightPos0.w;
				float distance = length(lightVec);

				float3 reflectionVec = reflect(-lightVec, normal);

				//_WorldSpaceLightPos0.w is equal to 0 if directional lights and 1 if other lights
				float attenuation = lerp(1.0, 1.0f / pow(distance, 3), _WorldSpaceLightPos0.w);

				float3 diffuseColor = max(0.0, dot(normal, lightVec)) * attenuation;
				float3 specularColor;
				if (dot(IN.normal, lightVec) >= 0.0) // if light is coming from opposite direction
					specularColor = attenuation * pow(max(0.0, dot(reflectionVec, viewWorld)), 1.0f / _Shininess);
				else
					specularColor = float3(0.0, 0.0, 0.0);

				float3 ambientColor = UNITY_LIGHTMODEL_AMBIENT.rgb;

				float4 finColor = float4(((ambientColor + diffuseColor) * tex2D(_MainTexture, finalUV_POM) + specularColor) * _LightColor0.rgb, 1.0);

				return finColor;
			}
			ENDCG
		}
	}
	Fallback "Diffuse"
}
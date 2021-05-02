/// Script: DepthOfFieldCamera.cs
/// Brief: Creates a DOF material out of camera texture, attaches DOF shader to it and outputs the result to the screen
/// Author: Egor Fesenko
/// Date: 05/02/2021
/// Sources:
/// 1) Based on awesome tutorial and explanation of DOF shader: https://catlikecoding.com/unity/tutorials/advanced-rendering/depth-of-field/
/// 2) https://docs.unity3d.com/ScriptReference/Graphics.Blit.html
/// 3) https://docs.unity3d.com/ScriptReference/RenderTexture.html
/// 4) https://docs.unity3d.com/ScriptReference/MonoBehaviour.OnRenderImage.html
/// 5) https://docs.unity3d.com/ScriptReference/RenderTexture.ReleaseTemporary.html / https://docs.unity3d.com/ScriptReference/RenderTexture.GetTemporary.html

using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System;

[ExecuteInEditMode, ImageEffectAllowedInSceneView]
public class DepthOfFieldCamera : MonoBehaviour
{

	const int circleOfConfusionPass = 0;
	const int preFilterPass = 1;
	const int bokehPass = 2;
	const int postFilterPass = 3;
	const int combinePass = 4;

	[Range(0.1f, 200f)]
	public float focusDistance = 10f;

	[Range(0.1f, 200f)]
	public float focusRange = 3f;

	[Range(1f, 10f)]
	public float bokehRadius = 4f;

	[HideInInspector]
	public Shader depthOfFieldShader;
	[NonSerialized]
	Material depthOfFieldMat;

    private void Update()
    {
		//Debug.Log((transform.position - GameObject.Find("Cube").transform.position).magnitude);
    }

    void OnRenderImage (RenderTexture source, RenderTexture destination)
	{
		if (depthOfFieldMat == null)
		{
			depthOfFieldMat = new Material(depthOfFieldShader);
			depthOfFieldMat.hideFlags = HideFlags.HideAndDontSave;
		}

		depthOfFieldMat.SetFloat("_FocusDist", focusDistance);
		depthOfFieldMat.SetFloat("_FocusRange", focusRange);
		depthOfFieldMat.SetFloat("_BokehRad", bokehRadius);

		// Circle of Confusion
		RenderTexture coc = RenderTexture.GetTemporary (source.width, source.height, 0, RenderTextureFormat.RHalf, RenderTextureReadWrite.Linear);

		// Downsampling values;
		int width = source.width / 2;
		int height = source.height / 2;
		RenderTextureFormat format = source.format;
		RenderTexture dof0 = RenderTexture.GetTemporary(width, height, 0, format);
		RenderTexture dof1 = RenderTexture.GetTemporary(width, height, 0, format);

		// Adding Textures for CoC values and DoF Values
		depthOfFieldMat.SetTexture("_CoCTex", coc);
		depthOfFieldMat.SetTexture("_DoFTex", dof0);

		Graphics.Blit(source, coc, depthOfFieldMat, circleOfConfusionPass);
		Graphics.Blit(source, dof0, depthOfFieldMat, preFilterPass);
		Graphics.Blit(dof0, dof1, depthOfFieldMat, bokehPass);
		Graphics.Blit(dof1, dof0, depthOfFieldMat, postFilterPass);
		Graphics.Blit(source, destination, depthOfFieldMat, combinePass);

		RenderTexture.ReleaseTemporary(coc);
		RenderTexture.ReleaseTemporary(dof0);
		RenderTexture.ReleaseTemporary(dof1);
	}
}
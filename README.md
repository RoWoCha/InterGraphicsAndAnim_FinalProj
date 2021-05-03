InterGraphicsAndAnim_FinalProj repo

Repo for GPR-300-01: Intermediate Graphics and Animation class Final Project
Uses Unity engine and HLSL/CG for shaders

Project is done by Egor Fesenko

--- Final Project ---

Unity version used: 2019.4.19f1

Shaders Implemented:

- Phong Shader for multiple lights
- Parallax Occlusion Mapping with Phong
- Depth of Field post-processing shader

Run instruction: Open the project in Unity, press Run.
Controls:
- WASD as standard
- E/Q to move up and down
- Mouse wheel up/down to change camera movement speed
- Hold Shift to move with max speed

How to adjust values:
- Phong with multiple lights
     In Assets/Materials choose any of the materials with attached Phong Shader (BoxMaterial, GroundMat, SphereMat) - edit texture/colour/shininess in the inspector
- Parallax Occlusion Mapping with Phong
     In Assets/Materials choose POMMaterial - edit Albido texture/Height Map texture/Height scale/NumOfParallaxSamples/Snininnes in the inspector
- DepthOfField
     On the main scene, choose Main Camera in the Hierarchy and find an attached script DepthOfFieldCamera.cs in the inspector - edit FocusDistance/FocusRange/BokehRadius
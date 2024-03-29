//////////////////////////////////////////////////////////////////////
// HLSL File:
// This example is compiled using the fxc shader compiler.
// It is possible directly compile HLSL in VS2013
//////////////////////////////////////////////////////////////////////

// This first constant buffer is special.
// The framework looks for particular variables and sets them automatically.
// See the CommonApp comments for the names it looks for.
cbuffer CommonApp
{
	float4x4 g_WVP;
	float4 g_lightDirections[MAX_NUM_LIGHTS];
	float3 g_lightColours[MAX_NUM_LIGHTS];
	int g_numLights;
	float4x4 g_InvXposeW;
	float4x4 g_W;
};


// When you define your own cbuffer you can use a matching structure in your app but you must be careful to match data alignment.
// Alternatively, you may use shader reflection to find offsets into buffers based on variable names.
// The compiler may optimise away the entire cbuffer if it is not used but it shouldn't remove indivdual variables within it.
// Any 'global' variables that are outside an explicit cbuffer go
// into a special cbuffer called "$Globals". This is more difficult to work with
// because you must use reflection to find them.
// Also, the compiler may optimise individual globals away if they are not used.
cbuffer MyApp
{
	float	g_frameCount;
	float3	g_waveOrigin;
}


// VSInput structure defines the vertex format expected by the input assembler when this shader is bound.
// You can find a matching structure in the C++ code.
struct VSInput
{
	float4 pos:POSITION;
	float4 colour:COLOUR0;
	float3 normal:NORMAL;
	float2 tex:TEXCOORD;
};

// PSInput structure is defining the output of the vertex shader and the input of the pixel shader.
// The variables are interpolated smoothly across triangles by the rasteriser.
struct PSInput
{
	float4 pos:SV_Position;
	float4 colour:COLOUR0;
	float3 normal:NORMAL;
	float2 tex:TEXCOORD;
	float4 mat:COLOUR1;
};

// PSOutput structure is defining the output of the pixel shader, just a colour value.
struct PSOutput
{
	float4 colour:SV_Target;
};

// Define several Texture 'slots'
Texture2D g_materialMap; //materialmap.dds
Texture2D g_texture0; // green grass
Texture2D g_texture1; // yellow grass
Texture2D g_texture2; // Gravel


// Define a state setting 'slot' for the sampler e.g. wrap/clamp modes, filtering etc.
SamplerState g_sampler;

// The vertex shader entry point. This function takes a single vertex and transforms it for the rasteriser. //world space
void VSMain(const VSInput input, out PSInput output)
{
	//int speed = g_frameCount * 100;
	//float x = cos(radians((input.pos.x * 10) + g_frameCount));
	//float y = cos(radians((input.pos.y * 100) + speed));
	//float y = 0;
	//float z = 0;
	//float z = cos(radians((input.pos.z * 10) + speed));

	//int z = mapindex / m_HeightMapWidth;
	//int x = mapindex % m_HeightMapWidth;
	output.pos = (mul(input.pos, g_WVP)); //+ float4(x, y, z, 1);
	//input.pos.xz this is called swizzling look it up
	//uv 0 to 1 to texture
	float2 newInputPos = (input.pos.xz + 512) / 1024; // between 0 and 1. to get x and y co-ords on the mat
	newInputPos.y = 1 - newInputPos.y;

	//input.pos.z + 512 / 1024;

	output.colour = input.colour;
	output.mat = g_materialMap.SampleLevel(g_sampler, newInputPos.xy, 0);
	output.normal = input.normal;
	output.tex = input.tex;

	//float4 example = g_materialMap.SampleLevel(g_sampler, input.tex, 0); //your using the position x and z to calculate where you are on the splat map
}

// The pixel shader entry point. This function writes out the fragment/pixel colour.
void PSMain(const PSInput input, out PSOutput output)
{
	float4 lightFinalColour = { 0.8f, 0.8f, 0.8f, 1.0f }; //CHANGED THE AMBIENT
	float4 finalColour = { 0.0f, 0.0f, 0.0f, 1.0f };

	for (int i = 0; i < MAX_NUM_LIGHTS; i++)
	{
		float intensity = clamp(dot(g_lightDirections[i], input.normal), 0, 1); //clamp due to intesity between 0 and 1
		lightFinalColour += float4(g_lightColours[i] * intensity, 1);
	}

	float4 tex0 = g_texture0.Sample(g_sampler, input.tex);
	float4 tex1 = g_texture1.Sample(g_sampler, input.tex);
	float4 tex2 = g_texture2.Sample(g_sampler, input.tex);


	finalColour = lerp(finalColour, tex0, input.mat.r); //How much texture we want based on the material map, the material maps red colour
	finalColour = lerp(finalColour, tex1, input.mat.g); //How much texture we want based on the material map, the material maps green colour
	finalColour = lerp(finalColour, tex2, input.mat.b); //How much texture we want based on the material map, the material maps blue colour
	//tex0, tex1, input.mat;
	//r,g,b,
	//float4 
	output.colour = finalColour * lightFinalColour;//input.colour * finalColour;	// 'return' the colour value for this fragment.
}
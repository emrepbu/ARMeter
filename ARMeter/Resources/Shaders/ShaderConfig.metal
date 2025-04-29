#include <metal_stdlib>
using namespace metal;

// Basic parameters for shader constants
constant bool EnableAREnvProbe [[function_constant(0)]];
constant bool EnableDynamicLighting [[function_constant(1)]];
constant bool EnableVRROnCapableDevice [[function_constant(2)]];
constant bool EnablePtCrossing [[function_constant(3)]];
constant bool EnableBaseColorMap [[function_constant(4)]];
constant bool EnableNormalMap [[function_constant(5)]];
constant bool EnableEmissiveMap [[function_constant(6)]];
constant bool EnableRoughnessMap [[function_constant(7)]];
constant bool EnableMetallicMap [[function_constant(8)]];
constant bool EnableAOMap [[function_constant(9)]];
constant bool EnableSpecularMap [[function_constant(10)]];
constant bool EnableOpacityMap [[function_constant(11)]];
constant bool EnableClearcoat [[function_constant(12)]];
constant bool EnableTransparency [[function_constant(13)]];
constant bool UseBaseColorMapAsTintMask [[function_constant(14)]];
constant bool EnableOpacityThreshold [[function_constant(15)]];
constant bool EnableMultiUVs [[function_constant(16)]];
constant bool EnableVertexColor [[function_constant(17)]];
constant bool EnableShadowedDynamicLight [[function_constant(18)]];
constant int DitherMode [[function_constant(19)]];
constant bool EnableVirtualEnvironmentProbes [[function_constant(20)]];
constant bool EnableClearcoatNormalMap [[function_constant(21)]];
constant bool RenderToCompositeLayer [[function_constant(22)]];

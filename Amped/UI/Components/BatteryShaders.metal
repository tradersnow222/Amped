#include <metal_stdlib>
#include <metal_math>
using namespace metal;

// MARK: - Data Structures

struct VertexIn {
    float3 position [[attribute(0)]];
    float3 normal [[attribute(1)]];
    float2 uv [[attribute(2)]];
};

struct VertexOut {
    float4 position [[position]];
    float3 worldPosition;
    float3 normal;
    float2 uv;
    float3 viewDirection;
};

struct BatteryUniforms {
    float4x4 modelViewProjectionMatrix;
    float4x4 modelMatrix;
    float4x4 viewMatrix;
    float3 cameraPosition;
    float3 lightPosition;
    float3 lightColor;
    float lightIntensity;
    float chargeLevel;
    float isCharging;
    float time;
    float glowIntensity;
    float metallic;
    float roughness;
    float3 chargeColor;
    float3 baseColor;
};

struct LightingResult {
    float3 diffuse;
    float3 specular;
    float3 ambient;
};

// MARK: - Utility Functions

float3 fresnelSchlick(float cosTheta, float3 F0) {
    return F0 + (1.0 - F0) * pow(1.0 - cosTheta, 5.0);
}

float distributionGGX(float3 N, float3 H, float roughness) {
    float a = roughness * roughness;
    float a2 = a * a;
    float NdotH = max(dot(N, H), 0.0);
    float NdotH2 = NdotH * NdotH;
    
    float num = a2;
    float denom = (NdotH2 * (a2 - 1.0) + 1.0);
    denom = 3.14159265359 * denom * denom;
    
    return num / denom;
}

float geometrySchlickGGX(float NdotV, float roughness) {
    float r = (roughness + 1.0);
    float k = (r * r) / 8.0;
    
    float num = NdotV;
    float denom = NdotV * (1.0 - k) + k;
    
    return num / denom;
}

float geometrySmith(float3 N, float3 V, float3 L, float roughness) {
    float NdotV = max(dot(N, V), 0.0);
    float NdotL = max(dot(N, L), 0.0);
    float ggx2 = geometrySchlickGGX(NdotV, roughness);
    float ggx1 = geometrySchlickGGX(NdotL, roughness);
    
    return ggx1 * ggx2;
}

LightingResult calculatePBRLighting(float3 worldPos, float3 normal, float3 viewDir, 
                                   float3 lightPos, float3 lightColor, float lightIntensity,
                                   float3 albedo, float metallic, float roughness) {
    LightingResult result;
    
    float3 lightDir = normalize(lightPos - worldPos);
    float3 halfwayDir = normalize(lightDir + viewDir);
    
    // Calculate distance attenuation
    float distance = length(lightPos - worldPos);
    float attenuation = lightIntensity / (distance * distance);
    float3 radiance = lightColor * attenuation;
    
    // Cook-Torrance BRDF
    float3 F0 = mix(float3(0.04), albedo, metallic);
    float3 F = fresnelSchlick(max(dot(halfwayDir, viewDir), 0.0), F0);
    
    float NDF = distributionGGX(normal, halfwayDir, roughness);
    float G = geometrySmith(normal, viewDir, lightDir, roughness);
    
    float3 numerator = NDF * G * F;
    float denominator = 4.0 * max(dot(normal, viewDir), 0.0) * max(dot(normal, lightDir), 0.0) + 0.001;
    float3 specular = numerator / denominator;
    
    float3 kS = F;
    float3 kD = float3(1.0) - kS;
    kD *= 1.0 - metallic;
    
    float NdotL = max(dot(normal, lightDir), 0.0);
    result.diffuse = (kD * albedo / 3.14159265359) * radiance * NdotL;
    result.specular = specular * radiance * NdotL;
    result.ambient = float3(0.03) * albedo;
    
    return result;
}

// MARK: - Vertex Shader

vertex VertexOut batteryVertexShader(VertexIn in [[stage_in]],
                                   constant BatteryUniforms& uniforms [[buffer(0)]]) {
    VertexOut out;
    
    float4 worldPosition = uniforms.modelMatrix * float4(in.position, 1.0);
    out.position = uniforms.modelViewProjectionMatrix * float4(in.position, 1.0);
    out.worldPosition = worldPosition.xyz;
    out.normal = normalize((uniforms.modelMatrix * float4(in.normal, 0.0)).xyz);
    out.uv = in.uv;
    out.viewDirection = normalize(uniforms.cameraPosition - worldPosition.xyz);
    
    return out;
}

// MARK: - Fragment Shader for Battery Body

fragment float4 batteryBodyFragmentShader(VertexOut in [[stage_in]],
                                         constant BatteryUniforms& uniforms [[buffer(0)]]) {
    
    // Base material properties
    float3 albedo = uniforms.baseColor;
    float metallic = uniforms.metallic;
    float roughness = uniforms.roughness;
    
    // Calculate PBR lighting
    LightingResult lighting = calculatePBRLighting(
        in.worldPosition,
        normalize(in.normal),
        normalize(in.viewDirection),
        uniforms.lightPosition,
        uniforms.lightColor,
        uniforms.lightIntensity,
        albedo,
        metallic,
        roughness
    );
    
    // Combine lighting components
    float3 color = lighting.ambient + lighting.diffuse + lighting.specular;
    
    // Add rim lighting for premium feel
    float rimPower = 2.0;
    float rim = 1.0 - max(0.0, dot(normalize(in.normal), normalize(in.viewDirection)));
    rim = pow(rim, rimPower);
    color += rim * float3(0.3, 0.4, 0.5) * 0.5;
    
    // Add subtle iridescence effect
    float iridescence = sin(in.uv.x * 10.0 + uniforms.time) * 0.1;
    color += iridescence * float3(0.1, 0.2, 0.3);
    
    return float4(color, 1.0);
}

// MARK: - Fragment Shader for Charge Segments

fragment float4 chargeSegmentFragmentShader(VertexOut in [[stage_in]],
                                           constant BatteryUniforms& uniforms [[buffer(0)]]) {
    
    // Base charge color
    float3 baseColor = uniforms.chargeColor;
    
    // Calculate lighting
    float3 normal = normalize(in.normal);
    float3 lightDir = normalize(uniforms.lightPosition - in.worldPosition);
    float3 viewDir = normalize(in.viewDirection);
    float3 halfwayDir = normalize(lightDir + viewDir);
    
    // Lambertian diffuse
    float NdotL = max(dot(normal, lightDir), 0.0);
    float3 diffuse = baseColor * NdotL;
    
    // Blinn-Phong specular
    float spec = pow(max(dot(normal, halfwayDir), 0.0), 32.0);
    float3 specular = float3(1.0) * spec;
    
    // Ambient
    float3 ambient = baseColor * 0.2;
    
    // Combine
    float3 color = ambient + diffuse + specular;
    
    // Add charge glow effect
    if (uniforms.isCharging > 0.5) {
        float pulse = (sin(uniforms.time * 4.0) + 1.0) * 0.5;
        float glowIntensity = uniforms.glowIntensity * pulse;
        color += baseColor * glowIntensity;
        
        // Add energy flow effect
        float flow = sin(in.uv.y * 6.28318530718 + uniforms.time * 8.0) * 0.3 + 0.7;
        color *= flow;
    }
    
    // Add inner glow based on charge level
    float centerDistance = length(in.uv - 0.5);
    float innerGlow = (1.0 - centerDistance) * uniforms.chargeLevel * 0.3;
    color += baseColor * innerGlow;
    
    return float4(color, 1.0);
}

// MARK: - Fragment Shader for Battery Terminal

fragment float4 batteryTerminalFragmentShader(VertexOut in [[stage_in]],
                                             constant BatteryUniforms& uniforms [[buffer(0)]]) {
    
    // Metallic terminal material
    float3 albedo = float3(0.8, 0.85, 0.9); // Metallic silver
    float metallic = 0.9;
    float roughness = 0.1;
    
    // Calculate PBR lighting
    LightingResult lighting = calculatePBRLighting(
        in.worldPosition,
        normalize(in.normal),
        normalize(in.viewDirection),
        uniforms.lightPosition,
        uniforms.lightColor,
        uniforms.lightIntensity,
        albedo,
        metallic,
        roughness
    );
    
    float3 color = lighting.ambient + lighting.diffuse + lighting.specular;
    
    // Add metallic reflection
    float3 reflectionDir = reflect(-normalize(in.viewDirection), normalize(in.normal));
    float reflection = max(0.0, dot(reflectionDir, normalize(uniforms.lightPosition - in.worldPosition)));
    color += reflection * float3(1.0) * 0.3;
    
    return float4(color, 1.0);
}

// MARK: - Compute Shader for Particle System

struct Particle {
    float3 position;
    float3 velocity;
    float3 color;
    float life;
    float size;
    float opacity;
};

kernel void updateBatteryParticles(device Particle* particles [[buffer(0)]],
                                  constant BatteryUniforms& uniforms [[buffer(1)]],
                                  uint index [[thread_position_in_grid]]) {
    
    if (index >= 1000) return; // Max particles
    
    Particle particle = particles[index];
    
    // Update particle physics
    particle.position += particle.velocity * 0.016; // 60fps delta time
    particle.velocity.y += -9.8 * 0.016; // Gravity
    particle.life -= 0.016;
    particle.opacity = particle.life / 2.0; // Max life of 2 seconds
    
    // Reset dead particles
    if (particle.life <= 0.0 && uniforms.isCharging > 0.5) {
        particle.position = float3(0.0, 0.0, 0.0); // Reset to battery center
        particle.velocity = float3(
            (float(index % 100) / 100.0 - 0.5) * 2.0, // Random X
            2.0 + (float(index % 50) / 50.0) * 3.0,   // Random Y upward
            0.0
        );
        particle.life = 2.0;
        particle.color = uniforms.chargeColor;
        particle.size = 2.0 + (float(index % 30) / 30.0) * 2.0; // Random size
        particle.opacity = 1.0;
    }
    
    particles[index] = particle;
}

// MARK: - Fragment Shader for Particle Rendering

fragment float4 particleFragmentShader(VertexOut in [[stage_in]],
                                      constant BatteryUniforms& uniforms [[buffer(0)]]) {
    
    // Calculate distance from center for circular particles
    float2 center = float2(0.5, 0.5);
    float distance = length(in.uv - center);
    
    // Create soft circular particle
    float alpha = 1.0 - smoothstep(0.0, 0.5, distance);
    
    // Apply charge color with energy effect
    float3 color = uniforms.chargeColor;
    
    // Add energy pulse
    float pulse = (sin(uniforms.time * 6.0 + distance * 10.0) + 1.0) * 0.5;
    color *= (0.7 + 0.3 * pulse);
    
    return float4(color, alpha * uniforms.glowIntensity);
} 
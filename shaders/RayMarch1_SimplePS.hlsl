cbuffer vars : register(b0)
{
	float2 uResolution;
	float uTime;

	float4 camPos;
	float3 origin_pos;

	float SDF;
	float Foggy;
	float Solid_Foggy;
	float3 Foggy_Color;
	
};

float DisplacedSphereDist(float3 ro1, float4 Sphere)
{
	float2x2 rot_mat = float2x2(cos(uTime * 0.2), -sin(uTime * 0.2), sin(uTime * 0.2), cos(uTime * 0.2));
	float2 rot_factor = ro1.xz * rot_mat;
	
	float3 ro = float3(rot_factor.x, ro1.y, rot_factor.y);
	float4 k = float4(5, 5, 5, + (1 - sin(uTime))*0.5);
	float rdo = length(ro - Sphere.xyz);
    float d1 = rdo - Sphere.w;
    float d2 = cos(ro.x*k.x)*cos(ro.y*k.y)*cos(ro.z*k.z) * k.w;

    return (d1+d2)/3.5;
}


float GetDist(float3 ro)
{
	return DisplacedSphereDist(ro, float4(0, 0, 0, 5));
	

}

float3 GetNormal(float3 p)
{
    float d = GetDist(p);
    float2 e = float2(0.001, 0);
    float3 n = d - float3(GetDist(p - e.xyy), GetDist(p - e.yxy), GetDist(p - e.yyx));
    return normalize(n);
}



float4 main(float4 fragCoord : SV_POSITION) : SV_TARGET
{
	float3 look_from = camPos + origin_pos;
	float3 look_to = origin_pos;
	float3 vup = float3(0, 1, 0);
	
	float3 w = normalize(look_from - look_to);
	float3 u = normalize(cross(vup, w));
	float3 v = cross(w, u);
	
	float3 ro = look_from, rd;
	float3 vertical = v, horizontal = uResolution.x / uResolution.y * u;
    float3 lower_left_corner = ro  - vertical / 2 -  horizontal / 2 - w;


	
	float3 light = normalize(float3(1, -1, 0));

    float2 uv = fragCoord.xy/uResolution;

    float3 Camera_matrix = lower_left_corner + horizontal * uv.x + vertical * uv.y;

    rd = 1 * (Camera_matrix - ro);

    rd = normalize(rd);

    float dist = 1, maxdist = 1000, l_dist = 0, was_min_dist = 3.402823466e+38F;
    int itr = 0;
    for(int i = 0; i < 125; i++)
    {
    	itr = i;

    	dist = GetDist(ro) ;
    	maxdist -= dist;
    	l_dist += dist;
    	ro += rd * dist;
    	was_min_dist  = min(was_min_dist, dist);
    	if(dist < SDF || maxdist < 0) break;
    	
    }
    
    float2x2 rot_mat = float2x2(cos(uTime * 0.2), -sin(uTime * 0.2), sin(uTime * 0.2), cos(uTime * 0.2));
	float2 rot_factor = ro.xz * rot_mat;
    
    float3 col_ro = float3(rot_factor.x, ro.y, rot_factor.y);
    float3 col = (col_ro + float3(0.5, 4, 10)) * 0.2;

    float3 normal = GetNormal(ro);
    col *= dot(light, -normal) * 0.4 + 0.5;
    col *= exp(-sqrt(itr) * 0.05) * 1.1;

	float Foggy_Density = (Foggy - was_min_dist + Solid_Foggy) / Foggy;

    return dist <= 0.01f ? float4(col.xyz, 0) : (was_min_dist < Foggy ? float4(Foggy_Color * Foggy_Density + float3(0.8) * (1 - Foggy_Density), 1) : 0.8);
}

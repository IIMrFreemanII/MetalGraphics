#include "SDF.h"

#include "Math.h"

// MARK: check if it works properly
float sdCircleSquared( float2 p, float r )
{
  return dot2(p) - r * r;
}

float sdCircle( float2 p, float r )
{
  return length(p) - r;
}

// MARK: check if it works properly
float sdRoundedBoxSquared(float2 p,float2 b, float4 r )
{
  r.xy = (p.x>0.0)?r.xy : r.zw;
  r.x  = (p.y>0.0)?r.x  : r.y;
  float2 q = abs(p)-b+r.x;
  float temp = min(max(q.x,q.y),0.0);
  return temp * temp + dot2(max(q,0.0)) - r.x * r.x;
}

float sdRoundedBox(float2 p,float2 b, float4 r )
{
  r.xy = (p.x>0.0)?r.xy : r.zw;
  r.x  = (p.y>0.0)?r.x  : r.y;
  float2 q = abs(p)-b+r.x;
  return min(max(q.x,q.y),0.0) + length(max(q,0.0)) - r.x;
}

// MARK: check if it works properly
float sdBoxSquared(float2 p, float2 b )
{
  float2 d = abs(p)-b;
  float temp = min(max(d.x,d.y),0.0);
  return dot2(max(d,0.0)) + temp * temp;
}

float sdBox(float2 p, float2 b )
{
  float2 d = abs(p)-b;
  return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}

float sdOrientedBox(float2 p, float2 a, float2 b, float th )
{
  float l = length(b-a);
  float2  d = (b-a)/l;
  float2  q = (p-(a+b)*0.5);
  q = float2x2(d.x,-d.y,d.y,d.x)*q;
  q = abs(q)-float2(l,th)*0.5;
  return length(max(q,0.0)) + min(max(q.x,q.y),0.0);
}

float sdSegment(float2 p, float2 a, float2 b )
{
  float2 pa = p-a, ba = b-a;
  float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
  return length( pa - ba*h );
}

float sdTriangle(float2 p, float2 p0, float2 p1, float2 p2 )
{
  float2 e0 = p1-p0;
  float2 e1 = p2-p1;
  float2 e2 = p0-p2;
  
  float2 v0 = p -p0;
  float2 v1 = p -p1;
  float2 v2 = p -p2;
  
  float2 pq0 = v0 - e0*clamp( dot(v0,e0)/dot(e0,e0), 0.0, 1.0 );
  float2 pq1 = v1 - e1*clamp( dot(v1,e1)/dot(e1,e1), 0.0, 1.0 );
  float2 pq2 = v2 - e2*clamp( dot(v2,e2)/dot(e2,e2), 0.0, 1.0 );
  
  float s = sign(e0.x*e2.y - e0.y*e2.x);
  float2 d = min(
                 min(float2(dot(pq0,pq0), s*(v0.x*e0.y-v0.y*e0.x)), float2(dot(pq1,pq1), s*(v1.x*e1.y-v1.y*e1.x))),
                 float2(dot(pq2,pq2), s*(v2.x*e2.y-v2.y*e2.x))
                 );
  return -sqrt(d.x)*sign(d.y);
}

float opRound(float d, float r )
{
  return d - r;
}

float opOnion(float d, float r )
{
  return abs(d) - r;
}

float opUnion( float d1, float d2 )
{
  return min(d1,d2);
}

float opSubtraction( float d1, float d2 )
{
  return max(-d1,d2);
}

float opIntersection( float d1, float d2 )
{
  return max(d1,d2);
}

float opSmoothUnion( float d1, float d2, float k )
{
  float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
  return mix( d2, d1, h ) - k*h*(1.0-h);
}

float opSmoothSubtraction( float d1, float d2, float k )
{
  float h = clamp( 0.5 - 0.5*(d2+d1)/k, 0.0, 1.0 );
  return mix( d2, -d1, h ) + k*h*(1.0-h);
}

float opSmoothIntersection( float d1, float d2, float k )
{
  float h = clamp( 0.5 - 0.5*(d2-d1)/k, 0.0, 1.0 );
  return mix( d2, d1, h ) + k*h*(1.0-h);
}

float opXor(float d1, float d2 )
{
  return max(min(d1,d2),-max(d1,d2));
}


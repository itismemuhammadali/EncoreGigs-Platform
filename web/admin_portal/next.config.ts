import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  async rewrites() {
    return [
      { source: '/terms-of-service', destination: '/terms-of-service.html' },
      { source: '/privacy-policy', destination: '/privacy-policy.html' },
      { source: '/terms-and-conditions', destination: '/terms-and-conditions.html' },
      { source: '/pricing-and-fees', destination: '/pricing-and-fees.html' },
      { source: '/dmca-policy', destination: '/dmca-policy.html' },
      { source: '/about-us', destination: '/about-us.html' },
      { source: '/legal', destination: '/legal.html' },
    ];
  },
};

export default nextConfig;

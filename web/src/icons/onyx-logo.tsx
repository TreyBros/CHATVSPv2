import * as React from "react";

interface OnyxLogoProps {
  width?: number;
  height?: number;
  className?: string;
  style?: React.CSSProperties;
}

const OnyxLogo = ({ width = 16, height = 16, className = "", style = {} }: OnyxLogoProps) => (
  <img
    src="/logo.png"
    alt="ChatVSP"
    width={width}
    height={height}
    className={`object-contain ${className}`}
    style={style}
  />
);
export default OnyxLogo;

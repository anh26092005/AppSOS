import React, { useState } from 'react';
import { generateDefaultAvatar } from '../utils/avatarUtils';

interface AvatarImageProps {
  src: string | undefined;
  alt: string;
  size?: 'sm' | 'md' | 'lg' | 'xl';
  className?: string;
}

/**
 * Avatar component với error handling và loading state
 * Tự động fallback về default avatar nếu image load failed
 */
const AvatarImage: React.FC<AvatarImageProps> = ({ 
  src, 
  alt, 
  size = 'md',
  className = '' 
}) => {
  const [imageError, setImageError] = useState(false);
  const [imageLoading, setImageLoading] = useState(true);

  // Size classes
  const sizeClasses = {
    sm: 'w-8 h-8',
    md: 'w-10 h-10',
    lg: 'w-12 h-12',
    xl: 'w-16 h-16',
  };

  // Determine avatar URL
  const avatarUrl = imageError || !src 
    ? generateDefaultAvatar(alt)
    : src;

  const handleImageError = () => {
    setImageError(true);
    setImageLoading(false);
  };

  const handleImageLoad = () => {
    setImageLoading(false);
  };

  return (
    <div className={`${sizeClasses[size]} relative ${className}`}>
      {imageLoading && !imageError && (
        <div className={`${sizeClasses[size]} rounded-full bg-gray-700 animate-pulse`} />
      )}
      <img
        src={avatarUrl}
        alt={alt}
        onError={handleImageError}
        onLoad={handleImageLoad}
        className={`${sizeClasses[size]} rounded-full object-cover ${
          imageLoading ? 'opacity-0' : 'opacity-100'
        } transition-opacity duration-200`}
      />
    </div>
  );
};

export default AvatarImage;

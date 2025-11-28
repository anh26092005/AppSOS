/**
 * Avatar utility functions
 * Xử lý avatar URLs, fallbacks, và default avatars
 */

/**
 * Tạo default avatar URL sử dụng UI Avatars API
 * @param name - Tên của user
 * @returns URL của avatar mặc định
 */
export const generateDefaultAvatar = (name: string): string => {
  if (!name) {
    return 'https://ui-avatars.com/api/?name=User&background=6366f1&color=fff&size=128';
  }
  
  // Encode name để tránh lỗi với ký tự đặc biệt
  const encodedName = encodeURIComponent(name);
  
  // Sử dụng UI Avatars với màu indigo (phù hợp với theme)
  return `https://ui-avatars.com/api/?name=${encodedName}&background=6366f1&color=fff&size=128&bold=true`;
};

/**
 * Fallback avatar URL khi không có tên
 */
export const FALLBACK_AVATAR = 'https://ui-avatars.com/api/?name=User&background=6366f1&color=fff&size=128';

/**
 * Lấy avatar URL từ backend avatar data
 * Xử lý cả object {url, key, bucket} và string URL
 * @param avatarData - Avatar data từ backend
 * @param userName - Tên user (dùng cho fallback)
 * @returns Avatar URL
 */
export const getAvatarUrl = (
  avatarData: any,
  userName?: string
): string => {
  // Nếu avatarData là object có url property
  if (avatarData && typeof avatarData === 'object' && avatarData.url) {
    return avatarData.url;
  }
  
  // Nếu avatarData là string URL
  if (typeof avatarData === 'string' && avatarData.trim()) {
    return avatarData;
  }
  
  // Fallback về default avatar
  return userName ? generateDefaultAvatar(userName) : FALLBACK_AVATAR;
};

/**
 * Validate avatar URL
 * @param url - URL cần validate
 * @returns true nếu URL hợp lệ
 */
export const isValidAvatarUrl = (url: string): boolean => {
  if (!url || typeof url !== 'string') return false;
  
  try {
    const urlObj = new URL(url);
    return urlObj.protocol === 'http:' || urlObj.protocol === 'https:';
  } catch {
    return false;
  }
};

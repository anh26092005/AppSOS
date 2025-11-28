import { User } from '../types';
import { getAvatarUrl } from './avatarUtils';

// Map backend user format to frontend user format
export const mapBackendUserToFrontendUser = (backendUser: any): User => {
  return {
    id: backendUser._id || backendUser.id,
    name: backendUser.fullName || backendUser.name,
    avatar: getAvatarUrl(backendUser.avatar, backendUser.fullName || backendUser.name),
    phone: backendUser.phone,
    registrationDate: backendUser.createdAt || new Date().toISOString(),
    status: backendUser.isActive !== false ? 'active' : 'suspended',
  };
};



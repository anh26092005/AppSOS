import axios from 'axios';
import { SystemSettings, DemoUser } from '../types';

const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:5000/api';

const getAuthHeaders = () => {
  const token = localStorage.getItem('token');
  return {
    headers: {
      Authorization: `Bearer ${token}`,
    },
  };
};

// Get system settings
export const getSystemSettings = async (): Promise<SystemSettings> => {
  const response = await axios.get(`${API_URL}/admin/system-settings`, getAuthHeaders());
  return response.data.data;
};

// Update demo mode
export const updateDemoMode = async (demoMode: boolean): Promise<SystemSettings> => {
  const response = await axios.put(
    `${API_URL}/admin/system-settings`,
    { demoMode },
    getAuthHeaders()
  );
  return response.data.data;
};

// Get demo users (users with isDemoAllowed = true)
export const getDemoUsers = async (params: {
  page?: number;
  limit?: number;
  search?: string;
}): Promise<{
  data: DemoUser[];
  pagination: { page: number; limit: number; total: number; pages: number };
}> => {
  const response = await axios.get(`${API_URL}/admin/demo-users`, {
    ...getAuthHeaders(),
    params,
  });
  return response.data;
};

// Update user demo access
export const updateUserDemoAccess = async (
  userId: string,
  isDemoAllowed: boolean
): Promise<DemoUser> => {
  const response = await axios.put(
    `${API_URL}/admin/users/${userId}/demo-access`,
    { isDemoAllowed },
    getAuthHeaders()
  );
  return response.data.data;
};

export const systemSettingsService = {
  getSystemSettings,
  updateDemoMode,
  getDemoUsers,
  updateUserDemoAccess,
};
